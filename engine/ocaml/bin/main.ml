(** Coherence engine — CLI entrypoint.

    Wires pure library modules with I/O.

    Modes:
      mechanical  — structural-proxy scoring, no credentials required
      llm         — semantic scoring via SELF-MEASURE.md (default before v0.5.0)
      hybrid      — run both backends, produce unified report
      auto        — hybrid when credentials are present, else mechanical

    Inputs:
      --target <name> --registry <path>    named target (any mode)
      --files <glob>  [--files <glob>...]  direct file input (mechanical / hybrid) *)

open Tsc_engine
open Tsc_engine.Types

(* ------------------------------------------------------------------ *)
(* Utility: file I/O *)

let read_file path =
  if Sys.file_exists path then
    let ic = open_in path in
    Fun.protect ~finally:(fun () -> close_in ic) (fun () ->
      let len = in_channel_length ic in
      Ok (really_input_string ic len)
    )
  else
    Error (Printf.sprintf "file not found: %s" path)

let rec mkdir_p path =
  if Sys.file_exists path then ()
  else begin
    mkdir_p (Filename.dirname path);
    (try Unix.mkdir path 0o755 with Unix.Unix_error (Unix.EEXIST, _, _) -> ())
  end

let write_file path content =
  mkdir_p (Filename.dirname path);
  let oc = open_out path in
  Fun.protect ~finally:(fun () -> close_out oc) (fun () ->
    output_string oc content
  )

(* ------------------------------------------------------------------ *)
(* Utility: glob expansion *)

(** Expand a glob pattern into matching file paths relative to root. *)
let expand_glob ~root pattern =
  let is_glob s = String.contains s '*' in
  if not (is_glob pattern) then begin
    let full = Filename.concat root pattern in
    if Sys.file_exists full then [pattern] else []
  end else begin
    let results = ref [] in
    let rec walk dir =
      let entries = try Sys.readdir dir with Sys_error _ -> [||] in
      Array.iter (fun entry ->
        let full = Filename.concat dir entry in
        let rel =
          let root_len = String.length root + 1 in
          if String.length full > root_len
          then String.sub full root_len (String.length full - root_len)
          else full
        in
        if Sys.is_directory full then walk full
        else begin
          let prefix = match String.split_on_char '*' pattern with p :: _ -> p | [] -> "" in
          let suffix =
            match List.rev (String.split_on_char '*' pattern) with
            | s :: _ when String.length s > 0 -> s
            | _ -> ""
          in
          let starts_with_prefix =
            String.length prefix = 0
            || (String.length rel >= String.length prefix
                && String.sub rel 0 (String.length prefix) = prefix)
          in
          let ends_with_suffix =
            String.length suffix = 0
            || (String.length rel >= String.length suffix
                && String.sub rel
                     (String.length rel - String.length suffix)
                     (String.length suffix) = suffix)
          in
          if starts_with_prefix && ends_with_suffix then
            results := rel :: !results
        end
      ) entries
    in
    walk root;
    List.sort String.compare !results
  end

(** Resolve named-target manifest files into (path, content) pairs. *)
let resolve_manifest_files ~root manifest =
  let included =
    List.concat_map (expand_glob ~root) manifest.manifest_include
  in
  let excluded =
    List.concat_map (expand_glob ~root) manifest.manifest_exclude
  in
  let filtered = List.filter (fun p -> not (List.mem p excluded)) included in
  List.filter_map (fun path ->
    match read_file (Filename.concat root path) with
    | Ok content -> Some (path, content)
    | Error msg ->
      Printf.eprintf "Warning: skipping %s: %s\n%!" path msg;
      None
  ) filtered

let resolve_files ~root ~registry manifest =
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
  let own_files = resolve_manifest_files ~root manifest in
  let seen = Hashtbl.create 64 in
  let dedup files =
    List.filter (fun (path, _) ->
      if Hashtbl.mem seen path then false
      else begin Hashtbl.add seen path (); true end
    ) files
  in
  dedup (nested_files @ own_files)

(** Expand glob patterns for --files mode. *)
let resolve_direct_files ~root globs =
  let paths = List.concat_map (expand_glob ~root) globs in
  List.sort_uniq String.compare paths
  |> List.filter_map (fun path ->
    match read_file (Filename.concat root path) with
    | Ok content -> Some (path, content)
    | Error msg ->
      Printf.eprintf "Warning: skipping %s: %s\n%!" path msg;
      None
  )

(* ------------------------------------------------------------------ *)
(* Timestamp *)

let timestamp () =
  let t = Unix.gettimeofday () in
  let tm = Unix.gmtime t in
  Printf.sprintf "%04d-%02d-%02dT%02d:%02d:%02dZ"
    (tm.Unix.tm_year + 1900) (tm.Unix.tm_mon + 1) tm.Unix.tm_mday
    tm.Unix.tm_hour tm.Unix.tm_min tm.Unix.tm_sec

(* ------------------------------------------------------------------ *)
(* CLI *)

type mode = Mechanical | Llm | Hybrid | Auto

let parse_mode s =
  match String.lowercase_ascii s with
  | "mechanical" -> Some Mechanical
  | "llm"        -> Some Llm
  | "hybrid"     -> Some Hybrid
  | "auto"       -> Some Auto
  | _            -> None

type cli_args = {
  cli_mode       : mode;
  cli_target     : string;       (* "" when using --files *)
  cli_registry   : string;
  cli_instruction: string;
  cli_root       : string;
  cli_output_dir : string;
  cli_files      : string list;  (* globs for direct file input *)
}

let () =
  if Array.length Sys.argv = 2 && Sys.argv.(1) = "--version" then begin
    Printf.printf "coh %s (%s)\n" Build_version.version Build_commit.commit;
    exit 0
  end

let parse_args () =
  let mode_s    = ref "auto" in
  let target    = ref "" in
  let registry  = ref "targets/registry.tsc" in
  let instruction = ref "runtime/SELF-MEASURE.md" in
  let root      = ref "." in
  let output_dir = ref ".tsc" in
  let files     = ref [] in
  let specs = [
    ("--mode",        Arg.Set_string mode_s,
     "Scoring mode: mechanical | llm | hybrid | auto (default: auto)");
    ("--target",      Arg.Set_string target,
     "Named target (requires --registry)");
    ("--registry",    Arg.Set_string registry,
     "Path to targets/registry.tsc");
    ("--files",       Arg.String (fun f -> files := f :: !files),
     "Glob pattern for direct file input (repeatable)");
    ("--instruction", Arg.Set_string instruction,
     "Path to LLM scoring instruction (default: runtime/SELF-MEASURE.md)");
    ("--root",        Arg.Set_string root,
     "Repository root directory (default: .)");
    ("--output",      Arg.Set_string output_dir,
     "Output directory for reports (default: .tsc)");
  ] in
  let usage = "coh --mode <mode> [--target <name> | --files <glob>...] [options]" in
  Arg.parse specs (fun _ -> ()) usage;
  let mode = match parse_mode !mode_s with
    | Some m -> m
    | None ->
      Printf.eprintf "Error: unknown mode '%s'. Use mechanical | llm | hybrid | auto\n" !mode_s;
      exit 1
  in
  if !target = "" && !files = [] then begin
    Printf.eprintf "Error: provide --target <name> or --files <glob>\n";
    Arg.usage specs usage;
    exit 1
  end;
  { cli_mode        = mode;
    cli_target      = !target;
    cli_registry    = !registry;
    cli_instruction = !instruction;
    cli_root        = !root;
    cli_output_dir  = !output_dir;
    cli_files       = List.rev !files }

(* ------------------------------------------------------------------ *)
(* Credential check for auto mode *)

let has_llm_credentials () =
  match Sys.getenv_opt "LLM_API_KEY" with
  | Some v when String.length v > 0 -> true
  | _ -> false

(* ------------------------------------------------------------------ *)
(* Bundle builders *)

let build_bundle_from_target ~root ~registry_path ~target_name =
  Printf.eprintf "Loading target registry from %s...\n%!" registry_path;
  let registry =
    match read_file registry_path with
    | Error e -> Printf.eprintf "Error: %s\n" e; exit 1
    | Ok content ->
      match Target_registry.parse_registry content with
      | Error e -> Printf.eprintf "Error parsing registry: %s\n" e; exit 1
      | Ok r -> r
  in
  Printf.eprintf "Resolving target '%s'...\n%!" target_name;
  let manifest_path =
    match Target_registry.resolve_target_path registry target_name with
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
  Printf.eprintf "Building file bundle...\n%!";
  let files = resolve_files ~root ~registry manifest in
  let bundle =
    Bundle.build_bundle
      ~target_name
      ~target_kind:manifest.manifest_kind
      ~files
  in
  Printf.eprintf "Bundle: %d files.\n%!" (List.length bundle.bundle_files);
  bundle

let build_bundle_from_files ~root ~globs =
  Printf.eprintf "Resolving file patterns...\n%!";
  let files = resolve_direct_files ~root globs in
  Printf.eprintf "Bundle: %d files.\n%!" (List.length files);
  Bundle.build_bundle
    ~target_name:"direct"
    ~target_kind:Aggregate
    ~files

(* ------------------------------------------------------------------ *)
(* Mode execution *)

let run_mechanical ~args ~bundle ~ts =
  Printf.eprintf "Running mechanical scoring...\n%!";
  let result = Mechanical_scoring.score_bundle bundle in
  Printf.eprintf "%s\n%!" (Mechanical_scoring.summarize_result result);
  let json_path =
    Filename.concat args.cli_output_dir
      (Printf.sprintf "tsc-%s-%s.json"
         (Option.value ~default:"direct" result.target) ts)
  in
  write_file json_path (Yojson.Safe.pretty_to_string (Mechanical_scoring.result_to_json result));
  Printf.printf "Done. Mechanical report: %s\n" json_path

let run_llm ~args ~bundle ~ts =
  let instruction =
    match read_file (Filename.concat args.cli_root args.cli_instruction) with
    | Error e -> Printf.eprintf "Error: %s\n" e; exit 1
    | Ok content -> content
  in
  let system_msg = Prompt.build_system_message ~instruction in
  let user_msg   = Prompt.build_user_message   ~bundle in
  let env_file   = Filename.concat args.cli_root ".tsc/.env" in
  let n = Dotenv.load env_file in
  if n > 0 then Printf.eprintf "Loaded %d variable(s) from %s\n%!" n env_file;
  Printf.eprintf "Loading provider configuration...\n%!";
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
  Printf.eprintf "Validating response...\n%!";
  let validated_result =
    match Response_schema.parse_json raw_response with
    | Error e ->
      Printf.eprintf "Error: response is not valid JSON: %s\n" e;
      None
    | Ok j ->
      match Response_schema.validate_result j with
      | Error e ->
        Printf.eprintf "Warning: response did not pass schema validation: %s\n" e;
        None
      | Ok r ->
        Printf.eprintf "Response validated.\n%!";
        Some r
  in
  let metadata : run_metadata = {
    meta_target = bundle.bundle_target_name;
    meta_file_hashes =
      List.map (fun f -> (f.file_path, f.file_hash)) bundle.bundle_files;
    meta_prompt_version = "SELF-MEASURE/1.0";
    meta_provider = config.provider_name;
    meta_model    = config.provider_model;
    meta_timestamp = ts;
  } in
  let raw_path =
    Filename.concat args.cli_output_dir
      (Printf.sprintf "tsc-%s-%s-raw.txt" bundle.bundle_target_name ts)
  in
  write_file raw_path raw_response;
  (match validated_result with
   | Some result ->
     let json_path =
       Filename.concat args.cli_output_dir
         (Printf.sprintf "tsc-%s-%s.json" bundle.bundle_target_name ts)
     in
     write_file json_path (Report.to_json ~result ~metadata ~mode:"llm" ());
     let text_path =
       Filename.concat args.cli_output_dir
         (Printf.sprintf "tsc-%s-%s.txt" bundle.bundle_target_name ts)
     in
     write_file text_path (Report.to_text ~result ~metadata ~mode:"llm" ());
     Printf.printf "Done. LLM reports:\n  %s\n  %s\n  %s\n"
       raw_path json_path text_path
   | None ->
     Printf.printf "Done. Raw response: %s\n\
                    Structured reports not generated (validation failed).\n"
       raw_path)

let run_hybrid ~args ~bundle ~ts =
  Printf.eprintf "Running hybrid scoring (mechanical + LLM)...\n%!";
  let mech_result = Mechanical_scoring.score_bundle bundle in
  Printf.eprintf "Mechanical: %s\n%!" (Mechanical_scoring.summarize_result mech_result);
  (* LLM call *)
  let instruction =
    match read_file (Filename.concat args.cli_root args.cli_instruction) with
    | Error e -> Printf.eprintf "Error: %s\n" e; exit 1
    | Ok content -> content
  in
  let system_msg = Prompt.build_system_message ~instruction in
  let user_msg   = Prompt.build_user_message   ~bundle in
  let env_file   = Filename.concat args.cli_root ".tsc/.env" in
  let n = Dotenv.load env_file in
  if n > 0 then Printf.eprintf "Loaded %d variable(s) from %s\n%!" n env_file;
  Printf.eprintf "Loading provider configuration...\n%!";
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
  Printf.eprintf "Validating LLM response...\n%!";
  let llm_result =
    match Response_schema.parse_json raw_response with
    | Error e ->
      Printf.eprintf "Error: LLM response is not valid JSON: %s\n" e;
      exit 1
    | Ok j ->
      match Response_schema.validate_result j with
      | Error e ->
        Printf.eprintf "Error: LLM response failed schema validation: %s\n" e;
        exit 1
      | Ok r -> r
  in
  let hybrid =
    Hybrid_scoring.combine ~target:bundle.bundle_target_name mech_result llm_result
  in
  let json_path =
    Filename.concat args.cli_output_dir
      (Printf.sprintf "tsc-%s-%s.json" bundle.bundle_target_name ts)
  in
  write_file json_path (Yojson.Safe.pretty_to_string (Hybrid_scoring.to_json hybrid));
  Printf.printf "Done. Hybrid report: %s\n" json_path

(* ------------------------------------------------------------------ *)
(* Entrypoint *)

let () =
  let args = parse_args () in
  let ts = timestamp () in
  let root = args.cli_root in

  (* Resolve effective mode (auto → mechanical or hybrid) *)
  let effective_mode = match args.cli_mode with
    | Auto ->
      if has_llm_credentials () then begin
        Printf.eprintf "Auto mode: credentials found — running hybrid.\n%!";
        Hybrid
      end else begin
        Printf.eprintf "Auto mode: no credentials — running mechanical.\n%!";
        Mechanical
      end
    | m -> m
  in

  (* Build bundle from target or files *)
  let bundle =
    if args.cli_target <> "" then
      build_bundle_from_target
        ~root
        ~registry_path:(Filename.concat root args.cli_registry)
        ~target_name:args.cli_target
    else
      build_bundle_from_files ~root ~globs:args.cli_files
  in

  (* Dispatch *)
  match effective_mode with
  | Mechanical -> run_mechanical ~args ~bundle ~ts
  | Llm        -> run_llm        ~args ~bundle ~ts
  | Hybrid     -> run_hybrid     ~args ~bundle ~ts
  | Auto       -> assert false  (* resolved above *)
