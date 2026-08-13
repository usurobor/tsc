(* value.ml — the closed scalar domain shared by typed output ports, evidence
   predicates, checker configuration, and the result-rule algebra.

   Why a dedicated type rather than [Json.t]: the result evaluator must be
   TOTAL and its comparisons must be well-defined. [Json.t] carries [Null],
   [Arr] and [Obj], for which "less than" has no meaning the v0 algebra is
   willing to define. Narrowing the fact domain to three scalars makes every
   operator in the algebra total by construction instead of by a runtime guard
   that could be forgotten — and it is the reason [Rule] needs no exception
   handling at all.

   The narrowing is a DECLARED limit of v0, not an accident: a checker that
   needs to publish structured data publishes it as evidence (which is JSON and
   is digested and retained), and exposes the scalar projections a rule may read
   as named ports. That is the fact-provenance invariant doing its job. *)

type t =
  | Bool of bool
  | Int of int
  | Str of string

(* The type NAME, as it appears in schemas, config contracts and diagnostics.
   One spelling, used by every error message, so a config-type refusal and a
   port-schema refusal cannot disagree about what to call an integer. *)
let type_name = function
  | Bool _ -> "boolean"
  | Int _ -> "integer"
  | Str _ -> "string"

let to_json = function
  | Bool b -> Json.Bool b
  | Int i -> Json.Int i
  | Str s -> Json.Str s

(* Read a scalar back out of a JSON document. Non-scalars are [None]: the caller
   turns that into a typed error naming the field, so no fabricated default can
   enter the fact space. *)
let of_json : Json.t -> t option = function
  | Json.Bool b -> Some (Bool b)
  | Json.Int i -> Some (Int i)
  | Json.Str s -> Some (Str s)
  | _ -> None

let to_display = function
  | Bool b -> if b then "true" else "false"
  | Int i -> string_of_int i
  | Str s -> Printf.sprintf "%S" s

(* Content address of one fact, for the receipt's `fact_refs`. Digesting the
   canonical JSON of the value (not the OCaml representation) is what lets an
   independent verifier recompute the same digest from the receipt alone. *)
let digest (v : t) : string = "sha256:" ^ Json.digest (to_json v)

(* Equality is defined across the whole domain; ORDER is not. Comparing a
   boolean to a string is a category error in the methodology, not a fact about
   the subject, so [compare] refuses it rather than inventing OCaml's structural
   ordering between constructors. *)
let equal (a : t) (b : t) : bool =
  match a, b with
  | Bool x, Bool y -> x = y
  | Int x, Int y -> x = y
  | Str x, Str y -> String.equal x y
  | _ -> false

let compare_ordered (a : t) (b : t) : (int, string) result =
  match a, b with
  | Int x, Int y -> Ok (compare x y)
  | Str x, Str y -> Ok (String.compare x y)
  | Bool _, Bool _ ->
    Error "ordered comparison is not defined on booleans"
  | _ ->
    Error (Printf.sprintf
             "ordered comparison between a %s and a %s is not defined"
             (type_name a) (type_name b))
