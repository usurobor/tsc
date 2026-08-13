(* provider.ml — the checker CAPABILITY contracts and the mechanical providers
   that implement them.

   THE BOUNDARY THIS FILE DEFINES IS THE POINT OF THE CYCLE:

     adding a PROVIDER is OCaml — it lives here, and only here;
     adding a METHODOLOGY is not — it is a JSON document and nothing else.

   Everything downstream of this file (linker, scheduler, evaluator, receipt
   writer) is methodology-agnostic. Nothing in this file knows what a CM is:
   a capability describes an interface and a provider answers a [request] with
   an [outcome]. Neither mentions a result class, a rule, or a `cm_id`.

   §WHO OWNS THE CONFIG SCHEMA (design gate 11). A step's `config` is
   methodology-owned and portable, so its SHAPE is owned by the CAPABILITY
   CONTRACT — not by the CM (which would let each methodology invent its own),
   and not by the provider (which would let an implementation widen or narrow
   what the interface promises). [cap_config] below is that schema, and the
   linker validates a normalized step's `config` against the capability it binds
   BEFORE execution. A config that does not validate refuses at LINK TIME rather
   than reaching the provider.

   §WHY PATH CONFINEMENT IS A CONFIG TYPE. `Cfg_confined_path` is not decoration.
   An escaping `relative_path` is a static property of the methodology document,
   so it is refusable at link time — which is both the strongest place to refuse
   it (nothing has run, no receipt exists) and exactly what #126 AC6 demands
   ("denies fail-closed with ZERO receipt bytes"). [confine] is still applied
   inside the provider as defence in depth, because a path arriving through an
   input PORT (as `fs.text-metrics.target` does) is not statically known.

   §PURITY BOUNDARY. [confine] is pure and total over strings — its whole
   negative space is testable without a filesystem. The [invoke] shells are the
   only effectful code in the runtime. A sandbox violation is reported as
   [Error] (a run-level fail-closed denial), never as a lawful [Refused]
   outcome: a refusal is an epistemic condition the methodology may reason
   about, whereas an attempt to read outside the subject is a fault that must
   not produce a measurement at all. *)

module J = Json

let ( let* ) = Result.bind

(* ────────────────────────── capability contracts ─────────────────────── *)

(* The scalar type of one configuration field, as the CAPABILITY declares it. *)
type config_type =
  | Cfg_bool
  | Cfg_int_min of int      (* an integer at or above this floor *)
  | Cfg_confined_path       (* a relative path that cannot escape the subject *)

let config_type_name = function
  | Cfg_bool -> "boolean"
  | Cfg_int_min n -> Printf.sprintf "integer >= %d" n
  | Cfg_confined_path -> "subject-relative path (non-empty, not absolute, no \"..\" segment)"

type config_field = {
  cfg_name     : string;
  cfg_type     : config_type;
  cfg_required : bool;
}

(* An input slot. The KIND is load-bearing for link safety: binding a CM subject
   artifact into a value slot, or a step's scalar output into an artifact slot,
   is a category error the linker refuses. *)
type slot_kind =
  | Slot_artifact           (* a host-supplied locator for a subject artifact *)
  | Slot_value              (* a scalar produced by another step's output port *)

type input_slot = {
  slot_name   : string;
  slot_kind   : slot_kind;
  slot_schema : string;
}

(* An output port the capability can publish. [port_withholdable] says whether a
   SUCCESS outcome may lawfully omit it. A methodology may declare such a port
   `required: false` (and then a dependent step skips when it is withheld); a
   methodology may NOT declare it `required: true`, because the capability does
   not promise it — the linker refuses that as a contract mismatch. *)
type output_port = {
  port_name        : string;
  port_schema      : string;
  port_withholdable : bool;
}

type capability = {
  cap_id         : string;
  cap_interface  : string;
  cap_slots      : input_slot list;
  cap_ports      : output_port list;
  cap_config     : config_field list;
  cap_evidence_schema : string;
  cap_evidence_predicates : string list;
  cap_grants     : string list;   (* what the provider must be granted to run *)
  cap_provider_id : string;
  cap_provider_version : string;
}

(* ─────────────────────────── check request/outcome ───────────────────── *)

type limits = {
  limit_wall_time_ms : int;
  limit_output_bytes : int;
}

(* The step's declared VIEW — nothing more. A provider sees the locators and
   values bound to its own slots, its own config, its own limits and its own
   grants. It cannot see the IR, the plan, the other steps, or the subject
   outside its adapters. *)
type request = {
  req_locators : (string * string) list;   (* artifact slot -> host path *)
  req_values   : (string * Value.t) list;  (* value slot -> scalar *)
  req_config   : (string * Value.t) list;
  req_limits   : limits;
  req_grants   : string list;
}

type status = Success | Incomplete | Refused | Failed

let status_name = function
  | Success -> "success"
  | Incomplete -> "incomplete"
  | Refused -> "refused"
  | Failed -> "failed"

type outcome = {
  out_status      : status;
  out_ports       : (string * Value.t) list;   (* published ports; success only *)
  out_evidence    : (string * Value.t) list;   (* declared evidence predicates *)
  out_diagnostics : string list;
}

let refused ~note =
  { out_status = Refused; out_ports = []; out_evidence = []; out_diagnostics = [ note ] }

let incomplete ~note ~evidence =
  { out_status = Incomplete; out_ports = []; out_evidence = evidence;
    out_diagnostics = [ note ] }

(* ────────────────────────── path confinement (pure) ──────────────────── *)

(* A relative path is ADMITTED iff it is non-empty, not absolute, and contains
   no parent-directory (`..`) segment. Such a path cannot lexically escape
   [root]. Anything else is DENIED: the runtime refuses to read rather than
   resolving a path that could climb out of the subject. Lexical
   (component-wise) confinement is deliberate — the stdlib carries no `realpath`
   and the contract forbids Unix — so admission never depends on I/O. *)
let confine ~(root : string) ~(rel : string) : (string, string) result =
  if String.length rel = 0 then
    Error "relative_path is empty"
  else if not (Filename.is_relative rel) then
    Error (Printf.sprintf
             "relative_path %S is absolute; it must stay within the subject root" rel)
  else if List.mem Filename.parent_dir_name (String.split_on_char '/' rel) then
    Error (Printf.sprintf
             "relative_path %S contains a %S segment and could escape the subject root"
             rel Filename.parent_dir_name)
  else
    Ok (Filename.concat root rel)

(* ───────────────────────── small effectful helpers ───────────────────── *)

let regular_file_size (path : string) : int =
  let ic = open_in_bin path in
  Fun.protect ~finally:(fun () -> close_in_noerr ic) (fun () -> in_channel_length ic)

let read_file (path : string) (limit : int) : string =
  let ic = open_in_bin path in
  Fun.protect ~finally:(fun () -> close_in_noerr ic)
    (fun () ->
       let len = min (in_channel_length ic) limit in
       really_input_string ic len)

(* ──────────────────────────── request accessors ──────────────────────── *)

(* A provider reads its own request through these. A missing slot or config key
   is a LINKER bug, not a subject condition, so it surfaces as [Failed] with a
   diagnostic rather than as a lawful measurement outcome. *)
let locator (r : request) (slot : string) : (string, string) result =
  match List.assoc_opt slot r.req_locators with
  | Some p -> Ok p
  | None -> Error (Printf.sprintf "artifact slot %S was not bound by the plan" slot)

let value_slot (r : request) (slot : string) : (Value.t, string) result =
  match List.assoc_opt slot r.req_values with
  | Some v -> Ok v
  | None -> Error (Printf.sprintf "value slot %S was not bound by the plan" slot)

let cfg_string (r : request) (key : string) : (string, string) result =
  match List.assoc_opt key r.req_config with
  | Some (Value.Str s) -> Ok s
  | Some other ->
    Error (Printf.sprintf "config.%s is a %s, expected a string" key (Value.type_name other))
  | None -> Error (Printf.sprintf "config.%s is missing" key)

let cfg_int (r : request) (key : string) : (int, string) result =
  match List.assoc_opt key r.req_config with
  | Some (Value.Int i) -> Ok i
  | Some other ->
    Error (Printf.sprintf "config.%s is a %s, expected an integer" key (Value.type_name other))
  | None -> Error (Printf.sprintf "config.%s is missing" key)

let cfg_bool_default (r : request) (key : string) ~(default : bool) : bool =
  match List.assoc_opt key r.req_config with
  | Some (Value.Bool b) -> b
  | _ -> default

(* ─────────────────────────────── fs.file-exists ──────────────────────── *)

(* Capability: does a named path exist under the subject root, and where?

   `present` is always published on success. `path` is WITHHOLDABLE: when the
   file is absent there is no path to name, so a successful check publishes
   `present: false` and nothing else. That is the lawful-withholding case this
   runtime exercises, and it is what makes a dependent step's principled skip
   reachable without any conditional node. *)
let fs_file_exists : capability = {
  cap_id = "fs.file-exists";
  cap_interface = "tsc-checker/0.1";
  cap_slots = [
    { slot_name = "root"; slot_kind = Slot_artifact;
      slot_schema = "tsc://schema/directory-artifact/0.1" };
  ];
  cap_ports = [
    { port_name = "present"; port_schema = "tsc://schema/boolean/0.1";
      port_withholdable = false };
    { port_name = "path"; port_schema = "tsc://schema/relative-path/0.1";
      port_withholdable = true };
  ];
  cap_config = [
    { cfg_name = "relative_path"; cfg_type = Cfg_confined_path; cfg_required = true };
  ];
  cap_evidence_schema = "tsc://schema/file-observation/0.1";
  cap_evidence_predicates = [ "exists"; "is_directory"; "size_bytes"; "checked_path" ];
  cap_grants = [ "subject.fs.read" ];
  cap_provider_id = "coh-min.fs.file-exists";
  cap_provider_version = "0.2.0";
}

let invoke_file_exists (r : request) : (outcome, string) result =
  let* root = locator r "root" in
  let* rel = cfg_string r "relative_path" in
  (* Defence in depth: the linker already refused an escaping literal, but the
     provider does not take that on trust. A denial here is an [Error] — the run
     fails closed and emits no receipt. *)
  let* checked_path = confine ~root ~rel in
  let exists = Sys.file_exists checked_path in
  let is_directory = exists && Sys.is_directory checked_path in
  let size_bytes =
    if exists && not is_directory then regular_file_size checked_path else -1 in
  let ports =
    (* Lawful withholding: `path` is published only when there is a path. *)
    ("present", Value.Bool exists)
    :: (if exists then [ ("path", Value.Str rel) ] else []) in
  Ok { out_status = Success;
       out_ports = ports;
       out_evidence = [
         "exists", Value.Bool exists;
         "is_directory", Value.Bool is_directory;
         "size_bytes", Value.Int size_bytes;
         "checked_path", Value.Str checked_path;
       ];
       out_diagnostics = [] }

(* ────────────────────────────── fs.text-metrics ──────────────────────── *)

(* Capability: measure a text file identified by a subject-relative path that
   arrives through an input PORT rather than through config. That is what makes
   it a dependent step: the path is produced by another checker.

   Outcome discipline:
     - the target is absent or is a directory -> `incomplete` (the checker ran
       but could not establish its contracted fact);
     - the target exceeds the methodology's `max_bytes` or the plan's
       `output_bytes` limit -> `refused` (a bound lawfully prevented the check);
     - otherwise -> `success` with all three ports published.
   None of these names a result class. What each means for the CM is decided by
   the step's `failure_policy` and then by the CM's own rule table. *)
let fs_text_metrics : capability = {
  cap_id = "fs.text-metrics";
  cap_interface = "tsc-checker/0.1";
  cap_slots = [
    { slot_name = "root"; slot_kind = Slot_artifact;
      slot_schema = "tsc://schema/directory-artifact/0.1" };
    { slot_name = "target"; slot_kind = Slot_value;
      slot_schema = "tsc://schema/relative-path/0.1" };
  ];
  cap_ports = [
    { port_name = "line_count"; port_schema = "tsc://schema/integer/0.1";
      port_withholdable = false };
    { port_name = "byte_size"; port_schema = "tsc://schema/integer/0.1";
      port_withholdable = false };
    { port_name = "non_empty"; port_schema = "tsc://schema/boolean/0.1";
      port_withholdable = false };
  ];
  cap_config = [
    { cfg_name = "max_bytes"; cfg_type = Cfg_int_min 1; cfg_required = true };
    { cfg_name = "count_blank_lines"; cfg_type = Cfg_bool; cfg_required = false };
  ];
  cap_evidence_schema = "tsc://schema/text-metrics-observation/0.1";
  cap_evidence_predicates = [ "checked_path"; "read_bytes"; "blank_lines_counted" ];
  cap_grants = [ "subject.fs.read" ];
  cap_provider_id = "coh-min.fs.text-metrics";
  cap_provider_version = "0.2.0";
}

(* Count lines the way a reader would: a trailing newline does not invent an
   extra line, and an unterminated final line still counts. *)
let count_lines ~(count_blank : bool) (contents : string) : int =
  let lines = String.split_on_char '\n' contents in
  let lines =
    match List.rev lines with
    | "" :: rest when rest <> [] -> List.rev rest   (* trailing newline *)
    | _ -> lines
  in
  let lines = if count_blank then lines else List.filter (fun l -> String.trim l <> "") lines in
  List.length lines

let invoke_text_metrics (r : request) : (outcome, string) result =
  let* root = locator r "root" in
  let* target = value_slot r "target" in
  let* rel =
    match target with
    | Value.Str s -> Ok s
    | other ->
      Error (Printf.sprintf "input slot \"target\" is a %s, expected a string"
               (Value.type_name other))
  in
  let* checked_path = confine ~root ~rel in
  let* max_bytes = cfg_int r "max_bytes" in
  let count_blank = cfg_bool_default r "count_blank_lines" ~default:true in
  let ceiling = min max_bytes r.req_limits.limit_output_bytes in
  let base_evidence = [ "checked_path", Value.Str checked_path ] in
  if not (Sys.file_exists checked_path) then
    Ok (incomplete
          ~note:(Printf.sprintf "no file at %S under the subject root" rel)
          ~evidence:(base_evidence @ [ "read_bytes", Value.Int 0;
                                       "blank_lines_counted", Value.Bool count_blank ]))
  else if Sys.is_directory checked_path then
    Ok (incomplete
          ~note:(Printf.sprintf "%S is a directory, not a text file" rel)
          ~evidence:(base_evidence @ [ "read_bytes", Value.Int 0;
                                       "blank_lines_counted", Value.Bool count_blank ]))
  else
    let size = regular_file_size checked_path in
    if size > ceiling then
      Ok (refused
            ~note:(Printf.sprintf
                     "%S is %d bytes, above the effective ceiling of %d \
                      (config.max_bytes %d, plan output_bytes %d)"
                     rel size ceiling max_bytes r.req_limits.limit_output_bytes))
    else
      let contents = read_file checked_path ceiling in
      let line_count = count_lines ~count_blank contents in
      Ok { out_status = Success;
           out_ports = [
             "line_count", Value.Int line_count;
             "byte_size", Value.Int size;
             "non_empty", Value.Bool (String.trim contents <> "");
           ];
           out_evidence = base_evidence @ [
             "read_bytes", Value.Int (String.length contents);
             "blank_lines_counted", Value.Bool count_blank;
           ];
           out_diagnostics = [] }

(* ────────────────────────────── the registry ─────────────────────────── *)

(* The complete provider set. Adding a row here is the ONLY OCaml a new
   capability requires; adding a methodology requires none. *)
let registry : (capability * (request -> (outcome, string) result)) list = [
  fs_file_exists, invoke_file_exists;
  fs_text_metrics, invoke_text_metrics;
]

let capabilities : capability list = List.map fst registry

let find_capability (id : string) : capability option =
  List.find_opt (fun c -> String.equal c.cap_id id) capabilities

let known_capability_ids () : string list = List.map (fun c -> c.cap_id) capabilities

let invoke (cap : capability) (r : request) : (outcome, string) result =
  match List.find_opt (fun (c, _) -> String.equal c.cap_id cap.cap_id) registry with
  | Some (_, f) ->
    (* A provider malfunction is `failed`, a closed status the methodology's
       `failure_policy` decides about — but a SANDBOX denial is an [Error] that
       aborts the run. The two are distinguished by [f] returning [Error] only
       for confinement and plan-binding faults. *)
    f r
  | None -> Error (Printf.sprintf "no provider is registered for capability %S" cap.cap_id)

let port (cap : capability) (name : string) : output_port option =
  List.find_opt (fun p -> String.equal p.port_name name) cap.cap_ports

let slot (cap : capability) (name : string) : input_slot option =
  List.find_opt (fun s -> String.equal s.slot_name name) cap.cap_slots

(* ─────────────────── the runtime's own capability surface ────────────── *)

(* A capability contract, as canonical JSON. This is what the runtime's
   `provider.digest` and `runtime.digest` in the receipt are digests OF: the
   INTERFACE the provider promises, not the binary that happens to implement it
   on this host. That choice is deliberate and reproducible — a digest computed
   from a build artifact would differ between two builds of identical source and
   would make every receipt unverifiable off-host, whereas the contract digest
   changes exactly when the promise changes. *)
let capability_json (c : capability) : J.t =
  let s x = J.Str x in
  let arr x = J.Arr x in
  J.Obj [
    "id", s c.cap_id;
    "interface", s c.cap_interface;
    "provider_id", s c.cap_provider_id;
    "provider_version", s c.cap_provider_version;
    "slots", arr (List.map (fun sl ->
        J.Obj [ "name", s sl.slot_name;
                "kind", s (match sl.slot_kind with
                    | Slot_artifact -> "artifact" | Slot_value -> "value");
                "schema", s sl.slot_schema ]) c.cap_slots);
    "ports", arr (List.map (fun p ->
        J.Obj [ "name", s p.port_name; "schema", s p.port_schema;
                "withholdable", J.Bool p.port_withholdable ]) c.cap_ports);
    "config", arr (List.map (fun f ->
        J.Obj [ "name", s f.cfg_name; "type", s (config_type_name f.cfg_type);
                "required", J.Bool f.cfg_required ]) c.cap_config);
    "evidence", J.Obj [
      "schema", s c.cap_evidence_schema;
      "predicates", arr (List.map s c.cap_evidence_predicates);
    ];
    "grants", arr (List.map s c.cap_grants);
  ]

let capability_digest (c : capability) : string =
  "sha256:" ^ J.digest (capability_json c)

(* The digest of the whole provider surface: what this build of the runtime can
   do. A receipt binds it so a verifier can tell whether the runtime that
   produced the receipt offered the same capabilities as the one replaying it. *)
let surface_digest () : string =
  "sha256:" ^ J.digest (J.Arr (List.map capability_json capabilities))
