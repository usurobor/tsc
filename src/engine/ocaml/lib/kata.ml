(** Kata framework — loads and validates kata configurations.

    Each kata lives in [katas/<id>/kata.toml]. This module parses the manifest
    and exposes the configuration for the kata runner in [bin/main.ml].

    Phase 1 scope: mechanical-mode only. No LLM calls.

    Phase 2 (cycle #34) extension: [[components]] + [expected].ranking for
    comparative katas. A kata with [components <> []] is scored once per
    component; [ranking] asserts a per-component C_Σ ordering rather than a
    single-bundle [score_range]. Phase 1 katas (no [[components]]) are
    unaffected. *)

(** A scoring component — a named sub-bundle used by comparative katas. *)
type kata_component = {
  comp_id    : string;       (* component id (must be unique within the kata) *)
  comp_files : string list;  (* file paths relative to the kata directory *)
}

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
  (* Phase 2 — empty for Phase 1 katas. *)
  components  : kata_component list;
  ranking     : string list;
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
      (* Phase 2: [[components]] array of tables.

         otoml stores `[[components]]` as a list of tables at key
         ["components"]. We pull each entry's `id` (string) and `files`
         (string array). Phase 1 katas omit this section, so we default
         to []. *)
      let components =
        match Otoml.find_opt tbl (Otoml.get_array (fun x -> x)) ["components"] with
        | None | Some [] -> []
        | Some entries ->
          List.filter_map (fun entry ->
            match Otoml.get_opt Otoml.get_table entry with
            | None -> None
            | Some kvs ->
              let lookup k = try Some (List.assoc k kvs) with Not_found -> None in
              let id_opt =
                match lookup "id" with
                | Some v -> Otoml.get_opt Otoml.get_string v
                | None -> None
              in
              let files_opt =
                match lookup "files" with
                | Some v ->
                  Otoml.get_opt (Otoml.get_array Otoml.get_string) v
                | None -> None
              in
              (match id_opt, files_opt with
               | Some cid, Some cfiles -> Some { comp_id = cid; comp_files = cfiles }
               | _ -> None)
          ) entries
      in
      let ranking =
        match Otoml.Helpers.find_strings_opt tbl ["expected"; "ranking"] with
        | Some xs -> xs
        | None    -> []
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
        components;
        ranking;
      }
  end
