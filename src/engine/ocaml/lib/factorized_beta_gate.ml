(** Factorized-β measurement gate (Sub-2 of #73, issue #75).

    Evaluates the FROZEN pre-registered A/B/C gate of
    research/self-measure/consistency-factorization/CONSISTENCY-FACTORIZATION-PREREG.md (rev 4) over
    the per-target factorized-β measurements the credentialed CI witness
    produces. Pure module — no I/O, no LLM call, no network.

    The cross-sample β consistency reuses {!Coherence.coherence_link} /
    {!Coherence.phi} (the one barrier source of truth); it is NOT
    re-implemented here. The inventory / adjudication / aggregation /
    validation are {!Factorized_beta}'s; this module only computes the gate
    arithmetic + the terminal verdict. The α/γ scalar path is untouched. *)

module FB = Factorized_beta

(* ------------------------------------------------------------------ *)
(* β cross-sample consistency (A1) — routed through the barrier        *)

(** Max absolute pairwise difference over the β_factorized values — the
    same max-pairwise spread [Witness_numeric.per_field_spread] computes
    per field, specialized to the single β field. *)
let beta_spread (betas : float list) : float =
  List.fold_left (fun acc a ->
    List.fold_left (fun acc b -> Float.max acc (Float.abs (a -. b))) acc betas)
    0.0 betas

(** Coh_consistency_max_pairwise over the β field: the canonical link
    [Coh = exp(-phi(spread))] via {!Coherence.coherence_link} (lambda=1).
    The barrier is NOT re-implemented (prereg: reuse Coherence.phi). *)
let beta_coh_consistency (betas : float list) : float =
  Coherence.coherence_link ~lambda:1.0 ~delta:(beta_spread betas)

(* ------------------------------------------------------------------ *)
(* A3 locus-level agreement                                            *)

(** Mean over all unordered sample pairs and eligible loci of
    verdict-equality (prereg §A3). *)
let locus_agreement ~(eligible_ids : string list)
    ~(samples : (string * FB.verdict) list list) : float =
  let agree = ref 0 and total = ref 0 in
  let rec pairs = function
    | [] | [ _ ] -> ()
    | s1 :: rest ->
      List.iter (fun s2 ->
        List.iter (fun id ->
          match List.assoc_opt id s1, List.assoc_opt id s2 with
          | Some v1, Some v2 ->
            incr total; if v1 = v2 then incr agree
          | _ -> ()   (* a validated sample answers every eligible id;
                         skip defensively otherwise *)
        ) eligible_ids) rest;
      pairs rest
  in
  pairs samples;
  if !total = 0 then 1.0 else float_of_int !agree /. float_of_int !total

(* ------------------------------------------------------------------ *)
(* Per-target measurement record + JSON                                *)

type target_measure = {
  tm_target            : string;
  tm_beta_loci         : int;
  tm_eligible_loci     : int;
  tm_locus_sparse      : bool;
  tm_declared_samples  : int;
  tm_validated_samples : int;
  tm_refused_samples   : int;
  tm_sample_betas      : float list;
  tm_beta_coh          : float;
  tm_agreement         : float;
  tm_baseline_beta_coh : float;
  tm_baseline_present  : bool;
}

let target_measure_to_json t =
  `Assoc [
    ("kind",              `String "factorized_beta_target_measure");
    ("target",            `String t.tm_target);
    ("beta_loci",         `Int t.tm_beta_loci);
    ("eligible_loci",     `Int t.tm_eligible_loci);
    ("locus_sparse",      `Bool t.tm_locus_sparse);
    ("a0_applicable",     `Bool (t.tm_eligible_loci > 0));
    ("declared_samples",  `Int t.tm_declared_samples);
    ("validated_samples", `Int t.tm_validated_samples);
    ("refused_samples",   `Int t.tm_refused_samples);
    ("sample_betas",      `List (List.map (fun b -> `Float b) t.tm_sample_betas));
    ("beta_coh_consistency_max_pairwise", `Float t.tm_beta_coh);
    ("locus_agreement",   `Float t.tm_agreement);
    ("baseline_beta_coh", `Float t.tm_baseline_beta_coh);
    ("baseline_present",  `Bool t.tm_baseline_present);
  ]

let get k = function `Assoc l -> List.assoc_opt k l | _ -> None
let fbool k j = match get k j with Some (`Bool b) -> b | _ -> false
let fint k j = match get k j with Some (`Int i) -> i | _ -> 0
let ffloat k j =
  match get k j with
  | Some (`Float f) -> f
  | Some (`Int i) -> float_of_int i
  | _ -> 0.0
let fstr k j = match get k j with Some (`String s) -> s | _ -> ""
let ffloatlist k j =
  match get k j with
  | Some (`List xs) ->
    List.filter_map (function
      | `Float f -> Some f
      | `Int i -> Some (float_of_int i)
      | _ -> None) xs
  | _ -> []

let target_measure_of_json j : (target_measure, string) result =
  match get "target" j with
  | Some (`String tgt) ->
    Ok { tm_target = tgt;
         tm_beta_loci = fint "beta_loci" j;
         tm_eligible_loci = fint "eligible_loci" j;
         tm_locus_sparse = fbool "locus_sparse" j;
         tm_declared_samples = fint "declared_samples" j;
         tm_validated_samples = fint "validated_samples" j;
         tm_refused_samples = fint "refused_samples" j;
         tm_sample_betas = ffloatlist "sample_betas" j;
         tm_beta_coh = ffloat "beta_coh_consistency_max_pairwise" j;
         tm_agreement = ffloat "locus_agreement" j;
         tm_baseline_beta_coh = ffloat "baseline_beta_coh" j;
         tm_baseline_present = fbool "baseline_present" j }
  | _ -> Error "target measure JSON missing 'target'"

(* ------------------------------------------------------------------ *)
(* Gate evaluation                                                     *)

type verdict_token = Pass | Fail | No_decision

let string_of_verdict_token = function
  | Pass -> "PASS"
  | Fail -> "FAIL"
  | No_decision -> "NO-DECISION"

let default_a1_floor = 0.90
let default_a2_margin = 0.10
let default_a3_floor = 0.90

type gate_input = {
  gi_targets          : target_measure list;
  gi_kata_b1          : bool;
  gi_admissibility_b2 : bool;
  gi_b3               : bool;
  gi_a1_floor         : float;
  gi_a2_margin        : float;
  gi_a3_floor         : float;
  gi_declared         : int;
}

type check = { chk_id : string; chk_passed : bool; chk_detail : string }

type gate_result = {
  gr_verdict      : verdict_token;
  gr_checks       : check list;
  gr_sparse_count : int;
  gr_scored       : string list;
}

let names ts = String.concat ", " (List.map (fun t -> t.tm_target) ts)

let evaluate_gate (gi : gate_input) : gate_result =
  let targets = gi.gi_targets in
  let sparse = List.filter (fun t -> t.tm_locus_sparse) targets in
  let sparse_count = List.length sparse in
  (* Scored = non-sparse held-out targets (A1/A2/A3 apply). *)
  let scored = List.filter (fun t -> not t.tm_locus_sparse) targets in
  (* A0 applies where E>0 (both 0<E<5 and E>=5); E=0 -> not applicable. *)
  let a0_targets = List.filter (fun t -> t.tm_eligible_loci > 0) targets in
  let a0_fail =
    List.filter (fun t ->
      not (t.tm_declared_samples = gi.gi_declared
           && t.tm_validated_samples = gi.gi_declared)) a0_targets
  in
  let a1_fail = List.filter (fun t -> t.tm_beta_coh < gi.gi_a1_floor) scored in
  (* A2 needs a recorded free-witness baseline; absent baseline cannot
     prove improvement -> miss (conservative). *)
  let a2_fail =
    List.filter (fun t ->
      not (t.tm_baseline_present
           && t.tm_beta_coh >= t.tm_baseline_beta_coh +. gi.gi_a2_margin)) scored
  in
  let a3_fail = List.filter (fun t -> t.tm_agreement < gi.gi_a3_floor) scored in
  let checks = [
    { chk_id = "A0"; chk_passed = (a0_fail = []);
      chk_detail =
        (if a0_fail = [] then
           Printf.sprintf "yield %d/%d on all %d applicable target(s)"
             gi.gi_declared gi.gi_declared (List.length a0_targets)
         else "yield below declared on: " ^ names a0_fail) };
    { chk_id = "A1"; chk_passed = (a1_fail = []);
      chk_detail =
        (if a1_fail = [] then
           Printf.sprintf "β Coh_consistency >= %.2f on all %d scored"
             gi.gi_a1_floor (List.length scored)
         else Printf.sprintf "below %.2f on: %s" gi.gi_a1_floor (names a1_fail)) };
    { chk_id = "A2"; chk_passed = (a2_fail = []);
      chk_detail =
        (if a2_fail = [] then
           Printf.sprintf ">= free-witness baseline + %.2f on all %d scored"
             gi.gi_a2_margin (List.length scored)
         else Printf.sprintf "below baseline + %.2f (or baseline absent) on: %s"
             gi.gi_a2_margin (names a2_fail)) };
    { chk_id = "A3"; chk_passed = (a3_fail = []);
      chk_detail =
        (if a3_fail = [] then
           Printf.sprintf "locus-verdict agreement >= %.2f on all %d scored"
             gi.gi_a3_floor (List.length scored)
         else Printf.sprintf "below %.2f on: %s" gi.gi_a3_floor (names a3_fail)) };
    { chk_id = "B1"; chk_passed = gi.gi_kata_b1;
      chk_detail = "kata-01 pass / kata-02 fail (discrimination non-regression)" };
    { chk_id = "B2"; chk_passed = gi.gi_admissibility_b2;
      chk_detail = "cm-admissibility --self-test verdict matrix unchanged" };
    { chk_id = "B3"; chk_passed = gi.gi_b3;
      chk_detail = "β local semantic controls (typed rules + label agreement)" };
  ] in
  let all_ab_pass = List.for_all (fun c -> c.chk_passed) checks in
  let verdict =
    if sparse_count > 1 then No_decision           (* C4 NO-DECISION guard *)
    else if all_ab_pass then Pass
    else Fail                                       (* C5 any A/B miss *)
  in
  { gr_verdict = verdict;
    gr_checks = checks;
    gr_sparse_count = sparse_count;
    gr_scored = List.map (fun t -> t.tm_target) scored }

let gate_result_to_json gr =
  `Assoc [
    ("kind",               `String "factorized_beta_gate_summary");
    ("verdict",            `String (string_of_verdict_token gr.gr_verdict));
    ("locus_sparse_count", `Int gr.gr_sparse_count);
    ("scored_targets",     `List (List.map (fun s -> `String s) gr.gr_scored));
    ("checks",
     `List (List.map (fun c ->
       `Assoc [ ("id",     `String c.chk_id);
                ("passed", `Bool c.chk_passed);
                ("detail", `String c.chk_detail) ]) gr.gr_checks));
    ("prereg",
     `String "research/self-measure/consistency-factorization/CONSISTENCY-FACTORIZATION-PREREG.md rev 4");
    ("note",
     `String "C4: >1 held-out locus_sparse -> NO-DECISION; C5: any A/B miss -> FAIL.");
  ]

(* ------------------------------------------------------------------ *)
(* B3 discrimination controls — witness label agreement                *)

type control_full = {
  cf_id          : string;
  cf_kind        : FB.kind;
  cf_llm_called  : bool;
  cf_source_path : string;
  cf_target_path : string;
  cf_source_text : string;
  cf_target_text : string;
  cf_expected    : string;
}

let parse_controls_full json : (control_full list, string) result =
  match get "controls" json with
  | Some (`List items) ->
    let rec go acc = function
      | [] -> Ok (List.rev acc)
      | o :: rest ->
        let kind_s = fstr "kind" o in
        (match FB.kind_of_string kind_s with
         | None ->
           Error (Printf.sprintf "control '%s' has unknown kind '%s'"
                    (fstr "id" o) kind_s)
         | Some k ->
           go ({ cf_id = fstr "id" o; cf_kind = k;
                 cf_llm_called = fbool "llm_called" o;
                 cf_source_path = fstr "source_path" o;
                 cf_target_path = fstr "target_path" o;
                 cf_source_text = fstr "source_text" o;
                 cf_target_text = fstr "target_text" o;
                 cf_expected = fstr "expected_verdict" o } :: acc) rest)
    in
    go [] items
  | _ -> Error "fixture missing 'controls' array"

(** A control as a synthetic RESOLVED locus: the inline source/target text
    is the span the witness adjudicates. *)
let control_to_locus (c : control_full) : FB.locus =
  { FB.locus_id = c.cf_id;
    kind = c.cf_kind;
    source_path = c.cf_source_path;
    source_span = c.cf_source_text;
    target_path = c.cf_target_path;
    target_span = c.cf_target_text;
    question = FB.question_for c.cf_kind;
    mechanical_status = FB.Resolved }

let controls_prompt json : (string, string) result =
  match parse_controls_full json with
  | Error e -> Error e
  | Ok controls ->
    let loci =
      List.filter_map (fun c ->
        if c.cf_llm_called then Some (control_to_locus c) else None) controls
    in
    Ok (FB.adjudication_instruction loci)

type b3_result = {
  b3_passed        : bool;
  b3_total         : int;
  b3_agreements    : int;
  b3_mismatches    : (string * string * string) list;
  b3_evidence_fail : string list;
  b3_typed_ok      : bool;
  b3_typed_errors  : string list;
}

let controls_check ~fixtures_json ~responses_json : (b3_result, string) result =
  (* Typed-fixture half first — reuse the frozen engine gate. *)
  let typed_ok, typed_errs =
    match FB.validate_controls fixtures_json with
    | Ok _ -> (true, [])
    | Error errs -> (false, errs)
  in
  match parse_controls_full fixtures_json with
  | Error e -> Error e
  | Ok controls ->
    (match FB.parse_locus_responses responses_json with
     | Error e -> Error ("witness controls response unparseable: " ^ e)
     | Ok responses ->
       let by_id id =
         List.find_opt (fun (r : FB.locus_response) ->
           r.FB.lr_locus_id = id) responses
       in
       let called = List.filter (fun c -> c.cf_llm_called) controls in
       let agreements = ref 0 in
       let mismatches = ref [] in
       let evidence_fail = ref [] in
       List.iter (fun c ->
         match by_id c.cf_id with
         | None ->
           mismatches := (c.cf_id, c.cf_expected, "<missing>") :: !mismatches
         | Some r ->
           let got = FB.string_of_verdict r.FB.lr_verdict in
           if got = c.cf_expected then incr agreements
           else mismatches := (c.cf_id, c.cf_expected, got) :: !mismatches;
           (* Every negative verdict must cite both source and target. *)
           if c.cf_expected = "contradicts" || r.FB.lr_verdict = FB.Contradicts then
             if not (List.mem "source" r.FB.lr_evidence_sides
                     && List.mem "target" r.FB.lr_evidence_sides) then
               evidence_fail := c.cf_id :: !evidence_fail
       ) called;
       let total = List.length called in
       let label_ok =
         if total < 20 then !agreements = total
         else float_of_int !agreements /. float_of_int (max 1 total) >= 0.95
       in
       let passed = typed_ok && label_ok && !evidence_fail = [] in
       Ok { b3_passed = passed;
            b3_total = total;
            b3_agreements = !agreements;
            b3_mismatches = List.rev !mismatches;
            b3_evidence_fail = List.rev !evidence_fail;
            b3_typed_ok = typed_ok;
            b3_typed_errors = typed_errs })

let b3_result_to_json b =
  `Assoc [
    ("kind",              `String "factorized_beta_b3_controls");
    ("b3_passed",         `Bool b.b3_passed);
    ("controls_called",   `Int b.b3_total);
    ("label_agreements",  `Int b.b3_agreements);
    ("typed_gate_passed", `Bool b.b3_typed_ok);
    ("typed_errors",      `List (List.map (fun e -> `String e) b.b3_typed_errors));
    ("label_mismatches",
     `List (List.map (fun (id, exp, got) ->
       `Assoc [ ("id", `String id);
                ("expected", `String exp);
                ("got", `String got) ]) b.b3_mismatches));
    ("evidence_side_failures",
     `List (List.map (fun s -> `String s) b.b3_evidence_fail));
  ]
