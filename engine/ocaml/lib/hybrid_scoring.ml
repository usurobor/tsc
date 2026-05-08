(** Hybrid scoring: combine mechanical and LLM results into a unified report.

    Pure module — no I/O. Receives both scored results and combines them
    into the canonical hybrid report JSON shape defined in DESIGN.md. *)

open Types

type final_source = [ `Llm | `Mechanical | `Agreement ]

type result = {
  hyb_target    : string;
  hyb_mech      : Mechanical_scoring.result;
  hyb_llm       : measure_result;
  hyb_final_src : final_source;
  hyb_final_alpha  : float;
  hyb_final_beta   : float;
  hyb_final_gamma  : float;
  hyb_final_csigma : float;
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

(** Select final source: LLM is semantic authority; report agreement when
    both backends agree within threshold. *)
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
  { hyb_target       = target;
    hyb_mech         = mech;
    hyb_llm          = llm;
    hyb_final_src    = src;
    hyb_final_alpha  = fa;
    hyb_final_beta   = fb;
    hyb_final_gamma  = fg;
    hyb_final_csigma = (fa +. fb +. fg) /. 3.0 }

let mech_subobj (m : Mechanical_scoring.result) =
  `Assoc [
    ("alpha",           `Float m.alpha.score);
    ("beta",            `Float m.beta.score);
    ("gamma",           `Float m.gamma.score);
    ("c_sigma",         `Float m.c_sigma);
    ("evidence_kind",   `String "structural-proxy");
    ("confidence",      `Float m.confidence);
    ("bottleneck_axis", `String (axis_name m.bottleneck_axis));
  ]

let llm_subobj (l : measure_result) =
  let cs = (l.result_alpha +. l.result_beta +. l.result_gamma) /. 3.0 in
  `Assoc [
    ("alpha",           `Float l.result_alpha);
    ("beta",            `Float l.result_beta);
    ("gamma",           `Float l.result_gamma);
    ("c_sigma",         `Float cs);
    ("evidence_kind",   `String "semantic-judgment");
    ("confidence",      `Float l.result_confidence);
    ("bottleneck_axis", `String l.result_bottleneck_axis);
  ]

let to_json (r : result) =
  let a = r.hyb_final_alpha and b = r.hyb_final_beta and g = r.hyb_final_gamma in
  `Assoc [
    ("target",          `String r.hyb_target);
    ("mode",            `String "hybrid");
    ("alpha",           `Float a);
    ("beta",            `Float b);
    ("gamma",           `Float g);
    ("c_sigma",         `Float r.hyb_final_csigma);
    ("bottleneck_axis", `String (bottleneck a b g));
    ("mechanical",      mech_subobj r.hyb_mech);
    ("llm",             llm_subobj  r.hyb_llm);
    ("final", `Assoc [
      ("source",  `String (final_source_str r.hyb_final_src));
      ("alpha",   `Float a);
      ("beta",    `Float b);
      ("gamma",   `Float g);
      ("c_sigma", `Float r.hyb_final_csigma);
    ]);
  ]
