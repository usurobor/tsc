(** Mechanical scoring: deterministic structural proxies over a bundle.

    No LLM calls. No network I/O. No Markdown AST parser.
    Identical [Bundle.t] + identical [config] → identical [result]. *)

open Types

(* ------------------------------------------------------------------ *)
(* Type definitions — must match mechanical_scoring.mli exactly. *)

type axis = [ `Alpha | `Beta | `Gamma ]
type evidence_kind = [ `Structural_proxy ]

type signal = {
  code     : string;
  label    : string;
  weight   : float;
  score    : float;
  evidence : string list;
}

type diagnostic_level = [ `Info | `Warning | `Error ]

type diagnostic = {
  level   : diagnostic_level;
  code    : string;
  message : string;
  paths   : string list;
}

type axis_result = {
  axis                : axis;
  score               : float;
  evidence_kind       : evidence_kind;
  signals             : signal list;
  summary             : string;
  unresolved_ambiguity: string list;
}

(** Canonical v3.2 aggregate record carried on every mechanical result.
    Sourced from [Coherence.aggregate]; never computed inline. *)
type aggregate = {
  c_sigma_math           : float;
  c_sigma_num            : float;
  epsilon                : float;
  zero_component_present : bool;
  numeric_floor_applied  : bool;
}

type result = {
  mode            : [ `Mechanical ];
  target          : string option;
  alpha           : axis_result;
  beta            : axis_result;
  gamma           : axis_result;
  aggregate       : aggregate;
  bottleneck_axis : axis;
  confidence      : float;
  diagnostics     : diagnostic list;
}

type weights = {
  alpha : float;
  beta  : float;
  gamma : float;
}

type alpha_config = {
  terminology_consistency      : float;
  repeated_structure           : float;
  duplicate_definition_tension : float;
  naming_drift                 : float;
}

type beta_config = {
  cross_reference_consistency : float;
  authority_alignment         : float;
  source_of_truth_alignment   : float;
  target_file_fit             : float;
}

type gamma_config = {
  canonical_generated_distinction : float;
  version_surface_consistency     : float;
  traceability_presence           : float;
  authority_evolution_consistency : float;
}

type config = {
  weights             : weights;
  alpha               : alpha_config;
  beta                : beta_config;
  gamma               : gamma_config;
  min_confidence_files: int;
  max_excerpt_chars   : int;
}

type comparison = {
  old_result          : result;
  new_result          : result;
  delta_alpha         : float;
  delta_beta          : float;
  delta_gamma         : float;
  delta_c_sigma_math  : float;
  delta_c_sigma_num   : float;
  changed_bottleneck  : bool;
  summary             : string;
}

(* ------------------------------------------------------------------ *)
(* Default configuration *)

let default_config : config = {
  weights = ({ alpha = 1.0; beta = 1.0; gamma = 1.0 } : weights);
  alpha = {
    terminology_consistency      = 0.40;
    repeated_structure           = 0.25;
    duplicate_definition_tension = 0.20;
    naming_drift                 = 0.15;
  };
  beta = {
    cross_reference_consistency = 0.35;
    authority_alignment         = 0.30;
    source_of_truth_alignment   = 0.20;
    target_file_fit             = 0.15;
  };
  gamma = {
    canonical_generated_distinction = 0.30;
    version_surface_consistency     = 0.30;
    traceability_presence           = 0.25;
    authority_evolution_consistency = 0.15;
  };
  min_confidence_files = 3;
  max_excerpt_chars    = 200;
}

(* ------------------------------------------------------------------ *)
(* Utility *)

let clamp01 x = Float.max 0.0 (Float.min 1.0 x)

let weighted_avg (pairs : (float * float) list) =
  let tw, twv =
    List.fold_left (fun (a, b) (w, v) -> (a +. w, b +. w *. v)) (0.0, 0.0) pairs
  in
  if tw = 0.0 then 0.5 else clamp01 (twv /. tw)

let split_lines s = String.split_on_char '\n' s

let str_lower s =
  String.map (fun c ->
    if c >= 'A' && c <= 'Z' then Char.chr (Char.code c + 32) else c
  ) s

let str_starts_with prefix s =
  let pl = String.length prefix and sl = String.length s in
  pl <= sl && String.sub s 0 pl = prefix

let truncate max_len s =
  if String.length s <= max_len then s
  else String.sub s 0 (max 0 (max_len - 3)) ^ "..."

(** Find needle in haystack; both already lowercase. *)
let str_contains needle haystack =
  let nl = String.length needle and hl = String.length haystack in
  if nl = 0 then true
  else if nl > hl then false
  else begin
    let found = ref false and i = ref 0 in
    while !i <= hl - nl && not !found do
      if String.sub haystack !i nl = needle then found := true
      else incr i
    done;
    !found
  end

let contains_keyword kw content =
  str_contains (str_lower kw) (str_lower content)

let contains_any keywords content =
  List.exists (fun kw -> contains_keyword kw content) keywords

(** A keyword MENTION is not a keyword ACT: "deprecated" as a quoted enum
    value, or a scorer's own keyword list in a string literal, does not
    deprecate anything. An occurrence counts only when no character of the
    match sits inside a double-quote or backtick span on its line. *)
let line_has_unquoted needle line =
  let nl = String.length needle and ll = String.length line in
  if nl = 0 || nl > ll then false
  else begin
    let inside = Array.make ll false in
    let in_dq = ref false and in_bt = ref false in
    String.iteri (fun i c ->
      (match c with
       | '"' -> in_dq := not !in_dq
       | '`' -> in_bt := not !in_bt
       | _ -> ());
      inside.(i) <- !in_dq || !in_bt) line;
    let found = ref false and i = ref 0 in
    while !i <= ll - nl && not !found do
      if String.sub line !i nl = needle then begin
        let quoted = ref false in
        for j = !i to !i + nl - 1 do
          if inside.(j) then quoted := true
        done;
        if not !quoted then found := true
      end;
      incr i
    done;
    !found
  end

let contains_any_unquoted keywords content =
  let lines = String.split_on_char '\n' (str_lower content) in
  List.exists (fun kw ->
    let kw = str_lower kw in
    List.exists (line_has_unquoted kw) lines) keywords

(** A document is a Markdown file. Document-structure signals — headings,
    links, authority claims, filename fit — measure documents only: a
    markdown-shaped substring inside an OCaml string literal is not a
    cross-reference, and a `#`-prefixed code line is not a heading.
    Corpus-level signals (versions, generated markers, deprecation,
    traceability) keep scanning every file. *)
let is_document (f : bundle_file) =
  Filename.check_suffix (str_lower f.file_path) ".md"

let documents files = List.filter is_document files

(** Normalize a link target as a path relative to the linking file's
    directory, collapsing `.` and `..` segments (clamped at the bundle
    root) and stripping any `#anchor` fragment. Markdown links are
    relative to the document that carries them — raw string comparison
    mis-resolved every `../` link from a nested file. *)
let normalize_link ~src target =
  let clean =
    match String.split_on_char '#' target with p :: _ -> p | [] -> target
  in
  if clean = "" then ""
  else begin
    let base_dir = Filename.dirname src in
    let combined =
      if base_dir = "." || base_dir = "" then clean
      else base_dir ^ "/" ^ clean
    in
    let stack =
      List.fold_left (fun acc seg ->
        match seg with
        | "" | "." -> acc
        | ".."     -> (match acc with _ :: tl -> tl | [] -> acc)
        | s        -> s :: acc
      ) [] (String.split_on_char '/' combined)
    in
    String.concat "/" (List.rev stack)
  end


(** Extract (level, heading-text) pairs from Markdown headings. *)
let extract_headings content =
  List.filter_map (fun line ->
    let line = String.trim line in
    let len = String.length line in
    if len = 0 || line.[0] <> '#' then None
    else begin
      let level = ref 0 in
      while !level < len && line.[!level] = '#' do incr level done;
      if !level = 0 || !level > 6 then None
      else
        let rest = String.trim (String.sub line !level (len - !level)) in
        if String.length rest = 0 then None
        else Some (!level, rest)
    end
  ) (split_lines content)

(** Extract [text](target) link targets via single-pass scan. *)
let extract_md_links content =
  let len = String.length content in
  let links = ref [] in
  let i = ref 0 in
  while !i < len - 3 do
    if content.[!i] = '[' then begin
      let j = ref (!i + 1) in
      while !j < len && content.[!j] <> ']' && content.[!j] <> '\n' do incr j done;
      if !j < len && content.[!j] = ']'
         && !j + 1 < len && content.[!j + 1] = '(' then begin
        let k = ref (!j + 2) in
        while !k < len && content.[!k] <> ')' && content.[!k] <> '\n' do incr k done;
        if !k < len && content.[!k] = ')' then begin
          links := String.sub content (!j + 2) (!k - !j - 2) :: !links;
          i := !k + 1
        end else incr i
      end else incr i
    end else incr i
  done;
  !links

(** Extract X.Y.Z version strings from content. A match with a '/'
    immediately adjacent is a path segment (a reference to a versioned
    directory, e.g. path/to/0.1.0/README.md), not a version
    claim, and is skipped. *)
let extract_versions content =
  let len = String.length content in
  let versions = ref [] in
  let i = ref 0 in
  while !i < len do
    if content.[!i] >= '0' && content.[!i] <= '9' then begin
      let start = !i in
      while !i < len && content.[!i] >= '0' && content.[!i] <= '9' do incr i done;
      if !i < len && content.[!i] = '.' then begin
        incr i;
        let ms = !i in
        while !i < len && content.[!i] >= '0' && content.[!i] <= '9' do incr i done;
        if !i - ms > 0 && !i < len && content.[!i] = '.' then begin
          incr i;
          let es = !i in
          while !i < len && content.[!i] >= '0' && content.[!i] <= '9' do incr i done;
          let path_adjacent =
            (start > 0 && content.[start - 1] = '/')
            || (!i < len && content.[!i] = '/')
          in
          if !i - es > 0 && not path_adjacent then
            versions := String.sub content start (!i - start) :: !versions
        end
      end
    end else
      incr i
  done;
  !versions

let is_internal_link target =
  String.length target > 0
  && not (str_starts_with "http" target)
  && not (str_starts_with "mailto" target)
  && not (str_starts_with "#" target)
  && not (str_starts_with "ftp" target)

(** GitHub-style anchor slug for a heading: lowercase, spaces to dashes,
    alphanumerics/dashes/underscores kept, everything else dropped. *)
let slugify heading =
  let b = Buffer.create (String.length heading) in
  String.iter (fun c ->
    let c = if c >= 'A' && c <= 'Z' then Char.chr (Char.code c + 32) else c in
    if (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c = '-' || c = '_'
    then Buffer.add_char b c
    else if c = ' ' then Buffer.add_char b '-'
  ) heading;
  Buffer.contents b

(** (path, heading slugs) for every document — the anchor-resolution map. *)
let doc_slug_map files =
  List.map (fun f ->
    (f.file_path,
     List.map (fun (_, text) -> slugify text) (extract_headings f.file_content)))
    (documents files)

(** A normalized link resolves when it names a bundle file exactly or is a
    directory prefix of one (directory links are valid tree references).
    When the link carries a #fragment and its target is a document in the
    bundle, the fragment must match one of that document's heading slugs —
    an anchor naming a heading the target does not have is a broken
    cross-reference (and, across files, a contradiction fingerprint:
    two documents citing the same section under different names cannot
    both be describing the same system). *)
let link_resolves ~bundle_paths ~doc_slugs ~src target =
  let fragment =
    match String.split_on_char '#' target with
    | _ :: frag :: _ -> frag
    | _ -> ""
  in
  let norm = normalize_link ~src target in
  if norm = "" then true  (* pure #anchor links are same-document *)
  else
    let file_match = List.exists (fun p -> p = norm) bundle_paths in
    let dir_match =
      List.exists (fun p -> str_starts_with (norm ^ "/") p) bundle_paths
    in
    if not (file_match || dir_match) then false
    else if fragment = "" || not file_match then true
    else
      match List.assoc_opt norm doc_slugs with
      | None -> true  (* fragment into a non-document: cannot validate *)
      | Some slugs -> List.mem (str_lower fragment) slugs

(** Compute axis score as weighted average of signal scores. *)
let axis_score_of_signals (sigs : signal list) =
  weighted_avg (List.map (fun s -> (s.weight, s.score)) sigs)

(* ------------------------------------------------------------------ *)
(* Alpha signals *)

(** Signal: Terminology consistency — heading phrase casing across files. *)
let sig_terminology_consistency ~cfg (files : bundle_file list) : signal =
  let all_headings =
    List.concat_map (fun f ->
      List.map snd (extract_headings f.file_content)
    ) files
  in
  if all_headings = [] then
    { code = "alpha.terminology_consistency";
      label = "Terminology consistency";
      weight = cfg.alpha.terminology_consistency;
      score = 1.0;
      evidence = ["No headings found — neutral"] }
  else begin
    let tbl : (string, string list) Hashtbl.t = Hashtbl.create 64 in
    List.iter (fun h ->
      let key = str_lower h in
      let forms = match Hashtbl.find_opt tbl key with
        | None -> [h]
        | Some fs -> if List.mem h fs then fs else h :: fs
      in
      Hashtbl.replace tbl key forms
    ) all_headings;
    let inconsistent = Hashtbl.fold (fun _ forms acc ->
      if List.length forms > 1 then forms :: acc else acc
    ) tbl [] in
    let total = Hashtbl.length tbl in
    let n_inc = List.length inconsistent in
    let score = clamp01 (1.0 -. float_of_int n_inc /. float_of_int (max 1 total)) in
    let evidence =
      if n_inc = 0 then
        [Printf.sprintf "All %d heading phrases consistent" total]
      else
        List.filteri (fun i _ -> i < 3) inconsistent
        |> List.map (fun forms ->
          truncate 120 ("Casing drift: " ^ String.concat " vs " forms))
    in
    { code = "alpha.terminology_consistency";
      label = "Terminology consistency";
      weight = cfg.alpha.terminology_consistency;
      score;
      evidence }
  end

(** Signal: Repeated structure — fraction of content files with an H1. *)
let sig_repeated_structure ~cfg (files : bundle_file list) : signal =
  let file_headings =
    List.filter_map (fun f ->
      let h = extract_headings f.file_content in
      if h = [] then None else Some (f.file_path, h)
    ) files
  in
  if file_headings = [] then
    { code = "alpha.repeated_structure"; label = "Repeated structure";
      weight = cfg.alpha.repeated_structure; score = 0.7;
      evidence = ["No files with headings"] }
  else begin
    let with_h1 = List.filter (fun (_, h) ->
      List.exists (fun (lvl, _) -> lvl = 1) h
    ) file_headings in
    let total = List.length file_headings in
    let n_h1 = List.length with_h1 in
    let score = clamp01 (float_of_int n_h1 /. float_of_int total) in
    { code = "alpha.repeated_structure"; label = "Repeated structure";
      weight = cfg.alpha.repeated_structure;
      score;
      evidence = [Printf.sprintf "%d/%d files with headings have an H1" n_h1 total] }
  end

(** Signal: Duplicate definition tension — heading phrases in >1 file. *)
let sig_duplicate_definition_tension ~cfg (files : bundle_file list) : signal =
  let heading_file_count : (string, int) Hashtbl.t = Hashtbl.create 64 in
  List.iter (fun f ->
    let seen : (string, unit) Hashtbl.t = Hashtbl.create 16 in
    List.iter (fun (_, text) ->
      let key = str_lower text in
      if not (Hashtbl.mem seen key) then begin
        Hashtbl.add seen key ();
        let n = Option.value ~default:0 (Hashtbl.find_opt heading_file_count key) in
        Hashtbl.replace heading_file_count key (n + 1)
      end
    ) (extract_headings f.file_content)
  ) files;
  let total = Hashtbl.length heading_file_count in
  if total = 0 then
    { code = "alpha.duplicate_definition_tension"; label = "Duplicate definition tension";
      weight = cfg.alpha.duplicate_definition_tension; score = 1.0;
      evidence = ["No headings to compare"] }
  else begin
    let duplicates = Hashtbl.fold (fun key n acc ->
      if n > 1 then (key, n) :: acc else acc
    ) heading_file_count [] in
    let n_dup = List.length duplicates in
    (* Light penalty — some cross-file heading repetition is expected. *)
    let score = clamp01 (1.0 -. float_of_int n_dup /. float_of_int total *. 0.5) in
    let evidence =
      if n_dup = 0 then ["No duplicate heading phrases across files"]
      else
        List.filteri (fun i _ -> i < 3) duplicates
        |> List.map (fun (key, n) ->
          truncate 120 (Printf.sprintf "'%s' in %d files" key n))
    in
    { code = "alpha.duplicate_definition_tension"; label = "Duplicate definition tension";
      weight = cfg.alpha.duplicate_definition_tension;
      score;
      evidence }
  end

(** Signal: Naming drift — mixed snake_case vs camelCase in heading words. *)
let sig_naming_drift ~cfg (files : bundle_file list) : signal =
  let is_snake s = String.contains s '_' in
  let has_upper_after_lower s =
    let len = String.length s in
    let had_lower = ref false and found = ref false in
    for i = 0 to len - 1 do
      let c = s.[i] in
      if c >= 'a' && c <= 'z' then had_lower := true
      else if c >= 'A' && c <= 'Z' && !had_lower then found := true
    done;
    !found
  in
  (* Parenthesized words are quoted vocabulary ("Grounding Witness
     (GroundingCertificate)" defines a formal name); quoting a name is
     not adopting a heading naming convention. Hyphenated Title-Case
     ("Self-Measure", "Post-Release") is prose, not camelCase — split on
     '-' before classifying. *)
  let is_quoted w = String.contains w '(' || String.contains w ')' in
  let snake = ref 0 and camel = ref 0 in
  List.iter (fun f ->
    List.iter (fun (_, text) ->
      String.split_on_char ' ' text |> List.iter (fun w ->
        if is_quoted w then ()
        else if is_snake w then incr snake
        else if List.exists has_upper_after_lower (String.split_on_char '-' w)
        then incr camel)
    ) (extract_headings f.file_content)
  ) files;
  let total = !snake + !camel in
  if total < 5 then
    (* Fewer than five identifier tokens across all headings cannot
       establish a naming convention, let alone drift from one. *)
    { code = "alpha.naming_drift"; label = "Naming drift";
      weight = cfg.alpha.naming_drift; score = 1.0;
      evidence =
        [Printf.sprintf
           "%d identifier token(s) in headings — too few to assess drift"
           total] }
  else begin
    let majority = Float.max (float_of_int !snake) (float_of_int !camel) in
    let score = clamp01 (majority /. float_of_int total) in
    { code = "alpha.naming_drift"; label = "Naming drift";
      weight = cfg.alpha.naming_drift;
      score;
      evidence = [Printf.sprintf "snake_case: %d, camelCase: %d" !snake !camel] }
  end

(* ------------------------------------------------------------------ *)
(* Beta signals *)

(** Signal: Cross-reference consistency — link resolution rate over the
    bundle's documents. Links normalize relative to their source document. *)
let sig_cross_reference_consistency ~cfg (files : bundle_file list) : signal =
  let bundle_paths = List.map (fun f -> f.file_path) files in
  let doc_slugs = doc_slug_map files in
  let all_links =
    List.concat_map (fun f ->
      extract_md_links f.file_content
      |> List.filter is_internal_link
      |> List.map (fun target -> (f.file_path, target))
    ) (documents files)
  in
  if all_links = [] then
    { code = "beta.cross_reference_consistency"; label = "Cross-reference consistency";
      weight = cfg.beta.cross_reference_consistency; score = 1.0;
      evidence = ["No internal links found"] }
  else begin
    let broken =
      List.filter
        (fun (src, t) -> not (link_resolves ~bundle_paths ~doc_slugs ~src t))
        all_links
    in
    let n_total = List.length all_links in
    let n_broken = List.length broken in
    let score = clamp01 (1.0 -. float_of_int n_broken /. float_of_int n_total) in
    let evidence =
      if n_broken = 0 then
        [Printf.sprintf "All %d internal links resolve" n_total]
      else
        [Printf.sprintf "%d/%d links unresolved" n_broken n_total]
        @ (List.filteri (fun i _ -> i < 3) broken
           |> List.map (fun (src, t) -> Printf.sprintf "%s -> %s" src t))
    in
    { code = "beta.cross_reference_consistency"; label = "Cross-reference consistency";
      weight = cfg.beta.cross_reference_consistency;
      score;
      evidence }
  end

(** Signal: Authority alignment — documents CLAIMING authority for
    themselves. Self-claim phrases only: a document that points at the
    canonical source ("spec/ is canonical") is coordinating, not
    contesting — only competing self-claims signal authority confusion.
    Emphasis markers are stripped before matching so "this file is the
    **canonical** definition" is recognized as the self-claim it is.
    One self-claimant is the ideal shape; two or more is a direct
    contest — the strongest structural contradiction mechanical scoring
    can detect — and is penalized steeply. *)
let sig_authority_alignment ~cfg (files : bundle_file list) : signal =
  let strip_emphasis s =
    let b = Buffer.create (String.length s) in
    String.iter (fun c ->
      if c <> '*' && c <> '_' && c <> '`' then Buffer.add_char b c) s;
    Buffer.contents b
  in
  let self_claim_kws =
    ["this is canonical"; "this is the canonical";
     "this document is canonical"; "this document is the canonical";
     "this file is canonical"; "this file is the canonical";
     "this spec is canonical"; "this spec is the canonical";
     "governs on disagreement";
     "is the source of truth"; "is authoritative"] in
  let files_with_authority = List.filter (fun f ->
    contains_any self_claim_kws (strip_emphasis f.file_content)
  ) (documents files) in
  let n = List.length files_with_authority in
  (* 0 self-claims = clean; 1 = ideal (one named authority);
     >= 2 = contested authority, steep penalty per extra claimant. *)
  let score =
    if n = 0 then 1.0
    else if n = 1 then 0.95
    else clamp01 (0.5 -. 0.15 *. float_of_int (n - 2))
  in
  let evidence =
    if n = 0 then ["No authority self-claims found — clean surface"]
    else
      [Printf.sprintf "%d documents self-claim authority" n]
      @ List.filteri (fun i _ -> i < 3) (List.map (fun f -> f.file_path) files_with_authority)
  in
  { code = "beta.authority_alignment"; label = "Authority alignment";
    weight = cfg.beta.authority_alignment;
    score;
    evidence }

(** Signal: Source-of-truth alignment — fraction of documents-with-links
    whose reference set is FULLY grounded in the bundle. Complements
    cross_reference_consistency (per-link rate) at document granularity:
    one document scattering half-broken references hurts more than the
    same broken links spread across many otherwise-grounded documents. *)
let sig_source_of_truth_alignment ~cfg (files : bundle_file list) : signal =
  let bundle_paths = List.map (fun f -> f.file_path) files in
  let doc_slugs = doc_slug_map files in
  let per_doc =
    List.filter_map (fun f ->
      let links =
        List.filter is_internal_link (extract_md_links f.file_content)
      in
      if links = [] then None
      else
        Some (f.file_path,
              List.for_all
                (fun t ->
                   link_resolves ~bundle_paths ~doc_slugs ~src:f.file_path t)
                links)
    ) (documents files)
  in
  if per_doc = [] then
    { code = "beta.source_of_truth_alignment"; label = "Source-of-truth alignment";
      weight = cfg.beta.source_of_truth_alignment; score = 1.0;
      evidence = ["No internal cross-references found"] }
  else begin
    let n_total = List.length per_doc in
    let n_grounded = List.length (List.filter snd per_doc) in
    let score = clamp01 (float_of_int n_grounded /. float_of_int n_total) in
    let evidence =
      [Printf.sprintf "%d/%d linking documents fully grounded in bundle"
         n_grounded n_total]
      @ (List.filter (fun (_, ok) -> not ok) per_doc
         |> List.filteri (fun i _ -> i < 3)
         |> List.map fst)
    in
    { code = "beta.source_of_truth_alignment"; label = "Source-of-truth alignment";
      weight = cfg.beta.source_of_truth_alignment;
      score;
      evidence }
  end

(** Signal: Target–file fit — H1 heading words overlap with the filename
    stem. Documents only. Words match on equality or prefix (>= 3 chars
    each way) so abbreviated stems fit their expansions ("equiv" /
    "equivalence"). README and SKILL.md title their DIRECTORY by
    convention, so their H1s compare against the directory words; the
    repo-root README titles the whole corpus and always fits. *)
let sig_target_file_fit ~cfg (files : bundle_file list) : signal =
  let words_of s =
    str_lower s
    |> String.map (fun c -> if c = '-' || c = '_' || c = '/' then ' ' else c)
    |> String.split_on_char ' '
    |> List.filter (fun w -> String.length w > 2)
  in
  let word_match a b =
    a = b || str_starts_with a b || str_starts_with b a
  in
  let scored = List.filter_map (fun f ->
    let headings = extract_headings f.file_content in
    match List.find_opt (fun (lvl, _) -> lvl = 1) headings with
    | None -> None
    | Some (_, h1) ->
      let stem =
        str_lower (Filename.remove_extension (Filename.basename f.file_path))
      in
      let h1_words = words_of h1 in
      let against words =
        List.exists (fun w -> List.exists (word_match w) words) h1_words
      in
      let overlap =
        if stem = "readme" || stem = "skill" then
          match words_of (Filename.dirname f.file_path) with
          | [] -> true  (* repo-root README titles the corpus *)
          | dir_words -> against dir_words
        else against (words_of stem)
      in
      Some overlap
  ) (documents files) in
  if scored = [] then
    { code = "beta.target_file_fit"; label = "Target-file fit";
      weight = cfg.beta.target_file_fit; score = 0.7;
      evidence = ["No files with H1 headings"] }
  else begin
    let n_fit   = List.length (List.filter Fun.id scored) in
    let n_total = List.length scored in
    let score = clamp01 (float_of_int n_fit /. float_of_int n_total) in
    { code = "beta.target_file_fit"; label = "Target-file fit";
      weight = cfg.beta.target_file_fit;
      score;
      evidence = [Printf.sprintf "%d/%d files have H1 words matching filename" n_fit n_total] }
  end

(* ------------------------------------------------------------------ *)
(* Gamma signals *)

(** Signal: Canonical/generated distinction. Explicitly marking generated
    artifacts (DO-NOT-EDIT headers) is the γ virtue this signal wants —
    never penalized. The risk case is inversion: when generated markers
    saturate the corpus, the canonical surface is too thin to own change. *)
let sig_canonical_generated_distinction ~cfg (files : bundle_file list) : signal =
  let gen_kws = ["generated"; "do not edit"; "auto-generated"; "automatically generated"] in
  (* A generated-file marker is a HEADER property: it lives in the first
     few lines. A document that merely discusses the DO-NOT-EDIT
     convention in prose is not a generated artifact. *)
  let header f =
    let rec take n = function
      | l :: rest when n > 0 -> l :: take (n - 1) rest
      | _ -> []
    in
    String.concat "\n" (take 5 (split_lines f.file_content))
  in
  let marked = List.filter (fun f -> contains_any gen_kws (header f)) files in
  let n_marked = List.length marked in
  let n_total  = List.length files in
  let density =
    if n_total = 0 then 0.0
    else float_of_int n_marked /. float_of_int n_total
  in
  let score =
    if density <= 0.3 then 1.0
    else clamp01 (1.0 -. (density -. 0.3))
  in
  let evidence =
    if n_marked = 0 then ["No generated-file markers — clean canonical surface"]
    else
      [Printf.sprintf
         "%d/%d files carry generated-file markers (distinction explicit)"
         n_marked n_total]
  in
  { code = "gamma.canonical_generated_distinction"; label = "Canonical/generated distinction";
    weight = cfg.gamma.canonical_generated_distinction;
    score;
    evidence }

(** Signal: Version surface consistency — X.Y.Z uniformity across files. *)
let sig_version_surface_consistency ~cfg (files : bundle_file list) : signal =
  let all_versions =
    List.concat_map (fun f -> extract_versions f.file_content) files
  in
  if all_versions = [] then
    { code = "gamma.version_surface_consistency"; label = "Version surface consistency";
      weight = cfg.gamma.version_surface_consistency; score = 0.7;
      evidence = ["No version strings found"] }
  else begin
    let unique = List.sort_uniq String.compare all_versions in
    let n_unique = List.length unique in
    let n_total  = List.length all_versions in
    let score =
      if n_unique = 1 then 1.0
      else clamp01 (1.0 -. float_of_int (n_unique - 1) /. float_of_int (max 1 n_total))
    in
    { code = "gamma.version_surface_consistency"; label = "Version surface consistency";
      weight = cfg.gamma.version_surface_consistency;
      score;
      evidence =
        [Printf.sprintf "%d version occurrences, %d unique: %s"
           n_total n_unique (String.concat ", " (List.filteri (fun i _ -> i < 5) unique))] }
  end

(** Signal: Traceability presence — issue refs, changelog, commit SHAs.
    Corpus-level property with saturation: traceability holds when a
    meaningful share of files (one per ten, minimum one) carries markers.
    A raw per-file fraction would reward spraying "changelog" into every
    file — ritual, not traceability. *)
let sig_traceability_presence ~cfg (files : bundle_file list) : signal =
  let trace_kws = ["changelog"; "closes #"; "fixes #"; "issue #"] in
  let files_with_trace = List.filter (fun f ->
    contains_any trace_kws f.file_content
  ) files in
  let n = List.length files_with_trace in
  let n_total = List.length files in
  let threshold = max 1 (n_total / 10) in
  let score =
    if n_total = 0 then 1.0
    else if n = 0 then 0.5
    else clamp01 (float_of_int n /. float_of_int threshold)
  in
  { code = "gamma.traceability_presence"; label = "Traceability presence";
    weight = cfg.gamma.traceability_presence;
    score;
    evidence =
      if n = 0 then ["No traceability markers found"]
      else
        [Printf.sprintf
           "%d/%d files contain traceability markers (saturation threshold %d)"
           n n_total threshold] }

(** Signal: Authority evolution consistency — deprecation-language density
    over LIVING surfaces. An isolated supersession note is normal
    evolution (explicit change paths are a γ virtue); supersession
    language saturating the living corpus is transitional ambiguity — too
    much of the bundle is busy replacing itself to say what is current.
    Ledger and archive surfaces (changelogs; frozen X.Y.Z version
    directories) exist to record supersession — deprecation language
    there is the system working, not ambiguity. *)
let sig_authority_evolution_consistency ~cfg (files : bundle_file list) : signal =
  let is_version_segment s =
    s <> ""
    && String.for_all (fun c -> (c >= '0' && c <= '9') || c = '.') s
    && String.contains s '.'
  in
  let is_ledger_or_archive f =
    let path = str_lower f.file_path in
    str_contains "changelog" path
    || List.exists is_version_segment (String.split_on_char '/' path)
  in
  let dep_kws = ["deprecated"; "superseded"; "replaced by"; "moved to"; "use instead"] in
  let living = List.filter (fun f -> not (is_ledger_or_archive f)) files in
  let files_with_dep =
    List.filter (fun f -> contains_any_unquoted dep_kws f.file_content) living
  in
  let n = List.length files_with_dep in
  let n_total = List.length living in
  let score =
    if n = 0 then 1.0
    else if n = 1 then 0.95
    else
      let density = float_of_int n /. float_of_int (max 1 n_total) in
      clamp01 (1.0 -. Float.min 0.5 (2.0 *. density))
  in
  { code = "gamma.authority_evolution_consistency"; label = "Authority evolution consistency";
    weight = cfg.gamma.authority_evolution_consistency;
    score;
    evidence =
      if n = 0 then ["No deprecation language found — clean evolution surface"]
      else [Printf.sprintf "%d/%d files contain deprecation/supersession language" n n_total] }

(* ------------------------------------------------------------------ *)
(* Axis scoring *)

let score_alpha ~config files =
  (* Heading-based signals measure documents; see [is_document]. *)
  let docs = documents files in
  let sigs = [
    sig_terminology_consistency      ~cfg:config docs;
    sig_repeated_structure           ~cfg:config docs;
    sig_duplicate_definition_tension ~cfg:config docs;
    sig_naming_drift                 ~cfg:config docs;
  ] in
  let s = axis_score_of_signals sigs in
  ({ axis = `Alpha;
     score = s;
     evidence_kind = `Structural_proxy;
     signals = sigs;
     summary = Printf.sprintf "α structural-proxy score: %.3f" s;
     unresolved_ambiguity = [] } : axis_result)

let score_beta ~config files =
  let sigs = [
    sig_cross_reference_consistency ~cfg:config files;
    sig_authority_alignment         ~cfg:config files;
    sig_source_of_truth_alignment   ~cfg:config files;
    sig_target_file_fit             ~cfg:config files;
  ] in
  let s = axis_score_of_signals sigs in
  ({ axis = `Beta;
     score = s;
     evidence_kind = `Structural_proxy;
     signals = sigs;
     summary = Printf.sprintf "β structural-proxy score: %.3f" s;
     unresolved_ambiguity = [] } : axis_result)

let score_gamma ~config files =
  let sigs = [
    sig_canonical_generated_distinction  ~cfg:config files;
    sig_version_surface_consistency      ~cfg:config files;
    sig_traceability_presence            ~cfg:config files;
    sig_authority_evolution_consistency  ~cfg:config files;
  ] in
  let s = axis_score_of_signals sigs in
  ({ axis = `Gamma;
     score = s;
     evidence_kind = `Structural_proxy;
     signals = sigs;
     summary = Printf.sprintf "γ structural-proxy score: %.3f" s;
     unresolved_ambiguity = [] } : axis_result)

(* ------------------------------------------------------------------ *)
(* Top-level scoring *)

(** Canonical aggregate epsilon — routes to [Coherence.epsilon_default]. *)
let aggregate_epsilon = Coherence.epsilon_default

(** Compute the canonical v3.2 aggregate from the three axis results.
    Routes through [Coherence.aggregate]; never computes an arithmetic mean.

    Note: [config.weights] is intentionally ignored for the headline cross-axis
    aggregate — spec/tsc-core.md §5 defines a single S3-invariant geometric form.
    Axis-internal signal weighting (the [weighted_avg] of per-signal scores)
    remains intact in [axis_score_of_signals]. *)
let compute_aggregate ~config:_ (a : axis_result) (b : axis_result) (g : axis_result) =
  let r = Coherence.aggregate
    ~epsilon:aggregate_epsilon
    ~s_alpha:a.score
    ~s_beta:b.score
    ~s_gamma:g.score
    ()
  in
  { c_sigma_math           = r.c_sigma_math;
    c_sigma_num            = r.c_sigma_num;
    epsilon                = r.epsilon;
    zero_component_present = r.zero_component_present;
    numeric_floor_applied  = r.numeric_floor_applied }

let compute_bottleneck (a : axis_result) (b : axis_result) (g : axis_result) =
  if a.score <= b.score && a.score <= g.score then `Alpha
  else if b.score <= g.score then `Beta
  else `Gamma

let compute_confidence ~config (files : bundle_file list) =
  let n = List.length files in
  if n = 0 then 0.0
  else clamp01 (float_of_int n /. float_of_int (max 1 config.min_confidence_files))

let score_files ?(config = default_config) (files : Bundle.file list) =
  let a = score_alpha ~config files in
  let b = score_beta  ~config files in
  let g = score_gamma ~config files in
  ({ mode            = `Mechanical;
     target          = None;
     alpha           = a;
     beta            = b;
     gamma           = g;
     aggregate       = compute_aggregate ~config a b g;
     bottleneck_axis = compute_bottleneck a b g;
     confidence      = compute_confidence ~config files;
     diagnostics     = [] } : result)

let score_bundle ?(config = default_config) (bundle : Bundle.t) =
  let r = score_files ~config bundle.bundle_files in
  { r with target = Some bundle.bundle_target_name }

let compare ?(config = default_config) ~old_ ~new_ =
  let old_result = score_bundle ~config old_ in
  let new_result = score_bundle ~config new_ in
  let da = new_result.alpha.score -. old_result.alpha.score in
  let db = new_result.beta.score  -. old_result.beta.score  in
  let dg = new_result.gamma.score -. old_result.gamma.score in
  let dcm = new_result.aggregate.c_sigma_math -. old_result.aggregate.c_sigma_math in
  let dcn = new_result.aggregate.c_sigma_num  -. old_result.aggregate.c_sigma_num  in
  { old_result;
    new_result;
    delta_alpha         = da;
    delta_beta          = db;
    delta_gamma         = dg;
    delta_c_sigma_math  = dcm;
    delta_c_sigma_num   = dcn;
    changed_bottleneck  = old_result.bottleneck_axis <> new_result.bottleneck_axis;
    summary             =
      Printf.sprintf
        "Δα=%.3f Δβ=%.3f Δγ=%.3f ΔC_Σ^math=%.3f ΔC_Σ^num=%.3f"
        da db dg dcm dcn }

(* ------------------------------------------------------------------ *)
(* JSON serialization *)

let axis_str = function `Alpha -> "alpha" | `Beta -> "beta" | `Gamma -> "gamma"
let level_str = function `Info -> "info" | `Warning -> "warning" | `Error -> "error"

let signal_to_json (s : signal) =
  `Assoc [
    ("code",     `String s.code);
    ("label",    `String s.label);
    ("weight",   `Float  s.weight);
    ("score",    `Float  s.score);
    ("evidence", `List (List.map (fun e -> `String e) s.evidence));
  ]

let axis_result_to_json (ar : axis_result) =
  `Assoc [
    ("axis",                 `String (axis_str ar.axis));
    ("score",                `Float  ar.score);
    ("evidence_kind",        `String "structural-proxy");
    ("signals",              `List (List.map signal_to_json ar.signals));
    ("summary",              `String ar.summary);
    ("unresolved_ambiguity", `List (List.map (fun s -> `String s) ar.unresolved_ambiguity));
  ]

let diagnostic_to_json (d : diagnostic) =
  `Assoc [
    ("level",   `String (level_str d.level));
    ("code",    `String d.code);
    ("message", `String d.message);
    ("paths",   `List (List.map (fun p -> `String p) d.paths));
  ]

(** Build the canonical v3.2 provenance JSON for a mechanical result.
    Routes through [Coherence.aggregate] (already invoked during scoring) and
    [Coherence.gauge_witness] with a [c_sigma_fn] built from the same helper —
    so the W2 fields are computed against the canonical aggregate, never an
    arithmetic surrogate. *)
let provenance_to_json (r : result) =
  let agg = r.aggregate in
  let c_sigma_fn sa sb sg =
    let r' = Coherence.aggregate
      ~epsilon:agg.epsilon
      ~s_alpha:sa ~s_beta:sb ~s_gamma:sg ()
    in
    r'.c_sigma_math
  in
  let gw = Coherence.gauge_witness
    ~labeled:(r.alpha.score, r.beta.score, r.gamma.score)
    ~c_sigma_fn
    ~tau_gauge_spread:0.05
  in
  Coherence.provenance_json
    ~c_sigma_math:(Some agg.c_sigma_math)
    ~zero_component_present:agg.zero_component_present
    ~c_sigma_num:(Some agg.c_sigma_num)
    ~epsilon:(Some agg.epsilon)
    ~numeric_floor_applied:agg.numeric_floor_applied
    ~w_gauge_ref:(Some gw.w_gauge_ref)
    ~w_gauge_spread:(Some gw.w_gauge_spread)
    ~tau_gauge_spread:(Some gw.tau_gauge_spread)
    ~canonical_remap_procedure:(Some gw.canonical_remap_procedure)
    ()

let result_to_json (r : result) =
  `Assoc [
    ("mode",            `String "mechanical");
    ("target",          (match r.target with None -> `Null | Some t -> `String t));
    ("alpha",           `Float r.alpha.score);
    ("beta",            `Float r.beta.score);
    ("gamma",           `Float r.gamma.score);
    ("bottleneck_axis", `String (axis_str r.bottleneck_axis));
    ("confidence",      `Float r.confidence);
    ("evidence_kind",   `String "structural-proxy");
    ("axis_detail", `Assoc [
      ("alpha", axis_result_to_json r.alpha);
      ("beta",  axis_result_to_json r.beta);
      ("gamma", axis_result_to_json r.gamma);
    ]);
    ("diagnostics", `List (List.map diagnostic_to_json r.diagnostics));
    ("provenance", provenance_to_json r);
  ]

let comparison_to_json (c : comparison) =
  `Assoc [
    ("old_result",         result_to_json c.old_result);
    ("new_result",         result_to_json c.new_result);
    ("delta_alpha",        `Float c.delta_alpha);
    ("delta_beta",         `Float c.delta_beta);
    ("delta_gamma",        `Float c.delta_gamma);
    ("delta_c_sigma_math", `Float c.delta_c_sigma_math);
    ("delta_c_sigma_num",  `Float c.delta_c_sigma_num);
    ("changed_bottleneck", `Bool  c.changed_bottleneck);
    ("summary",            `String c.summary);
  ]

let summarize_signal (s : signal) =
  Printf.sprintf "[%s] %s: %.3f" s.code s.label s.score

let summarize_result (r : result) =
  Printf.sprintf
    "mechanical: α=%.3f β=%.3f γ=%.3f C_Σ^math=%.3f C_Σ^num=%.3f bottleneck=%s confidence=%.2f"
    r.alpha.score r.beta.score r.gamma.score
    r.aggregate.c_sigma_math r.aggregate.c_sigma_num
    (axis_str r.bottleneck_axis) r.confidence
