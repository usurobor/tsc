(** Witness numeric contract vector (v3.2.3).

    The seven numeric fields of the witness response contract — the
    fields the consistency protocol spreads over and the medoid
    election measures distance on (skills/cm-of-cms/SKILL.md §3;
    skills/self-measure/SKILL.md consistency block). One source of
    truth: the spread report and the medoid both consume this module.

    Pure module — the only I/O is [of_json_file] reading one file. *)

(** Contract fields, in canonical report order. *)
type field =
  | Alpha
  | Beta
  | Gamma
  | Delta_alpha_beta
  | Delta_beta_gamma
  | Delta_gamma_alpha
  | Confidence

let all_fields =
  [ Alpha; Beta; Gamma;
    Delta_alpha_beta; Delta_beta_gamma; Delta_gamma_alpha;
    Confidence ]

let field_name = function
  | Alpha -> "alpha"
  | Beta -> "beta"
  | Gamma -> "gamma"
  | Delta_alpha_beta -> "delta_alpha_beta"
  | Delta_beta_gamma -> "delta_beta_gamma"
  | Delta_gamma_alpha -> "delta_gamma_alpha"
  | Confidence -> "confidence"

(** One response's numeric contract values, in [all_fields] order. *)
type vector = float array

let get (v : vector) (f : field) : float =
  let rec index i = function
    | [] -> invalid_arg "Witness_numeric.get"
    | x :: _ when x = f -> i
    | _ :: rest -> index (i + 1) rest
  in
  v.(index 0 all_fields)

(** Parse a witness response file into its numeric vector.
    [Error] names the file and the offending field — malformed inputs
    are visible, never silently coerced. *)
let of_json_file path : (vector, string) result =
  match
    (try Ok (Yojson.Safe.from_file path)
     with
     | Sys_error e -> Error e
     | Yojson.Json_error e -> Error (Printf.sprintf "%s: %s" path e))
  with
  | Error e -> Error e
  | Ok json ->
    (match json with
     | `Assoc fields ->
       let rec collect acc = function
         | [] -> Ok (Array.of_list (List.rev acc))
         | f :: rest ->
           let name = field_name f in
           (match List.assoc_opt name fields with
            | Some (`Float x) -> collect (x :: acc) rest
            | Some (`Int i) -> collect (Float.of_int i :: acc) rest
            | Some _ ->
              Error (Printf.sprintf "%s: field '%s' is not a number"
                       path name)
            | None ->
              Error (Printf.sprintf "%s: missing numeric field '%s'"
                       path name))
       in
       collect [] all_fields
     | _ -> Error (Printf.sprintf "%s: not a JSON object" path))

(** Total L1 distance between two vectors. *)
let l1_distance (a : vector) (b : vector) : float =
  let d = ref 0.0 in
  Array.iteri (fun i x -> d := !d +. Float.abs (x -. b.(i))) a;
  !d

(** Per-field values and max-absolute-pairwise spread across vectors.
    Returns entries in [all_fields] order: (field, values, spread). *)
let per_field_spread (vs : vector list) : (field * float list * float) list =
  List.mapi (fun i f ->
    let vals = List.map (fun v -> v.(i)) vs in
    let spread =
      List.fold_left (fun acc a ->
        List.fold_left (fun acc b ->
          Float.max acc (Float.abs (a -. b))) acc vals)
        0.0 vals
    in
    (f, vals, spread)
  ) all_fields

(** The consistency delta: max per-field spread across all fields. *)
let max_spread (vs : vector list) : float =
  List.fold_left (fun acc (_, _, s) -> Float.max acc s)
    0.0 (per_field_spread vs)

(** Per-field MEAN absolute pairwise difference — the k-fair companion
    statistic (Issue D): unlike the max, the mean of all m(m-1)/2
    pairwise differences does not grow monotonically with sample count,
    so k=3 and k=5 readings are comparable. Returns entries in
    [all_fields] order. Requires >= 2 vectors (0.0 per field otherwise
    is never emitted — callers enforce the arity upstream). *)
let per_field_mean_pairwise (vs : vector list) : (field * float) list =
  List.mapi (fun i f ->
    let vals = List.map (fun v -> v.(i)) vs in
    let total = ref 0.0 and pairs = ref 0 in
    let rec walk = function
      | [] -> ()
      | a :: rest ->
        List.iter (fun b ->
          total := !total +. Float.abs (a -. b);
          incr pairs) rest;
        walk rest
    in
    walk vals;
    (f, if !pairs = 0 then 0.0 else !total /. Float.of_int !pairs)
  ) all_fields

(** The k-fair consistency delta: max over fields of the per-field
    mean pairwise difference. *)
let max_mean_pairwise (vs : vector list) : float =
  List.fold_left (fun acc (_, d) -> Float.max acc d)
    0.0 (per_field_mean_pairwise vs)
