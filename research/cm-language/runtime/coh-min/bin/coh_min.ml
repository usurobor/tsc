(* coh-min CLI — the minimal standalone CM runner.

   Usage:
     coh_min run --ir <ir.json> --target <subject-dir> [--out <path>]

   Loads the NormalizedCMIR, links the SandboxExecutionPlan, executes the finite
   provider DAG against the subject directory, and emits one MeasurementReceipt
   (canonical JSON) to stdout (and to --out if given). A short human summary goes
   to stderr; the machine artifact is on stdout.

   Exit codes:
     0  a receipt was computed
     1  the run failed closed (e.g. a denied path, a malformed IR) — NO receipt
     2  a usage error

   This is the M2 tracer for the portable runtime; it is NOT yet the production
   `coh cm run`. *)

module J = Coh_min.Json
module R = Coh_min.Runner

(* ux-cli: colour encodes semantics (red = error), a symbol always accompanies
   it (never colour-only), and NO_COLOR disables the escape codes. Terminal
   detection would need Unix.isatty, which the stdlib-only contract forbids, so
   NO_COLOR is the documented escape hatch. *)
let red s =
  if Sys.getenv_opt "NO_COLOR" <> None then s else "\027[31m" ^ s ^ "\027[0m"

let die_usage msg = prerr_endline msg; exit 2

let usage = "usage: coh_min run --ir <ir.json> --target <subject-dir> [--out <path>]"

(* Parse `run` flags into (ir_path, target_root, out) or a usage error. *)
let parse_run (argv : string array) : (string * string * string option, string) result =
  let rec loop i ir target out =
    if i >= Array.length argv then
      match ir, target with
      | Some ir, Some target -> Ok (ir, target, out)
      | None, _ -> Error "--ir <ir.json> is required"
      | _, None -> Error "--target <subject-dir> is required"
    else
      let need what =
        if i + 1 >= Array.length argv then Error (what ^ " needs a value") else Ok argv.(i + 1) in
      match argv.(i) with
      | "--ir" -> (match need "--ir" with Ok v -> loop (i + 2) (Some v) target out | Error e -> Error e)
      | "--target" -> (match need "--target" with Ok v -> loop (i + 2) ir (Some v) out | Error e -> Error e)
      | "--out" -> (match need "--out" with Ok v -> loop (i + 2) ir target (Some v) | Error e -> Error e)
      | other -> Error ("unknown argument " ^ other)
  in
  loop 2 None None None

let run_command (argv : string array) : unit =
  match parse_run argv with
  | Error e -> die_usage (usage ^ "\n" ^ e)
  | Ok (ir_path, target_root, out) ->
    match R.run { R.ir_path; target_root } with
    | Error msg ->
      (* fail-closed: no receipt is emitted. *)
      prerr_endline (red (Printf.sprintf "\xe2\x9c\x97 coh_min: %s" msg));
      exit 1
    | Ok receipt ->
      let doc = J.document receipt in
      print_string doc;
      (match out with
       | Some path ->
         let oc = open_out_bin path in
         Fun.protect ~finally:(fun () -> close_out oc) (fun () -> output_string oc doc);
         Printf.eprintf "receipt written to %s\n" path
       | None -> ());
      let result = J.member "result" receipt in
      let jbool k = match J.member_opt k result with Some (J.Bool x) -> x | _ -> false in
      Printf.eprintf "coh_min: cm=%s target=%s result_class=%s (computed=%b complete=%b)\n"
        (J.to_string (J.member "cm_id" receipt)) target_root
        (J.to_string (J.member "result_class" result))
        (jbool "computed") (jbool "complete");
      exit 0

let () =
  let argv = Sys.argv in
  if Array.length argv < 2 then die_usage usage
  else match argv.(1) with
    | "run" -> run_command argv
    | other -> die_usage (Printf.sprintf "unknown command %S\n%s" other usage)
