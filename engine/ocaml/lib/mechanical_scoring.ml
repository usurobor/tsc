(** Mechanical scoring for TSC.

    Implements deterministic structural scoring over a resolved bundle.
    See mechanical_scoring.mli for the contract. *)

open Types

(* --- Type definitions matching .mli --- *)

type axis = [ `Alpha | `Beta | `Gamma ]

type evidence_kind = [ `Structural_proxy ]

type signal = {
  code : string;
  label : string;
  weight : float;
  score : float;
  evidence : string list;
}

type diagnostic_level = [ `Info | `Warning | `Error ]

type diagnostic = {
  level : diagnostic_level;
  code : string;
  message : string;
  paths : string list;
}

type axis_result = {
  axis : axis;
  score : float;
  evidence_kind : evidence_kind;
  signals : signal list;
  summary : string;
  unresolved_ambiguity : string list;
}

type result = {
  mode : [ `Mechanical ];
  target : string option;
  alpha : axis_result;
  beta : axis_result;
  gamma : axis_result;
  c_sigma : float;
  bottleneck_axis : axis;
  confidence : float;
  diagnostics : diagnostic list;
}

type weights = {
  alpha : float;
  beta : float;
  gamma : float;
}

type alpha_config = {
  terminology_consistency : float;
  repeated_structure : float;
  duplicate_definition_tension : float;
  naming_drift : float;
}

type beta_config = {
  cross_reference_consistency : float;
  authority_alignment : float;
  source_of_truth_alignment : float;
  target_file_fit : float;
}

type gamma_config = {
  canonical_generated_distinction : float;
  version_surface_consistency : float;
  traceability_presence : float;
  authority_evolution_consistency : float;
}

type config = {
  weights : weights;
  alpha : alpha_config;
  beta : beta_config;
  gamma : gamma_config;
  min_confidence_files : int;
  max_excerpt_chars : int;
}

type comparison = {
  old_result : result;
  new_result : result;
  delta_alpha : float;
  delta_beta : float;
  delta_gamma : float;
  delta_c_sigma : float;
  changed_bottleneck : bool;
  summary : string;
}

let default_config : config = {
  weights = { alpha = 1.0; beta = 1.0; gamma = 1.0 };
  alpha = {
    terminology_consistency = 0.30;
    repeated_structure = 0.25;
    duplicate_definition_tension = 0.25;
    naming_drift = 0.20;
  };
  beta = {
    cross_reference_consistency = 0.30;
    authority_alignment = 0.25;
    source_of_truth_alignment = 0.25;
    target_file_fit = 0.20;
  };
  gamma = {
    canonical_generated_distinction = 0.25;
    version_surface_consistency = 0.30;
    traceability_presence = 0.25;
    authority_evolution_consistency = 0.20;
  };
  min_confidence_files = 3;
  max_excerpt_chars = 200;
}

(* --- Utility functions --- *)

(** Truncate a string for evidence excerpts. *)
let truncate max_len s =
  if String.length s <= max_len then s
  else String.sub s 0 max_len ^ "..."

(** Split content into lowercase words. *)
let words content =
  let buf = Buffer.create 64 in
  let result = ref [] in
  String.iter (fun c ->
    if (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
       || (c >= '0' && c <= '9') || c = '_' || c = '-' then
      Buffer.add_char buf (Char.lowercase_ascii c)
    else begin
      if Buffer.length buf > 0 then begin
        result := Buffer.contents buf :: !result;
        Buffer.clear buf
      end
    end
  ) content;
  if Buffer.length buf > 0 then
    result := Buffer.contents buf :: !result;
  List.rev !result

(** Extract lines from content. *)
let lines content =
  String.split_on_char '\n' content

(** Extract heading lines (lines starting with #). *)
let headings content =
  lines content
  |> List.filter (fun line ->
    let trimmed = String.trim line in
    String.length trimmed > 0 && trimmed.[0] = '#')

(** Build a word frequency table. *)
let word_freq words =
  let tbl = Hashtbl.create 128 in
  List.iter (fun w ->
    let count = try Hashtbl.find tbl w with Not_found -> 0 in
    Hashtbl.replace tbl w (count + 1)
  ) words;
  tbl

(** Extract bold terms from Markdown content: **term** or __term__. *)
let bold_terms content =
  let result = ref [] in
  let len = String.length content in
  let i = ref 0 in
  while !i < len - 3 do
    if content.[!i] = '*' && content.[!i + 1] = '*' then begin
      let start = !i + 2 in
      let j = ref start in
      while !j < len - 1 && not (content.[!j] = '*' && content.[!j + 1] = '*') do
        incr j
      done;
      if !j < len - 1 then begin
        let term = String.sub content start (!j - start) in
        if String.length term > 0 && String.length term < 80 then
          result := String.lowercase_ascii term :: !result;
        i := !j + 2
      end else
        i := !j
    end else
      incr i
  done;
  List.rev !result

(** Check if content contains a reference to a path or file. *)
let file_references content =
  let result = ref [] in
  let ls = lines content in
  List.iter (fun line ->
    (* Match patterns like `path/to/file.ext` or (path/to/file.ext) *)
    let len = String.length line in
    let i = ref 0 in
    while !i < len do
      if line.[!i] = '`' || line.[!i] = '(' then begin
        let delim = if line.[!i] = '`' then '`' else ')' in
        let start = !i + 1 in
        let j = ref start in
        while !j < len && line.[!j] <> delim do incr j done;
        if !j < len then begin
          let candidate = String.sub line start (!j - start) in
          if String.contains candidate '/' || String.contains candidate '.' then
            result := candidate :: !result;
          i := !j + 1
        end else
          i := !j
      end else
        incr i
    done
  ) ls;
  List.rev !result

(* --- String search helper --- *)

let string_contains_s haystack needle =
  let hlen = String.length haystack in
  let nlen = String.length needle in
  if nlen = 0 then true
  else if nlen > hlen then false
  else begin
    let found = ref false in
    for i = 0 to hlen - nlen do
      if not !found then
        if String.sub haystack i nlen = needle then found := true
    done;
    !found
  end

(* --- Version extraction --- *)

module Regexp = struct
  let version_like content =
    let result = ref [] in
    let len = String.length content in
    let i = ref 0 in
    while !i < len - 4 do
      let c = content.[!i] in
      if c >= '0' && c <= '9' then begin
        let start = !i in
        let j = ref start in
        let dots = ref 0 in
        while !j < len && (
          let ch = content.[!j] in
          (ch >= '0' && ch <= '9') || (ch = '.' && !dots < 2)
        ) do
          if content.[!j] = '.' then incr dots;
          incr j
        done;
        if !dots >= 1 then begin
          let ver = String.sub content start (!j - start) in
          if String.length ver >= 3 then
            result := ver :: !result
        end;
        i := !j
      end else
        incr i
    done;
    List.rev !result
end

(* --- Alpha signals --- *)

(** Terminology consistency: are the same key terms used across files? *)
let score_terminology_consistency ~max_excerpt files =
  let all_bold = List.concat_map (fun (f : bundle_file) ->
    bold_terms f.file_content
  ) files in
  let freq = word_freq all_bold in
  let total_terms = Hashtbl.length freq in
  if total_terms = 0 then
    { code = "A1"; label = "terminology-consistency";
      weight = 1.0; score = 0.8;
      evidence = ["no bold terms found — neutral"] }
  else begin
    (* Terms that appear in multiple files *)
    let term_file_count = Hashtbl.create 64 in
    List.iter (fun (f : bundle_file) ->
      let file_terms = bold_terms f.file_content in
      let seen = Hashtbl.create 16 in
      List.iter (fun t ->
        if not (Hashtbl.mem seen t) then begin
          Hashtbl.replace seen t ();
          let c = try Hashtbl.find term_file_count t with Not_found -> 0 in
          Hashtbl.replace term_file_count t (c + 1)
        end
      ) file_terms
    ) files;
    let n_files = List.length files in
    let shared = Hashtbl.fold (fun _ count acc ->
      if count > 1 then acc + 1 else acc
    ) term_file_count 0 in
    let ratio = if total_terms > 0
      then float_of_int shared /. float_of_int total_terms
      else 0.0 in
    let s = 0.5 +. ratio *. 0.5 in (* 0.5 base + up to 0.5 for sharing *)
    let evidence =
      Printf.sprintf "%d/%d terms shared across %d files"
        shared total_terms n_files in
    { code = "A1"; label = "terminology-consistency";
      weight = 1.0; score = Float.min 1.0 s;
      evidence = [truncate max_excerpt evidence] }
  end

(** Repeated structure: do files share heading patterns? *)
let score_repeated_structure ~max_excerpt files =
  let heading_sets = List.map (fun (f : bundle_file) ->
    headings f.file_content
    |> List.map (fun h ->
      (* Normalize: strip # prefix, lowercase *)
      let trimmed = String.trim h in
      let no_hash = ref 0 in
      while !no_hash < String.length trimmed && trimmed.[!no_hash] = '#' do
        incr no_hash
      done;
      String.lowercase_ascii (String.trim (
        String.sub trimmed !no_hash (String.length trimmed - !no_hash))))
  ) files in
  let all_headings = List.concat heading_sets in
  let total = List.length all_headings in
  if total = 0 then
    { code = "A2"; label = "repeated-structure";
      weight = 1.0; score = 0.7;
      evidence = ["no headings found"] }
  else begin
    let freq = word_freq all_headings in
    let repeated = Hashtbl.fold (fun _ count acc ->
      if count > 1 then acc + 1 else acc
    ) freq 0 in
    let unique = Hashtbl.length freq in
    let ratio = if unique > 0
      then float_of_int repeated /. float_of_int unique
      else 0.0 in
    let s = 0.4 +. ratio *. 0.6 in
    { code = "A2"; label = "repeated-structure";
      weight = 1.0; score = Float.min 1.0 s;
      evidence = [truncate max_excerpt (Printf.sprintf
        "%d/%d unique headings repeated across files" repeated unique)] }
  end

(** Duplicate definition tension: same bold term defined differently. *)
let score_duplicate_definition ~max_excerpt files =
  (* Check if bold terms have contradicting contexts *)
  let term_contexts = Hashtbl.create 64 in
  List.iter (fun (f : bundle_file) ->
    let ls = lines f.file_content in
    List.iter (fun line ->
      let bolds = bold_terms line in
      List.iter (fun term ->
        let existing = try Hashtbl.find term_contexts term with Not_found -> [] in
        Hashtbl.replace term_contexts term
          ((f.file_path, truncate max_excerpt (String.trim line)) :: existing)
      ) bolds
    ) ls
  ) files;
  let tensions = Hashtbl.fold (fun term locs acc ->
    let unique_files = List.sort_uniq String.compare
      (List.map fst locs) in
    if List.length unique_files > 1 && List.length locs > 2 then
      (term, List.length unique_files) :: acc
    else acc
  ) term_contexts [] in
  let n_tensions = List.length tensions in
  let s = if n_tensions = 0 then 1.0
    else Float.max 0.3 (1.0 -. float_of_int n_tensions *. 0.1) in
  let evidence = if n_tensions = 0 then ["no definition tension detected"]
    else List.map (fun (term, n) ->
      Printf.sprintf "'%s' defined across %d files" term n
    ) (List.filteri (fun i _ -> i < 3) tensions) in
  { code = "A3"; label = "duplicate-definition-tension";
    weight = 1.0; score = s;
    evidence }

(** Naming drift: inconsistent capitalization/hyphenation of key terms. *)
let score_naming_drift ~max_excerpt files =
  let all_words = List.concat_map (fun (f : bundle_file) ->
    words f.file_content
  ) files in
  let canonical = Hashtbl.create 128 in
  let drift_count = ref 0 in
  List.iter (fun w ->
    let lower = String.lowercase_ascii w in
    match Hashtbl.find_opt canonical lower with
    | None -> Hashtbl.replace canonical lower w
    | Some existing ->
      if existing <> w then incr drift_count
  ) all_words;
  let total = Hashtbl.length canonical in
  let ratio = if total > 0
    then float_of_int !drift_count /. float_of_int total
    else 0.0 in
  let s = Float.max 0.3 (1.0 -. ratio *. 2.0) in
  { code = "A4"; label = "naming-drift";
    weight = 1.0; score = Float.min 1.0 s;
    evidence = [truncate max_excerpt (Printf.sprintf
      "%d drift instances across %d unique terms" !drift_count total)] }

(* --- Beta signals --- *)

(** Cross-reference consistency: do file refs resolve? *)
let score_cross_references ~max_excerpt files =
  let file_paths = List.map (fun (f : bundle_file) -> f.file_path) files in
  let all_refs = List.concat_map (fun (f : bundle_file) ->
    file_references f.file_content
    |> List.map (fun r -> (f.file_path, r))
  ) files in
  let total_refs = List.length all_refs in
  if total_refs = 0 then
    { code = "B1"; label = "cross-reference-consistency";
      weight = 1.0; score = 0.7;
      evidence = ["no cross-file references found"] }
  else begin
    let resolved = List.filter (fun (_, ref_path) ->
      List.exists (fun fp ->
        fp = ref_path || String.ends_with ~suffix:ref_path fp
        || String.ends_with ~suffix:fp ref_path
      ) file_paths
    ) all_refs in
    let n_resolved = List.length resolved in
    let ratio = float_of_int n_resolved /. float_of_int total_refs in
    let s = 0.3 +. ratio *. 0.7 in
    { code = "B1"; label = "cross-reference-consistency";
      weight = 1.0; score = Float.min 1.0 s;
      evidence = [truncate max_excerpt (Printf.sprintf
        "%d/%d references resolve within bundle" n_resolved total_refs)] }
  end

(** Authority alignment: do files agree on ownership claims? *)
let score_authority_alignment ~max_excerpt files =
  (* Look for "canonical", "authoritative", "governs", "source of truth" *)
  let authority_markers = ["canonical"; "authoritative"; "governs";
    "source of truth"; "single source"] in
  let claims = List.concat_map (fun (f : bundle_file) ->
    let lower = String.lowercase_ascii f.file_content in
    List.filter_map (fun marker ->
      if String.length lower >= String.length marker then begin
        let found = ref false in
        for i = 0 to String.length lower - String.length marker do
          if not !found then begin
            let sub = String.sub lower i (String.length marker) in
            if sub = marker then found := true
          end
        done;
        if !found then Some (f.file_path, marker) else None
      end else None
    ) authority_markers
  ) files in
  let n_claims = List.length claims in
  (* More authority claims per file = potentially good if consistent *)
  let n_files = List.length files in
  if n_claims = 0 then
    { code = "B2"; label = "authority-alignment";
      weight = 1.0; score = 0.6;
      evidence = ["no authority claims found — neutral-low"] }
  else begin
    let ratio = float_of_int n_claims /. float_of_int n_files in
    let s = if ratio > 0.5 then 0.85 else 0.6 +. ratio *. 0.5 in
    { code = "B2"; label = "authority-alignment";
      weight = 1.0; score = Float.min 1.0 s;
      evidence = [truncate max_excerpt (Printf.sprintf
        "%d authority claims across %d files" n_claims n_files)] }
  end

(** Source-of-truth alignment: detect duplicated version/name facts. *)
let score_source_of_truth ~max_excerpt files =
  (* Check for version strings appearing in multiple files *)
  let version_pattern = Regexp.version_like in
  let version_locs = List.concat_map (fun (f : bundle_file) ->
    let versions = version_pattern f.file_content in
    List.map (fun v -> (f.file_path, v)) versions
  ) files in
  let version_files = Hashtbl.create 16 in
  List.iter (fun (path, ver) ->
    let existing = try Hashtbl.find version_files ver with Not_found -> [] in
    Hashtbl.replace version_files ver (path :: existing)
  ) version_locs;
  let duplicated = Hashtbl.fold (fun ver paths acc ->
    let unique = List.sort_uniq String.compare paths in
    if List.length unique > 1 then (ver, unique) :: acc else acc
  ) version_files [] in
  let n_dup = List.length duplicated in
  let s = if n_dup = 0 then 0.9
    else Float.max 0.4 (0.9 -. float_of_int n_dup *. 0.15) in
  let evidence = if n_dup = 0 then
    ["no duplicated version strings detected"]
  else
    List.map (fun (ver, paths) ->
      Printf.sprintf "version '%s' in %d files" ver (List.length paths)
    ) (List.filteri (fun i _ -> i < 3) duplicated) in
  { code = "B3"; label = "source-of-truth-alignment";
    weight = 1.0; score = s;
    evidence }

(** Target-file fit: do included files match the target's declared scope? *)
let score_target_file_fit ~max_excerpt files target_opt =
  match target_opt with
  | None ->
    { code = "B4"; label = "target-file-fit";
      weight = 1.0; score = 0.7;
      evidence = ["no target specified — neutral"] }
  | Some target_name ->
    let relevant = List.filter (fun (f : bundle_file) ->
      let lower_path = String.lowercase_ascii f.file_path in
      let lower_target = String.lowercase_ascii target_name in
      String.length f.file_content > 10
      && (string_contains_s lower_path lower_target
          || f.file_size > 100)
    ) files in
    let ratio = if List.length files > 0
      then float_of_int (List.length relevant) /. float_of_int (List.length files)
      else 0.0 in
    let s = 0.5 +. ratio *. 0.5 in
    { code = "B4"; label = "target-file-fit";
      weight = 1.0; score = Float.min 1.0 s;
      evidence = [truncate max_excerpt (Printf.sprintf
        "%d/%d files substantive for target '%s'"
        (List.length relevant) (List.length files) target_name)] }

(* --- Gamma signals --- *)

(** Canonical/generated distinction: are generated files marked? *)
let score_canonical_generated ~max_excerpt files =
  let generated_markers = ["generated by"; "do not edit"; "auto-generated";
    "this file is generated"] in
  let generated_files = List.filter (fun (f : bundle_file) ->
    let lower = String.lowercase_ascii
      (if String.length f.file_content > 500
       then String.sub f.file_content 0 500
       else f.file_content) in
    List.exists (fun marker ->
      let found = ref false in
      let mlen = String.length marker in
      for i = 0 to String.length lower - mlen do
        if not !found then begin
          let sub = String.sub lower i mlen in
          if sub = marker then found := true
        end
      done;
      !found
    ) generated_markers
  ) files in
  let n_gen = List.length generated_files in
  let n_total = List.length files in
  (* Having generated files clearly marked is good *)
  let s = if n_gen = 0 then 0.8  (* no generated files — fine *)
    else 0.7 +. 0.3 *. (float_of_int n_gen /. float_of_int n_total) in
  { code = "G1"; label = "canonical-generated-distinction";
    weight = 1.0; score = Float.min 1.0 s;
    evidence = [truncate max_excerpt (Printf.sprintf
      "%d/%d files have generation markers" n_gen n_total)] }

(** Version surface consistency: do version mentions agree? *)
let score_version_consistency ~max_excerpt files =
  let version_pattern = Regexp.version_like in
  let all_versions = List.concat_map (fun (f : bundle_file) ->
    version_pattern f.file_content
  ) files in
  let freq = word_freq all_versions in
  let n_distinct = Hashtbl.length freq in
  if n_distinct <= 1 then
    { code = "G2"; label = "version-surface-consistency";
      weight = 1.0; score = 0.95;
      evidence = [if n_distinct = 0 then "no version strings found"
        else "single version string — consistent"] }
  else begin
    (* Penalize for many distinct versions *)
    let s = Float.max 0.3 (1.0 -. float_of_int (n_distinct - 1) *. 0.1) in
    let top_versions = Hashtbl.fold (fun v c acc -> (v, c) :: acc) freq []
      |> List.sort (fun (_, a) (_, b) -> compare b a)
      |> List.filteri (fun i _ -> i < 3) in
    let evidence = List.map (fun (v, c) ->
      Printf.sprintf "'%s' (%d occurrences)" v c
    ) top_versions in
    { code = "G2"; label = "version-surface-consistency";
      weight = 1.0; score = s;
      evidence }
  end

(** Traceability presence: do files show traceability artifacts? *)
let score_traceability ~max_excerpt files =
  let trace_markers = ["changelog"; "issue"; "closes #"; "fixes #";
    "see #"; "pr #"; "commit"; "version history"] in
  let traced_files = List.filter (fun (f : bundle_file) ->
    let lower = String.lowercase_ascii f.file_content in
    List.exists (fun marker ->
      let found = ref false in
      let mlen = String.length marker in
      if String.length lower >= mlen then
        for i = 0 to String.length lower - mlen do
          if not !found then begin
            let sub = String.sub lower i mlen in
            if sub = marker then found := true
          end
        done;
      !found
    ) trace_markers
  ) files in
  let ratio = if List.length files > 0
    then float_of_int (List.length traced_files) /. float_of_int (List.length files)
    else 0.0 in
  let s = 0.4 +. ratio *. 0.6 in
  { code = "G3"; label = "traceability-presence";
    weight = 1.0; score = Float.min 1.0 s;
    evidence = [truncate max_excerpt (Printf.sprintf
      "%d/%d files have traceability markers"
      (List.length traced_files) (List.length files))] }

(** Authority evolution consistency: do files maintain consistent
    authority and evolution patterns? *)
let score_authority_evolution ~max_excerpt files =
  (* Check for consistent use of dates, version references, change markers *)
  let evolution_markers = ["added"; "changed"; "removed"; "deprecated";
    "breaking"; "migration"] in
  let files_with_evolution = List.filter (fun (f : bundle_file) ->
    let lower = String.lowercase_ascii f.file_content in
    let has_marker = List.exists (fun marker ->
      let found = ref false in
      let mlen = String.length marker in
      if String.length lower >= mlen then
        for i = 0 to String.length lower - mlen do
          if not !found then begin
            let sub = String.sub lower i mlen in
            if sub = marker then found := true
          end
        done;
      !found
    ) evolution_markers in
    has_marker
  ) files in
  let ratio = if List.length files > 0
    then float_of_int (List.length files_with_evolution)
         /. float_of_int (List.length files)
    else 0.0 in
  let s = 0.5 +. ratio *. 0.5 in
  { code = "G4"; label = "authority-evolution-consistency";
    weight = 1.0; score = Float.min 1.0 s;
    evidence = [truncate max_excerpt (Printf.sprintf
      "%d/%d files have evolution markers"
      (List.length files_with_evolution) (List.length files))] }

(* --- Regexp helpers (no external dependency) --- *)


(* --- Axis scoring --- *)

let score_alpha ~config files =
  let max_excerpt = config.max_excerpt_chars in
  let s1 = score_terminology_consistency ~max_excerpt files in
  let s2 = score_repeated_structure ~max_excerpt files in
  let s3 = score_duplicate_definition ~max_excerpt files in
  let s4 = score_naming_drift ~max_excerpt files in
  let signals = [
    { s1 with weight = config.alpha.terminology_consistency };
    { s2 with weight = config.alpha.repeated_structure };
    { s3 with weight = config.alpha.duplicate_definition_tension };
    { s4 with weight = config.alpha.naming_drift };
  ] in
  let weighted_sum = List.fold_left (fun acc s ->
    acc +. s.weight *. s.score
  ) 0.0 signals in
  let weight_total = List.fold_left (fun acc s ->
    acc +. s.weight
  ) 0.0 signals in
  let score = if weight_total > 0.0
    then weighted_sum /. weight_total
    else 0.5 in
  {
    axis = `Alpha;
    score;
    evidence_kind = `Structural_proxy;
    signals;
    summary = Printf.sprintf "Pattern coherence: %.2f (terminology, structure, definitions, naming)" score;
    unresolved_ambiguity = [];
  }

let score_beta ~config ~target files =
  let max_excerpt = config.max_excerpt_chars in
  let s1 = score_cross_references ~max_excerpt files in
  let s2 = score_authority_alignment ~max_excerpt files in
  let s3 = score_source_of_truth ~max_excerpt files in
  let s4 = score_target_file_fit ~max_excerpt files target in
  let signals = [
    { s1 with weight = config.beta.cross_reference_consistency };
    { s2 with weight = config.beta.authority_alignment };
    { s3 with weight = config.beta.source_of_truth_alignment };
    { s4 with weight = config.beta.target_file_fit };
  ] in
  let weighted_sum = List.fold_left (fun acc s ->
    acc +. s.weight *. s.score
  ) 0.0 signals in
  let weight_total = List.fold_left (fun acc s ->
    acc +. s.weight
  ) 0.0 signals in
  let score = if weight_total > 0.0
    then weighted_sum /. weight_total
    else 0.5 in
  {
    axis = `Beta;
    score;
    evidence_kind = `Structural_proxy;
    signals;
    summary = Printf.sprintf "Relational coherence: %.2f (references, authority, truth, fit)" score;
    unresolved_ambiguity = [];
  }

let score_gamma ~config files =
  let max_excerpt = config.max_excerpt_chars in
  let s1 = score_canonical_generated ~max_excerpt files in
  let s2 = score_version_consistency ~max_excerpt files in
  let s3 = score_traceability ~max_excerpt files in
  let s4 = score_authority_evolution ~max_excerpt files in
  let signals = [
    { s1 with weight = config.gamma.canonical_generated_distinction };
    { s2 with weight = config.gamma.version_surface_consistency };
    { s3 with weight = config.gamma.traceability_presence };
    { s4 with weight = config.gamma.authority_evolution_consistency };
  ] in
  let weighted_sum = List.fold_left (fun acc s ->
    acc +. s.weight *. s.score
  ) 0.0 signals in
  let weight_total = List.fold_left (fun acc s ->
    acc +. s.weight
  ) 0.0 signals in
  let score = if weight_total > 0.0
    then weighted_sum /. weight_total
    else 0.5 in
  {
    axis = `Gamma;
    score;
    evidence_kind = `Structural_proxy;
    signals;
    summary = Printf.sprintf "Process coherence: %.2f (generated, versions, traceability, evolution)" score;
    unresolved_ambiguity = [];
  }

(* --- Main scoring functions --- *)

let score_bundle ?(config = default_config) (bundle : target_bundle) =
  let files = bundle.bundle_files in
  let target = Some bundle.bundle_target_name in
  let alpha = score_alpha ~config files in
  let beta = score_beta ~config ~target files in
  let gamma = score_gamma ~config files in
  let c_sigma =
    let wa = config.weights.alpha and wb = config.weights.beta and wg = config.weights.gamma in
    let product = (alpha.score ** wa) *. (beta.score ** wb) *. (gamma.score ** wg) in
    product ** (1.0 /. (wa +. wb +. wg)) in
  let bottleneck_axis =
    if alpha.score <= beta.score && alpha.score <= gamma.score then `Alpha
    else if beta.score <= gamma.score then `Beta
    else `Gamma in
  let n_files = List.length files in
  let confidence = if n_files >= config.min_confidence_files then 1.0
    else float_of_int n_files /. float_of_int config.min_confidence_files in
  let diagnostics =
    if n_files < config.min_confidence_files then
      [{ level = `Warning; code = "D001";
         message = Printf.sprintf "Bundle has %d files (< %d minimum for full confidence)"
           n_files config.min_confidence_files;
         paths = [] }]
    else [] in
  {
    mode = `Mechanical;
    target;
    alpha; beta; gamma;
    c_sigma;
    bottleneck_axis;
    confidence;
    diagnostics;
  }

let score_files ?(config = default_config) (files : bundle_file list) =
  let alpha = score_alpha ~config files in
  let beta = score_beta ~config ~target:None files in
  let gamma = score_gamma ~config files in
  let c_sigma =
    let wa = config.weights.alpha and wb = config.weights.beta and wg = config.weights.gamma in
    let product = (alpha.score ** wa) *. (beta.score ** wb) *. (gamma.score ** wg) in
    product ** (1.0 /. (wa +. wb +. wg)) in
  let bottleneck_axis =
    if alpha.score <= beta.score && alpha.score <= gamma.score then `Alpha
    else if beta.score <= gamma.score then `Beta
    else `Gamma in
  let n_files = List.length files in
  let confidence = if n_files >= config.min_confidence_files then 1.0
    else float_of_int n_files /. float_of_int config.min_confidence_files in
  let diagnostics =
    if n_files < config.min_confidence_files then
      [{ level = `Warning; code = "D001";
         message = Printf.sprintf "Bundle has %d files (< %d minimum)"
           n_files config.min_confidence_files;
         paths = [] }]
    else [] in
  {
    mode = `Mechanical;
    target = None;
    alpha; beta; gamma;
    c_sigma;
    bottleneck_axis;
    confidence;
    diagnostics;
  }

let compare ?(config = default_config) ~old_ ~new_ =
  let old_result = score_bundle ~config old_ in
  let new_result = score_bundle ~config new_ in
  {
    old_result;
    new_result;
    delta_alpha = new_result.alpha.score -. old_result.alpha.score;
    delta_beta = new_result.beta.score -. old_result.beta.score;
    delta_gamma = new_result.gamma.score -. old_result.gamma.score;
    delta_c_sigma = new_result.c_sigma -. old_result.c_sigma;
    changed_bottleneck = old_result.bottleneck_axis <> new_result.bottleneck_axis;
    summary = Printf.sprintf "C_Σ: %.3f → %.3f (Δ%+.3f)"
      old_result.c_sigma new_result.c_sigma
      (new_result.c_sigma -. old_result.c_sigma);
  }

(* --- JSON serialization --- *)

let axis_to_string = function
  | `Alpha -> "alpha" | `Beta -> "beta" | `Gamma -> "gamma"

let signal_to_json (s : signal) : Yojson.Safe.t =
  `Assoc [
    ("code", `String s.code);
    ("label", `String s.label);
    ("weight", `Float s.weight);
    ("score", `Float s.score);
    ("evidence", `List (List.map (fun e -> `String e) s.evidence));
  ]

let diagnostic_to_json (d : diagnostic) : Yojson.Safe.t =
  `Assoc [
    ("level", `String (match d.level with
      | `Info -> "info" | `Warning -> "warning" | `Error -> "error"));
    ("code", `String d.code);
    ("message", `String d.message);
    ("paths", `List (List.map (fun p -> `String p) d.paths));
  ]

let axis_result_to_json (ar : axis_result) : Yojson.Safe.t =
  `Assoc [
    ("axis", `String (axis_to_string ar.axis));
    ("score", `Float ar.score);
    ("evidence_kind", `String "structural-proxy");
    ("signals", `List (List.map signal_to_json ar.signals));
    ("summary", `String ar.summary);
    ("unresolved_ambiguity", `List (List.map (fun s -> `String s) ar.unresolved_ambiguity));
  ]

let result_to_json (r : result) : Yojson.Safe.t =
  `Assoc [
    ("mode", `String "mechanical");
    ("target", (match r.target with Some t -> `String t | None -> `Null));
    ("alpha", `Float r.alpha.score);
    ("beta", `Float r.beta.score);
    ("gamma", `Float r.gamma.score);
    ("c_sigma", `Float r.c_sigma);
    ("bottleneck_axis", `String (axis_to_string r.bottleneck_axis));
    ("confidence", `Float r.confidence);
    ("evidence_kind", `String "structural-proxy");
    ("alpha_detail", axis_result_to_json r.alpha);
    ("beta_detail", axis_result_to_json r.beta);
    ("gamma_detail", axis_result_to_json r.gamma);
    ("diagnostics", `List (List.map diagnostic_to_json r.diagnostics));
  ]

let comparison_to_json (c : comparison) : Yojson.Safe.t =
  `Assoc [
    ("old", result_to_json c.old_result);
    ("new", result_to_json c.new_result);
    ("delta_alpha", `Float c.delta_alpha);
    ("delta_beta", `Float c.delta_beta);
    ("delta_gamma", `Float c.delta_gamma);
    ("delta_c_sigma", `Float c.delta_c_sigma);
    ("changed_bottleneck", `Bool c.changed_bottleneck);
    ("summary", `String c.summary);
  ]

(* --- Human-readable output --- *)

let summarize_signal (s : signal) =
  Printf.sprintf "[%s] %s: %.2f (weight %.2f) — %s"
    s.code s.label s.score s.weight
    (String.concat "; " s.evidence)

let summarize_result (r : result) =
  Printf.sprintf
    "Mechanical Scoring Result\n\
     ========================\n\
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
     Alpha signals:\n\
     %s\n\
     \n\
     Beta signals:\n\
     %s\n\
     \n\
     Gamma signals:\n\
     %s\n"
    (match r.target with Some t -> t | None -> "(direct files)")
    r.alpha.score r.beta.score r.gamma.score r.c_sigma
    (axis_to_string r.bottleneck_axis)
    r.confidence
    (String.concat "\n" (List.map (fun s -> "  " ^ summarize_signal s) r.alpha.signals))
    (String.concat "\n" (List.map (fun s -> "  " ^ summarize_signal s) r.beta.signals))
    (String.concat "\n" (List.map (fun s -> "  " ^ summarize_signal s) r.gamma.signals))
