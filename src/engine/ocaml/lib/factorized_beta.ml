(** Factorized β: deterministic locus enumeration + mechanical aggregation.

    Implements the FROZEN pre-registration
    docs/beta/governance/CONSISTENCY-FACTORIZATION-PREREG.md (rev 4):

    - the engine enumerates a deterministic, pre-witness β locus inventory
      (kills the witness's selection freedom);
    - the LLM adjudicates each RESOLVED locus with a bounded verdict
      (supports | contradicts | insufficient) — it never emits a scalar;
    - the engine counts and aggregates the verdicts into [β_factorized] by
      the pre-registered formula (kills counting/aggregation freedom).

    Pure module — no I/O, no LLM call, no network. Identical bundle -> identical
    inventory + identical locus ids. The β loci are enumerated on the exact
    mechanical anchors the scalar β signals use ({!Mechanical_scoring}
    [extract_md_links], [normalize_link], [link_resolves], [doc_slug_map],
    [slugify]); no rule invents a surface the engine does not already compute.

    The cross-sample consistency barrier is {!Coherence.phi} / the existing
    [Consistency] report over the β field — this module does NOT re-implement
    it and does NOT touch the α/γ scalar path. *)

open Types

(* ------------------------------------------------------------------ *)
(* Locus / verdict types                                              *)

(** The three allowed β locus kinds (prereg §"β locus schema"). No
    [repeated_fact], no γ/version kind. Each maps to a real mechanical
    anchor in {!Mechanical_scoring}. *)
type kind =
  | Citation_bears_claim   (* internal Markdown link + anchor resolution *)
  | Authority_claim        (* authority self-claim phrase carrying a link *)
  | Target_file_fit        (* H1 words vs filename stem (self, same file) *)

(** Two-valued (prereg §"β locus schema"): a link resolving to a
    non-document is NOT enumerated, so there is no third bucket. *)
type mechanical_status =
  | Resolved     (* readable document target; the LLM judges bearing *)
  | Unresolved   (* path/anchor does not resolve; scored d=1.0, no LLM *)

(** The bounded LLM verdict. The LLM emits exactly one of these per
    resolved locus; the engine maps it to a defect weight. *)
type verdict =
  | Supports
  | Contradicts
  | Insufficient

(** One enumerated β locus. [locus_id] is assigned by the canonical
    emission order (bundle file order -> source line -> kind order). *)
type locus = {
  locus_id          : string;
  kind              : kind;
  source_path       : string;
  source_span       : string;
  target_path       : string;
  target_span       : string;
  question          : string;
  mechanical_status : mechanical_status;
}

(* ------------------------------------------------------------------ *)
(* String / weight conversions                                        *)

let string_of_kind = function
  | Citation_bears_claim -> "citation_bears_claim"
  | Authority_claim -> "authority_claim"
  | Target_file_fit -> "target_file_fit"

let kind_of_string = function
  | "citation_bears_claim" -> Some Citation_bears_claim
  | "authority_claim" -> Some Authority_claim
  | "target_file_fit" -> Some Target_file_fit
  | _ -> None

(** Short tag embedded in a [locus_id] (prereg example: [beta.link.0007]). *)
let kind_short = function
  | Citation_bears_claim -> "link"
  | Authority_claim -> "auth"
  | Target_file_fit -> "fit"

(** Emission tie-break within a document/line: citation < authority < fit. *)
let kind_rank = function
  | Citation_bears_claim -> 0
  | Authority_claim -> 1
  | Target_file_fit -> 2

(** Per-kind weight [w] (prereg §"Aggregation formula"). *)
let kind_weight = function
  | Citation_bears_claim -> 1.0
  | Authority_claim -> 1.0
  | Target_file_fit -> 0.5

let string_of_status = function
  | Resolved -> "resolved"
  | Unresolved -> "unresolved"

let string_of_verdict = function
  | Supports -> "supports"
  | Contradicts -> "contradicts"
  | Insufficient -> "insufficient"

let verdict_of_string = function
  | "supports" -> Some Supports
  | "contradicts" -> Some Contradicts
  | "insufficient" -> Some Insufficient
  | _ -> None

(** Per-locus defect weight [d] for a resolved verdict (prereg table). *)
let defect_weight_of_verdict = function
  | Supports -> 0.0
  | Insufficient -> 0.5
  | Contradicts -> 1.0

(** The bounded adjudication question per kind. *)
let question_for = function
  | Citation_bears_claim ->
    "Does the cited target support the claim the source makes about it?"
  | Authority_claim ->
    "Does the linked target bear out the authority relationship the source \
     claims?"
  | Target_file_fit ->
    "Does the H1 heading name the same subject as the file's identity (its \
     filename stem)?"

(* ------------------------------------------------------------------ *)
(* Local string / Markdown helpers                                    *)

let split_lines s = String.split_on_char '\n' s

let lower s =
  String.map (fun c ->
    if c >= 'A' && c <= 'Z' then Char.chr (Char.code c + 32) else c) s

(** Substring search; case-insensitive (both sides lowercased). *)
let contains_sub needle hay =
  let needle = lower needle and hay = lower hay in
  let nl = String.length needle and hl = String.length hay in
  if nl = 0 then true
  else if nl > hl then false
  else begin
    let found = ref false and i = ref 0 in
    while !i <= hl - nl && not !found do
      if String.sub hay !i nl = needle then found := true else incr i
    done;
    !found
  end

(** Strip emphasis markers so "**canonical**" reads as the self-claim it
    is — mirrors [sig_authority_alignment]'s [strip_emphasis]. *)
let strip_emphasis s =
  let b = Buffer.create (String.length s) in
  String.iter (fun c ->
    if c <> '*' && c <> '_' && c <> '`' then Buffer.add_char b c) s;
  Buffer.contents b

let is_doc (f : bundle_file) = Filename.check_suffix (lower f.file_path) ".md"

let is_md_path p = Filename.check_suffix (lower p) ".md"

let starts_with pre s =
  let pl = String.length pre and sl = String.length s in
  pl <= sl && String.sub s 0 pl = pre

(** Whether a link RESOLVES TO a non-document — an existing directory or an
    existing non-[.md] file — the only internal-link exclusion the prereg
    declares (§"citation_bears_claim"): such a link has no readable
    [target_span]. A link that resolves to nothing (a broken reference) is
    NOT a non-document resolution: it is enumerated with
    [mechanical_status = unresolved] (d=1.0, no LLM). This keeps the status
    two-valued and the enumerated set faithful to the links
    [cross_reference_consistency] scores. *)
let resolves_to_non_document ~bundle_paths ~src target =
  let norm = Mechanical_scoring.normalize_link ~src target in
  if norm = "" then false  (* pure #anchor: excluded upstream by is_internal_link *)
  else
    let file_match = List.mem norm bundle_paths in
    if file_match then not (is_md_path norm)  (* existing non-.md file *)
    else List.exists (fun p -> starts_with (norm ^ "/") p) bundle_paths (* dir *)

(** Line-indexed heading parse — the exact rule of
    [Mechanical_scoring.extract_headings], but per line so we can cite the
    source/target line number the enumerator orders on. *)
let heading_of_line line =
  let line = String.trim line in
  let len = String.length line in
  if len = 0 || line.[0] <> '#' then None
  else begin
    let lvl = ref 0 in
    while !lvl < len && line.[!lvl] = '#' do incr lvl done;
    if !lvl = 0 || !lvl > 6 then None
    else
      let rest = String.trim (String.sub line !lvl (len - !lvl)) in
      if rest = "" then None else Some (!lvl, rest)
  end

(** The authority self-claim phrase set — exactly [sig_authority_alignment]'s
    (prereg §"authority_claim"). *)
let self_claim_kws =
  ["this is canonical"; "this is the canonical";
   "this document is canonical"; "this document is the canonical";
   "this file is canonical"; "this file is the canonical";
   "this spec is canonical"; "this spec is the canonical";
   "governs on disagreement";
   "is the source of truth"; "is authoritative"]

(* ------------------------------------------------------------------ *)
(* Target-span extraction (the readable side the LLM adjudicates)     *)

let truncate_span s =
  if String.length s <= 400 then s
  else String.sub s 0 397 ^ "..."

(** The heading section for [slug]: the matching heading line through the
    next heading of equal-or-higher level (prereg §"citation_bears_claim"). *)
let section_for_slug content slug =
  let target = lower slug in
  let rec find = function
    | [] -> None
    | line :: rest ->
      (match heading_of_line line with
       | Some (lvl, text) when Mechanical_scoring.slugify text = target ->
         Some (lvl, line, rest)
       | _ -> find rest)
  in
  match find (split_lines content) with
  | None -> None
  | Some (lvl, hline, rest) ->
    let body = ref [hline] in
    (try
       List.iter (fun line ->
         match heading_of_line line with
         | Some (l2, _) when l2 <= lvl -> raise Exit
         | _ -> body := line :: !body) rest
     with Exit -> ());
    Some (truncate_span (String.concat "\n" (List.rev !body)))

(** The target H1 plus its first paragraph (prereg §"citation_bears_claim"). *)
let h1_first_paragraph content =
  let rec find = function
    | [] -> None
    | line :: rest ->
      (match heading_of_line line with
       | Some (1, text) -> Some (text, rest)
       | _ -> find rest)
  in
  match find (split_lines content) with
  | None -> None
  | Some (h1, rest) ->
    let rec skip = function "" :: t -> skip t | xs -> xs in
    let para = ref [] in
    (try
       List.iter (fun line ->
         if String.trim line = "" then raise Exit
         else para := line :: !para) (skip rest)
     with Exit -> ());
    let paragraph = String.concat " " (List.rev !para) in
    Some (truncate_span
            (if paragraph = "" then "# " ^ h1 else "# " ^ h1 ^ " — " ^ paragraph))

let target_span_for ~content_map ~target_path ~fragment =
  match List.assoc_opt target_path content_map with
  | None -> ""
  | Some content ->
    (match (if fragment = "" then h1_first_paragraph content
            else section_for_slug content fragment)
     with Some s -> s | None -> "")

(* ------------------------------------------------------------------ *)
(* Enumerators                                                        *)

(* Pre-locus: everything but the ordinal-assigned [locus_id]. Carries the
   canonical sort key (doc index, source line, kind, column). *)
type pre = {
  p_doc         : int;
  p_line        : int;
  p_col         : int;
  p_kind        : kind;
  p_source_path : string;
  p_source_span : string;
  p_target_path : string;
  p_target_span : string;
  p_status      : mechanical_status;
}

(** Internal links on one line, left-to-right (extract_md_links prepends). *)
let internal_links_of_line line =
  List.filter Mechanical_scoring.is_internal_link
    (List.rev (Mechanical_scoring.extract_md_links line))

let fragment_of target =
  match String.split_on_char '#' target with _ :: f :: _ -> f | _ -> ""

(** citation_bears_claim: one locus per internal Markdown link that intends
    a document. Non-document links (directory / non-[.md]) are not
    enumerated. Unresolved when [link_resolves] is false (d=1.0, no LLM). *)
let citation_pre doc_index (doc : bundle_file) ~bundle_paths ~doc_slugs ~content_map =
  let src = doc.file_path in
  let acc = ref [] in
  List.iteri (fun li line ->
    let lineno = li + 1 in
    List.iteri (fun col target ->
      if not (resolves_to_non_document ~bundle_paths ~src target) then begin
        let norm = Mechanical_scoring.normalize_link ~src target in
        let resolved =
          Mechanical_scoring.link_resolves ~bundle_paths ~doc_slugs ~src target
        in
        let status = if resolved then Resolved else Unresolved in
        let tspan =
          if resolved then
            target_span_for ~content_map ~target_path:norm
              ~fragment:(fragment_of target)
          else ""
        in
        acc := { p_doc = doc_index; p_line = lineno; p_col = col;
                 p_kind = Citation_bears_claim;
                 p_source_path = src; p_source_span = String.trim line;
                 p_target_path = norm; p_target_span = tspan;
                 p_status = status } :: !acc
      end
    ) (internal_links_of_line line)
  ) (split_lines doc.file_content);
  List.rev !acc

(** authority_claim: one locus per authority self-claim phrase occurrence
    that carries an inline document link on the same line. A self-claim
    with no inline document link emits no locus. *)
let authority_pre doc_index (doc : bundle_file) ~bundle_paths ~doc_slugs ~content_map =
  let src = doc.file_path in
  let acc = ref [] in
  List.iteri (fun li line ->
    let lineno = li + 1 in
    let stripped = strip_emphasis line in
    if List.exists (fun kw -> contains_sub kw stripped) self_claim_kws then begin
      (* The linked surface must be a document (or a broken reference), not a
         resolved non-document — same exclusion as citation_bears_claim. *)
      let candidates =
        List.filter
          (fun t -> not (resolves_to_non_document ~bundle_paths ~src t))
          (internal_links_of_line line)
      in
      match candidates with
      | [] -> ()  (* self-claim with no linked document surface -> no locus *)
      | target :: _ ->
        let norm = Mechanical_scoring.normalize_link ~src target in
        let resolved =
          Mechanical_scoring.link_resolves ~bundle_paths ~doc_slugs ~src target
        in
        let status = if resolved then Resolved else Unresolved in
        let tspan =
          if resolved then
            target_span_for ~content_map ~target_path:norm
              ~fragment:(fragment_of target)
          else ""
        in
        acc := { p_doc = doc_index; p_line = lineno; p_col = 0;
                 p_kind = Authority_claim;
                 p_source_path = src; p_source_span = String.trim line;
                 p_target_path = norm; p_target_span = tspan;
                 p_status = status } :: !acc
    end
  ) (split_lines doc.file_content);
  List.rev !acc

(** target_file_fit: one locus per document that has an H1 — the file's own
    identity vs its own H1. Always resolved. Documents with no H1 emit no
    locus. [source_span] is the filename stem, or (for readme/skill
    basenames) the parent directory words, per the existing convention. *)
let fit_pre doc_index (doc : bundle_file) =
  let rec find_h1 li = function
    | [] -> None
    | line :: rest ->
      (match heading_of_line line with
       | Some (1, text) -> Some (li + 1, text)
       | _ -> find_h1 (li + 1) rest)
  in
  match find_h1 0 (split_lines doc.file_content) with
  | None -> []
  | Some (h1_line, h1_text) ->
    let path = doc.file_path in
    let stem = lower (Filename.remove_extension (Filename.basename path)) in
    let source_span =
      if stem = "readme" || stem = "skill" then
        (match Filename.dirname path with
         | "." | "" -> "(repo root)"
         | d -> Filename.basename d)
      else stem
    in
    [ { p_doc = doc_index; p_line = h1_line; p_col = 0;
        p_kind = Target_file_fit;
        p_source_path = path; p_source_span = source_span;
        p_target_path = path; p_target_span = "# " ^ h1_text;
        p_status = Resolved } ]

(** The deterministic, pre-witness β locus inventory for a bundle's files.
    Canonical order: bundle file order -> source line -> kind order ->
    column; [locus_id] assigned by that order. *)
let inventory (files : bundle_file list) : locus list =
  let docs = List.filter is_doc files in
  let bundle_paths = List.map (fun f -> f.file_path) files in
  let doc_slugs = Mechanical_scoring.doc_slug_map files in
  let content_map = List.map (fun f -> (f.file_path, f.file_content)) docs in
  let pres =
    List.concat
      (List.mapi (fun i doc ->
         citation_pre i doc ~bundle_paths ~doc_slugs ~content_map
         @ authority_pre i doc ~bundle_paths ~doc_slugs ~content_map
         @ fit_pre i doc)
         docs)
  in
  let sorted =
    List.stable_sort (fun a b ->
      let c = compare a.p_doc b.p_doc in
      if c <> 0 then c else
      let c = compare a.p_line b.p_line in
      if c <> 0 then c else
      let c = compare (kind_rank a.p_kind) (kind_rank b.p_kind) in
      if c <> 0 then c else compare a.p_col b.p_col) pres
  in
  List.mapi (fun idx p ->
    { locus_id = Printf.sprintf "beta.%s.%04d" (kind_short p.p_kind) (idx + 1);
      kind = p.p_kind;
      source_path = p.p_source_path;
      source_span = p.p_source_span;
      target_path = p.p_target_path;
      target_span = p.p_target_span;
      question = question_for p.p_kind;
      mechanical_status = p.p_status }) sorted

let eligible_count loci =
  List.length (List.filter (fun l -> l.mechanical_status = Resolved) loci)

(* ------------------------------------------------------------------ *)
(* Aggregation: β_factorized                                          *)

let clamp01 x = Float.max 0.0 (Float.min 1.0 x)

type beta_aggregate = {
  beta_factorized     : float;  (* 1 - sum(w.d)/sum(w), clamped [0,1] *)
  n_loci              : int;    (* N(T) — all enumerated loci *)
  eligible_loci       : int;    (* E(T) — LLM-eligible (resolved) loci *)
  locus_sparse        : bool;   (* E(T) < 5 *)
  sum_weight          : float;
  sum_weighted_defect : float;
}

(** [β_factorized] over ALL loci (unresolved included as real β defects,
    d=1.0). [verdict_of] supplies the LLM verdict for each RESOLVED locus;
    it is never consulted for an unresolved locus. Degenerate: N(T)=0 ->
    β=1.0. Sparsity is on the eligible (resolved) count, per prereg. *)
let compute_beta (loci : locus list) ~(verdict_of : locus -> verdict) : beta_aggregate =
  let n = List.length loci in
  let eligible = eligible_count loci in
  if n = 0 then
    { beta_factorized = 1.0; n_loci = 0; eligible_loci = 0;
      locus_sparse = true; sum_weight = 0.0; sum_weighted_defect = 0.0 }
  else begin
    let sw, swd =
      List.fold_left (fun (sw, swd) l ->
        let w = kind_weight l.kind in
        let d =
          match l.mechanical_status with
          | Unresolved -> 1.0
          | Resolved -> defect_weight_of_verdict (verdict_of l)
        in
        (sw +. w, swd +. w *. d)) (0.0, 0.0) loci
    in
    let beta = if sw = 0.0 then 1.0 else clamp01 (1.0 -. swd /. sw) in
    { beta_factorized = beta; n_loci = n; eligible_loci = eligible;
      locus_sparse = eligible < 5; sum_weight = sw;
      sum_weighted_defect = swd }
  end

(** [compute_beta] with verdicts supplied as a [(locus_id, verdict)] assoc
    (the shape {!validate_sample} returns on success). *)
let beta_of_verdicts loci verdicts =
  compute_beta loci
    ~verdict_of:(fun l ->
      match List.assoc_opt l.locus_id verdicts with
      | Some v -> v
      | None -> Supports  (* unreachable after validate_sample *) )

(* ------------------------------------------------------------------ *)
(* Locus-response schema + sample validation                          *)

(** One validated LLM response. [lr_evidence_sides] are the citation sides
    the response carries (from an [evidence] object's non-empty keys); a
    negative (contradicts) verdict must carry both "source" and "target". *)
type locus_response = {
  lr_locus_id      : string;
  lr_verdict       : verdict;
  lr_confidence    : float;
  lr_evidence_sides: string list;
  lr_evidence      : string;
  lr_rationale     : string;
}

let get_field k = function
  | `Assoc l -> List.assoc_opt k l
  | _ -> None

let parse_locus_response json =
  match get_field "locus_id" json with
  | Some (`String id) ->
    (match get_field "verdict" json with
     | Some (`String vs) ->
       (match verdict_of_string vs with
        | None -> Error (Printf.sprintf "unknown verdict '%s'" vs)
        | Some v ->
          let confidence =
            match get_field "confidence" json with
            | Some (`Float f) -> f
            | Some (`Int i) -> float_of_int i
            | _ -> 0.0
          in
          let sides, text =
            match get_field "evidence" json with
            | Some (`Assoc kvs) ->
              let sides =
                List.filter_map (fun (k, v) ->
                  match v with
                  | `String s when String.trim s <> "" -> Some k
                  | _ -> None) kvs
              in
              let text =
                String.concat " | "
                  (List.filter_map (fun (k, v) ->
                     match v with `String s -> Some (k ^ ": " ^ s) | _ -> None)
                     kvs)
              in
              (sides, text)
            | Some (`String s) -> ([], s)
            | _ -> ([], "")
          in
          let rationale =
            match get_field "rationale" json with
            | Some (`String s) -> s
            | _ -> ""
          in
          Ok { lr_locus_id = id; lr_verdict = v; lr_confidence = confidence;
               lr_evidence_sides = sides; lr_evidence = text;
               lr_rationale = rationale })
     | _ -> Error "missing or non-string 'verdict'")
  | _ -> Error "missing or non-string 'locus_id'"

let rec parse_locus_responses json =
  match json with
  | `List items ->
    let rec go acc = function
      | [] -> Ok (List.rev acc)
      | x :: rest ->
        (match parse_locus_response x with
         | Ok r -> go (r :: acc) rest
         | Error e -> Error e)
    in
    go [] items
  | `Assoc _ ->
    (match get_field "responses" json with
     | Some (`List _ as l) -> parse_locus_responses l
     | _ -> Error "expected an array or an object with a 'responses' array")
  | _ -> Error "expected a JSON array of locus responses"

(** Why a sample is refused (prereg §"Response validation": exactly one
    response per resolved locus_id — no more, no less; a negative verdict
    must carry both evidence sides). A refused sample counts against A0. *)
type refusal =
  | Missing_response of string    (* resolved locus with no response *)
  | Duplicate_response of string  (* resolved locus answered more than once *)
  | Extraneous_response of string (* response for a non-eligible/unknown id *)
  | Incomplete_evidence of string (* contradicts without both evidence sides *)

let refusal_to_string = function
  | Missing_response id ->
    Printf.sprintf "missing response for resolved locus %s" id
  | Duplicate_response id ->
    Printf.sprintf "duplicate response for locus %s" id
  | Extraneous_response id ->
    Printf.sprintf "response for non-eligible or unknown locus %s" id
  | Incomplete_evidence id ->
    Printf.sprintf
      "negative (contradicts) verdict for locus %s lacks both source and \
       target evidence" id

(** Validate one sample's responses against the resolved locus set.
    [Ok verdicts] (a [(locus_id, verdict)] assoc over the resolved loci)
    when every resolved locus is answered exactly once, no spurious answer
    is present, and every contradicts verdict carries both evidence sides;
    otherwise [Error refusals] listing every problem — the sample is
    refused, not repaired (matching the engine's "refuse, don't skip"
    contract). *)
let validate_sample ~loci ~responses =
  let resolved_ids =
    List.filter_map (fun l ->
      if l.mechanical_status = Resolved then Some l.locus_id else None) loci
  in
  let problems = ref [] in
  let seen = Hashtbl.create 16 in
  List.iter (fun r ->
    if not (List.mem r.lr_locus_id resolved_ids) then
      problems := Extraneous_response r.lr_locus_id :: !problems
    else begin
      if Hashtbl.mem seen r.lr_locus_id then
        problems := Duplicate_response r.lr_locus_id :: !problems
      else Hashtbl.add seen r.lr_locus_id ();
      match r.lr_verdict with
      | Contradicts ->
        if not (List.mem "source" r.lr_evidence_sides
                && List.mem "target" r.lr_evidence_sides) then
          problems := Incomplete_evidence r.lr_locus_id :: !problems
      | Supports | Insufficient -> ()
    end
  ) responses;
  List.iter (fun id ->
    if not (Hashtbl.mem seen id) then
      problems := Missing_response id :: !problems) resolved_ids;
  match !problems with
  | [] ->
    Ok (List.filter_map (fun r ->
          if List.mem r.lr_locus_id resolved_ids
          then Some (r.lr_locus_id, r.lr_verdict) else None) responses)
  | ps -> Error (List.rev ps)

(* ------------------------------------------------------------------ *)
(* JSON serialization                                                 *)

let locus_to_json ?target l =
  let base = [
    ("locus_id",          `String l.locus_id);
    ("kind",              `String (string_of_kind l.kind));
    ("source_path",       `String l.source_path);
    ("source_span",       `String l.source_span);
    ("target_path",       `String l.target_path);
    ("target_span",       `String l.target_span);
    ("question",          `String l.question);
    ("mechanical_status", `String (string_of_status l.mechanical_status));
    ("llm_called",        `Bool (l.mechanical_status = Resolved));
  ] in
  match target with
  | Some t -> `Assoc (("target", `String t) :: base)
  | None -> `Assoc base

(** The pre-witness inventory artifact (prereg §"Aggregation formula":
    written BEFORE any witness call, uploaded and cited in the close-out). *)
let inventory_to_json ~target (loci : locus list) =
  let eligible = eligible_count loci in
  `Assoc [
    ("kind",          `String "factorized_beta_inventory");
    ("target",        `String target);
    ("beta_loci",     `Int (List.length loci));
    ("eligible_loci", `Int eligible);
    ("locus_sparse",  `Bool (eligible < 5));
    ("loci",          `List (List.map (fun l -> locus_to_json ~target l) loci));
  ]

let aggregate_to_json a =
  `Assoc [
    ("beta_factorized",     `Float a.beta_factorized);
    ("beta_loci",           `Int a.n_loci);
    ("eligible_loci",       `Int a.eligible_loci);
    ("locus_sparse",        `Bool a.locus_sparse);
    ("sum_weight",          `Float a.sum_weight);
    ("sum_weighted_defect", `Float a.sum_weighted_defect);
  ]

(* ------------------------------------------------------------------ *)
(* Adjudication prompt surface                                        *)

(** One per-locus adjudication block for a witness prompt. *)
let locus_prompt_block l =
  Printf.sprintf
    "### %s (%s)\nsource_path: %s\nsource:\n%s\ntarget_path: %s\ntarget:\n%s\n\
     Question: %s"
    l.locus_id (string_of_kind l.kind)
    l.source_path l.source_span
    l.target_path l.target_span
    l.question

(** The bounded per-locus adjudication instruction. The witness adjudicates
    ONLY the resolved loci; it emits exactly one response per locus_id and
    NEVER a scalar — the engine computes β. Consistent with how
    runtime/SELF-MEASURE.md / src/skills/self-measure emit prompts, but this is
    a separate β-adjudication surface and does NOT change the α/γ scalar
    path. *)
let adjudication_instruction (loci : locus list) =
  let resolved = List.filter (fun l -> l.mechanical_status = Resolved) loci in
  let header =
    "# Factorized-β locus adjudication\n\n\
     You are adjudicating a FIXED set of β loci enumerated by the engine.\n\
     Do NOT add, drop, split, or merge loci. Do NOT emit any coherence \
     score, β, or aggregate — the engine computes β from your verdicts.\n\n\
     For each locus below, decide whether the target bears out the source's \
     claim and return exactly one verdict:\n\
     - `supports`      — the target bears out the claim.\n\
     - `contradicts`   — the target conflicts with the claim.\n\
     - `insufficient`  — the target neither supports nor contradicts it.\n\n\
     Ground every verdict in the provided source and target text only. A \
     `contradicts` verdict MUST cite both the source and the target.\n\n\
     Return a JSON array with exactly one object per locus_id below:\n\
     {\"locus_id\": \"...\", \"verdict\": \"supports|contradicts|insufficient\", \
     \"confidence\": 0.0, \"evidence\": {\"source\": \"...\", \"target\": \"...\"}, \
     \"rationale\": \"one sentence\"}\n\n\
     ## Loci"
  in
  let blocks = String.concat "\n\n" (List.map locus_prompt_block resolved) in
  if resolved = [] then header ^ "\n\n(no LLM-eligible loci)"
  else header ^ "\n\n" ^ blocks

(* ------------------------------------------------------------------ *)
(* B3 discrimination-gate fixture (typed rules, checked before any run) *)

(** One B3 control from
    docs/beta/governance/fixtures/factorized-beta-controls.json. *)
type control = {
  c_id                      : string;
  c_kind                    : string;
  c_hard                    : bool;
  c_llm_called              : bool;
  c_mechanical_status       : string;
  c_expected_verdict        : string;
  c_required_evidence_sides : string list;
}

let parse_controls json =
  match get_field "controls" json with
  | Some (`List items) ->
    let str o k =
      match get_field k o with
      | Some (`String s) -> Ok s
      | _ -> Error (Printf.sprintf "control missing string field '%s'" k)
    in
    let boolf o k = match get_field k o with Some (`Bool b) -> b | _ -> false in
    let sides o =
      match get_field "required_evidence_sides" o with
      | Some (`List xs) ->
        List.filter_map (function `String s -> Some s | _ -> None) xs
      | _ -> []
    in
    let rec go acc = function
      | [] -> Ok (List.rev acc)
      | o :: rest ->
        (match str o "id", str o "kind",
               str o "mechanical_status", str o "expected_verdict" with
         | Ok id, Ok kind, Ok ms, Ok ev ->
           go ({ c_id = id; c_kind = kind; c_hard = boolf o "hard";
                 c_llm_called = boolf o "llm_called";
                 c_mechanical_status = ms; c_expected_verdict = ev;
                 c_required_evidence_sides = sides o } :: acc) rest
         | Error e, _, _, _ | _, Error e, _, _
         | _, _, Error e, _ | _, _, _, Error e -> Error e)
    in
    go [] items
  | _ -> Error "fixture missing 'controls' array"

let allowed_kinds =
  ["citation_bears_claim"; "authority_claim"; "target_file_fit"]

let allowed_verdicts =
  ["supports"; "contradicts"; "insufficient"; "unresolved"]

(** The typed fixture rules the prereg (B3) requires BEFORE any run.
    Returns human-readable errors ([] = the control is well-typed). *)
let typed_rule_errors c =
  let errs = ref [] in
  let add fmt = Printf.ksprintf (fun s -> errs := s :: !errs) fmt in
  if not (List.mem c.c_kind allowed_kinds) then
    add "%s: kind '%s' is not an allowed β locus kind" c.c_id c.c_kind;
  if not (List.mem c.c_expected_verdict allowed_verdicts) then
    add "%s: expected_verdict '%s' is not allowed" c.c_id c.c_expected_verdict;
  let unresolved_verdict = c.c_expected_verdict = "unresolved" in
  let unresolved_status = c.c_mechanical_status = "unresolved" in
  if unresolved_verdict <> unresolved_status then
    add "%s: expected_verdict=unresolved must hold iff \
         mechanical_status=unresolved" c.c_id;
  if unresolved_verdict && c.c_llm_called then
    add "%s: an unresolved fixture must have llm_called=false" c.c_id;
  if c.c_llm_called
     && not (List.mem c.c_expected_verdict
               ["supports"; "contradicts"; "insufficient"]) then
    add "%s: an llm_called fixture must expect \
         supports|contradicts|insufficient" c.c_id;
  if c.c_expected_verdict = "contradicts"
     && c.c_required_evidence_sides <> ["source"; "target"] then
    add "%s: a contradicts fixture must require both source and target \
         evidence" c.c_id;
  List.rev !errs

(** The B3 typed-fixture gate over a parsed controls file: [Ok n] (the
    control count) when every control is well-typed; [Error errs] listing
    every violation. The label-agreement half of B3 needs a witness run and
    is deferred to the credentialed CI witness. *)
let validate_controls json =
  match parse_controls json with
  | Error e -> Error [e]
  | Ok controls ->
    let errs = List.concat_map typed_rule_errors controls in
    if errs = [] then Ok (List.length controls) else Error errs
