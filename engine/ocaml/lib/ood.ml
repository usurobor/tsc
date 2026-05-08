(** OOD cutover guard: warn when a reference window predates v3.2.0.

    When the engine reads an OOD reference window, it must check schema_version.
    If schema_version < "v3.2.0", the historical C_Sigma values are not
    comparable across the barrier-transform cutover (spec/tsc-core.md §12) and
    the reference distribution must be reset.

    Returns Ok () when the reference window is compatible, Error msg when not. *)

let cutover_version = "v3.2.0"

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

(** check_schema_version: validate that a reference window JSON object carries
    a schema_version >= v3.2.0.

    On success: Ok ()
    On version too old: Error with the cutover-reset diagnostic message
    On missing field: Error with missing-field message
    On parse error: Error with parse message *)
let check_schema_version json =
  match json with
  | `Assoc fields ->
    (match List.assoc_opt "schema_version" fields with
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
       Error "OOD reference window missing required field 'schema_version'")
  | _ ->
    Error "OOD reference window must be a JSON object"
