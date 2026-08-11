(* ir.ml — the NormalizedCMIR contract, as a typed value the runtime can trust.

   #126 handed the runner raw JSON: [link] reached into the document with
   raising accessors, so an IR missing a canonical block either crashed or —
   worse — ran anyway, and NOTHING asked whether the artifact was actually a
   `#NormalizedCMIR`. This module is the repair (#127): parsing the IR is now a
   PURE, TOTAL function that either yields a typed value every later stage can
   rely on, or a [result] error naming exactly what was missing. No stage
   downstream of [of_json] can observe a half-valid IR.

   DIVISION OF AUTHORITY (deliberate, and the reason this module does not
   re-implement the schema):

     - `research/cm-language/schema.cue` `#NormalizedCMIR` is the CONTRACT. It is
       closed, so it owns EXACTNESS: the permitted top-level field set, the
       pinned `format` literal, and the shape of every block that is present.
       `make vet-ir` runs `cue vet` over EVERY IR under `examples/` and `make
       gate` depends on it, so a non-conforming IR fails the build.
     - This module owns FAIL-CLOSED CONSUMPTION at run time: the canonical block
       set must be PRESENT, and every field the runtime reads must be there and
       well-typed, or nothing executes.

   These two are complementary, not redundant, and the overlap is smaller than
   it looks. `cue vet` proves a great deal about a block that is present, but
   CUE's unification makes some ABSENT blocks indistinguishable from empty ones:
   a field whose schema value is already concrete (`format`) unifies to that
   literal when omitted, and an open struct or list (`procedure`,
   `result_contract`) is complete as `{}` / `[]`. Measured against this schema
   with v0.9.2, deleting one canonical block from a conforming IR gives:

     format  procedure  result_contract   -> `cue vet` PASSES; this module refuses
     cm_id  cm_version  source_digest
     input_contract  receipt_contract     -> both refuse (`incomplete value string`)

   So `cue vet` alone would let an IR with no `procedure` and no
   `result_contract` reach the runtime. That is precisely the class #127 exists
   to close, and it is why the block-presence check below is load-bearing rather
   than a re-statement of the schema. (Tightening `#NormalizedCMIR` itself would
   be the other repair; it is explicitly out of scope for this slice, and the
   schema is not ours to edit.)

   What this module deliberately does NOT do is re-check fields it never
   consumes — that would be a second source of truth free to drift from the
   first. The rule is: the schema owns exactness, this module owns presence and
   the fields it reads.

   Note the asymmetry runs both ways: this module is also STRICTER than the
   schema on `result_contract.result_classes`, which `#NormalizedCMIR` leaves
   open but the runtime requires (see below). A vetted IR is therefore not
   automatically runnable, and the runner says exactly which declaration it
   lacked.

   Style (ocaml + write-functional skills): pure — no I/O, no exceptions, no
   fabricated empty state. Every absent required field is an [Error] carrying
   its own dotted path, never a silent default. *)

module J = Json

let ( let* ) = Result.bind

(* ─────────────────────── non-raising JSON accessors ──────────────────────

   `Json.member` and friends RAISE (they are the vendored ascent-0 surface, kept
   byte-identical). Validation must be total, so this module reads through its
   own [result]-returning accessors and never calls the raising ones. *)

(* One field of a JSON object, or [None] — also [None] when [j] is not an
   object, which the required-* helpers below turn into a typed error. *)
let field (key : string) (j : J.t) : J.t option =
  match j with J.Obj kvs -> List.assoc_opt key kvs | _ -> None

let missing (ctx : string) (key : string) =
  Error (Printf.sprintf "%s%s is missing" ctx key)

let malformed (ctx : string) (key : string) (what : string) =
  Error (Printf.sprintf "%s%s must be %s" ctx key what)

let required_string ~(ctx : string) (key : string) (j : J.t) : (string, string) result =
  match field key j with
  | Some (J.Str v) -> Ok v
  | Some _ -> malformed ctx key "a string"
  | None -> missing ctx key

let required_object ~(ctx : string) (key : string) (j : J.t) : (J.t, string) result =
  match field key j with
  | Some (J.Obj _ as o) -> Ok o
  | Some _ -> malformed ctx key "an object"
  | None -> missing ctx key

let required_array ~(ctx : string) (key : string) (j : J.t) : (J.t list, string) result =
  match field key j with
  | Some (J.Arr xs) -> Ok xs
  | Some _ -> malformed ctx key "an array"
  | None -> missing ctx key

(* Sequence a list of results; the FIRST error wins, so the message names the
   earliest fault in document order rather than an arbitrary one. *)
let all (rs : ('a, string) result list) : ('a list, string) result =
  List.fold_right
    (fun r acc ->
       match r, acc with
       | Error e, _ -> Error e
       | _, (Error _ as e) -> e
       | Ok x, Ok xs -> Ok (x :: xs))
    rs (Ok [])

let required_string_array ~(ctx : string) (key : string) (j : J.t)
  : (string list, string) result =
  let* items = required_array ~ctx key j in
  all (List.map
         (function J.Str v -> Ok v | _ -> malformed ctx key "an array of strings")
         items)

(* ────────────────────────────── the typed IR ─────────────────────────────

   Field names are disambiguated at the type definition (ocaml skill §2.1):
   [step] and [t] share no field name, so no access site pays an annotation. *)

(* One `procedure.steps[*]` entry, with every field the runtime consumes. *)
type step = {
  step_id         : string;
  step_kind       : string;
  provider_kind   : string;
  provider_class  : string;
  reads           : string list;   (* typed input surfaces; gate on readiness *)
  produces        : string;        (* the surface this step makes available *)
  config          : J.t option;    (* provider-private; [None] = none declared *)
  may_access      : string list;   (* sandbox capability binding (firewall seam) *)
  search_strength : string;
}

(* A validated `#NormalizedCMIR`, projected to what the runtime reads. *)
type t = {
  format         : string;
  cm_id          : string;
  cm_version     : string;
  source_digest  : string;
  input_roles    : string list;   (* input_contract.required_artifacts[*].role *)
  steps          : step list;     (* procedure.steps *)
  result_classes : string list;   (* result_contract.result_classes — the CM's
                                     declared result-class VOCABULARY *)
}

(* The one `format` a `#NormalizedCMIR` may carry (schema.cue pins it as a
   literal). Checking it here is resource discovery, not decoration: it is the
   cheapest proof that the artifact handed to the runtime is a CM IR at all,
   made before any later stage depends on that. *)
let format_pin = "tsc-cm-ir/0.1"

(* The canonical top-level blocks `#NormalizedCMIR` requires. Named once, so the
   required set and its regression table cannot drift apart. *)
let canonical_blocks =
  [ "format"; "cm_id"; "cm_version"; "source_digest";
    "input_contract"; "procedure"; "result_contract"; "receipt_contract" ]

let step_of_json (index : int) (j : J.t) : (step, string) result =
  let ctx = Printf.sprintf "procedure.steps[%d]." index in
  let* step_id = required_string ~ctx "id" j in
  let* step_kind = required_string ~ctx "kind" j in
  let* provider_kind = required_string ~ctx "provider_kind" j in
  let* provider_class = required_string ~ctx "provider_class" j in
  let* reads = required_string_array ~ctx "reads" j in
  let* produces = required_string ~ctx "produces" j in
  let* may_access = required_string_array ~ctx "may_access" j in
  let* search_strength = required_string ~ctx "search_strength" j in
  (* `config` is provider-private and genuinely optional — a step needing none
     declares none. Absence is carried as [None], NOT as an empty object: a
     provider that requires configuration then fails closed with its own
     message instead of silently reading a fabricated `{}`. *)
  let* config =
    match field "config" j with
    | None -> Ok None
    | Some (J.Obj _ as c) -> Ok (Some c)
    | Some _ -> malformed ctx "config" "an object"
  in
  Ok { step_id; step_kind; provider_kind; provider_class; reads; produces;
       config; may_access; search_strength }

(* The base surfaces a run starts with: the roles the input contract requires.
   A step becomes ready when all of its `reads` are present, so these seed the
   DAG. *)
let input_roles_of (input_contract : J.t) : (string list, string) result =
  let ctx = "input_contract." in
  let* items = required_array ~ctx "required_artifacts" input_contract in
  all (List.mapi
         (fun index a ->
            let ctx = Printf.sprintf "input_contract.required_artifacts[%d]." index in
            required_string ~ctx "role" a)
         items)

(* Validate a parsed IR document into the typed value the runtime executes.
   Total: every failure is an [Error] naming the dotted path at fault. *)
let of_json (j : J.t) : (t, string) result =
  let ctx = "" in
  let* format = required_string ~ctx "format" j in
  let* () =
    if format = format_pin then Ok ()
    else
      Error (Printf.sprintf "format %S is not the NormalizedCMIR format %S"
               format format_pin)
  in
  let* cm_id = required_string ~ctx "cm_id" j in
  let* cm_version = required_string ~ctx "cm_version" j in
  let* source_digest = required_string ~ctx "source_digest" j in
  let* input_contract = required_object ~ctx "input_contract" j in
  let* procedure = required_object ~ctx "procedure" j in
  let* result_contract = required_object ~ctx "result_contract" j in
  (* `receipt_contract` is a canonical block the schema requires and the
     runtime reads nothing from (the emitted receipt's shape is pinned by
     `examples/*/contracts/receipt.cue`). Its PRESENCE is still enforced: an IR
     missing a canonical block must never execute, whichever block it is. *)
  let* _receipt_contract = required_object ~ctx "receipt_contract" j in
  let* input_roles = input_roles_of input_contract in
  let* step_jsons = required_array ~ctx:"procedure." "steps" procedure in
  let* steps = all (List.mapi step_of_json step_jsons) in
  (* The CM's declared result-class vocabulary. REQUIRED by the runtime even
     though `#NormalizedCMIR` leaves `result_contract` open: the runtime refuses
     to emit a receipt whose `result_class` the CM never declared, and it cannot
     enforce that against a set it does not have. Defaulting here would restore
     exactly the drift #127 exists to close, so absence is an error. *)
  let* result_classes =
    required_string_array ~ctx:"result_contract." "result_classes" result_contract in
  let* () =
    if result_classes = [] then
      Error "result_contract.result_classes declares no result class"
    else Ok ()
  in
  Ok { format; cm_id; cm_version; source_digest; input_roles; steps; result_classes }

(* The vocabulary gate (#127 AC4). The runtime DERIVES a result class in OCaml
   — ascent-0's `result_contract.derivation` is prose, and a machine-executable
   derivation is a later slice — but it does not OWN the vocabulary: a class the
   IR does not declare is refused, and no receipt is emitted. *)
let declares (ir : t) (result_class : string) : bool =
  List.mem result_class ir.result_classes

(* How the refusal reads to an operator: the class the derivation produced, and
   the set the IR actually declared. *)
let undeclared_class_error (ir : t) (result_class : string) : string =
  Printf.sprintf
    "result_class %S is not declared in the IR's result_contract.result_classes \
     [%s]; the runtime refuses to emit a receipt carrying a class the CM does \
     not declare"
    result_class
    (String.concat ", " (List.map (Printf.sprintf "%S") ir.result_classes))
