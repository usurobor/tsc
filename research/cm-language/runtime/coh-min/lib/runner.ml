(* coh-min runtime — the minimal, domain-neutral CM runner (M2), running the
   first ordinary CM end to end (M3).

   The path, harvested from the Ascent-0 runtime (`research/cm-language/runtime/
   ascent-0/lib/runtime.ml`) and generalized to an ORDINARY CM:

     load NormalizedCMIR (procedure.steps)
       -> LINK a SandboxExecutionPlan (each step's provider binding + capability)
       -> EXECUTE the finite DAG: a step runs only when its typed `reads`
          surfaces are all present; an unrun step is a principled skip, never a
          crash
       -> INVOKE the real provider backend (`file.exists` stats the disk)
       -> EVALUATE a small result rule over the produced evidence (the result is
          runtime-DERIVED, not provider-notarized)
       -> EMIT one MeasurementReceipt (canonical JSON, content-addressed plan).

   Unlike Ascent-0 this has NO oracle, NO sealed reveal, NO model enumeration:
   it is the ordinary-CM side of the two-sided kernel. The receipt CHANGES with
   the subject — README present -> README_PRESENT, absent -> README_ABSENT —
   because a real provider read the disk. Static IR validation cannot show that.

   Style (ocaml + write-functional skills): the executor is a recursion over an
   IMMUTABLE state record (no `ref` / `while`); every expected failure — a
   denied path, a malformed IR, an unknown provider — is carried in [result]
   and surfaces at the CLI edge as a fail-closed non-zero exit, never a partial
   receipt. *)

module J = Json

let ( let* ) = Result.bind

(* ─────────────────────────── run request ─────────────────────────────── *)

type run_request = {
  ir_path     : string;
  target_root : string;   (* the repository/subject directory under assessment *)
}

(* ───────────────────────── the execution plan ────────────────────────── *)

type plan_step = {
  order           : int;
  step_id         : string;
  provider_class  : string;
  provider_kind   : string;
  kind            : string;
  reads           : string list;
  produces        : string;
  config          : J.t;
  may_access      : string list;   (* sandbox capability binding (firewall seam) *)
  search_strength : string;
}

type plan = {
  cm_id         : string;
  cm_version    : string;
  source_digest : string;
  steps         : plan_step list;
}

(* LINK: normalize the IR's `procedure.steps` into a SandboxExecutionPlan. Each
   step is bound with the capabilities it declared (`may_access`); no host
   control plane is contacted — that binding is the standalone-sandbox seam that
   Ascent-0 uses for its oracle firewall and that this ordinary CM leaves empty. *)
let link (ir : J.t) : plan =
  let steps_json = J.to_list (J.member "steps" (J.member "procedure" ir)) in
  let link_step order sj =
    let list_field k =
      match J.member_opt k sj with Some a -> List.map J.to_string (J.to_list a) | None -> [] in
    { order;
      step_id = J.to_string (J.member "id" sj);
      provider_class = J.to_string (J.member "provider_class" sj);
      provider_kind = J.to_string (J.member "provider_kind" sj);
      kind = J.to_string (J.member "kind" sj);
      reads = list_field "reads";
      produces = J.to_string (J.member "produces" sj);
      config = (match J.member_opt "config" sj with Some c -> c | None -> J.Obj []);
      may_access = list_field "may_access";
      search_strength =
        (match J.member_opt "search_strength" sj with Some (J.Str s) -> s | _ -> "exact") }
  in
  { cm_id = J.to_string (J.member "cm_id" ir);
    cm_version = J.to_string (J.member "cm_version" ir);
    source_digest = J.to_string (J.member "source_digest" ir);
    steps = List.mapi link_step steps_json }

(* ───────────────────────────── execution ─────────────────────────────── *)

(* Immutable execution state, threaded through the DAG recursion. The three
   history lists are kept in reverse (cheap prepend) and reversed at emit. *)
type exec = {
  present  : string list;                       (* surfaces available *)
  trace    : (int * string) list;               (* (order, step_id), reversed *)
  evidence : (string * Provider.observation) list;  (* (step_id, obs), reversed *)
  findings : (string * bool) list;              (* produced surface -> boolean value *)
}

let seed_surfaces (ir : J.t) : string list =
  match J.member_opt "input_contract" ir with
  | Some ic ->
    (match J.member_opt "required_artifacts" ic with
     | Some (J.Arr items) ->
       List.filter_map
         (fun a -> match J.member_opt "role" a with Some (J.Str r) -> Some r | _ -> None)
         items
     | _ -> [])
  | None -> []

let ready (e : exec) (s : plan_step) : bool =
  List.for_all (fun r -> List.mem r e.present) s.reads

(* INVOKE one step's provider backend. Returns the evidence it captured and the
   boolean finding it produced, or an expected-failure reason (fail-closed). *)
let invoke ~(root : string) (s : plan_step)
  : ((string * Provider.observation) * (string * bool), string) result =
  match s.provider_class with
  | "file.exists" ->
    (match J.member_opt "relative_path" s.config with
     | Some (J.Str rel) ->
       let* obs = Provider.file_exists ~root ~rel in
       Ok ((s.step_id, obs), (s.produces, obs.Provider.exists))
     | _ -> Error "file.exists: config.relative_path (string) is required")
  | other ->
    Error (Printf.sprintf
             "unknown provider_class %S (coh-min wires only file.exists so far)" other)

(* Drive the finite DAG by input readiness: repeatedly run the first step (in IR
   order) whose typed `reads` are all present, until none is ready. The steps
   still unrun are returned so the caller can record them as principled skips. *)
let rec drive ~(root : string) (e : exec) (remaining : plan_step list)
  : (exec * plan_step list, string) result =
  match List.find_opt (ready e) remaining with
  | None -> Ok (e, remaining)   (* stuck: unrun steps are principled skips *)
  | Some s ->
    let* ((sid, obs), finding) = invoke ~root s in
    let e' = {
      present  = s.produces :: e.present;
      trace    = (List.length e.trace, s.step_id) :: e.trace;
      evidence = (sid, obs) :: e.evidence;
      findings = finding :: e.findings;
    } in
    drive ~root e' (List.filter (fun x -> x.step_id <> s.step_id) remaining)

(* EXECUTE: seed the base surfaces from the IR's required artifacts, then drive
   the DAG. Reports each unrun step with the surfaces it was missing, so a
   reviewer can confirm every skip is an absent input, not a wiring bug. *)
let execute ~(root : string) (ir : J.t) (pl : plan)
  : (exec * (string * string list) list, string) result =
  let e0 = { present = seed_surfaces ir; trace = []; evidence = []; findings = [] } in
  let* (e, remaining) = drive ~root e0 pl.steps in
  let skipped =
    List.map
      (fun s -> (s.step_id, List.filter (fun r -> not (List.mem r e.present)) s.reads))
      remaining
  in
  Ok (e, skipped)

(* ───────────────────────── evaluate the result rule ──────────────────── *)

type verdict = { result_class : string; complete : bool }

(* The decision projection for `example.readme-present`. The `.cm`'s `decide`
   block is not yet lowered into the IR, so the tracer carries the mapping for
   the one CM it knows; any other CM is left unclassified (fail-closed). This
   CM-specificity is honest tracer scope (see README §Honest scope). *)
let classify (pl : plan) (e : exec) : string option =
  if pl.cm_id = "example.readme-present" then
    match List.assoc_opt "readme_presence" e.findings with
    | Some true  -> Some "README_PRESENT"
    | Some false -> Some "README_ABSENT"
    | None -> None
  else None

let evaluate (pl : plan) (e : exec) (skipped : (string * string list) list) : verdict =
  let all_ran = skipped = [] && List.length e.trace = List.length pl.steps in
  match all_ran, classify pl e with
  | true, Some result_class -> { result_class; complete = true }
  | _ -> { result_class = "INCOMPLETE"; complete = false }

(* ─────────────────────────────── emit ────────────────────────────────── *)

let s x = J.Str x
let i x = J.Int x
let b x = J.Bool x
let arr x = J.Arr x
let obj x = J.Obj x

let plan_json (pl : plan) : J.t =
  let step_json st =
    obj [
      "order", i st.order;
      "step_id", s st.step_id;
      "provider_class", s st.provider_class;
      "provider_kind", s st.provider_kind;
      "kind", s st.kind;
      "reads", arr (List.map s st.reads);
      "produces", s st.produces;
      "may_access", arr (List.map s st.may_access);
      "search_strength", s st.search_strength;
    ]
  in
  obj [
    "cm_id", s pl.cm_id;
    "cm_version", s pl.cm_version;
    "source_digest", s pl.source_digest;
    "steps", arr (List.map step_json pl.steps);
  ]

let emit (rr : run_request) (pl : plan) (e : exec)
    (skipped : (string * string list) list) (v : verdict) : J.t =
  let plan_j = plan_json pl in
  obj [
    "format", s "tsc-measurement-receipt/0.1";
    "cm_id", s pl.cm_id;
    "cm_version", s pl.cm_version;
    "source_digest", s pl.source_digest;
    "run_request", obj [
      "target_root", s rr.target_root;
      "ir_path", s rr.ir_path;
    ];
    "plan_digest", s ("sha256:" ^ J.digest plan_j);
    "sandbox_execution_plan", plan_j;
    "execution_trace", arr
      (List.rev_map (fun (order, sid) -> obj [ "order", i order; "step_id", s sid ]) e.trace);
    "skipped_steps", arr
      (List.map (fun (sid, missing) ->
           obj [ "step_id", s sid; "missing_surfaces", arr (List.map s missing) ]) skipped);
    "evidence", arr
      (List.rev_map (fun (sid, obs) ->
           obj [ "step_id", s sid; "observation", Provider.observation_to_json obs ])
         e.evidence);
    "result", obj [
      "result_class", s v.result_class;
      "computed", b true;
      "complete", b v.complete;
      "rule", s "every declared step ran (else INCOMPLETE); then readme_presence \
                 true -> README_PRESENT, false -> README_ABSENT";
      "derived_from", arr (List.map s [ "execution_trace"; "evidence.readme_exists" ]);
    ];
  ]

(* ─────────────────────────────── driver ──────────────────────────────── *)

(* Load the hand-authored IR, link, execute against the subject, and emit one
   receipt — or a fail-closed error string. The SHA-256 self-test runs first so
   no emitted `plan_digest` can be silently wrong. IR read/parse failures and
   the DAG's expected failures all funnel into [Error]. *)
let run (rr : run_request) : (J.t, string) result =
  Sha256.self_test ();
  (* One guard around the whole pipeline: `parse_file` and the `link` accessors
     both raise on a malformed IR, so catching here keeps every IR fault
     fail-closed (a clean [Error], never an escaping exception). The vendored
     parser is not limited to [Parse_error]: a malformed number literal raises
     [Failure] (json.ml `int_of_string`/`float_of_string`) and a truncated
     `\u` escape raises [Invalid_argument] (json.ml `String.sub`), so both are
     caught here too — in α's code, keeping the vendored files byte-identical
     to ascent-0 (β round-1 F1). *)
  try
    let ir = J.parse_file rr.ir_path in
    let pl = link ir in
    let* (e, skipped) = execute ~root:rr.target_root ir pl in
    Ok (emit rr pl e skipped (evaluate pl e skipped))
  with
  | Sys_error msg -> Error msg
  | J.Parse_error msg -> Error ("IR error: " ^ msg)
  | Failure msg -> Error ("IR error: " ^ msg)
  | Invalid_argument msg -> Error ("IR error: " ^ msg)
