(** Coherence math: barrier transform, aggregate forms, W2 gauge witness.

    Implements the v3.2.0 transformation chain from spec/tsc-core.md:
      delta -> phi(delta) -> D -> Coh = exp(-D)

    All functions are pure; no I/O. *)

(* ------------------------------------------------------------------ *)
(* Barrier transform *)

(** phi(delta) = delta / (1 - delta) — canonical default barrier function.
    Returns +infinity (Float.infinity) for delta >= 1 by convention.
    Requires delta in [0, 1]. *)
let phi delta =
  if delta >= 1.0 then Float.infinity
  else delta /. (1.0 -. delta)

(** discrepancy_energy: D = lambda * phi(delta).
    D in [0, +infinity]. Requires lambda > 0, delta in [0, 1]. *)
let discrepancy_energy ~lambda ~delta =
  lambda *. phi delta

(** coherence_link: Coh = exp(-D).
    Endpoint policy: delta = 1 => D = +inf => Coh = 0 (strict equality, not limit).
    Requires lambda > 0, delta in [0, 1]. *)
let coherence_link ~lambda ~delta =
  if delta >= 1.0 then 0.0
  else
    let d = discrepancy_energy ~lambda ~delta in
    exp (-. d)

(* ------------------------------------------------------------------ *)
(* Aggregate forms *)

(** Result carrying both mathematical and numerical aggregate forms. *)
type aggregate_result = {
  c_sigma_math           : float;
  c_sigma_num            : float;
  epsilon                : float;
  zero_component_present : bool;
  numeric_floor_applied  : bool;
}

(** aggregate: compute C_Sigma^math and C_Sigma^num from component scores.

    C_Sigma^math = (s_alpha * s_beta * s_gamma)^(1/3)   [carries strict zero at endpoint]
    C_Sigma^num  = exp((1/3) * sum(ln(max(si, epsilon))))  [uses epsilon floor]

    They coincide when all si >= epsilon (default epsilon = 1e-5). *)
let aggregate ?(epsilon = 1e-5) ~s_alpha ~s_beta ~s_gamma () =
  let zero_present =
    s_alpha = 0.0 || s_beta = 0.0 || s_gamma = 0.0 in
  let floor_applied =
    s_alpha < epsilon || s_beta < epsilon || s_gamma < epsilon in
  let c_math =
    if zero_present then 0.0
    else (s_alpha *. s_beta *. s_gamma) ** (1.0 /. 3.0)
  in
  let fa = Float.max s_alpha epsilon
  and fb = Float.max s_beta  epsilon
  and fg = Float.max s_gamma epsilon in
  let c_num = exp ((log fa +. log fb +. log fg) /. 3.0) in
  { c_sigma_math           = c_math;
    c_sigma_num            = c_num;
    epsilon;
    zero_component_present = zero_present;
    numeric_floor_applied  = floor_applied }

(* ------------------------------------------------------------------ *)
(* W2 gauge witness *)

(** W2 gauge witness result.
    w_gauge_ref    = |C_Sigma(labeled) - C_Sigma(canonical_remap)|
    w_gauge_spread = max_pi C_Sigma - min_pi C_Sigma  over all 6 permutations *)
type gauge_witness = {
  w_gauge_ref               : float;
  w_gauge_spread            : float;
  tau_gauge_spread          : float;
  canonical_remap_procedure : string;
}

(** gauge_witness: compute W2 reference and spread signals.

    labeled: (s_alpha, s_beta, s_gamma) as assigned by the measurement procedure.
    c_sigma_fn: function (s_a, s_b, s_g) -> C_Sigma.  Must accept any assignment.
    tau_gauge_spread: default threshold for the spread signal.

    Canonical remap: sort the three scores in ascending order and assign
    lexicographically (lowest -> alpha, middle -> beta, highest -> gamma).
    This is deterministic and structure-derived. *)
let gauge_witness ~labeled ~c_sigma_fn ~tau_gauge_spread =
  let (sa, sb, sg) = labeled in
  let cs_labeled = c_sigma_fn sa sb sg in
  let scores = [sa; sb; sg] in
  let sorted = List.sort Float.compare scores in
  let (ca, cb, cg) = match sorted with
    | [a; b; c] -> (a, b, c)
    | _ -> assert false
  in
  let cs_canonical = c_sigma_fn ca cb cg in
  let w_gauge_ref = abs_float (cs_labeled -. cs_canonical) in
  let perms = [
    (sa, sb, sg); (sa, sg, sb); (sb, sa, sg);
    (sb, sg, sa); (sg, sa, sb); (sg, sb, sa)
  ] in
  let values = List.map (fun (a, b, g) -> c_sigma_fn a b g) perms in
  let max_v = List.fold_left Float.max neg_infinity values in
  let min_v = List.fold_left Float.min infinity values in
  let w_gauge_spread = max_v -. min_v in
  { w_gauge_ref;
    w_gauge_spread;
    tau_gauge_spread;
    canonical_remap_procedure =
      "lexicographic ascending by score value (lowest->alpha, middle->beta, highest->gamma)" }

(* ------------------------------------------------------------------ *)
(* Provenance JSON skeleton *)

(** Build the canonical v3.2.0 provenance JSON object from spec/tsc-oper.md §6.
    Computed values may be provided or left as null (use None). *)
let provenance_json
    ?(barrier_clip_eta_phi = None)
    ?(l_link_alpha_beta = None)
    ?(l_link_beta_gamma = None)
    ?(l_link_gamma_alpha = None)
    ?(c_sigma_math = None)
    ?(zero_component_present = false)
    ?(c_sigma_num = None)
    ?(epsilon = None)
    ?(numeric_floor_applied = false)
    ?(w_gauge_ref = None)
    ?(w_gauge_spread = None)
    ?(tau_gauge_spread = None)
    ?(canonical_remap_procedure = None)
    () =
  let nullable_float = function
    | None   -> `Null
    | Some f -> `Float f
  in
  let nullable_string = function
    | None   -> `Null
    | Some s -> `String s
  in
  `Assoc [
    ("discrepancy_symbol",  `String "delta");
    ("discrepancy_range",   `String "[0,1]");
    ("coherence_link",      `String "barrier_exponential");
    ("barrier_phi",         `String "delta/(1-delta)");
    ("barrier_clip_eta_phi",nullable_float barrier_clip_eta_phi);
    ("endpoint_policy",     `String "delta=1 -> D=infinity -> Coh=0");
    ("energy_variable",     `String "D_ab");
    ("link_lipschitz_constants", `Assoc [
      ("alpha_beta",   nullable_float l_link_alpha_beta);
      ("beta_gamma",   nullable_float l_link_beta_gamma);
      ("gamma_alpha",  nullable_float l_link_gamma_alpha);
    ]);
    ("aggregate_math", `Assoc [
      ("C_sigma_math",          nullable_float c_sigma_math);
      ("zero_component_present",`Bool zero_component_present);
    ]);
    ("aggregate_numeric", `Assoc [
      ("C_sigma_num",         nullable_float c_sigma_num);
      ("epsilon",             nullable_float epsilon);
      ("numeric_floor_applied",`Bool numeric_floor_applied);
    ]);
    ("gauge_witness", `Assoc [
      ("w_gauge_ref",               nullable_float w_gauge_ref);
      ("w_gauge_spread",            nullable_float w_gauge_spread);
      ("tau_gauge_spread",          nullable_float tau_gauge_spread);
      ("canonical_remap_procedure", nullable_string canonical_remap_procedure);
    ]);
  ]
