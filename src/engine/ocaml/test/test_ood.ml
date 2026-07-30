(** Tests for cycle/52 (#52) — OOD aggregate_semantics detector.

    Run via: opam exec -- dune runtest src/engine/ocaml/test/

    AC1 — aggregate_semantics is required as a string field.
    AC2 — only "canonical-v3.2-geometric-num" is accepted.
    AC3 — v3.2-versioned windows without the sentinel are rejected with
          reset guidance; fixtures carrying the sentinel are accepted.

    These tests use the unified entry point [Ood.check_reference_window]
    (with the legacy alias [Ood.check_schema_version] exercised once for
    backward-compatibility insurance). *)

open Tsc_engine

(* ------------------------------------------------------------------ *)
(* Helpers *)

let fail msg =
  Printf.eprintf "FAIL: %s\n%!" msg;
  exit 1

let pass label =
  Printf.printf "PASS: %s\n%!" label

let check cond label =
  if not cond then fail label else pass label

let canonical = "canonical-v3.2-geometric-num"

(** Substring search. Returns true if [sub] occurs in [s]. *)
let contains sub s =
  let nl = String.length sub and hl = String.length s in
  if nl = 0 then true
  else if nl > hl then false
  else
    let found = ref false in
    for i = 0 to hl - nl do
      if not !found && String.sub s i nl = sub then found := true
    done;
    !found

(* ------------------------------------------------------------------ *)
(* AC1: aggregate_semantics required as string *)

let test_ac1_field_required () =
  (* Positive: schema_version + canonical sentinel both present *)
  let ok_window = `Assoc [
    ("schema_version", `String "v3.2.0");
    ("aggregate_semantics", `String canonical);
    ("c_sigma_values", `List [`Float 0.82; `Float 0.79]);
  ] in
  (match Ood.check_reference_window ok_window with
   | Ok () -> pass "AC1: canonical sentinel + v3.2.0 -> Ok"
   | Error msg -> fail (Printf.sprintf "AC1: expected Ok, got Error: %s" msg));
  (* Negative: schema_version present, aggregate_semantics missing *)
  let no_field = `Assoc [
    ("schema_version", `String "v3.2.0");
    ("c_sigma_values", `List [`Float 0.82]);
  ] in
  (match Ood.check_reference_window no_field with
   | Error msg ->
     check (contains "aggregate_semantics" msg)
       "AC1: missing-field error names 'aggregate_semantics'"
   | Ok () ->
     fail "AC1: expected Error for missing aggregate_semantics, got Ok");
  (* Negative: aggregate_semantics present but not a string *)
  let wrong_type = `Assoc [
    ("schema_version", `String "v3.2.0");
    ("aggregate_semantics", `Int 42);
  ] in
  (match Ood.check_reference_window wrong_type with
   | Error msg ->
     check (contains "aggregate_semantics" msg)
       "AC1: non-string error names 'aggregate_semantics'"
   | Ok () ->
     fail "AC1: expected Error for non-string aggregate_semantics");
  (* Negative: aggregate_semantics as bool *)
  let wrong_type_bool = `Assoc [
    ("schema_version", `String "v3.2.0");
    ("aggregate_semantics", `Bool true);
  ] in
  (match Ood.check_reference_window wrong_type_bool with
   | Error msg ->
     check (contains "aggregate_semantics" msg)
       "AC1: bool-valued field error names 'aggregate_semantics'"
   | Ok () ->
     fail "AC1: expected Error for bool aggregate_semantics")

(* ------------------------------------------------------------------ *)
(* AC2: only the canonical sentinel is accepted *)

let test_ac2_only_canonical_accepted () =
  (* Positive: exact canonical string *)
  let canonical_window = `Assoc [
    ("schema_version", `String "v3.2.0");
    ("aggregate_semantics", `String canonical);
  ] in
  (match Ood.check_reference_window canonical_window with
   | Ok () -> pass "AC2: exact canonical sentinel passes"
   | Error msg -> fail (Printf.sprintf "AC2: expected Ok, got Error: %s" msg));
  (* Negative cases: each wrong value must be rejected and the error must
     name both the observed value and the expected canonical value. *)
  let negatives = [
    "arithmetic";
    "weighted-average";
    "canonical-v3.2-geometric-math";
    "legacy";
  ] in
  List.iter (fun bad ->
    let w = `Assoc [
      ("schema_version", `String "v3.2.0");
      ("aggregate_semantics", `String bad);
    ] in
    match Ood.check_reference_window w with
    | Error msg ->
      check (contains bad msg)
        (Printf.sprintf "AC2: error for '%s' names observed value" bad);
      check (contains canonical msg)
        (Printf.sprintf "AC2: error for '%s' names expected canonical value" bad)
    | Ok () ->
      fail (Printf.sprintf "AC2: expected Error for '%s', got Ok" bad)
  ) negatives

(* ------------------------------------------------------------------ *)
(* AC3: v3.2.0 without sentinel rejected with reset guidance;
        fixture windows carry the sentinel. *)

let test_ac3_reset_guidance_and_fixtures () =
  (* The pre-v0.10.0 shape: schema_version = v3.2.0, no aggregate_semantics.
     This passed under the old check; it must now fail with guidance that
     references reset/regenerate. *)
  let pre_v0_10_window = `Assoc [
    ("schema_version", `String "v3.2.0");
    ("c_sigma_values", `List [`Float 0.82; `Float 0.79; `Float 0.81]);
  ] in
  (match Ood.check_reference_window pre_v0_10_window with
   | Error msg ->
     let lower = String.lowercase_ascii msg in
     check (contains "reset" lower
            || contains "regenerate" lower)
       "AC3: pre-v0.10.0 window error includes reset/regenerate guidance";
     check (contains "aggregate_semantics" msg)
       "AC3: pre-v0.10.0 window error names 'aggregate_semantics'"
   | Ok () ->
     fail "AC3: expected Error for v3.2.0 window without aggregate_semantics");
  (* Self-produced fixture: a window that this branch would emit must
     carry the canonical sentinel and validate. *)
  let fixture_window = `Assoc [
    ("schema_version", `String "v3.2.0");
    ("aggregate_semantics", `String canonical);
    ("c_sigma_values", `List [`Float 0.82; `Float 0.79; `Float 0.81]);
    ("epsilon", `Float 1e-5);
  ] in
  (match Ood.check_reference_window fixture_window with
   | Ok () -> pass "AC3: fixture window with sentinel validates"
   | Error msg -> fail (Printf.sprintf "AC3: fixture validation failed: %s" msg));
  (* Cutover stack: a pre-v3.2.0 window still fails first (the version
     guard is strictly stronger than the semantics guard). *)
  let v31_window = `Assoc [
    ("schema_version", `String "v3.1.0");
    ("aggregate_semantics", `String canonical);
  ] in
  (match Ood.check_reference_window v31_window with
   | Error msg ->
     check (contains "3.2.0" msg || contains "cutover" msg
            || contains "predates" msg)
       "AC3: v3.1.0 window fails on the version cutover (precedence)"
   | Ok () ->
     fail "AC3: expected Error for v3.1.0 window even with sentinel");
  (* Legacy alias: check_schema_version is wired to check_reference_window
     so out-of-tree callers also get the strengthened check. *)
  (match Ood.check_schema_version pre_v0_10_window with
   | Error _ ->
     pass "AC3: legacy alias 'check_schema_version' also enforces sentinel"
   | Ok () ->
     fail "AC3: legacy alias should also reject pre-v0.10.0-shaped windows")

(* ------------------------------------------------------------------ *)
(* Runner *)

let () =
  Printf.printf "=== TSC OOD aggregate_semantics tests (#52) ===\n%!";
  test_ac1_field_required ();
  test_ac2_only_canonical_accepted ();
  test_ac3_reset_guidance_and_fixtures ();
  Printf.printf "=== All OOD aggregate_semantics tests passed ===\n%!"
