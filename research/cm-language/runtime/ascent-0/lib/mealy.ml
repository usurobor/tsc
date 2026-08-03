(* The bounded model class H_M, reimplemented independently for the Sub-3
   runtime. This is NOT linked from the Sub-1 generator; it is the runtime's own
   computation of the frozen mathematical object declared in the fixture's
   class.json (a deterministic pointed Mealy transducer, canonical enumeration).

   NOTHING here reads the fixture's precomputed candidate sets, fibers, or
   predictions. Given only the PUBLIC bounds (N, |Sigma|, |Gamma|, U-length) and
   the PUBLIC training traces, this module:
     - enumerate  : materialises the whole bounded class by real enumeration,
     - run        : executes a candidate's transition law on any input word,
     - fit        : keeps the exact-fit candidates (L_M = 0),
     - fiber      : quotients by behavioural equivalence over a query family,
     - predict    : runs each surviving candidate's law on the held-out query.
   Every cardinality the receipt reports is computed here, not read. *)

type config = {
  sigma : int;   (* |Sigma| *)
  gamma : int;   (* |Gamma| *)
  maxn  : int;   (* N : state bound, 1 <= |S| <= N *)
  ulen  : int;   (* U = all Sigma-strings of length 1..ulen *)
}

(* n states (0..n-1, initial state fixed at 0);
   tbl.(s*sigma + i) = (delta, lambda) for state s on input symbol i. *)
type machine = { n : int; tbl : (int * int) array }

let in_sym i = Char.chr (Char.code 'a' + i)     (* 0->a, 1->b *)
let out_sym j = Char.chr (Char.code '0' + j)    (* 0->'0', 1->'1' *)

let inputs_of_str (s : string) : int array =
  Array.init (String.length s) (fun i -> Char.code s.[i] - Char.code 'a')

let str_of_outputs (y : int array) : string =
  String.init (Array.length y) (fun i -> out_sym y.(i))

(* Canonical transition-law presentation (the "source" polar projection). Format
   matches the frozen class so a recovered candidate is comparable to the sealed
   generator: "n2; 0a->1/0; 0b->0/0; 1a->1/1; 1b->1/1". *)
let canonical_id (cfg : config) (m : machine) : string =
  let buf = Buffer.create 64 in
  Buffer.add_string buf (Printf.sprintf "n%d" m.n);
  for s = 0 to m.n - 1 do
    for i = 0 to cfg.sigma - 1 do
      let (d, l) = m.tbl.(s * cfg.sigma + i) in
      Buffer.add_string buf
        (Printf.sprintf "; %d%c->%d/%c" s (in_sym i) d (out_sym l))
    done
  done;
  Buffer.contents buf

(* Deterministic run from s0 = 0: fold the transition/output law over the word. *)
let run (cfg : config) (m : machine) (u : int array) : int array =
  let s = ref 0 in
  Array.map
    (fun i -> let (d, l) = m.tbl.(!s * cfg.sigma + i) in s := d; l)
    u

let run_str (cfg : config) (m : machine) (word : string) : string =
  str_of_outputs (run cfg m (inputs_of_str word))

(* Every machine with exactly n states, in canonical order. Cells ordered
   (state outer, input inner); each cell a mixed-radix digit over
   (delta in 0..n-1, lambda in 0..gamma-1), first cell most significant. *)
let machines_with_n (cfg : config) (n : int) : machine list =
  let cells = n * cfg.sigma in
  let radix = n * cfg.gamma in
  let total = ref 1 in
  for _ = 1 to cells do total := !total * radix done;
  let acc = ref [] in
  for idx = !total - 1 downto 0 do
    let tbl = Array.make cells (0, 0) in
    let rem = ref idx in
    for c = cells - 1 downto 0 do
      let v = !rem mod radix in
      rem := !rem / radix;
      tbl.(c) <- (v / cfg.gamma, v mod cfg.gamma)
    done;
    acc := { n; tbl } :: !acc
  done;
  !acc

(* The whole bounded class H_M: n ascending 1..N, per-n canonical order. *)
let enumerate (cfg : config) : machine list =
  let rec go n = if n > cfg.maxn then [] else machines_with_n cfg n @ go (n + 1) in
  go 1

(* The finite query universe U: all Sigma-strings of length 1..ulen, shortlex. *)
let universe (cfg : config) : int array list =
  let rec of_len len =
    if len = 0 then [ [||] ]
    else
      List.concat_map
        (fun p -> List.init cfg.sigma (fun i -> Array.append p [| i |]))
        (of_len (len - 1))
  in
  let rec go len = if len > cfg.ulen then [] else of_len len @ go (len + 1) in
  go 1

type trace = { input : int array; output : int array }

let trace_of_strings (i : string) (o : string) : trace =
  { input = inputs_of_str i;
    output = Array.init (String.length o) (fun k -> Char.code o.[k] - Char.code '0') }

(* L_M(m, D): number of training traces whose predicted reply differs. *)
let loss (cfg : config) (m : machine) (d : trace list) : int =
  List.fold_left
    (fun acc t -> if run cfg m t.input = t.output then acc else acc + 1)
    0 d

let fits (cfg : config) (m : machine) (d : trace list) : bool = loss cfg m d = 0

(* C_train: the complete exact-fit set over the enumerated class. *)
let fit (cfg : config) (cls : machine list) (d : trace list) : machine list =
  List.filter (fun m -> fits cfg m d) cls

(* Behavioural signature over a query family J (join of reply words). *)
let signature (cfg : config) (m : machine) (j : int array list) : string =
  String.concat "|" (List.map (fun u -> str_of_outputs (run cfg m u)) j)

type fiber_class = {
  repr_id : string;
  repr    : machine;
  sig_    : string;
  members : string list;   (* canonical ids of all members *)
}

(* Quotient a candidate list by ~=^J, preserving canonical (first-seen) order. *)
let fiber (cfg : config) (cands : machine list) (j : int array list) : fiber_class list =
  let order = ref [] in
  let tbl : (string, fiber_class) Hashtbl.t = Hashtbl.create 64 in
  List.iter
    (fun m ->
       let s = signature cfg m j in
       let id = canonical_id cfg m in
       match Hashtbl.find_opt tbl s with
       | None ->
         Hashtbl.replace tbl s { repr_id = id; repr = m; sig_ = s; members = [ id ] };
         order := s :: !order
       | Some fc ->
         Hashtbl.replace tbl s { fc with members = fc.members @ [ id ] })
    cands;
  List.rev_map (fun s -> Hashtbl.find tbl s) !order |> List.rev
