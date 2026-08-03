(* cm_surface — the .cm surface-language front-end for the TSC CM model.
 *
 * Pipeline:  .cm source  --lex-->  tokens  --parse-->  AST  --lower-->  JSON
 *
 * ONE `.cm` source, TWO byte-exact projections (both reproduce `cue export`'s
 * bytes: 4-space indent, insertion-order keys, `": "` separators, raw UTF-8,
 * trailing newline):
 *
 *   default   (Lower.ir)     → the normalized IR   (== compiled/cm0.json,
 *                              the `#NormalizedCMIR` projection: id · kind ·
 *                              provider_kind · failure per step).
 *   --source  (Lower.source) → the FULL authored #CMSource expression
 *                              (== `cue export … -e cm0`): content-addressed
 *                              provider digests, per-step input/output/evidence
 *                              contracts, target_contract, standing_scope, and
 *                              the boundary note — everything the IR projects out.
 *
 * The surface is thus a FAITHFUL, lossless carrier of the full source, not just
 * the IR (issue #115 follow-on). Stdlib only — no external deps, so this
 * front-end is fully isolated from the frozen `coh` engine. IR/source emission
 * only: no provider runtime. *)

(* ────────────────────────────────────────────────────────────────────────
   JSON value + CUE-exact serializer
   ──────────────────────────────────────────────────────────────────────── *)
module Json = struct
  type t =
    | S of string
    | Bool of bool
    | Null
    | Arr of t list
    | Obj of (string * t) list

  (* Only quote/backslash/controls are escaped; high bytes (UTF-8 for §, δ, …)
     pass through raw, matching cue export, which emits raw UTF-8 not \uXXXX. *)
  let escape s =
    let b = Buffer.create (String.length s + 2) in
    String.iter
      (fun c ->
        match c with
        | '"' -> Buffer.add_string b "\\\""
        | '\\' -> Buffer.add_string b "\\\\"
        | '\n' -> Buffer.add_string b "\\n"
        | '\t' -> Buffer.add_string b "\\t"
        | '\r' -> Buffer.add_string b "\\r"
        | c -> Buffer.add_char b c)
      s;
    Buffer.contents b

  let pad n = String.make (n * 4) ' '

  (* Mirrors Go's json.MarshalIndent(v, "", "    "), which is what cue export
     uses. Empty containers render as `[]` / `{}` on one line. *)
  let rec render ind = function
    | S s -> "\"" ^ escape s ^ "\""
    | Bool b -> if b then "true" else "false"
    | Null -> "null"
    | Arr [] -> "[]"
    | Arr xs ->
        let inner = List.map (fun x -> pad (ind + 1) ^ render (ind + 1) x) xs in
        "[\n" ^ String.concat ",\n" inner ^ "\n" ^ pad ind ^ "]"
    | Obj [] -> "{}"
    | Obj kvs ->
        let inner =
          List.map
            (fun (k, v) ->
              pad (ind + 1) ^ "\"" ^ escape k ^ "\": " ^ render (ind + 1) v)
            kvs
        in
        "{\n" ^ String.concat ",\n" inner ^ "\n" ^ pad ind ^ "}"

  (* Top-level document: the value at indent 0 plus a trailing newline. *)
  let to_string v = render 0 v ^ "\n"
end

(* ────────────────────────────────────────────────────────────────────────
   Errors
   ──────────────────────────────────────────────────────────────────────── *)
exception Compile_error of string

let err fmt = Printf.ksprintf (fun s -> raise (Compile_error s)) fmt

(* ────────────────────────────────────────────────────────────────────────
   Lexer
   ──────────────────────────────────────────────────────────────────────── *)
module Lex = struct
  type token =
    | ATOM of string (* keywords, identifiers, versions (v0.1), hex words *)
    | STR of string (* "double-quoted" *)
    | LPAREN
    | RPAREN
    | LBRACE
    | RBRACE
    | COLON
    | COMMA
    | EQ
    | AT (* @ — introduces a content-address digest *)
    | ARROW (* -> *)
    | EOF

  type lexeme = { tok : token; line : int }

  (* `!` for the effectful binders `let!`/`and!`; `-` for hyphenated ids like
     `refusal-rubric`. `->` is matched before the atom rule so ARROW still wins. *)
  let is_atom_char c =
    (c >= 'a' && c <= 'z')
    || (c >= 'A' && c <= 'Z')
    || (c >= '0' && c <= '9')
    || c = '_' || c = '.' || c = '!' || c = '-'

  let tokenize (src : string) : lexeme list =
    let n = String.length src in
    let i = ref 0 in
    let line = ref 1 in
    let out = ref [] in
    let push t = out := { tok = t; line = !line } :: !out in
    while !i < n do
      let c = src.[!i] in
      if c = '\n' then (
        incr line;
        incr i)
      else if c = ' ' || c = '\t' || c = '\r' then incr i
      else if c = '#' then
        while !i < n && src.[!i] <> '\n' do
          incr i
        done
      else if c = '(' then (push LPAREN; incr i)
      else if c = ')' then (push RPAREN; incr i)
      else if c = '{' then (push LBRACE; incr i)
      else if c = '}' then (push RBRACE; incr i)
      else if c = ':' then (push COLON; incr i)
      else if c = ',' then (push COMMA; incr i)
      else if c = '=' then (push EQ; incr i)
      else if c = '@' then (push AT; incr i)
      else if c = '-' && !i + 1 < n && src.[!i + 1] = '>' then (push ARROW; i := !i + 2)
      else if c = '"' then begin
        let start = !i + 1 in
        incr i;
        let b = Buffer.create 32 in
        let closed = ref false in
        while !i < n && not !closed do
          let d = src.[!i] in
          if d = '"' then (closed := true; incr i)
          else if d = '\\' && !i + 1 < n then (
            (match src.[!i + 1] with
            | 'n' -> Buffer.add_char b '\n'
            | 't' -> Buffer.add_char b '\t'
            | 'r' -> Buffer.add_char b '\r'
            | '"' -> Buffer.add_char b '"'
            | '\\' -> Buffer.add_char b '\\'
            | other -> Buffer.add_char b other);
            i := !i + 2)
          else (
            if d = '\n' then incr line;
            Buffer.add_char b d;
            incr i)
        done;
        if not !closed then err "line %d: unterminated string starting at col %d" !line start;
        push (STR (Buffer.contents b))
      end
      else if is_atom_char c then begin
        let start = !i in
        while !i < n && is_atom_char src.[!i] do incr i done;
        push (ATOM (String.sub src start (!i - start)))
      end
      else err "line %d: unexpected character %C" !line c
    done;
    push EOF;
    List.rev !out
end

(* ────────────────────────────────────────────────────────────────────────
   AST
   ──────────────────────────────────────────────────────────────────────── *)
module Ast = struct
  type step = {
    id : string;
    kind : string; (* #StepKind *)
    provider_kind : string; (* tool | oracle | cm | llm *)
    provider_id : string;
    provider_digest : string; (* content address, e.g. sha256:ic0 *)
    failure : string; (* #ResultClass *)
    binder : [ `Let | `And ];
    input : (string * Json.t) list; (* reads / protocol / methodology / skill, in order *)
    output_contract : (string * Json.t) list;
    evidence_contract : (string * Json.t) list;
  }

  type artifact = { role : string; kind : string; required : bool }

  type cm = {
    name : string;
    version : string;
    input_param : string;
    input_type : string;
    output_type : string;
    question : string;
    target_kind : string;
    target_description : string;
    source_digest : string;
    artifacts : artifact list;
    lists : string list;
    binding : string;
    standing : string;
    steps : step list;
    reports : string list;
    derivation : string;
    boundary_note : string;
    forbids : string list;
  }
end

(* ────────────────────────────────────────────────────────────────────────
   Parser  (hand-written recursive descent over the lexeme stream)
   ──────────────────────────────────────────────────────────────────────── *)
module Parse = struct
  open Lex

  type state = { mutable toks : lexeme list }

  let peek st = match st.toks with l :: _ -> l | [] -> { tok = EOF; line = -1 }
  let advance st = match st.toks with _ :: r -> st.toks <- r | [] -> ()
  let cur_line st = (peek st).line

  let tok_str = function
    | ATOM a -> Printf.sprintf "identifier %S" a
    | STR s -> Printf.sprintf "string %S" s
    | LPAREN -> "'('" | RPAREN -> "')'"
    | LBRACE -> "'{'" | RBRACE -> "'}'"
    | COLON -> "':'" | COMMA -> "','" | EQ -> "'='" | AT -> "'@'"
    | ARROW -> "'->'" | EOF -> "end of input"

  let expect st t =
    let l = peek st in
    if l.tok = t then advance st
    else err "line %d: expected %s, got %s" l.line (tok_str t) (tok_str l.tok)

  let atom st =
    let l = peek st in
    match l.tok with
    | ATOM a -> advance st; a
    | other -> err "line %d: expected identifier, got %s" l.line (tok_str other)

  let str st =
    let l = peek st in
    match l.tok with
    | STR s -> advance st; s
    | other -> err "line %d: expected string, got %s" l.line (tok_str other)

  let keyword st kw =
    let l = peek st in
    match l.tok with
    | ATOM a when a = kw -> advance st
    | other -> err "line %d: expected %S, got %s" l.line kw (tok_str other)

  let is_atom st s = match (peek st).tok with ATOM a -> a = s | _ -> false

  (* strip a leading `v` from a version atom: v0.1 → 0.1 *)
  let strip_v s = if String.length s > 0 && s.[0] = 'v' then String.sub s 1 (String.length s - 1) else s

  let atom_list st =
    let rec loop acc =
      let a = atom st in
      let acc = a :: acc in
      match (peek st).tok with COMMA -> advance st; loop acc | _ -> List.rev acc
    in
    loop []

  (* @sha256:<hex> → "sha256:<hex>"  (AT then COLON are their own tokens). *)
  let parse_digest_at st =
    expect st AT;
    let alg = atom st in
    expect st COLON;
    let hex = atom st in
    alg ^ ":" ^ hex

  (* bare digest (no `@`), for `source_digest sha256:<hex>` *)
  let parse_digest_bare st =
    let alg = atom st in
    expect st COLON;
    let hex = atom st in
    alg ^ ":" ^ hex

  (* one value inside an output/evidence contract: `true`/`false` → Bool,
     any other bareword → string. *)
  let parse_value st : Json.t =
    match (peek st).tok with
    | ATOM "true" -> advance st; Json.Bool true
    | ATOM "false" -> advance st; Json.Bool false
    | _ -> Json.S (atom st)

  (* comma-separated `key: value` pairs (an output_contract / evidence_contract). *)
  let parse_kvlist st : (string * Json.t) list =
    let rec loop acc =
      let k = atom st in
      expect st COLON;
      let v = parse_value st in
      let acc = (k, v) :: acc in
      match (peek st).tok with COMMA -> advance st; loop acc | _ -> List.rev acc
    in
    loop []

  (* optional `{ … }` block carrying a step's input / output / evidence contracts. *)
  let parse_step_block st =
    let input = ref [] and output = ref [] and evidence = ref [] in
    if (peek st).tok = LBRACE then begin
      advance st;
      let add r k v = r := (k, v) :: !r in
      let rec loop () =
        match (peek st).tok with
        | RBRACE -> advance st
        | ATOM "reads" ->
            advance st;
            add input "reads" (Json.Arr (List.map (fun a -> Json.S a) (atom_list st)));
            loop ()
        | ATOM "protocol" -> advance st; add input "protocol" (Json.S (atom st)); loop ()
        | ATOM "methodology" ->
            advance st;
            let id = atom st in
            let dg = parse_digest_at st in
            add input "methodology"
              (Json.Obj [ ("id", Json.S id); ("kind", Json.S "methodology"); ("digest", Json.S dg) ]);
            loop ()
        | ATOM "skill" ->
            advance st;
            let id = atom st in
            let k = atom st in
            let dg = parse_digest_at st in
            let ver = strip_v (atom st) in
            add input "skill"
              (Json.Obj
                 [ ("id", Json.S id); ("kind", Json.S k); ("digest", Json.S dg); ("version", Json.S ver) ]);
            loop ()
        | ATOM "output" -> advance st; output := parse_kvlist st; loop ()
        | ATOM "evidence" -> advance st; evidence := parse_kvlist st; loop ()
        | other -> err "line %d: unexpected %s in step block" (cur_line st) (tok_str other)
      in
      loop ()
    end;
    (List.rev !input, !output, !evidence)

  (* let!/and! <id> = <kind> via <provider_kind> <provider_id> @<digest> on <FAIL> { … } *)
  let parse_step st binder =
    let id = atom st in
    expect st EQ;
    let kind = atom st in
    keyword st "via";
    let provider_kind = atom st in
    let provider_id = atom st in
    let provider_digest = parse_digest_at st in
    keyword st "on";
    let failure = atom st in
    let input, output_contract, evidence_contract = parse_step_block st in
    { Ast.id; kind; provider_kind; provider_id; provider_digest; failure; binder;
      input; output_contract; evidence_contract }

  let parse_cm st : Ast.cm =
    keyword st "cm";
    let name = atom st in
    let version = strip_v (atom st) in
    expect st LPAREN;
    let input_param = atom st in
    expect st COLON;
    let input_type = atom st in
    expect st RPAREN;
    expect st ARROW;
    let output_type = atom st in
    expect st LBRACE;

    let question = ref None and target_kind = ref None and target_description = ref None in
    let source_digest = ref None and standing = ref None and binding = ref None in
    let boundary_note = ref None and derivation = ref None and forbids = ref None in
    let artifacts = ref [] and lists = ref [] and steps = ref [] and reports = ref [] in

    let rec body () =
      match (peek st).tok with
      | RBRACE -> advance st
      | EOF -> err "line %d: unexpected end of input inside `cm` block" (cur_line st)
      | ATOM "question" -> advance st; question := Some (str st); body ()
      | ATOM "target" ->
          advance st;
          let k = atom st in
          let d = str st in
          target_kind := Some k;
          target_description := Some d;
          body ()
      | ATOM "source_digest" -> advance st; source_digest := Some (parse_digest_bare st); body ()
      | ATOM "require" ->
          advance st;
          let role = atom st in
          expect st COLON;
          let kind = atom st in
          let required = if is_atom st "optional" then (advance st; false) else true in
          artifacts := { Ast.role; kind; required } :: !artifacts;
          body ()
      | ATOM "lists" -> advance st; lists := !lists @ atom_list st; body ()
      | ATOM "binding" -> advance st; binding := Some (atom st); body ()
      | ATOM "standing" -> advance st; standing := Some (str st); body ()
      | ATOM "let" ->
          err "line %d: pure `let` is unused by CM0; provider steps use `let!`/`and!`" (cur_line st)
      | ATOM "let!" -> advance st; steps := parse_step st `Let :: !steps; body ()
      | ATOM "and!" -> advance st; steps := parse_step st `And :: !steps; body ()
      | ATOM "retain" -> advance st; reports := !reports @ atom_list st; body ()
      | ATOM "decide" ->
          advance st;
          keyword st "from";
          keyword st "assessments";
          keyword st "deferred";
          derivation := Some (str st);
          body ()
      | ATOM "boundary_note" -> advance st; boundary_note := Some (str st); body ()
      | ATOM "forbid" -> advance st; forbids := Some (atom_list st); body ()
      | other -> err "line %d: unexpected %s in `cm` block" (cur_line st) (tok_str other)
    in
    body ();
    expect st EOF;

    let req nm = function Some x -> x | None -> err "cm %s: missing required `%s` declaration" name nm in
    {
      Ast.name; version; input_param; input_type; output_type;
      question = req "question" !question;
      target_kind = req "target" !target_kind;
      target_description = req "target" !target_description;
      source_digest = req "source_digest" !source_digest;
      artifacts = List.rev !artifacts;
      lists = !lists;
      binding = req "binding" !binding;
      standing = req "standing" !standing;
      steps = List.rev !steps;
      reports = !reports;
      derivation = req "decide" !derivation;
      boundary_note = req "boundary_note" !boundary_note;
      forbids = req "forbid" !forbids;
    }

  let parse toks = parse_cm { toks }
end

(* ────────────────────────────────────────────────────────────────────────
   Validation + lowering to the two JSON projections
   ──────────────────────────────────────────────────────────────────────── *)
module Lower = struct
  open Ast

  (* The measure-only boundary is structurally mandatory: a CM0-family CM MUST
     forbid the full authority set. Dropping any (e.g. `admit`) is a compile
     error — the boundary is load-bearing, not cosmetic (issue #115 negative
     probe). General over all five forbids. *)
  let required_forbids = [ "compile"; "admit"; "authorize"; "repair"; "self_authorize" ]

  let input_kind = function
    | "instrument" -> "instrument_subject"
    | other -> err "unknown input subject %S (expected `instrument`)" other

  let output_kind = function
    | "InstrumentAssessment" -> "instrument_assessment"
    | other -> err "unknown output type %S (expected `InstrumentAssessment`)" other

  let validate (cm : cm) =
    List.iter
      (fun r ->
        if not (List.mem r cm.forbids) then
          err
            "cm %s: measure-only boundary must `forbid` all of [%s]; missing %S. \
             The boundary is load-bearing (OPER-AUTH-001: CM0 cannot admit itself)."
            cm.name (String.concat ", " required_forbids) r)
      required_forbids;
    List.iter
      (fun f -> if not (List.mem f required_forbids) then err "cm %s: unknown authority %S in `forbid`" cm.name f)
      cm.forbids;
    (match cm.steps with
    | [] -> err "cm %s: procedure has no provider steps" cm.name
    | first :: rest ->
        if first.binder <> `Let then err "cm %s: the first provider step (%s) must be `let!`" cm.name first.id;
        List.iter
          (fun s -> if s.binder <> `And then err "cm %s: provider step %s after the first must be `and!`" cm.name s.id)
          rest)

  (* ── default projection: the normalized IR (== compiled/cm0.json). ──────── *)
  let ir (cm : cm) : Json.t =
    validate cm;
    let open Json in
    let artifact a = Obj [ ("role", S a.role); ("kind", S a.kind); ("required", Bool a.required) ] in
    let step s =
      Obj [ ("id", S s.id); ("kind", S s.kind); ("provider_kind", S s.provider_kind); ("failure", S s.failure) ]
    in
    Obj
      [
        ("format", S "tsc-cm-ir/0.1");
        ("cm_id", S ("tsc." ^ cm.name));
        ("cm_version", S cm.version);
        ("source_digest", S cm.source_digest);
        ( "input_contract",
          Obj
            [
              ("kind", S (input_kind cm.input_param));
              ("required_artifacts", Arr (List.map artifact cm.artifacts));
              ("artifact_lists", Arr (List.map (fun x -> S x) cm.lists));
              ("runtime_binding", S cm.binding);
            ] );
        ("procedure", Obj [ ("steps", Arr (List.map step cm.steps)) ]);
        ( "result_contract",
          Obj
            [
              ("kind", S (output_kind cm.output_type));
              ("subcontracts", Arr (List.map (fun s -> S s.id) cm.steps));
              ("runtime_binding", S cm.binding);
              ( "emits",
                Obj
                  [ ("admission_verdict", Bool false); ("authorization", Bool false); ("boundary_decision", Bool false) ] );
              ("derivation", S cm.derivation);
            ] );
        ( "receipt_contract",
          Obj
            [
              ("kind", S (output_kind cm.output_type));
              ("reports", Arr (List.map (fun x -> S x) cm.reports));
              ("measure_only", Bool true);
            ] );
      ]

  (* ── full projection: the authored #CMSource (== `cue export … -e cm0`). ── *)
  let source (cm : cm) : Json.t =
    validate cm;
    let open Json in
    (* one artifact slot: {kind, required, ref:null} *)
    let slot a = (a.role, Obj [ ("kind", S a.kind); ("required", Bool a.required); ("ref", Null) ]) in
    (* the #InstrumentSubject object, reused verbatim as output.subject *)
    let input_obj =
      Obj
        (List.map slot cm.artifacts
        @ List.map (fun l -> (l, Arr [])) cm.lists
        @ [
            ("standing_scope", Obj [ ("declared", S cm.standing) ]);
            ("contract_integrity", S "assessable_from_normalized_ir");
            ("runtime_binding", Obj [ ("status", S cm.binding) ]);
          ])
    in
    let step s =
      Obj
        [
          ("id", S s.id);
          ("kind", S s.kind);
          ("provider", Obj [ ("kind", S s.provider_kind); ("id", S s.provider_id); ("digest", S s.provider_digest) ]);
          ("input", Obj s.input);
          ("output_contract", Obj s.output_contract);
          ("evidence_contract", Obj s.evidence_contract);
          ("failure", S s.failure);
        ]
    in
    Obj
      [
        ("id", S ("tsc." ^ cm.name));
        ("version", S cm.version);
        ("question", S cm.question);
        ("target_contract", Obj [ ("kind", S cm.target_kind); ("description", S cm.target_description) ]);
        ("input", input_obj);
        ("procedure", Obj [ ("steps", Arr (List.map step cm.steps)) ]);
        ( "boundary",
          Obj
            [
              ("measure_only", Bool true);
              ("note", S cm.boundary_note);
              ("may_compile", Bool false);
              ("may_admit", Bool false);
              ("may_authorize", Bool false);
              ("may_repair", Bool false);
            ] );
        ( "output",
          Obj
            [
              ("subject", input_obj);
              ("subcontracts_assessed", Arr (List.map (fun s -> S s.id) cm.steps));
              ("runtime_binding_status", S cm.binding);
              ("emits_admission_verdict", Bool false);
              ("emits_authorization", Bool false);
              ("emits_boundary_decision", Bool false);
            ] );
      ]
end

(* ────────────────────────────────────────────────────────────────────────
   Public API
   ──────────────────────────────────────────────────────────────────────── *)
type mode = Ir | Source

let compile_string ?(mode = Ir) (src : string) : string =
  let cm = src |> Lex.tokenize |> Parse.parse in
  let json = match mode with Ir -> Lower.ir cm | Source -> Lower.source cm in
  Json.to_string json

let compile_file ?(mode = Ir) (path : string) : string =
  let ic = open_in_bin path in
  let n = in_channel_length ic in
  let s = really_input_string ic n in
  close_in ic;
  compile_string ~mode s
