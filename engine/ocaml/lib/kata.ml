(** Kata framework — loads and validates kata configurations.

    Each kata lives in [katas/<id>/kata.toml]. This module parses the manifest
    and exposes the configuration for the kata runner in [bin/main.ml].

    Phase 1 scope: mechanical-mode only. No LLM calls. *)

(** Kata configuration parsed from kata.toml *)
type kata_config = {
  id          : string;
  difficulty  : int;
  mode        : string;
  description : string;
  input_files : string list;
  verdict     : string;
  score_min   : float;
  score_max   : float;
}

(** Load a kata configuration from katas/<id>/kata.toml.

    Returns [Ok config] on success, [Error msg] on failure. *)
let load katas_dir id =
  let kata_dir  = Filename.concat katas_dir id in
  let toml_path = Filename.concat kata_dir "kata.toml" in
  if not (Sys.file_exists toml_path) then
    Error (Printf.sprintf "kata not found: %s" toml_path)
  else begin
    match Otoml.Parser.from_file_result toml_path with
    | Error e -> Error (Printf.sprintf "kata.toml parse error (%s): %s" toml_path e)
    | Ok tbl ->
      let get_str path =
        match Otoml.Helpers.find_string_opt tbl path with
        | Some s -> s
        | None   -> ""
      in
      let get_int path =
        match Otoml.Helpers.find_integer_opt tbl path with
        | Some n -> n
        | None   -> 1
      in
      let get_float_opt path =
        match Otoml.Helpers.find_float_opt tbl path with
        | Some f -> Some f
        | None   ->
          (* TOML may store as integer (e.g. "min = 0") — try integer conversion *)
          (match Otoml.Helpers.find_integer_opt tbl path with
           | Some n -> Some (float_of_int n)
           | None   -> None)
      in
      (* [input].files array *)
      let input_files =
        match Otoml.Helpers.find_strings_opt tbl ["input"; "files"] with
        | Some fs -> fs
        | None    -> []
      in
      (* [expected].verdict *)
      let verdict =
        match Otoml.Helpers.find_string_opt tbl ["expected"; "verdict"] with
        | Some v -> v
        | None   -> "pass"
      in
      (* [expected.score_range].min / .max *)
      let score_min =
        match get_float_opt ["expected"; "score_range"; "min"] with
        | Some v -> v
        | None   -> 0.0
      in
      let score_max =
        match get_float_opt ["expected"; "score_range"; "max"] with
        | Some v -> v
        | None   -> 1.0
      in
      Ok {
        id;
        difficulty  = get_int ["difficulty"];
        mode        = get_str ["mode"];
        description = get_str ["description"];
        input_files;
        verdict;
        score_min;
        score_max;
      }
  end
