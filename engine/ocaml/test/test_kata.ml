(** OCaml tests for the kata framework — AC6 of tsc issue #33,
    AC4 of tsc issue #34.

    Tests run via: cd engine/ocaml && opam exec -- dune runtest

    Covered:
    - kata-01 (glider) config loads correctly (id, verdict, score_range)
    - kata-02 (random-soup) config loads correctly (id, verdict, score_range)
    - kata-03 (comparative) config loads correctly (components + ranking)
    - kata-04 (philosophical) config loads correctly (mechanical mode +
      verdict=fail + mode justification claim)
    - kata-05 (adversarial) config loads correctly (multi-file fail verdict)
    - Missing kata returns an Error (not an exception)

    These tests are hermetic: no LLM calls, no network, no credentials required. *)

let fail msg =
  Printf.eprintf "FAIL: %s\n%!" msg;
  exit 1

let pass label =
  Printf.printf "PASS: %s\n%!" label

let check cond label =
  if not cond then fail label else pass label

(* ------------------------------------------------------------------ *)
(* Helpers: find katas directory relative to test binary location *)

(** Locate the katas/ directory.

    Under [dune runtest], the test binary runs from
    [engine/ocaml/_build/default/test/].  The katas dir lives at the
    repo root, five levels up: [../../../../../katas].

    When [TSC_ROOT] is set (e.g. by CI or manual override), we use that.
    Otherwise we try known relative candidates in order. *)
let katas_dir =
  match Sys.getenv_opt "TSC_ROOT" with
  | Some root -> Filename.concat root "katas"
  | None ->
    (* Candidates: dune _build path, then repo-root path (for manual runs) *)
    let candidates = [
      "../../../../../katas";  (* from _build/default/test/ under engine/ocaml *)
      "../../katas";           (* from engine/ocaml/ directly *)
      "katas";                 (* from repo root *)
    ] in
    match List.find_opt Sys.file_exists candidates with
    | Some p -> p
    | None   -> "katas"  (* last resort — let load() produce a useful error *)

(* ------------------------------------------------------------------ *)
(* Test: kata-01 (glider) loads correctly *)

let () =
  let result = Tsc_engine.Kata.load katas_dir "01-glider" in
  match result with
  | Error e -> fail (Printf.sprintf "kata-01 load failed: %s" e)
  | Ok k ->
    check (k.Tsc_engine.Kata.id = "01-glider")
      "kata-01: id = 01-glider";
    check (k.verdict = "pass")
      "kata-01: expected.verdict = pass";
    (* Range is over canonical C_Σ^num (geometric mean; spec/tsc-core.md §5).
       Positive-control min was widened from the pre-cutover arithmetic
       baseline of 0.87 because geometric ≤ arithmetic. *)
    check (k.score_min >= 0.75 && k.score_min <= 0.92)
      (Printf.sprintf "kata-01: score_min = %.4f (expected in [0.75, 0.92])" k.score_min);
    check (k.score_max = 1.0)
      (Printf.sprintf "kata-01: score_max = %.4f (expected 1.0)" k.score_max);
    check (k.input_files <> [])
      "kata-01: input.files is non-empty";
    check (k.difficulty = 1)
      (Printf.sprintf "kata-01: difficulty = %d (expected 1)" k.difficulty);
    Printf.printf "kata-01 loaded OK\n%!"

(* ------------------------------------------------------------------ *)
(* Test: kata-02 (random-soup) loads correctly *)

let () =
  let result = Tsc_engine.Kata.load katas_dir "02-random-soup" in
  match result with
  | Error e -> fail (Printf.sprintf "kata-02 load failed: %s" e)
  | Ok k ->
    check (k.Tsc_engine.Kata.id = "02-random-soup")
      "kata-02: id = 02-random-soup";
    check (k.verdict = "fail")
      "kata-02: expected.verdict = fail";
    check (k.score_max >= 0.60 && k.score_max <= 0.85)
      (Printf.sprintf "kata-02: score_max = %.4f (expected in [0.60, 0.85])" k.score_max);
    check (k.score_min = 0.0)
      (Printf.sprintf "kata-02: score_min = %.4f (expected 0.0)" k.score_min);
    check (k.input_files <> [])
      "kata-02: input.files is non-empty";
    check (k.difficulty = 1)
      (Printf.sprintf "kata-02: difficulty = %d (expected 1)" k.difficulty);
    Printf.printf "kata-02 loaded OK\n%!"

(* ------------------------------------------------------------------ *)
(* Test: kata-03 (comparative) loads correctly *)

let () =
  let result = Tsc_engine.Kata.load katas_dir "03-comparative" in
  match result with
  | Error e -> fail (Printf.sprintf "kata-03 load failed: %s" e)
  | Ok k ->
    check (k.Tsc_engine.Kata.id = "03-comparative")
      "kata-03: id = 03-comparative";
    check (k.mode = "mechanical")
      (Printf.sprintf "kata-03: mode = %s (expected mechanical)" k.mode);
    check (List.length k.components = 2)
      (Printf.sprintf "kata-03: %d components (expected 2)" (List.length k.components));
    let comp_ids = List.map (fun c -> c.Tsc_engine.Kata.comp_id) k.components in
    check (comp_ids = ["glider"; "random-soup"])
      (Printf.sprintf "kata-03: component ids = [%s] (expected [glider; random-soup])"
         (String.concat "; " comp_ids));
    check (k.ranking = ["glider"; "random-soup"])
      (Printf.sprintf "kata-03: ranking = [%s] (expected [glider; random-soup])"
         (String.concat "; " k.ranking));
    check (k.difficulty = 2)
      (Printf.sprintf "kata-03: difficulty = %d (expected 2)" k.difficulty);
    Printf.printf "kata-03 loaded OK\n%!"

(* ------------------------------------------------------------------ *)
(* Test: kata-04 (philosophical) loads correctly *)

let () =
  let result = Tsc_engine.Kata.load katas_dir "04-philosophical" in
  match result with
  | Error e -> fail (Printf.sprintf "kata-04 load failed: %s" e)
  | Ok k ->
    check (k.Tsc_engine.Kata.id = "04-philosophical")
      "kata-04: id = 04-philosophical";
    check (k.mode = "mechanical")
      (Printf.sprintf "kata-04: mode = %s (expected mechanical — γ-decided)" k.mode);
    check (k.verdict = "fail")
      (Printf.sprintf "kata-04: verdict = %s (expected fail)" k.verdict);
    check (k.score_max >= 0.9)
      (Printf.sprintf "kata-04: score_max = %.4f (expected >= 0.9 to bracket observed C_Σ ≈ 0.93)" k.score_max);
    check (k.input_files <> [])
      "kata-04: input.files is non-empty";
    check (k.components = [])
      "kata-04: no components (single-bundle Phase 1 schema)";
    Printf.printf "kata-04 loaded OK\n%!"

(* ------------------------------------------------------------------ *)
(* Test: kata-05 (adversarial) loads correctly *)

let () =
  let result = Tsc_engine.Kata.load katas_dir "05-adversarial" in
  match result with
  | Error e -> fail (Printf.sprintf "kata-05 load failed: %s" e)
  | Ok k ->
    check (k.Tsc_engine.Kata.id = "05-adversarial")
      "kata-05: id = 05-adversarial";
    check (k.mode = "mechanical")
      (Printf.sprintf "kata-05: mode = %s (expected mechanical)" k.mode);
    check (k.verdict = "fail")
      (Printf.sprintf "kata-05: verdict = %s (expected fail)" k.verdict);
    check (List.length k.input_files = 3)
      (Printf.sprintf "kata-05: %d input files (expected 3 — multi-file adversarial)" (List.length k.input_files));
    check (k.score_max <= 0.85)
      (Printf.sprintf "kata-05: score_max = %.4f (expected <= 0.85)" k.score_max);
    check (k.difficulty = 4)
      (Printf.sprintf "kata-05: difficulty = %d (expected 4)" k.difficulty);
    Printf.printf "kata-05 loaded OK\n%!"

(* ------------------------------------------------------------------ *)
(* Test: kata-03 README documents component-copy rationale (AC1 surface) *)

let read_text path =
  if Sys.file_exists path then
    let ic = open_in path in
    Fun.protect ~finally:(fun () -> close_in ic) (fun () ->
      let len = in_channel_length ic in
      really_input_string ic len
    )
  else ""

let contains haystack needle =
  let h_len = String.length haystack in
  let n_len = String.length needle in
  if n_len = 0 then true
  else
    let rec scan i =
      if i + n_len > h_len then false
      else if String.sub haystack i n_len = needle then true
      else scan (i + 1)
    in
    scan 0

let () =
  let readme = read_text (Filename.concat katas_dir "03-comparative/README.md") in
  check (contains readme "ranking")
    "kata-03: README mentions ranking invariant";
  check (contains readme "glider" && contains readme "random-soup")
    "kata-03: README references both kata-01 and kata-02 source inputs";
  Printf.printf "kata-03 README OK\n%!"

(* ------------------------------------------------------------------ *)
(* Test: kata-04 README contains mode justification (AC2 / cycle #34 active
   design constraint). γ's design: kata-04 README must explicitly justify the
   mechanical-mode choice. *)

let () =
  let readme = read_text (Filename.concat katas_dir "04-philosophical/README.md") in
  check (contains readme "Mode justification" || contains readme "mode justification")
    "kata-04: README contains 'Mode justification' section";
  check (contains readme "mechanical")
    "kata-04: README discusses mechanical mode";
  check (contains readme "hermetic" || contains readme "credentials")
    "kata-04: README justifies hermetic-by-default rationale";
  Printf.printf "kata-04 README OK (mode-justification claim verifiable)\n%!"

(* ------------------------------------------------------------------ *)
(* Test: kata-05 README documents the adversarial-design intent *)

let () =
  let readme = read_text (Filename.concat katas_dir "05-adversarial/README.md") in
  check (contains readme "adversarial" || contains readme "Adversarial")
    "kata-05: README documents the adversarial framing";
  check (contains readme "contradict")
    "kata-05: README documents the cross-file contradiction design";
  Printf.printf "kata-05 README OK\n%!"

(* ------------------------------------------------------------------ *)
(* Test: missing kata returns Error *)

let () =
  match Tsc_engine.Kata.load katas_dir "bogus-kata" with
  | Error _ -> pass "missing kata returns Error"
  | Ok k    -> fail (Printf.sprintf "expected Error for missing kata, got Ok id='%s'" k.Tsc_engine.Kata.id)
