(* cm_surface — the .cm surface-language front-end for the TSC CM model.
 *
 * Pipeline:  .cm source  --lex-->  tokens  --parse-->  AST  --lower-->  IR JSON
 *
 * The IR JSON is emitted byte-for-byte identically to `cue export` of the
 * corresponding `#NormalizedCMIR` expression (4-space indent, insertion-order
 * keys, `: ` separators, trailing newline). Stdlib only — no external deps, so
 * this front-end is fully isolated from the frozen `coh` engine.
 *
 * Scope (issue #115): CM0 only. The grammar covers exactly the constructs CM0
 * needs from #114's minimal instruction set (`cm` / `let!` / `and!` / `require`
 * / `retain` / `decide` / `forbid`) plus three declaration directives
 * (`source_digest`, `lists`, `binding`), and is written to extend. IR emission
 * only: no provider runtime. *)

(* ────────────────────────────────────────────────────────────────────────
   JSON value + CUE-exact serializer
   ──────────────────────────────────────────────────────────────────────── *)
module Json = struct
  type t =
    | S of string
    | Bool of bool
    | Arr of t list
    | Obj of (string * t) list

  (* Only quote/backslash/controls are escaped. CM0's payload is clean ASCII,
     so no escape ever fires; this keeps parity with cue export, which does not
     HTML-escape these strings either. *)
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
    | Arr [] -> "[]"
    | Arr xs ->
        let inner =
          List.map (fun x -> pad (ind + 1) ^ render (ind + 1) x) xs
        in
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
    | ARROW (* -> *)
    | EOF

  type lexeme = { tok : token; line : int }

  (* `!` is admitted so the effectful binders `let!` / `and!` lex as single
     atoms; it never appears elsewhere in the surface. *)
  let is_atom_char c =
    (c >= 'a' && c <= 'z')
    || (c >= 'A' && c <= 'Z')
    || (c >= '0' && c <= '9')
    || c = '_' || c = '.' || c = '!'

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
        (* line comment *)
        while !i < n && src.[!i] <> '\n' do
          incr i
        done
      else if c = '(' then (
        push LPAREN;
        incr i)
      else if c = ')' then (
        push RPAREN;
        incr i)
      else if c = '{' then (
        push LBRACE;
        incr i)
      else if c = '}' then (
        push RBRACE;
        incr i)
      else if c = ':' then (
        push COLON;
        incr i)
      else if c = ',' then (
        push COMMA;
        incr i)
      else if c = '=' then (
        push EQ;
        incr i)
      else if c = '-' && !i + 1 < n && src.[!i + 1] = '>' then (
        push ARROW;
        i := !i + 2)
      else if c = '"' then begin
        let start = !i + 1 in
        incr i;
        let b = Buffer.create 32 in
        let closed = ref false in
        while !i < n && not !closed do
          let d = src.[!i] in
          if d = '"' then (
            closed := true;
            incr i)
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
        while !i < n && is_atom_char src.[!i] do
          incr i
        done;
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
    kind : string; (* #StepKind: mechanical | oracle | invoke_cm | semantic_judgment | transform *)
    provider_kind : string; (* tool | oracle | cm | llm ... *)
    provider_id : string; (* surface-only detail; not projected into the IR *)
    failure : string; (* #ResultClass *)
    binder : [ `Let | `And ]; (* let! vs and! *)
  }

  type artifact = { role : string; kind : string; required : bool }

  type cm = {
    name : string;
    version : string;
    input_param : string; (* e.g. "instrument" *)
    input_type : string; (* e.g. "Methodology" (surface doc; not in IR) *)
    output_type : string; (* e.g. "InstrumentAssessment" *)
    source_digest : string;
    artifacts : artifact list;
    lists : string list;
    binding : string;
    steps : step list;
    reports : string list; (* retain … *)
    derivation : string; (* decide from assessments deferred "…" *)
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
    | LPAREN -> "'('"
    | RPAREN -> "')'"
    | LBRACE -> "'{'"
    | RBRACE -> "'}'"
    | COLON -> "':'"
    | COMMA -> "','"
    | EQ -> "'='"
    | ARROW -> "'->'"
    | EOF -> "end of input"

  let expect st t =
    let l = peek st in
    if l.tok = t then advance st
    else err "line %d: expected %s, got %s" l.line (tok_str t) (tok_str l.tok)

  (* consume an ATOM, returning its text *)
  let atom st =
    let l = peek st in
    match l.tok with
    | ATOM a ->
        advance st;
        a
    | other -> err "line %d: expected identifier, got %s" l.line (tok_str other)

  (* consume a specific keyword ATOM *)
  let keyword st kw =
    let l = peek st in
    match l.tok with
    | ATOM a when a = kw -> advance st
    | other -> err "line %d: expected %S, got %s" l.line kw (tok_str other)

  let is_atom st s = match (peek st).tok with ATOM a -> a = s | _ -> false

  (* comma-separated list of atoms until a stopping predicate. *)
  let atom_list st =
    let rec loop acc =
      let a = atom st in
      let acc = a :: acc in
      match (peek st).tok with
      | COMMA ->
          advance st;
          loop acc
      | _ -> List.rev acc
    in
    loop []

  (* source_digest sha256:<hex>  →  "sha256:<hex>" (COLON is its own token). *)
  let parse_digest st =
    let alg = atom st in
    expect st COLON;
    let hex = atom st in
    alg ^ ":" ^ hex

  (* one provider-bound step:
       let!/and! <id> = <kind> via <provider_kind> <provider_id> on <FAILURE> *)
  let parse_step st binder =
    let id = atom st in
    expect st EQ;
    let kind = atom st in
    keyword st "via";
    let provider_kind = atom st in
    let provider_id = atom st in
    keyword st "on";
    let failure = atom st in
    { Ast.id; kind; provider_kind; provider_id; failure; binder }

  let parse_cm st : Ast.cm =
    keyword st "cm";
    let name = atom st in
    (* version token: v0.1 → strip leading 'v' *)
    let vraw = atom st in
    let version =
      if String.length vraw > 0 && vraw.[0] = 'v' then
        String.sub vraw 1 (String.length vraw - 1)
      else vraw
    in
    (* (param : Type) *)
    expect st LPAREN;
    let input_param = atom st in
    expect st COLON;
    let input_type = atom st in
    expect st RPAREN;
    expect st ARROW;
    let output_type = atom st in
    expect st LBRACE;

    (* mutable accumulators for the block body *)
    let source_digest = ref None in
    let artifacts = ref [] in
    let lists = ref [] in
    let binding = ref None in
    let steps = ref [] in
    let reports = ref [] in
    let derivation = ref None in
    let forbids = ref None in

    let rec body () =
      match (peek st).tok with
      | RBRACE -> advance st
      | EOF -> err "line %d: unexpected end of input inside `cm` block" (cur_line st)
      | ATOM "source_digest" ->
          advance st;
          source_digest := Some (parse_digest st);
          body ()
      | ATOM "require" ->
          advance st;
          let role = atom st in
          expect st COLON;
          let kind = atom st in
          (* optional trailing `optional` keyword flips required→false *)
          let required = if is_atom st "optional" then (advance st; false) else true in
          artifacts := { Ast.role; kind; required } :: !artifacts;
          body ()
      | ATOM "lists" ->
          advance st;
          lists := !lists @ atom_list st;
          body ()
      | ATOM "binding" ->
          advance st;
          binding := Some (atom st);
          body ()
      | ATOM "let" ->
          err "line %d: pure `let` is unused by CM0; provider steps use `let!`/`and!`" (cur_line st)
      | ATOM "let!" ->
          advance st;
          steps := parse_step st `Let :: !steps;
          body ()
      | ATOM "and!" ->
          advance st;
          steps := parse_step st `And :: !steps;
          body ()
      | ATOM "retain" ->
          advance st;
          reports := !reports @ atom_list st;
          body ()
      | ATOM "decide" ->
          advance st;
          keyword st "from";
          keyword st "assessments";
          keyword st "deferred";
          let d = match (peek st).tok with
            | STR s -> advance st; s
            | other -> err "line %d: `decide … deferred` expects a quoted derivation string, got %s" (cur_line st) (tok_str other)
          in
          derivation := Some d;
          body ()
      | ATOM "forbid" ->
          advance st;
          forbids := Some (atom_list st);
          body ()
      | other ->
          err "line %d: unexpected %s in `cm` block" (cur_line st) (tok_str other)
    in
    body ();
    expect st EOF;

    let req name = function Some x -> x | None -> err "cm %s: missing required `%s` declaration" name name in
    {
      Ast.name;
      version;
      input_param;
      input_type;
      output_type;
      source_digest = req "source_digest" !source_digest;
      artifacts = List.rev !artifacts;
      lists = !lists;
      binding = req "binding" !binding;
      steps = List.rev !steps;
      reports = !reports;
      derivation = req "decide" !derivation;
      forbids = req "forbid" !forbids;
    }

  let parse toks = parse_cm { toks }
end

(* ────────────────────────────────────────────────────────────────────────
   Validation + lowering to the normalized IR
   ──────────────────────────────────────────────────────────────────────── *)
module Lower = struct
  open Ast

  (* The measure-only boundary is structurally mandatory: a CM0-family CM MUST
     forbid the full authority set. Dropping any (e.g. `admit`) is a compile
     error — the boundary is load-bearing, not cosmetic (issue #115 negative
     probe). *)
  let required_forbids = [ "compile"; "admit"; "authorize"; "repair"; "self_authorize" ]

  (* input parameter name → input_contract.kind *)
  let input_kind = function
    | "instrument" -> "instrument_subject"
    | other -> err "unknown input subject %S (expected `instrument`)" other

  (* surface output type → the IR `kind` used by result_contract / receipt_contract *)
  let output_kind = function
    | "InstrumentAssessment" -> "instrument_assessment"
    | other -> err "unknown output type %S (expected `InstrumentAssessment`)" other

  let validate (cm : cm) =
    (* forbid completeness (boundary bite) *)
    List.iter
      (fun r ->
        if not (List.mem r cm.forbids) then
          err
            "cm %s: measure-only boundary must `forbid` all of [%s]; missing %S. \
             The boundary is load-bearing (OPER-AUTH-001: CM0 cannot admit itself)."
            cm.name
            (String.concat ", " required_forbids)
            r)
      required_forbids;
    (* no unknown authorities silently accepted *)
    List.iter
      (fun f ->
        if not (List.mem f required_forbids) then
          err "cm %s: unknown authority %S in `forbid`" cm.name f)
      cm.forbids;
    (* step binder shape: exactly one leading `let!`, remaining `and!`
       (F#-style workflow: `let!` then `and!`). *)
    (match cm.steps with
    | [] -> err "cm %s: procedure has no provider steps" cm.name
    | first :: rest ->
        if first.binder <> `Let then
          err "cm %s: the first provider step (%s) must be `let!`" cm.name first.id;
        List.iter
          (fun s ->
            if s.binder <> `And then
              err "cm %s: provider step %s after the first must be `and!`" cm.name s.id)
          rest)

  let lower (cm : cm) : Json.t =
    validate cm;
    let open Json in
    let artifact a =
      Obj [ ("role", S a.role); ("kind", S a.kind); ("required", Bool a.required) ]
    in
    let step s =
      Obj
        [
          ("id", S s.id);
          ("kind", S s.kind);
          ("provider_kind", S s.provider_kind);
          ("failure", S s.failure);
        ]
    in
    let subcontracts = List.map (fun s -> S s.id) cm.steps in
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
              ("subcontracts", Arr subcontracts);
              ("runtime_binding", S cm.binding);
              ( "emits",
                Obj
                  [
                    (* measure-only ⇒ all three fixed false (boundary forbids
                       admit/authorize/decide). *)
                    ("admission_verdict", Bool false);
                    ("authorization", Bool false);
                    ("boundary_decision", Bool false);
                  ] );
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
end

(* ────────────────────────────────────────────────────────────────────────
   Public API
   ──────────────────────────────────────────────────────────────────────── *)
let compile_string (src : string) : string =
  src |> Lex.tokenize |> Parse.parse |> Lower.lower |> Json.to_string

let compile_file (path : string) : string =
  let ic = open_in_bin path in
  let n = in_channel_length ic in
  let s = really_input_string ic n in
  close_in ic;
  compile_string s
