(* coh-min CLI — the minimal standalone CM runner.

   Usage:
     coh_min run --ir <ir.json> --target <subject-dir> [--out <path>]

   Loads the NormalizedCMIR, links the SandboxExecutionPlan, executes the finite
   provider DAG against the subject directory, and emits one MeasurementReceipt
   (canonical JSON) to stdout (and to --out if given). Exit 0 on a computed
   receipt; a short human summary goes to stderr. This is the M2 tracer for the
   portable runtime; it is NOT yet the production `coh cm run`. *)

module J = Coh_min.Json
module R = Coh_min.Runner

let () =
  let argv = Sys.argv in
  let fail msg = prerr_endline msg; exit 2 in
  if Array.length argv < 2 then
    fail "usage: coh_min run --ir <ir.json> --target <subject-dir> [--out <path>]";
  match argv.(1) with
  | "run" ->
    let ir = ref None and target = ref None and out = ref None in
    let k = ref 2 in
    while !k < Array.length argv do
      (match argv.(!k) with
       | "--ir" -> incr k;
         if !k >= Array.length argv then fail "--ir needs a path";
         ir := Some argv.(!k)
       | "--target" -> incr k;
         if !k >= Array.length argv then fail "--target needs a path";
         target := Some argv.(!k)
       | "--out" -> incr k;
         if !k >= Array.length argv then fail "--out needs a path";
         out := Some argv.(!k)
       | other -> fail ("unknown argument " ^ other));
      incr k
    done;
    let ir_path = match !ir with Some p -> p | None -> fail "--ir <ir.json> is required" in
    let target_root = match !target with Some p -> p | None -> fail "--target <subject-dir> is required" in
    let receipt = R.run { R.ir_path; target_root } in
    let doc = J.document receipt in
    print_string doc;
    (match !out with
     | Some path ->
       let oc = open_out_bin path in output_string oc doc; close_out oc;
       Printf.eprintf "receipt written to %s\n" path
     | None -> ());
    let result = J.member "result" receipt in
    Printf.eprintf "coh_min: cm=%s target=%s result_class=%s (computed=%b complete=%b)\n"
      (J.to_string (J.member "cm_id" receipt))
      target_root
      (J.to_string (J.member "result_class" result))
      (match J.member_opt "computed" result with Some (J.Bool x) -> x | _ -> false)
      (match J.member_opt "complete" result with Some (J.Bool x) -> x | _ -> false);
    exit 0
  | other -> fail ("unknown command " ^ other)
