(** OCaml tests for the kata framework — AC6 of tsc issue #33.

    Tests run via: cd engine/ocaml && opam exec -- dune runtest

    Covered:
    - kata-01 (glider) config loads correctly (id, verdict, score_range)
    - kata-02 (random-soup) config loads correctly (id, verdict, score_range)
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
    check (k.score_min >= 0.80 && k.score_min <= 0.92)
      (Printf.sprintf "kata-01: score_min = %.4f (expected in [0.80, 0.92])" k.score_min);
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
(* Test: missing kata returns Error *)

let () =
  match Tsc_engine.Kata.load katas_dir "bogus-kata" with
  | Error _ -> pass "missing kata returns Error"
  | Ok k    -> fail (Printf.sprintf "expected Error for missing kata, got Ok id='%s'" k.Tsc_engine.Kata.id)
