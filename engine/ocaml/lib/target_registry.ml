(** Target registry: parse registry.tsc and target manifests.

    Pure module — no I/O. Receives file contents as strings.
    Caller is responsible for reading files from disk. *)

open Types

(** Parse a target kind string. *)
let parse_target_kind = function
  | "theory" -> Ok Theory
  | "implementation" -> Ok Implementation
  | "aggregate" -> Ok Aggregate
  | s -> Error (Printf.sprintf "unknown target kind: %s" s)

(** Extract a key = "value" pair from a line.
    Handles both quoted and unquoted values. *)
let parse_kv_line line =
  match String.split_on_char '=' line with
  | [] -> None
  | [_] -> None
  | key :: rest ->
    let key = String.trim key in
    let value = String.trim (String.concat "=" rest) in
    let value =
      if String.length value >= 2
         && value.[0] = '"'
         && value.[String.length value - 1] = '"'
      then String.sub value 1 (String.length value - 2)
      else value
    in
    Some (key, value)

(** Extract a string list from TOML-like array syntax.
    Expects lines like:
      include = [
        "spec/ ** /*.md"
      ] *)
let parse_string_list_block lines start_idx =
  let rec collect acc i =
    if i >= Array.length lines then (List.rev acc, i)
    else
      let line = String.trim lines.(i) in
      if line = "]" then (List.rev acc, i + 1)
      else
        let cleaned =
          line
          |> String.split_on_char '"'
          |> (function _ :: v :: _ -> Some v | _ -> None)
        in
        match cleaned with
        | Some v -> collect (v :: acc) (i + 1)
        | None -> collect acc (i + 1)
  in
  collect [] (start_idx + 1)

(** Parse a target manifest from its file content. *)
let parse_manifest (content : string) : (target_manifest, string) result =
  let lines = Array.of_list (String.split_on_char '\n' content) in
  let n = Array.length lines in
  let name = ref "" in
  let kind = ref "" in
  let description = ref "" in
  let include_list = ref [] in
  let exclude_list = ref [] in
  let optional_list = ref [] in
  let include_targets = ref [] in
  let i = ref 0 in
  while !i < n do
    let line = String.trim lines.(!i) in
    if String.length line = 0 || line.[0] = '#' then
      incr i
    else
      match parse_kv_line line with
      | Some ("name", v) -> name := v; incr i
      | Some ("kind", v) -> kind := v; incr i
      | Some ("description", v) -> description := v; incr i
      | Some ("format", _) -> incr i  (* skip format line *)
      | Some (key, _) when String.contains line '[' ->
        let lst, next_i = parse_string_list_block lines !i in
        (match key with
         | "include" -> include_list := lst
         | "exclude" -> exclude_list := lst
         | "optional" -> optional_list := lst
         | "include_targets" -> include_targets := lst
         | _ -> ());
        i := next_i
      | _ -> incr i
  done;
  match parse_target_kind !kind with
  | Error e -> Error e
  | Ok k ->
    Ok {
      manifest_name = !name;
      manifest_kind = k;
      manifest_description = !description;
      manifest_include = !include_list;
      manifest_exclude = !exclude_list;
      manifest_optional = !optional_list;
      manifest_include_targets = !include_targets;
    }

(** Parse the target registry from registry.tsc content. *)
let parse_registry (content : string) : (target_registry, string) result =
  let lines = String.split_on_char '\n' content in
  let format_ref = ref "" in
  let default_ref = ref "" in
  let targets = ref [] in
  let current_target = ref None in
  List.iter (fun line ->
    let line = String.trim line in
    if String.length line > 0 && line.[0] <> '#' then
      match parse_kv_line line with
      | Some ("format", v) -> format_ref := v
      | Some ("default_target", v) -> default_ref := v
      | Some ("manifest", v) ->
        (match !current_target with
         | Some name -> targets := (name, v) :: !targets
         | None -> ())
      | _ ->
        (* Check for [target.xxx] section header *)
        if String.length line > 8
           && String.sub line 0 8 = "[target."
        then begin
          let name = String.sub line 8 (String.length line - 9) in
          current_target := Some name
        end
  ) lines;
  if !format_ref = "" then Error "missing format field in registry"
  else
    Ok {
      registry_format = !format_ref;
      registry_default_target = !default_ref;
      registry_targets = List.rev !targets;
    }

(** Resolve a target name to its manifest path using the registry. *)
let resolve_target_path registry target_name =
  match List.assoc_opt target_name registry.registry_targets with
  | Some path -> Ok path
  | None ->
    Error (Printf.sprintf "target '%s' not found in registry" target_name)
