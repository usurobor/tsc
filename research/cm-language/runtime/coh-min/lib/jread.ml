(* jread.ml — total, [result]-returning accessors over a parsed JSON document.

   `Json.member` and friends RAISE: they are the vendored ascent-0 surface and
   are kept byte-identical, so they cannot be softened in place. Every artifact
   validator in this runtime (`Ir`, `Rule`, `Request`, `Plan`, `Receipt`) must
   be TOTAL — an absent or ill-typed field is a fail-closed [Error] naming the
   dotted path at fault, never an exception and never a fabricated default.

   #127 proved that discipline for one artifact family by giving `ir.ml` its own
   private accessors. #129 has four artifact families, and four private copies
   of the same eight functions would be four places for the error vocabulary to
   drift. This module is the single copy: one spelling of "is missing", one
   spelling of "must be an object", shared by every validator, so a reviewer can
   grep one string and find every refusal site.

   Convention: [ctx] is the dotted path PREFIX of the enclosing object
   (`"result.rules[2]."`), [key] the field. Callers pass a [ctx] that already
   ends in `.` — or `""` at the document root. *)

let ( let* ) = Result.bind

let missing (ctx : string) (key : string) =
  Error (Printf.sprintf "%s%s is missing" ctx key)

let malformed (ctx : string) (key : string) (what : string) =
  Error (Printf.sprintf "%s%s must be %s" ctx key what)

(* One field of a JSON object, or [None] — also [None] when [j] is not an
   object at all, which the required-* helpers turn into a typed error. *)
let field (key : string) (j : Json.t) : Json.t option =
  match j with Json.Obj kvs -> List.assoc_opt key kvs | _ -> None

(* The key set of an object, in document order. Used for closedness checks
   (an undeclared field is refused, never ignored). *)
let keys (j : Json.t) : string list =
  match j with Json.Obj kvs -> List.map fst kvs | _ -> []

let is_obj (j : Json.t) : bool = match j with Json.Obj _ -> true | _ -> false

let required_string ~(ctx : string) (key : string) (j : Json.t) : (string, string) result =
  match field key j with
  | Some (Json.Str v) -> Ok v
  | Some _ -> malformed ctx key "a string"
  | None -> missing ctx key

let required_int ~(ctx : string) (key : string) (j : Json.t) : (int, string) result =
  match field key j with
  | Some (Json.Int v) -> Ok v
  | Some _ -> malformed ctx key "an integer"
  | None -> missing ctx key

let required_bool ~(ctx : string) (key : string) (j : Json.t) : (bool, string) result =
  match field key j with
  | Some (Json.Bool v) -> Ok v
  | Some _ -> malformed ctx key "a boolean"
  | None -> missing ctx key

let required_object ~(ctx : string) (key : string) (j : Json.t) : (Json.t, string) result =
  match field key j with
  | Some (Json.Obj _ as o) -> Ok o
  | Some _ -> malformed ctx key "an object"
  | None -> missing ctx key

let required_array ~(ctx : string) (key : string) (j : Json.t) : (Json.t list, string) result =
  match field key j with
  | Some (Json.Arr xs) -> Ok xs
  | Some _ -> malformed ctx key "an array"
  | None -> missing ctx key

(* Sequence a list of results; the FIRST error wins, so a message names the
   earliest fault in document order rather than an arbitrary one. *)
let all (rs : ('a, string) result list) : ('a list, string) result =
  List.fold_right
    (fun r acc ->
       match r, acc with
       | Error e, _ -> Error e
       | _, (Error _ as e) -> e
       | Ok x, Ok xs -> Ok (x :: xs))
    rs (Ok [])

let required_string_array ~(ctx : string) (key : string) (j : Json.t)
  : (string list, string) result =
  let* items = required_array ~ctx key j in
  all (List.map
         (function Json.Str v -> Ok v | _ -> malformed ctx key "an array of strings")
         items)

(* An OPTIONAL field with a declared default. Absence is lawful here — these are
   the only fields in the whole runtime where absence is not a refusal, and each
   call site documents why. *)
let optional_bool ~(ctx : string) (key : string) ~(default : bool) (j : Json.t)
  : (bool, string) result =
  match field key j with
  | None -> Ok default
  | Some (Json.Bool v) -> Ok v
  | Some _ -> malformed ctx key "a boolean"

(* Refuse any field the contract does not declare. Closedness is enforced by the
   runtime as well as by CUE (gate 9: neither mechanism is load-bearing alone),
   and a misspelled field is a methodology bug that must not execute. *)
let closed ~(ctx : string) ~(allowed : string list) (j : Json.t) : (unit, string) result =
  match List.filter (fun k -> not (List.mem k allowed)) (keys j) with
  | [] -> Ok ()
  | extra ->
    Error (Printf.sprintf "%s carries undeclared field(s) [%s]; permitted: [%s]"
             (if ctx = "" then "the document" else String.sub ctx 0 (String.length ctx - 1))
             (String.concat ", " (List.map (Printf.sprintf "%S") extra))
             (String.concat ", " (List.map (Printf.sprintf "%S") allowed)))

(* One scalar of the closed [Value] domain. Used for checker config and for
   rule-table literals. *)
let required_value ~(ctx : string) (key : string) (j : Json.t) : (Value.t, string) result =
  match field key j with
  | None -> missing ctx key
  | Some v ->
    (match Value.of_json v with
     | Some v -> Ok v
     | None -> malformed ctx key "a boolean, integer or string")

(* Uniqueness of a declared id set. Duplicate step ids, duplicate rule ids and
   duplicate class names are all silent-shadowing bugs; each is refused at load
   with the offending name. *)
let unique ~(what : string) (names : string list) : (unit, string) result =
  let rec go seen = function
    | [] -> Ok ()
    | n :: rest ->
      if List.mem n seen then
        Error (Printf.sprintf "duplicate %s %S" what n)
      else go (n :: seen) rest
  in
  go [] names
