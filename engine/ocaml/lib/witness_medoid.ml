(** Medoid-of-k witness adjudication (SELF-MEASURE v3.2.3).

    Given k witness response files, choose the MEDOID: the sample with
    minimum total L1 distance to the other samples over the numeric
    contract fields (Witness_numeric — the same seven fields the
    consistency spread uses). The adjudicated reading is a real witness
    response with intact evidence text; which sample is adjudicated is
    no longer first-sample order luck. Adjudication never changes the
    spread — all samples still feed the consistency report.

    Compatibility policy (named, deliberate — inherited from the
    retired scripts/witness-medoid.py and pinned by tests):
    - samples that fail to parse or lack a numeric field are EXCLUDED
      from the election (the funnel refuses them downstream anyway);
    - if no sample parses, the FIRST argument is chosen (the ingest
      step then refuses it with a recorded artifact — same failure
      surface as before the medoid existed);
    - ties break toward the earliest argument. *)

(** Path of the medoid sample. [Error] only on an empty input list. *)
let choose (paths : string list) : (string, string) result =
  match paths with
  | [] -> Error "witness-medoid needs at least one response file"
  | first :: _ ->
    let valid =
      List.filter_map (fun p ->
        match Witness_numeric.of_json_file p with
        | Ok v -> Some (p, v)
        | Error _ -> None)
        paths
    in
    (match valid with
     | [] -> Ok first
     | [ (p, _) ] -> Ok p
     | _ ->
       let indexed = List.mapi (fun i (p, v) -> (i, p, v)) valid in
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
       (match best with
        | Some (p, _) -> Ok p
        | None -> Ok first))
