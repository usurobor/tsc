(** Coherence engine — CLI entrypoint.

    Wires pure library modules with I/O.
    Usage: coh [--mode mechanical|llm|hybrid|auto] --target <name> [options]
           coh --mode mechanical --files <paths...> *)

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

(** Resolve a target with include_targets expansion. *)
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

(* --- Scoring mode --- *)

type scoring_mode = Mechanical | Llm | Hybrid | Auto

let string_of_mode = function
  | Mechanical -> "mechanical"
  | Llm -> "llm"
  | Hybrid -> "hybrid"
  | Auto -> "auto"

let parse_mode s =
  match String.lowercase_ascii s with
  | "mechanical" -> Ok Mechanical
  | "llm" -> Ok Llm
  | "hybrid" -> Ok Hybrid
  | "auto" -> Ok Auto
  | _ -> Error (Printf.sprintf "unknown mode '%s' (expected: mechanical, llm, hybrid, auto)" s)

(* --- CLI --- *)

type cli_args = {
  cli_target : string;
  cli_instruction : string;
  cli_root : string;
  cli_output_dir : string;
  cli_mode : scoring_mode;
  cli_files : string list;
}

let () =
  if Array.length Sys.argv = 2 && Sys.argv.(1) = "--version" then begin
    Printf.printf "coh %s (%s)\n" Build_version.version Build_commit.commit;
    exit 0
  end

let parse_args () =
  let target = ref "" in
  let instruction = ref "runtime/SELF-MEASURE.md" in
  let root = ref "." in
  let output_dir = ref ".tsc" in
  let mode_str = ref "auto" in
  let file_args = ref [] in
  let specs = [
    ("--target", Arg.Set_string target, "Target name (spec, engine, repo)");
    ("--instruction", Arg.Set_string instruction, "Path to self-measure instruction");
    ("--root", Arg.Set_string root, "Repository root directory");
    ("--output", Arg.Set_string output_dir, "Output directory for reports");
    ("--mode", Arg.Set_string mode_str, "Scoring mode: mechanical, llm, hybrid, auto (default: auto)");
    ("--files", Arg.Rest_all (fun args -> file_args := args), "Direct file paths to measure");
  ] in
  let usage = "coh [--mode mechanical|llm|hybrid|auto] --target <name> [options]\n\
               coh --mode mechanical --files <paths...>" in
  Arg.parse specs (fun arg -> file_args := arg :: !file_args) usage;
  let mode = match parse_mode !mode_str with
    | Ok m -> m
    | Error e -> Printf.eprintf "Error: %s\n" e; exit 1
  in
  if !target = "" && !file_args = [] then begin
    Arg.usage specs usage;
    exit 1
  end;
  {
    cli_target = !target;
    cli_instruction = !instruction;
    cli_root = !root;
    cli_output_dir = !output_dir;
    cli_mode = mode;
    cli_files = List.rev !file_args;
  }

(** Create directory and parents. *)
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

(** Load dotenv and provider config. Returns None if credentials absent. *)
let try_load_provider ~root =
  let env_file = Filename.concat root ".tsc/.env" in
  let n = Dotenv.load env_file in
  if n > 0 then Printf.eprintf "Loaded %d variable(s) from %s\n%!" n env_file;
  match Provider.config_from_env () with
  | Ok c -> Some c
  | Error _ -> None

(** Build a bundle from direct file paths. *)
let bundle_from_files ~root files =
  let file_pairs = List.filter_map (fun path ->
    let full = if Filename.is_relative path then Filename.concat root path else path in
    match read_file full with
    | Ok content -> Some (path, content)
    | Error msg ->
      Printf.eprintf "Warning: skipping %s: %s\n%!" path msg;
      None
  ) files in
  Bundle.build_bundle
    ~target_name:"(direct)"
    ~target_kind:Aggregate
    ~files:file_pairs

(** Run mechanical scoring and write reports. *)
let run_mechanical ~args ~bundle =
  Printf.eprintf "Running mechanical scoring...\n%!";
  let result = Mechanical_scoring.score_bundle bundle in
  Printf.eprintf "Mechanical scoring complete: C_Σ = %.3f\n%!" result.c_sigma;
  let ts = timestamp () in
  let target_label = match result.target with Some t -> t | None -> "direct" in
  let json_path =
    Filename.concat args.cli_output_dir
      (Printf.sprintf "tsc-%s-%s-mechanical.json" target_label ts)
  in
  write_file json_path
    (Yojson.Safe.pretty_to_string (Mechanical_scoring.result_to_json result));
  let text_path =
    Filename.concat args.cli_output_dir
      (Printf.sprintf "tsc-%s-%s-mechanical.txt" target_label ts)
  in
  write_file text_path (Mechanical_scoring.summarize_result result);
  Printf.printf "Done. Reports written to:\n  %s\n  %s\n" json_path text_path;
  result

(** Run LLM scoring and write reports. *)
let run_llm ~args ~bundle ~provider_config =
  Printf.eprintf "Loading LLM scoring instruction...\n%!";
  let root = args.cli_root in
  let instruction =
    match read_file (Filename.concat root args.cli_instruction) with
    | Error e -> Printf.eprintf "Error: %s\n" e; exit 1
    | Ok content -> content
  in
  let system_msg = Prompt.build_system_message ~instruction in
  let user_msg = Prompt.build_user_message ~bundle in
  Printf.eprintf "Calling %s/%s...\n%!"
    provider_config.provider_name provider_config.provider_model;
  let raw_response =
    match Provider.call_provider ~config:provider_config
            ~system_message:system_msg ~user_message:user_msg with
    | Error e -> Printf.eprintf "Error calling provider: %s\n" e; exit 1
    | Ok r -> r
  in
  Printf.eprintf "Validating response...\n%!";
  let json =
    match Response_schema.parse_json raw_response with
    | Error e ->
      Printf.eprintf "Error: response is not valid JSON: %s\n" e; None
    | Ok j -> Some j
  in
  let validated_result =
    match json with
    | None -> None
    | Some j ->
      match Response_schema.validate_result j with
      | Error e ->
        Printf.eprintf "Warning: validation failed: %s\n" e; None
      | Ok r ->
        Printf.eprintf "Response validated successfully.\n%!"; Some r
  in
  let ts = timestamp () in
  let metadata : run_metadata = {
    meta_target = args.cli_target;
    meta_file_hashes =
      List.map (fun f -> (f.file_path, f.file_hash)) bundle.bundle_files;
    meta_prompt_version = "SELF-MEASURE/1.0";
    meta_provider = provider_config.provider_name;
    meta_model = provider_config.provider_model;
    meta_timestamp = ts;
  } in
  let raw_report_path =
    Filename.concat args.cli_output_dir
      (Printf.sprintf "tsc-%s-%s-raw.txt" args.cli_target ts)
  in
  write_file raw_report_path raw_response;
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
  );
  validated_result

(** Run hybrid scoring: both mechanical and LLM on the same bundle. *)
let run_hybrid ~args ~bundle ~provider_config =
  let mech_result = run_mechanical ~args ~bundle in
  let llm_result = run_llm ~args ~bundle ~provider_config in
  (* Write combined hybrid report *)
  let ts = timestamp () in
  let target_label = if args.cli_target <> "" then args.cli_target else "direct" in
  let hybrid_json =
    `Assoc [
      ("target", `String target_label);
      ("mode", `String "hybrid");
      ("mechanical", Mechanical_scoring.result_to_json mech_result);
      ("llm", (match llm_result with
        | Some r ->
          `Assoc [
            ("alpha", `Float r.result_alpha);
            ("beta", `Float r.result_beta);
            ("gamma", `Float r.result_gamma);
            ("c_sigma", `Float ((r.result_alpha +. r.result_beta +. r.result_gamma) /. 3.0));
            ("evidence_kind", `String "semantic-judgment");
          ]
        | None -> `String "llm-failed"));
      ("final", (match llm_result with
        | Some r ->
          `Assoc [
            ("source", `String "llm");
            ("alpha", `Float r.result_alpha);
            ("beta", `Float r.result_beta);
            ("gamma", `Float r.result_gamma);
            ("c_sigma", `Float ((r.result_alpha +. r.result_beta +. r.result_gamma) /. 3.0));
          ]
        | None ->
          `Assoc [
            ("source", `String "mechanical");
            ("alpha", `Float mech_result.alpha.score);
            ("beta", `Float mech_result.beta.score);
            ("gamma", `Float mech_result.gamma.score);
            ("c_sigma", `Float mech_result.c_sigma);
          ]));
    ]
  in
  let hybrid_path =
    Filename.concat args.cli_output_dir
      (Printf.sprintf "tsc-%s-%s-hybrid.json" target_label ts)
  in
  write_file hybrid_path (Yojson.Safe.pretty_to_string hybrid_json);
  Printf.printf "Hybrid report: %s\n" hybrid_path

(** Main entry point. *)
let () =
  let args = parse_args () in
  let root = args.cli_root in

  (* Resolve effective mode *)
  let provider_config = try_load_provider ~root in
  let effective_mode = match args.cli_mode with
    | Auto ->
      if provider_config <> None then Hybrid else Mechanical
    | Llm ->
      if provider_config = None then begin
        Printf.eprintf "Error: --mode llm requires LLM credentials (LLM_PROVIDER, LLM_MODEL, LLM_API_KEY)\n";
        exit 1
      end;
      Llm
    | Hybrid ->
      if provider_config = None then begin
        Printf.eprintf "Error: --mode hybrid requires LLM credentials\n";
        exit 1
      end;
      Hybrid
    | Mechanical -> Mechanical
  in
  Printf.eprintf "Mode: %s\n%!" (string_of_mode effective_mode);

  (* Build the bundle *)
  let bundle =
    if args.cli_files <> [] then begin
      Printf.eprintf "Building bundle from %d direct files...\n%!" (List.length args.cli_files);
      bundle_from_files ~root args.cli_files
    end else begin
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
      Printf.eprintf "Building file bundle...\n%!";
      let files = resolve_files ~root ~registry manifest in
      Bundle.build_bundle
        ~target_name:args.cli_target
        ~target_kind:manifest.manifest_kind
        ~files
    end
  in
  Printf.eprintf "Bundle contains %d files.\n%!" (List.length bundle.bundle_files);

  (* Run scoring *)
  match effective_mode with
  | Mechanical ->
    ignore (run_mechanical ~args ~bundle)
  | Llm ->
    let config = match provider_config with
      | Some c -> c
      | None -> Printf.eprintf "Error: no credentials\n"; exit 1
    in
    ignore (run_llm ~args ~bundle ~provider_config:config)
  | Hybrid ->
    let config = match provider_config with
      | Some c -> c
      | None -> Printf.eprintf "Error: no credentials\n"; exit 1
    in
    run_hybrid ~args ~bundle ~provider_config:config
  | Auto -> assert false (* resolved above *)
