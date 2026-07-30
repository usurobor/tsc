(** Tests for Factorized_beta_gate (cycle/75, #75 gate-evaluation logic).

    Runnable without a witness: the β-consistency barrier routing, the A3
    locus-agreement statistic, the A/B/C gate combination (PASS / FAIL /
    NO-DECISION), and the B3 controls label-agreement check over the
    committed frozen fixture. The measurement RUN itself (real witnesses)
    is the credentialed CI witness's job. *)

open Tsc_engine
module G = Factorized_beta_gate
module FB = Factorized_beta

let failures = ref 0
let fail msg = Printf.eprintf "FAIL: %s\n%!" msg; incr failures
let pass label = Printf.printf "PASS: %s\n%!" label
let check cond label = if cond then pass label else fail label
let approx a b = Float.abs (a -. b) < 1e-6

(* ------------------------------------------------------------------ *)
(* β consistency (A1) — barrier routing                                *)

let test_beta_spread_and_coh () =
  check (approx (G.beta_spread [ 0.9; 0.9; 0.9 ]) 0.0)
    "identical β -> spread 0";
  check (approx (G.beta_coh_consistency [ 0.9; 0.9; 0.9 ]) 1.0)
    "A1: identical β -> Coh_consistency 1.0";
  (* spread 0.1 -> phi = 0.1/0.9 -> Coh = exp(-0.1/0.9). *)
  let expect = exp (-. (0.1 /. 0.9)) in
  check (approx (G.beta_coh_consistency [ 0.9; 0.8 ]) expect)
    "A1: β spread 0.1 routes through Coherence.coherence_link";
  check (approx (G.beta_coh_consistency [ 0.7 ]) 1.0)
    "A1: single sample -> spread 0 -> 1.0"

(* ------------------------------------------------------------------ *)
(* A3 locus agreement                                                  *)

let test_locus_agreement () =
  let ids = [ "l1"; "l2" ] in
  let s v1 v2 = [ ("l1", v1); ("l2", v2) ] in
  (* two identical samples -> agreement 1.0 *)
  check (approx (G.locus_agreement ~eligible_ids:ids
                   ~samples:[ s FB.Supports FB.Contradicts;
                              s FB.Supports FB.Contradicts ]) 1.0)
    "A3: identical verdict maps -> agreement 1.0";
  (* one of two loci disagrees across the single pair -> 0.5 *)
  check (approx (G.locus_agreement ~eligible_ids:ids
                   ~samples:[ s FB.Supports FB.Contradicts;
                              s FB.Supports FB.Supports ]) 0.5)
    "A3: one locus disagreeing over one pair -> 0.5";
  check (approx (G.locus_agreement ~eligible_ids:[] ~samples:[]) 1.0)
    "A3: no loci / no pairs -> vacuous 1.0"

(* ------------------------------------------------------------------ *)
(* Gate combination                                                    *)

let tm ?(sparse = false) ?(declared = 3) ?(validated = 3) ?(eligible = 6)
    ?(beta_coh = 0.95) ?(agreement = 0.95) ?(baseline = 0.80)
    ?(baseline_present = true) target = {
  G.tm_target = target;
  tm_beta_loci = 8;
  tm_eligible_loci = eligible;
  tm_locus_sparse = sparse;
  tm_declared_samples = declared;
  tm_validated_samples = validated;
  tm_refused_samples = declared - validated;
  tm_sample_betas = [ beta_coh; beta_coh; beta_coh ];
  tm_beta_coh = beta_coh;
  tm_agreement = agreement;
  tm_baseline_beta_coh = baseline;
  tm_baseline_present = baseline_present;
}

let gi ?(kata = true) ?(adm = true) ?(b3 = true) targets = {
  G.gi_targets = targets;
  gi_kata_b1 = kata;
  gi_admissibility_b2 = adm;
  gi_b3 = b3;
  gi_a1_floor = G.default_a1_floor;
  gi_a2_margin = G.default_a2_margin;
  gi_a3_floor = G.default_a3_floor;
  gi_declared = 3;
}

let five = [ "spec"; "engine"; "repo"; "methodology"; "cm-of-cms" ]

let test_gate_pass () =
  let g = G.evaluate_gate (gi (List.map (fun t -> tm t) five)) in
  check (g.G.gr_verdict = G.Pass)
    "gate: all A0-A3 + B1-B3 pass on 5 scored targets -> PASS";
  check (g.G.gr_sparse_count = 0) "gate: no sparse targets"

let test_gate_fail_a1 () =
  let ts = tm ~beta_coh:0.80 "spec" :: List.map (fun t -> tm t) (List.tl five) in
  let g = G.evaluate_gate (gi ts) in
  check (g.G.gr_verdict = G.Fail) "gate: an A1 miss (β_coh<0.90) -> FAIL";
  check (List.exists (fun (c : G.check) ->
      c.G.chk_id = "A1" && not c.G.chk_passed) g.G.gr_checks)
    "gate: A1 check reports the miss"

let test_gate_fail_a2_no_baseline () =
  let ts = tm ~baseline_present:false "spec"
           :: List.map (fun t -> tm t) (List.tl five) in
  let g = G.evaluate_gate (gi ts) in
  check (g.G.gr_verdict = G.Fail)
    "gate: A2 with an absent baseline cannot prove improvement -> FAIL"

let test_gate_fail_a0_yield () =
  let ts = tm ~validated:2 "spec" :: List.map (fun t -> tm t) (List.tl five) in
  let g = G.evaluate_gate (gi ts) in
  check (g.G.gr_verdict = G.Fail) "gate: A0 yield 2/3 -> FAIL"

let test_gate_fail_guard () =
  let g = G.evaluate_gate (gi ~b3:false (List.map (fun t -> tm t) five)) in
  check (g.G.gr_verdict = G.Fail) "gate: a B3 miss -> FAIL"

let test_gate_no_decision () =
  (* Two sparse held-out targets -> NO-DECISION (C4), even if the rest pass. *)
  let ts =
    tm ~sparse:true ~eligible:2 "methodology"
    :: tm ~sparse:true ~eligible:0 "cm-of-cms"
    :: List.map (fun t -> tm t) [ "spec"; "engine"; "repo" ]
  in
  let g = G.evaluate_gate (gi ts) in
  check (g.G.gr_verdict = G.No_decision)
    "gate: >1 locus_sparse held-out target -> NO-DECISION (C4)";
  check (g.G.gr_sparse_count = 2) "gate: sparse count = 2"

let test_gate_one_sparse_ok () =
  (* Exactly one sparse target is excluded from A1/A2/A3 but does NOT
     trigger NO-DECISION; the remaining four still gate to PASS. *)
  let ts =
    tm ~sparse:true ~eligible:3 "methodology"
    :: List.map (fun t -> tm t) [ "spec"; "engine"; "repo"; "cm-of-cms" ]
  in
  let g = G.evaluate_gate (gi ts) in
  check (g.G.gr_verdict = G.Pass)
    "gate: exactly one sparse target -> still gated on the other four -> PASS";
  check (g.G.gr_sparse_count = 1 && List.length g.G.gr_scored = 4)
    "gate: one sparse, four scored"

let test_gate_json_roundtrip () =
  let t = tm "spec" in
  let j = G.target_measure_to_json t in
  (match G.target_measure_of_json j with
   | Ok t2 ->
     check (t2.G.tm_target = "spec" && approx t2.G.tm_beta_coh t.G.tm_beta_coh
            && t2.G.tm_validated_samples = 3)
       "gate: target_measure JSON round-trips"
   | Error e -> fail ("target_measure_of_json: " ^ e))

let test_verdict_tokens () =
  check (G.string_of_verdict_token G.Pass = "PASS"
         && G.string_of_verdict_token G.Fail = "FAIL"
         && G.string_of_verdict_token G.No_decision = "NO-DECISION")
    "gate: terminal tokens are PASS | FAIL | NO-DECISION"

(* ------------------------------------------------------------------ *)
(* B3 controls label agreement over the committed frozen fixture       *)

let repo_root = lazy (
  let rec up d =
    if Sys.file_exists (Filename.concat d "targets/registry.tsc") then d
    else let p = Filename.dirname d in
      if p = d then failwith "repo root not found" else up p
  in
  up (Sys.getcwd ()))

let read_file path =
  let ic = open_in_bin path in
  Fun.protect ~finally:(fun () -> close_in ic) (fun () ->
    really_input_string ic (in_channel_length ic))

let get k = function `Assoc l -> List.assoc_opt k l | _ -> None
let fstr k j = match get k j with Some (`String s) -> s | _ -> ""
let fbool k j = match get k j with Some (`Bool b) -> b | _ -> false

(* Build a witness response array from the fixture controls, choosing each
   verdict via [pick]. contradicts responses carry both evidence sides. *)
let responses_for fixtures ~pick =
  match get "controls" fixtures with
  | Some (`List items) ->
    `List (List.filter_map (fun o ->
      if fbool "llm_called" o then
        let id = fstr "id" o in
        let v = pick (fstr "expected_verdict" o) in
        Some (`Assoc [
          ("locus_id", `String id);
          ("verdict", `String v);
          ("confidence", `Float 0.9);
          ("evidence", `Assoc [ ("source", `String "src cite");
                                ("target", `String "tgt cite") ]);
          ("rationale", `String "r");
        ])
      else None) items)
  | _ -> `List []

let test_b3_controls_agree () =
  let path = Filename.concat (Lazy.force repo_root)
      "docs/beta/governance/fixtures/factorized-beta-controls.json" in
  let fixtures = Yojson.Safe.from_string (read_file path) in
  let responses = responses_for fixtures ~pick:(fun exp -> exp) in
  (match G.controls_check ~fixtures_json:fixtures ~responses_json:responses with
   | Ok b3 ->
     check (b3.G.b3_passed && b3.G.b3_typed_ok && b3.G.b3_agreements = b3.G.b3_total)
       "B3: witness matching every expected label -> pass (typed + full agreement)"
   | Error e -> fail ("controls_check (agree): " ^ e))

let test_b3_controls_mismatch () =
  let path = Filename.concat (Lazy.force repo_root)
      "docs/beta/governance/fixtures/factorized-beta-controls.json" in
  let fixtures = Yojson.Safe.from_string (read_file path) in
  (* Flip every expected verdict to 'supports' — the contradicts and
     insufficient controls now disagree. *)
  let responses = responses_for fixtures ~pick:(fun _ -> "supports") in
  (match G.controls_check ~fixtures_json:fixtures ~responses_json:responses with
   | Ok b3 ->
     check (not b3.G.b3_passed && b3.G.b3_mismatches <> [])
       "B3: a mislabeling witness -> fail with recorded mismatches"
   | Error e -> fail ("controls_check (mismatch): " ^ e))

let test_b3_controls_evidence_side () =
  (* A contradicts response missing the target evidence side fails B3. *)
  let path = Filename.concat (Lazy.force repo_root)
      "docs/beta/governance/fixtures/factorized-beta-controls.json" in
  let fixtures = Yojson.Safe.from_string (read_file path) in
  let responses =
    match get "controls" fixtures with
    | Some (`List items) ->
      `List (List.filter_map (fun o ->
        if fbool "llm_called" o then
          let id = fstr "id" o and exp = fstr "expected_verdict" o in
          let ev =
            if exp = "contradicts" then `Assoc [ ("source", `String "s") ]
            else `Assoc [ ("source", `String "s"); ("target", `String "t") ]
          in
          Some (`Assoc [ ("locus_id", `String id); ("verdict", `String exp);
                         ("confidence", `Float 0.9); ("evidence", ev);
                         ("rationale", `String "r") ])
        else None) items)
    | _ -> `List []
  in
  (match G.controls_check ~fixtures_json:fixtures ~responses_json:responses with
   | Ok b3 ->
     check (not b3.G.b3_passed && b3.G.b3_evidence_fail <> [])
       "B3: a contradicts verdict missing an evidence side -> fail"
   | Error e -> fail ("controls_check (evidence): " ^ e))

let test_controls_prompt () =
  let path = Filename.concat (Lazy.force repo_root)
      "docs/beta/governance/fixtures/factorized-beta-controls.json" in
  let fixtures = Yojson.Safe.from_string (read_file path) in
  (match G.controls_prompt fixtures with
   | Ok prompt ->
     check (String.length prompt > 0
            && (let contains_sub needle hay =
                  let nl = String.length needle and hl = String.length hay in
                  let found = ref false and i = ref 0 in
                  while not !found && !i <= hl - nl do
                    if String.sub hay !i nl = needle then found := true else incr i
                  done; !found in
                contains_sub "ctrl.citation.supports.01" prompt))
       "B3: controls prompt lists the llm_called control loci"
   | Error e -> fail ("controls_prompt: " ^ e))

(* ------------------------------------------------------------------ *)

let () =
  test_beta_spread_and_coh ();
  test_locus_agreement ();
  test_gate_pass ();
  test_gate_fail_a1 ();
  test_gate_fail_a2_no_baseline ();
  test_gate_fail_a0_yield ();
  test_gate_fail_guard ();
  test_gate_no_decision ();
  test_gate_one_sparse_ok ();
  test_gate_json_roundtrip ();
  test_verdict_tokens ();
  test_b3_controls_agree ();
  test_b3_controls_mismatch ();
  test_b3_controls_evidence_side ();
  test_controls_prompt ();
  if !failures > 0 then begin
    Printf.eprintf "\n%d factorized-β gate test(s) FAILED.\n%!" !failures;
    exit 1
  end;
  Printf.printf "All factorized-β gate tests passed.\n%!"
