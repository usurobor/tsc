(** Tests for strict v3.2 delta validation (cycle/51 AC1).

    Covered:
    - validate_v32_deltas Ok when all three required delta fields are present
      and in [0, 1].
    - validate_v32_deltas Error when a required field is missing, naming
      that field in missing_fields.
    - validate_v32_deltas Error when a present field is out of [0, 1],
      naming that field in invalid_fields with the observed value
      rendered as a string. *)

open Tsc_engine

let fail msg =
  Printf.eprintf "FAIL: %s\n%!" msg;
  exit 1

let pass label =
  Printf.printf "PASS: %s\n%!" label

let check cond label =
  if not cond then fail label else pass label

let parse raw =
  match Response_schema.parse_json raw with
  | Ok j -> j
  | Error e -> fail (Printf.sprintf "parse setup failed: %s" e)

(* ------------------------------------------------------------------ *)
(* AC1 positive: all three delta fields present and in range.          *)

let test_valid_v32_deltas () =
  let label = "AC1 positive: validate_v32_deltas accepts all three deltas in [0, 1]" in
  let j = parse {|{
    "delta_alpha_beta":  0.3,
    "delta_beta_gamma":  0.7,
    "delta_gamma_alpha": 0.2
  }|} in
  match Response_schema.validate_v32_deltas j with
  | Ok (d_ab, d_bg, d_ga) ->
    check (abs_float (d_ab -. 0.3) < 1e-9
        && abs_float (d_bg -. 0.7) < 1e-9
        && abs_float (d_ga -. 0.2) < 1e-9) label
  | Error _ ->
    fail (label ^ " — got Error instead of Ok")

(* AC1 positive: integer-valued deltas (0 and 1) are accepted. *)
let test_valid_v32_deltas_integers () =
  let label = "AC1 positive: integer deltas at boundaries (0, 1) accepted" in
  let j = parse {|{
    "delta_alpha_beta":  0,
    "delta_beta_gamma":  1,
    "delta_gamma_alpha": 0
  }|} in
  match Response_schema.validate_v32_deltas j with
  | Ok (d_ab, d_bg, d_ga) ->
    check (d_ab = 0.0 && d_bg = 1.0 && d_ga = 0.0) label
  | Error _ -> fail (label ^ " — got Error instead of Ok")

(* ------------------------------------------------------------------ *)
(* AC1 negative: missing delta_beta_gamma must be named.               *)

let test_missing_delta_beta_gamma () =
  let label = "AC1 negative: missing delta_beta_gamma is named in missing_fields" in
  let j = parse {|{
    "delta_alpha_beta":  0.3,
    "delta_gamma_alpha": 0.2
  }|} in
  match Response_schema.validate_v32_deltas j with
  | Ok _ ->
    fail (label ^ " — got Ok despite missing field")
  | Error err ->
    let names_field = List.mem "delta_beta_gamma" err.missing_fields in
    let no_invalids = err.invalid_fields = [] in
    let only_one_missing = List.length err.missing_fields = 1 in
    check (names_field && no_invalids && only_one_missing) label

(* AC1 negative: all three missing -> all three listed. *)
let test_missing_all_deltas () =
  let label = "AC1 negative: all three deltas missing yields full missing_fields list" in
  let j = parse {|{}|} in
  match Response_schema.validate_v32_deltas j with
  | Ok _ -> fail (label ^ " — got Ok on empty object")
  | Error err ->
    let s = err.missing_fields in
    check (List.mem "delta_alpha_beta" s
        && List.mem "delta_beta_gamma" s
        && List.mem "delta_gamma_alpha" s
        && List.length s = 3
        && err.invalid_fields = []) label

(* ------------------------------------------------------------------ *)
(* AC1 negative: out-of-range delta_alpha_beta = 1.5.                  *)

let test_out_of_range_delta () =
  let label = "AC1 negative: out-of-range delta is named with observed value" in
  let j = parse {|{
    "delta_alpha_beta":  1.5,
    "delta_beta_gamma":  0.7,
    "delta_gamma_alpha": 0.2
  }|} in
  match Response_schema.validate_v32_deltas j with
  | Ok _ -> fail (label ^ " — got Ok on out-of-range delta")
  | Error err ->
    let observed =
      List.assoc_opt "delta_alpha_beta" err.invalid_fields
    in
    let mentions_value =
      match observed with
      | None -> false
      | Some v -> String.length v > 0
    in
    check (err.missing_fields = []
        && List.length err.invalid_fields = 1
        && observed <> None
        && mentions_value) label

(* AC1 negative: negative delta value also rejected. *)
let test_negative_delta () =
  let label = "AC1 negative: negative delta rejected as out of [0, 1]" in
  let j = parse {|{
    "delta_alpha_beta":  -0.01,
    "delta_beta_gamma":  0.5,
    "delta_gamma_alpha": 0.5
  }|} in
  match Response_schema.validate_v32_deltas j with
  | Ok _ -> fail (label ^ " — got Ok on negative delta")
  | Error err ->
    check (List.mem_assoc "delta_alpha_beta" err.invalid_fields
        && err.missing_fields = []) label

(* AC1 negative: non-numeric delta (string) rejected. *)
let test_string_delta () =
  let label = "AC1 negative: string-valued delta rejected" in
  let j = parse {|{
    "delta_alpha_beta":  "not-a-number",
    "delta_beta_gamma":  0.5,
    "delta_gamma_alpha": 0.5
  }|} in
  match Response_schema.validate_v32_deltas j with
  | Ok _ -> fail (label ^ " — got Ok on string delta")
  | Error err ->
    check (List.mem_assoc "delta_alpha_beta" err.invalid_fields) label

(* AC1 negative: mixed missing + invalid -> both lists populated. *)
let test_mixed_missing_and_invalid () =
  let label = "AC1 negative: mixed missing + invalid populates both lists" in
  let j = parse {|{
    "delta_alpha_beta":  2.0
  }|} in
  match Response_schema.validate_v32_deltas j with
  | Ok _ -> fail (label ^ " — got Ok on mixed bad input")
  | Error err ->
    check (List.mem_assoc "delta_alpha_beta" err.invalid_fields
        && List.mem "delta_beta_gamma" err.missing_fields
        && List.mem "delta_gamma_alpha" err.missing_fields) label

(* ------------------------------------------------------------------ *)

let () =
  test_valid_v32_deltas ();
  test_valid_v32_deltas_integers ();
  test_missing_delta_beta_gamma ();
  test_missing_all_deltas ();
  test_out_of_range_delta ();
  test_negative_delta ();
  test_string_delta ();
  test_mixed_missing_and_invalid ();
  Printf.printf "All response_schema v3.2 strict validation tests passed.\n%!"
