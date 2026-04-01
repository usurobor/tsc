(** Report generation: validated result → machine + human reports.

    Pure module — returns report strings. Caller writes to disk.
    Uses Yojson.Safe for structured JSON output. *)

open Types

(** Build axis evidence as Yojson value. *)
let evidence_to_yojson ev =
  `Assoc [
    ("positive", `List (List.map (fun s -> `String s) ev.evidence_positive));
    ("negative", `List (List.map (fun s -> `String s) ev.evidence_negative));
    ("reason", `String ev.evidence_reason);
  ]

(** Generate machine-readable JSON report. *)
let to_json ~result ~metadata =
  let json =
    `Assoc [
      ("target", `String result.result_target);
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
