(** Consistency protocol, LLM arm (skills/cm-of-cms/SKILL.md §3).

    delta_consistency = max absolute pairwise difference over the
    response contract's numeric fields (Witness_numeric); it maps
    through the canonical barrier phi(delta) = delta/(1-delta) to
    Coh_consistency = exp(-phi) (tsc-core §3.2, lambda = 1).

    This module is the engine home of that mapping — the barrier is
    sourced HERE for consistency reports, never re-implemented in
    scripts (the P1 migration: scripts/cm-consistency.sh delegates). *)

(** The barrier transform phi(delta) = delta / (1 - delta).
    Defined on [0, 1); callers map delta >= 1 to Coh 0 directly. *)
let barrier delta = delta /. (1.0 -. delta)

(** Coh_consistency from a spread delta: exp(-phi(delta)); 0 when the
    spread saturates (delta >= 1 — the barrier diverges). *)
let coh_from_delta delta =
  if delta >= 1.0 then 0.0 else Float.exp (-.(barrier delta))

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
      let delta = Witness_numeric.max_spread vectors in
      let coh = coh_from_delta delta in
      let fields_json =
        `Assoc (List.map (fun (f, vals, spread) ->
          (Witness_numeric.field_name f,
           `Assoc [
             ("values", `List (List.map (fun x -> `Float x) vals));
             ("spread", `Float (round6 spread));
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
        ("protocol", `String "skills/cm-of-cms/SKILL.md section 3");
      ])
