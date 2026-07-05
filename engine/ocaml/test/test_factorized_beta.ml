(** Tests for Factorized_beta (cycle/74, rev-4 prereg AC1–AC10).

    Covered:
    - AC3 stable-locus-id regression: same bundle -> same inventory + ids.
    - AC1 exactly the three allowed kinds; deterministic canonical order.
    - AC5 unresolved loci scored d=1.0 with no LLM call.
    - AC6 aggregation exactly per the prereg formula, across
      supports/insufficient/contradicts/unresolved, plus the sparsity
      (E<5) and degenerate (N=0 -> β=1.0) rules.
    - AC4 response validation: exactly one response per resolved locus_id;
      missing / duplicate / extraneous / evidence-incomplete refuse.
    - AC7 (checkable half): the B3 typed-fixture gate over the committed
      controls file. *)

open Tsc_engine
module FB = Factorized_beta

let failures = ref 0

let fail msg =
  Printf.eprintf "FAIL: %s\n%!" msg;
  incr failures

let pass label = Printf.printf "PASS: %s\n%!" label

let check cond label = if cond then pass label else fail label

let approx a b = Float.abs (a -. b) < 1e-9

(* ------------------------------------------------------------------ *)
(* Bundle fixtures                                                    *)

let make_file ~path ~content : Types.bundle_file =
  { file_path = path;
    file_content = content;
    file_hash = "";
    file_size = String.length content;
    file_target_kind = Types.Theory }

let readme = make_file ~path:"README.md" ~content:(String.concat "\n" [
  "# Readme";
  "";
  "The composite is the geometric mean ([composite](spec/core.md#composite)).";
  "This document is the source of truth ([contract](spec/core.md)).";
  "See the [missing anchor](spec/core.md#nope).";
  "See the [diagram](spec/diagram.svg).";        (* resolves to existing non-.md file -> dropped *)
  "See the [broken](img/logo.png).";             (* resolves to nothing -> unresolved locus *)
  "See the [tree](spec).";                        (* resolves to a directory -> dropped *)
])

let core = make_file ~path:"spec/core.md" ~content:(String.concat "\n" [
  "# Core";
  "";
  "## Composite";
  "";
  "The composite metric.";
])

(* A real non-document (non-.md) bundle file: a link that resolves to it is
   excluded from enumeration; a broken link is not. *)
let diagram = make_file ~path:"spec/diagram.svg" ~content:"<svg></svg>"

(* Bundle-file order matches Bundle.build_bundle's path sort:
   "README.md" < "spec/core.md" < "spec/diagram.svg". *)
let sample_bundle = [ readme; core; diagram ]

(* ------------------------------------------------------------------ *)
(* AC3: stable locus ids + AC1 canonical order and allowed kinds       *)

let id_kind_status l =
  (l.FB.locus_id, FB.string_of_kind l.FB.kind, FB.string_of_status l.FB.mechanical_status)

let test_stable_locus_ids () =
  let inv1 = FB.inventory sample_bundle in
  let inv2 = FB.inventory sample_bundle in
  check (List.map id_kind_status inv1 = List.map id_kind_status inv2)
    "AC3: same bundle -> identical inventory + ids (idempotent)";
  (* The exact canonical sequence: bundle file order -> source line ->
     kind order (citation < authority < target_file_fit). *)
  let expected = [
    ("beta.fit.0001",  "target_file_fit",      "resolved");    (* README H1 *)
    ("beta.link.0002", "citation_bears_claim", "resolved");    (* #composite *)
    ("beta.link.0003", "citation_bears_claim", "resolved");    (* spec/core.md *)
    ("beta.auth.0004", "authority_claim",      "resolved");    (* source-of-truth *)
    ("beta.link.0005", "citation_bears_claim", "unresolved");  (* #nope broken anchor *)
    ("beta.link.0006", "citation_bears_claim", "unresolved");  (* img/logo.png broken path *)
    ("beta.fit.0007",  "target_file_fit",      "resolved");    (* core H1 *)
  ] in
  check (List.map id_kind_status inv1 = expected)
    "AC1/AC3: exact canonical order, ids, kinds, and statuses";
  (* AC1: only the three allowed kinds appear. *)
  let kinds = List.sort_uniq compare (List.map (fun l -> FB.string_of_kind l.FB.kind) inv1) in
  check (List.for_all (fun k ->
      List.mem k ["citation_bears_claim"; "authority_claim"; "target_file_fit"]) kinds)
    "AC1: no kind outside the allowed three"

let test_non_document_link_not_enumerated () =
  let inv = FB.inventory sample_bundle in
  let targets = List.map (fun l -> l.FB.target_path) inv in
  (* A link that RESOLVES TO an existing non-.md file (spec/diagram.svg) or a
     directory (spec) is not enumerated. *)
  check (not (List.mem "spec/diagram.svg" targets))
    "AC1: link resolving to an existing non-.md file is not enumerated";
  check (not (List.mem "spec" targets))
    "AC1: link resolving to a directory is not enumerated";
  (* A broken link (img/logo.png resolves to nothing) IS enumerated, as an
     unresolved locus. *)
  check (List.exists (fun l ->
      l.FB.target_path = "img/logo.png" && l.FB.mechanical_status = FB.Unresolved) inv)
    "AC5: a broken (non-resolving) link is enumerated as unresolved";
  check (List.length inv = 7) "inventory has the expected 7 loci"

let test_authority_needs_link () =
  (* A self-claim line with NO inline document link emits no authority locus. *)
  let f = make_file ~path:"README.md" ~content:(String.concat "\n" [
    "# Readme";
    "This document is canonical and owns the contract.";
  ]) in
  let inv = FB.inventory [ f ] in
  let auth = List.filter (fun l -> l.FB.kind = FB.Authority_claim) inv in
  check (auth = []) "authority self-claim without inline link emits no locus"

let test_unresolved_flags () =
  let inv = FB.inventory sample_bundle in
  let nope = List.find (fun l -> l.FB.locus_id = "beta.link.0005") inv in
  (* AC5: unresolved -> two-valued status unresolved, no LLM call (llm_called false) *)
  check (nope.FB.mechanical_status = FB.Unresolved)
    "AC5: broken-anchor link is Unresolved";
  let json = FB.locus_to_json ~target:"spec" nope in
  let llm_called =
    match json with
    | `Assoc kvs ->
      (match List.assoc_opt "llm_called" kvs with Some (`Bool b) -> b | _ -> true)
    | _ -> true
  in
  check (not llm_called) "AC5/AC2: unresolved locus serializes llm_called=false"

(* ------------------------------------------------------------------ *)
(* AC6: aggregation formula                                            *)

(* Build a resolved locus of a given kind. *)
let rloc id kind = {
  FB.locus_id = id; kind; source_path = "s"; source_span = "s";
  target_path = "t"; target_span = "t"; question = "q";
  mechanical_status = FB.Resolved }

let uloc id kind = { (rloc id kind) with FB.mechanical_status = FB.Unresolved }

let vmap pairs = fun (l : FB.locus) -> List.assoc l.FB.locus_id pairs

let test_aggregation_supports_contradicts () =
  let loci = [ rloc "a" FB.Citation_bears_claim; rloc "b" FB.Citation_bears_claim ] in
  let agg = FB.compute_beta loci
      ~verdict_of:(vmap [ ("a", FB.Supports); ("b", FB.Contradicts) ]) in
  (* w=1,1; d=0,1 -> 1 - 1/2 = 0.5 *)
  check (approx agg.FB.beta_factorized 0.5)
    "AC6: supports(0)+contradicts(1) over two citations -> β=0.5";
  check (agg.FB.n_loci = 2 && agg.FB.eligible_loci = 2)
    "AC6: N=2, E=2 counted"

let test_aggregation_insufficient () =
  let loci = [ rloc "a" FB.Citation_bears_claim ] in
  let agg = FB.compute_beta loci ~verdict_of:(vmap [ ("a", FB.Insufficient) ]) in
  check (approx agg.FB.beta_factorized 0.5)
    "AC6: a single insufficient citation -> d=0.5 -> β=0.5"

let test_aggregation_kind_weight () =
  (* target_file_fit contradicts (w=0.5,d=1) + citation supports (w=1,d=0)
     -> 1 - 0.5/1.5 = 0.6667 *)
  let loci = [ rloc "fit" FB.Target_file_fit; rloc "cite" FB.Citation_bears_claim ] in
  let agg = FB.compute_beta loci
      ~verdict_of:(vmap [ ("fit", FB.Contradicts); ("cite", FB.Supports) ]) in
  check (approx agg.FB.beta_factorized (1.0 -. (0.5 /. 1.5)))
    "AC6: kind weights applied (fit=0.5, citation=1.0)"

let test_aggregation_unresolved () =
  let loci = [ uloc "a" FB.Citation_bears_claim ] in
  let agg = FB.compute_beta loci ~verdict_of:(fun _ -> FB.Supports) in
  check (approx agg.FB.beta_factorized 0.0)
    "AC5/AC6: a lone unresolved locus -> d=1.0 -> β=0.0";
  check (agg.FB.eligible_loci = 0 && agg.FB.n_loci = 1)
    "AC6: unresolved locus counts in N but not E"

let test_sample_bundle_aggregation () =
  (* End-to-end on the enumerated bundle: 5 resolved (all supports) + 2
     unresolved. Weights: 2 fit@0.5 + 3 link + 1 auth + 2 unresolved link
     = 1.0 + 3.0 + 1.0 + 2.0 = 6.0; only the 2 unresolved score d=1.0 ->
     sum_wd = 2.0 -> β = 1 - 2/6 = 0.6667. *)
  let inv = FB.inventory sample_bundle in
  let agg = FB.compute_beta inv ~verdict_of:(fun _ -> FB.Supports) in
  check (approx agg.FB.sum_weight 6.0 && approx agg.FB.sum_weighted_defect 2.0)
    "AC6: enumerated bundle sum_w=6.0, sum_wd=2.0";
  check (approx agg.FB.beta_factorized (1.0 -. (2.0 /. 6.0)))
    "AC6: enumerated bundle all-supports -> β=1-2/6 (two unresolved defects)";
  check (agg.FB.eligible_loci = 5 && agg.FB.n_loci = 7)
    "AC6: enumerated bundle N=7, E=5"

let test_sparsity_rule () =
  let four = List.init 4 (fun i -> rloc (string_of_int i) FB.Citation_bears_claim) in
  let agg4 = FB.compute_beta four ~verdict_of:(fun _ -> FB.Supports) in
  check (agg4.FB.locus_sparse && agg4.FB.eligible_loci = 4)
    "AC6: E=4 (<5) -> locus_sparse";
  let five = List.init 5 (fun i -> rloc (string_of_int i) FB.Citation_bears_claim) in
  let agg5 = FB.compute_beta five ~verdict_of:(fun _ -> FB.Supports) in
  check ((not agg5.FB.locus_sparse) && agg5.FB.eligible_loci = 5)
    "AC6: E=5 -> not locus_sparse";
  (* sparsity is on the ELIGIBLE (resolved) count, not N: six unresolved
     loci are E=0 -> sparse, never a hollow seam pass. *)
  let six_u = List.init 6 (fun i -> uloc (string_of_int i) FB.Citation_bears_claim) in
  let aggu = FB.compute_beta six_u ~verdict_of:(fun _ -> FB.Supports) in
  check (aggu.FB.locus_sparse && aggu.FB.eligible_loci = 0 && aggu.FB.n_loci = 6)
    "AC6: all-unresolved bundle is E=0 -> sparse despite N=6"

let test_degenerate_empty () =
  let agg = FB.compute_beta [] ~verdict_of:(fun _ -> FB.Supports) in
  check (approx agg.FB.beta_factorized 1.0
         && agg.FB.n_loci = 0 && agg.FB.locus_sparse)
    "AC6: N=0 -> β=1.0 and locus_sparse"

(* ------------------------------------------------------------------ *)
(* AC4: response validation                                           *)

let vloci = [
  rloc "beta.link.0001" FB.Citation_bears_claim;
  rloc "beta.link.0002" FB.Citation_bears_claim;
  uloc "beta.link.0003" FB.Citation_bears_claim;
]

let resp ?(sides = []) id v = {
  FB.lr_locus_id = id; lr_verdict = v; lr_confidence = 0.5;
  lr_evidence_sides = sides; lr_evidence = ""; lr_rationale = "" }

let test_validate_happy () =
  let responses = [ resp "beta.link.0001" FB.Supports;
                    resp "beta.link.0002" FB.Supports ] in
  match FB.validate_sample ~loci:vloci ~responses with
  | Ok verdicts ->
    check (List.length verdicts = 2
           && List.assoc "beta.link.0001" verdicts = FB.Supports)
      "AC4: one response per resolved locus -> Ok verdict map"
  | Error rs ->
    fail ("AC4 happy path refused: "
          ^ String.concat "; " (List.map FB.refusal_to_string rs))

let test_validate_missing () =
  let responses = [ resp "beta.link.0001" FB.Supports ] in
  match FB.validate_sample ~loci:vloci ~responses with
  | Ok _ -> fail "AC4: missing resolved response accepted"
  | Error rs ->
    check (List.exists (function FB.Missing_response "beta.link.0002" -> true | _ -> false) rs)
      "AC4: missing resolved locus refuses the sample"

let test_validate_duplicate () =
  let responses = [ resp "beta.link.0001" FB.Supports;
                    resp "beta.link.0001" FB.Supports;
                    resp "beta.link.0002" FB.Supports ] in
  match FB.validate_sample ~loci:vloci ~responses with
  | Ok _ -> fail "AC4: duplicate response accepted"
  | Error rs ->
    check (List.exists (function FB.Duplicate_response "beta.link.0001" -> true | _ -> false) rs)
      "AC4: duplicate response refuses the sample"

let test_validate_extraneous () =
  (* A response for the unresolved locus (not LLM-eligible) is extraneous. *)
  let responses = [ resp "beta.link.0001" FB.Supports;
                    resp "beta.link.0002" FB.Supports;
                    resp "beta.link.0003" FB.Supports ] in
  match FB.validate_sample ~loci:vloci ~responses with
  | Ok _ -> fail "AC4: response for unresolved locus accepted"
  | Error rs ->
    check (List.exists (function FB.Extraneous_response "beta.link.0003" -> true | _ -> false) rs)
      "AC4: response for a non-eligible locus refuses the sample"

let test_validate_evidence_sides () =
  (* contradicts needs both source and target evidence. *)
  let bad = [ resp ~sides:["source"] "beta.link.0001" FB.Contradicts;
              resp "beta.link.0002" FB.Supports ] in
  (match FB.validate_sample ~loci:vloci ~responses:bad with
   | Ok _ -> fail "AC4: contradicts with one evidence side accepted"
   | Error rs ->
     check (List.exists (function FB.Incomplete_evidence "beta.link.0001" -> true | _ -> false) rs)
       "B3/AC4: contradicts needs both source and target evidence");
  let good = [ resp ~sides:["source"; "target"] "beta.link.0001" FB.Contradicts;
               resp "beta.link.0002" FB.Supports ] in
  (match FB.validate_sample ~loci:vloci ~responses:good with
   | Ok _ -> pass "B3/AC4: contradicts with both sides accepted"
   | Error rs ->
     fail ("contradicts-with-both-sides refused: "
           ^ String.concat "; " (List.map FB.refusal_to_string rs)))

let test_parse_locus_response () =
  let raw = {|[
    {"locus_id": "beta.link.0001", "verdict": "contradicts", "confidence": 0.9,
     "evidence": {"source": "src cite", "target": "tgt cite"},
     "rationale": "they disagree"}
  ]|} in
  match FB.parse_locus_responses (Yojson.Safe.from_string raw) with
  | Error e -> fail ("parse_locus_responses errored: " ^ e)
  | Ok [ r ] ->
    check (r.FB.lr_verdict = FB.Contradicts
           && List.mem "source" r.FB.lr_evidence_sides
           && List.mem "target" r.FB.lr_evidence_sides)
      "parse: verdict + evidence sides extracted from evidence object"
  | Ok _ -> fail "parse: expected exactly one response"

(* ------------------------------------------------------------------ *)
(* AC7: B3 typed-fixture gate over the committed controls              *)

let repo_root = lazy (
  let rec up d =
    if Sys.file_exists (Filename.concat d "targets/registry.tsc") then d
    else let p = Filename.dirname d in
      if p = d then failwith "repo root not found" else up p
  in
  up (Sys.getcwd ()))

let read_file path =
  let ic = open_in_bin path in
  Fun.protect ~finally:(fun () -> close_in ic) (fun () ->
    really_input_string ic (in_channel_length ic))

let test_b3_fixture_typed_gate () =
  let path = Filename.concat (Lazy.force repo_root)
      "docs/beta/governance/fixtures/factorized-beta-controls.json" in
  let json = Yojson.Safe.from_string (read_file path) in
  match FB.validate_controls json with
  | Ok n ->
    check (n = 8)
      (Printf.sprintf "AC7: committed B3 fixture is well-typed (%d controls)" n)
  | Error errs ->
    fail ("AC7: committed B3 fixture failed typed rules: "
          ^ String.concat "; " errs)

let test_b3_typed_rules_negative () =
  (* A contradicts control that fails to require both evidence sides must
     be caught by the typed rule. *)
  let bad = {
    FB.c_id = "x"; c_kind = "citation_bears_claim"; c_hard = true;
    c_llm_called = true; c_mechanical_status = "resolved";
    c_expected_verdict = "contradicts"; c_required_evidence_sides = ["source"] } in
  check (FB.typed_rule_errors bad <> [])
    "AC7: contradicts control missing an evidence side is rejected";
  (* An unresolved verdict with llm_called=true violates the iff/no-call rule. *)
  let bad2 = { bad with FB.c_expected_verdict = "unresolved";
                        c_mechanical_status = "resolved" } in
  check (FB.typed_rule_errors bad2 <> [])
    "AC7: unresolved verdict with resolved status is rejected";
  (* A clean control passes. *)
  let ok = { FB.c_id = "y"; c_kind = "target_file_fit"; c_hard = true;
             c_llm_called = true; c_mechanical_status = "resolved";
             c_expected_verdict = "supports"; c_required_evidence_sides = ["source"; "target"] } in
  check (FB.typed_rule_errors ok = []) "AC7: a well-typed control passes"

(* ------------------------------------------------------------------ *)

let () =
  test_stable_locus_ids ();
  test_non_document_link_not_enumerated ();
  test_authority_needs_link ();
  test_unresolved_flags ();
  test_aggregation_supports_contradicts ();
  test_aggregation_insufficient ();
  test_aggregation_kind_weight ();
  test_aggregation_unresolved ();
  test_sample_bundle_aggregation ();
  test_sparsity_rule ();
  test_degenerate_empty ();
  test_validate_happy ();
  test_validate_missing ();
  test_validate_duplicate ();
  test_validate_extraneous ();
  test_validate_evidence_sides ();
  test_parse_locus_response ();
  test_b3_fixture_typed_gate ();
  test_b3_typed_rules_negative ();
  if !failures > 0 then begin
    Printf.eprintf "\n%d factorized-β test(s) FAILED.\n%!" !failures;
    exit 1
  end;
  Printf.printf "All factorized-β tests passed.\n%!"
