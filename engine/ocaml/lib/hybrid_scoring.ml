(** Hybrid scoring: combine mechanical and LLM results into a unified report.

    Pure module — no I/O. Receives both scored results and combines them
    into the canonical v3.2 hybrid report JSON shape.

    Cross-axis aggregation is the canonical v3.2 geometric mean (spec
    [spec/tsc-core.md] §5), reported as [c_sigma_math] (strict zero
    collapse) and [c_sigma_num] (ε-floored numeric form). No arithmetic
    mean. No flat [c_sigma] field. *)

open Types

type final_source = [ `Llm | `Mechanical | `Agreement ]

(** A canonical v3.2 aggregate triple for one backend or the final view. *)
type aggregate = {
  agg_c_sigma_math           : float;
  agg_c_sigma_num            : float;
  agg_epsilon                : float;
  agg_zero_component_present : bool;
  agg_numeric_floor_applied  : bool;
}

type result = {
  hyb_target       : string;
  hyb_mech         : Mechanical_scoring.result;
  hyb_llm          : measure_result;
  hyb_llm_agg      : aggregate;
  hyb_final_src    : final_source;
  hyb_final_alpha  : float;
  hyb_final_beta   : float;
  hyb_final_gamma  : float;
  hyb_final_agg    : aggregate;
}

let final_source_str = function
  | `Llm        -> "llm"
  | `Mechanical -> "mechanical"
  | `Agreement  -> "agreement"

let axis_name = function
  | `Alpha -> "alpha" | `Beta -> "beta" | `Gamma -> "gamma"

let bottleneck a b g =
  if a <= b && a <= g then "alpha"
  else if b <= g then "beta"
  else "gamma"

(** Canonical v3.2 aggregate over three component scores. *)
let aggregate_of ?(epsilon = 1e-5) ~s_alpha ~s_beta ~s_gamma () =
  let r = Coherence.aggregate ~epsilon ~s_alpha ~s_beta ~s_gamma () in
  { agg_c_sigma_math           = r.Coherence.c_sigma_math;
    agg_c_sigma_num            = r.Coherence.c_sigma_num;
    agg_epsilon                = r.Coherence.epsilon;
    agg_zero_component_present = r.Coherence.zero_component_present;
    agg_numeric_floor_applied  = r.Coherence.numeric_floor_applied }

(** Aggregate already attached to a mechanical result. *)
let aggregate_of_mech (m : Mechanical_scoring.result) =
  { agg_c_sigma_math           = m.c_sigma_math;
    agg_c_sigma_num            = m.c_sigma_num;
    agg_epsilon                = m.epsilon;
    agg_zero_component_present = m.zero_component_present;
    agg_numeric_floor_applied  = m.numeric_floor_applied }

(** Select final source: LLM is semantic authority; report agreement when
    both backends agree within threshold on every axis. *)
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
  let llm_agg =
    aggregate_of
      ~epsilon:mech.epsilon
      ~s_alpha:llm.result_alpha ~s_beta:llm.result_beta ~s_gamma:llm.result_gamma ()
  in
  let final_agg =
    aggregate_of ~epsilon:mech.epsilon ~s_alpha:fa ~s_beta:fb ~s_gamma:fg ()
  in
  { hyb_target      = target;
    hyb_mech        = mech;
    hyb_llm         = llm;
    hyb_llm_agg     = llm_agg;
    hyb_final_src   = src;
    hyb_final_alpha = fa;
    hyb_final_beta  = fb;
    hyb_final_gamma = fg;
    hyb_final_agg   = final_agg }

(** Canonical-aggregate JSON fields shared by every sub-object. *)
let aggregate_fields (a : aggregate) =
  [ ("c_sigma_math",           `Float a.agg_c_sigma_math);
    ("c_sigma_num",            `Float a.agg_c_sigma_num);
    ("zero_component_present", `Bool  a.agg_zero_component_present);
    ("numeric_floor_applied",  `Bool  a.agg_numeric_floor_applied) ]

let mech_subobj (m : Mechanical_scoring.result) =
  let a = aggregate_of_mech m in
  `Assoc ([
    ("alpha",           `Float m.alpha.score);
    ("beta",            `Float m.beta.score);
    ("gamma",           `Float m.gamma.score);
  ] @ aggregate_fields a @ [
    ("evidence_kind",   `String "structural-proxy");
    ("confidence",      `Float m.confidence);
    ("bottleneck_axis", `String (axis_name m.bottleneck_axis));
  ])

let llm_subobj (l : measure_result) (a : aggregate) =
  `Assoc ([
    ("alpha",           `Float l.result_alpha);
    ("beta",            `Float l.result_beta);
    ("gamma",           `Float l.result_gamma);
  ] @ aggregate_fields a @ [
    ("evidence_kind",   `String "semantic-judgment");
    ("confidence",      `Float l.result_confidence);
    ("bottleneck_axis", `String l.result_bottleneck_axis);
  ])

(** Canonical v3.2 provenance for the hybrid final adjudication. *)
let provenance_json (r : result) =
  let c_sigma_fn sa sb sg =
    let agg = Coherence.aggregate
      ~epsilon:r.hyb_final_agg.agg_epsilon
      ~s_alpha:sa ~s_beta:sb ~s_gamma:sg () in
    agg.Coherence.c_sigma_math
  in
  let gw = Coherence.gauge_witness
    ~labeled:(r.hyb_final_alpha, r.hyb_final_beta, r.hyb_final_gamma)
    ~c_sigma_fn
    ~tau_gauge_spread:0.05
  in
  Coherence.provenance_json
    ~c_sigma_math:(Some r.hyb_final_agg.agg_c_sigma_math)
    ~zero_component_present:r.hyb_final_agg.agg_zero_component_present
    ~c_sigma_num:(Some r.hyb_final_agg.agg_c_sigma_num)
    ~epsilon:(Some r.hyb_final_agg.agg_epsilon)
    ~numeric_floor_applied:r.hyb_final_agg.agg_numeric_floor_applied
    ~w_gauge_ref:(Some gw.w_gauge_ref)
    ~w_gauge_spread:(Some gw.w_gauge_spread)
    ~tau_gauge_spread:(Some gw.tau_gauge_spread)
    ~canonical_remap_procedure:(Some gw.canonical_remap_procedure)
    ()

let to_json (r : result) =
  let a = r.hyb_final_alpha and b = r.hyb_final_beta and g = r.hyb_final_gamma in
  `Assoc ([
    ("target",          `String r.hyb_target);
    ("mode",            `String "hybrid");
    ("schema_version",  `String "v3.2.0");
    ("alpha",           `Float a);
    ("beta",            `Float b);
    ("gamma",           `Float g);
  ] @ aggregate_fields r.hyb_final_agg @ [
    ("bottleneck_axis", `String (bottleneck a b g));
    ("mechanical",      mech_subobj r.hyb_mech);
    ("llm",             llm_subobj  r.hyb_llm r.hyb_llm_agg);
    ("final", `Assoc ([
      ("source",  `String (final_source_str r.hyb_final_src));
      ("alpha",   `Float a);
      ("beta",    `Float b);
      ("gamma",   `Float g);
    ] @ aggregate_fields r.hyb_final_agg));
    ("provenance", provenance_json r);
  ])
