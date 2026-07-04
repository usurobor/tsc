(** Consistency protocol, LLM arm (skills/cm-of-cms/SKILL.md §3).

    delta_consistency = max absolute pairwise difference over the
    response contract's numeric fields (Witness_numeric); it maps
    through the canonical barrier phi(delta) = delta/(1-delta) to
    Coh_consistency = exp(-phi) (tsc-core §3.2, lambda = 1).

    The barrier itself is NOT defined here: Coherence.phi /
    Coherence.coherence_link are the one source of the transform
    (engine/ocaml/lib/coherence.ml), and this module routes through
    them. The k=5 characterization pass caught the first draft of this
    module re-implementing the formula locally — the exact
    second-source-of-truth defect the P1 migration existed to remove;
    a smoke grep now guards against the regression. *)

(** The canonical barrier, routed: phi(delta) = delta / (1 - delta),
    +infinity at delta >= 1 (Coherence.phi's convention). *)
let barrier = Coherence.phi

(** Coh_consistency from a spread delta: the canonical link
    Coh = exp(-lambda * phi(delta)) at lambda = 1 (tsc-core §3.2);
    0 when the spread saturates (delta >= 1). *)
let coh_from_delta delta = Coherence.coherence_link ~lambda:1.0 ~delta

(* Round to 6 decimals — the report convention the Python
   implementation used (values stay raw; spreads and headline numbers
   round). *)
let round6 x = Float.round (x *. 1e6) /. 1e6

(** Build the llm-arm consistency report for validated witness samples.
    Same JSON semantics as the retired Python implementation in
    scripts/cm-consistency.sh: kind/arm/target/repeats, per-field
    values + spread, delta_consistency, coh_consistency, protocol.
    Requires >= 2 sample files; every file must carry the full numeric
    contract (Error otherwise — malformed samples are refused, not
    skipped: the callers pass funnel-validated samples only). *)
let llm_spread_report ~target ~files : (Yojson.Safe.t, string) result =
  if List.length files < 2 then
    Error "llm-spread needs >= 2 response files"
  else
    let rec load acc = function
      | [] -> Ok (List.rev acc)
      | f :: rest ->
        (match Witness_numeric.of_json_file f with
         | Ok v -> load (v :: acc) rest
         | Error e -> Error e)
    in
    match load [] files with
    | Error e -> Error e
    | Ok vectors ->
      let per_field = Witness_numeric.per_field_spread vectors in
      let mean_pairwise = Witness_numeric.per_field_mean_pairwise vectors in
      let delta = Witness_numeric.max_spread vectors in
      let coh = coh_from_delta delta in
      (* k-fair companion (Issue D): mean-pairwise per field, then max
         across fields; same barrier, same lambda. Reported under NEW
         names — the legacy max-pairwise fields stay untouched for
         history continuity and remain the conservative standing
         metric unless separately promoted. *)
      let delta_kfair = Witness_numeric.max_mean_pairwise vectors in
      let coh_kfair = coh_from_delta delta_kfair in
      let fields_json =
        `Assoc (List.map (fun (f, vals, spread) ->
          let mean =
            match List.assoc_opt f mean_pairwise with
            | Some d -> d | None -> 0.0
          in
          (Witness_numeric.field_name f,
           `Assoc [
             ("values", `List (List.map (fun x -> `Float x) vals));
             ("spread", `Float (round6 spread));
             ("mean_pairwise", `Float (round6 mean));
           ]))
          per_field)
      in
      Ok (`Assoc [
        ("kind", `String "cm_consistency_report");
        ("arm", `String "llm");
        ("target", `String target);
        ("repeats", `Int (List.length files));
        ("fields", fields_json);
        ("delta_consistency", `Float (round6 delta));
        ("coh_consistency", `Float (round6 coh));
        ("delta_consistency_max_pairwise", `Float (round6 delta));
        ("coh_consistency_max_pairwise", `Float (round6 coh));
        ("delta_consistency_mean_pairwise", `Float (round6 delta_kfair));
        ("coh_consistency_mean_pairwise", `Float (round6 coh_kfair));
        ("statistic", `Assoc [
          ("legacy", `String "max_pairwise");
          ("kfair", `String "mean_pairwise");
        ]);
        ("protocol", `String "skills/cm-of-cms/SKILL.md section 3");
      ])
