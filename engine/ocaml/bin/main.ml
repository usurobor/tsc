(** Coherence engine — CLI entrypoint.

    Wires pure library modules with I/O.

    Modes:
      mechanical  — structural-proxy scoring, no credentials required
      llm         — semantic scoring via SELF-MEASURE.md (default before v0.5.0)
      hybrid      — run both backends, produce unified report
      auto        — hybrid when the FULL provider configuration
                    (LLM_PROVIDER, LLM_MODEL, LLM_API_KEY) is present;
                    partial sets warn and fall back to mechanical

    Inputs:
      --target <name> --registry <path>    named target (any mode); repeatable
      --files <glob>  [--files <glob>...]  direct file input (mechanical / hybrid)

    Self-measurement (skills/self-measure/SKILL.md):
      coh self [...]           dispatches to the rendered [coh-self] command
                               (git-style external subcommand; the procedure
                               is declared by the skill, not by this binary)

    Consistency protocol (skills/cm-of-cms/SKILL.md §3):
      coh consistency-spread --target <t> <resp.json>... [--output <f>]
                               k-sample spread report (lib/consistency.ml)
      coh witness-medoid [--target <t>] <resp.json>...
                               medoid-of-k adjudication (lib/witness_medoid.ml);
                               with --target only funnel-valid samples are
                               candidates and zero valid samples exits 2

    External provider route (skills/self-measure/SKILL.md §LLM contract):
      --emit-prompt <path>     write the exact LLM prompt (instruction +
                               target metadata + file bundle) to <path> and
                               exit; no provider call is made
      --llm-response <path>    in llm / hybrid modes, read the provider
                               response from <path> instead of calling the
                               provider over HTTP. Validation is identical
                               to the HTTP route (strict v3.2 delta
                               validation; failure = no report, no
                               mechanical fallback)

    Cross-target (Operational §7.4):
      When [--target] is provided two or more times, the engine emits a
      cross-target report (`kind = cross_target_report`) whose top-level
      aggregate is the geometric mean of per-target [C_sigma_num] /
      [C_sigma_math] values. This surface is mechanical-only for the
      current cycle — supplying multiple targets with [--mode llm],
      [--mode hybrid], or effective [auto] exits non-zero with an
      explicit "mechanical-only" message. *)

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

(** Expand a glob pattern into matching file paths relative to root.

    Approximation, not full glob semantics: a pattern is matched by the
    literal prefix before its first '*' and the literal suffix after its
    last '*'. Sufficient for the manifest shapes used in targets/
    (`dir/**` and `dir/**/*.ext`); a pattern like `a/*/b.md` would also
    match deeper paths. *)
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

(* The timestamp lands in report FILENAMES, so it uses ISO-8601 basic
   time (no colons): a colon in a file name is rejected by NTFS-safe
   tooling — GitHub artifact upload refuses the whole report set. *)
let timestamp () =
  let t = Unix.gettimeofday () in
  let tm = Unix.gmtime t in
  Printf.sprintf "%04d-%02d-%02dT%02d%02d%02dZ"
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
  cli_targets    : string list;  (* [] when using --files; >= 2 = cross-target *)
  cli_registry   : string;
  cli_instruction: string;
  cli_root       : string;
  cli_output_dir : string;
  cli_files      : string list;  (* globs for direct file input *)
  cli_kata       : string;       (* "" when not using --kata *)
  cli_emit_prompt  : string;     (* "" when not emitting the LLM prompt *)
  cli_llm_response : string;     (* "" when using the HTTP provider route *)
}

let () =
  if Array.length Sys.argv = 2 && Sys.argv.(1) = "--version" then begin
    Printf.printf "coh %s (%s)\n" Build_version.version Build_commit.commit;
    exit 0
  end

(* `coh self` — git-style external-subcommand dispatch.

   The self-measurement procedure is declared by
   skills/self-measure/SKILL.md and rendered into the [coh-self]
   executable by scripts/render-self-measure.sh. The engine stays
   generic (measure any target); the skill owns what "self" means.
   Resolution order: sibling of this binary, then PATH. *)
let () =
  if Array.length Sys.argv >= 2 && Sys.argv.(1) = "self" then begin
    let rest = Array.sub Sys.argv 2 (Array.length Sys.argv - 2) in
    let argv cmd = Array.append [| cmd |] rest in
    let sibling =
      Filename.concat (Filename.dirname Sys.executable_name) "coh-self"
    in
    (try
       if Sys.file_exists sibling then Unix.execv sibling (argv sibling)
       else Unix.execvp "coh-self" (argv "coh-self")
     with Unix.Unix_error _ ->
       Printf.eprintf
         "coh self: cannot find 'coh-self' (sibling of %s or on PATH).\n\
          The self-measurement command is rendered from \
          skills/self-measure/SKILL.md;\n\
          run scripts/render-self-measure.sh and install scripts/coh-self \
          next to coh.\n"
         Sys.executable_name;
       exit 127)
  end

(* `coh consistency-spread` / `coh witness-medoid` — the meter's
   consistency-protocol semantics, in-engine (P1 of the Python-removal
   master issue). Exit codes: 0 success; 2 precondition or malformed
   input. Malformed inputs produce a visible error on stderr, never a
   silent exclusion. witness-medoid's two election modes (numeric
   compatibility mode with first-argument fallback; funnel-valid mode
   under --target with an explicit zero-valid error) live in
   lib/witness_medoid.ml and are pinned by tests. *)
let () =
  if Array.length Sys.argv >= 2 && Sys.argv.(1) = "consistency-spread" then begin
    let target = ref "" and output = ref "" and files = ref [] in
    let rec eat i =
      if i >= Array.length Sys.argv then ()
      else match Sys.argv.(i) with
        | "--target" when i + 1 < Array.length Sys.argv ->
          target := Sys.argv.(i + 1); eat (i + 2)
        | "--output" when i + 1 < Array.length Sys.argv ->
          output := Sys.argv.(i + 1); eat (i + 2)
        | f -> files := f :: !files; eat (i + 1)
    in
    eat 2;
    let files = List.rev !files in
    if !target = "" || files = [] then begin
      prerr_endline
        "usage: coh consistency-spread --target <target> <response.json>... \
         [--output <report.json>]";
      exit 2
    end;
    (match Tsc_engine.Consistency.llm_spread_report ~target:!target ~files with
     | Error e ->
       Printf.eprintf "coh consistency-spread: %s\n" e;
       exit 2
     | Ok report ->
       let text = Yojson.Safe.pretty_to_string report ^ "\n" in
       (match report with
        | `Assoc kv ->
          let f k = match List.assoc_opt k kv with
            | Some (`Float x) -> x | _ -> 0.0 in
          if !output <> "" then begin
            let oc = open_out !output in
            output_string oc text; close_out oc
          end else print_string text;
          Printf.printf
            "cm-consistency: %s llm-spread over %d repeats -> delta %.4f, \
             Coh_consistency %.4f%s\n"
            !target (List.length files)
            (f "delta_consistency") (f "coh_consistency")
            (if !output <> "" then " -> " ^ !output else "")
        | _ -> ());
       exit 0)
  end

let () =
  if Array.length Sys.argv >= 2 && Sys.argv.(1) = "witness-medoid" then begin
    let target = ref "" and files = ref [] in
    let rec eat i =
      if i >= Array.length Sys.argv then ()
      else match Sys.argv.(i) with
        | "--target" when i + 1 < Array.length Sys.argv ->
          target := Sys.argv.(i + 1); eat (i + 2)
        | f -> files := f :: !files; eat (i + 1)
    in
    eat 2;
    let files = List.rev !files in
    (* With --target the election is funnel-aware: only samples that
       pass the complete witness-validation funnel are candidates, and
       zero valid samples is an explicit exit 2 (the workflow records a
       no-valid-samples artifact instead of adjudicating an invalid
       sample into a guaranteed ingest failure). Without --target the
       legacy numeric-completeness election applies. *)
    let result =
      if !target <> "" then
        Tsc_engine.Witness_medoid.choose_valid ~expected_target:!target files
      else Tsc_engine.Witness_medoid.choose files
    in
    match result with
    | Ok path -> print_endline path; exit 0
    | Error e ->
      Printf.eprintf "coh witness-medoid: %s\n" e;
      prerr_endline
        "usage: coh witness-medoid [--target <target>] <response.json>...";
      exit 2
  end

let parse_args () =
  let mode_s    = ref "auto" in
  let targets   = ref [] in
  let registry  = ref "targets/registry.tsc" in
  let instruction = ref "runtime/SELF-MEASURE.md" in
  let root      = ref "." in
  let output_dir = ref ".tsc" in
  let files     = ref [] in
  let kata      = ref "" in
  let emit_prompt  = ref "" in
  let llm_response = ref "" in
  let specs = [
    ("--mode",        Arg.Set_string mode_s,
     "Scoring mode: mechanical | llm | hybrid | auto (default: auto)");
    ("--kata",        Arg.Set_string kata,
     "Run kata <id> from katas/ directory (e.g. --kata 01-glider)");
    ("--target",      Arg.String (fun t -> targets := t :: !targets),
     "Named target (requires --registry; repeatable — \
      two or more triggers a mechanical cross-target report)");
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
    ("--emit-prompt", Arg.Set_string emit_prompt,
     "Write the exact LLM prompt for the resolved bundle to <path> and \
      exit (no provider call)");
    ("--llm-response", Arg.Set_string llm_response,
     "Read the LLM response from <path> instead of calling the provider \
      (llm / hybrid modes; external provider route)");
  ] in
  let usage =
    "coh [self] --mode <mode> [--kata <id> | --target <name> [--target <name>...] | \
     --files <glob>...] [options]"
  in
  Arg.parse specs (fun _ -> ()) usage;
  let mode = match parse_mode !mode_s with
    | Some m -> m
    | None ->
      Printf.eprintf "Error: unknown mode '%s'. Use mechanical | llm | hybrid | auto\n" !mode_s;
      exit 1
  in
  if !kata = "" && !targets = [] && !files = [] then begin
    Printf.eprintf "Error: provide --kata <id>, --target <name>, or --files <glob>\n";
    Arg.usage specs usage;
    exit 1
  end;
  if !emit_prompt <> "" && !llm_response <> "" then begin
    Printf.eprintf "Error: --emit-prompt and --llm-response are mutually exclusive\n";
    exit 1
  end;
  if !llm_response <> "" && parse_mode !mode_s = Some Mechanical then begin
    Printf.eprintf "Error: --llm-response requires --mode llm or --mode hybrid\n";
    exit 1
  end;
  { cli_mode        = mode;
    cli_targets     = List.rev !targets;
    cli_registry    = !registry;
    cli_instruction = !instruction;
    cli_root        = !root;
    cli_output_dir  = !output_dir;
    cli_files       = List.rev !files;
    cli_kata        = !kata;
    cli_emit_prompt  = !emit_prompt;
    cli_llm_response = !llm_response }

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
(* Factorized-β measurement harness subcommands (Sub-2 of #73, #75)     *)
(*
   The engine drives the FROZEN factorized-β experiment. Three
   deterministic halves + two B3-control halves, each git-style
   external-subcommand style (mirrors consistency-spread / witness-medoid),
   all pure-core-in-library / thin-binary:

     factorized-beta-inventory  — emit the pre-witness inventory artifact +
                                   the bounded adjudication prompt for a target.
     factorized-beta-target     — ingest k witness responses -> validate ->
                                   per-sample β_factorized -> β Coh_consistency
                                   (barrier reused) -> A3 agreement -> per-target
                                   measurement record.
     factorized-beta-gate       — read the per-target measurements + B1/B2/B3
                                   flags -> A/B/C gate -> terminal
                                   PASS | FAIL | NO-DECISION token.
     factorized-beta-controls-prompt / -check
                                — the B3 discrimination controls: emit the
                                  adjudication prompt over the labeled controls,
                                  then check witness verdicts against the frozen
                                  oracle labels (+ the typed-fixture gate).

   The α/γ scalar path (Prompt / Response_schema / the scalar subcommands)
   is untouched; this is a separate β-adjudication surface. *)

let () =
  if Array.length Sys.argv >= 2 && Sys.argv.(1) = "factorized-beta-inventory" then begin
    let n = Array.length Sys.argv in
    let target = ref "" and registry = ref "targets/registry.tsc"
    and root = ref "." and output = ref ".tsc/fb" in
    let rec eat i =
      if i >= n then ()
      else match Sys.argv.(i) with
        | "--target"   when i + 1 < n -> target := Sys.argv.(i + 1); eat (i + 2)
        | "--registry" when i + 1 < n -> registry := Sys.argv.(i + 1); eat (i + 2)
        | "--root"     when i + 1 < n -> root := Sys.argv.(i + 1); eat (i + 2)
        | "--output"   when i + 1 < n -> output := Sys.argv.(i + 1); eat (i + 2)
        | _ -> eat (i + 1)
    in
    eat 2;
    if !target = "" then begin
      prerr_endline
        "usage: coh factorized-beta-inventory --target <t> [--registry <r>] \
         [--root <dir>] [--output <dir>]";
      exit 2
    end;
    let bundle =
      build_bundle_from_target ~root:!root
        ~registry_path:(Filename.concat !root !registry)
        ~target_name:!target
    in
    let loci = Factorized_beta.inventory bundle.bundle_files in
    let inv_json = Factorized_beta.inventory_to_json ~target:!target loci in
    let prompt = Factorized_beta.adjudication_instruction loci in
    let inv_path =
      Filename.concat !output (Printf.sprintf "inventory/%s.json" !target) in
    let prompt_path =
      Filename.concat !output (Printf.sprintf "prompt/%s.md" !target) in
    write_file inv_path (Yojson.Safe.pretty_to_string inv_json);
    write_file prompt_path prompt;
    let eligible =
      List.length
        (List.filter (fun (l : Factorized_beta.locus) ->
           l.Factorized_beta.mechanical_status = Factorized_beta.Resolved) loci)
    in
    Printf.printf
      "factorized-β inventory: %s N=%d E=%d locus_sparse=%b\n  %s\n  %s\n"
      !target (List.length loci) eligible (eligible < 5) inv_path prompt_path;
    exit 0
  end

let () =
  if Array.length Sys.argv >= 2 && Sys.argv.(1) = "factorized-beta-target" then begin
    let n = Array.length Sys.argv in
    let target = ref "" and registry = ref "targets/registry.tsc"
    and root = ref "." and output = ref ".tsc/fb"
    and declared = ref 3 and baseline = ref "" and responses = ref [] in
    let rec eat i =
      if i >= n then ()
      else match Sys.argv.(i) with
        | "--target"    when i + 1 < n -> target := Sys.argv.(i + 1); eat (i + 2)
        | "--registry"  when i + 1 < n -> registry := Sys.argv.(i + 1); eat (i + 2)
        | "--root"      when i + 1 < n -> root := Sys.argv.(i + 1); eat (i + 2)
        | "--output"    when i + 1 < n -> output := Sys.argv.(i + 1); eat (i + 2)
        | "--declared"  when i + 1 < n ->
          declared := (try int_of_string Sys.argv.(i + 1) with _ -> 3); eat (i + 2)
        | "--baseline-beta-coh" when i + 1 < n ->
          baseline := Sys.argv.(i + 1); eat (i + 2)
        | "--response"  when i + 1 < n ->
          responses := Sys.argv.(i + 1) :: !responses; eat (i + 2)
        | _ -> eat (i + 1)
    in
    eat 2;
    let responses = List.rev !responses in
    if !target = "" then begin
      prerr_endline
        "usage: coh factorized-beta-target --target <t> [--baseline-beta-coh <f>] \
         --response <r.json> [--response <r.json>...] [--declared 3] \
         [--registry <r>] [--root <dir>] [--output <dir>]";
      exit 2
    end;
    let bundle =
      build_bundle_from_target ~root:!root
        ~registry_path:(Filename.concat !root !registry)
        ~target_name:!target
    in
    let loci = Factorized_beta.inventory bundle.bundle_files in
    (* Per response: parse -> validate_sample -> β_factorized. A refused
       sample is a recorded fact that counts against A0 (refuse, don't
       skip). *)
    let validated = ref [] and refused = ref 0 in
    List.iter (fun rf ->
      match read_file rf with
      | Error e -> Printf.eprintf "  refused %s: %s\n%!" rf e; incr refused
      | Ok raw ->
        (match (try Ok (Yojson.Safe.from_string raw)
                with Yojson.Json_error e -> Error e) with
         | Error e -> Printf.eprintf "  refused %s: bad JSON: %s\n%!" rf e; incr refused
         | Ok json ->
           (match Factorized_beta.parse_locus_responses json with
            | Error e -> Printf.eprintf "  refused %s: %s\n%!" rf e; incr refused
            | Ok resps ->
              (match Factorized_beta.validate_sample ~loci ~responses:resps with
               | Error rs ->
                 Printf.eprintf "  refused %s: %s\n%!" rf
                   (String.concat "; "
                      (List.map Factorized_beta.refusal_to_string rs));
                 incr refused
               | Ok verdicts ->
                 let agg = Factorized_beta.beta_of_verdicts loci verdicts in
                 validated :=
                   (verdicts, agg.Factorized_beta.beta_factorized) :: !validated)))
    ) responses;
    let validated = List.rev !validated in
    let betas = List.map snd validated in
    let samples = List.map fst validated in
    let eligible_ids =
      List.filter_map (fun (l : Factorized_beta.locus) ->
        if l.Factorized_beta.mechanical_status = Factorized_beta.Resolved
        then Some l.Factorized_beta.locus_id else None) loci
    in
    let eligible = List.length eligible_ids in
    let beta_coh = Factorized_beta_gate.beta_coh_consistency betas in
    let agreement = Factorized_beta_gate.locus_agreement ~eligible_ids ~samples in
    let baseline_present = !baseline <> "" in
    let baseline_coh =
      if baseline_present then (try float_of_string !baseline with _ -> 0.0)
      else 0.0
    in
    let tm = { Factorized_beta_gate.
      tm_target = !target;
      tm_beta_loci = List.length loci;
      tm_eligible_loci = eligible;
      tm_locus_sparse = eligible < 5;
      tm_declared_samples = !declared;
      tm_validated_samples = List.length validated;
      tm_refused_samples = !refused;
      tm_sample_betas = betas;
      tm_beta_coh = beta_coh;
      tm_agreement = agreement;
      tm_baseline_beta_coh = baseline_coh;
      tm_baseline_present = baseline_present } in
    let path =
      Filename.concat !output (Printf.sprintf "measure/%s.json" !target) in
    write_file path
      (Yojson.Safe.pretty_to_string
         (Factorized_beta_gate.target_measure_to_json tm));
    Printf.printf
      "factorized-β target %s: N=%d E=%d sparse=%b validated=%d/%d refused=%d \
       β_coh=%.4f agree=%.4f baseline=%.4f -> %s\n"
      !target (List.length loci) eligible (eligible < 5)
      (List.length validated) !declared !refused beta_coh agreement baseline_coh path;
    exit 0
  end

let () =
  if Array.length Sys.argv >= 2 && Sys.argv.(1) = "factorized-beta-gate" then begin
    let n = Array.length Sys.argv in
    let measure_dir = ref "" and output = ref ""
    and kata = ref "" and adm = ref "" and b3 = ref "" and declared = ref 3 in
    let rec eat i =
      if i >= n then ()
      else match Sys.argv.(i) with
        | "--measure-dir"      when i + 1 < n -> measure_dir := Sys.argv.(i + 1); eat (i + 2)
        | "--output"           when i + 1 < n -> output := Sys.argv.(i + 1); eat (i + 2)
        | "--kata-b1"          when i + 1 < n -> kata := Sys.argv.(i + 1); eat (i + 2)
        | "--admissibility-b2" when i + 1 < n -> adm := Sys.argv.(i + 1); eat (i + 2)
        | "--b3"               when i + 1 < n -> b3 := Sys.argv.(i + 1); eat (i + 2)
        | "--declared"         when i + 1 < n ->
          declared := (try int_of_string Sys.argv.(i + 1) with _ -> 3); eat (i + 2)
        | _ -> eat (i + 1)
    in
    eat 2;
    if !measure_dir = "" then begin
      prerr_endline
        "usage: coh factorized-beta-gate --measure-dir <dir> [--kata-b1 pass|fail] \
         [--admissibility-b2 pass|fail] [--b3 pass|fail] [--declared 3] \
         [--output <f>]";
      exit 2
    end;
    let files =
      (try Array.to_list (Sys.readdir !measure_dir) with Sys_error _ -> [])
      |> List.filter (fun f -> Filename.check_suffix f ".json")
      |> List.sort String.compare
      |> List.map (fun f -> Filename.concat !measure_dir f)
    in
    let targets =
      List.filter_map (fun f ->
        match read_file f with
        | Error e -> Printf.eprintf "gate: skip %s: %s\n%!" f e; None
        | Ok raw ->
          (match (try Ok (Yojson.Safe.from_string raw)
                  with Yojson.Json_error e -> Error e) with
           | Error e -> Printf.eprintf "gate: skip %s: %s\n%!" f e; None
           | Ok j ->
             (match Factorized_beta_gate.target_measure_of_json j with
              | Ok tm -> Some tm
              | Error e -> Printf.eprintf "gate: skip %s: %s\n%!" f e; None)))
        files
    in
    let flag s =
      let s = String.lowercase_ascii s in
      s = "pass" || s = "passed" || s = "true"
    in
    let gi = { Factorized_beta_gate.
      gi_targets = targets;
      gi_kata_b1 = flag !kata;
      gi_admissibility_b2 = flag !adm;
      gi_b3 = flag !b3;
      gi_a1_floor = Factorized_beta_gate.default_a1_floor;
      gi_a2_margin = Factorized_beta_gate.default_a2_margin;
      gi_a3_floor = Factorized_beta_gate.default_a3_floor;
      gi_declared = !declared } in
    let gr = Factorized_beta_gate.evaluate_gate gi in
    let summary = Factorized_beta_gate.gate_result_to_json gr in
    let out =
      if !output <> "" then !output
      else Filename.concat !measure_dir "gate-summary.json" in
    write_file out (Yojson.Safe.pretty_to_string summary);
    List.iter (fun (c : Factorized_beta_gate.check) ->
      Printf.printf "  [%s] %s — %s\n"
        (if c.Factorized_beta_gate.chk_passed then "PASS" else "MISS")
        c.Factorized_beta_gate.chk_id c.Factorized_beta_gate.chk_detail)
      gr.Factorized_beta_gate.gr_checks;
    Printf.printf
      "targets scored: %d; locus_sparse: %d; summary artifact: %s\n"
      (List.length gr.Factorized_beta_gate.gr_scored)
      gr.Factorized_beta_gate.gr_sparse_count out;
    (* The single terminal token on its own final line — CI reads this. *)
    print_endline
      (Factorized_beta_gate.string_of_verdict_token
         gr.Factorized_beta_gate.gr_verdict);
    exit 0
  end

let () =
  if Array.length Sys.argv >= 2 && Sys.argv.(1) = "factorized-beta-controls-prompt" then begin
    let n = Array.length Sys.argv in
    let fixtures =
      ref "docs/beta/governance/fixtures/factorized-beta-controls.json"
    and output = ref "" in
    let rec eat i =
      if i >= n then ()
      else match Sys.argv.(i) with
        | "--fixtures" when i + 1 < n -> fixtures := Sys.argv.(i + 1); eat (i + 2)
        | "--output"   when i + 1 < n -> output := Sys.argv.(i + 1); eat (i + 2)
        | _ -> eat (i + 1)
    in
    eat 2;
    let raw = match read_file !fixtures with
      | Ok r -> r | Error e -> Printf.eprintf "%s\n" e; exit 2 in
    let json = try Yojson.Safe.from_string raw
      with Yojson.Json_error e -> Printf.eprintf "bad fixture JSON: %s\n" e; exit 2 in
    (match Factorized_beta_gate.controls_prompt json with
     | Error e -> Printf.eprintf "controls-prompt: %s\n" e; exit 2
     | Ok prompt ->
       if !output <> "" then begin
         write_file !output prompt;
         Printf.printf "controls prompt -> %s\n" !output
       end else print_string prompt);
    exit 0
  end

let () =
  if Array.length Sys.argv >= 2 && Sys.argv.(1) = "factorized-beta-controls-check" then begin
    let n = Array.length Sys.argv in
    let fixtures =
      ref "docs/beta/governance/fixtures/factorized-beta-controls.json"
    and response = ref "" and output = ref "" in
    let rec eat i =
      if i >= n then ()
      else match Sys.argv.(i) with
        | "--fixtures" when i + 1 < n -> fixtures := Sys.argv.(i + 1); eat (i + 2)
        | "--response" when i + 1 < n -> response := Sys.argv.(i + 1); eat (i + 2)
        | "--output"   when i + 1 < n -> output := Sys.argv.(i + 1); eat (i + 2)
        | _ -> eat (i + 1)
    in
    eat 2;
    if !response = "" then begin
      prerr_endline
        "usage: coh factorized-beta-controls-check --response <r.json> \
         [--fixtures <f>] [--output <f>]";
      exit 2
    end;
    let fraw = match read_file !fixtures with
      | Ok r -> r | Error e -> Printf.eprintf "%s\n" e; exit 2 in
    let fjson = try Yojson.Safe.from_string fraw
      with Yojson.Json_error e -> Printf.eprintf "bad fixture JSON: %s\n" e; exit 2 in
    let rraw = match read_file !response with
      | Ok r -> r | Error e -> Printf.eprintf "%s\n" e; exit 2 in
    let rjson = try Yojson.Safe.from_string rraw
      with Yojson.Json_error e -> Printf.eprintf "bad response JSON: %s\n" e; exit 2 in
    (match Factorized_beta_gate.controls_check
             ~fixtures_json:fjson ~responses_json:rjson with
     | Error e -> Printf.eprintf "controls-check: %s\n" e; exit 2
     | Ok b3 ->
       if !output <> "" then
         write_file !output
           (Yojson.Safe.pretty_to_string
              (Factorized_beta_gate.b3_result_to_json b3));
       Printf.printf
         "B3 controls: called=%d agreements=%d typed_ok=%b -> %s\n"
         b3.Factorized_beta_gate.b3_total b3.Factorized_beta_gate.b3_agreements
         b3.Factorized_beta_gate.b3_typed_ok
         (if b3.Factorized_beta_gate.b3_passed then "pass" else "fail");
       (* Terminal token for the CI B3 step. *)
       print_endline (if b3.Factorized_beta_gate.b3_passed then "pass" else "fail"));
    exit 0
  end

(* ------------------------------------------------------------------ *)
(* Witness validation-failure artifact (cycle/51 AC2; review round 2)  *)
(*
   Every refused witness response — parse failure, base-schema failure,
   prohibited computed-coherence fields, target mismatch, strict v3.2
   delta failure, checklist-walk failure, or defect-card failure —
   funnels through this one writer. The raw provider
   response must already have been written to disk by the caller. No
   coherence report is rendered. There is no mechanical fallback (AC3). *)

let write_validation_failure_artifact
    ~output_dir
    ~target
    ~ts
    ~raw_path
    ~(wf : Response_schema.witness_failure) =
  let missing_json =
    `List (List.map (fun s -> `String s) wf.wf_missing_fields)
  in
  let invalid_json =
    `List (List.map (fun (k, v) ->
      `Assoc [
        ("field", `String k);
        ("observed_value", `String v);
        ("expected_range", `String "[0, 1]");
      ]
    ) wf.wf_invalid_fields)
  in
  let artifact = `Assoc [
    ("kind",                    `String "validation_failure");
    ("schema",                  `String "tsc-llm-response/v3.2");
    ("status",                  `String "error");
    ("target",                  `String target);
    ("stage",                   `String (Response_schema.witness_stage_to_string wf.wf_stage));
    ("errors",                  `List (List.map (fun e -> `String e) wf.wf_errors));
    ("missing_required_fields", missing_json);
    ("invalid_fields",          invalid_json);
    ("raw_response_path",       `String raw_path);
    ("message",                 `String "witness response failed validation; coherence report not rendered (no mechanical fallback).");
  ] in
  let path =
    Filename.concat output_dir
      (Printf.sprintf "tsc-%s-%s-validation-failure.json" target ts)
  in
  write_file path (Yojson.Safe.pretty_to_string artifact);
  path

(** Validate a raw witness response; on any failure, write the durable
    validation-failure artifact and exit non-zero. Shared by run_llm and
    run_hybrid so no refusal path can diverge between modes. *)
let validate_witness_or_exit ~args ~bundle ~ts ~raw_path raw_response =
  let expected_target = bundle.bundle_target_name in
  match
    Response_schema.validate_witness_response ~expected_target raw_response
  with
  | Ok (result, deltas) ->
    Printf.eprintf "Response validated.\n%!";
    (result, deltas)
  | Error wf ->
    Printf.eprintf "Error: witness response failed validation: %s\n"
      (Response_schema.format_witness_failure wf);
    let artifact_path =
      write_validation_failure_artifact
        ~output_dir:args.cli_output_dir
        ~target:bundle.bundle_target_name
        ~ts
        ~raw_path
        ~wf
    in
    Printf.eprintf "Raw response preserved at %s\n" raw_path;
    Printf.eprintf "Validation failure artifact: %s\n" artifact_path;
    Printf.eprintf "No coherence report rendered (no mechanical fallback).\n";
    exit 1

(* ------------------------------------------------------------------ *)
(* Mode execution *)

(** Obtain the raw LLM response plus (provider, model) labels.

    Two routes (skills/self-measure/SKILL.md §LLM contract):
    - HTTP route (default): engine calls the configured provider.
    - External route (--llm-response): the response was produced out of
      band (e.g. by the Claude CLI step of the rendered self-measurement
      workflow); the engine reads it from disk. Provider/model labels
      come from LLM_PROVIDER / LLM_MODEL when set, else "external".

    Both routes feed the identical validation pipeline downstream. *)
let obtain_llm_response ~args ~system_msg ~user_msg =
  if args.cli_llm_response <> "" then begin
    Printf.eprintf "Reading LLM response from %s (external provider route)...\n%!"
      args.cli_llm_response;
    let raw =
      match read_file args.cli_llm_response with
      | Error e -> Printf.eprintf "Error: %s\n" e; exit 1
      | Ok r -> r
    in
    let getenv_label name =
      match Sys.getenv_opt name with
      | Some v when String.trim v <> "" -> v
      | _ -> "external"
    in
    (raw, getenv_label "LLM_PROVIDER", getenv_label "LLM_MODEL")
  end else begin
    let env_file = Filename.concat args.cli_root ".tsc/.env" in
    let n = Dotenv.load env_file in
    if n > 0 then Printf.eprintf "Loaded %d variable(s) from %s\n%!" n env_file;
    Printf.eprintf "Loading provider configuration...\n%!";
    let config =
      match Provider.config_from_env () with
      | Error e -> Printf.eprintf "Error: %s\n" e; exit 1
      | Ok c -> c
    in
    Printf.eprintf "Calling %s/%s...\n%!" config.provider_name config.provider_model;
    let raw =
      match Provider.call_provider ~config ~system_message:system_msg ~user_message:user_msg with
      | Error e -> Printf.eprintf "Error calling provider: %s\n" e; exit 1
      | Ok r -> r
    in
    (raw, config.provider_name, config.provider_model)
  end

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
  let raw_response, provider_name, provider_model =
    obtain_llm_response ~args ~system_msg ~user_msg
  in
  Printf.eprintf "Validating response...\n%!";
  (* Raw response is always preserved on disk, regardless of validation
     outcome.  No post-response mechanical fallback (cycle/51 AC3). *)
  let raw_path =
    Filename.concat args.cli_output_dir
      (Printf.sprintf "tsc-%s-%s-raw.txt" bundle.bundle_target_name ts)
  in
  write_file raw_path raw_response;
  let metadata : run_metadata = {
    meta_target = bundle.bundle_target_name;
    meta_file_hashes =
      List.map (fun f -> (f.file_path, f.file_hash)) bundle.bundle_files;
    meta_prompt_version = Tsc_engine.Types.self_measure_protocol_version;
    meta_provider = provider_name;
    meta_model    = provider_model;
    meta_timestamp = ts;
  } in
  (* Witness-validation funnel: every refusal stage (parse, base schema,
     prohibited fields, target mismatch, v3.2 delta, checklist,
     defect_cards) writes the same validation-failure artifact and
     exits (cycle/51 AC1/AC2/AC3; stages 6-7 added by v3.2.3/v3.2.4). *)
  let result, (d_ab, d_bg, d_ga) =
    validate_witness_or_exit ~args ~bundle ~ts ~raw_path raw_response
  in
  let json_path =
    Filename.concat args.cli_output_dir
      (Printf.sprintf "tsc-%s-%s.json" bundle.bundle_target_name ts)
  in
  write_file json_path (Report.to_json ~result ~metadata ~mode:"llm"
    ~delta_alpha_beta:(Some d_ab)
    ~delta_beta_gamma:(Some d_bg)
    ~delta_gamma_alpha:(Some d_ga) ());
  let text_path =
    Filename.concat args.cli_output_dir
      (Printf.sprintf "tsc-%s-%s.txt" bundle.bundle_target_name ts)
  in
  write_file text_path (Report.to_text ~result ~metadata ~mode:"llm" ());
  Printf.printf "Done. LLM reports:\n  %s\n  %s\n  %s\n"
    raw_path json_path text_path

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
  let raw_response, _provider_name, _provider_model =
    obtain_llm_response ~args ~system_msg ~user_msg
  in
  Printf.eprintf "Validating LLM response...\n%!";
  (* Raw response is always preserved on disk, regardless of validation
     outcome.  No post-response mechanical fallback (cycle/51 AC3). *)
  let raw_path =
    Filename.concat args.cli_output_dir
      (Printf.sprintf "tsc-%s-%s-raw.txt" bundle.bundle_target_name ts)
  in
  write_file raw_path raw_response;
  (* Same witness-validation funnel as run_llm — the refusal contract
     cannot diverge between modes (cycle/51 AC1/AC2/AC3). *)
  let llm_result, _deltas =
    validate_witness_or_exit ~args ~bundle ~ts ~raw_path raw_response
  in
  let hybrid =
    Hybrid_scoring.combine ~target:bundle.bundle_target_name mech_result llm_result
  in
  let json_path =
    Filename.concat args.cli_output_dir
      (Printf.sprintf "tsc-%s-%s.json" bundle.bundle_target_name ts)
  in
  write_file json_path (Yojson.Safe.pretty_to_string (Hybrid_scoring.to_json hybrid));
  Printf.printf "Done. Hybrid reports:\n  %s\n  %s\n" raw_path json_path

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
          Printf.eprintf "  component '%s': C_Σ^num=%.4f\n%!" cid r.aggregate.c_sigma_num;
          (cid, r.aggregate.c_sigma_num, r)
        ) kata.components
      in
      let actual_ranking =
        scored
        |> List.sort (fun (_, a, _) (_, b, _) -> compare b a)  (* high → low *)
        |> List.map (fun (cid, _, _) -> cid)
      in
      let ranking_correct = (actual_ranking = kata.ranking) in
      (* Emit result JSON — kata output uses canonical c_sigma_num for ranking. *)
      let components_json = `List (List.map (fun (cid, score, r) ->
        `Assoc [
          ("id",          `String cid);
          ("c_sigma_num", `Float score);
          ("mechanical",  Mechanical_scoring.result_to_json r);
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
      (* Compare against kata expectations — canonical c_sigma_num is the
         range-checked aggregate (well-defined under degenerate inputs). *)
      let c_sigma_num = result.aggregate.c_sigma_num in
      let kata_pass =
        match kata.verdict with
        | "pass" ->
          (* Pass: score must be within [min, max] *)
          c_sigma_num >= kata.score_min && c_sigma_num <= kata.score_max
        | "fail" ->
          (* Fail: input expected to be incoherent; score should be <= max *)
          c_sigma_num <= kata.score_max
        | v ->
          Printf.eprintf "Warning: unknown expected.verdict '%s'; treating as pass\n" v;
          c_sigma_num >= kata.score_min && c_sigma_num <= kata.score_max
      in
      (* Emit result JSON — kata output uses canonical c_sigma_num. *)
      let result_json = `Assoc [
        ("kata_id",        `String kata_id);
        ("expected_verdict", `String kata.verdict);
        ("c_sigma_num",    `Float c_sigma_num);
        ("score_range",    `Assoc [
          ("min", `Float kata.score_min);
          ("max", `Float kata.score_max);
        ]);
        ("kata_pass",      `Bool kata_pass);
        ("mechanical",     Mechanical_scoring.result_to_json result);
      ] in
      Printf.printf "%s\n" (Yojson.Safe.pretty_to_string result_json);
      if kata_pass then begin
        Printf.eprintf "KATA PASS: '%s' — C_Σ^num=%.4f within expected range [%.4f, %.4f] for verdict '%s'\n%!"
          kata_id c_sigma_num kata.score_min kata.score_max kata.verdict;
        exit 0
      end else begin
        Printf.eprintf "KATA FAIL: '%s' — C_Σ^num=%.4f outside expected range [%.4f, %.4f] for verdict '%s'\n%!"
          kata_id c_sigma_num kata.score_min kata.score_max kata.verdict;
        exit 1
      end
    end

(* ------------------------------------------------------------------ *)
(* Cross-target dispatch (Operational §7.4 / sub-issue #53) *)

(** Reject duplicate target ids before any scoring work. *)
let reject_duplicates (targets : string list) =
  let seen = Hashtbl.create 8 in
  let dups = ref [] in
  List.iter (fun t ->
    if Hashtbl.mem seen t then dups := t :: !dups
    else Hashtbl.add seen t ()
  ) targets;
  match List.rev !dups with
  | [] -> ()
  | ds ->
    Printf.eprintf
      "Error: duplicate target id(s) in cross-target request: %s\n"
      (String.concat ", " ds);
    exit 1

(** Multi-target cross-target run. Mechanical-only by AC1; the entry
    point has already verified effective_mode = Mechanical. *)
let run_cross_target ~args ~ts =
  reject_duplicates args.cli_targets;
  Printf.eprintf "Cross-target run: %d targets [%s]\n%!"
    (List.length args.cli_targets)
    (String.concat ", " args.cli_targets);
  let registry_path = Filename.concat args.cli_root args.cli_registry in
  let per_target_results =
    List.map (fun target_name ->
      let bundle =
        build_bundle_from_target
          ~root:args.cli_root
          ~registry_path
          ~target_name
      in
      let result = Mechanical_scoring.score_bundle bundle in
      Printf.eprintf "  %s: %s\n%!"
        target_name (Mechanical_scoring.summarize_result result);
      (target_name, result)
    ) args.cli_targets
  in
  let report_json =
    Cross_target.report_from_results per_target_results
  in
  let json_path =
    Filename.concat args.cli_output_dir
      (Printf.sprintf "tsc-cross-target-%s.json" ts)
  in
  write_file json_path (Yojson.Safe.pretty_to_string report_json);
  Printf.printf "Done. Cross-target report: %s\n" json_path

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

  (* Resolve effective mode (auto -> mechanical or hybrid).

     cycle/51 AC3 invariant: auto-mode mechanical selection is
     PRE-PROVIDER ONLY.  Once we enter run_llm / run_hybrid below and
     issue a provider call, any post-response failure is terminal and
     never falls back to mechanical scoring. *)
  let effective_mode = match args.cli_mode with
    | Auto ->
      if args.cli_llm_response <> "" then begin
        (* External provider route: a pre-produced response stands in
           for credentials — auto resolves to hybrid. *)
        Printf.eprintf "Auto mode: --llm-response supplied — running hybrid.\n%!";
        Hybrid
      end
      else if Tsc_engine.Credentials.has_llm_credentials () then begin
        Printf.eprintf
          "Auto mode: full provider configuration found — running hybrid.\n%!";
        Hybrid
      end else begin
        (* A partial provider configuration is a misconfiguration, not
           a credential: hybrid would fail downstream after claiming
           the semantic path. Say exactly what is missing, then run
           the honest fallback. *)
        if Tsc_engine.Credentials.partial_llm_credentials () then
          Printf.eprintf
            "Auto mode: partial LLM configuration (missing %s) — running \
             mechanical. Set all of %s for hybrid.\n%!"
            (String.concat ", "
               (Tsc_engine.Credentials.missing_llm_credentials ()))
            (String.concat ", " Tsc_engine.Credentials.provider_env_vars)
        else
          Printf.eprintf "Auto mode: no credentials — running mechanical.\n%!";
        Mechanical
      end
    | m -> m
  in

  (* Cross-target (Operational §7.4): two or more --target flags.
     Mechanical-only for this cycle; reject LLM / Hybrid explicitly. *)
  let n_targets = List.length args.cli_targets in
  if n_targets >= 2 && (args.cli_emit_prompt <> "" || args.cli_llm_response <> "") then begin
    Printf.eprintf
      "Error: --emit-prompt / --llm-response take a single --target \
       (cross-target is mechanical-only); run each target separately.\n";
    exit 1
  end;
  if n_targets >= 2 then begin
    (match effective_mode with
     | Mechanical -> ()
     | Llm | Hybrid ->
       Printf.eprintf
         "Error: cross-target is mechanical-only this cycle \
          (received %d --target with --mode %s); \
          use --mode mechanical or run each target separately.\n"
         n_targets
         (match args.cli_mode with
          | Mechanical -> "mechanical"
          | Llm -> "llm"
          | Hybrid -> "hybrid"
          | Auto -> "auto");
       exit 1
     | Auto -> assert false);
    run_cross_target ~args ~ts;
    exit 0
  end;

  (* Single-target / --files path — unchanged behavior. *)
  let single_target =
    match args.cli_targets with
    | [t] -> t
    | []  -> ""
    | _   -> assert false  (* >=2 already handled *)
  in
  let bundle =
    if single_target <> "" then
      build_bundle_from_target
        ~root
        ~registry_path:(Filename.concat root args.cli_registry)
        ~target_name:single_target
    else
      build_bundle_from_files ~root ~globs:args.cli_files
  in

  (* --emit-prompt: write the exact LLM prompt for this bundle and exit.
     This is the deterministic half of the external provider route — the
     emitted file is byte-identical to what the HTTP route would send
     (instruction + target metadata + hashed file bundle). *)
  if args.cli_emit_prompt <> "" then begin
    let instruction =
      match read_file (Filename.concat args.cli_root args.cli_instruction) with
      | Error e -> Printf.eprintf "Error: %s\n" e; exit 1
      | Ok content -> content
    in
    let prompt = Prompt.build_prompt ~instruction ~bundle in
    write_file args.cli_emit_prompt prompt;
    Printf.printf "Done. LLM prompt (%d files, %d bytes): %s\n"
      (List.length bundle.bundle_files)
      (String.length prompt)
      args.cli_emit_prompt;
    exit 0
  end;

  (* Dispatch *)
  match effective_mode with
  | Mechanical -> run_mechanical ~args ~bundle ~ts
  | Llm        -> run_llm        ~args ~bundle ~ts
  | Hybrid     -> run_hybrid     ~args ~bundle ~ts
  | Auto       -> assert false  (* resolved above *)
