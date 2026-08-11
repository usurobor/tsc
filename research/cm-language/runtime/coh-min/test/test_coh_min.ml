(* test_coh_min — stdlib-only assertions (no ppx; the contract forbids it).
   `dune runtest` runs this; a non-zero exit fails the build.

   Invariants proved (test skill §2.1):
     1. PATH CONFINEMENT (#126 AC6, the fail-closed invariant) — the pure
        [confine] function ADMITS an in-root path and DENIES every escape shape.
        Proved as a pure-function test: the strongest cheap proof, no filesystem
        needed.
     2. FIXTURE SENSITIVITY (#126 AC2/AC3/AC4) — running the real runner against
        a subject WITH a README yields README_PRESENT and against one WITHOUT
        yields README_ABSENT, and the two receipts are NOT byte-identical.
     3. FAIL-CLOSED EXECUTION (#126 AC6 end to end) — an IR whose provider config
        escapes the subject root makes the whole run return Error (no receipt).
     4. CANONICAL IR REQUIRED (#127 AC5) — an IR missing ANY canonical
        `#NormalizedCMIR` block, or any field the runtime consumes, fails closed
        with a clean `IR error` and no receipt. Table-driven over
        [Ir.canonical_blocks], so the required set and its regression table
        cannot drift apart.
     5. VOCABULARY IS THE IR'S (#127 AC4) — the emitted `result_class` must be
        one the IR declares. Proved by CHANGING ONLY the IR's declared set and
        watching the identical run flip from receipt to fail-closed refusal:
        that is what distinguishes "read from the IR" from "hardcoded in OCaml".

   Invariants 2–5 build their own temp subject dirs + IR files, so the test is
   self-contained and does not depend on the examples/ tree layout. The shipped
   example IRs are gated separately, and against the real schema, by
   `make vet-ir`. *)

module J = Coh_min.Json
module Ir = Coh_min.Ir
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

(* ── canonical #NormalizedCMIR fixtures (#127) ──

   Built as JSON VALUES rather than a printf'd string, so a regression can omit
   exactly one canonical block ([List.remove_assoc]) or swap exactly one
   declared vocabulary, with everything else held identical. A negative fixture
   that differs in one field is evidence; one hand-retyped as a whole string is
   not. This mirrors the shape of `examples/readme-present/ir/*.ir.json`. *)

let s x = J.Str x
let b x = J.Bool x
let arr x = J.Arr x
let obj x = J.Obj x

let default_classes = [ "README_PRESENT"; "README_ABSENT"; "INCOMPLETE" ]

let readme_step ~relative_path = [
  "id", s "readme_exists";
  "kind", s "mechanical";
  "provider_kind", s "tool";
  "provider_class", s "file.exists";
  "reads", arr [ s "target_root" ];
  "produces", s "readme_presence";
  "config", obj [ "relative_path", s relative_path ];
  "search_strength", s "exact";
  "may_access", arr [];
  "failure", s "INCOMPLETE";
]

(* A step whose `reads` surface no step ever produces: it can never become
   ready, so it is a principled SKIP and drives the run to INCOMPLETE. *)
let never_ready_step = [
  "id", s "never_ready";
  "kind", s "mechanical";
  "provider_kind", s "tool";
  "provider_class", s "file.exists";
  "reads", arr [ s "a_surface_no_step_produces" ];
  "produces", s "unreachable";
  "config", obj [ "relative_path", s "README.md" ];
  "search_strength", s "exact";
  "may_access", arr [];
  "failure", s "INCOMPLETE";
]

let ir_fields
    ?(relative_path = "README.md")
    ?(result_classes = default_classes)
    ?(extra_steps = [])
    () = [
  "format", s "tsc-cm-ir/0.1";
  "cm_id", s "example.readme-present";
  "cm_version", s "0.1";
  "source_digest",
  s "sha256:0000000000000000000000000000000000000000000000000000000000000000";
  "input_contract", obj [
    "kind", s "repository_subject";
    "required_artifacts", arr [
      obj [ "role", s "target_root"; "kind", s "directory"; "required", b true ]
    ];
    "artifact_lists", arr [];
    "runtime_binding", s "INCOMPLETE";
  ];
  "procedure", obj [
    "steps", arr (List.map obj (readme_step ~relative_path :: extra_steps))
  ];
  "result_contract", obj [
    "kind", s "readme_presence_measurement";
    "subcontracts", arr [ s "readme_exists" ];
    "runtime_binding", s "INCOMPLETE";
    "result_classes", arr (List.map s result_classes);
    "emits", obj [
      "admission_verdict", b false;
      "authorization", b false;
      "boundary_decision", b false;
    ];
    "derivation", s "unrun step -> INCOMPLETE; else readme_presence true -> \
                     README_PRESENT, false -> README_ABSENT.";
  ];
  "receipt_contract", obj [
    "kind", s "readme_presence_measurement";
    "reports", arr [ s "readme_presence"; s "result_class" ];
    "measure_only", b true;
  ];
]

let result_class_of receipt = J.to_string (J.member "result_class" (J.member "result" receipt))
let complete_of receipt =
  match J.member_opt "complete" (J.member "result" receipt) with
  | Some (J.Bool x) -> x
  | _ -> false

(* ── temp-file plumbing shared by the end-to-end tests ── *)

let ir_seq = ref 0
let write_ir base fields =
  incr ir_seq;
  let path = Filename.concat base (Printf.sprintf "ir-%d.json" !ir_seq) in
  write_file path (J.document (obj fields));
  path

(* Run and demand the clean fail-closed IR-error channel: an [Error] whose
   message carries the documented class prefix, never an [Ok] receipt and never
   an escaping exception (the last arm is exactly β #126 F1's bug class). *)
let is_ir_error ~target_root ir_path =
  match R.run { R.ir_path; target_root } with
  | Error msg -> String.length msg >= 8 && String.sub msg 0 8 = "IR error"
  | Ok _ -> false
  | exception _ -> false

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
  let ir_ok = write_ir base (ir_fields ()) in
  let ir_escape = write_ir base (ir_fields ~relative_path:"../escape" ()) in
  (match R.run { R.ir_path = ir_ok; target_root = present_dir } with
   | Ok r ->
     check "present subject -> README_PRESENT" (result_class_of r = "README_PRESENT")
   | Error e -> check ("present run should succeed, got: " ^ e) false);
  (match R.run { R.ir_path = ir_ok; target_root = absent_dir } with
   | Ok r ->
     check "absent subject -> README_ABSENT" (result_class_of r = "README_ABSENT")
   | Error e -> check ("absent run should succeed, got: " ^ e) false);
  (* #126 AC4: the two receipts must not be byte-identical. *)
  (match R.run { R.ir_path = ir_ok; target_root = present_dir },
         R.run { R.ir_path = ir_ok; target_root = absent_dir } with
   | Ok rp, Ok ra -> check "present and absent receipts differ" (J.document rp <> J.document ra)
   | _ -> check "both runs produced receipts for the differ check" false);
  (* #126 AC6 end to end: an escaping config denies the whole run (no receipt). *)
  check "escaping relative_path fails the run closed"
    (is_error (R.run { R.ir_path = ir_escape; target_root = present_dir }));
  (* β #126 round-1 F1 regression pair: the vendored parser raises exception
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
  check "malformed number literal (12e) IR -> clean IR error (no exception)"
    (is_ir_error ~target_root:present_dir ir_bad_number);
  check "truncated \\u escape IR -> clean IR error (no exception)"
    (is_ir_error ~target_root:present_dir ir_bad_escape);
  (base, present_dir)

(* ── 4. #127 AC5: a non-canonical IR never executes ──

   Table-driven over [Ir.canonical_blocks] — the SAME list the validator uses,
   so adding a required block to the contract automatically adds its regression
   here instead of silently leaving one untested. *)
let test_canonical_blocks_required base present_dir =
  List.iter
    (fun block ->
       let path = write_ir base (List.remove_assoc block (ir_fields ())) in
       check
         (Printf.sprintf "IR missing canonical block %S -> clean IR error, no receipt" block)
         (is_ir_error ~target_root:present_dir path))
    Ir.canonical_blocks;
  (* The `format` field is present but not the pinned NormalizedCMIR literal:
     the artifact is not a CM IR at all, and must be refused before anything
     downstream depends on it. *)
  let wrong_format =
    ("format", s "tsc-measurement-receipt/0.1")
    :: List.remove_assoc "format" (ir_fields ()) in
  check "IR with a non-NormalizedCMIR `format` -> clean IR error"
    (is_ir_error ~target_root:present_dir (write_ir base wrong_format));
  (* Nested required fields: a canonical block that is PRESENT but hollow is
     just as unrunnable as an absent one. Each replaces exactly one block with
     the same block minus one field. *)
  let without key block fields =
    (block, obj (List.remove_assoc key
                   (match List.assoc block fields with
                    | J.Obj kvs -> kvs
                    | _ -> [])))
    :: List.remove_assoc block fields
  in
  let cases = [
    "procedure.steps", without "steps" "procedure" (ir_fields ());
    "input_contract.required_artifacts",
    without "required_artifacts" "input_contract" (ir_fields ());
    "result_contract.result_classes",
    without "result_classes" "result_contract" (ir_fields ());
  ] in
  List.iter
    (fun (name, fields) ->
       check (Printf.sprintf "IR missing %s -> clean IR error, no receipt" name)
         (is_ir_error ~target_root:present_dir (write_ir base fields)))
    cases;
  (* A step missing a field the runtime consumes; the error must name the step
     by its dotted path rather than crashing in the linker. *)
  let step_missing_produces =
    ir_fields () |> List.remove_assoc "procedure" |> fun rest ->
    ("procedure",
     obj [ "steps", arr [ obj (List.remove_assoc "produces" (readme_step ~relative_path:"README.md")) ] ])
    :: rest
  in
  check "IR step missing `produces` -> clean IR error, no receipt"
    (is_ir_error ~target_root:present_dir (write_ir base step_missing_produces))

(* ── 5. #127 AC4: the result-class vocabulary is the IR's, not the runner's ──

   The discriminating experiment: hold the subject, the provider and the
   derivation fixed, and change ONLY `result_contract.result_classes`. A runner
   with the vocabulary hardcoded in OCaml would emit the same receipt either
   way; this one must refuse. *)
let test_vocabulary_gate base present_dir =
  (* positive: the declared vocabulary covers the derived class *)
  (match R.run { R.ir_path = write_ir base (ir_fields ()); target_root = present_dir } with
   | Ok r ->
     check "declared vocabulary admits the derived class (README_PRESENT)"
       (result_class_of r = "README_PRESENT")
   | Error e -> check ("declared-vocabulary run should succeed, got: " ^ e) false);
  (* negative: a CM declaring a DIFFERENT vocabulary refuses the same run *)
  let foreign =
    write_ir base (ir_fields ~result_classes:[ "PRESENT"; "ABSENT"; "INCOMPLETE" ] ()) in
  check "IR declaring a different vocabulary -> run fails closed (no receipt)"
    (is_error (R.run { R.ir_path = foreign; target_root = present_dir }));
  (* and the refusal must name the offending class, not just fail *)
  check "vocabulary refusal names the undeclared class"
    (match R.run { R.ir_path = foreign; target_root = present_dir } with
     | Error msg ->
       let has needle =
         let n = String.length needle and h = String.length msg in
         let rec scan i = i + n <= h && (String.sub msg i n = needle || scan (i + 1)) in
         scan 0
       in
       has "README_PRESENT" && has "result_classes"
     | Ok _ -> false);
  (* the INCOMPLETE class is gated by the same rule: an unrun step drives the
     derivation to INCOMPLETE, which is emitted only when the IR declares it *)
  let skip_declared = write_ir base (ir_fields ~extra_steps:[ never_ready_step ] ()) in
  (match R.run { R.ir_path = skip_declared; target_root = present_dir } with
   | Ok r ->
     check "unrun step -> INCOMPLETE receipt (declared), complete=false"
       (result_class_of r = "INCOMPLETE" && not (complete_of r))
   | Error e -> check ("skip run should succeed with INCOMPLETE, got: " ^ e) false);
  let skip_undeclared =
    write_ir base
      (ir_fields ~extra_steps:[ never_ready_step ]
         ~result_classes:[ "README_PRESENT"; "README_ABSENT" ] ()) in
  check "unrun step with INCOMPLETE undeclared -> fails closed (no receipt)"
    (is_error (R.run { R.ir_path = skip_undeclared; target_root = present_dir }))

let () =
  test_confine ();
  let (base, present_dir) = test_end_to_end () in
  test_canonical_blocks_required base present_dir;
  test_vocabulary_gate base present_dir;
  if !failures > 0 then (Printf.printf "\n%d check(s) failed\n" !failures; exit 1)
  else Printf.printf "\nall checks passed\n"
