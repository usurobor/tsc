(** Report generation: validated result → machine + human reports.

    Pure module — returns report strings. Caller writes to disk.
    Uses Yojson.Safe for structured JSON output.

    v0.10.0 cutover: aggregate facts emitted only under [provenance]
    (canonical v3.2 shape); flat top-level [c_sigma] removed. Text
    reports render both canonical aggregate forms (C_Σ^math and
    C_Σ^num); no arithmetic-mean headline. *)

open Types

(** Build axis evidence as Yojson value. *)
let evidence_to_yojson ev =
  `Assoc [
    ("positive", `List (List.map (fun s -> `String s) ev.evidence_positive));
    ("negative", `List (List.map (fun s -> `String s) ev.evidence_negative));
    ("reason", `String ev.evidence_reason);
  ]

(** Build the canonical v3.2 provenance sub-object for an LLM/hybrid report.

    Routes the headline aggregate through [Coherence.aggregate]; passes a
    [c_sigma_fn] derived from the same helper to [Coherence.gauge_witness]
    so the W2 fields are computed against the canonical aggregate, never
    against an arithmetic surrogate.

    Accepts optional per-pair delta values when the LLM emits them;
    falls back to null fields when only component scores are available. *)
let provenance
    ?(delta_alpha_beta = None)
    ?(delta_beta_gamma = None)
    ?(delta_gamma_alpha = None)
    ~s_alpha ~s_beta ~s_gamma
    () =
  let lambda = 1.0 in
  let epsilon = Coherence.epsilon_default in
  let agg = Coherence.aggregate ~epsilon ~s_alpha ~s_beta ~s_gamma () in
  let l_ab = Option.map (fun _ -> Lipschitz.l_link lambda) delta_alpha_beta in
  let l_bg = Option.map (fun _ -> Lipschitz.l_link lambda) delta_beta_gamma in
  let l_ga = Option.map (fun _ -> Lipschitz.l_link lambda) delta_gamma_alpha in
  let c_sigma_fn sa sb sg =
    let r = Coherence.aggregate ~epsilon ~s_alpha:sa ~s_beta:sb ~s_gamma:sg () in
    r.c_sigma_math
  in
  let gw = Coherence.gauge_witness
    ~labeled:(s_alpha, s_beta, s_gamma)
    ~c_sigma_fn
    ~tau_gauge_spread:0.05
  in
  Coherence.provenance_json
    ~l_link_alpha_beta:l_ab
    ~l_link_beta_gamma:l_bg
    ~l_link_gamma_alpha:l_ga
    ~c_sigma_math:(Some agg.c_sigma_math)
    ~zero_component_present:agg.zero_component_present
    ~c_sigma_num:(Some agg.c_sigma_num)
    ~epsilon:(Some epsilon)
    ~numeric_floor_applied:agg.numeric_floor_applied
    ~w_gauge_ref:(Some gw.w_gauge_ref)
    ~w_gauge_spread:(Some gw.w_gauge_spread)
    ~tau_gauge_spread:(Some gw.tau_gauge_spread)
    ~canonical_remap_procedure:(Some gw.canonical_remap_procedure)
    ()

(** Generate machine-readable JSON report.

    Emits aggregate facts only under [provenance] (canonical v3.2 shape):
    no top-level [c_sigma], [c_sigma_math], [c_sigma_num], [epsilon],
    [zero_component_present], or [numeric_floor_applied]. *)
let to_json ~result ~metadata ?(mode = "llm")
    ?(delta_alpha_beta = None)
    ?(delta_beta_gamma = None)
    ?(delta_gamma_alpha = None)
    () =
  let prov = provenance
    ~delta_alpha_beta
    ~delta_beta_gamma
    ~delta_gamma_alpha
    ~s_alpha:result.result_alpha
    ~s_beta:result.result_beta
    ~s_gamma:result.result_gamma
    ()
  in
  let json =
    `Assoc [
      ("target", `String result.result_target);
      ("mode", `String mode);
      ("schema_version", `String "v3.2.0");
      ("alpha", `Float result.result_alpha);
      ("beta", `Float result.result_beta);
      ("gamma", `Float result.result_gamma);
      ("bottleneck_axis", `String result.result_bottleneck_axis);
      ("confidence", `Float result.result_confidence);
      ("summary", `String result.result_summary);
      ("axis_evidence", `Assoc [
        ("alpha", evidence_to_yojson result.result_alpha_evidence);
        ("beta", evidence_to_yojson result.result_beta_evidence);
        ("gamma", evidence_to_yojson result.result_gamma_evidence);
      ]);
      ("unresolved_ambiguity",
        `List (List.map (fun s -> `String s) result.result_unresolved_ambiguity));
      ("next_fixes",
        `List (List.map (fun f ->
          `Assoc [
            ("axis", `String f.fix_axis);
            ("fix", `String f.fix_description);
          ]
        ) result.result_next_fixes));
      ("provenance", prov);
      ("metadata", `Assoc [
        ("target", `String metadata.meta_target);
        ("file_hashes", `Assoc (List.map (fun (p, h) ->
          (p, `String h)) metadata.meta_file_hashes));
        ("prompt_version", `String metadata.meta_prompt_version);
        ("provider", `String metadata.meta_provider);
        ("model", `String metadata.meta_model);
        ("timestamp", `String metadata.meta_timestamp);
      ]);
    ]
  in
  Yojson.Safe.pretty_to_string json

(** Generate human-readable text report.

    v0.10.0 cutover: renders both canonical aggregate forms
    (C_Σ^math and C_Σ^num) from [Coherence.aggregate]; the v0.9.x
    arithmetic-mean line ("C_Σ = (α+β+γ)/3") has been removed. *)
let to_text ~result ~metadata ?(mode = "llm") () =
  let agg = Coherence.aggregate
    ~epsilon:Coherence.epsilon_default
    ~s_alpha:result.result_alpha
    ~s_beta:result.result_beta
    ~s_gamma:result.result_gamma
    ()
  in
  let evidence_text name ev =
    Printf.sprintf "  %s:\n    positive: %s\n    negative: %s\n    reason: %s"
      name
      (String.concat "; " ev.evidence_positive)
      (String.concat "; " ev.evidence_negative)
      ev.evidence_reason
  in
  Printf.sprintf
    "TSC Measurement Report\n\
     ======================\n\
     Mode: %s\n\
     Target: %s\n\
     \n\
     Scores:\n\
     \  α = %.3f\n\
     \  β = %.3f\n\
     \  γ = %.3f\n\
     \  C_Σ^math = %.3f\n\
     \  C_Σ^num  = %.3f\n\
     \n\
     Bottleneck: %s\n\
     Confidence: %.3f\n\
     \n\
     Summary: %s\n\
     \n\
     Evidence:\n\
     %s\n\
     %s\n\
     %s\n\
     \n\
     Unresolved ambiguity: %s\n\
     \n\
     Next fixes:\n\
     %s\n\
     \n\
     ---\n\
     Run metadata:\n\
     \  target: %s\n\
     \  prompt version: %s\n\
     \  provider: %s\n\
     \  model: %s\n\
     \  timestamp: %s\n\
     \  files: %d\n"
    mode
    result.result_target
    result.result_alpha
    result.result_beta
    result.result_gamma
    agg.c_sigma_math
    agg.c_sigma_num
    result.result_bottleneck_axis
    result.result_confidence
    result.result_summary
    (evidence_text "α" result.result_alpha_evidence)
    (evidence_text "β" result.result_beta_evidence)
    (evidence_text "γ" result.result_gamma_evidence)
    (String.concat "; " result.result_unresolved_ambiguity)
    (String.concat "\n" (List.map (fun f ->
       Printf.sprintf "  - [%s] %s" f.fix_axis f.fix_description
     ) result.result_next_fixes))
    metadata.meta_target
    metadata.meta_prompt_version
    metadata.meta_provider
    metadata.meta_model
    metadata.meta_timestamp
    (List.length metadata.meta_file_hashes)
