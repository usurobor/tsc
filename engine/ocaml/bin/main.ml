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
  cli_kata       : string;       (* "" when not using --kata *)
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
  let kata      = ref "" in
  let specs = [
    ("--mode",        Arg.Set_string mode_s,
     "Scoring mode: mechanical | llm | hybrid | auto (default: auto)");
    ("--kata",        Arg.Set_string kata,
     "Run kata <id> from katas/ directory (e.g. --kata 01-glider)");
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
  let usage = "coh --mode <mode> [--kata <id> | --target <name> | --files <glob>...] [options]" in
  Arg.parse specs (fun _ -> ()) usage;
  let mode = match parse_mode !mode_s with
    | Some m -> m
    | None ->
      Printf.eprintf "Error: unknown mode '%s'. Use mechanical | llm | hybrid | auto\n" !mode_s;
      exit 1
  in
  if !kata = "" && !target = "" && !files = [] then begin
    Printf.eprintf "Error: provide --kata <id>, --target <name>, or --files <glob>\n";
    Arg.usage specs usage;
    exit 1
  end;
  { cli_mode        = mode;
    cli_target      = !target;
    cli_registry    = !registry;
    cli_instruction = !instruction;
    cli_root        = !root;
    cli_output_dir  = !output_dir;
    cli_files       = List.rev !files;
    cli_kata        = !kata }

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
        let (d_ab, d_bg, d_ga) = match Response_schema.extract_deltas j with
          | Ok triple -> triple
          | Error _ -> (None, None, None)
        in
        Some (r, d_ab, d_bg, d_ga)
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
   | Some (result, d_ab, d_bg, d_ga) ->
     let json_path =
       Filename.concat args.cli_output_dir
         (Printf.sprintf "tsc-%s-%s.json" bundle.bundle_target_name ts)
     in
     write_file json_path (Report.to_json ~result ~metadata ~mode:"llm"
       ~delta_alpha_beta:d_ab ~delta_beta_gamma:d_bg ~delta_gamma_alpha:d_ga ());
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
(* Kata runner *)

(** Read each [files] entry under [kata_dir] and return (rel_to_root, content)
    pairs suitable for [Bundle.build_bundle]. Skips missing files with a
    warning. *)
let load_kata_files ~root ~kata_dir files =
  let abs_files = List.map (fun f -> Filename.concat kata_dir f) files in
  List.filter_map (fun abs_path ->
    let rel_path =
      let root_len = String.length root in
      if String.length abs_path > root_len + 1
         && String.sub abs_path 0 root_len = root
      then String.sub abs_path (root_len + 1) (String.length abs_path - root_len - 1)
      else abs_path
    in
    match read_file abs_path with
    | Ok content -> Some (rel_path, content)
    | Error msg ->
      Printf.eprintf "Warning: skipping %s: %s\n%!" abs_path msg;
      None
  ) abs_files

(** Run a kata: load kata.toml, score input files (or components), compare
    against expected verdict/range/ranking. *)
let run_kata ~root ~kata_id ~mode_override =
  let katas_dir = Filename.concat root "katas" in
  Printf.eprintf "Loading kata '%s'...\n%!" kata_id;
  match Tsc_engine.Kata.load katas_dir kata_id with
  | Error e ->
    Printf.eprintf "Error: %s\n" e;
    exit 1
  | Ok kata ->
    Printf.eprintf "Kata: %s (%s)\n%!" kata.Tsc_engine.Kata.id kata.description;
    let kata_dir = Filename.concat katas_dir kata.id in
    (* Determine effective mode *)
    let eff_mode =
      if mode_override <> "" then mode_override
      else if kata.mode <> "" then kata.mode
      else "mechanical"
    in
    (* Phase 1 + 2: mechanical-mode only. LLM-mode katas (AC6) deferred. *)
    (match parse_mode eff_mode with
     | Some (Llm | Hybrid | Auto) ->
       Printf.eprintf "Error: kata mode '%s' requires LLM credentials; Phase 1/2 katas are mechanical-only\n" eff_mode;
       exit 1
     | None ->
       Printf.eprintf "Error: unknown mode '%s'\n" eff_mode;
       exit 1
     | Some Mechanical -> ());
    (* Branch: comparative (components) vs single-bundle (Phase 1 katas).

       A kata is comparative iff it declares [[components]]. Comparative
       katas score each component separately and check [expected.ranking];
       single-bundle katas score [input.files] as one bundle and check
       [expected.verdict] + [expected.score_range]. *)
    if kata.components <> [] then begin
      Printf.eprintf "Running mechanical scoring for kata '%s' (comparative, %d components)...\n%!"
        kata_id (List.length kata.components);
      (* Score each component. *)
      let scored : (string * float * Tsc_engine.Mechanical_scoring.result) list =
        List.map (fun comp ->
          let cid = comp.Tsc_engine.Kata.comp_id in
          let file_pairs = load_kata_files ~root ~kata_dir comp.Tsc_engine.Kata.comp_files in
          if file_pairs = [] then begin
            Printf.eprintf "Error: kata '%s' component '%s' has no readable input files\n" kata_id cid;
            exit 1
          end;
          let bundle = Bundle.build_bundle
            ~target_name:(Printf.sprintf "kata-%s-%s" kata_id cid)
            ~target_kind:Tsc_engine.Types.Aggregate
            ~files:file_pairs
          in
          let r = Mechanical_scoring.score_bundle bundle in
          Printf.eprintf "  component '%s': C_Σ^num=%.4f (C_Σ^math=%.4f)\n%!"
            cid r.c_sigma_num r.c_sigma_math;
          (cid, r.c_sigma_num, r)
        ) kata.components
      in
      let actual_ranking =
        scored
        |> List.sort (fun (_, a, _) (_, b, _) -> compare b a)  (* high → low *)
        |> List.map (fun (cid, _, _) -> cid)
      in
      let ranking_correct = (actual_ranking = kata.ranking) in
      (* Emit result JSON *)
      let components_json = `List (List.map (fun (cid, score, r) ->
        `Assoc [
          ("id",                     `String cid);
          ("c_sigma_num",            `Float score);
          ("c_sigma_math",           `Float r.c_sigma_math);
          ("zero_component_present", `Bool  r.zero_component_present);
          ("numeric_floor_applied",  `Bool  r.numeric_floor_applied);
          ("mechanical",             Mechanical_scoring.result_to_json r);
        ]
      ) scored) in
      let result_json = `Assoc [
        ("kata_id",          `String kata_id);
        ("expected_verdict", `String kata.verdict);
        ("expected_ranking", `List (List.map (fun s -> `String s) kata.ranking));
        ("actual_ranking",   `List (List.map (fun s -> `String s) actual_ranking));
        ("ranking_correct",  `Bool ranking_correct);
        ("components",       components_json);
      ] in
      Printf.printf "%s\n" (Yojson.Safe.pretty_to_string result_json);
      if ranking_correct then begin
        Printf.eprintf "KATA PASS: '%s' — ranking %s matches expected\n%!"
          kata_id (String.concat ">" actual_ranking);
        exit 0
      end else begin
        Printf.eprintf "KATA FAIL: '%s' — ranking %s != expected %s\n%!"
          kata_id (String.concat ">" actual_ranking) (String.concat ">" kata.ranking);
        exit 1
      end
    end
    else begin
      let file_pairs = load_kata_files ~root ~kata_dir kata.input_files in
      if file_pairs = [] then begin
        Printf.eprintf "Error: kata '%s' has no readable input files\n" kata_id;
        exit 1
      end;
      Printf.eprintf "Running mechanical scoring for kata '%s'...\n%!" kata_id;
      let bundle = Bundle.build_bundle
        ~target_name:("kata-" ^ kata_id)
        ~target_kind:Tsc_engine.Types.Aggregate
        ~files:file_pairs
      in
      let result = Mechanical_scoring.score_bundle bundle in
      Printf.eprintf "%s\n%!" (Mechanical_scoring.summarize_result result);
      (* Compare against kata expectations using canonical v3.2 c_sigma_num.
         Per spec/tsc-oper.md §5, c_sigma_num is the threshold-comparison
         value; if zero_component_present = true the math degeneracy already
         fails any non-zero threshold. *)
      let c_sigma = result.c_sigma_num in
      let kata_pass =
        match kata.verdict with
        | "pass" ->
          not result.zero_component_present
          && c_sigma >= kata.score_min && c_sigma <= kata.score_max
        | "fail" ->
          c_sigma <= kata.score_max
        | v ->
          Printf.eprintf "Warning: unknown expected.verdict '%s'; treating as pass\n" v;
          c_sigma >= kata.score_min && c_sigma <= kata.score_max
      in
      let result_json = `Assoc [
        ("kata_id",                `String kata_id);
        ("expected_verdict",       `String kata.verdict);
        ("c_sigma_num",            `Float c_sigma);
        ("c_sigma_math",           `Float result.c_sigma_math);
        ("zero_component_present", `Bool  result.zero_component_present);
        ("numeric_floor_applied",  `Bool  result.numeric_floor_applied);
        ("score_range",            `Assoc [
          ("min", `Float kata.score_min);
          ("max", `Float kata.score_max);
        ]);
        ("kata_pass",              `Bool kata_pass);
        ("mechanical",             Mechanical_scoring.result_to_json result);
      ] in
      Printf.printf "%s\n" (Yojson.Safe.pretty_to_string result_json);
      if kata_pass then begin
        Printf.eprintf "KATA PASS: '%s' — C_Σ^num=%.4f within expected range [%.4f, %.4f] for verdict '%s'\n%!"
          kata_id c_sigma kata.score_min kata.score_max kata.verdict;
        exit 0
      end else begin
        Printf.eprintf "KATA FAIL: '%s' — C_Σ^num=%.4f outside expected range [%.4f, %.4f] for verdict '%s'\n%!"
          kata_id c_sigma kata.score_min kata.score_max kata.verdict;
        exit 1
      end
    end

(* ------------------------------------------------------------------ *)
(* Entrypoint *)

let () =
  let args = parse_args () in
  let ts = timestamp () in
  let root = args.cli_root in

  (* Kata mode: short-circuit before regular bundle path *)
  if args.cli_kata <> "" then begin
    let mode_override = match args.cli_mode with
      | Auto -> ""  (* let kata.toml decide *)
      | Mechanical -> "mechanical"
      | Llm        -> "llm"
      | Hybrid     -> "hybrid"
    in
    run_kata ~root ~kata_id:args.cli_kata ~mode_override
    (* run_kata always calls exit; this line is unreachable *)
  end;

  (* Resolve effective mode (auto → mechanical or hybrid) *)
  let effective_mode = match args.cli_mode with
    | Auto ->
      if Tsc_engine.Credentials.has_llm_credentials () then begin
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
