(* Minimal, dependency-free JSON: a recursive-descent PARSER (to read the
   fixture's public inputs + the sealed reveal bundle + the hand-authored IR)
   and a canonical SERIALIZER (to emit a reproducible MeasurementReceipt and to
   content-address the SandboxExecutionPlan). Stdlib only. Object keys are
   emitted in lexicographic order, arrays keep insertion order, two-space
   indent, LF newlines, trailing newline — the same canonical form the Sub-1
   fixture uses, so digests are reproducible with the system sha256sum. *)

type t =
  | Null
  | Bool of bool
  | Int of int
  | Float of float
  | Str of string
  | Arr of t list
  | Obj of (string * t) list

(* ─────────────────────────────── parser ─────────────────────────────── *)

exception Parse_error of string

let parse (s : string) : t =
  let n = String.length s in
  let pos = ref 0 in
  let peek () = if !pos < n then s.[!pos] else '\000' in
  let adv () = incr pos in
  let rec skip_ws () =
    if !pos < n then
      match s.[!pos] with
      | ' ' | '\t' | '\n' | '\r' -> adv (); skip_ws ()
      | _ -> ()
  in
  let fail msg = raise (Parse_error (Printf.sprintf "%s at offset %d" msg !pos)) in
  let expect c =
    if peek () = c then adv () else fail (Printf.sprintf "expected %c" c)
  in
  let parse_string () =
    expect '"';
    let buf = Buffer.create 16 in
    let rec go () =
      if !pos >= n then fail "unterminated string";
      let c = s.[!pos] in
      adv ();
      match c with
      | '"' -> Buffer.contents buf
      | '\\' ->
        let e = s.[!pos] in
        adv ();
        (match e with
         | '"' -> Buffer.add_char buf '"'
         | '\\' -> Buffer.add_char buf '\\'
         | '/' -> Buffer.add_char buf '/'
         | 'n' -> Buffer.add_char buf '\n'
         | 't' -> Buffer.add_char buf '\t'
         | 'r' -> Buffer.add_char buf '\r'
         | 'b' -> Buffer.add_char buf '\b'
         | 'f' -> Buffer.add_char buf '\012'
         | 'u' ->
           (* minimal \uXXXX: keep ASCII, drop non-ASCII to '?' — the fixtures
              this runtime reads are ASCII, so this path is not exercised. *)
           let hex = String.sub s !pos 4 in
           pos := !pos + 4;
           let code = int_of_string ("0x" ^ hex) in
           if code < 128 then Buffer.add_char buf (Char.chr code)
           else Buffer.add_char buf '?'
         | _ -> fail "bad escape");
        go ()
      | c -> Buffer.add_char buf c; go ()
    in
    go ()
  in
  let rec parse_value () =
    skip_ws ();
    match peek () with
    | '{' -> parse_obj ()
    | '[' -> parse_arr ()
    | '"' -> Str (parse_string ())
    | 't' -> pos := !pos + 4; Bool true
    | 'f' -> pos := !pos + 5; Bool false
    | 'n' -> pos := !pos + 4; Null
    | c when c = '-' || (c >= '0' && c <= '9') -> parse_number ()
    | _ -> fail "unexpected character"
  and parse_number () =
    let start = !pos in
    let is_float = ref false in
    let cont () =
      match peek () with
      | '0'..'9' | '-' | '+' -> true
      | '.' | 'e' | 'E' -> is_float := true; true
      | _ -> false
    in
    while !pos < n && cont () do adv () done;
    let tok = String.sub s start (!pos - start) in
    if !is_float then Float (float_of_string tok) else Int (int_of_string tok)
  and parse_arr () =
    expect '[';
    skip_ws ();
    if peek () = ']' then (adv (); Arr [])
    else begin
      let items = ref [] in
      let rec go () =
        let v = parse_value () in
        items := v :: !items;
        skip_ws ();
        match peek () with
        | ',' -> adv (); go ()
        | ']' -> adv ()
        | _ -> fail "expected , or ]"
      in
      go ();
      Arr (List.rev !items)
    end
  and parse_obj () =
    expect '{';
    skip_ws ();
    if peek () = '}' then (adv (); Obj [])
    else begin
      let items = ref [] in
      let rec go () =
        skip_ws ();
        let k = parse_string () in
        skip_ws ();
        expect ':';
        let v = parse_value () in
        items := (k, v) :: !items;
        skip_ws ();
        match peek () with
        | ',' -> adv (); go ()
        | '}' -> adv ()
        | _ -> fail "expected , or }"
      in
      go ();
      Obj (List.rev !items)
    end
  in
  let v = parse_value () in
  skip_ws ();
  v

let parse_file (path : string) : t =
  let ic = open_in_bin path in
  let len = in_channel_length ic in
  let s = really_input_string ic len in
  close_in ic;
  parse s

(* ───────────────────────────── accessors ───────────────────────────── *)

let member (key : string) (j : t) : t =
  match j with
  | Obj kvs -> (try List.assoc key kvs with Not_found ->
      raise (Parse_error (Printf.sprintf "no member %S" key)))
  | _ -> raise (Parse_error (Printf.sprintf "member %S of non-object" key))

let member_opt (key : string) (j : t) : t option =
  match j with Obj kvs -> List.assoc_opt key kvs | _ -> None

let to_string = function
  | Str s -> s
  | _ -> raise (Parse_error "expected string")

let to_int = function
  | Int i -> i
  | _ -> raise (Parse_error "expected int")

let to_list = function
  | Arr l -> l
  | _ -> raise (Parse_error "expected array")

(* ──────────────────────────── serializer ───────────────────────────── *)

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

let rec render ?(indent = 0) (j : t) : string =
  let pad k = String.make (k * 2) ' ' in
  match j with
  | Null -> "null"
  | Bool b -> if b then "true" else "false"
  | Int i -> string_of_int i
  | Float f ->
    (* integers-as-floats render without trailing dot; else %g *)
    if Float.is_integer f then Printf.sprintf "%.0f" f else Printf.sprintf "%g" f
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

let document (j : t) : string = render j ^ "\n"

let digest (j : t) : string = Sha256.digest_string (document j)
