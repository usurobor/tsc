(** Medoid-of-k witness adjudication (SELF-MEASURE v3.2.3).

    Given k witness response files, choose the MEDOID: the sample with
    minimum total L1 distance to the other samples over the numeric
    contract fields (Witness_numeric — the same seven fields the
    consistency spread uses). The adjudicated reading is a real witness
    response with intact evidence text; which sample is adjudicated is
    no longer first-sample order luck. Adjudication never changes the
    spread — all samples still feed the consistency report.

    Two election modes, one election:

    - [choose] filters on NUMERIC completeness only. Compatibility
      policy (named, deliberate — inherited from the retired
      scripts/witness-medoid.py and pinned by tests): unparseable or
      field-incomplete samples are excluded; if no sample parses, the
      FIRST argument is chosen (the ingest step then refuses it with a
      recorded artifact); ties break toward the earliest argument.

    - [choose_valid] filters on FULL FUNNEL validity
      (Response_schema.validate_witness_response — every refusal stage,
      not just numeric shape). A numerically complete sample that fails
      the checklist or defect-card stages can never be adjudicated
      (post-loop stabilization Issue 1: under [choose] such a sample
      could be elected and then hard-fail the ingest step). No
      first-argument fallback: zero funnel-valid samples is an explicit
      [Error], so the caller records a no-valid-samples artifact
      instead of manufacturing an ingest failure. *)

(** Elect the medoid among [(path, vector)] candidates.
    Ties break toward the earliest element. None on empty input. *)
let elect (candidates : (string * Witness_numeric.vector) list)
  : string option =
  match candidates with
  | [] -> None
  | [ (p, _) ] -> Some p
  | _ ->
    let indexed = List.mapi (fun i (p, v) -> (i, p, v)) candidates in
    let best =
      List.fold_left (fun acc (i, p, v) ->
        let total =
          List.fold_left (fun t (j, _, w) ->
            if i = j then t
            else t +. Witness_numeric.l1_distance v w)
            0.0 indexed
        in
        match acc with
        | Some (_, best_total) when best_total <= total -> acc
        | _ -> Some (p, total))
        None indexed
    in
    Option.map fst best

(** Path of the medoid sample over numerically complete candidates.
    [Error] only on an empty input list. *)
let choose (paths : string list) : (string, string) result =
  match paths with
  | [] -> Error "witness-medoid needs at least one response file"
  | first :: _ ->
    let candidates =
      List.filter_map (fun p ->
        match Witness_numeric.of_json_file p with
        | Ok v -> Some (p, v)
        | Error _ -> None)
        paths
    in
    (match elect candidates with
     | Some p -> Ok p
     | None -> Ok first)

(** Path of the medoid sample over FUNNEL-VALID candidates: each file
    must pass the complete witness-validation funnel for
    [expected_target]. [Error] when the input list is empty or no
    sample validates — never a fallback to an invalid sample. *)
let choose_valid ~(expected_target : string) (paths : string list)
  : (string, string) result =
  match paths with
  | [] -> Error "witness-medoid needs at least one response file"
  | _ ->
    let candidates =
      List.filter_map (fun p ->
        let raw =
          try
            let ic = open_in_bin p in
            let n = in_channel_length ic in
            let s = really_input_string ic n in
            close_in ic; Some s
          with _ -> None
        in
        match raw with
        | None -> None
        | Some raw ->
          (match Response_schema.validate_witness_response
                   ~expected_target raw with
           | Ok _ ->
             (match Witness_numeric.of_json_file p with
              | Ok v -> Some (p, v)
              | Error _ -> None)
           | Error _ -> None))
        paths
    in
    (match elect candidates with
     | Some p -> Ok p
     | None ->
       Error
         (Printf.sprintf
            "no funnel-valid witness sample among %d file(s) for \
             target '%s'"
            (List.length paths) expected_target))
