(* ascent0_gen — the executable fixture generator + sealed oracle for the
   Ascent-0 `source = behavior` slice (GitHub #119).

   Modes:
     emit    [OUTDIR]   generate all public artifacts + reveal bundle + MANIFEST
     replay  [OUTDIR]   regenerate in memory and prove byte identity vs on-disk
     verify  [OUTDIR]   prove the sealed-oracle commitments bind the reveal bundle
     selftest           run the SHA-256 known-answer test only

   Nothing load-bearing is hand-typed: see cases.ml. Digests are real
   SHA-256 (see sha256.ml), reproducible with the system `sha256sum`. *)

let default_out = "generated"

(* ---- tiny filesystem helpers ---- *)
let rec mkdir_p (dir : string) : unit =
  if dir = "" || dir = "." || Sys.file_exists dir then ()
  else begin
    mkdir_p (Filename.dirname dir);
    (try Unix.mkdir dir 0o755 with Unix.Unix_error (Unix.EEXIST, _, _) -> ())
  end

let write_file (path : string) (content : string) : unit =
  mkdir_p (Filename.dirname path);
  let oc = open_out_bin path in
  output_string oc content;
  close_out oc

let read_file (path : string) : string =
  let ic = open_in_bin path in
  let n = in_channel_length ic in
  let s = really_input_string ic n in
  close_in ic; s

(* ---- assemble the artifact set (relpath, content) ---- *)

let build () : (string * string) list * (string * string) list =
  let cases =
    [ Cases.build_case1 (); Cases.build_case2 (); Cases.build_case3 ();
      Cases.build_case4 (); Cases.build_case5 () ]
  in
  let public = ref [] and reveal = ref [] in
  List.iter
    (fun (name, sem, pub, rev) ->
       public := (Printf.sprintf "cases/%s/semantic_input.txt" name, sem) :: !public;
       public := (Printf.sprintf "cases/%s/public.json" name, Serialize.document pub) :: !public;
       match rev with
       | Some (fn, rj) -> reveal := (Printf.sprintf "reveal/%s" fn, Serialize.document rj) :: !reveal
       | None -> ())
    cases;
  let (class_json, sep_ok) = Cases.class_doc () in
  if not sep_ok then failwith "class: query universe U is not a complete separator";
  public := ("class.json", Serialize.document class_json) :: !public;
  public := ("minimality.json", Serialize.document (Cases.minimality_doc ())) :: !public;
  (* index summary — computed from the other public artifacts' digests *)
  let idx_cases =
    List.map
      (fun (name, _, pub, rev) ->
         let pub_doc = Serialize.document pub in
         let entry =
           [ ("case", Serialize.Str name);
             ("public_json_sha256", Serialize.Str (Sha256.digest_string pub_doc)) ]
         in
         let entry =
           match rev with
           | Some (fn, rj) ->
             entry
             @ [ ("reveal_file", Serialize.Str (Printf.sprintf "reveal/%s" fn));
                 ("oracle_commitment_sha256",
                  Serialize.Str (Sha256.digest_string (Serialize.document rj))) ]
           | None -> entry
         in
         Serialize.Obj entry)
      cases
  in
  let index =
    Serialize.Obj
      [ ("artifact", Serialize.Str "ascent-0 source=behavior fixture set (#119)");
        ("config",
         Serialize.Obj [ ("N", Serialize.Int 2); ("Sigma_size", Serialize.Int 2);
                         ("Gamma_size", Serialize.Int 2);
                         ("query_universe_max_length", Serialize.Int 3);
                         ("class_size", Serialize.Int (Mealy.class_size Cases.cfg)) ]);
        ("result_rule",
         Serialize.Str
           "not admissible -> DECORATIVE_LIFT; else |C_train|=0 -> \
            NO_REALIZATION_IN_MODEL; else oracle_run & separating & pass>=1 & \
            tested_fiber=1 -> LIFT_VALIDATED; else |F_id|>=2 -> \
            ASCENT_UNDERDETERMINED; else IDENTIFIED_IN_MODEL");
        ("cases", Serialize.Arr idx_cases) ]
  in
  public := ("index.json", Serialize.document index) :: !public;
  (List.sort compare !public, List.sort compare !reveal)

(* ---- MANIFEST (sha256sum -c compatible) over the public artifacts ---- *)
let manifest_of (public : (string * string) list) : string =
  let lines =
    List.map (fun (p, c) -> Printf.sprintf "%s  %s" (Sha256.digest_string c) p)
      (List.sort compare public)
  in
  String.concat "\n" lines ^ "\n"

(* ---- modes ---- *)

let emit outdir =
  Sha256.self_test ();
  let (public, reveal) = build () in
  List.iter (fun (p, c) -> write_file (Filename.concat outdir p) c) public;
  List.iter (fun (p, c) -> write_file (Filename.concat outdir p) c) reveal;
  let man = manifest_of public in
  write_file (Filename.concat outdir "MANIFEST.sha256") man;
  Printf.printf "emit -> %s\n" outdir;
  Printf.printf "  public artifacts: %d   reveal artifacts: %d\n"
    (List.length public) (List.length reveal);
  Printf.printf "  MANIFEST.sha256 (%d entries):\n" (List.length public);
  List.iter (fun (p, c) -> Printf.printf "    %s  %s\n" (Sha256.digest_string c) p)
    (List.sort compare public);
  Printf.printf "  manifest digest: %s\n" (Sha256.digest_string man);
  List.iter
    (fun (p, c) -> Printf.printf "  reveal digest (oracle commitment): %s  %s\n"
        (Sha256.digest_string c) p)
    (List.sort compare reveal);
  0

let replay outdir =
  Sha256.self_test ();
  let (public, reveal) = build () in
  let ok = ref true in
  let check (p, c) =
    let path = Filename.concat outdir p in
    if not (Sys.file_exists path) then begin
      Printf.printf "  MISSING   %s\n" p; ok := false
    end else begin
      let disk = read_file path in
      let dg = Sha256.digest_string c and dgd = Sha256.digest_string disk in
      if disk = c then Printf.printf "  MATCH     %s  %s\n" dg p
      else begin
        Printf.printf "  MISMATCH  %s (rebuilt %s vs disk %s)\n" p dg dgd; ok := false
      end
    end
  in
  Printf.printf "replay <- %s (byte-identity: rebuilt vs committed)\n" outdir;
  Printf.printf " public:\n"; List.iter check (List.sort compare public);
  Printf.printf " reveal:\n"; List.iter check (List.sort compare reveal);
  (* also confirm the on-disk MANIFEST matches the rebuilt one *)
  let man = manifest_of public in
  let manpath = Filename.concat outdir "MANIFEST.sha256" in
  if Sys.file_exists manpath && read_file manpath = man then
    Printf.printf " MANIFEST.sha256 MATCH  %s\n" (Sha256.digest_string man)
  else begin Printf.printf " MANIFEST.sha256 MISMATCH\n"; ok := false end;
  if !ok then (Printf.printf "REPLAY OK: all artifacts byte-identical\n"; 0)
  else (Printf.printf "REPLAY FAILED\n"; 1)

(* verify that each sealed oracle commitment (in the on-disk public.json)
   equals sha256 of the on-disk reveal file, and that the sealed output is
   the hidden machine's genuine reply (the oracle is not lying). *)
let verify outdir =
  Sha256.self_test ();
  let ok = ref true in
  let sealed =
    [ ("case1_lift_validated", "reveal/case1_lift_validated.json");
      ("case5_roundtrip", "reveal/case5_roundtrip.json") ]
  in
  Printf.printf "verify <- %s (sealed-oracle commit/reveal binding)\n" outdir;
  List.iter
    (fun (name, revrel) ->
       let pubpath = Filename.concat outdir (Printf.sprintf "cases/%s/public.json" name) in
       let revpath = Filename.concat outdir revrel in
       if not (Sys.file_exists pubpath && Sys.file_exists revpath) then begin
         Printf.printf "  %s: MISSING files\n" name; ok := false
       end else begin
         let pub = read_file pubpath and rev = read_file revpath in
         let rev_digest = Sha256.digest_string rev in
         (* extract oracle_commitment_sha256 value from the public json text *)
         let key = "\"oracle_commitment_sha256\": \"" in
         let committed =
           match
             (let rec idx i =
                if i + String.length key > String.length pub then None
                else if String.sub pub i (String.length key) = key then Some (i + String.length key)
                else idx (i + 1)
              in idx 0)
           with
           | Some start ->
             let stop = String.index_from pub start '"' in
             Some (String.sub pub start (stop - start))
           | None -> None
         in
         (match committed with
          | Some c when c = rev_digest ->
            Printf.printf "  %s: commitment BINDS reveal  %s\n" name rev_digest
          | Some c ->
            Printf.printf "  %s: commitment MISMATCH (public %s vs reveal %s)\n" name c rev_digest;
            ok := false
          | None -> Printf.printf "  %s: no commitment field found\n" name; ok := false)
       end)
    sealed;
  (* internal-consistency: the latch's genuine reply matches each sealed output *)
  let check_out q expect =
    let got = Mealy.str_of_outputs (Mealy.run Cases.cfg Cases.w_latch (Mealy.inputs_of_str q)) in
    if got = expect then Printf.printf "  oracle-not-lying: W(%s)=%s = sealed output\n" q got
    else (Printf.printf "  oracle LYING: W(%s)=%s <> sealed %s\n" q got expect; ok := false)
  in
  check_out "ab" "01";
  if !ok then (Printf.printf "VERIFY OK\n"; 0) else (Printf.printf "VERIFY FAILED\n"; 1)

let () =
  let args = Array.to_list Sys.argv in
  let exit_code =
    match args with
    | _ :: "emit" :: rest -> emit (match rest with d :: _ -> d | [] -> default_out)
    | _ :: "replay" :: rest -> replay (match rest with d :: _ -> d | [] -> default_out)
    | _ :: "verify" :: rest -> verify (match rest with d :: _ -> d | [] -> default_out)
    | _ :: "selftest" :: _ -> Sha256.self_test (); Printf.printf "SHA-256 self-test OK\n"; 0
    | _ ->
      Printf.printf
        "usage: ascent0_gen (emit|replay|verify) [OUTDIR] | selftest\n"; 2
  in
  exit exit_code
