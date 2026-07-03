(** Tests for sub-issue #54 AC6 — target-registry smoke tests.

    Run via: opam exec -- dune runtest engine/ocaml/test/

    AC6 invariant: the test suite proves the shipped target registry
    resolves the canonical targets to non-empty bundles.

    AC6 oracle (each bullet a check below):
      1. parse_registry yields Ok for targets/registry.tsc;
         asserts registry_format = "tsc-target-registry/0.1".
      2. exactly the five names {spec, engine, repo, methodology,
         cm-of-cms} are registered (methodology and cm-of-cms joined
         with the CM² wave — the 1st and 0th coherence methodologies
         as measurable targets).
      3. resolve_target_path returns Ok for each name -> the canonical
         targets/<name>.tsc manifest path.
      4. parse_manifest returns Ok with a non-empty manifest_include OR
         manifest_include_targets list for each target.
      5. file expansion produces > 0 files for each target via the same
         root/path semantics main.ml uses (prefix+suffix glob walk).

    The registry, manifest, and glob-expansion code lives in
    [engine/ocaml/lib/target_registry.ml] + [engine/ocaml/bin/main.ml].
    main.ml's glob helper is reproduced here verbatim so the test
    exercises the same semantics without depending on the binary
    target. *)

open Tsc_engine

(* ------------------------------------------------------------------ *)
(* Helpers (test-suite style identical to test_cross_target.ml) *)

let fail msg =
  Printf.eprintf "FAIL: %s\n%!" msg;
  exit 1

let pass label =
  Printf.printf "PASS: %s\n%!" label

let check cond label =
  if not cond then fail label else pass label

(* ------------------------------------------------------------------ *)
(* Test fixtures — resolved relative to repo root.

   When dune runs the test, the cwd may be _build/default/engine/ocaml/test/.
   Walk up from cwd to find the repo root (directory containing VERSION
   alongside targets/registry.tsc). This matches the dune-runtime
   convention used by other tests in this suite. *)

let rec find_repo_root start =
  if Sys.file_exists (Filename.concat start "VERSION")
     && Sys.file_exists (Filename.concat start "targets/registry.tsc")
  then start
  else
    let parent = Filename.dirname start in
    if parent = start then
      fail "test_target_registry: could not locate repo root from cwd"
    else find_repo_root parent

let repo_root = lazy (find_repo_root (Sys.getcwd ()))

let read_file path =
  if not (Sys.file_exists path) then
    fail (Printf.sprintf "fixture missing: %s" path)
  else
    let ic = open_in path in
    Fun.protect ~finally:(fun () -> close_in ic) (fun () ->
      let len = in_channel_length ic in
      really_input_string ic len
    )

(* ------------------------------------------------------------------ *)
(* Reproduce main.ml's [expand_glob] verbatim so the test exercises the
   same file-resolution semantics the runtime uses. *)

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
          let prefix =
            match String.split_on_char '*' pattern with
            | p :: _ -> p
            | []     -> ""
          in
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

(* Resolve a manifest's full file set: include - exclude across all
   patterns; matches main.ml's [resolve_manifest_files] logic minus
   the file I/O. *)
let expand_manifest_paths ~root (m : Types.target_manifest) =
  let included = List.concat_map (expand_glob ~root) m.manifest_include in
  let excluded = List.concat_map (expand_glob ~root) m.manifest_exclude in
  List.filter (fun p -> not (List.mem p excluded)) included

(* ------------------------------------------------------------------ *)
(* AC6 bullet 1 + 2: parse_registry yields Ok with the canonical format
   and exactly the three expected targets. *)

let test_parse_registry () =
  let root = Lazy.force repo_root in
  let registry_path = Filename.concat root "targets/registry.tsc" in
  let content = read_file registry_path in
  match Target_registry.parse_registry content with
  | Error e -> fail (Printf.sprintf "parse_registry: %s" e)
  | Ok reg ->
    check (reg.registry_format = "tsc-target-registry/0.1")
      (Printf.sprintf
         "AC6.1: registry_format = \"tsc-target-registry/0.1\" (got %S)"
         reg.registry_format);
    let names = List.map fst reg.registry_targets in
    let sorted = List.sort String.compare names in
    check (sorted = ["cm-of-cms"; "engine"; "methodology"; "repo"; "spec"])
      (Printf.sprintf
         "AC6.2: exactly {spec, engine, repo, methodology, cm-of-cms} \
          registered (got %s)"
         (String.concat ", " sorted))

(* AC6 bullet 3: resolve_target_path returns the canonical manifest
   path for each registered name. *)

let test_resolve_target_path () =
  let root = Lazy.force repo_root in
  let content = read_file (Filename.concat root "targets/registry.tsc") in
  match Target_registry.parse_registry content with
  | Error e -> fail (Printf.sprintf "parse_registry: %s" e)
  | Ok reg ->
    let expect name expected_path =
      match Target_registry.resolve_target_path reg name with
      | Error e -> fail (Printf.sprintf "resolve_target_path %s: %s" name e)
      | Ok p ->
        check (p = expected_path)
          (Printf.sprintf "AC6.3: resolve %S -> %S (got %S)"
             name expected_path p)
    in
    expect "spec"        "targets/spec.tsc";
    expect "engine"      "targets/engine.tsc";
    expect "repo"        "targets/repo.tsc";
    expect "methodology" "targets/methodology.tsc";
    expect "cm-of-cms"   "targets/cm-of-cms.tsc"

(* AC6 bullet 4: each manifest parses and carries a non-empty include
   OR include_targets list. (spec and engine carry `include` globs;
   repo carries `include_targets` plus a few singleton `include` paths.) *)

let test_parse_manifest_each () =
  let root = Lazy.force repo_root in
  let content = read_file (Filename.concat root "targets/registry.tsc") in
  match Target_registry.parse_registry content with
  | Error e -> fail (Printf.sprintf "parse_registry: %s" e)
  | Ok reg ->
    List.iter (fun name ->
      (match Target_registry.resolve_target_path reg name with
       | Error e -> fail (Printf.sprintf "resolve %s: %s" name e)
       | Ok mpath ->
         let mc = read_file (Filename.concat root mpath) in
         (match Target_registry.parse_manifest mc with
          | Error e -> fail (Printf.sprintf "parse_manifest %s: %s" name e)
          | Ok m ->
            let nonempty =
              m.manifest_include <> [] || m.manifest_include_targets <> []
            in
            check nonempty
              (Printf.sprintf
                 "AC6.4: %s manifest has non-empty include or include_targets \
                  (got %d include, %d include_targets)"
                 name
                 (List.length m.manifest_include)
                 (List.length m.manifest_include_targets))))
    ) ["spec"; "engine"; "repo"; "methodology"; "cm-of-cms"]

(* AC6 bullet 5: file expansion produces > 0 files for each target
   using the same root/path semantics main.ml uses. For `repo` (aggregate
   target), expansion includes both its own globs and the nested-target
   manifests it includes (spec + engine). *)

let test_file_expansion_nonempty () =
  let root = Lazy.force repo_root in
  let content = read_file (Filename.concat root "targets/registry.tsc") in
  match Target_registry.parse_registry content with
  | Error e -> fail (Printf.sprintf "parse_registry: %s" e)
  | Ok reg ->
    let expand_one name =
      match Target_registry.resolve_target_path reg name with
      | Error e -> fail (Printf.sprintf "resolve %s: %s" name e)
      | Ok mpath ->
        let mc = read_file (Filename.concat root mpath) in
        (match Target_registry.parse_manifest mc with
         | Error e -> fail (Printf.sprintf "parse_manifest %s: %s" name e)
         | Ok m ->
           let own = expand_manifest_paths ~root m in
           let nested =
             List.concat_map (fun nested_name ->
               (match Target_registry.resolve_target_path reg nested_name with
                | Error _ -> []
                | Ok npath ->
                  (match Target_registry.parse_manifest
                           (read_file (Filename.concat root npath)) with
                   | Error _ -> []
                   | Ok nm -> expand_manifest_paths ~root nm))
             ) m.manifest_include_targets
           in
           (* Dedup like main.ml does. *)
           let all = own @ nested in
           let seen = Hashtbl.create 64 in
           List.filter (fun p ->
             if Hashtbl.mem seen p then false
             else (Hashtbl.add seen p (); true)
           ) all)
    in
    List.iter (fun name ->
      let files = expand_one name in
      let n = List.length files in
      check (n > 0)
        (Printf.sprintf "AC6.5: target %S expands to %d > 0 files" name n)
    ) ["spec"; "engine"; "repo"; "methodology"; "cm-of-cms"]

(* ------------------------------------------------------------------ *)
(* Runner *)

let () =
  Printf.printf "=== TSC target-registry smoke tests (#54 AC6) ===\n%!";
  test_parse_registry ();
  test_resolve_target_path ();
  test_parse_manifest_each ();
  test_file_expansion_nonempty ();
  Printf.printf "=== All target-registry smoke tests passed ===\n%!"
