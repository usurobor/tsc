(* Canonical, dependency-free JSON serialization. Deterministic bytes so
   that a re-run produces byte-identical artifacts and matching SHA-256
   digests. Object keys are emitted in lexicographic order; arrays keep
   their given order; two-space indent; LF newlines; trailing newline. *)

type json =
  | Null
  | Bool of bool
  | Int of int
  | Str of string
  | Arr of json list
  | Obj of (string * json) list

let escape (s : string) : string =
  let buf = Buffer.create (String.length s + 2) in
  String.iter
    (fun c ->
       match c with
       | '"' -> Buffer.add_string buf "\\\""
       | '\\' -> Buffer.add_string buf "\\\\"
       | '\n' -> Buffer.add_string buf "\\n"
       | '\t' -> Buffer.add_string buf "\\t"
       | '\r' -> Buffer.add_string buf "\\r"
       | c -> Buffer.add_char buf c)
    s;
  Buffer.contents buf

let rec render ?(indent = 0) (j : json) : string =
  let pad n = String.make (n * 2) ' ' in
  match j with
  | Null -> "null"
  | Bool b -> if b then "true" else "false"
  | Int i -> string_of_int i
  | Str s -> "\"" ^ escape s ^ "\""
  | Arr [] -> "[]"
  | Arr xs ->
    let items =
      List.map (fun x -> pad (indent + 1) ^ render ~indent:(indent + 1) x) xs
    in
    "[\n" ^ String.concat ",\n" items ^ "\n" ^ pad indent ^ "]"
  | Obj [] -> "{}"
  | Obj kvs ->
    let sorted = List.sort (fun (a, _) (b, _) -> compare a b) kvs in
    let items =
      List.map
        (fun (k, v) ->
           pad (indent + 1) ^ "\"" ^ escape k ^ "\": "
           ^ render ~indent:(indent + 1) v)
        sorted
    in
    "{\n" ^ String.concat ",\n" items ^ "\n" ^ pad indent ^ "}"

(* Full document string: canonical render + trailing newline. This exact
   string is what gets hashed and written to disk. *)
let document (j : json) : string = render j ^ "\n"

let digest_of_document (j : json) : string = Sha256.digest_string (document j)
