(* ir.ml — `tsc-cm-ir/0.2`: a NormalizedCMIR as a typed value the runtime can
   trust, and the load-time refusals that make a methodology safe to execute.

   WHAT CHANGED FROM 0.1, AND WHY THE VERSION HAD TO MOVE.

   In 0.1 the IR carried a `procedure` whose steps named a `provider_class` and
   a single `produces` surface, and a `result_contract` whose `derivation` was
   PROSE. The runtime read the vocabulary from the document and the derivation
   from `Runner.classify` — an OCaml function keyed on `cm_id`. The IR described
   a methodology; it did not CONTAIN one.

   0.2 is the shape that contains one:

     - a step names a checker CAPABILITY, not a provider. Who implements it is
       the linker's answer, not the methodology's (design §Core ontology).
     - a step declares TYPED INPUT and OUTPUT PORTS. Ports are what make the
       graph a graph: an input binds either a CM input or one named output port
       of another step, and those bindings ARE the edges.
     - every output is `required` (default) or `optional`. That single bit is
       what lets conditional progress exist without conditional nodes — see
       §Required and optional output ports below.
     - `failure_policy` maps a checker outcome to FACT AVAILABILITY or RUN
       STATUS. The 0.1 `failure -> ResultClass` shortcut is gone: it gave one
       node hidden authority over the CM's verdict.
     - `result` carries an ORDERED FIRST-MATCH RULE TABLE with a mandatory
       default ([Rule]), so the derivation is data.

   The `0.1` format string stays owned by what ships on `main`; a 0.2 document
   is structurally incompatible with it, so reusing the string would assert a
   false compatibility and destroy `format` as a discriminator.

   §REQUIRED AND OPTIONAL OUTPUT PORTS. A `success` outcome MUST publish every
   REQUIRED output; missing one is a provider contract violation and the outcome
   is REJECTED, not downgraded. An OPTIONAL output may be absent from a success:
   that is lawful withholding. A downstream step whose input binds an absent
   optional port is a principled SKIP naming the unpublished port. Without this
   distinction, "success publishes its declared outputs" and "a successful
   checker may withhold a proposal" contradict each other.

   §FACT PROVENANCE (issue AC5). Every non-scheduler fact a rule reads must
   originate in a DECLARED typed step output or a DECLARED evidence predicate.
   [validate_provenance] enforces that at LOAD — not at evaluation — so a rule
   reaching for an undeclared fact is refused before any provider runs, rather
   than being discovered by whichever subject happens to reach that clause.
   Scheduler-owned facts are limited to execution status ([terminal_statuses]).
   This is what keeps [Rule]'s evaluator generic: a fact that exists only inside
   this runtime's internals cannot be named by a portable rule.

   §DIVISION OF AUTHORITY with `contracts/cm-ir.cue` (unchanged in spirit from
   #127, but no longer lopsided). The CUE schema now marks every canonical block
   `field!:`, so it refuses ABSENCE as well as extras; this module refuses
   absence independently. Gate 9 requires both, precisely so neither is
   load-bearing alone. What this module adds on top of the schema is everything
   CUE cannot see: graph acyclicity, port resolution, fact provenance, rule-table
   totality, and vocabulary closure.

   Style: pure and total. No I/O, no exceptions, no fabricated defaults; every
   refusal is an [Error] carrying the dotted path at fault. *)

module J = Json
open Jread

let ( let* ) = Result.bind

(* The one `format` a NormalizedCMIR may carry. Checking it first is the
   cheapest proof that the artifact handed to the runtime is a CM IR at all. *)
let format_pin = "tsc-cm-ir/0.2"

(* The canonical top-level blocks. Named ONCE: the validator, the CUE schema's
   required set and the gate-9 negative-fixture table all derive from this list,
   so they cannot drift apart. *)
let canonical_blocks =
  [ "format"; "cm"; "question"; "inputs"; "steps"; "result"; "receipt"; "permissions" ]

(* The closed set of terminal step statuses a scheduler fact may name. `skipped`
   is in the set: a principled skip is an observable outcome a methodology is
   entitled to reason about, and hiding it would force CMs to infer it. *)
let terminal_statuses = [ "success"; "incomplete"; "refused"; "failed"; "skipped" ]

(* The checker kinds this runtime executes. `semantic_judgment`, `invoke_cm`,
   `oracle` and `transform` are named by the design but are explicitly out of
   scope for this cycle (FLAT: every step terminates at a primitive provider),
   so they are REFUSED rather than silently accepted and mis-executed. *)
let executable_kinds = [ "mechanical" ]

(* ──────────────────────────── typed IR shapes ────────────────────────── *)

(* Where a step input comes from. These two constructors are the graph's edge
   set: [From_output] is an edge, [From_input] is a root. *)
type binding =
  | From_input of string                 (* a declared CM input *)
  | From_output of string * string       (* step_id, output port *)

let binding_to_string = function
  | From_input name -> Printf.sprintf "input %S" name
  | From_output (sid, port) -> Printf.sprintf "%s.%s" sid port

type step_input = {
  in_name   : string;
  in_from   : binding;
  in_schema : string;
}

type step_output = {
  out_name     : string;
  out_schema   : string;
  out_required : bool;   (* default true; false = lawful withholding permitted *)
}

(* What a non-success checker outcome does to the run. Deliberately NOT a result
   class: a step must not name the CM's verdict. *)
type disposition =
  | Fact_unavailable   (* the step publishes nothing; the run continues *)
  | Run_failed         (* the run aborts fail-closed; no receipt *)

let disposition_of_string ~ctx ~key = function
  | "fact_unavailable" -> Ok Fact_unavailable
  | "run_failed" -> Ok Run_failed
  | other ->
    Error (Printf.sprintf
             "%s%s is %S; a failure policy maps an outcome to fact availability \
              or run status (\"fact_unavailable\" | \"run_failed\"), never to a \
              result class" ctx key other)

type failure_policy = {
  on_incomplete : disposition;
  on_refused    : disposition;
  on_failed     : disposition;
}

type bounds = {
  wall_time_ms : int;
  output_bytes : int;
}

type step = {
  step_id      : string;
  step_kind    : string;
  capability   : string;
  interface    : string;
  step_inputs  : step_input list;
  step_outputs : step_output list;
  step_config  : (string * Value.t) list;
  ev_schema    : string;
  ev_required  : bool;
  ev_predicates : string list;
  requested_capabilities : string list;
  step_bounds  : bounds;
  policy       : failure_policy;
}

type cm_input = {
  input_name     : string;
  input_kind     : string;
  input_schema   : string;
  input_required : bool;
}

type receipt_contract = {
  family        : string;
  family_schema : string;
  reports       : Rule.reference list;
  measure_only  : bool;
}

type permissions = {
  permitted_capabilities : string list;
  permitted_bounds       : bounds;
}

type t = {
  format           : string;
  cm_id            : string;
  cm_version       : string;
  cm_source_digest : string;
  question         : string;
  inputs           : cm_input list;
  steps            : step list;
  result           : Rule.table;
  receipt          : receipt_contract;
  permissions      : permissions;
}

let find_step (ir : t) (sid : string) : step option =
  List.find_opt (fun s -> String.equal s.step_id sid) ir.steps

let declares_output (s : step) (port : string) : bool =
  List.exists (fun o -> String.equal o.out_name port) s.step_outputs

let output_port (s : step) (port : string) : step_output option =
  List.find_opt (fun o -> String.equal o.out_name port) s.step_outputs

let declares_predicate (s : step) (pred : string) : bool =
  List.mem pred s.ev_predicates

(* ──────────────────────────────── parsing ────────────────────────────── *)

let bounds_of_json ~(ctx : string) (j : J.t) : (bounds, string) result =
  let* () = closed ~ctx ~allowed:[ "wall_time_ms"; "output_bytes" ] j in
  let* wall_time_ms = required_int ~ctx "wall_time_ms" j in
  let* output_bytes = required_int ~ctx "output_bytes" j in
  if wall_time_ms <= 0 then Error (ctx ^ "wall_time_ms must be positive")
  else if output_bytes <= 0 then Error (ctx ^ "output_bytes must be positive")
  else Ok { wall_time_ms; output_bytes }

let binding_of_json ~(ctx : string) (j : J.t) : (binding, string) result =
  let* () = closed ~ctx ~allowed:[ "input"; "step"; "output" ] j in
  match field "input" j, field "step" j, field "output" j with
  | Some (J.Str name), None, None -> Ok (From_input name)
  | None, Some (J.Str sid), Some (J.Str port) -> Ok (From_output (sid, port))
  | None, Some _, Some _ -> Error (ctx ^ "step and output must both be strings")
  | Some _, None, None -> Error (ctx ^ "input must be a string")
  | None, Some _, None -> Error (ctx ^ "output is missing (a step binding needs both)")
  | None, None, Some _ -> Error (ctx ^ "step is missing (a step binding needs both)")
  | _ ->
    Error (ctx ^ "from must be {\"input\": \"<name>\"} or \
                  {\"step\": \"<id>\", \"output\": \"<port>\"}, not both")

let step_input_of_json ~(ctx : string) (in_name : string) (j : J.t)
  : (step_input, string) result =
  let ctx = Printf.sprintf "%s%s." ctx in_name in
  let* () = closed ~ctx ~allowed:[ "from"; "schema" ] j in
  let* from_j = required_object ~ctx "from" j in
  let* in_from = binding_of_json ~ctx:(ctx ^ "from.") from_j in
  let* in_schema = required_string ~ctx "schema" j in
  Ok { in_name; in_from; in_schema }

let step_output_of_json ~(ctx : string) (out_name : string) (j : J.t)
  : (step_output, string) result =
  let ctx = Printf.sprintf "%s%s." ctx out_name in
  let* () = closed ~ctx ~allowed:[ "schema"; "required" ] j in
  let* out_schema = required_string ~ctx "schema" j in
  (* `required` defaults to TRUE. Withholding must be declared, never assumed:
     the safe reading of an unannotated port is "the checker promises it". *)
  let* out_required = optional_bool ~ctx "required" ~default:true j in
  Ok { out_name; out_schema; out_required }

(* An object whose KEYS are names and whose values are described by [each].
   Ports and inputs are name-keyed in the design's JSON, so this preserves the
   document's own shape rather than re-spelling it as an array of records. *)
let named_map ~(ctx : string) (each : string -> J.t -> ('a, string) result) (j : J.t)
  : ('a list, string) result =
  match j with
  | J.Obj kvs ->
    let* () = unique ~what:("name under " ^ ctx) (List.map fst kvs) in
    all (List.map (fun (k, v) ->
        if is_obj v then each k v
        else malformed ctx k "an object") kvs)
  | _ -> Error (Printf.sprintf "%s must be an object" ctx)

let config_of_json ~(ctx : string) (j : J.t) : ((string * Value.t) list, string) result =
  match j with
  | J.Obj kvs ->
    let* () = unique ~what:("config key under " ^ ctx) (List.map fst kvs) in
    all (List.map
           (fun (k, v) ->
              match Value.of_json v with
              | Some value -> Ok (k, value)
              | None ->
                Error (Printf.sprintf
                         "%s%s must be a boolean, integer or string; v0 checker \
                          configuration is scalar-valued" ctx k))
           kvs)
  | _ -> Error (Printf.sprintf "%s must be an object" (String.sub ctx 0 (String.length ctx - 1)))

let failure_policy_of_json ~(ctx : string) (j : J.t) : (failure_policy, string) result =
  let* () = closed ~ctx ~allowed:[ "incomplete"; "refused"; "failed" ] j in
  let one key =
    let* s = required_string ~ctx key j in
    disposition_of_string ~ctx ~key s
  in
  let* on_incomplete = one "incomplete" in
  let* on_refused = one "refused" in
  let* on_failed = one "failed" in
  Ok { on_incomplete; on_refused; on_failed }

let step_of_json (index : int) (j : J.t) : (step, string) result =
  let ctx = Printf.sprintf "steps[%d]." index in
  let* () =
    closed ~ctx
      ~allowed:[ "id"; "kind"; "checker"; "inputs"; "outputs"; "config"; "evidence";
                 "capabilities"; "bounds"; "failure_policy" ] j in
  let* step_id = required_string ~ctx "id" j in
  let* step_kind = required_string ~ctx "kind" j in
  let* () =
    if List.mem step_kind executable_kinds then Ok ()
    else
      Error (Printf.sprintf
               "%skind %S is not executable by this runtime; FLAT execution runs \
                [%s] only — every step must terminate at a primitive provider"
               ctx step_kind (String.concat ", " executable_kinds))
  in
  let* checker = required_object ~ctx "checker" j in
  let* () = closed ~ctx:(ctx ^ "checker.") ~allowed:[ "capability"; "interface" ] checker in
  let* capability = required_string ~ctx:(ctx ^ "checker.") "capability" checker in
  let* interface = required_string ~ctx:(ctx ^ "checker.") "interface" checker in
  let* inputs_j = required_object ~ctx "inputs" j in
  let* step_inputs =
    named_map ~ctx:(ctx ^ "inputs") (step_input_of_json ~ctx:(ctx ^ "inputs.")) inputs_j in
  let* outputs_j = required_object ~ctx "outputs" j in
  let* step_outputs =
    named_map ~ctx:(ctx ^ "outputs") (step_output_of_json ~ctx:(ctx ^ "outputs.")) outputs_j in
  let* () =
    if step_outputs = [] then
      Error (ctx ^ "outputs declares no port; a checker that publishes nothing \
                    cannot contribute a fact")
    else Ok () in
  let* config_j = required_object ~ctx "config" j in
  let* step_config = config_of_json ~ctx:(ctx ^ "config.") config_j in
  let* evidence = required_object ~ctx "evidence" j in
  let ectx = ctx ^ "evidence." in
  let* () = closed ~ctx:ectx ~allowed:[ "schema"; "required"; "predicates" ] evidence in
  let* ev_schema = required_string ~ctx:ectx "schema" evidence in
  let* ev_required = required_bool ~ctx:ectx "required" evidence in
  (* The evidence PREDICATES a rule may name. Declaring them here is what makes
     `{"evidence": "step.pred"}` a provenance-checkable reference rather than a
     hole through which the evaluator could reach into provider internals. *)
  let* ev_predicates = required_string_array ~ctx:ectx "predicates" evidence in
  let* () = unique ~what:(ectx ^ "predicate") ev_predicates in
  let* capabilities = required_object ~ctx "capabilities" j in
  let* () = closed ~ctx:(ctx ^ "capabilities.") ~allowed:[ "request" ] capabilities in
  let* requested_capabilities =
    required_string_array ~ctx:(ctx ^ "capabilities.") "request" capabilities in
  let* bounds_j = required_object ~ctx "bounds" j in
  let* step_bounds = bounds_of_json ~ctx:(ctx ^ "bounds.") bounds_j in
  let* policy_j = required_object ~ctx "failure_policy" j in
  let* policy = failure_policy_of_json ~ctx:(ctx ^ "failure_policy.") policy_j in
  Ok { step_id; step_kind; capability; interface; step_inputs; step_outputs;
       step_config; ev_schema; ev_required; ev_predicates; requested_capabilities;
       step_bounds; policy }

let cm_input_of_json ~(ctx : string) (input_name : string) (j : J.t)
  : (cm_input, string) result =
  let ctx = Printf.sprintf "%s%s." ctx input_name in
  let* () = closed ~ctx ~allowed:[ "kind"; "schema"; "required" ] j in
  let* input_kind = required_string ~ctx "kind" j in
  let* input_schema = required_string ~ctx "schema" j in
  let* input_required = required_bool ~ctx "required" j in
  Ok { input_name; input_kind; input_schema; input_required }

let receipt_of_json (j : J.t) : (receipt_contract, string) result =
  let ctx = "receipt." in
  let* () =
    closed ~ctx ~allowed:[ "family"; "schema"; "reports"; "measure_only" ] j in
  let* family = required_string ~ctx "family" j in
  let* family_schema = required_string ~ctx "schema" j in
  let* report_refs = required_string_array ~ctx "reports" j in
  (* A report is a FACT REFERENCE, spelled exactly as a rule spells one, so the
     same provenance check covers both. `step.port` reads an output port;
     `evidence:step.pred` reads a declared evidence predicate. *)
  let* reports =
    all (List.mapi
           (fun i r ->
              let ictx = Printf.sprintf "receipt.reports[%d]." i in
              let evp = "evidence:" in
              let n = String.length evp in
              if String.length r > n && String.sub r 0 n = evp then
                let rest = String.sub r n (String.length r - n) in
                let* (sid, pred) = Rule.split_ref ~ctx:ictx ~key:"evidence" rest in
                Ok (Rule.Evidence (sid, pred))
              else
                let* (sid, port) = Rule.split_ref ~ctx:ictx ~key:"fact" r in
                Ok (Rule.Output (sid, port)))
           report_refs) in
  let* measure_only = required_bool ~ctx "measure_only" j in
  Ok { family; family_schema; reports; measure_only }

let permissions_of_json (j : J.t) : (permissions, string) result =
  let ctx = "permissions." in
  let* () = closed ~ctx ~allowed:[ "capabilities"; "bounds" ] j in
  let* permitted_capabilities = required_string_array ~ctx "capabilities" j in
  let* bounds_j = required_object ~ctx "bounds" j in
  let* permitted_bounds = bounds_of_json ~ctx:(ctx ^ "bounds.") bounds_j in
  Ok { permitted_capabilities; permitted_bounds }

(* ─────────────────── graph, provenance and closure checks ────────────── *)

(* Every input binds a declared CM input or an existing step's DECLARED output
   port. An unresolved port is a wiring bug that must never reach the linker. *)
let validate_edges (ir : t) : (unit, string) result =
  let check (s : step) (i : step_input) =
    match i.in_from with
    | From_input name ->
      if List.exists (fun ci -> String.equal ci.input_name name) ir.inputs then Ok ()
      else
        Error (Printf.sprintf
                 "step %S input %S binds CM input %S, which `inputs` does not declare"
                 s.step_id i.in_name name)
    | From_output (sid, port) ->
      if String.equal sid s.step_id then
        Error (Printf.sprintf "step %S input %S binds its own output %S" s.step_id i.in_name port)
      else
        (match find_step ir sid with
         | None ->
           Error (Printf.sprintf
                    "step %S input %S binds output of step %S, which does not exist"
                    s.step_id i.in_name sid)
         | Some producer ->
           if declares_output producer port then Ok ()
           else
             Error (Printf.sprintf
                      "step %S input %S binds %s.%s, which step %S does not declare \
                       as an output port" s.step_id i.in_name sid port sid))
  in
  all (List.concat_map (fun s -> List.map (check s) s.step_inputs) ir.steps)
  |> Result.map (fun _ -> ())

(* The graph must be FINITE and ACYCLIC (design §Graph execution semantics 1).
   Kahn's algorithm over the edge set: repeatedly remove steps all of whose
   step-to-step dependencies are already removed. Anything left is in a cycle,
   and the refusal names the members so the author can see the loop. *)
let validate_acyclic (ir : t) : (unit, string) result =
  let deps (s : step) =
    List.filter_map
      (fun i -> match i.in_from with From_output (sid, _) -> Some sid | From_input _ -> None)
      s.step_inputs
  in
  let rec settle (settled : string list) (pending : step list) =
    let ready, blocked =
      List.partition (fun s -> List.for_all (fun d -> List.mem d settled) (deps s)) pending
    in
    match ready with
    | [] ->
      if blocked = [] then Ok ()
      else
        Error (Printf.sprintf
                 "the step graph is cyclic; steps [%s] can never become ready"
                 (String.concat ", "
                    (List.map (fun s -> Printf.sprintf "%S" s.step_id) blocked)))
    | _ -> settle (List.map (fun s -> s.step_id) ready @ settled) blocked
  in
  settle [] ir.steps

(* §FACT PROVENANCE (issue AC5). Refused at LOAD. *)
let validate_provenance (ir : t) : (unit, string) result =
  let resolve ~(site : string) (r : Rule.reference) =
    match r with
    | Rule.Output (sid, port) ->
      (match find_step ir sid with
       | None ->
         Error (Printf.sprintf
                  "%s reads fact %S, but no step %S is declared" site
                  (Rule.reference_to_string r) sid)
       | Some s ->
         if declares_output s port then Ok ()
         else
           Error (Printf.sprintf
                    "%s reads fact %S, which step %S does not declare as an output \
                     port [%s]; every non-scheduler fact must originate in a \
                     declared typed step output or a declared evidence predicate"
                    site (Rule.reference_to_string r) sid
                    (String.concat ", "
                       (List.map (fun o -> Printf.sprintf "%S" o.out_name) s.step_outputs))))
    | Rule.Evidence (sid, pred) ->
      (match find_step ir sid with
       | None ->
         Error (Printf.sprintf
                  "%s reads evidence %S, but no step %S is declared" site
                  (Rule.reference_to_string r) sid)
       | Some s ->
         if declares_predicate s pred then Ok ()
         else
           Error (Printf.sprintf
                    "%s reads evidence predicate %S, which step %S does not declare \
                     [%s]" site (Rule.reference_to_string r) sid
                    (String.concat ", " (List.map (Printf.sprintf "%S") s.ev_predicates))))
  in
  let rule_refs =
    List.map
      (fun (rid, r) -> resolve ~site:(Printf.sprintf "result rule %S" rid) r)
      (Rule.all_references ir.result) in
  let report_refs =
    List.map (fun r -> resolve ~site:"receipt.reports" r) ir.receipt.reports in
  (* Scheduler-owned facts: execution status only, and only for declared steps
     and known statuses. *)
  let status_refs =
    List.map
      (fun (rid, (sid, status)) ->
         match find_step ir sid with
         | None ->
           Error (Printf.sprintf
                    "result rule %S reads the status of step %S, which is not declared"
                    rid sid)
         | Some _ ->
           if List.mem status terminal_statuses then Ok ()
           else
             Error (Printf.sprintf
                      "result rule %S tests step %S for status %S; the closed status \
                       set is [%s]" rid sid status
                      (String.concat ", " (List.map (Printf.sprintf "%S") terminal_statuses))))
      (Rule.all_statuses ir.result) in
  all (rule_refs @ report_refs @ status_refs) |> Result.map (fun _ -> ())

(* Every step's requested capabilities must be within the CM's own declared
   envelope, and its bounds within the CM's ceilings. `permissions` is the
   MAXIMUM the linker may request; a step asking for more is refused before any
   host policy is consulted. *)
let validate_permissions (ir : t) : (unit, string) result =
  let p = ir.permissions in
  let check (s : step) =
    let excess =
      List.filter (fun c -> not (List.mem c p.permitted_capabilities))
        s.requested_capabilities in
    if excess <> [] then
      Error (Printf.sprintf
               "step %S requests capability/ies [%s] outside the CM's declared \
                permissions.capabilities [%s]" s.step_id
               (String.concat ", " (List.map (Printf.sprintf "%S") excess))
               (String.concat ", " (List.map (Printf.sprintf "%S") p.permitted_capabilities)))
    else if s.step_bounds.wall_time_ms > p.permitted_bounds.wall_time_ms then
      Error (Printf.sprintf
               "step %S declares wall_time_ms %d above the CM ceiling %d"
               s.step_id s.step_bounds.wall_time_ms p.permitted_bounds.wall_time_ms)
    else if s.step_bounds.output_bytes > p.permitted_bounds.output_bytes then
      Error (Printf.sprintf
               "step %S declares output_bytes %d above the CM ceiling %d"
               s.step_id s.step_bounds.output_bytes p.permitted_bounds.output_bytes)
    else Ok ()
  in
  all (List.map check ir.steps) |> Result.map (fun _ -> ())

(* ─────────────────────────────── entry point ─────────────────────────── *)

let of_json (j : J.t) : (t, string) result =
  let ctx = "" in
  let* () = closed ~ctx ~allowed:canonical_blocks j in
  let* format = required_string ~ctx "format" j in
  let* () =
    if String.equal format format_pin then Ok ()
    else
      Error (Printf.sprintf "format %S is not the NormalizedCMIR format %S"
               format format_pin)
  in
  let* cm = required_object ~ctx "cm" j in
  let* () = closed ~ctx:"cm." ~allowed:[ "id"; "version"; "source_digest" ] cm in
  let* cm_id = required_string ~ctx:"cm." "id" cm in
  let* cm_version = required_string ~ctx:"cm." "version" cm in
  let* cm_source_digest = required_string ~ctx:"cm." "source_digest" cm in
  let* question = required_string ~ctx "question" j in
  let* () =
    if String.trim question = "" then
      Error "question is empty; a CM with no governing measurement question \
             measures nothing"
    else Ok () in
  let* inputs_j = required_object ~ctx "inputs" j in
  let* inputs = named_map ~ctx:"inputs" (cm_input_of_json ~ctx:"inputs.") inputs_j in
  let* () =
    if inputs = [] then Error "inputs declares no subject input" else Ok () in
  let* step_jsons = required_array ~ctx "steps" j in
  let* steps = all (List.mapi step_of_json step_jsons) in
  let* () =
    if steps = [] then
      Error "steps declares no work; an IR declaring no work and no vocabulary \
             must not validate"
    else Ok () in
  let* () = unique ~what:"step id" (List.map (fun s -> s.step_id) steps) in
  let* result_j = required_object ~ctx "result" j in
  let* result = Rule.of_json result_j in
  let* receipt_j = required_object ~ctx "receipt" j in
  let* receipt = receipt_of_json receipt_j in
  let* permissions_j = required_object ~ctx "permissions" j in
  let* permissions = permissions_of_json permissions_j in
  let ir = { format; cm_id; cm_version; cm_source_digest; question; inputs; steps;
             result; receipt; permissions } in
  let* () = validate_edges ir in
  let* () = validate_acyclic ir in
  let* () = validate_provenance ir in
  let* () = validate_permissions ir in
  Ok ir
