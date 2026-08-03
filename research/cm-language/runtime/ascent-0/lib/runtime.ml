(* The Ascent-0 Sub-3 runtime: load the NormalizedCMIR, resolve a RunRequest for
   one case, LINK sandbox provider bindings into a SandboxExecutionPlan, EXECUTE
   the finite DAG (a step runs only when its typed inputs exist), INVOKE the
   provider backends, CAPTURE evidence, RETAIN candidate alternatives, EVALUATE
   the Result rule, and EMIT one MeasurementReceipt.

   THE CRUX: the mechanical providers COMPUTE from the PUBLIC inputs. Nothing
   here reads the fixture's precomputed candidate sets / fibers / predictions
   (those are Sub-1's EXPECTED values). The only sealed datum is opened by the
   oracle backend alone, via the sandbox firewall, strictly AFTER the predictions
   are frozen. See `read_public_inputs` for the exact list of fields consumed.

   Honest terminology: the linked artifact is a SandboxExecutionPlan, never a
   normative CompiledCM. *)

module J = Json

(* ─────────────────────── fixture location (read-only) ─────────────────── *)

let rec find_up (dir : string) (rel : string) : string option =
  let cand = Filename.concat dir rel in
  if Sys.file_exists cand then Some cand
  else
    let parent = Filename.dirname dir in
    if parent = dir then None else find_up parent rel

let fixture_generated () : string =
  match Sys.getenv_opt "ASCENT0_FIXTURE_ROOT" with
  | Some p -> p
  | None ->
    (match find_up (Sys.getcwd ()) "research/ascent/fixtures/ascent-0/generated" with
     | Some p -> p
     | None -> failwith
         "could not locate research/ascent/fixtures/ascent-0/generated (set ASCENT0_FIXTURE_ROOT)")

(* ───────────────────────────── run request ───────────────────────────── *)

type run_request = {
  case_id      : string;
  case_dir     : string;   (* .../generated/cases/<case> *)
  class_path   : string;   (* .../generated/class.json *)
  reveal_path  : string;   (* .../generated/reveal/<case>.json  — SEALED *)
  ir_path      : string;
  view_path    : string;   (* canned deterministic #CompiledView *)
}

let case_map = function
  | "case1" -> "case1_lift_validated"
  | other -> other  (* accept full names too *)

let resolve_run_request ~case ~project_dir : run_request =
  let gen = fixture_generated () in
  let full = case_map case in
  let case_dir = Filename.concat gen (Filename.concat "cases" full) in
  if not (Sys.file_exists case_dir) then
    failwith (Printf.sprintf "unknown case %S (resolved dir %s absent)" case case_dir);
  {
    case_id = full;
    case_dir;
    class_path = Filename.concat gen "class.json";
    reveal_path = Filename.concat gen (Filename.concat "reveal" (full ^ ".json"));
    ir_path = Filename.concat project_dir "ir/ascent0.ir.json";
    view_path = Filename.concat project_dir
        (Printf.sprintf "fixtures/canned_compiled_view_%s.json"
           (match case with "case1" | "case1_lift_validated" -> "case1" | c -> c));
  }

(* ─────────────── PUBLIC INPUTS ONLY (the load-bearing firewall) ───────────
   This function is the single place the runtime reads the fixture case files.
   It reads ONLY the public-input surfaces and DELIBERATELY does not touch the
   Sub-1 EXPECTED / answer-key fields, which are listed here so a reviewer can
   check by inspection that none is consumed:
     candidate_fiber_over_U, complete_candidate_set_size,
     frozen_prediction_on_heldout, heldout_distinct_predictions,
     heldout_is_separating, training_identification_fiber_over_U,
     training_fiber_over_J_train, fiber_split_by_heldout_over_J_eval,
     expected_result, derived_result, expected_pass_count, expected_fail_count,
     expected_fail_count, expected_tested_fiber_size_after_reveal,
     recovered_class_contains_hidden_machine.
   Those are Sub-1's computed answers; this runtime recomputes them. *)

type public_inputs = {
  cfg          : Mealy.config;
  bounds_note  : string;
  traces       : Mealy.trace list;
  traces_json  : J.t;
  j_train      : string list;
  j_eval       : string list;
  heldout      : string;
  commitment   : string;
  viewpoint    : string;
}

let read_public_inputs (rr : run_request) : public_inputs =
  (* H_M declaration / search bounds — from class.json (public methodology). *)
  let cls = J.parse_file rr.class_path in
  let sigma = List.length (J.to_list (J.member "Sigma" cls)) in
  let gamma = List.length (J.to_list (J.member "Gamma" cls)) in
  let maxn = J.to_int (J.member "N_state_bound" cls) in
  (* U-length = the declared separator-completeness bound n1+n2-1 <= 2N-1
     (class.json.equivalence_separation_bound); derived from N, not read as a
     precomputed count. *)
  let ulen = 2 * maxn - 1 in
  let cfg = Mealy.{ sigma; gamma; maxn; ulen } in
  (* training traces + query families + held-out query + public commitment —
     from public.json (the mechanical backend contract; these are inputs). *)
  let pub = J.parse_file (Filename.concat rr.case_dir "public.json") in
  let traces_json = J.member "training_traces" pub in
  let traces =
    List.map
      (fun t -> Mealy.trace_of_strings
          (J.to_string (J.member "input" t))
          (J.to_string (J.member "observed_reply" t)))
      (J.to_list traces_json)
  in
  let heldout = J.to_string (J.member "heldout_query_public" pub) in
  (* J_train / J_eval are DERIVED from the public inputs (the training inputs and
     the public held-out query), not read from the fixture's core_ir block, so
     the runtime leans on no precomputed field for the query families. *)
  let j_train = List.map (fun t -> J.to_string (J.member "input" t)) (J.to_list traces_json) in
  let j_eval = j_train @ [ heldout ] in
  let commitment = J.to_string (J.member "oracle_commitment_sha256" pub) in
  (* the one-POV behaviour-primary viewpoint — the leak-free semantic input. *)
  let viewpoint =
    let ic = open_in_bin (Filename.concat rr.case_dir "semantic_input.txt") in
    let len = in_channel_length ic in
    let s = really_input_string ic len in close_in ic; s
  in
  { cfg;
    bounds_note = Printf.sprintf "complete_within_bound(N=%d, |Sigma|=%d, |Gamma|=%d)"
        maxn sigma gamma;
    traces; traces_json; j_train; j_eval; heldout; commitment; viewpoint }

(* ────────────────────────── the execution plan ───────────────────────── *)

type plan_step = {
  order          : int;
  step_id        : string;
  provider_class : string;
  provider_kind  : string;
  kind           : string;
  reads          : string list;
  produces       : string list;  (* surfaces this step makes present *)
  may_access     : string list;  (* sealed surfaces the sandbox grants (firewall) *)
  search_strength: string;
}

type plan = { cm_id : string; cm_version : string; source_digest : string;
              steps : plan_step list }

(* surfaces a step produces (authoritative for DAG gating; the IR `produces`
   is the single-valued hint, the plan is the linked truth). *)
let produced_by = function
  | "semantic" -> ["compiled_view"]
  | "finite_model_enumerate" -> ["enumerated_class"]
  | "realization_fit" -> ["fit_candidate_set"; "empty_or_unresolved_set"]
  | "realization_quotient" -> ["identification_fiber"]
  | "descent_predict" -> ["candidate_predictions"]
  (* the oracle emits the confirmed continuation pair (q*, revealed_output) that
     round-trip folds, so round-trip depends (via descent_evidence) on reveal. *)
  | "oracle_reveal_compare" -> ["oracle_outcome"; "descent_evidence"]
  | "roundtrip_check" -> ["roundtrip_fiber"]
  | other -> [other]

(* LINK: normalise the IR steps into a SandboxExecutionPlan, binding each step's
   sandbox capability (may_access). Firewall B lives here: only the oracle step's
   capability lists oracle surfaces; every non-oracle step is linked with an
   oracle-free capability (mirrors the Sub-2 may_access narrowing). *)
let link (ir : J.t) : plan =
  let steps_json = J.to_list (J.member "steps" (J.member "procedure" ir)) in
  let steps =
    List.mapi
      (fun order sj ->
         let sid = J.to_string (J.member "id" sj) in
         let pclass = J.to_string (J.member "provider_class" sj) in
         let declared_access =
           match J.member_opt "may_access" sj with
           | Some a -> List.map J.to_string (J.to_list a)
           | None -> []
         in
         (* Firewall B, enforced at link time: strip oracle surfaces from any
            non-oracle capability, no matter what the IR declared. *)
         let oracle_surfaces = ["oracle_reveal"; "hidden_machine"; "heldout_output_pre_reveal"] in
         let may_access =
           if pclass = "oracle" then declared_access
           else List.filter (fun s -> not (List.mem s oracle_surfaces)) declared_access
         in
         { order;
           step_id = sid;
           provider_class = pclass;
           provider_kind = J.to_string (J.member "provider_kind" sj);
           kind = J.to_string (J.member "kind" sj);
           reads = List.map J.to_string (J.to_list (J.member "reads" sj));
           produces = produced_by sid;
           may_access;
           search_strength = J.to_string (J.member "search_strength" sj) })
      steps_json
  in
  { cm_id = J.to_string (J.member "cm_id" ir);
    cm_version = J.to_string (J.member "cm_version" ir);
    source_digest = J.to_string (J.member "source_digest" ir);
    steps }

(* ─────────────────────────── execution state ─────────────────────────── *)

type oracle_outcome = {
  reveal_recomputed_sha : string;
  commitment_verified   : bool;
  revealed_output       : string;
  hidden_id             : string;
  pass_classes          : Mealy.fiber_class list;
  fail_classes          : Mealy.fiber_class list;
  tested_fiber_size     : int;
  contains_hidden       : bool;
  reveal_tick           : int;
}

type state = {
  pin : public_inputs;
  rr  : run_request;
  mutable present : string list;              (* surfaces available *)
  mutable clock : int;
  mutable events : (int * string * string) list;
  mutable exec_order : (int * string) list;
  mutable reveal_access_log : (string * string) list;
  (* produced artifacts *)
  mutable compiled_view : J.t option;
  mutable klass : Mealy.machine list;
  mutable fit : Mealy.machine list;
  mutable id_fiber : Mealy.fiber_class list;
  mutable predictions : (Mealy.fiber_class * string) list;
  mutable predictions_frozen_tick : int;
  mutable distinct_predictions : string list;
  mutable separating : bool;
  mutable oracle : oracle_outcome option;
  mutable roundtrip_fit : int;
  mutable roundtrip_fiber : int;
  mutable roundtrip_contains_hidden : bool;
}

let fresh_state pin rr = {
  pin; rr;
  present = []; clock = 0; events = []; exec_order = [];
  reveal_access_log = [];
  compiled_view = None; klass = []; fit = []; id_fiber = [];
  predictions = []; predictions_frozen_tick = 0; distinct_predictions = [];
  separating = false; oracle = None;
  roundtrip_fit = 0; roundtrip_fiber = 0; roundtrip_contains_hidden = false;
}

let tick st = st.clock <- st.clock + 1; st.clock
let log st sid ev = st.events <- (st.clock, sid, ev) :: st.events

(* THE SANDBOX FIREWALL: the only path to the sealed reveal bundle. It refuses
   any caller whose linked capability does not grant "oracle_reveal", and logs
   every access with the caller's provider class so the receipt can prove only
   the oracle opened it. *)
let read_sealed_reveal st ~provider_class ~(may_access : string list) : string * J.t =
  if not (List.mem "oracle_reveal" may_access) then
    failwith (Printf.sprintf
                "SANDBOX DENY: provider_class=%s has no oracle_reveal capability; \
                 the sealed reveal bundle is unreachable to it (Firewall B)"
                provider_class);
  st.reveal_access_log <- (provider_class, "oracle_reveal") :: st.reveal_access_log;
  let ic = open_in_bin st.rr.reveal_path in
  let len = in_channel_length ic in
  let raw = really_input_string ic len in
  close_in ic;
  (raw, J.parse raw)

(* ───────────────────────────── backends ──────────────────────────────── *)

let backend (st : state) (ps : plan_step) : unit =
  let cfg = st.pin.cfg in
  match ps.step_id with
  | "semantic" ->
    (* Canned deterministic #CompiledView (fixture response — no live LLM). It
       is a PROPOSAL: it owns no H_M and carries no warrant. We assert it is the
       closed five-field view (Firewall A shape). *)
    let v = J.parse_file st.rr.view_path in
    let required = ["governing_question"; "preserved_local_claims";
                    "closure_assumption"; "polar_view"; "named_obstruction"] in
    List.iter (fun k -> ignore (J.member k v)) required;
    (match v with
     | J.Obj kvs when List.length kvs = 5 -> ()
     | _ -> failwith "semantic: #CompiledView must be exactly the five proposal fields");
    st.compiled_view <- Some v;
    ignore (tick st); log st ps.step_id "compiled_view_proposed"
  | "finite_model_enumerate" ->
    (* Genuine complete bounded enumeration over H_M. *)
    st.klass <- Mealy.enumerate cfg;
    ignore (tick st);
    log st ps.step_id (Printf.sprintf "enumerated_%d_machines" (List.length st.klass))
  | "realization_fit" ->
    (* Genuine exact-fit partition (L_M = 0) over the enumerated class. *)
    st.fit <- Mealy.fit cfg st.klass st.pin.traces;
    ignore (tick st);
    log st ps.step_id (Printf.sprintf "fit_%d_of_%d"
                         (List.length st.fit) (List.length st.klass))
  | "realization_quotient" ->
    (* Genuine quotient F_id = C_train / ~=^U. *)
    st.id_fiber <- Mealy.fiber cfg st.fit (Mealy.universe cfg);
    ignore (tick st);
    log st ps.step_id (Printf.sprintf "identification_fiber_%d_classes"
                         (List.length st.id_fiber))
  | "descent_predict" ->
    (* Genuine descent: run each surviving candidate's transition law on the
       PUBLIC held-out query. Predictions are then FROZEN (before any reveal). *)
    let preds =
      List.map (fun fc -> (fc, Mealy.run_str cfg fc.Mealy.repr st.pin.heldout)) st.id_fiber
    in
    st.predictions <- preds;
    st.distinct_predictions <-
      List.sort_uniq compare (List.map snd preds);
    st.separating <- List.length st.distinct_predictions >= 2;
    st.predictions_frozen_tick <- tick st;
    log st ps.step_id
      (Printf.sprintf "predictions_frozen (%d classes, distinct=%s, separating=%b)"
         (List.length preds) (String.concat "," st.distinct_predictions) st.separating)
  | "oracle_reveal_compare" ->
    (* Firewall B + ordering: predictions must already be frozen. *)
    if st.predictions_frozen_tick = 0 then
      failwith "oracle: predictions are not frozen; reveal refused (ordering)";
    let (raw, rev) = read_sealed_reveal st ~provider_class:ps.provider_class
        ~may_access:ps.may_access in
    let recomputed = Sha256.digest_string raw in
    let commitment_verified = String.equal recomputed st.pin.commitment in
    let revealed_output = J.to_string (J.member "heldout_output" rev) in
    let hidden_id =
      J.to_string (J.member "canonical_id" (J.member "hidden_machine" rev)) in
    let reveal_tick = tick st in
    if not (st.predictions_frozen_tick < reveal_tick) then
      failwith "oracle: reveal did not strictly follow the frozen predictions";
    (* partition the FROZEN prediction classes by the revealed output. *)
    let pass, fail =
      List.partition (fun (_, p) -> String.equal p revealed_output) st.predictions in
    let pass_classes = List.map fst pass and fail_classes = List.map fst fail in
    (* tested fiber over J_eval among the passing candidate machines. *)
    let pass_machines =
      List.concat_map
        (fun fc -> List.filter (fun m -> List.mem (Mealy.canonical_id cfg m) fc.Mealy.members) st.fit)
        pass_classes
    in
    let jeval = List.map Mealy.inputs_of_str st.pin.j_eval in
    let tested_fiber = Mealy.fiber cfg pass_machines jeval in
    let contains_hidden =
      List.exists (fun m -> String.equal (Mealy.canonical_id cfg m) hidden_id) st.fit in
    st.oracle <- Some {
      reveal_recomputed_sha = recomputed;
      commitment_verified;
      revealed_output;
      hidden_id;
      pass_classes; fail_classes;
      tested_fiber_size = List.length tested_fiber;
      contains_hidden;
      reveal_tick;
    };
    log st ps.step_id
      (Printf.sprintf "reveal_opened output=%s commitment_verified=%b pass=%d fail=%d tested_fiber=%d"
         revealed_output commitment_verified (List.length pass) (List.length fail)
         (List.length tested_fiber))
  | "roundtrip_check" ->
    (* Fold the oracle-confirmed continuation (q*, revealed_output) back in,
       re-fit, re-quotient over J_eval; report the round-trip class. *)
    (match st.oracle with
     | None -> failwith "roundtrip: no oracle outcome to fold"
     | Some o ->
       let augmented =
         st.pin.traces @ [ Mealy.trace_of_strings st.pin.heldout o.revealed_output ] in
       let cfit = Mealy.fit cfg st.klass augmented in
       let jeval = List.map Mealy.inputs_of_str st.pin.j_eval in
       let rfiber = Mealy.fiber cfg cfit jeval in
       st.roundtrip_fit <- List.length cfit;
       st.roundtrip_fiber <- List.length rfiber;
       st.roundtrip_contains_hidden <-
         List.exists (fun m -> String.equal (Mealy.canonical_id cfg m) o.hidden_id) cfit;
       ignore (tick st);
       log st ps.step_id
         (Printf.sprintf "roundtrip fit=%d fiber_over_J_eval=%d contains_hidden=%b"
            st.roundtrip_fit st.roundtrip_fiber st.roundtrip_contains_hidden))
  | other -> failwith ("unknown step " ^ other)

(* ───────────────── EXECUTE: run the DAG by input readiness ────────────── *)

let execute (st : state) (pl : plan) : unit =
  (* seed the base surfaces produced by RunRequest resolution. *)
  st.present <- [
    "one_pov_behavior_primary_viewpoint"; "training_traces";
    "public_methodology_contract"; "H_M_declaration"; "search_bounds";
    "equivalence_relation"; "heldout_input_query"; "oracle_commitment";
    "oracle_reveal_bundle";
  ];
  let remaining = ref pl.steps in
  let ran = ref true in
  while !remaining <> [] && !ran do
    ran := false;
    (* pick the first step (IR order) whose typed inputs all exist. *)
    (match List.find_opt
             (fun s -> List.for_all (fun r -> List.mem r st.present) s.reads)
             !remaining with
     | None -> ()  (* stuck; loop exits *)
     | Some s ->
       backend st s;
       st.exec_order <- (List.length st.exec_order, s.step_id) :: st.exec_order;
       st.present <- st.present @ s.produces;
       remaining := List.filter (fun x -> x.step_id <> s.step_id) !remaining;
       ran := true)
  done;
  if !remaining <> [] then
    failwith (Printf.sprintf "DAG stuck; unrun steps: %s"
                (String.concat "," (List.map (fun s -> s.step_id) !remaining)))

(* ─────────────────────── EVALUATE the Result rule ─────────────────────── *)

type verdict = { result_class : string; admissible : bool; oracle_run : bool }

let evaluate (st : state) : verdict =
  (* admissible is a property of the PROPOSAL (a valid #CompiledView / typed
     generator witnessed), decoupled from fit — exactly as the frozen Sub-1
     Result rule requires. Folding fit>0 in here would make the
     NO_REALIZATION_IN_MODEL branch dead code and collapse the case3 (empty fit
     after complete search) vs case4 (proposal refused before realization)
     distinction. *)
  let admissible =
    (match st.compiled_view with Some _ -> true | None -> false) in
  let oracle_run = st.oracle <> None in
  let f_id = List.length st.id_fiber in
  let rc =
    (* Defensive guard, NOT exercised by the case1-only runtime: a
       non-#CompiledView proposal crashes at the semantic step, so compiled_view
       is always Some here and admissible is always true. Genuine DECORATIVE_LIFT
       — a WELL-FORMED *decorative* proposal (admissible=false over realizable
       data, Sub-1 case4) — is wired in #122. Kept so the Result rule is total
       and matches the rule the receipt prints. *)
    if not admissible then "DECORATIVE_LIFT"
    else if List.length st.fit = 0 then "NO_REALIZATION_IN_MODEL"
    else begin
      match st.oracle with
      | Some o when oracle_run && st.separating
                  && List.length o.pass_classes >= 1
                  && o.tested_fiber_size = 1 -> "LIFT_VALIDATED"
      | _ -> if f_id >= 2 then "ASCENT_UNDERDETERMINED" else "IDENTIFIED_IN_MODEL"
    end
  in
  { result_class = rc; admissible; oracle_run }

(* ─────────────────────────── EMIT the receipt ─────────────────────────── *)

let s x = J.Str x
let i x = J.Int x
let b x = J.Bool x
let arr x = J.Arr x
let obj x = J.Obj x

let plan_json (pl : plan) : J.t =
  obj [
    "cm_id", s pl.cm_id;
    "cm_version", s pl.cm_version;
    "source_digest", s pl.source_digest;
    "steps", arr (List.map (fun st ->
        obj [
          "order", i st.order;
          "step_id", s st.step_id;
          "provider_class", s st.provider_class;
          "provider_kind", s st.provider_kind;
          "kind", s st.kind;
          "reads", arr (List.map s st.reads);
          "produces", arr (List.map s st.produces);
          "may_access", arr (List.map s st.may_access);
          "search_strength", s st.search_strength;
        ]) pl.steps);
  ]

let emit (st : state) (pl : plan) (v : verdict) : J.t =
  let o = match st.oracle with Some o -> o | None -> failwith "no oracle outcome" in
  let plan_j = plan_json pl in
  let events = List.rev st.events in
  let compiled_view = match st.compiled_view with Some v -> v | None -> obj [] in
  let fiber_entry fc predicted =
    obj [ "representative", s fc.Mealy.repr_id;
          "predicted_on_heldout", s predicted;
          "member_count", i (List.length fc.Mealy.members) ] in
  let pass_repr = List.map (fun fc -> fc.Mealy.repr_id) o.pass_classes in
  let fail_repr = List.map (fun fc -> fc.Mealy.repr_id) o.fail_classes in
  obj [
    "format", s "tsc-ascent0-receipt/0.1";
    "cm_id", s pl.cm_id;
    "cm_version", s pl.cm_version;
    "source_digest", s pl.source_digest;
    "run_request", obj [
      "case", s st.rr.case_id;
      "arm", s "deterministic_conformance";
      "heldout_query", s st.pin.heldout;
      "fixture_case_dir", s st.rr.case_dir;
    ];
    "plan_digest", s ("sha256:" ^ J.digest plan_j);
    "sandbox_execution_plan", plan_j;
    "compiled_view", compiled_view;
    "execution_trace", arr (List.map (fun (order, sid) ->
        obj [ "order", i order; "step_id", s sid ]) (List.rev st.exec_order));
    "event_log", arr (List.map (fun (tk, sid, ev) ->
        obj [ "tick", i tk; "step_id", s sid; "event", s ev ]) events);
    "derivation", obj [
      "enumerated_class_size", i (List.length st.klass);
      "search_claim", s st.pin.bounds_note;
      "fit_candidate_count", i (List.length st.fit);
      "identification_fiber_size", i (List.length st.id_fiber);
      "heldout_query", s st.pin.heldout;
      "heldout_distinct_predictions", arr (List.map s st.distinct_predictions);
      "heldout_is_separating", b st.separating;
      "oracle", obj [
        "reveal_path", s st.rr.reveal_path;
        "public_commitment_sha256", s st.pin.commitment;
        "recomputed_reveal_sha256", s o.reveal_recomputed_sha;
        "commitment_verified", b o.commitment_verified;
        "revealed_output", s o.revealed_output;
        "hidden_machine_canonical_id", s o.hidden_id;
        "pass_count", i (List.length o.pass_classes);
        "fail_count", i (List.length o.fail_classes);
        "tested_fiber_size", i o.tested_fiber_size;
        "recovered_class_contains_hidden_machine", b o.contains_hidden;
      ];
      "roundtrip", obj [
        "augmented_fit_count", i st.roundtrip_fit;
        "fiber_over_J_eval_size", i st.roundtrip_fiber;
        "contains_hidden_machine", b st.roundtrip_contains_hidden;
      ];
    ];
    "retained_alternatives", obj [
      "policy", s "the executor retains every surviving alternative up to the \
                   Result rule; it never collapses a multi-candidate fiber before evaluate";
      "identification_fiber", arr
        (List.map (fun (fc, p) -> fiber_entry fc p) st.predictions);
      "pass_partition", arr (List.map s pass_repr);
      "fail_partition", arr (List.map s fail_repr);
      "retained_before_result_rule", i (List.length st.id_fiber);
    ];
    "oracle_seal", obj [
      "predictions_frozen_tick", i st.predictions_frozen_tick;
      "reveal_opened_tick", i o.reveal_tick;
      "ordering_ok", b (st.predictions_frozen_tick < o.reveal_tick);
      "reveal_access_log", arr (List.map (fun (pc, sf) ->
          obj [ "provider_class", s pc; "surface", s sf ])
          (List.rev st.reveal_access_log));
      "non_oracle_reveal_accesses",
        i (List.length (List.filter (fun (pc, _) -> pc <> "oracle") st.reveal_access_log));
      "note", s "only Oracle.revealAndCompare holds the oracle_reveal capability; \
                 every other step is linked with an oracle-free sandbox (Firewall B), \
                 and reveal is opened strictly after the predictions are frozen";
    ];
    "result", obj [
      "result_class", s v.result_class;
      "computed", b true;
      "admissible", b v.admissible;
      "oracle_run", b v.oracle_run;
      "rule", s "not admissible -> DECORATIVE_LIFT; else |C_train|=0 -> \
                 NO_REALIZATION_IN_MODEL; else oracle_run and separating and \
                 pass>=1 and tested_fiber=1 -> LIFT_VALIDATED; else |F_id|>=2 -> \
                 ASCENT_UNDERDETERMINED; else IDENTIFIED_IN_MODEL";
      "derived_from", arr (List.map s [
        "admissible"; "fit_candidate_count"; "oracle_run"; "heldout_is_separating";
        "oracle.pass_count"; "oracle.tested_fiber_size"; "identification_fiber_size";
      ]);
    ];
  ]

(* ─────────────────────────────── driver ──────────────────────────────── *)

let run ~case ~project_dir : J.t =
  Sha256.self_test ();
  let rr = resolve_run_request ~case ~project_dir in
  let ir = J.parse_file rr.ir_path in
  let pin = read_public_inputs rr in
  let pl = link ir in
  let st = fresh_state pin rr in
  execute st pl;
  let v = evaluate st in
  emit st pl v

(* Firewall B self-test: prove the sealed reveal is unreachable to a non-oracle
   capability and reachable only to the oracle one. Returns a report; raises if
   the firewall does NOT bite (a non-oracle read that succeeds is a failure). *)
let firewall_probe ~case ~project_dir : string =
  let rr = resolve_run_request ~case ~project_dir in
  let pin = read_public_inputs rr in
  let st = fresh_state pin rr in
  let denied =
    try
      ignore (read_sealed_reveal st ~provider_class:"descent"
                ~may_access:["heldout_input_query"]);
      false  (* should NOT reach here *)
    with Failure _ -> true
  in
  if not denied then
    failwith "FIREWALL BREACH: a non-oracle capability read the sealed reveal";
  (* the oracle capability may open it. *)
  let (_, rev) = read_sealed_reveal st ~provider_class:"oracle"
      ~may_access:["oracle_reveal"] in
  let out = J.to_string (J.member "heldout_output" rev) in
  Printf.sprintf
    "firewall B: non-oracle (descent) DENIED oracle_reveal = %b; \
     oracle ALLOWED, read heldout_output=%s; reveal_access_log entries: %d (all oracle)"
    denied out (List.length st.reveal_access_log)
