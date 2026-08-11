(* test_coh_min — stdlib-only assertions (no ppx; the contract forbids it).
   `dune runtest` runs this; a non-zero exit fails the build.

   Invariants proved (test skill §2.1):
     1. PATH CONFINEMENT (AC6, the fail-closed invariant) — the pure [confine]
        function ADMITS an in-root path and DENIES every escape shape. Proved as
        a pure-function test: the strongest cheap proof, no filesystem needed.
     2. FIXTURE SENSITIVITY (AC2/AC3/AC4) — running the real runner against a
        subject WITH a README yields README_PRESENT and against one WITHOUT
        yields README_ABSENT, and the two receipts are NOT byte-identical.
     3. FAIL-CLOSED EXECUTION (AC6 end to end) — an IR whose provider config
        escapes the subject root makes the whole run return Error (no receipt).

   Invariants 2 and 3 build their own temp subject dirs + IR files, so the test
   is self-contained and does not depend on the examples/ tree layout. *)

module J = Coh_min.Json
module P = Coh_min.Provider
module R = Coh_min.Runner

let failures = ref 0
let check name cond =
  if cond then Printf.printf "ok   - %s\n" name
  else (incr failures; Printf.printf "FAIL - %s\n" name)

let is_error = function Error _ -> true | Ok _ -> false

(* ── 1. path confinement (pure) ── *)
let test_confine () =
  let admit rel = P.confine ~root:"/subject" ~rel in
  check "confine admits README.md" (admit "README.md" = Ok "/subject/README.md");
  check "confine admits nested docs/README.md"
    (admit "docs/README.md" = Ok "/subject/docs/README.md");
  check "confine denies empty" (is_error (admit ""));
  check "confine denies absolute /etc/passwd" (is_error (admit "/etc/passwd"));
  check "confine denies leading ../" (is_error (admit "../secret"));
  check "confine denies interior a/../../b" (is_error (admit "a/../../b"));
  check "confine denies bare .." (is_error (admit ".."));
  (* a filename that merely CONTAINS dots but is not a `..` segment is fine *)
  check "confine admits ..README (not a segment)" (admit "..README" = Ok "/subject/..README")

(* ── temp-dir scaffolding for the end-to-end tests ── *)
let mkdir_p path = if not (Sys.file_exists path) then Sys.mkdir path 0o755

let write_file path contents =
  let oc = open_out_bin path in
  Fun.protect ~finally:(fun () -> close_out oc) (fun () -> output_string oc contents)

let ir_json ~relative_path =
  Printf.sprintf {|{
  "format": "tsc-cm-ir/0.1",
  "cm_id": "example.readme-present",
  "cm_version": "0.1",
  "source_digest": "sha256:0000000000000000000000000000000000000000000000000000000000000000",
  "input_contract": {
    "kind": "repository_subject",
    "required_artifacts": [ { "role": "target_root", "kind": "directory", "required": true } ],
    "artifact_lists": [],
    "runtime_binding": "INCOMPLETE"
  },
  "procedure": { "steps": [ {
    "id": "readme_exists", "kind": "mechanical", "provider_kind": "tool",
    "provider_class": "file.exists", "reads": ["target_root"],
    "produces": "readme_presence", "config": { "relative_path": %S },
    "search_strength": "exact", "may_access": [], "failure": "INCOMPLETE"
  } ] }
}|} relative_path

let result_class_of receipt = J.to_string (J.member "result_class" (J.member "result" receipt))

let test_end_to_end () =
  (* A stdlib-only unique temp dir: temp_file mints a unique name, which we
     replace with a directory (no Unix.getpid — the contract forbids Unix). *)
  let base = Filename.temp_file "coh_min_test_" "" in
  Sys.remove base;
  mkdir_p base;
  let present_dir = Filename.concat base "present" in
  let absent_dir = Filename.concat base "absent" in
  mkdir_p present_dir; mkdir_p absent_dir;
  write_file (Filename.concat present_dir "README.md") "# subject under test\n";
  let ir_ok = Filename.concat base "ok.ir.json" in
  let ir_escape = Filename.concat base "escape.ir.json" in
  write_file ir_ok (ir_json ~relative_path:"README.md");
  write_file ir_escape (ir_json ~relative_path:"../escape");
  (match R.run { R.ir_path = ir_ok; target_root = present_dir } with
   | Ok r ->
     check "present subject -> README_PRESENT" (result_class_of r = "README_PRESENT")
   | Error e -> check ("present run should succeed, got: " ^ e) false);
  (match R.run { R.ir_path = ir_ok; target_root = absent_dir } with
   | Ok r ->
     check "absent subject -> README_ABSENT" (result_class_of r = "README_ABSENT")
   | Error e -> check ("absent run should succeed, got: " ^ e) false);
  (* AC4: the two receipts must not be byte-identical. *)
  (match R.run { R.ir_path = ir_ok; target_root = present_dir },
         R.run { R.ir_path = ir_ok; target_root = absent_dir } with
   | Ok rp, Ok ra -> check "present and absent receipts differ" (J.document rp <> J.document ra)
   | _ -> check "both runs produced receipts for the differ check" false);
  (* AC6 end to end: an escaping config denies the whole run (no receipt). *)
  check "escaping relative_path fails the run closed"
    (is_error (R.run { R.ir_path = ir_escape; target_root = present_dir }));
  (* β round-1 F1 regression pair: the vendored parser raises exception
     classes beyond Parse_error — [Failure] on a malformed number literal and
     [Invalid_argument] on a truncated `\u` escape. Both must funnel to the
     clean fail-closed [Error] channel (never an escaping exception; the CLI
     maps that channel to exit 1). Before the fix these two inputs crashed
     this very test process, which is why the earlier malformed-IR coverage
     did not catch them. *)
  let ir_bad_number = Filename.concat base "bad-number.ir.json" in
  let ir_bad_escape = Filename.concat base "bad-escape.ir.json" in
  write_file ir_bad_number {|{ "cm_id": "x", "n": 12e }|};
  write_file ir_bad_escape {|{ "cm_id": "\u00|};
  let run_error ir_path =
    match R.run { R.ir_path; target_root = present_dir } with
    | Error msg ->
      (* the fault must surface on the documented channel with its prefix *)
      String.length msg >= 8 && String.sub msg 0 8 = "IR error"
    | Ok _ -> false
    | exception _ -> false   (* an escaping exception is exactly the F1 bug *)
  in
  check "malformed number literal (12e) IR -> clean IR error (no exception)"
    (run_error ir_bad_number);
  check "truncated \\u escape IR -> clean IR error (no exception)"
    (run_error ir_bad_escape)

let () =
  test_confine ();
  test_end_to_end ();
  if !failures > 0 then (Printf.printf "\n%d check(s) failed\n" !failures; exit 1)
  else Printf.printf "\nall checks passed\n"
