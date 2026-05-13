(** Hybrid scoring: combine mechanical and LLM results into a unified report.

    Pure module — no I/O. Receives both scored results and combines them
    into the canonical hybrid report JSON shape.

    v0.10.0 cutover: cross-axis aggregate facts come from
    [Coherence.aggregate] (canonical v3.2 geometric forms), not arithmetic
    mean. Public JSON carries no flat [c_sigma]; aggregate facts live only
    under the [provenance] sub-object. *)

open Types

type final_source = [ `Llm | `Mechanical | `Agreement ]

(** Canonical aggregate epsilon — must match [Mechanical_scoring] and
    [Report.provenance_v320]. *)
let aggregate_epsilon = 1e-5

type result = {
  hyb_target    : string;
  hyb_mech      : Mechanical_scoring.result;
  hyb_llm       : measure_result;
  hyb_final_src : final_source;
  hyb_final_alpha     : float;
  hyb_final_beta      : float;
  hyb_final_gamma     : float;
  hyb_final_aggregate : Mechanical_scoring.aggregate;
}

let final_source_str = function
  | `Llm       -> "llm"
  | `Mechanical -> "mechanical"
  | `Agreement  -> "agreement"

let axis_name = function
  | `Alpha -> "alpha" | `Beta -> "beta" | `Gamma -> "gamma"

let bottleneck a b g =
  if a <= b && a <= g then "alpha"
  else if b <= g then "beta"
  else "gamma"

(** Compute the canonical v3.2 aggregate over a triple of axis scores.
    Routes through [Coherence.aggregate]; never computes an arithmetic mean. *)
let aggregate_of_triple sa sb sg : Mechanical_scoring.aggregate =
  let r = Coherence.aggregate
    ~epsilon:aggregate_epsilon
    ~s_alpha:sa ~s_beta:sb ~s_gamma:sg ()
  in
  { c_sigma_math           = r.c_sigma_math;
    c_sigma_num            = r.c_sigma_num;
    epsilon                = r.epsilon;
    zero_component_present = r.zero_component_present;
    numeric_floor_applied  = r.numeric_floor_applied }

(** Build the canonical v3.2 provenance JSON for a hybrid (or LLM-only)
    aggregate over a labeled triple. Routes through [Coherence.aggregate]
    and [Coherence.gauge_witness] with a canonical [c_sigma_fn]. *)
let provenance_for_triple ~labeled (agg : Mechanical_scoring.aggregate) =
  let c_sigma_fn sa sb sg =
    let r = Coherence.aggregate
      ~epsilon:agg.epsilon
      ~s_alpha:sa ~s_beta:sb ~s_gamma:sg ()
    in
    r.c_sigma_math
  in
  let gw = Coherence.gauge_witness
    ~labeled
    ~c_sigma_fn
    ~tau_gauge_spread:0.05
  in
  Coherence.provenance_json
    ~c_sigma_math:(Some agg.c_sigma_math)
    ~zero_component_present:agg.zero_component_present
    ~c_sigma_num:(Some agg.c_sigma_num)
    ~epsilon:(Some agg.epsilon)
    ~numeric_floor_applied:agg.numeric_floor_applied
    ~w_gauge_ref:(Some gw.w_gauge_ref)
    ~w_gauge_spread:(Some gw.w_gauge_spread)
    ~tau_gauge_spread:(Some gw.tau_gauge_spread)
    ~canonical_remap_procedure:(Some gw.canonical_remap_procedure)
    ()

(** Select final source: LLM is semantic authority; report agreement when
    both backends agree within threshold (per-axis). *)
let select_final (mech : Mechanical_scoring.result) (llm : measure_result) =
  let threshold = 0.1 in
  let agree =
    abs_float (mech.alpha.score -. llm.result_alpha) < threshold &&
    abs_float (mech.beta.score  -. llm.result_beta)  < threshold &&
    abs_float (mech.gamma.score -. llm.result_gamma) < threshold
  in
  if agree then `Agreement else `Llm

let combine ~target (mech : Mechanical_scoring.result) (llm : measure_result) =
  let src = select_final mech llm in
  let fa, fb, fg = match src with
    | `Llm | `Agreement ->
      llm.result_alpha, llm.result_beta, llm.result_gamma
    | `Mechanical ->
      mech.alpha.score, mech.beta.score, mech.gamma.score
  in
  { hyb_target          = target;
    hyb_mech            = mech;
    hyb_llm             = llm;
    hyb_final_src       = src;
    hyb_final_alpha     = fa;
    hyb_final_beta      = fb;
    hyb_final_gamma     = fg;
    hyb_final_aggregate = aggregate_of_triple fa fb fg }

(** Mechanical sub-object — axis scores + provenance for the mechanical
    aggregate. No flat [c_sigma] at any level. *)
let mech_subobj (m : Mechanical_scoring.result) =
  `Assoc [
    ("alpha",           `Float m.alpha.score);
    ("beta",            `Float m.beta.score);
    ("gamma",           `Float m.gamma.score);
    ("evidence_kind",   `String "structural-proxy");
    ("confidence",      `Float m.confidence);
    ("bottleneck_axis", `String (axis_name m.bottleneck_axis));
    ("provenance",
      provenance_for_triple
        ~labeled:(m.alpha.score, m.beta.score, m.gamma.score)
        m.aggregate);
  ]

(** LLM sub-object — axis scores + provenance for the LLM aggregate. *)
let llm_subobj (l : measure_result) =
  let agg = aggregate_of_triple l.result_alpha l.result_beta l.result_gamma in
  `Assoc [
    ("alpha",           `Float l.result_alpha);
    ("beta",            `Float l.result_beta);
    ("gamma",           `Float l.result_gamma);
    ("evidence_kind",   `String "semantic-judgment");
    ("confidence",      `Float l.result_confidence);
    ("bottleneck_axis", `String l.result_bottleneck_axis);
    ("provenance",
      provenance_for_triple
        ~labeled:(l.result_alpha, l.result_beta, l.result_gamma)
        agg);
  ]

let to_json (r : result) =
  let a = r.hyb_final_alpha and b = r.hyb_final_beta and g = r.hyb_final_gamma in
  `Assoc [
    ("target",          `String r.hyb_target);
    ("mode",            `String "hybrid");
    ("alpha",           `Float a);
    ("beta",            `Float b);
    ("gamma",           `Float g);
    ("bottleneck_axis", `String (bottleneck a b g));
    ("mechanical",      mech_subobj r.hyb_mech);
    ("llm",             llm_subobj  r.hyb_llm);
    ("final", `Assoc [
      ("source",       `String (final_source_str r.hyb_final_src));
      ("alpha",        `Float a);
      ("beta",         `Float b);
      ("gamma",        `Float g);
    ]);
    ("provenance",
      provenance_for_triple ~labeled:(a, b, g) r.hyb_final_aggregate);
  ]
