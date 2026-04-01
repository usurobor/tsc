(** Report generation: validated result → machine + human reports.

    Pure module — returns report strings. Caller writes to disk. *)

open Types

(** Generate machine-readable JSON report. *)
let to_json ~result ~metadata =
  let evidence_json ev =
    Printf.sprintf
      {|{"positive":[%s],"negative":[%s],"reason":"%s"}|}
      (String.concat "," (List.map (Printf.sprintf {|"%s"|}) ev.evidence_positive))
      (String.concat "," (List.map (Printf.sprintf {|"%s"|}) ev.evidence_negative))
      (String.escaped ev.evidence_reason)
  in
  let fixes_json =
    String.concat "," (List.map (fun f ->
      Printf.sprintf {|{"axis":"%s","fix":"%s"}|}
        f.fix_axis (String.escaped f.fix_description)
    ) result.result_next_fixes)
  in
  let hashes_json =
    String.concat "," (List.map (fun (path, hash) ->
      Printf.sprintf {|"%s":"%s"|} path hash
    ) metadata.meta_file_hashes)
  in
  Printf.sprintf
    {|{
  "target": "%s",
  "alpha": %.3f,
  "beta": %.3f,
  "gamma": %.3f,
  "bottleneck_axis": "%s",
  "confidence": %.3f,
  "summary": "%s",
  "axis_evidence": {
    "alpha": %s,
    "beta": %s,
    "gamma": %s
  },
  "unresolved_ambiguity": [%s],
  "next_fixes": [%s],
  "metadata": {
    "target": "%s",
    "file_hashes": {%s},
    "prompt_version": "%s",
    "provider": "%s",
    "model": "%s",
    "timestamp": "%s"
  }
}|}
    result.result_target
    result.result_alpha
    result.result_beta
    result.result_gamma
    result.result_bottleneck_axis
    result.result_confidence
    (String.escaped result.result_summary)
    (evidence_json result.result_alpha_evidence)
    (evidence_json result.result_beta_evidence)
    (evidence_json result.result_gamma_evidence)
    (String.concat "," (List.map (Printf.sprintf {|"%s"|}) result.result_unresolved_ambiguity))
    fixes_json
    metadata.meta_target
    hashes_json
    metadata.meta_prompt_version
    metadata.meta_provider
    metadata.meta_model
    metadata.meta_timestamp

(** Generate human-readable text report. *)
let to_text ~result ~metadata =
  let c_sigma =
    (result.result_alpha +. result.result_beta +. result.result_gamma) /. 3.0
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
     Target: %s\n\
     \n\
     Scores:\n\
     \  α = %.3f\n\
     \  β = %.3f\n\
     \  γ = %.3f\n\
     \  C_Σ = %.3f\n\
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
    result.result_target
    result.result_alpha
    result.result_beta
    result.result_gamma
    c_sigma
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
