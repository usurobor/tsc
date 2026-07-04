(** Tests for the consistency protocol's LLM arm and the medoid
    election (P1 of the Python-removal master issue).

    Pins:
    - the barrier transform lives in the engine (Consistency.barrier /
      coh_from_delta) — anchor values include the live spreads the
      instrument has recorded (delta 0.12, 0.17, 0.22);
    - llm_spread_report reproduces the retired Python report semantics
      (fields, spread, delta_consistency, coh_consistency);
    - Witness_medoid.choose reproduces the retired Python self-test
      matrix verbatim: outlier loses, ties break earliest, unparseable
      and field-incomplete samples are excluded from the election, and
      when nothing parses the first argument is chosen (the named
      compatibility policy — downstream funnel refuses it). *)

open Tsc_engine

let failures = ref 0

let fail msg =
  incr failures;
  Printf.printf "FAIL: %s\n%!" msg

let check cond msg =
  if cond then Printf.printf "PASS: %s\n%!" msg else fail msg

let check_close ?(tol = 1e-9) label got want =
  check (Float.abs (got -. want) < tol)
    (Printf.sprintf "%s (|%.9f - %.9f| < %g)" label got want tol)

(* ------------------------------------------------------------------ *)
(* Fixture helpers                                                     *)

let tmp_dir = Filename.temp_file "tsc-consistency" ""
let () = Sys.remove tmp_dir; Unix.mkdir tmp_dir 0o755

let field_names =
  List.map Witness_numeric.field_name Witness_numeric.all_fields

(* Write a response file carrying the seven numeric fields, all 0.5
   except overrides. *)
let write_response name overrides =
  let path = Filename.concat tmp_dir name in
  let value n =
    match List.assoc_opt n overrides with Some v -> v | None -> 0.5
  in
  let json =
    `Assoc (List.map (fun n -> (n, `Float (value n))) field_names)
  in
  let oc = open_out path in
  output_string oc (Yojson.Safe.to_string json);
  close_out oc;
  path

let write_raw name content =
  let path = Filename.concat tmp_dir name in
  let oc = open_out path in
  output_string oc content;
  close_out oc;
  path

(* ------------------------------------------------------------------ *)
(* Barrier / Coh_consistency anchors                                   *)

let test_barrier () =
  check_close "barrier: coh(0) = 1" (Consistency.coh_from_delta 0.0) 1.0;
  check_close ~tol:1e-9 "barrier: coh(0.12) = 0.872525... (live engine spread)"
    (Consistency.coh_from_delta 0.12) 0.8725252928694238;
  check_close ~tol:1e-9 "barrier: coh(0.17) = 0.814795... (live spec spread)"
    (Consistency.coh_from_delta 0.17) 0.8147945551343462;
  check_close ~tol:1e-9 "barrier: coh(0.22) = 0.754235... (live repo spread)"
    (Consistency.coh_from_delta 0.22) 0.7542350048231139;
  check_close "barrier: coh(1.0) = 0 (saturated spread)"
    (Consistency.coh_from_delta 1.0) 0.0;
  check_close "barrier: coh(1.5) = 0 (beyond saturation)"
    (Consistency.coh_from_delta 1.5) 0.0;
  check_close "barrier: phi(0.5) = 1" (Consistency.barrier 0.5) 1.0

(* ------------------------------------------------------------------ *)
(* Spread report semantics                                             *)

let test_spread_report () =
  let r1 = write_response "s1.json" [ ("alpha", 0.62); ("beta", 0.78) ] in
  let r2 = write_response "s2.json" [ ("alpha", 0.66); ("beta", 0.60) ] in
  let r3 = write_response "s3.json" [ ("alpha", 0.87); ("beta", 0.73) ] in
  match Consistency.llm_spread_report ~target:"spec" ~files:[ r1; r2; r3 ] with
  | Error e -> fail ("spread: report errored: " ^ e)
  | Ok (`Assoc kv) ->
    let str k = match List.assoc_opt k kv with
      | Some (`String s) -> s | _ -> "" in
    let num k = match List.assoc_opt k kv with
      | Some (`Float x) -> x | Some (`Int i) -> Float.of_int i | _ -> nan in
    check (str "kind" = "cm_consistency_report" && str "arm" = "llm"
           && str "target" = "spec")
      "spread: kind/arm/target preserved";
    check (num "repeats" = 3.0) "spread: repeats = 3";
    (* alpha spread = 0.87 - 0.62 = 0.25 -> delta; beta spread = 0.18 *)
    check_close ~tol:1e-9 "spread: delta_consistency = max field spread (0.25)"
      (num "delta_consistency") 0.25;
    check_close ~tol:1e-6 "spread: coh_consistency = exp(-0.25/0.75)"
      (num "coh_consistency") 0.716531;
    (match List.assoc_opt "fields" kv with
     | Some (`Assoc fields) ->
       check (List.length fields = 7
              && List.map fst fields = field_names)
         "spread: all seven fields present in canonical order";
       (match List.assoc_opt "beta" fields with
        | Some (`Assoc b) ->
          (match List.assoc_opt "spread" b with
           | Some (`Float s) ->
             check_close ~tol:1e-9 "spread: per-field beta spread 0.18" s 0.18
           | _ -> fail "spread: beta spread missing")
        | _ -> fail "spread: beta field missing")
     | _ -> fail "spread: fields object missing")
  | Ok _ -> fail "spread: report is not an object"

let test_spread_refusals () =
  let r1 = write_response "one.json" [] in
  (match Consistency.llm_spread_report ~target:"spec" ~files:[ r1 ] with
   | Error _ -> check true "spread refusal: fewer than two files"
   | Ok _ -> fail "spread refusal: single file accepted");
  (match Consistency.llm_spread_report ~target:"spec"
           ~files:[ r1; Filename.concat tmp_dir "absent.json" ] with
   | Error _ -> check true "spread refusal: missing file"
   | Ok _ -> fail "spread refusal: missing file accepted");
  let bad = write_raw "bad.json" "not json" in
  (match Consistency.llm_spread_report ~target:"spec" ~files:[ r1; bad ] with
   | Error _ -> check true "spread refusal: malformed JSON"
   | Ok _ -> fail "spread refusal: malformed JSON accepted");
  let partial = write_raw "partial.json" {|{"alpha": 0.5}|} in
  (match Consistency.llm_spread_report ~target:"spec" ~files:[ r1; partial ] with
   | Error e ->
     check (String.length e > 0)
       (Printf.sprintf
          "spread refusal: missing numeric field is a visible error (%s)" e)
   | Ok _ -> fail "spread refusal: field-incomplete sample accepted");
  let nonnum =
    write_raw "nonnum.json"
      ({|{"alpha": "high", "beta": 0.5, "gamma": 0.5, |}
       ^ {|"delta_alpha_beta": 0.1, "delta_beta_gamma": 0.1, |}
       ^ {|"delta_gamma_alpha": 0.1, "confidence": 0.5}|})
  in
  (match Consistency.llm_spread_report ~target:"spec" ~files:[ r1; nonnum ] with
   | Error _ -> check true "spread refusal: non-numeric field"
   | Ok _ -> fail "spread refusal: non-numeric field accepted");
  (* Saturated spread maps to Coh 0. *)
  let lo = write_response "lo.json" [ ("alpha", 0.0) ] in
  let hi = write_response "hi.json" [ ("alpha", 1.0) ] in
  (match Consistency.llm_spread_report ~target:"spec" ~files:[ lo; hi ] with
   | Ok (`Assoc kv) ->
     (match List.assoc_opt "coh_consistency" kv with
      | Some (`Float c) ->
        check_close "spread: delta >= 1.0 -> Coh_consistency 0" c 0.0
      | _ -> fail "spread: saturated report missing coh_consistency")
   | _ -> fail "spread: saturated pair refused")

(* ------------------------------------------------------------------ *)
(* Medoid election — the retired Python self-test matrix               *)

let test_medoid () =
  (* r1 is the outlier; r2 and r3 agree -> medoid is r2 (earliest of
     the agreeing pair). *)
  let r1 = write_response "m1.json" [ ("alpha", 0.1) ] in
  let r2 = write_response "m2.json" [ ("alpha", 0.9) ] in
  let r3 = write_response "m3.json" [ ("alpha", 0.9) ] in
  (match Witness_medoid.choose [ r1; r2; r3 ] with
   | Ok p -> check (p = r2) "medoid: outlier loses"
   | Error e -> fail ("medoid: outlier case errored: " ^ e));
  (* All identical -> tie -> earliest argument wins. *)
  let s1 = write_response "t1.json" [] in
  let s2 = write_response "t2.json" [] in
  let s3 = write_response "t3.json" [] in
  (match Witness_medoid.choose [ s1; s2; s3 ] with
   | Ok p -> check (p = s1) "medoid: tie breaks earliest"
   | Error e -> fail ("medoid: tie case errored: " ^ e));
  (* Unparseable sample excluded from the election. *)
  let bad = write_raw "mbad.json" "not json" in
  (match Witness_medoid.choose [ bad; r2; r3 ] with
   | Ok p -> check (p = r2) "medoid: unparseable sample excluded"
   | Error e -> fail ("medoid: bad-excluded case errored: " ^ e));
  (* Nothing parses -> first argument (downstream funnel refuses). *)
  let bad2 = write_raw "mbad2.json" "{}" in
  (match Witness_medoid.choose [ bad; bad2 ] with
   | Ok p -> check (p = bad) "medoid: none parse -> first argument"
   | Error e -> fail ("medoid: none-parse case errored: " ^ e));
  (* Field-incomplete sample excluded. *)
  let partial = write_raw "mpartial.json" {|{"alpha": 0.5}|} in
  (match Witness_medoid.choose [ partial; r2; r3 ] with
   | Ok p -> check (p = r2) "medoid: field-incomplete sample excluded"
   | Error e -> fail ("medoid: partial-excluded case errored: " ^ e));
  (* Empty input refused. *)
  (match Witness_medoid.choose [] with
   | Error _ -> check true "medoid: empty input refused"
   | Ok _ -> fail "medoid: empty input accepted")

(* ------------------------------------------------------------------ *)

let () =
  Printf.printf "=== TSC consistency + medoid tests (Python-removal P1) ===\n%!";
  test_barrier ();
  test_spread_report ();
  test_spread_refusals ();
  test_medoid ();
  if !failures > 0 then begin
    Printf.printf "=== %d FAILURES ===\n%!" !failures;
    exit 1
  end;
  Printf.printf "=== All consistency + medoid tests passed ===\n%!"
