(* ascent0_runner — the Ascent-0 Sub-3 runtime CLI.

   Usage:
     ascent0_runner run <case> [--out <path>]

   Loads the NormalizedCMIR, resolves the RunRequest for <case>, links the
   SandboxExecutionPlan, executes the finite provider DAG, and emits one
   MeasurementReceipt (canonical JSON) to stdout (and to --out if given).

   This is NOT `coh cm run`, and the linked artifact is a SandboxExecutionPlan,
   NOT a normative CompiledCM. *)

let rec find_up dir rel =
  let cand = Filename.concat dir rel in
  if Sys.file_exists cand then Some (Filename.dirname (Filename.dirname cand))
  else
    let parent = Filename.dirname dir in
    if parent = dir then None else find_up parent rel

let project_dir () =
  match Sys.getenv_opt "ASCENT0_PROJECT_DIR" with
  | Some p -> p
  | None ->
    (match find_up (Sys.getcwd ())
             "research/cm-language/runtime/ascent-0/ir/ascent0.ir.json" with
     | Some p -> p
     | None -> failwith
         "could not locate the ascent-0 runtime project (set ASCENT0_PROJECT_DIR)")

let () =
  let argv = Sys.argv in
  let fail msg = prerr_endline msg; exit 2 in
  if Array.length argv < 2 then fail "usage: ascent0_runner run <case> [--out <path>]";
  match argv.(1) with
  | "run" ->
    if Array.length argv < 3 then fail "usage: ascent0_runner run <case> [--out <path>]";
    let case = argv.(2) in
    let out = ref None in
    let k = ref 3 in
    while !k < Array.length argv do
      (match argv.(!k) with
       | "--out" -> incr k;
         if !k >= Array.length argv then fail "--out needs a path";
         out := Some argv.(!k)
       | other -> fail ("unknown argument " ^ other));
      incr k
    done;
    let pd = project_dir () in
    let receipt = Ascent0.Runtime.run ~case ~project_dir:pd in
    let doc = Ascent0.Json.document receipt in
    print_string doc;
    (match !out with
     | Some path ->
       let oc = open_out_bin path in output_string oc doc; close_out oc;
       Printf.eprintf "receipt written to %s\n" path
     | None -> ());
    (* short human summary to stderr; the machine artifact is on stdout. *)
    let m key j = Ascent0.Json.member key j in
    let result = m "result" receipt in
    let der = m "derivation" receipt in
    let oc = m "oracle" der in
    Printf.eprintf
      "ascent0_runner: case=%s result_class=%s (computed=%b)\n\
      \  enumerated=%d  fit=%d  F_id=%d  separating=%b\n\
      \  oracle: revealed=%s commitment_verified=%b pass=%d fail=%d tested_fiber=%d\n"
      (Ascent0.Json.to_string (m "case" (m "run_request" receipt)))
      (Ascent0.Json.to_string (m "result_class" result))
      true
      (Ascent0.Json.to_int (m "enumerated_class_size" der))
      (Ascent0.Json.to_int (m "fit_candidate_count" der))
      (Ascent0.Json.to_int (m "identification_fiber_size" der))
      (match m "heldout_is_separating" der with Ascent0.Json.Bool x -> x | _ -> false)
      (Ascent0.Json.to_string (m "revealed_output" oc))
      (match m "commitment_verified" oc with Ascent0.Json.Bool x -> x | _ -> false)
      (Ascent0.Json.to_int (m "pass_count" oc))
      (Ascent0.Json.to_int (m "fail_count" oc))
      (Ascent0.Json.to_int (m "tested_fiber_size" oc));
    exit 0
  | "firewall-selftest" ->
    let case = if Array.length argv >= 3 then argv.(2) else "case1" in
    let pd = project_dir () in
    let report = Ascent0.Runtime.firewall_probe ~case ~project_dir:pd in
    print_endline report;
    exit 0
  | other -> fail ("unknown command " ^ other)
