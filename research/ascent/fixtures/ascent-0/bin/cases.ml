(* The five fixture cases. This module defines ONLY the scenario *inputs*
   (a hidden machine where one exists, the training split, the held-out
   query, a decorative prose proposal). Every load-bearing number — the
   complete candidate set, the fibers, the separating predictions, the
   cardinalities, and the resulting category — is DERIVED here by the
   Mealy enumeration, never written by hand. Emit-time assertions prove the
   derived category equals the case's designed expectation. *)

open Mealy
open Serialize

(* Frozen configuration: the SMALLEST object the five cases demonstrate.
   See minimality_doc for the mechanical proof that N=1, |Gamma|=1, and
   |Sigma|=1 each fail to demonstrate a required obligation. *)
let cfg = { sigma = 2; gamma = 2; maxn = 2; ulen = 3 }

(* One hard-coded master seed; each case's salt is derived from it by
   hashing, so no salt is hand-typed and replay is deterministic. The salt
   is a domain-separating nonce, NOT a secret (see README "Sealing"). *)
let master_seed = "ascent-0|source-equiv-behavior|salt-domain|v1"
let salt_for (case : string) : string =
  Sha256.digest_string (master_seed ^ "|" ^ case)

(* The latch W: reply is 1 iff at least one 'a' has occurred strictly
   before the current position; state 0 = "no a yet", state 1 = "a seen". *)
let w_latch = { n = 2; tbl = [| (1, 0); (0, 0); (1, 1); (1, 1) |] }

let tr = trace_of_strings

(* ---- invariant-1 guard: withheld vocabulary must not reach the semantic
   input (the only semantic-facing artifact). ---- *)
let forbidden_terms =
  [ "source"; "transition law"; "finite-state machine"; "finite state machine";
    "mealy"; "hidden generator" ]

let contains_ci (hay : string) (needle : string) : bool =
  let h = String.lowercase_ascii hay and n = String.lowercase_ascii needle in
  let lh = String.length h and ln = String.length n in
  let rec go i = if i + ln > lh then false
                 else if String.sub h i ln = n then true else go (i + 1) in
  go 0

let assert_leakfree (label : string) (s : string) : unit =
  List.iter
    (fun t ->
       if contains_ci s t then
         failwith (Printf.sprintf
                     "invariant-1 violation in %s: withheld term %S present" label t))
    forbidden_terms

(* ---- JSON encoders for machines and fibers ---- *)

let table_json (m : machine) : json =
  let rows = ref [] in
  for s = m.n - 1 downto 0 do
    for i = cfg.sigma - 1 downto 0 do
      let (d, l) = m.tbl.(s * cfg.sigma + i) in
      rows :=
        Obj [ ("state", Int s);
              ("input", Str (String.make 1 (in_sym i)));
              ("next_state", Int d);
              ("output", Str (String.make 1 (out_sym l))) ] :: !rows
    done
  done;
  Arr !rows

let machine_json (m : machine) : json =
  Obj [ ("states", Int m.n);
        ("initial_state", Int 0);
        ("canonical_id", Str (canonical_id cfg m));
        ("transition_output_table", table_json m) ]

let query_json (u : int array) : json = Str (str_of_inputs u)

let fiber_class_json ?(heldout : int array option) (fc : fiber_class) : json =
  let base =
    [ ("representative_canonical_id", Str fc.repr_id);
      ("complexity_K_M", Int (complexity fc.repr));
      ("behavior_signature_over_U", Str fc.sig_);
      ("member_count", Int (List.length fc.members));
      ("member_canonical_ids", Arr (List.map (fun s -> Str s) fc.members)) ]
  in
  let base =
    match heldout with
    | None -> base
    | Some q ->
      base
      @ [ ("frozen_prediction_on_heldout",
           Str (str_of_outputs (run cfg fc.repr q))) ]
  in
  Obj base

(* ---- the FROZEN Result rule (also stated verbatim in the README).
   The category is a pure function of the derived facts. ---- *)
type facts = {
  admissible : bool;         (* passed pre-search admissibility (typed generator + prediction operator) *)
  c_train_size : int;        (* |C_train| after complete bounded search; -1 if refused pre-search *)
  f_id_size : int;           (* |C_train / ~=^U| ; -1 if n/a *)
  oracle_run : bool;         (* a sealed held-out oracle is part of the case *)
  separating : bool;         (* held-out yields >= 2 distinct predictions across the fiber *)
  pass_count : int;          (* candidates predicting the revealed output *)
  tested_fiber_size : int;   (* |C_pass / ~=^J_eval| after reveal *)
}

let result_rule (f : facts) : string =
  if not f.admissible then "DECORATIVE_LIFT"
  else if f.c_train_size = 0 then "NO_REALIZATION_IN_MODEL"
  else if f.oracle_run && f.separating && f.pass_count >= 1 && f.tested_fiber_size = 1
  then "LIFT_VALIDATED"
  else if f.f_id_size >= 2 then "ASCENT_UNDERDETERMINED"
  else "IDENTIFIED_IN_MODEL"

(* ---- semantic input (leak-free, behavior-primary, one POV) ---- *)

let obs_block (traces : trace list) : string =
  String.concat "\n"
    (List.map
       (fun t ->
          Printf.sprintf "  input \"%s\"  ->  reply \"%s\""
            (str_of_inputs t.input) (str_of_outputs t.output))
       traces)

let semantic_input ~(traces : trace list) ~(heldout : int array option) : string =
  let head =
    "VIEWPOINT (one point of view)\n\
    \  This component is a black box. The only account of it you are given is\n\
    \  the finite list of input/response observations below. You send it an\n\
    \  input word over the symbols {a, b}; it answers with one reply symbol\n\
    \  (0 or 1) for each input symbol you send. Treat the observations below as\n\
    \  the complete account of what the component is.\n\n\
     OBSERVATIONS (the given account, in full)\n"
  in
  let tail =
    match heldout with
    | Some q ->
      Printf.sprintf
        "\n\nINTENT\n\
        \  Give the most complete account you can of what this component is, and\n\
        \  predict its reply to the input word \"%s\", which does not appear above.\n"
        (str_of_inputs q)
    | None ->
      "\n\nINTENT\n\
      \  Give the most complete account you can of what this component is.\n"
  in
  head ^ obs_block traces ^ tail

(* common IR block for a realizable case *)
let core_ir ~(jtrain : int array list) ~(jeval : int array list)
    ~(oracle : string) ~(fiber_ref : string) ~(empty_ref : string) : json =
  Obj [
    ("H_M",
     Str "deterministic pointed Mealy transducers with 1..N states over \
          Sigma,Gamma; canonical enumeration in class.json");
    ("SearchClaim", Str "complete_within_bound(N=2, |Sigma|=2, |Gamma|=2)");
    ("joint_realization",
     Str "generator G in H_M with the identity observation atlas: each \
          candidate directly predicts the reply word for an input history; \
          the atlas is trivial and retained");
    ("equivalence",
     Str "behavioral equivalence ~=^J: identical reply word on every query in \
          the indexing family J; refinement-monotone (wider J refines finer)");
    ("L_M",
     Str "count of training traces whose predicted reply word differs from the \
          observed reply word; admissible fit bound tau_M = 0 (exact)");
    ("K_M", Str "generator state count; admissible complexity bound kappa_M = N = 2");
    ("J_train", Arr (List.map query_json jtrain));
    ("J_eval", Arr (List.map query_json jeval));
    ("oracle", Str oracle);
    ("candidate_fiber", Str fiber_ref);
    ("empty_or_unresolved_set", Str empty_ref);
  ]

(* ============================ CASE 1 ============================ *)
(* Validated held-out descent -> LIFT_VALIDATED. Training leaves a fiber the
   held-out input "ab" separates; the recovered candidate predicts the sealed
   output; predicted = actual. "ab" is out-of-fit and input-indexed (it tests
   the reply after an 'a' followed by a 'b', a context absent from training). *)

let build_case1 () =
  let name = "case1_lift_validated" in
  let d = [ tr "a" "0"; tr "aa" "01"; tr "b" "0"; tr "ba" "00" ] in
  let heldout = inputs_of_str "ab" in
  let c_train = fit_candidates cfg d in
  let u = universe cfg in
  let fib_u = fiber cfg c_train u in
  let jtrain = List.map (fun t -> t.input) d in
  let jeval = jtrain @ [ heldout ] in
  let preds = distinct_predictions cfg fib_u heldout in
  let separating = List.length preds >= 2 in
  let actual = str_of_outputs (run cfg w_latch heldout) in
  let c_pass = List.filter (fun m -> str_of_outputs (run cfg m heldout) = actual) c_train in
  let c_fail = List.filter (fun m -> str_of_outputs (run cfg m heldout) <> actual) c_train in
  let f_eval_split = fiber cfg c_train jeval in            (* held-out splits training class *)
  let tested = fiber cfg c_pass jeval in
  let w_in_pass = List.exists (fun m -> canonical_id cfg m = canonical_id cfg w_latch) c_pass in
  let facts = {
    admissible = true;
    c_train_size = List.length c_train;
    f_id_size = List.length fib_u;
    oracle_run = true;
    separating;
    pass_count = List.length c_pass;
    tested_fiber_size = List.length tested;
  } in
  let derived = result_rule facts in
  if derived <> "LIFT_VALIDATED" then
    failwith (Printf.sprintf "case1 derived %s <> LIFT_VALIDATED" derived);
  if not w_in_pass then failwith "case1: W not among passing candidates";
  let salt = salt_for name in
  let reveal =
    Obj [ ("case", Str name);
          ("hidden_machine", machine_json w_latch);
          ("heldout_query", Str (str_of_inputs heldout));
          ("heldout_output", Str actual);
          ("salt", Str salt);
          ("note",
           Str "revealed only after predictions are frozen; the runtime (Sub 3) \
                may read this bundle only via a dedicated oracle step") ]
  in
  let reveal_doc = document reveal in
  let commitment = Sha256.digest_string reveal_doc in
  let sem = semantic_input ~traces:d ~heldout:(Some heldout) in
  assert_leakfree (name ^ "/semantic_input") sem;
  let public =
    Obj [
      ("case", Str name);
      ("expected_result", Str "LIFT_VALIDATED");
      ("derived_result", Str derived);
      ("purpose", Str "a genuinely new (held-out, out-of-fit) articulation is \
                       generated and validated by the sealed oracle");
      ("training_traces",
       Arr (List.map (fun t ->
           Obj [ ("input", Str (str_of_inputs t.input));
                 ("observed_reply", Str (str_of_outputs t.output)) ]) d));
      ("heldout_query_public", Str (str_of_inputs heldout));
      ("heldout_is_out_of_fit",
       Bool (not (List.exists (fun t -> t.input = heldout) d)));
      ("complete_candidate_set_size", Int (List.length c_train));
      ("training_identification_fiber_over_U", Int (List.length fib_u));
      ("training_fiber_over_J_train", Int (List.length (fiber cfg c_train jtrain)));
      ("heldout_distinct_predictions", Arr (List.map (fun s -> Str s) preds));
      ("heldout_is_separating", Bool separating);
      ("fiber_split_by_heldout_over_J_eval", Int (List.length f_eval_split));
      ("expected_pass_count", Int (List.length c_pass));
      ("expected_fail_count", Int (List.length c_fail));
      ("expected_tested_fiber_size_after_reveal", Int (List.length tested));
      ("recovered_class_contains_hidden_machine", Bool w_in_pass);
      ("oracle_commitment_sha256", Str commitment);
      ("oracle_commitment_formula",
       Str "sha256( canonical_document( reveal/case1_lift_validated.json ) )");
      ("candidate_fiber_over_U",
       Arr (List.map (fiber_class_json ~heldout) fib_u));
      ("core_ir",
       core_ir ~jtrain ~jeval
         ~oracle:"commit/reveal sealed held-out; commitment above, reveal bundle separate"
         ~fiber_ref:"candidate_fiber_over_U"
         ~empty_ref:"C_fail (candidates refuted by the held-out) has size expected_fail_count");
    ]
  in
  (name, sem, public, Some ("case1_lift_validated.json", reveal))

(* ============================ CASE 2 ============================ *)
(* Underdetermined -> ASCENT_UNDERDETERMINED. Too few traces; the complete
   bounded search retains >= 2 inequivalent candidates and NO separating
   oracle is run. Two of equal complexity are exhibited with the query that
   distinguishes them (so complexity cannot break the tie). *)

let build_case2 () =
  let name = "case2_ascent_underdetermined" in
  let d = [ tr "a" "0"; tr "b" "0" ] in
  let c_train = fit_candidates cfg d in
  let u = universe cfg in
  let fib_u = fiber cfg c_train u in
  let jtrain = List.map (fun t -> t.input) d in
  (* exhibit two inequivalent classes of equal complexity + a witness query *)
  let pair =
    let rec find = function
      | a :: rest ->
        (match List.find_opt (fun b -> complexity a.repr = complexity b.repr) rest with
         | Some b -> (a, b)
         | None -> find rest)
      | [] -> failwith "case2: no equal-complexity inequivalent pair"
    in find fib_u
  in
  let (ca, cb) = pair in
  let witness =
    match List.find_opt (fun q -> run cfg ca.repr q <> run cfg cb.repr q) u with
    | Some q -> q
    | None -> failwith "case2: exhibited pair does not differ on U"
  in
  let facts = {
    admissible = true;
    c_train_size = List.length c_train;
    f_id_size = List.length fib_u;
    oracle_run = false;
    separating = false;
    pass_count = 0;
    tested_fiber_size = -1;
  } in
  let derived = result_rule facts in
  if derived <> "ASCENT_UNDERDETERMINED" then
    failwith (Printf.sprintf "case2 derived %s <> ASCENT_UNDERDETERMINED" derived);
  let sem = semantic_input ~traces:d ~heldout:None in
  assert_leakfree (name ^ "/semantic_input") sem;
  let public =
    Obj [
      ("case", Str name);
      ("expected_result", Str "ASCENT_UNDERDETERMINED");
      ("derived_result", Str derived);
      ("purpose", Str ">= 2 inequivalent candidates survive a complete bounded \
                       search; no tie-break is provided");
      ("training_traces",
       Arr (List.map (fun t ->
           Obj [ ("input", Str (str_of_inputs t.input));
                 ("observed_reply", Str (str_of_outputs t.output)) ]) d));
      ("complete_candidate_set_size", Int (List.length c_train));
      ("inequivalent_class_count_over_U", Int (List.length fib_u));
      ("no_oracle_run", Bool true);
      ("exhibited_inequivalent_pair",
       Obj [ ("candidate_A", machine_json ca.repr);
             ("candidate_B", machine_json cb.repr);
             ("equal_complexity_K_M", Int (complexity ca.repr));
             ("distinguishing_query_not_in_training", Str (str_of_inputs witness));
             ("A_reply_on_query", Str (str_of_outputs (run cfg ca.repr witness)));
             ("B_reply_on_query", Str (str_of_outputs (run cfg cb.repr witness)));
             ("both_fit_training", Bool (fits cfg ca.repr d && fits cfg cb.repr d)) ]);
      ("candidate_fiber_over_U", Arr (List.map (fiber_class_json ?heldout:None) fib_u));
      ("core_ir",
       core_ir ~jtrain ~jeval:jtrain
         ~oracle:"none (no held-out oracle run; identification stays underdetermined)"
         ~fiber_ref:"candidate_fiber_over_U"
         ~empty_ref:"none (fiber is non-empty and non-singleton)");
    ]
  in
  (name, sem, public, None)

(* ============================ CASE 3 ============================ *)
(* No realization -> NO_REALIZATION_IN_MODEL. Contradictory deterministic
   evidence: the same input history "a" is required to reply both "0" and
   "1". A deterministic transducer maps a fixed input history to a unique
   reply word, so NO machine of any size within the bound realizes both; the
   exhaustive search confirms an empty candidate set — distinct from
   UNRESOLVED (incomplete search) and UNDERDETERMINED (multiple classes). *)

let build_case3 () =
  let name = "case3_no_realization_in_model" in
  let d = [ tr "a" "0"; tr "a" "1" ] in
  let c_train = fit_candidates cfg d in
  let facts = {
    admissible = true;
    c_train_size = List.length c_train;
    f_id_size = 0;
    oracle_run = false;
    separating = false;
    pass_count = 0;
    tested_fiber_size = -1;
  } in
  let derived = result_rule facts in
  if derived <> "NO_REALIZATION_IN_MODEL" then
    failwith (Printf.sprintf "case3 derived %s <> NO_REALIZATION_IN_MODEL" derived);
  let sem = semantic_input ~traces:d ~heldout:None in
  assert_leakfree (name ^ "/semantic_input") sem;
  let public =
    Obj [
      ("case", Str name);
      ("expected_result", Str "NO_REALIZATION_IN_MODEL");
      ("derived_result", Str derived);
      ("purpose", Str "a complete search over the whole bounded class yields an \
                       EMPTY candidate set; empty-after-complete-search is not \
                       collapsed into uncertainty");
      ("training_traces",
       Arr (List.map (fun t ->
           Obj [ ("input", Str (str_of_inputs t.input));
                 ("required_reply", Str (str_of_outputs t.output)) ]) d));
      ("contradiction",
       Str "input history \"a\" is required to reply both \"0\" and \"1\"");
      ("enumerated_class_size", Int (class_size cfg));
      ("fitting_candidate_count", Int (List.length c_train));
      ("completeness_argument",
       Str "SearchClaim = complete_within_bound(N=2,|Sigma|=2,|Gamma|=2): every \
            machine in the class was enumerated and none fits. Independently: a \
            deterministic pointed transducer sends a fixed input history to a \
            unique reply word from the fixed initial state, so two distinct \
            required replies for the same history are unrealizable at ANY state \
            count. Hence NO_REALIZATION_IN_MODEL, not UNRESOLVED.");
      ("distinct_from",
       Obj [ ("UNRESOLVED", Str "would require an INCOMPLETE search; here the search is complete");
             ("ASCENT_UNDERDETERMINED", Str "would require >= 1 fitting candidate; here there are 0") ]);
      ("core_ir",
       core_ir ~jtrain:(List.map (fun t -> t.input) d) ~jeval:(List.map (fun t -> t.input) d)
         ~oracle:"none"
         ~fiber_ref:"empty"
         ~empty_ref:"C_fit is empty (0 of enumerated_class_size machines fit)");
    ]
  in
  (name, sem, public, None)

(* ============================ CASE 4 ============================ *)
(* Decorative -> DECORATIVE_LIFT. A fluent proposed whole that is refused
   BEFORE realization for lacking a typed generator presentation, a
   prediction operator, an admissible realization in H_M, an
   obstruction-dissolution witness, and a held-out consequence. It never
   enters the fiber. The underlying training {a:0} IS realizable, so the
   refusal concerns the PROPOSAL, not the data (distinct from case 3). *)

let build_case4 () =
  let name = "case4_decorative_lift" in
  let d = [ tr "a" "0" ] in
  let prose =
    "source and behavior are complementary manifestations of the program's \
     underlying identity, each expressing the whole through its own aspect" in
  (* admissibility attempts to parse the proposal as a typed generator; prose
     provides none of the required witnesses. *)
  let required_witnesses =
    [ ("typed_generator_presentation", false,
       "the proposal is prose; it exposes no state set, initial state, or \
        transition/output law that could be admitted into H_M");
      ("prediction_operator", false,
       "no operator predict(candidate, input) is supplied; the proposal cannot \
        answer any query");
      ("admissible_realization_in_H_M", false,
       "nothing to enumerate, fit, or bound; the proposal is not a member of \
        the declared candidate class");
      ("obstruction_dissolution_witness", false,
       "the obstruction (finite traces underdetermine reply on unattempted \
        inputs) is restated, not dissolved");
      ("heldout_consequence", false,
       "the proposal yields no checkable held-out consequence") ]
  in
  let admissible = List.for_all (fun (_, ok, _) -> ok) required_witnesses in
  (* show the data itself is realizable, to separate refusal-of-proposal from
     refusal-of-data *)
  let realizable_count = List.length (fit_candidates cfg d) in
  let facts = {
    admissible;
    c_train_size = -1;        (* search is NOT run: proposal refused pre-search *)
    f_id_size = -1;
    oracle_run = false;
    separating = false;
    pass_count = 0;
    tested_fiber_size = -1;
  } in
  let derived = result_rule facts in
  if derived <> "DECORATIVE_LIFT" then
    failwith (Printf.sprintf "case4 derived %s <> DECORATIVE_LIFT" derived);
  let sem = semantic_input ~traces:d ~heldout:None in
  assert_leakfree (name ^ "/semantic_input") sem;
  let public =
    Obj [
      ("case", Str name);
      ("expected_result", Str "DECORATIVE_LIFT");
      ("derived_result", Str derived);
      ("purpose", Str "fluency without executable generativity is refused BEFORE \
                       realization; the proposal never enters the generator fiber");
      ("proposed_whole_prose", Str prose);
      ("admissibility_gate_passed", Bool admissible);
      ("required_witnesses",
       Arr (List.map (fun (n, ok, why) ->
           Obj [ ("witness", Str n); ("present", Bool ok); ("reason", Str why) ])
           required_witnesses));
      ("search_run", Bool false);
      ("refused_before_realization", Bool true);
      ("underlying_training_is_realizable", Bool (realizable_count > 0));
      ("underlying_training_fitting_candidate_count", Int realizable_count);
      ("distinct_from",
       Obj [ ("NO_REALIZATION_IN_MODEL",
               Str "there the data is well-typed but unrealizable after a complete \
                    search; here the data is realizable and the PROPOSAL is refused");
             ("ASCENT_UNDERDETERMINED",
               Str "there >= 2 typed candidates survive; here nothing typed is \
                    proposed at all") ]);
    ]
  in
  (name, sem, public, None)

(* ============================ CASE 5 ============================ *)
(* Round-trip -> validated continuation (LIFT_VALIDATED with a round-trip
   witness). q-star = "ab" separates the surviving training candidates (they
   predict different outputs); the revealed output leaves one J_eval class;
   re-ascending on D_train U Descend(W, q-star) returns that class (contains
   W), and the U-fiber strictly shrinks (strong, separating). *)

let build_case5 () =
  let name = "case5_roundtrip" in
  let d = [ tr "a" "0"; tr "b" "0"; tr "bb" "00" ] in
  let heldout = inputs_of_str "ab" in
  let u = universe cfg in
  let c_train = fit_candidates cfg d in
  let fib_before = fiber cfg c_train u in
  let jtrain = List.map (fun t -> t.input) d in
  let jeval = jtrain @ [ heldout ] in
  let preds = distinct_predictions cfg fib_before heldout in
  let separating = List.length preds >= 2 in
  let actual = str_of_outputs (run cfg w_latch heldout) in
  (* Descend(W, q-star) folded back into training; re-ascend *)
  let d' = d @ [ { input = heldout; output = run cfg w_latch heldout } ] in
  let c_after = fit_candidates cfg d' in
  let fib_after_u = fiber cfg c_after u in
  let roundtrip_class = fiber cfg c_after jeval in   (* over J_eval': should be singleton *)
  let w_in_after = List.exists (fun m -> canonical_id cfg m = canonical_id cfg w_latch) c_after in
  let c_pass = List.filter (fun m -> str_of_outputs (run cfg m heldout) = actual) c_train in
  let tested = fiber cfg c_pass jeval in
  let strong = List.length fib_after_u < List.length fib_before in
  let facts = {
    admissible = true;
    c_train_size = List.length c_train;
    f_id_size = List.length fib_before;
    oracle_run = true;
    separating;
    pass_count = List.length c_pass;
    tested_fiber_size = List.length tested;
  } in
  let derived = result_rule facts in
  if derived <> "LIFT_VALIDATED" then
    failwith (Printf.sprintf "case5 derived %s <> LIFT_VALIDATED" derived);
  if not w_in_after then failwith "case5: W not returned by re-ascent";
  if List.length roundtrip_class <> 1 then
    failwith (Printf.sprintf "case5: round-trip class not singleton (%d)"
                (List.length roundtrip_class));
  if not strong then failwith "case5: q* did not strictly shrink the U-fiber (not separating)";
  if not separating then failwith "case5: q* not separating";
  let salt = salt_for name in
  let reveal =
    Obj [ ("case", Str name);
          ("hidden_machine", machine_json w_latch);
          ("heldout_query", Str (str_of_inputs heldout));
          ("heldout_output", Str actual);
          ("salt", Str salt);
          ("note", Str "revealed only after predictions are frozen") ]
  in
  let reveal_doc = document reveal in
  let commitment = Sha256.digest_string reveal_doc in
  let sem = semantic_input ~traces:d ~heldout:(Some heldout) in
  assert_leakfree (name ^ "/semantic_input") sem;
  let public =
    Obj [
      ("case", Str name);
      ("expected_result", Str "LIFT_VALIDATED (validated continuation / round-trip)");
      ("derived_result", Str derived);
      ("purpose", Str "Ascend(D_train U Descend(W,q*)) ~= W under the declared \
                       equivalence, with q* strongly separating");
      ("training_traces",
       Arr (List.map (fun t ->
           Obj [ ("input", Str (str_of_inputs t.input));
                 ("observed_reply", Str (str_of_outputs t.output)) ]) d));
      ("heldout_query_public", Str (str_of_inputs heldout));
      ("heldout_distinct_predictions_before", Arr (List.map (fun s -> Str s) preds));
      ("heldout_is_separating", Bool separating);
      ("complete_candidate_set_size_before", Int (List.length c_train));
      ("fiber_over_U_before", Int (List.length fib_before));
      ("complete_candidate_set_size_after_fold", Int (List.length c_after));
      ("fiber_over_U_after_fold", Int (List.length fib_after_u));
      ("strong_separation_fiber_strictly_shrinks", Bool strong);
      ("roundtrip_class_over_J_eval_after_fold", Int (List.length roundtrip_class));
      ("roundtrip_class_contains_hidden_machine", Bool w_in_after);
      ("expected_tested_fiber_size_after_reveal", Int (List.length tested));
      ("oracle_commitment_sha256", Str commitment);
      ("oracle_commitment_formula",
       Str "sha256( canonical_document( reveal/case5_roundtrip.json ) )");
      ("candidate_fiber_over_U_before",
       Arr (List.map (fiber_class_json ~heldout) fib_before));
      ("candidate_fiber_over_U_after_fold",
       Arr (List.map (fiber_class_json ?heldout:None) fib_after_u));
      ("core_ir",
       core_ir ~jtrain ~jeval
         ~oracle:"commit/reveal sealed held-out; q* is separating"
         ~fiber_ref:"candidate_fiber_over_U_before / _after_fold"
         ~empty_ref:"none");
    ]
  in
  (name, sem, public, Some ("case5_roundtrip.json", reveal))

(* ============================ class + minimality ============================ *)

let class_doc () : json * bool =
  (* witness that U (length 1..ulen) fully separates the class: no two
     machines agree on all of U yet disagree on a longer string. Since a
     Mealy separation bound is n1+n2-1 <= 3 = ulen for this class, U is a
     complete separator; we also verify it mechanically. *)
  let u = universe cfg in
  let longer =
    (* all strings of length ulen+1 .. ulen+2 to test for hidden disagreement *)
    let rec strings_of_len len =
      if len = 0 then [ [||] ]
      else List.concat_map (fun p -> List.init cfg.sigma (fun i -> Array.append p [| i |]))
             (strings_of_len (len - 1)) in
    strings_of_len (cfg.ulen + 1) @ strings_of_len (cfg.ulen + 2) in
  let ms = enumerate_class cfg in
  (* group by U-signature; within each group check all agree on longer strings *)
  let tbl : (string, machine list) Hashtbl.t = Hashtbl.create 512 in
  List.iter (fun m ->
      let s = signature cfg m u in
      Hashtbl.replace tbl s (m :: (try Hashtbl.find tbl s with Not_found -> []))) ms;
  let separator_complete =
    Hashtbl.fold (fun _ group acc ->
        acc && (match group with
            | [] | [ _ ] -> true
            | m0 :: rest ->
              List.for_all (fun m ->
                  List.for_all (fun q -> run cfg m0 q = run cfg m q) longer) rest))
      tbl true in
  Obj [
    ("object",
     Str "deterministic pointed Mealy transducer W = (S, s0, Sigma, Gamma, delta, lambda)");
    ("N_state_bound", Int cfg.maxn);
    ("Sigma", Arr (List.init cfg.sigma (fun i -> Str (String.make 1 (in_sym i)))));
    ("Gamma", Arr (List.init cfg.gamma (fun j -> Str (String.make 1 (out_sym j)))));
    ("initial_state", Int 0);
    ("determinism", Str "delta and lambda are total functions of (state, input)");
    ("canonical_enumeration",
     Str "n ascending 1..N; within n, cells ordered (state outer, input inner); \
          each cell a mixed-radix digit over (delta in 0..n-1, lambda in 0..|Gamma|-1), \
          first cell most significant");
    ("class_size", Int (class_size cfg));
    ("query_universe_U",
     Str (Printf.sprintf "all Sigma-strings of length 1..%d (|U| = %d), shortlex"
            cfg.ulen (List.length u)));
    ("equivalence_separation_bound",
     Str "two <=2-state machines are behaviorally equivalent iff they agree on \
          all strings of length <= n1+n2-1 <= 3 = ulen; hence U is a complete \
          separator for the class");
    ("equivalence_separation_verified_mechanically", Bool separator_complete);
    ("articulations",
     Obj [ ("behavior",
             Str "the reply-word function over the declared query family (the \
                  behavior-primary POV; the only public semantic input)");
           ("polar_projection",
             Str "the canonical transition-law presentation (canonical_id); a \
                  PROJECTION available only from a recovered candidate, never \
                  handed to the invocation");
           ("higher_generator_W",
             Str "the pointed transducer producing both") ]);
  ] , separator_complete

let minimality_doc () : json =
  (* N=1 insufficiency: case-1 augmented dataset unrealizable memoryless *)
  let d1 = [ tr "a" "0"; tr "aa" "01"; tr "b" "0"; tr "ba" "00" ] in
  let heldout = inputs_of_str "ab" in
  let d1aug = d1 @ [ { input = heldout; output = run cfg w_latch heldout } ] in
  let n1 = { cfg with maxn = 1 } in
  let fit_n1 = List.length (fit_candidates n1 d1aug) in
  let fit_n2 = List.length (fit_candidates cfg d1aug) in
  (* Gamma=1 degeneracy *)
  let g1 = { cfg with gamma = 1 } in
  let g1_behaviors =
    List.length (List.sort_uniq compare
                   (List.map (fun m -> signature g1 m (universe g1)) (enumerate_class g1))) in
  (* Sigma minimality: at sigma=2, widening input family a-only -> {a,b}
     splits classes; at sigma=1 there is no second symbol to index over. *)
  let u = universe cfg in
  let a_only = List.filter (fun q -> Array.for_all (fun s -> s = 0) q) u in
  let ms = enumerate_class cfg in
  let n_narrow = List.length (List.sort_uniq compare (List.map (fun m -> signature cfg m a_only) ms)) in
  let n_wide = List.length (List.sort_uniq compare (List.map (fun m -> signature cfg m u) ms)) in
  Obj [
    ("claim", Str "the smallest object the five cases demonstrate is \
                   N=2, |Sigma|=2, |Gamma|=2");
    ("N_geq_2_required",
     Obj [ ("demonstration",
             Str "case 1's augmented dataset D_train U {(ab, sealed output)} has \
                  an EMPTY complete fit set at N=1 (memoryless) but a non-empty \
                  one at N=2: the validated held-out descent is unrealizable \
                  without state");
           ("fitting_candidates_at_N_equals_1", Int fit_n1);
           ("fitting_candidates_at_N_equals_2", Int fit_n2);
           ("conclusion", Str (if fit_n1 = 0 && fit_n2 > 0
                               then "N >= 2 required" else "UNEXPECTED")) ]);
    ("Gamma_geq_2_required",
     Obj [ ("demonstration",
             Str "with a single output symbol every machine has identical \
                  behavior, so no fiber has >= 2 classes and no held-out can \
                  separate: neither LIFT_VALIDATED separation nor \
                  ASCENT_UNDERDETERMINED is demonstrable");
           ("distinct_behaviors_over_U_at_Gamma_equals_1", Int g1_behaviors);
           ("conclusion", Str (if g1_behaviors <= 1 then "Gamma >= 2 required" else "UNEXPECTED")) ]);
    ("Sigma_geq_2_required",
     Obj [ ("demonstration",
             Str "the bound obligation 'input-indexed equivalence / behavior on \
                  unattempted INPUTS' is vacuous at |Sigma|=1 (one input symbol: \
                  widening the input family cannot split a class by input). At \
                  |Sigma|=2, widening the indexing family from a-only queries to \
                  {a,b} queries splits classes, so the obligation is non-trivial");
           ("classes_under_a_only_family", Int n_narrow);
           ("classes_under_full_family", Int n_wide);
           ("b_queries_split_count", Int (n_wide - n_narrow));
           ("conclusion", Str (if n_wide > n_narrow then "Sigma >= 2 required" else "UNEXPECTED")) ]);
  ]
