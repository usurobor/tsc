(** Tests for mechanical scoring.

    Verifies determinism, signal behavior, and report shape. *)

open Tsc_engine
open Tsc_engine.Types

let make_file ?(kind = Theory) path content =
  Bundle.make_bundle_file ~target_kind:kind ~path ~content

let make_bundle ?(name = "test") ?(kind = Theory) files =
  {
    bundle_target_name = name;
    bundle_target_kind = kind;
    bundle_files = List.map (fun (p, c) -> make_file ~kind p c) files;
  }

(* --- Determinism --- *)

let%expect_test "identical input produces identical output" =
  let files = [
    ("README.md", "# Project\n\nThis is the **canonical** source.");
    ("DESIGN.md", "# Design\n\nThe **canonical** spec lives here.");
  ] in
  let bundle = make_bundle files in
  let r1 = Mechanical_scoring.score_bundle bundle in
  let r2 = Mechanical_scoring.score_bundle bundle in
  Printf.printf "alpha: %b\n" (r1.alpha.score = r2.alpha.score);
  Printf.printf "beta: %b\n" (r1.beta.score = r2.beta.score);
  Printf.printf "gamma: %b\n" (r1.gamma.score = r2.gamma.score);
  Printf.printf "c_sigma: %b\n" (r1.c_sigma = r2.c_sigma);
  [%expect {|
    alpha: true
    beta: true
    gamma: true
    c_sigma: true
  |}]

(* --- Score ranges --- *)

let%expect_test "scores are in [0, 1]" =
  let files = [
    ("a.md", "# Alpha\n\n**term** is used here.");
    ("b.md", "# Beta\n\n**term** is also here. See `a.md`.");
    ("c.md", "# Gamma\n\nVersion 0.1.0. Changelog entry.");
  ] in
  let bundle = make_bundle files in
  let r = Mechanical_scoring.score_bundle bundle in
  let in_range x = x >= 0.0 && x <= 1.0 in
  Printf.printf "alpha: %b\n" (in_range r.alpha.score);
  Printf.printf "beta: %b\n" (in_range r.beta.score);
  Printf.printf "gamma: %b\n" (in_range r.gamma.score);
  Printf.printf "c_sigma: %b\n" (in_range r.c_sigma);
  Printf.printf "confidence: %b\n" (in_range r.confidence);
  [%expect {|
    alpha: true
    beta: true
    gamma: true
    c_sigma: true
    confidence: true
  |}]

(* --- Confidence reduction for small bundles --- *)

let%expect_test "small bundle reduces confidence" =
  let files = [("single.md", "# One file\n\nContent.")] in
  let bundle = make_bundle files in
  let r = Mechanical_scoring.score_bundle bundle in
  Printf.printf "confidence < 1.0: %b\n" (r.confidence < 1.0);
  Printf.printf "has diagnostic: %b\n" (List.length r.diagnostics > 0);
  [%expect {|
    confidence < 1.0: true
    has diagnostic: true
  |}]

(* --- JSON roundtrip shape --- *)

let%expect_test "JSON output has required fields" =
  let files = [
    ("README.md", "# Project\n\nVersion 1.0.0");
    ("DESIGN.md", "# Design\n\nSee `README.md`.");
    ("PLAN.md", "# Plan\n\nStep 1.");
  ] in
  let bundle = make_bundle files in
  let r = Mechanical_scoring.score_bundle bundle in
  let json = Mechanical_scoring.result_to_json r in
  let has_field key = match json with
    | `Assoc fields -> List.mem_assoc key fields
    | _ -> false
  in
  Printf.printf "mode: %b\n" (has_field "mode");
  Printf.printf "alpha: %b\n" (has_field "alpha");
  Printf.printf "beta: %b\n" (has_field "beta");
  Printf.printf "gamma: %b\n" (has_field "gamma");
  Printf.printf "c_sigma: %b\n" (has_field "c_sigma");
  Printf.printf "bottleneck_axis: %b\n" (has_field "bottleneck_axis");
  Printf.printf "confidence: %b\n" (has_field "confidence");
  Printf.printf "evidence_kind: %b\n" (has_field "evidence_kind");
  Printf.printf "diagnostics: %b\n" (has_field "diagnostics");
  [%expect {|
    mode: true
    alpha: true
    beta: true
    gamma: true
    c_sigma: true
    bottleneck_axis: true
    confidence: true
    evidence_kind: true
    diagnostics: true
  |}]

(* --- Mode field --- *)

let%expect_test "mode is mechanical" =
  let bundle = make_bundle [("x.md", "content")] in
  let r = Mechanical_scoring.score_bundle bundle in
  let json = Mechanical_scoring.result_to_json r in
  (match json with
   | `Assoc fields ->
     (match List.assoc_opt "mode" fields with
      | Some (`String s) -> Printf.printf "mode: %s\n" s
      | _ -> Printf.printf "mode: missing\n")
   | _ -> Printf.printf "not an object\n");
  [%expect {| mode: mechanical |}]

(* --- Bottleneck axis is valid --- *)

let%expect_test "bottleneck is one of alpha/beta/gamma" =
  let files = [
    ("a.md", "# A\nContent");
    ("b.md", "# B\nMore content");
    ("c.md", "# C\nEven more");
  ] in
  let r = Mechanical_scoring.score_bundle (make_bundle files) in
  let valid = match r.bottleneck_axis with
    | `Alpha | `Beta | `Gamma -> true in
  Printf.printf "valid: %b\n" valid;
  [%expect {| valid: true |}]

(* --- Direct file scoring matches bundle scoring --- *)

let%expect_test "score_files and score_bundle agree on same content" =
  let files = [
    ("a.md", "# Alpha\n**term** here.");
    ("b.md", "# Beta\n**term** there too.");
  ] in
  let bundle_files = List.map (fun (p, c) -> make_file p c) files in
  let bundle = make_bundle files in
  let r_bundle = Mechanical_scoring.score_bundle bundle in
  let r_files = Mechanical_scoring.score_files bundle_files in
  (* Scores should be very close — target presence may differ slightly *)
  Printf.printf "alpha close: %b\n"
    (Float.abs (r_bundle.alpha.score -. r_files.alpha.score) < 0.01);
  Printf.printf "c_sigma close: %b\n"
    (Float.abs (r_bundle.c_sigma -. r_files.c_sigma) < 0.05);
  [%expect {|
    alpha close: true
    c_sigma close: true
  |}]
