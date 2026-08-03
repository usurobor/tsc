(* The frozen mathematical object: a deterministic pointed Mealy
   transducer  W = (S, s0, Sigma, Gamma, delta, lambda), pointed at s0 = 0,
   with 1 <= |S| <= N, over finite input alphabet Sigma and output
   alphabet Gamma, together with a canonical enumeration of the whole
   bounded class.

   Nothing here hard-codes any load-bearing count. Every cardinality a
   fixture reports (candidate set size, fiber size, separability) is
   *computed* by exhaustive enumeration below. *)

type config = {
  sigma : int;   (* |Sigma| : input alphabet size *)
  gamma : int;   (* |Gamma| : output alphabet size *)
  maxn  : int;   (* N : state bound, 1 <= |S| <= N *)
  ulen  : int;   (* query-universe max length: U = all Sigma-strings of length 1..ulen *)
}

(* A machine: n states (states are 0..n-1, initial state fixed at 0),
   tbl.(s*sigma + i) = (delta, lambda) for state s on input symbol i. *)
type machine = { n : int; tbl : (int * int) array }

let in_sym i = Char.chr (Char.code 'a' + i)          (* input symbol render:  0->a,1->b *)
let out_sym j = Char.chr (Char.code '0' + j)          (* output symbol render: 0->'0'   *)

let str_of_inputs (u : int array) : string =
  String.init (Array.length u) (fun i -> in_sym u.(i))

let str_of_outputs (y : int array) : string =
  String.init (Array.length y) (fun i -> out_sym y.(i))

let inputs_of_str (s : string) : int array =
  Array.init (String.length s) (fun i -> Char.code s.[i] - Char.code 'a')

let outputs_of_str (s : string) : int array =
  Array.init (String.length s) (fun i -> Char.code s.[i] - Char.code '0')

(* Canonical presentation of a machine as a stable, human-readable string.
   This *is* the "source / transition-law presentation" projection. *)
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

(* Deterministic run of the Mealy machine on an input history, from s0=0. *)
let run (cfg : config) (m : machine) (u : int array) : int array =
  let s = ref 0 in
  Array.map
    (fun i ->
       let (d, l) = m.tbl.(!s * cfg.sigma + i) in
       s := d; l)
    u

(* Complete canonical enumeration of every machine with exactly n states.
   Cells are ordered (state outer, input inner); each cell ranges over
   delta in 0..n-1 and lambda in 0..gamma-1 as a mixed-radix counter, most
   significant digit = first cell. This fixes ONE canonical order over the
   whole class, independent of any fixture. *)
let machines_with_n (cfg : config) (n : int) : machine list =
  let cells = n * cfg.sigma in
  let radix = n * cfg.gamma in
  let total =
    let t = ref 1 in for _ = 1 to cells do t := !t * radix done; !t
  in
  let acc = ref [] in
  for idx = total - 1 downto 0 do
    let tbl = Array.make cells (0, 0) in
    let rem = ref idx in
    (* decode least-significant cell last so cell 0 is most significant *)
    for c = cells - 1 downto 0 do
      let v = !rem mod radix in
      rem := !rem / radix;
      tbl.(c) <- (v / cfg.gamma, v mod cfg.gamma)
    done;
    acc := { n; tbl } :: !acc
  done;
  !acc

(* The complete bounded class H_M: machines with 1..N states, in canonical
   order (n ascending, then the per-n canonical order). *)
let enumerate_class (cfg : config) : machine list =
  let rec go n = if n > cfg.maxn then [] else machines_with_n cfg n @ go (n + 1) in
  go 1

let class_size (cfg : config) : int = List.length (enumerate_class cfg)

(* The finite query universe U: all Sigma-strings of length 1..ulen,
   in shortlex order. *)
let universe (cfg : config) : int array list =
  let rec strings_of_len len =
    if len = 0 then [ [||] ]
    else
      let prefixes = strings_of_len (len - 1) in
      List.concat_map
        (fun p ->
           List.init cfg.sigma (fun i -> Array.append p [| i |]))
        prefixes
  in
  let rec go len = if len > cfg.ulen then [] else strings_of_len len @ go (len + 1) in
  go 1

(* An observation / training trace: an input history and its observed output. *)
type trace = { input : int array; output : int array }

let trace_of_strings (i : string) (o : string) : trace =
  { input = inputs_of_str i; output = outputs_of_str o }

(* Exact fit: L_M(m, D) = 0  iff  m reproduces every observed output.
   Returns the number of disagreeing traces (the loss L_M). *)
let loss (cfg : config) (m : machine) (d : trace list) : int =
  List.fold_left
    (fun acc t -> if run cfg m t.input = t.output then acc else acc + 1)
    0 d

let fits (cfg : config) (m : machine) (d : trace list) : bool = loss cfg m d = 0

(* Complexity K_M(m): primary = state count. (kappa_M = N, so within-bound
   is automatic for the enumerated class; state count is retained so the
   receipt can show no tie-break exploits complexity.) *)
let complexity (m : machine) : int = m.n

(* The behavioral SIGNATURE of a machine over a query family J: the tuple
   of output strings, joined. Two machines are equivalent under ~=^J iff
   equal signatures. This is behavior-over-J equivalence; wider J refines
   finer (monotone by construction). *)
let signature (cfg : config) (m : machine) (j : int array list) : string =
  String.concat "|" (List.map (fun u -> str_of_outputs (run cfg m u)) j)

(* C_train: complete bounded set of candidates that exactly realize the
   training traces (L_M = 0), in canonical order. *)
let fit_candidates (cfg : config) (d : trace list) : machine list =
  List.filter (fun m -> fits cfg m d) (enumerate_class cfg)

(* A fiber over query family J: distinct behavioral classes among a
   candidate list, each with its canonically-least representative and the
   full membership. Preserves canonical order. *)
type fiber_class = {
  repr_id   : string;
  repr      : machine;
  sig_      : string;
  members   : string list;   (* canonical ids of all members *)
}

let fiber (cfg : config) (cands : machine list) (j : int array list) : fiber_class list =
  (* group by signature, preserving first-seen (canonical) order *)
  let order = ref [] in          (* signatures in first-seen order *)
  let tbl : (string, fiber_class) Hashtbl.t = Hashtbl.create 64 in
  List.iter
    (fun m ->
       let s = signature cfg m j in
       let id = canonical_id cfg m in
       match Hashtbl.find_opt tbl s with
       | None ->
         Hashtbl.replace tbl s
           { repr_id = id; repr = m; sig_ = s; members = [ id ] };
         order := s :: !order
       | Some fc ->
         Hashtbl.replace tbl s { fc with members = fc.members @ [ id ] })
    cands;
  List.rev_map (fun s -> Hashtbl.find tbl s) !order |> List.rev
  (* note: !order is reverse-first-seen; rev restores canonical order *)

(* For a held-out query q, the set of DISTINCT predicted outputs across a
   fiber's classes. |distinct| >= 2  <=>  q separates the fiber. Predictions
   are public (each candidate is a concrete machine); only the *true* output
   is sealed. *)
let predictions_on (cfg : config) (classes : fiber_class list) (q : int array)
  : (string * string) list =
  (* (representative id, predicted output string) *)
  List.map (fun fc -> (fc.repr_id, str_of_outputs (run cfg fc.repr q))) classes

let distinct_predictions (cfg : config) (classes : fiber_class list) (q : int array)
  : string list =
  List.sort_uniq compare
    (List.map (fun fc -> str_of_outputs (run cfg fc.repr q)) classes)
