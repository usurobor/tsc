(* The Ascent-0 runtime: load the NormalizedCMIR, resolve a RunRequest for one
   case, LINK sandbox provider bindings into a SandboxExecutionPlan, EXECUTE the
   finite DAG (a step runs only when its typed inputs exist), INVOKE the provider
   backends, CAPTURE evidence, RETAIN candidate alternatives, EVALUATE the Result
   rule, and EMIT one MeasurementReceipt.

   Sub-3 wired ONE case (case1). Sub-4 (#122) wires ALL FIVE fixture cases to
   their required outcomes across TWO arms:

     - deterministic conformance arm: a CANNED #CompiledView proposal per case
       (fixtures/canned_compiled_view_<case>.json), so the categorical results
       are reproducible and failures are wiring/logic bugs.
     - blind live-LLM arm: an EXTERNALLY-supplied proposal (--proposal <path>),
       produced by a provider that saw ONLY the sanctioned one-POV semantic input
       (no withheld vocabulary, no oracle access). The runtime ingests the
       proposal and the mechanical backend earns or refuses the result exactly as
       in the deterministic arm.

   THE CRUX: the mechanical providers COMPUTE from the PUBLIC inputs. Nothing here
   reads the fixture's precomputed candidate sets / fibers / predictions (those
   are Sub-1's EXPECTED values). The only sealed datum is opened by the oracle
   backend alone, via the sandbox firewall, strictly AFTER the predictions are
   frozen. See `read_public_inputs` for the exact list of fields consumed.

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

type arm = Deterministic | Blind

let arm_tag = function Deterministic -> "deterministic_conformance" | Blind -> "blind_live_llm"

type run_request = {
  case_id       : string;
  case_short    : string;  (* case1 .. case5 *)
  case_dir      : string;   (* .../generated/cases/<case> *)
  class_path    : string;   (* .../generated/class.json *)
  reveal_path   : string;   (* .../generated/reveal/<case>.json  — SEALED (may be absent) *)
  ir_path       : string;
  view_path     : string;   (* canned deterministic #CompiledView (deterministic arm) *)
  arm           : arm;
  proposal_path : string option; (* blind arm: externally-supplied proposal *)
}

let case_map = function
  | "case1" -> "case1_lift_validated"
  | "case2" -> "case2_ascent_underdetermined"
  | "case3" -> "case3_no_realization_in_model"
  | "case4" -> "case4_decorative_lift"
  | "case5" -> "case5_roundtrip"
  | other -> other  (* accept full names too *)

let short_of = function
  | "case1_lift_validated" -> "case1"
  | "case2_ascent_underdetermined" -> "case2"
  | "case3_no_realization_in_model" -> "case3"
  | "case4_decorative_lift" -> "case4"
  | "case5_roundtrip" -> "case5"
  | other -> other

let resolve_run_request ~case ~project_dir ~arm ~proposal_path : run_request =
  let gen = fixture_generated () in
  let full = case_map case in
  let short = short_of full in
  let case_dir = Filename.concat gen (Filename.concat "cases" full) in
  if not (Sys.file_exists case_dir) then
    failwith (Printf.sprintf "unknown case %S (resolved dir %s absent)" case case_dir);
  {
    case_id = full;
    case_short = short;
    case_dir;
    class_path = Filename.concat gen "class.json";
    reveal_path = Filename.concat gen (Filename.concat "reveal" (full ^ ".json"));
    ir_path = Filename.concat project_dir "ir/ascent0.ir.json";
    view_path = Filename.concat project_dir
        (Printf.sprintf "fixtures/canned_compiled_view_%s.json" short);
    arm;
    proposal_path;
  }

(* ────────────────── the semantic PROPOSAL and its admissibility ─────────
   A proposal is the one semantic judgment's result: a closed five-field
   #CompiledView (Firewall A) PLUS a typed `generative_commitment` — the
   machine-ingestible witnesses the mechanical admissibility gate checks. The
   gate is STRUCTURAL (does the proposal present a typed generator that
   references the declared class and supply a prediction operator?), NOT prose
   aesthetics. A decorative proposal (no typed generator, no operator) fails the
   gate and is refused BEFORE any realization step runs. *)

type proposal = {
  view       : J.t;                 (* the closed five-field #CompiledView *)
  witnesses  : (string * bool) list;
  admissible : bool;
}

let str_present k obj =
  match J.member_opt k obj with
  | Some (J.Str s) -> String.length (String.trim s) > 0
  | _ -> false

let bool_field k obj =
  match J.member_opt k obj with Some (J.Bool b) -> b | _ -> false

let parse_proposal (raw : J.t) : proposal =
  let view =
    match J.member_opt "view" raw with
    | Some v -> v
    | None -> failwith "proposal: missing `view` (the #CompiledView)" in
  (* Firewall A shape: the view is EXACTLY the five proposal fields. *)
  let required = ["governing_question"; "preserved_local_claims";
                  "closure_assumption"; "polar_view"; "named_obstruction"] in
  List.iter (fun k -> ignore (J.member k view)) required;
  (match view with
   | J.Obj kvs when List.length kvs = 5 -> ()
   | _ -> failwith "proposal: #CompiledView must be exactly the five proposal fields (Firewall A)");
  let c =
    match J.member_opt "generative_commitment" raw with
    | Some v -> v
    | None -> failwith "proposal: missing `generative_commitment`" in
  let typed_gen = bool_field "presents_typed_generator" c in
  let op        = str_present "prediction_operator" c in
  let class_ref = str_present "generator_class_ref" c in
  let heldout_c = bool_field "commits_heldout_consequence" c in
  let dissolves = bool_field "dissolves_named_obstruction" c in
  (* Pre-realization admissibility = a typed generator that references the
     declared class AND supplies a prediction operator. The remaining two
     witnesses are recorded but do not gate admissibility (an admissible
     proposal may still lack a held-out consequence — cases 2 and 3). *)
  let admissible = typed_gen && op && class_ref in
  let witnesses = [
    "typed_generator_presentation", typed_gen;
    "prediction_operator", op;
    "admissible_realization_in_H_M", class_ref;
    "heldout_consequence", heldout_c;
    "obstruction_dissolution_witness", dissolves;
  ] in
  { view; witnesses; admissible }

let load_proposal (rr : run_request) : proposal =
  let path =
    match rr.arm, rr.proposal_path with
    | Blind, Some p -> p
    | Blind, None -> failwith "blind arm requires --proposal <path>"
    | Deterministic, _ -> rr.view_path
  in
  parse_proposal (J.parse_file path)

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
     expected_tested_fiber_size_after_reveal, inequivalent_class_count_over_U,
     fitting_candidate_count, enumerated_class_size, admissibility_gate_passed,
     required_witnesses, underlying_training_*, recovered_class_contains_hidden_machine,
     roundtrip_class_*, complete_candidate_set_size_*, fiber_over_U_*.
   Those are Sub-1's computed answers; this runtime recomputes them. *)

type public_inputs = {
  cfg          : Mealy.config;
  bounds_note  : string;
  traces       : Mealy.trace list;
  j_train      : string list;
  j_eval       : string list;
  heldout      : string option;
  commitment   : string option;   (* public commit digest, when the case has an oracle *)
  has_oracle   : bool;            (* commitment present AND the sealed reveal file exists *)
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
  let pub = J.parse_file (Filename.concat rr.case_dir "public.json") in
  (* Training traces: present for cases 1,2,3,5 (absent for the decorative case,
     whose subject is a prose proposal, not an observation set). A trace's reply
     is carried as `observed_reply` (cases 1,2,5) or `required_reply` (case 3,
     where the contradictory required replies are the whole point). *)
  let traces_json =
    match J.member_opt "training_traces" pub with Some (J.Arr l) -> l | _ -> [] in
  let reply_of t =
    match J.member_opt "observed_reply" t, J.member_opt "required_reply" t with
    | Some (J.Str s), _ -> s
    | _, Some (J.Str s) -> s
    | _ -> failwith "training trace: neither observed_reply nor required_reply" in
  let traces =
    List.map
      (fun t -> Mealy.trace_of_strings (J.to_string (J.member "input" t)) (reply_of t))
      traces_json
  in
  let heldout =
    match J.member_opt "heldout_query_public" pub with
    | Some (J.Str s) -> Some s | _ -> None in
  (* J_train / J_eval are DERIVED from the public inputs (the training inputs and
     the public held-out query), not read from the fixture's core_ir block. *)
  let j_train = List.map (fun t -> J.to_string (J.member "input" t)) traces_json in
  let j_eval = match heldout with Some h -> j_train @ [ h ] | None -> j_train in
  let commitment =
    match J.member_opt "oracle_commitment_sha256" pub with
    | Some (J.Str s) -> Some s | _ -> None in
  let has_oracle =
    commitment <> None && heldout <> None && Sys.file_exists rr.reveal_path in
  (* the one-POV behaviour-primary viewpoint — the leak-free semantic input. *)
  let viewpoint =
    let ic = open_in_bin (Filename.concat rr.case_dir "semantic_input.txt") in
    let len = in_channel_length ic in
    let s = really_input_string ic len in close_in ic; s
  in
  { cfg;
    bounds_note = Printf.sprintf "complete_within_bound(N=%d, |Sigma|=%d, |Gamma|=%d)"
        maxn sigma gamma;
    traces; j_train; j_eval; heldout; commitment; has_oracle; viewpoint }

(* ────────────────────────── the execution plan ───────────────────────── *)

type plan_step = {
  order          : int;
  step_id        : string;
  provider_class : string;
  provider_kind  : string;
  kind           : string;
  reads          : string list;
  produces       : string list;  (* surfaces this step CAN make present *)
  may_access     : string list;  (* sealed surfaces the sandbox grants (firewall) *)
  search_strength: string;
}

type plan = { cm_id : string; cm_version : string; source_digest : string;
              steps : plan_step list }

(* surfaces a step CAN produce (authoritative for DAG gating; the IR `produces`
   is the single-valued hint, the plan is the linked truth). The semantic step's
   admissibility gate is a capability it CAN emit (admissible_proposal); whether
   it actually emits it is decided at execute time by the gate. *)
let produced_by = function
  | "semantic" -> ["compiled_view"; "admissible_proposal"]
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
  prop : proposal;
  mutable present : string list;              (* surfaces available *)
  mutable clock : int;
  mutable events : (int * string * string) list;
  mutable exec_order : (int * string) list;
  mutable skipped : (string * string list) list;   (* step_id, missing surfaces *)
  mutable reveal_access_log : (string * string) list;
  (* produced artifacts *)
  mutable admissible : bool;
  mutable search_ran : bool;
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

let fresh_state pin rr prop = {
  pin; rr; prop;
  present = []; clock = 0; events = []; exec_order = []; skipped = [];
  reveal_access_log = [];
  admissible = false; search_ran = false;
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
(* A backend returns the surfaces it ACTUALLY produced (dynamic), which may be a
   subset of the step's plan `produces` — the semantic gate withholds
   admissible_proposal on a decorative proposal. *)

let backend (st : state) (ps : plan_step) : string list =
  let cfg = st.pin.cfg in
  match ps.step_id with
  | "semantic" ->
    (* The one semantic judgment, ingested as a PROPOSAL (canned in the
       deterministic arm; externally supplied in the blind arm). It owns no H_M
       and carries no warrant. The admissibility gate decides whether it yields
       the admissible_proposal capability the realization steps require. *)
    st.compiled_view <- Some st.prop.view;
    st.admissible <- st.prop.admissible;
    ignore (tick st);
    log st ps.step_id
      (Printf.sprintf "compiled_view_proposed admissible=%b (witnesses: %s)"
         st.admissible
         (String.concat "," (List.map (fun (n,p) -> Printf.sprintf "%s=%b" n p) st.prop.witnesses)));
    if st.admissible then ["compiled_view"; "admissible_proposal"] else ["compiled_view"]
  | "finite_model_enumerate" ->
    (* Genuine complete bounded enumeration over H_M. *)
    st.klass <- Mealy.enumerate cfg;
    st.search_ran <- true;
    ignore (tick st);
    log st ps.step_id (Printf.sprintf "enumerated_%d_machines" (List.length st.klass));
    ps.produces
  | "realization_fit" ->
    (* Genuine exact-fit partition (L_M = 0) over the enumerated class. *)
    st.fit <- Mealy.fit cfg st.klass st.pin.traces;
    ignore (tick st);
    log st ps.step_id (Printf.sprintf "fit_%d_of_%d"
                         (List.length st.fit) (List.length st.klass));
    ps.produces
  | "realization_quotient" ->
    (* Genuine quotient F_id = C_train / ~=^U. *)
    st.id_fiber <- Mealy.fiber cfg st.fit (Mealy.universe cfg);
    ignore (tick st);
    log st ps.step_id (Printf.sprintf "identification_fiber_%d_classes"
                         (List.length st.id_fiber));
    ps.produces
  | "descent_predict" ->
    (* Genuine descent: run each surviving candidate's transition law on the
       PUBLIC held-out query. Predictions are then FROZEN (before any reveal). *)
    let heldout = match st.pin.heldout with
      | Some h -> h | None -> failwith "descent: no held-out query present" in
    let preds =
      List.map (fun fc -> (fc, Mealy.run_str cfg fc.Mealy.repr heldout)) st.id_fiber
    in
    st.predictions <- preds;
    st.distinct_predictions <- List.sort_uniq compare (List.map snd preds);
    st.separating <- List.length st.distinct_predictions >= 2;
    st.predictions_frozen_tick <- tick st;
    log st ps.step_id
      (Printf.sprintf "predictions_frozen (%d classes, distinct=%s, separating=%b)"
         (List.length preds) (String.concat "," st.distinct_predictions) st.separating);
    ps.produces
  | "oracle_reveal_compare" ->
    (* Firewall B + ordering: predictions must already be frozen. *)
    if st.predictions_frozen_tick = 0 then
      failwith "oracle: predictions are not frozen; reveal refused (ordering)";
    let commitment = match st.pin.commitment with
      | Some c -> c | None -> failwith "oracle: no public commitment present" in
    let (raw, rev) = read_sealed_reveal st ~provider_class:ps.provider_class
        ~may_access:ps.may_access in
    let recomputed = Sha256.digest_string raw in
    let commitment_verified = String.equal recomputed commitment in
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
         (List.length tested_fiber));
    ps.produces
  | "roundtrip_check" ->
    (* Fold the oracle-confirmed continuation (q*, revealed_output) back in,
       re-fit, re-quotient over J_eval; report the round-trip class. *)
    (match st.oracle, st.pin.heldout with
     | None, _ -> failwith "roundtrip: no oracle outcome to fold"
     | _, None -> failwith "roundtrip: no held-out query"
     | Some o, Some heldout ->
       let augmented =
         st.pin.traces @ [ Mealy.trace_of_strings heldout o.revealed_output ] in
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
            st.roundtrip_fit st.roundtrip_fiber st.roundtrip_contains_hidden));
    ps.produces
  | other -> failwith ("unknown step " ^ other)

(* ───────────────── EXECUTE: run the DAG by input readiness ────────────── *)

let execute (st : state) (pl : plan) : unit =
  (* Seed the base surfaces produced by RunRequest resolution. The one-POV
     viewpoint, training traces, and the public methodology contract are always
     present; the held-out query and the oracle surfaces are seeded ONLY when the
     case supplies them, so steps depending on an absent surface are principled
     skips (recorded in the receipt), not silent failures. *)
  st.present <- [
    "one_pov_behavior_primary_viewpoint"; "training_traces";
    "public_methodology_contract"; "H_M_declaration"; "search_bounds";
    "equivalence_relation";
  ];
  (match st.pin.heldout with Some _ -> st.present <- st.present @ ["heldout_input_query"] | None -> ());
  if st.pin.has_oracle then
    st.present <- st.present @ ["oracle_commitment"; "oracle_reveal_bundle"];
  let remaining = ref pl.steps in
  let ran = ref true in
  while !remaining <> [] && !ran do
    ran := false;
    (* pick the first step (IR order) whose typed inputs all exist. *)
    (match List.find_opt
             (fun s -> List.for_all (fun r -> List.mem r st.present) s.reads)
             !remaining with
     | None -> ()  (* stuck; loop exits, unrun steps become principled skips *)
     | Some s ->
       let produced = backend st s in
       st.exec_order <- (List.length st.exec_order, s.step_id) :: st.exec_order;
       st.present <- st.present @ produced;
       remaining := List.filter (fun x -> x.step_id <> s.step_id) !remaining;
       ran := true)
  done;
  (* Any step still unrun is a principled skip: record it with the surfaces it
     was missing, so a reviewer can confirm each skip is an absent case surface
     (no held-out / no oracle / a withheld admissible_proposal), not a bug. *)
  st.skipped <-
    List.map
      (fun s -> (s.step_id, List.filter (fun r -> not (List.mem r st.present)) s.reads))
      !remaining

(* ─────────────────────── EVALUATE the Result rule ─────────────────────── *)

type verdict = { result_class : string; admissible : bool; oracle_run : bool; search_ran : bool }

let evaluate (st : state) : verdict =
  (* admissible is a property of the PROPOSAL (a valid typed generator with a
     prediction operator was witnessed), decoupled from fit — exactly as the
     frozen Sub-1 Result rule requires. A decorative proposal is refused BEFORE
     realization (the admissibility gate withheld the admissible_proposal
     capability, so no search ran). *)
  let admissible = st.admissible in
  let search_ran = st.search_ran in
  let oracle_run = st.oracle <> None in
  let f_id = List.length st.id_fiber in
  (* internal consistency: an admissible proposal MUST have run the search;
     otherwise the DAG stalled on a real wiring bug and we refuse to mislabel it. *)
  if admissible && not search_ran then
    failwith "evaluate: admissible proposal but the bounded search never ran (wiring bug)";
  let rc =
    if not admissible then "DECORATIVE_LIFT"            (* refused before realization *)
    else if search_ran && List.length st.fit = 0 then "NO_REALIZATION_IN_MODEL"
    else begin
      match st.oracle with
      | Some o when oracle_run && st.separating
                  && List.length o.pass_classes >= 1
                  && o.tested_fiber_size = 1 -> "LIFT_VALIDATED"
      | _ -> if f_id >= 2 then "ASCENT_UNDERDETERMINED" else "IDENTIFIED_IN_MODEL"
    end
  in
  { result_class = rc; admissible; oracle_run; search_ran }

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
  let plan_j = plan_json pl in
  let events = List.rev st.events in
  let compiled_view = match st.compiled_view with Some v -> v | None -> obj [] in
  let fiber_entry fc predicted =
    obj [ "representative", s fc.Mealy.repr_id;
          "predicted_on_heldout", s predicted;
          "member_count", i (List.length fc.Mealy.members) ] in
  (* oracle / round-trip derivation blocks appear ONLY when the oracle ran. *)
  let oracle_block, roundtrip_block, oracle_seal_block =
    match st.oracle with
    | None -> [], [], []
    | Some o ->
      let ob = [ "oracle", obj [
          "reveal_path", s st.rr.reveal_path;
          "public_commitment_sha256", s (Option.value ~default:"" st.pin.commitment);
          "recomputed_reveal_sha256", s o.reveal_recomputed_sha;
          "commitment_verified", b o.commitment_verified;
          "revealed_output", s o.revealed_output;
          "hidden_machine_canonical_id", s o.hidden_id;
          "pass_count", i (List.length o.pass_classes);
          "fail_count", i (List.length o.fail_classes);
          "tested_fiber_size", i o.tested_fiber_size;
          "recovered_class_contains_hidden_machine", b o.contains_hidden;
        ] ] in
      let rb = [ "roundtrip", obj [
          "augmented_fit_count", i st.roundtrip_fit;
          "fiber_over_J_eval_size", i st.roundtrip_fiber;
          "contains_hidden_machine", b st.roundtrip_contains_hidden;
          "equivalence_scope", s "Ascend(D_train U Descend(W,q*)) ~= W under the \
                                  declared behavioural equivalence over J_eval within \
                                  the bounded class (scoped identification, NOT absolute \
                                  identity): the round-trip class is the SINGLE J_eval \
                                  equivalence class that contains the hidden machine";
        ] ] in
      let sb = [ "oracle_seal", obj [
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
        ] ] in
      ob, rb, sb
  in
  let pass_repr = match st.oracle with
    | Some o -> List.map (fun fc -> fc.Mealy.repr_id) o.pass_classes | None -> [] in
  let fail_repr = match st.oracle with
    | Some o -> List.map (fun fc -> fc.Mealy.repr_id) o.fail_classes | None -> [] in
  obj [
    "format", s "tsc-ascent0-receipt/0.1";
    "cm_id", s pl.cm_id;
    "cm_version", s pl.cm_version;
    "source_digest", s pl.source_digest;
    "run_request", obj [
      "case", s st.rr.case_id;
      "arm", s (arm_tag st.rr.arm);
      "heldout_query", s (Option.value ~default:"" st.pin.heldout);
      "fixture_case_dir", s st.rr.case_dir;
    ];
    "plan_digest", s ("sha256:" ^ J.digest plan_j);
    "sandbox_execution_plan", plan_j;
    "compiled_view", compiled_view;
    "admissibility", obj [
      "admissible", b st.admissible;
      "gate", s "a proposal is admissible iff it presents a typed generator that \
                 references the declared class AND supplies a prediction operator; \
                 an admissible proposal yields the admissible_proposal capability that \
                 finite_model_enumerate reads, so a decorative proposal is refused \
                 BEFORE realization (no search runs)";
      "witnesses", arr (List.map (fun (n, p) ->
          obj [ "witness", s n; "present", b p ]) st.prop.witnesses);
    ];
    "execution_trace", arr (List.map (fun (order, sid) ->
        obj [ "order", i order; "step_id", s sid ]) (List.rev st.exec_order));
    "skipped_steps", arr (List.map (fun (sid, missing) ->
        obj [ "step_id", s sid; "missing_surfaces", arr (List.map s missing) ]) st.skipped);
    "event_log", arr (List.map (fun (tk, sid, ev) ->
        obj [ "tick", i tk; "step_id", s sid; "event", s ev ]) events);
    "derivation", obj ([
      "enumerated_class_size", i (List.length st.klass);
      "search_claim", s st.pin.bounds_note;
      "search_ran", b st.search_ran;
      "fit_candidate_count", i (List.length st.fit);
      "identification_fiber_size", i (List.length st.id_fiber);
      "heldout_query", s (Option.value ~default:"" st.pin.heldout);
      "heldout_distinct_predictions", arr (List.map s st.distinct_predictions);
      "heldout_is_separating", b st.separating;
    ] @ oracle_block @ roundtrip_block);
    "retained_alternatives", obj [
      "policy", s "the executor retains every surviving alternative up to the \
                   Result rule; it never collapses a multi-candidate fiber before evaluate";
      "identification_fiber", arr
        (List.map (fun (fc, p) -> fiber_entry fc p) st.predictions);
      "pass_partition", arr (List.map s pass_repr);
      "fail_partition", arr (List.map s fail_repr);
      "retained_before_result_rule", i (List.length st.id_fiber);
    ];
  ] |> fun base ->
  (* append the oracle_seal only when the oracle ran (top-level optional). *)
  (match base with
   | J.Obj kvs -> J.Obj (kvs @ oracle_seal_block @ [
       "result", obj [
         "result_class", s v.result_class;
         "computed", b true;
         "admissible", b v.admissible;
         "oracle_run", b v.oracle_run;
         "search_ran", b v.search_ran;
         "rule", s "not admissible -> DECORATIVE_LIFT; else search_ran and |C_train|=0 -> \
                    NO_REALIZATION_IN_MODEL; else oracle_run and separating and \
                    pass>=1 and tested_fiber=1 -> LIFT_VALIDATED; else |F_id|>=2 -> \
                    ASCENT_UNDERDETERMINED; else IDENTIFIED_IN_MODEL";
         "derived_from", arr (List.map s [
           "admissible"; "search_ran"; "fit_candidate_count"; "oracle_run";
           "heldout_is_separating"; "oracle.pass_count"; "oracle.tested_fiber_size";
           "identification_fiber_size";
         ]);
       ];
     ])
   | other -> other)

(* ─────────────────────────────── driver ──────────────────────────────── *)

let run ~case ~project_dir ~arm ~proposal_path : J.t =
  Sha256.self_test ();
  let rr = resolve_run_request ~case ~project_dir ~arm ~proposal_path in
  let ir = J.parse_file rr.ir_path in
  let pin = read_public_inputs rr in
  let prop = load_proposal rr in
  let pl = link ir in
  let st = fresh_state pin rr prop in
  execute st pl;
  let v = evaluate st in
  emit st pl v

(* The exact sanctioned prompt the runtime emits for the BLIND arm: the one-POV
   semantic input verbatim (leak-checked against the withheld vocabulary), plus
   the required output schema. A blind provider agent receives ONLY this; it has
   no access to the fixture answer key, the sealed oracle, or the withheld terms.
   Its reply is ingested via `--proposal <path>` and mechanically earned/refused. *)
let withheld_terms =
  [ "source"; "transition law"; "finite-state machine"; "finite state machine";
    "mealy"; "hidden generator" ]

let contains_ci hay needle =
  let h = String.lowercase_ascii hay and n = String.lowercase_ascii needle in
  let lh = String.length h and ln = String.length n in
  let rec go k = if k + ln > lh then false
                 else if String.sub h k ln = n then true else go (k + 1) in
  go 0

let blind_prompt ~case ~project_dir : string =
  let rr = resolve_run_request ~case ~project_dir ~arm:Blind ~proposal_path:None in
  let pin = read_public_inputs rr in
  (* leak guard: the sanctioned input must not contain any withheld term. *)
  List.iter (fun t ->
      if contains_ci pin.viewpoint t then
        failwith (Printf.sprintf
                    "BLIND-PROMPT ABORT: withheld term %S present in the sanctioned input" t))
    withheld_terms;
  String.concat "\n" [
    "=== ASCENT-0 BLIND SEMANTIC INPUT (the ONLY context the provider may use) ===";
    pin.viewpoint;
    "=== REQUIRED OUTPUT (JSON; nothing else) ===";
    "Return exactly this shape (the mechanical backend earns or refuses it):";
    "{";
    "  \"view\": {";
    "    \"governing_question\": string,";
    "    \"preserved_local_claims\": [string, ...],";
    "    \"closure_assumption\": string,";
    "    \"polar_view\": string,";
    "    \"named_obstruction\": string";
    "  },";
    "  \"generative_commitment\": {";
    "    \"presents_typed_generator\": bool,";
    "    \"generator_class_ref\": string | null,";
    "    \"prediction_operator\": string | null,";
    "    \"commits_heldout_consequence\": bool,";
    "    \"dissolves_named_obstruction\": bool";
    "  }";
    "}";
    "Constraints: propose only from the viewpoint above. Do NOT assume any";
    "vocabulary that was not given to you. You have no access to any answer key,";
    "expected result, or sealed continuation.";
  ]

(* Firewall B self-test: prove the sealed reveal is unreachable to a non-oracle
   capability and reachable only to the oracle one. Returns a report; raises if
   the firewall does NOT bite (a non-oracle read that succeeds is a failure). *)
let firewall_probe ~case ~project_dir : string =
  let rr = resolve_run_request ~case ~project_dir ~arm:Deterministic ~proposal_path:None in
  let pin = read_public_inputs rr in
  let prop = load_proposal rr in
  let st = fresh_state pin rr prop in
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
