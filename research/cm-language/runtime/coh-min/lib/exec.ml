(* exec.ml — the checker DAG scheduler.

   Given a linked plan and the host locators, drive every step to a TERMINAL
   status and collect the immutable fact set the result evaluator will read.
   This module knows nothing about result classes: it produces facts, statuses
   and evidence, and stops. Which is the whole separation the design asks for —
   "checkers produce facts and evidence; the CM-owned rule produces the result".

   §READINESS, AND THE THIRD OUTCOME PEOPLE FORGET. A step is READY when every
   input bound to a peer's output port has that port PUBLISHED. It is SKIPPABLE
   when some such producer is terminal but did NOT publish the port it binds —
   because the producer was itself skipped or non-success, or because it
   succeeded and lawfully WITHHELD an optional port. Those are the only two
   possibilities once the graph is acyclic, so the loop below always makes
   progress and never blocks.

   The skip is PRINCIPLED: it names the unpublished port. That string is the
   difference between a runtime that reports "readme_depth: skipped" (useless)
   and one that reports "skipped: required input \"target\" binds
   readme_locate.path, which step readme_locate did not publish" — which tells
   the reader exactly which optional port was withheld and why the dependent
   check could not proceed. Nothing is fabricated: there is no default value,
   no empty string, no zero.

   §PROVIDER CONTRACT ENFORCEMENT, ON THE SUCCESS PATH. A `success` outcome
   missing a REQUIRED declared output is a contract violation: the outcome is
   REJECTED and the run fails closed. It is deliberately not downgraded to
   `incomplete`, because downgrading would let a provider convert "I broke my
   contract" into "the fact is unavailable" — a status the methodology is
   entitled to reason about and would then be reasoning about falsely.

   §THE TWO KINDS OF FAILURE. A checker outcome (`incomplete`/`refused`/
   `failed`) is data the methodology's `failure_policy` decides about. A SANDBOX
   DENIAL — a path that would escape the subject, a slot the plan never bound —
   is not: it aborts the run with no receipt. Providers signal the first through
   [Provider.outcome] and the second through [Error], and this module preserves
   the distinction rather than flattening it. *)

let ( let* ) = Result.bind

(* ─────────────────────────── the immutable fact set ──────────────────── *)

type entry = {
  order         : int;
  entry_step    : string;
  entry_status  : string;
  published     : (string * Value.t) list;   (* declared ports actually published *)
  (* LAWFUL WITHHOLDING ONLY. A port appears here when the checker SUCCEEDED and
     chose not to publish it — the one case where absence is a decision rather
     than a consequence. For a skipped, incomplete, refused or failed step the
     list is empty: nothing was withheld, the check simply did not establish
     anything, and [entry_status] already says so. Conflating the two would make
     "withheld" mean "absent", which is the distinction the required/optional
     port split exists to draw. *)
  withheld      : string list;
  skip_reason   : string option;             (* names the unpublished port *)
  diagnostics   : string list;
  entry_provider : string;
  entry_provider_digest : string;
  entry_evidence_schema : string;
  entry_evidence : (string * Value.t) list;
}

type state = {
  trace : entry list;   (* execution order, oldest first *)
}

let find_entry (st : state) (sid : string) : entry option =
  List.find_opt (fun e -> String.equal e.entry_step sid) st.trace

(* The three accessors the result evaluator is allowed, and no fourth. Built
   here because this is where the facts live; consumed by [Rule.env]. *)
let env_of_state (st : state) : Rule.env = {
  Rule.output =
    (fun sid port ->
       match find_entry st sid with
       | Some e -> List.assoc_opt port e.published
       | None -> None);
  Rule.predicate =
    (fun sid pred ->
       match find_entry st sid with
       | Some e -> List.assoc_opt pred e.entry_evidence
       | None -> None);
  Rule.status =
    (fun sid ->
       match find_entry st sid with Some e -> Some e.entry_status | None -> None);
}

let retained_evidence (st : state) (sid : string) : bool =
  match find_entry st sid with Some e -> e.entry_evidence <> [] | None -> false

(* ───────────────────────────── readiness ─────────────────────────────── *)

(* The dependency verdict for one input: satisfied, blocked (producer not yet
   terminal), or unsatisfiable (producer terminal, port not published). *)
type dep =
  | Satisfied
  | Pending
  | Unsatisfiable of string   (* the reason, naming the unpublished port *)

let dep_of_input (st : state) (step_id : string) (i : Ir.step_input) : dep =
  match i.Ir.in_from with
  | Ir.From_input _ -> Satisfied
  | Ir.From_output (sid, port) ->
    (match find_entry st sid with
     | None -> Pending
     | Some e ->
       if List.mem_assoc port e.published then Satisfied
       else
         Unsatisfiable
           (Printf.sprintf
              "required input %S of step %S binds %s.%s, which step %S did not \
               publish (step %S ended %s)"
              i.Ir.in_name step_id sid port sid sid e.entry_status))

type readiness =
  | Ready
  | Blocked
  | Skip of string

let readiness_of (st : state) (l : Linker.linked) : readiness =
  let deps = List.map (dep_of_input st l.Linker.l_step.Ir.step_id) l.Linker.l_step.Ir.step_inputs in
  match List.find_opt (function Unsatisfiable _ -> true | _ -> false) deps with
  | Some (Unsatisfiable why) -> Skip why
  | _ -> if List.exists (fun d -> d = Pending) deps then Blocked else Ready

(* ──────────────────────────── invoking one step ──────────────────────── *)

let build_request (st : state) (l : Linker.linked) ~(locators : (string * string) list)
  : (Provider.request, string) result =
  let s = l.Linker.l_step in
  let* bound =
    Jread.all
      (List.map
         (fun (i : Ir.step_input) ->
            match i.Ir.in_from with
            | Ir.From_input name ->
              (match List.assoc_opt name locators with
               | Some path -> Ok (`Locator (i.Ir.in_name, path))
               | None ->
                 Error (Printf.sprintf
                          "step %S input %S binds CM input %S, for which no host \
                           locator was supplied" s.Ir.step_id i.Ir.in_name name))
            | Ir.From_output (sid, port) ->
              (match find_entry st sid with
               | Some e ->
                 (match List.assoc_opt port e.published with
                  | Some v -> Ok (`Value (i.Ir.in_name, v))
                  | None ->
                    Error (Printf.sprintf
                             "step %S input %S binds %s.%s, which was not published"
                             s.Ir.step_id i.Ir.in_name sid port))
               | None ->
                 Error (Printf.sprintf
                          "step %S input %S binds %s.%s, whose producer has not run"
                          s.Ir.step_id i.Ir.in_name sid port)))
         s.Ir.step_inputs)
  in
  Ok {
    Provider.req_locators =
      List.filter_map (function `Locator (k, v) -> Some (k, v) | `Value _ -> None) bound;
    req_values =
      List.filter_map (function `Value (k, v) -> Some (k, v) | `Locator _ -> None) bound;
    req_config = s.Ir.step_config;
    req_limits = { Provider.limit_wall_time_ms = l.Linker.l_plan.Plan.limits.Plan.wall_time_ms;
                   limit_output_bytes = l.Linker.l_plan.Plan.limits.Plan.output_bytes };
    req_grants = l.Linker.l_plan.Plan.grants;
  }

(* Validate a SUCCESS outcome against the step's declared contract, then project
   it onto the declared ports. Undeclared ports the provider happened to publish
   are dropped: what a step makes visible is what the METHODOLOGY declared, not
   whatever the implementation offers. *)
let accept_success (s : Ir.step) (o : Provider.outcome)
  : ((string * Value.t) list * string list, string) result =
  let declared_required =
    List.filter (fun (p : Ir.step_output) -> p.Ir.out_required) s.Ir.step_outputs in
  let missing =
    List.filter
      (fun (p : Ir.step_output) -> not (List.mem_assoc p.Ir.out_name o.Provider.out_ports))
      declared_required in
  if missing <> [] then
    Error (Printf.sprintf
             "step %S returned `success` without publishing required output port(s) \
              [%s]; a success missing a required output is a contract violation and \
              is rejected, not downgraded" s.Ir.step_id
             (String.concat ", "
                (List.map (fun (p : Ir.step_output) -> Printf.sprintf "%S" p.Ir.out_name) missing)))
  else
    let missing_predicates =
      if not s.Ir.ev_required then []
      else
        List.filter (fun p -> not (List.mem_assoc p o.Provider.out_evidence))
          s.Ir.ev_predicates in
    if missing_predicates <> [] then
      Error (Printf.sprintf
               "step %S declares evidence as required but its outcome omits \
                predicate(s) [%s]" s.Ir.step_id
               (String.concat ", " (List.map (Printf.sprintf "%S") missing_predicates)))
    else
      let published =
        List.filter_map
          (fun (p : Ir.step_output) ->
             match List.assoc_opt p.Ir.out_name o.Provider.out_ports with
             | Some v -> Some (p.Ir.out_name, v)
             | None -> None)
          s.Ir.step_outputs in
      let withheld =
        List.filter_map
          (fun (p : Ir.step_output) ->
             if List.mem_assoc p.Ir.out_name published then None else Some p.Ir.out_name)
          s.Ir.step_outputs in
      Ok (published, withheld)

let disposition_for (s : Ir.step) (status : Provider.status) : Ir.disposition =
  match status with
  | Provider.Success -> Ir.Fact_unavailable   (* unreachable; success publishes *)
  | Provider.Incomplete -> s.Ir.policy.Ir.on_incomplete
  | Provider.Refused -> s.Ir.policy.Ir.on_refused
  | Provider.Failed -> s.Ir.policy.Ir.on_failed

let run_step (st : state) (l : Linker.linked) ~(locators : (string * string) list)
  : (entry, string) result =
  let s = l.Linker.l_step in
  let* req = build_request st l ~locators in
  let* outcome = Provider.invoke l.Linker.l_cap req in
  let base = {
    order = List.length st.trace;
    entry_step = s.Ir.step_id;
    entry_status = Provider.status_name outcome.Provider.out_status;
    published = [];
    withheld = [];
    skip_reason = None;
    diagnostics = outcome.Provider.out_diagnostics;
    entry_provider = l.Linker.l_plan.Plan.provider_id;
    entry_provider_digest = l.Linker.l_plan.Plan.provider_digest;
    entry_evidence_schema = s.Ir.ev_schema;
    entry_evidence = outcome.Provider.out_evidence;
  } in
  match outcome.Provider.out_status with
  | Provider.Success ->
    let* (published, withheld) = accept_success s outcome in
    Ok { base with published; withheld }
  | other ->
    (match disposition_for s other with
     | Ir.Fact_unavailable ->
       (* No fact is published, and nothing was WITHHELD: the checker did not
          establish its fact at all. The status itself is the fact the rule may
          read. *)
       Ok base
     | Ir.Run_failed ->
       Error (Printf.sprintf
                "step %S ended %s and its failure_policy maps that outcome to \
                 run_failed%s" s.Ir.step_id (Provider.status_name other)
                (match outcome.Provider.out_diagnostics with
                 | [] -> ""
                 | d :: _ -> ": " ^ d)))

(* ───────────────────────────── the schedule ──────────────────────────── *)

(* Ready steps could execute concurrently; observable results must not depend on
   scheduling order. This runtime is single-threaded and picks the FIRST ready
   step in the given order, which makes the trace deterministic. That the RESULT
   does not depend on that choice is a property the fact set has — facts are
   immutable and each is written once — and is pinned by a regression test that
   runs the same CM with its steps permuted and compares the derived class and
   published facts. *)
let rec drive (st : state) (remaining : Linker.linked list) ~(locators : (string * string) list)
  : (state, string) result =
  match remaining with
  | [] -> Ok st
  | _ ->
    let ready = List.find_opt (fun l -> readiness_of st l = Ready) remaining in
    (match ready with
     | Some l ->
       let* e = run_step st l ~locators in
       drive { trace = st.trace @ [ e ] }
         (List.filter (fun x -> x != l) remaining) ~locators
     | None ->
       let skippable =
         List.find_map
           (fun l -> match readiness_of st l with Skip why -> Some (l, why) | _ -> None)
           remaining
       in
       (match skippable with
        | Some (l, why) ->
          let s = l.Linker.l_step in
          let e = {
            order = List.length st.trace;
            entry_step = s.Ir.step_id;
            entry_status = "skipped";
            published = [];
            withheld = [];
            skip_reason = Some why;
            diagnostics = [];
            entry_provider = l.Linker.l_plan.Plan.provider_id;
            entry_provider_digest = l.Linker.l_plan.Plan.provider_digest;
            entry_evidence_schema = s.Ir.ev_schema;
            entry_evidence = [];
          } in
          drive { trace = st.trace @ [ e ] }
            (List.filter (fun x -> x != l) remaining) ~locators
        | None ->
          (* Unreachable: [Ir.validate_acyclic] refused any graph in which a step
             could stay Blocked forever. Reported rather than looped on, because
             a silent infinite loop is the one failure mode a scheduler must not
             have. *)
          Error (Printf.sprintf
                   "scheduler deadlock: step(s) [%s] are neither ready nor skippable"
                   (String.concat ", "
                      (List.map (fun l -> Printf.sprintf "%S" l.Linker.l_step.Ir.step_id) remaining)))))

(* The retained evidence must fit the run's evidence budget. A bound that is
   recorded but never enforced is decoration. *)
let check_evidence_budget (st : state) ~(ceiling : int) : (unit, string) result =
  let bytes =
    List.fold_left
      (fun acc e ->
         acc
         + String.length
             (Json.document
                (Json.Obj (List.map (fun (k, v) -> (k, Value.to_json v)) e.entry_evidence))))
      0 st.trace
  in
  if bytes <= ceiling then Ok ()
  else
    Error (Printf.sprintf
             "retained evidence is %d bytes, above the run request's evidence_bytes \
              ceiling of %d" bytes ceiling)

let execute (l : Linker.t) ~(locators : (string * string) list) ~(evidence_ceiling : int)
  : (state, string) result =
  let* st = drive { trace = [] } l.Linker.linked ~locators in
  let* () = check_evidence_budget st ~ceiling:evidence_ceiling in
  Ok st
