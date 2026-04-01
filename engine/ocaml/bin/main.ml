(** TSC Engine — CLI entrypoint.

    Wires pure library modules with I/O.
    Usage: tsc-engine measure --target <name> [--instruction <path>] *)

open Tsc_engine

(** Read a file, return (Ok content) or (Error msg). *)
let read_file path =
  if Sys.file_exists path then
    let ic = open_in path in
    Fun.protect ~finally:(fun () -> close_in ic) (fun () ->
      let len = in_channel_length ic in
      Ok (really_input_string ic len)
    )
  else
    Error (Printf.sprintf "file not found: %s" path)

(** Expand a glob pattern into matching file paths.
    Simplified: handles ** /*, specific files, and directory prefixes. *)
let expand_glob ~root pattern =
  let is_glob s = String.contains s '*' in
  if not (is_glob pattern) then begin
    let full = Filename.concat root pattern in
    if Sys.file_exists full then [pattern] else []
  end else begin
    (* Walk directory tree and match against pattern prefix/suffix *)
    let results = ref [] in
    let rec walk dir =
      let entries = Sys.readdir dir in
      Array.iter (fun entry ->
        let full = Filename.concat dir entry in
        if Sys.is_directory full then
          walk full
        else begin
          let rel =
            let root_len = String.length root + 1 in
            if String.length full > root_len then
              String.sub full root_len (String.length full - root_len)
            else full
          in
          (* Simple pattern matching: prefix** /*.suffix *)
          let prefix =
            match String.split_on_char '*' pattern with
            | p :: _ -> p
            | [] -> ""
          in
          let suffix =
            let parts = String.split_on_char '*' pattern in
            match List.rev parts with
            | s :: _ when String.length s > 0 -> s
            | _ -> ""
          in
          let matches_prefix =
            String.length prefix = 0
            || (String.length rel >= String.length prefix
                && String.sub rel 0 (String.length prefix) = prefix)
          in
          let matches_suffix =
            String.length suffix = 0
            || (String.length rel >= String.length suffix
                && String.sub rel
                     (String.length rel - String.length suffix)
                     (String.length suffix) = suffix)
          in
          if matches_prefix && matches_suffix then
            results := rel :: !results
        end
      ) entries
    in
    (try walk root with Sys_error _ -> ());
    List.sort String.compare !results
  end

(** Resolve a target manifest into (path, content) pairs. *)
let resolve_files ~root manifest =
  let included =
    List.concat_map (expand_glob ~root) manifest.Types.manifest_include
  in
  let excluded =
    List.concat_map (expand_glob ~root) manifest.Types.manifest_exclude
  in
  let filtered =
    List.filter (fun p -> not (List.mem p excluded)) included
  in
  List.filter_map (fun path ->
    match read_file (Filename.concat root path) with
    | Ok content -> Some (path, content)
    | Error _ -> None
  ) filtered

(** Get current timestamp as ISO 8601. *)
let timestamp () =
  let t = Unix.gettimeofday () in
  let tm = Unix.gmtime t in
  Printf.sprintf "%04d-%02d-%02dT%02d:%02d:%02dZ"
    (tm.Unix.tm_year + 1900)
    (tm.Unix.tm_mon + 1)
    tm.Unix.tm_mday
    tm.Unix.tm_hour
    tm.Unix.tm_min
    tm.Unix.tm_sec

(** Parse CLI arguments. *)
type cli_args = {
  cli_target : string;
  cli_instruction : string;
  cli_root : string;
  cli_output_dir : string;
}

let parse_args () =
  let target = ref "" in
  let instruction = ref "runtime/SELF-MEASURE.md" in
  let root = ref "." in
  let output_dir = ref ".tsc" in
  let specs = [
    ("--target", Arg.Set_string target, "Target name (spec, engine, repo)");
    ("--instruction", Arg.Set_string instruction, "Path to self-measure instruction");
    ("--root", Arg.Set_string root, "Repository root directory");
    ("--output", Arg.Set_string output_dir, "Output directory for reports");
  ] in
  let usage = "tsc-engine measure --target <name> [options]" in
  Arg.parse specs (fun _ -> ()) usage;
  if !target = "" then begin
    Arg.usage specs usage;
    exit 1
  end;
  {
    cli_target = !target;
    cli_instruction = !instruction;
    cli_root = !root;
    cli_output_dir = !output_dir;
  }

(** Write a string to a file, creating parent directories. *)
let write_file path content =
  let dir = Filename.dirname path in
  if not (Sys.file_exists dir) then
    ignore (Sys.command (Printf.sprintf "mkdir -p '%s'" dir));
  let oc = open_out path in
  Fun.protect ~finally:(fun () -> close_out oc) (fun () ->
    output_string oc content
  )

(** Main entry point. *)
let () =
  let args = parse_args () in
  let root = args.cli_root in

  (* Step 1: Load registry *)
  Printf.eprintf "Loading target registry...\n%!";
  let registry_path = Filename.concat root "targets/registry.tsc" in
  let registry =
    match read_file registry_path with
    | Error e -> Printf.eprintf "Error: %s\n" e; exit 1
    | Ok content ->
      match Target_registry.parse_registry content with
      | Error e -> Printf.eprintf "Error parsing registry: %s\n" e; exit 1
      | Ok r -> r
  in

  (* Step 2: Resolve target *)
  Printf.eprintf "Resolving target '%s'...\n%!" args.cli_target;
  let manifest_path =
    match Target_registry.resolve_target_path registry args.cli_target with
    | Error e -> Printf.eprintf "Error: %s\n" e; exit 1
    | Ok p -> Filename.concat root p
  in
  let manifest =
    match read_file manifest_path with
    | Error e -> Printf.eprintf "Error: %s\n" e; exit 1
    | Ok content ->
      match Target_registry.parse_manifest content with
      | Error e -> Printf.eprintf "Error parsing manifest: %s\n" e; exit 1
      | Ok m -> m
  in

  (* Step 3: Build bundle *)
  Printf.eprintf "Building file bundle...\n%!";
  let files = resolve_files ~root manifest in
  let bundle =
    Bundle.build_bundle
      ~target_name:args.cli_target
      ~target_kind:manifest.manifest_kind
      ~files
  in
  Printf.eprintf "Bundle contains %d files.\n%!" (List.length bundle.Types.bundle_files);

  (* Step 4: Load instruction *)
  let instruction =
    match read_file (Filename.concat root args.cli_instruction) with
    | Error e -> Printf.eprintf "Error: %s\n" e; exit 1
    | Ok content -> content
  in

  (* Step 5: Build prompt *)
  let system_msg = Prompt.build_system_message ~instruction in
  let user_msg = Prompt.build_user_message ~bundle in

  (* Step 6: Call provider *)
  Printf.eprintf "Loading provider configuration from environment...\n%!";
  let config =
    match Provider.config_from_env () with
    | Error e -> Printf.eprintf "Error: %s\n" e; exit 1
    | Ok c -> c
  in
  Printf.eprintf "Calling %s/%s...\n%!" config.provider_name config.provider_model;
  let _response =
    match Provider.call_provider ~config ~system_message:system_msg ~user_message:user_msg with
    | Error e -> Printf.eprintf "Error calling provider: %s\n" e; exit 1
    | Ok r -> r
  in

  (* Step 7: Validate response *)
  (* Note: Full JSON parsing requires a JSON library.
     For v0.1.0, we output the raw response and metadata. *)
  Printf.eprintf "Provider responded. Writing raw output...\n%!";

  (* Step 8: Write reports *)
  let ts = timestamp () in
  let metadata : Types.run_metadata = {
    meta_target = args.cli_target;
    meta_file_hashes =
      List.map (fun f ->
        (f.Types.file_path, f.Types.file_hash)
      ) bundle.Types.bundle_files;
    meta_prompt_version = "SELF-MEASURE/1.0";
    meta_provider = config.provider_name;
    meta_model = config.provider_model;
    meta_timestamp = ts;
  } in

  let raw_report_path =
    Filename.concat args.cli_output_dir
      (Printf.sprintf "tsc-%s-%s-raw.txt" args.cli_target ts)
  in
  write_file raw_report_path _response;

  let meta_path =
    Filename.concat args.cli_output_dir
      (Printf.sprintf "tsc-%s-%s-meta.json" args.cli_target ts)
  in
  let meta_json =
    Printf.sprintf
      {|{"target":"%s","prompt_version":"%s","provider":"%s","model":"%s","timestamp":"%s","file_count":%d}|}
      metadata.meta_target
      metadata.meta_prompt_version
      metadata.meta_provider
      metadata.meta_model
      metadata.meta_timestamp
      (List.length metadata.meta_file_hashes)
  in
  write_file meta_path meta_json;

  Printf.printf "Done. Reports written to:\n  %s\n  %s\n" raw_report_path meta_path;
  ignore metadata
