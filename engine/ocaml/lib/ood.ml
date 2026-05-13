(** OOD reference-window validation: schema_version and aggregate_semantics.

    When the engine reads an OOD reference window, it must check two
    compatibility surfaces:

    1. {b Schema version} — if [schema_version < "v3.2.0"], the historical
       C_Σ values are not comparable across the barrier-transform cutover
       (spec/tsc-core.md §12) and the reference distribution must be reset.

    2. {b Aggregate semantics} — even at [schema_version = "v3.2.0"], the
       window must declare which numerical aggregate semantics built its
       distribution. Only [canonical-v3.2-geometric-num] (matching
       spec/tsc-core.md §5.2 [C_Σ^num]) is accepted. Pre-v0.10.0 windows
       built with arithmetic aggregate semantics produce false drift
       signals when compared against current [C_Σ^num] values; they must
       be reset.

    The exported entry point is {!check_reference_window}. The legacy name
    {!check_schema_version} is preserved as an alias so existing callers
    continue to work. *)

let cutover_version = "v3.2.0"

(** The only [aggregate_semantics] string accepted by this validator.
    Reference windows produced under the post-v0.10.0 numerical aggregate
    (spec/tsc-core.md §5.2 [C_Σ^num]) MUST stamp this exact value. *)
let canonical_aggregate_semantics = "canonical-v3.2-geometric-num"

(** Parse a semantic version string "vX.Y.Z" or "X.Y.Z" into (major, minor, patch).
    Returns None on parse failure. *)
let parse_version s =
  let s = if String.length s > 0 && s.[0] = 'v'
    then String.sub s 1 (String.length s - 1)
    else s
  in
  match String.split_on_char '.' s with
  | [maj; min_; pat] ->
    (match int_of_string_opt maj, int_of_string_opt min_, int_of_string_opt pat with
     | Some a, Some b, Some c -> Some (a, b, c)
     | _ -> None)
  | _ -> None

(** version_lt: true when version string a is strictly less than version string b.
    Falls back to string comparison on parse failure. *)
let version_lt a b =
  match parse_version a, parse_version b with
  | Some (ma, mia, pa), Some (mb, mib, pb) ->
    (ma, mia, pa) < (mb, mib, pb)
  | _ -> String.compare a b < 0

(** Validate the [schema_version] field of a reference-window JSON object.
    Internal helper consumed by {!check_reference_window}. *)
let check_schema_version_field fields =
  match List.assoc_opt "schema_version" fields with
  | Some (`String v) ->
    if version_lt v cutover_version then
      Error (Printf.sprintf
        "OOD reference window schema_version '%s' predates v3.2.0. \
         The barrier-transform cutover (spec/tsc-core.md §12) makes \
         historical C_Sigma values incompatible. Reset the OOD reference \
         distribution before proceeding." v)
    else
      Ok ()
  | Some _ ->
    Error "OOD reference window field 'schema_version' is not a string"
  | None ->
    Error "OOD reference window missing required field 'schema_version'"

(** Validate the [aggregate_semantics] field of a reference-window JSON
    object.

    - Missing field → [Error] naming [aggregate_semantics] and emitting
      reset guidance (a v3.2.0-versioned window without this field is the
      pre-v0.10.0 shape — see spec/tsc-core.md §12).
    - Non-string field → [Error] naming [aggregate_semantics].
    - Wrong string → [Error] naming both the observed value and the
      expected canonical sentinel.
    - Canonical sentinel → [Ok ()]. *)
let check_aggregate_semantics_field fields =
  match List.assoc_opt "aggregate_semantics" fields with
  | Some (`String v) when v = canonical_aggregate_semantics ->
    Ok ()
  | Some (`String v) ->
    Error (Printf.sprintf
      "OOD reference window 'aggregate_semantics' = '%s' is not accepted; \
       expected '%s' (spec/tsc-core.md §5.2 C_Sigma^num). Reset or \
       regenerate the OOD reference distribution: aggregate semantics \
       are incompatible across the v0.10.0 numerical-aggregate cutover."
      v canonical_aggregate_semantics)
  | Some _ ->
    Error (Printf.sprintf
      "OOD reference window field 'aggregate_semantics' is not a string \
       (expected '%s')" canonical_aggregate_semantics)
  | None ->
    Error (Printf.sprintf
      "OOD reference window missing required field 'aggregate_semantics' \
       (expected '%s'). A v3.2.0-versioned window without this field is \
       the pre-v0.10.0 shape; reset the OOD reference distribution \
       (spec/tsc-core.md §12) — historical C_Sigma values built from \
       arithmetic aggregate semantics are not comparable to current \
       C_Sigma^num values."
      canonical_aggregate_semantics)

(** check_reference_window: validate that a reference window JSON object
    declares both a compatible [schema_version] and the canonical
    [aggregate_semantics] sentinel.

    The [schema_version] check runs first; on its failure, the
    aggregate-semantics check is skipped (the version-cutover error is
    strictly stronger and the operator's next action is the same:
    reset). *)
let check_reference_window json =
  match json with
  | `Assoc fields ->
    (match check_schema_version_field fields with
     | Error _ as e -> e
     | Ok () -> check_aggregate_semantics_field fields)
  | _ ->
    Error "OOD reference window must be a JSON object"

(** check_schema_version: legacy alias for {!check_reference_window}.

    Pre-v0.10.0 callers expected this entry point to enforce only the
    [schema_version] cutover. From v0.10.0 onward it enforces both
    [schema_version] {b and} [aggregate_semantics] — a window that
    passed the old check but lacks the canonical aggregate semantics
    sentinel will now correctly fail with reset guidance. *)
let check_schema_version = check_reference_window
