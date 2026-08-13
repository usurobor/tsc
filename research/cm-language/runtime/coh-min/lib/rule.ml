(* rule.ml — the CM-owned result rule, as DATA, and the generic evaluator for
   it.

   This module is the whole point of #129. Before it, the derivation lived in
   `Runner.classify`, an OCaml function that asked `if cm_id = "…"`. After it,
   the derivation is an ordered first-match table of pure JSON ASTs carried in
   the IR's `result` block, and this evaluator knows nothing about any
   methodology: it is given a closed vocabulary, a table, and an immutable fact
   set, and it returns the first class that matches.

   The v0 algebra (pinned by the design's §Declarative result semantics and by
   issue AC4):

     boolean      {"and": [e…]}  {"or": [e…]}  {"not": e}
     equality     {"eq": [a, b]}  {"ne": [a, b]}
     ordering     {"lt"|"le"|"gt"|"ge": [a, b]}
     presence     {"present": ref}
     status       {"step_status": ["step_id", "success"]}

   An operand is either a REFERENCE object — {"fact": "step.port"} or
   {"evidence": "step.predicate"} — or a JSON scalar LITERAL. Nothing else: no
   provider calls, no mutation, no recursion, no unbounded iteration, no host
   access. There is no way to spell any of those in this AST, which is a
   stronger guarantee than checking for them.

   TWO PROPERTIES ARE LOAD-BEARING AND DELIBERATE:

   1. **Totality.** The table is ordered clauses plus a MANDATORY `default`, so
      evaluation always emits exactly one class. [of_json] refuses a table with
      no default (issue AC6), so "no rule matched" is unrepresentable rather
      than handled.

   2. **Non-short-circuiting.** `and`/`or` evaluate every operand even once the
      answer is settled. The algebra is pure and finite, so this cannot change
      any verdict — but it makes the set of facts CONSULTED equal to the set of
      facts APPEARING in the clauses that were evaluated. That is what lets the
      receipt's `fact_refs` be exact rather than a superset, and lets a verifier
      recompute the derivation from the receipt alone. A short-circuiting
      evaluator would have to record its own trace to make the same claim.

   The evaluator does NOT reach into runtime-private state. Its only window onto
   the run is the [env] record below, whose three functions serve exactly the
   fact classes the fact-provenance invariant permits: declared typed step
   outputs, declared evidence predicates, and scheduler-owned execution status.
   There is no fourth accessor, so a rule cannot read a fact the methodology did
   not declare — the invariant is enforced by the shape of this interface as
   well as by [Ir]'s load-time check. *)

module J = Json
open Jread

let ( let* ) = Result.bind

(* ───────────────────────────── the AST ───────────────────────────────── *)

(* A reference to one immutable run fact. Both forms are (step_id, name); they
   differ in WHICH declaration must have introduced the name — an output port or
   an evidence predicate — which is what [Ir] checks at load. *)
type reference =
  | Output of string * string     (* step_id, declared output port *)
  | Evidence of string * string   (* step_id, declared evidence predicate *)

let reference_to_string = function
  | Output (sid, port) -> sid ^ "." ^ port
  | Evidence (sid, pred) -> sid ^ "." ^ pred

let reference_kind = function
  | Output _ -> "step_output"
  | Evidence _ -> "evidence_predicate"

type operand =
  | Ref of reference
  | Lit of Value.t

type comparison = Lt | Le | Gt | Ge

let comparison_key = function Lt -> "lt" | Le -> "le" | Gt -> "gt" | Ge -> "ge"

type expr =
  | And of expr list
  | Or of expr list
  | Not of expr
  | Eq of operand * operand
  | Ne of operand * operand
  | Compare of comparison * operand * operand
  | Present of reference
  | Step_status of string * string

type clause = {
  clause_id : string;
  guard     : expr;
  emit      : string;
}

(* The terminal clause. It has an id (so the receipt's `rule_id` is always a
   real declared name, including when the default fires) and NO guard: a
   default that could fail to match would not be a default. *)
type fallback = {
  fallback_id   : string;
  fallback_emit : string;
}

(* One warrant obligation: a class stronger than ordinary schema validity, and
   what must be retained for it to be claimable. The v0 catalog has exactly one
   requirement form — `evidence.<step_id>` — and an UNKNOWN requirement is never
   treated as discharged (design §Warrant obligations). *)
type obligation = {
  obliged_class : string;
  requirement   : string;
}

type table = {
  classes     : string list;
  clauses     : clause list;
  fallback    : fallback;
  obligations : obligation list;
}

(* ─────────────────────────────── parsing ─────────────────────────────── *)

let split_ref ~(ctx : string) ~(key : string) (s : string) : (string * string, string) result =
  match String.index_opt s '.' with
  | None ->
    Error (Printf.sprintf "%s%s reference %S must be \"<step_id>.<name>\"" ctx key s)
  | Some i ->
    let sid = String.sub s 0 i in
    let name = String.sub s (i + 1) (String.length s - i - 1) in
    if sid = "" || name = "" || String.contains name '.' then
      Error (Printf.sprintf "%s%s reference %S must be \"<step_id>.<name>\"" ctx key s)
    else Ok (sid, name)

let reference_of_json ~(ctx : string) (j : J.t) : (reference, string) result =
  match field "fact" j, field "evidence" j with
  | Some (J.Str s), None ->
    let* (sid, port) = split_ref ~ctx ~key:"fact" s in
    Ok (Output (sid, port))
  | None, Some (J.Str s) ->
    let* (sid, pred) = split_ref ~ctx ~key:"evidence" s in
    Ok (Evidence (sid, pred))
  | Some _, None -> malformed ctx "fact" "a string"
  | None, Some _ -> malformed ctx "evidence" "a string"
  | Some _, Some _ ->
    Error (Printf.sprintf "%sreference declares both \"fact\" and \"evidence\"" ctx)
  | None, None ->
    Error (Printf.sprintf
             "%sreference must be {\"fact\": \"<step>.<port>\"} or \
              {\"evidence\": \"<step>.<predicate>\"}" ctx)

(* An operand is a reference OBJECT or a scalar LITERAL. An object that is not a
   well-formed reference is refused rather than being treated as a literal —
   a misspelled {"factt": …} must not silently become an opaque constant. *)
let operand_of_json ~(ctx : string) (j : J.t) : (operand, string) result =
  match j with
  | J.Obj _ ->
    let* r = reference_of_json ~ctx j in
    Ok (Ref r)
  | other ->
    (match Value.of_json other with
     | Some v -> Ok (Lit v)
     | None ->
       Error (Printf.sprintf
                "%soperand must be a reference object or a boolean/integer/string \
                 literal" ctx))

let binary ~(ctx : string) ~(key : string) (j : J.t) : (operand * operand, string) result =
  let* items = required_array ~ctx key j in
  match items with
  | [ a; b ] ->
    let ctx = Printf.sprintf "%s%s." ctx key in
    let* a = operand_of_json ~ctx a in
    let* b = operand_of_json ~ctx b in
    Ok (a, b)
  | _ -> Error (Printf.sprintf "%s%s must be an array of exactly two operands" ctx key)

let operator_keys =
  [ "and"; "or"; "not"; "eq"; "ne"; "lt"; "le"; "gt"; "ge"; "present"; "step_status" ]

let rec expr_of_json ~(ctx : string) (j : J.t) : (expr, string) result =
  if not (is_obj j) then
    Error (Printf.sprintf "%sexpression must be an object with exactly one operator" ctx)
  else
    match keys j with
    | [ op ] when List.mem op operator_keys -> operator_of_json ~ctx ~op j
    | [ op ] ->
      Error (Printf.sprintf "%sunknown operator %S; the v0 algebra is [%s]"
               ctx op (String.concat ", " operator_keys))
    | ks ->
      Error (Printf.sprintf
               "%sexpression must carry exactly one operator, found [%s]"
               ctx (String.concat ", " (List.map (Printf.sprintf "%S") ks)))

and operator_of_json ~(ctx : string) ~(op : string) (j : J.t) : (expr, string) result =
  let nested key =
    let* items = required_array ~ctx key j in
    if items = [] then
      Error (Printf.sprintf "%s%s must carry at least one operand" ctx key)
    else
      all (List.mapi
             (fun i e -> expr_of_json ~ctx:(Printf.sprintf "%s%s[%d]." ctx key i) e)
             items)
  in
  match op with
  | "and" -> let* es = nested "and" in Ok (And es)
  | "or" -> let* es = nested "or" in Ok (Or es)
  | "not" ->
    let* inner = required_object ~ctx "not" j in
    let* e = expr_of_json ~ctx:(ctx ^ "not.") inner in
    Ok (Not e)
  | "eq" -> let* (a, b) = binary ~ctx ~key:"eq" j in Ok (Eq (a, b))
  | "ne" -> let* (a, b) = binary ~ctx ~key:"ne" j in Ok (Ne (a, b))
  | "lt" -> let* (a, b) = binary ~ctx ~key:"lt" j in Ok (Compare (Lt, a, b))
  | "le" -> let* (a, b) = binary ~ctx ~key:"le" j in Ok (Compare (Le, a, b))
  | "gt" -> let* (a, b) = binary ~ctx ~key:"gt" j in Ok (Compare (Gt, a, b))
  | "ge" -> let* (a, b) = binary ~ctx ~key:"ge" j in Ok (Compare (Ge, a, b))
  | "present" ->
    let* inner = required_object ~ctx "present" j in
    let* r = reference_of_json ~ctx:(ctx ^ "present.") inner in
    Ok (Present r)
  | "step_status" ->
    let* items = required_array ~ctx "step_status" j in
    (match items with
     | [ J.Str sid; J.Str status ] -> Ok (Step_status (sid, status))
     | _ ->
       Error (Printf.sprintf
                "%sstep_status must be [\"<step_id>\", \"<status>\"]" ctx))
  | other -> Error (Printf.sprintf "%sunknown operator %S" ctx other)

let clause_of_json (index : int) (j : J.t) : (clause, string) result =
  let ctx = Printf.sprintf "result.rules[%d]." index in
  let* () = closed ~ctx ~allowed:[ "id"; "when"; "emit" ] j in
  let* clause_id = required_string ~ctx "id" j in
  let* guard_j = required_object ~ctx "when" j in
  let* guard = expr_of_json ~ctx:(ctx ^ "when.") guard_j in
  let* emit = required_string ~ctx "emit" j in
  Ok { clause_id; guard; emit }

let fallback_of_json (j : J.t) : (fallback, string) result =
  let ctx = "result.default." in
  let* () = closed ~ctx ~allowed:[ "id"; "emit" ] j in
  let* fallback_id = required_string ~ctx "id" j in
  let* fallback_emit = required_string ~ctx "emit" j in
  Ok { fallback_id; fallback_emit }

let obligation_of_json (index : int) (j : J.t) : (obligation, string) result =
  let ctx = Printf.sprintf "result.obligations[%d]." index in
  let* () = closed ~ctx ~allowed:[ "class"; "requires" ] j in
  let* obliged_class = required_string ~ctx "class" j in
  let* requires = required_string_array ~ctx "requires" j in
  match requires with
  | [] -> Error (ctx ^ "requires declares no obligation")
  | _ -> Ok { obliged_class; requirement = String.concat "\n" requires }

(* Obligations are stored one requirement per record so the receipt can report a
   per-requirement discharge state. [obligation_of_json] parses one IR entry
   (which may list several requirements) and this flattens it. *)
let flatten_obligations (os : obligation list) : obligation list =
  List.concat_map
    (fun o ->
       List.map (fun r -> { obliged_class = o.obliged_class; requirement = r })
         (String.split_on_char '\n' o.requirement))
    os

(* The `result` block of a NormalizedCMIR. Closed, and total by construction:
   a missing `default` is refused here, so no downstream stage has to consider
   the "no rule matched" case. *)
let of_json (j : J.t) : (table, string) result =
  let ctx = "result." in
  let* () =
    closed ~ctx ~allowed:[ "classes"; "rules"; "default"; "obligations" ] j in
  let* classes = required_string_array ~ctx "classes" j in
  let* () =
    if classes = [] then Error "result.classes declares no result class" else Ok () in
  let* () = unique ~what:"result class" classes in
  let* rule_jsons = required_array ~ctx "rules" j in
  let* clauses = all (List.mapi clause_of_json rule_jsons) in
  let* fallback_j = required_object ~ctx "default" j in
  let* fallback = fallback_of_json fallback_j in
  let* () =
    unique ~what:"rule id" (List.map (fun c -> c.clause_id) clauses @ [ fallback.fallback_id ]) in
  let* obligation_jsons = required_array ~ctx "obligations" j in
  let* obligations = all (List.mapi obligation_of_json obligation_jsons) in
  let obligations = flatten_obligations obligations in
  (* Result honesty (issue AC6): every emitted class — including the default's,
     and including a class named only by an obligation — must be in the declared
     vocabulary. A rule emitting an undeclared class is refused at LOAD, so it
     cannot be discovered by a subject that happens to reach that clause. *)
  let emitted =
    List.map (fun c -> (c.clause_id, c.emit)) clauses
    @ [ (fallback.fallback_id, fallback.fallback_emit) ] in
  let* () =
    all (List.map
           (fun (rid, cls) ->
              if List.mem cls classes then Ok ()
              else
                Error (Printf.sprintf
                         "result rule %S emits %S, which result.classes does not \
                          declare [%s]"
                         rid cls
                         (String.concat ", " (List.map (Printf.sprintf "%S") classes))))
           emitted)
    |> Result.map (fun _ -> ()) in
  let* () =
    all (List.map
           (fun o ->
              if List.mem o.obliged_class classes then Ok ()
              else
                Error (Printf.sprintf
                         "result.obligations names class %S, which result.classes \
                          does not declare" o.obliged_class))
           obligations)
    |> Result.map (fun _ -> ()) in
  Ok { classes; clauses; fallback; obligations }

(* ───────────────── references, for load-time provenance ──────────────── *)

let rec refs_of_expr (e : expr) : reference list =
  let of_operand = function Ref r -> [ r ] | Lit _ -> [] in
  match e with
  | And es | Or es -> List.concat_map refs_of_expr es
  | Not e -> refs_of_expr e
  | Eq (a, b) | Ne (a, b) | Compare (_, a, b) -> of_operand a @ of_operand b
  | Present r -> [ r ]
  | Step_status _ -> []

let rec statuses_of_expr (e : expr) : (string * string) list =
  match e with
  | And es | Or es -> List.concat_map statuses_of_expr es
  | Not e -> statuses_of_expr e
  | Eq _ | Ne _ | Compare _ | Present _ -> []
  | Step_status (sid, st) -> [ (sid, st) ]

(* Every reference the table can ever read, with the rule that named it — so a
   provenance refusal can say WHICH rule reached for an undeclared fact. *)
let all_references (t : table) : (string * reference) list =
  List.concat_map
    (fun c -> List.map (fun r -> (c.clause_id, r)) (refs_of_expr c.guard))
    t.clauses

let all_statuses (t : table) : (string * (string * string)) list =
  List.concat_map
    (fun c -> List.map (fun s -> (c.clause_id, s)) (statuses_of_expr c.guard))
    t.clauses

(* ───────────────────────────── evaluation ────────────────────────────── *)

(* The evaluator's ONLY window onto the run. Three accessors, one per fact class
   the fact-provenance invariant permits; there is deliberately no fourth. Each
   returns [None] when the fact was not produced — a skipped step's port, an
   evidence predicate a refused checker never emitted — and the algebra's
   presence predicate is the only lawful way to observe that. *)
type env = {
  output    : string -> string -> Value.t option;   (* step_id -> port *)
  predicate : string -> string -> Value.t option;   (* step_id -> evidence predicate *)
  status    : string -> string option;              (* step_id -> terminal status *)
}

let lookup (env : env) (r : reference) : Value.t option =
  match r with
  | Output (sid, port) -> env.output sid port
  | Evidence (sid, pred) -> env.predicate sid pred

(* A reference read during evaluation, with what it resolved to. This is the
   derivation witness the receipt carries and a verifier replays. *)
type reading = {
  read_reference : reference;
  read_value     : Value.t option;
}

let readings_of_expr (env : env) (e : expr) : reading list =
  List.map
    (fun r -> { read_reference = r; read_value = lookup env r })
    (refs_of_expr e)

(* Resolve an operand. An unavailable reference makes the surrounding comparison
   FALSE rather than an error: "the README's line count is at least 5" is a
   well-posed question with answer "no" when no line count was produced. This is
   the only place unavailability is interpreted, and [Present] is the predicate
   that observes it directly. *)
let resolve (env : env) (o : operand) : Value.t option =
  match o with Ref r -> lookup env r | Lit v -> Some v

let rec eval (env : env) (e : expr) : (bool, string) result =
  (* NOT short-circuiting, deliberately: see the header. [List.map] over every
     operand, then combine. The algebra is pure, so this is observationally
     identical to short-circuiting and makes the witness set exact. *)
  let combine f es =
    let* bs = all (List.map (eval env) es) in
    Ok (f bs)
  in
  match e with
  | And es -> combine (List.for_all (fun b -> b)) es
  | Or es -> combine (List.exists (fun b -> b)) es
  | Not inner ->
    let* b = eval env inner in
    Ok (not b)
  | Eq (a, b) ->
    (match resolve env a, resolve env b with
     | Some x, Some y -> Ok (Value.equal x y)
     | _ -> Ok false)
  | Ne (a, b) ->
    (match resolve env a, resolve env b with
     | Some x, Some y -> Ok (not (Value.equal x y))
     | _ -> Ok false)
  | Compare (op, a, b) ->
    (match resolve env a, resolve env b with
     | Some x, Some y ->
       (* A type mismatch between two AVAILABLE facts is a methodology fault,
          not a measurement outcome: it is refused rather than answered. *)
       let* c = Value.compare_ordered x y in
       Ok (match op with Lt -> c < 0 | Le -> c <= 0 | Gt -> c > 0 | Ge -> c >= 0)
     | _ -> Ok false)
  | Present r -> Ok (lookup env r <> None)
  | Step_status (sid, expected) ->
    (match env.status sid with
     | Some actual -> Ok (String.equal actual expected)
     | None -> Ok false)

(* The derivation: the first clause whose guard holds, else the default. The
   witness is every reference appearing in the clauses that were EVALUATED —
   exact, because evaluation does not short-circuit. *)
type derivation = {
  emitted_class : string;
  matched_rule  : string;
  witness       : reading list;
}

let dedup_readings (rs : reading list) : reading list =
  let rec go seen = function
    | [] -> []
    | r :: rest ->
      let key = reference_to_string r.read_reference in
      if List.mem key seen then go seen rest
      else r :: go (key :: seen) rest
  in
  go [] rs

let derive (env : env) (t : table) : (derivation, string) result =
  let rec go (witness : reading list) = function
    | [] ->
      Ok { emitted_class = t.fallback.fallback_emit;
           matched_rule = t.fallback.fallback_id;
           witness = dedup_readings (List.rev witness) }
    | c :: rest ->
      let witness = List.rev_append (readings_of_expr env c.guard) witness in
      let* hit = eval env c.guard in
      if hit then
        Ok { emitted_class = c.emit;
             matched_rule = c.clause_id;
             witness = dedup_readings (List.rev witness) }
      else go witness rest
  in
  go [] t.clauses

(* ─────────────────────────── warrant obligations ─────────────────────── *)

(* The v0 obligation catalog. Exactly one requirement form is known:

     evidence.<step_id>   the named step retained evidence in this run

   An UNKNOWN requirement is NOT treated as discharged (design §Warrant
   obligations: "an unknown obligation is not treated as discharged"), so
   inventing a stronger-sounding obligation makes the class unclaimable rather
   than making it free. *)
type discharge = {
  discharged_class       : string;
  discharged_requirement : string;
  discharged             : bool;
  discharge_note         : string;
}

let evidence_prefix = "evidence."

let obligations_for (t : table) (cls : string) : obligation list =
  List.filter (fun o -> String.equal o.obliged_class cls) t.obligations

let discharge_one ~(retained : string -> bool) (o : obligation) : discharge =
  let n = String.length evidence_prefix in
  let req = o.requirement in
  if String.length req > n && String.sub req 0 n = evidence_prefix then
    let sid = String.sub req n (String.length req - n) in
    let ok = retained sid in
    { discharged_class = o.obliged_class;
      discharged_requirement = req;
      discharged = ok;
      discharge_note =
        if ok then Printf.sprintf "step %S retained evidence" sid
        else Printf.sprintf "step %S retained no evidence in this run" sid }
  else
    { discharged_class = o.obliged_class;
      discharged_requirement = req;
      discharged = false;
      discharge_note =
        Printf.sprintf
          "requirement %S is not in the v0 obligation catalog [%s<step_id>]; \
           an unknown obligation is never treated as discharged"
          req evidence_prefix }
