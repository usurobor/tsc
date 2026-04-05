(** Coherence engine — CLI entrypoint.

    Wires pure library modules with I/O.
    Usage: coh --target <name> [--instruction <path>] *)

open Tsc_engine
open Tsc_engine.Types

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

(** Resolve a single manifest's include/exclude into (path, content) pairs. *)
let resolve_manifest_files ~root manifest =
  let included =
    List.concat_map (expand_glob ~root) manifest.manifest_include
  in
  let excluded =
    List.concat_map (expand_glob ~root) manifest.manifest_exclude
  in
  let filtered =
    List.filter (fun p -> not (List.mem p excluded)) included
  in
  List.filter_map (fun path ->
    match read_file (Filename.concat root path) with
    | Ok content -> Some (path, content)
    | Error msg ->
      Printf.eprintf "Warning: skipping %s: %s\n%!" path msg;
      None
  ) filtered

(** Resolve a target with include_targets expansion.
    Loads nested target manifests from the registry and merges their files. *)
let resolve_files ~root ~registry manifest =
  (* First resolve any nested include_targets *)
  let nested_files =
    List.concat_map (fun target_name ->
      match Target_registry.resolve_target_path registry target_name with
      | Error e ->
        Printf.eprintf "Warning: cannot resolve nested target '%s': %s\n%!" target_name e;
        []
      | Ok manifest_path ->
        match read_file (Filename.concat root manifest_path) with
        | Error e ->
          Printf.eprintf "Warning: cannot read manifest for '%s': %s\n%!" target_name e;
          []
        | Ok content ->
          match Target_registry.parse_manifest content with
          | Error e ->
            Printf.eprintf "Warning: cannot parse manifest for '%s': %s\n%!" target_name e;
            []
          | Ok nested_manifest ->
            resolve_manifest_files ~root nested_manifest
    ) manifest.manifest_include_targets
  in
  (* Then resolve this manifest's own includes *)
  let own_files = resolve_manifest_files ~root manifest in
  (* Merge, dedup by path, preserving order *)
  let seen = Hashtbl.create 64 in
  let dedup files =
    List.filter (fun (path, _) ->
      if Hashtbl.mem seen path then false
      else begin Hashtbl.add seen path (); true end
    ) files
  in
  dedup (nested_files @ own_files)

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

let version =
  match Build_info.V1.version () with
  | None -> "dev"
  | Some v -> Build_info.V1.Version.to_string v

let () =
  if Array.length Sys.argv = 2 && Sys.argv.(1) = "--version" then begin
    Printf.printf "coh %s (%s)\n" version Build_commit.commit;
    exit 0
  end

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
  let usage = "coh --target <name> [options]" in
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

(** Create directory and parents. No shell — uses Unix.mkdir directly. *)
let rec mkdir_p path =
  if Sys.file_exists path then ()
  else begin
    mkdir_p (Filename.dirname path);
    (try Unix.mkdir path 0o755 with Unix.Unix_error (Unix.EEXIST, _, _) -> ())
  end

(** Write a string to a file, creating parent directories. *)
let write_file path content =
  mkdir_p (Filename.dirname path);
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
  let files = resolve_files ~root ~registry manifest in
  let bundle =
    Bundle.build_bundle
      ~target_name:args.cli_target
      ~target_kind:manifest.manifest_kind
      ~files
  in
  Printf.eprintf "Bundle contains %d files.\n%!" (List.length bundle.bundle_files);

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
  let raw_response =
    match Provider.call_provider ~config ~system_message:system_msg ~user_message:user_msg with
    | Error e -> Printf.eprintf "Error calling provider: %s\n" e; exit 1
    | Ok r -> r
  in

  (* Step 7: Validate response *)
  Printf.eprintf "Validating response...\n%!";
  let json =
    match Response_schema.parse_json raw_response with
    | Error e ->
      Printf.eprintf "Error: response is not valid JSON: %s\n" e;
      Printf.eprintf "Raw response saved for inspection.\n";
      (* Fall through to save raw response even on parse failure *)
      None
    | Ok j -> Some j
  in
  let validated_result =
    match json with
    | None -> None
    | Some j ->
      match Response_schema.validate_result j with
      | Error e ->
        Printf.eprintf "Warning: response did not pass schema validation: %s\n" e;
        None
      | Ok r ->
        Printf.eprintf "Response validated successfully.\n%!";
        Some r
  in

  (* Step 8: Write reports *)
  let ts = timestamp () in
  let metadata : run_metadata = {
    meta_target = args.cli_target;
    meta_file_hashes =
      List.map (fun f ->
        (f.file_path, f.file_hash)
      ) bundle.bundle_files;
    meta_prompt_version = "SELF-MEASURE/1.0";
    meta_provider = config.provider_name;
    meta_model = config.provider_model;
    meta_timestamp = ts;
  } in

  (* Always write raw response *)
  let raw_report_path =
    Filename.concat args.cli_output_dir
      (Printf.sprintf "tsc-%s-%s-raw.txt" args.cli_target ts)
  in
  write_file raw_report_path raw_response;

  (* Write structured reports if validation passed *)
  (match validated_result with
   | Some result ->
     let json_path =
       Filename.concat args.cli_output_dir
         (Printf.sprintf "tsc-%s-%s.json" args.cli_target ts)
     in
     write_file json_path (Report.to_json ~result ~metadata);
     let text_path =
       Filename.concat args.cli_output_dir
         (Printf.sprintf "tsc-%s-%s.txt" args.cli_target ts)
     in
     write_file text_path (Report.to_text ~result ~metadata);
     Printf.printf "Done. Reports written to:\n  %s\n  %s\n  %s\n"
       raw_report_path json_path text_path
   | None ->
     Printf.printf "Done. Raw response written to:\n  %s\n\
                     Structured reports not generated (validation failed).\n"
       raw_report_path
  )
