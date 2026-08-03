(* ascent0_runner — the Ascent-0 runtime CLI.

   Usage:
     ascent0_runner run <case> [--arm deterministic|blind] [--proposal <path>] [--out <path>]
     ascent0_runner blind-prompt <case>
     ascent0_runner firewall-selftest [<case>]

   `run` loads the NormalizedCMIR, resolves the RunRequest for <case>, links the
   SandboxExecutionPlan, executes the finite provider DAG, and emits one
   MeasurementReceipt (canonical JSON) to stdout (and to --out if given).

   The deterministic arm uses the canned #CompiledView per case; the blind arm
   ingests an externally-supplied proposal (--proposal), produced by a provider
   that saw ONLY the sanctioned one-POV input (`blind-prompt` prints that input).

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

let member_opt = Ascent0.Json.member_opt
let jint = function Some (Ascent0.Json.Int n) -> n | _ -> -1
let jstr = function Some (Ascent0.Json.Str s) -> s | _ -> "-"
let jbool = function Some (Ascent0.Json.Bool x) -> x | _ -> false

let () =
  let argv = Sys.argv in
  let fail msg = prerr_endline msg; exit 2 in
  if Array.length argv < 2 then
    fail "usage: ascent0_runner run <case> [--arm deterministic|blind] [--proposal <path>] [--out <path>]";
  match argv.(1) with
  | "run" ->
    if Array.length argv < 3 then fail "usage: ascent0_runner run <case> [--arm ...] [--proposal <path>] [--out <path>]";
    let case = argv.(2) in
    let out = ref None in
    let arm = ref Ascent0.Runtime.Deterministic in
    let proposal = ref None in
    let k = ref 3 in
    while !k < Array.length argv do
      (match argv.(!k) with
       | "--out" -> incr k;
         if !k >= Array.length argv then fail "--out needs a path";
         out := Some argv.(!k)
       | "--arm" -> incr k;
         if !k >= Array.length argv then fail "--arm needs a value";
         (match argv.(!k) with
          | "deterministic" -> arm := Ascent0.Runtime.Deterministic
          | "blind" -> arm := Ascent0.Runtime.Blind
          | other -> fail ("unknown arm " ^ other))
       | "--proposal" -> incr k;
         if !k >= Array.length argv then fail "--proposal needs a path";
         proposal := Some argv.(!k)
       | other -> fail ("unknown argument " ^ other));
      incr k
    done;
    let pd = project_dir () in
    let receipt =
      Ascent0.Runtime.run ~case ~project_dir:pd ~arm:!arm ~proposal_path:!proposal in
    let doc = Ascent0.Json.document receipt in
    print_string doc;
    (match !out with
     | Some path ->
       let oc = open_out_bin path in output_string oc doc; close_out oc;
       Printf.eprintf "receipt written to %s\n" path
     | None -> ());
    (* short human summary to stderr; the machine artifact is on stdout. *)
    let m key j = member_opt key j in
    let result = Ascent0.Json.member "result" receipt in
    let der = Ascent0.Json.member "derivation" receipt in
    let rr = Ascent0.Json.member "run_request" receipt in
    let oc = m "oracle" der in
    let oracle_line = match oc with
      | Some o ->
        Printf.sprintf
          "  oracle: revealed=%s commitment_verified=%b pass=%d fail=%d tested_fiber=%d\n"
          (jstr (m "revealed_output" o)) (jbool (m "commitment_verified" o))
          (jint (m "pass_count" o)) (jint (m "fail_count" o))
          (jint (m "tested_fiber_size" o))
      | None -> "  oracle: (not run for this case)\n" in
    Printf.eprintf
      "ascent0_runner: case=%s arm=%s result_class=%s (computed=%b)\n\
      \  admissible=%b search_ran=%b enumerated=%d fit=%d F_id=%d separating=%b\n%s"
      (jstr (m "case" rr)) (jstr (m "arm" rr))
      (jstr (m "result_class" result)) (jbool (m "computed" result))
      (jbool (m "admissible" result)) (jbool (m "search_ran" result))
      (jint (m "enumerated_class_size" der)) (jint (m "fit_candidate_count" der))
      (jint (m "identification_fiber_size" der)) (jbool (m "heldout_is_separating" der))
      oracle_line;
    exit 0
  | "blind-prompt" ->
    if Array.length argv < 3 then fail "usage: ascent0_runner blind-prompt <case>";
    let pd = project_dir () in
    print_endline (Ascent0.Runtime.blind_prompt ~case:argv.(2) ~project_dir:pd);
    exit 0
  | "firewall-selftest" ->
    let case = if Array.length argv >= 3 then argv.(2) else "case1" in
    let pd = project_dir () in
    let report = Ascent0.Runtime.firewall_probe ~case ~project_dir:pd in
    print_endline report;
    exit 0
  | other -> fail ("unknown command " ^ other)
