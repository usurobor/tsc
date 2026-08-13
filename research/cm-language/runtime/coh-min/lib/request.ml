(* request.ml — `tsc-run-request/0.1`: the run request as a first-class,
   canonical, content-addressed ARTIFACT, and the named snapshot scheme that
   makes its subject binding recomputable.

   §WHY THE SUBJECT IS A DIGEST AND NOT A PATH (issue AC9). `--target ./fixtures/
   present` is a LOCATOR: it says where this host happens to keep the bytes. It
   is not identity. Two hosts can offer the same path with different content, the
   same content at different paths, and neither can be checked after the fact. A
   receipt that binds a path proves nothing; a receipt that binds a content
   digest can be re-derived by anyone who has the subject.

   So every subject entry carries `kind`, `scheme` and `digest`. The SCHEME is
   the part that is easy to leave out and fatal to leave out: a digest is only
   recomputable if you know how the snapshot was constructed. The design defers
   the CATALOG of schemes but not the requirement to name one, and an absent or
   unrecognized scheme refuses fail-closed here.

   §`directory-merkle/0.1` — the one scheme this runtime implements.

     1. Walk the located directory recursively. Every REGULAR FILE reachable
        from the root is included; directories contribute only through their
        files, so an empty directory is invisible to the digest. There are NO
        exclusions — not `.git`, not dotfiles: an exclusion list that is not in
        the scheme name is an unrecordable difference between two runs.
     2. For each file compute `sha256(contents)` and its subject-relative path
        with `/` separators.
     3. Sort the (path, digest) pairs by `String.compare` on the PATH. Sorting
        the flat path list — rather than relying on directory-traversal order —
        is what makes the digest independent of the filesystem's readdir order.
     4. Emit one line per file, `"<hex>  <path>\n"` (two spaces: the `sha256sum`
        convention, so the manifest is reproducible with coreutils).
     5. The snapshot digest is `sha256` of that concatenation.

   Symlinks are followed by the stdlib's `Sys.is_directory`/`open_in`, and the
   stdlib gives no way to distinguish a symlink from its target without Unix,
   which the contract forbids. `0.1` therefore digests link TARGETS, and that is
   a property of the named scheme rather than an unrecorded accident — a scheme
   that treats them differently must take a different name. *)

module J = Json
open Jread

let ( let* ) = Result.bind

let format_pin = "tsc-run-request/0.1"

let canonical_blocks =
  [ "format"; "cm_ir"; "subject"; "profile"; "parameters"; "capability_ceiling"; "bounds" ]

(* v0 defines exactly one profile. Deferral is not a free-form extension point:
   an unknown profile refuses rather than being ignored. *)
let profile_pin = "default"

(* ─────────────────────── the named snapshot schemes ──────────────────── *)

let directory_merkle = "directory-merkle/0.1"

(* The complete catalog. An entry names (scheme, subject kind) together, because
   a scheme is only meaningful for the kind of thing it snapshots. *)
let snapshot_schemes = [ (directory_merkle, "directory_snapshot") ]

let rec collect_files ~(root : string) ~(prefix : string) : string list =
  let dir = if prefix = "" then root else Filename.concat root prefix in
  let entries = Sys.readdir dir in
  Array.sort String.compare entries;
  Array.to_list entries
  |> List.concat_map (fun name ->
      let rel = if prefix = "" then name else prefix ^ "/" ^ name in
      let abs = Filename.concat dir name in
      if Sys.is_directory abs then collect_files ~root ~prefix:rel else [ rel ])

(* A subject entry that cannot be READ cannot be digested, and a snapshot that
   silently omitted it would bind an identity that is not the subject's. The
   scheme covers every regular file reachable from the root, so an unreadable
   one — a device node, a socket, a permission-denied file — REFUSES the whole
   snapshot rather than being skipped. That is the fail-closed reading, and it
   is why this returns a [result] instead of raising: the caller turns it into
   one sentence and no receipt is produced. *)
let file_digest (path : string) : (string, string) result =
  try
    let ic = open_in_bin path in
    Fun.protect ~finally:(fun () -> close_in_noerr ic)
      (fun () -> Ok (Sha256.digest_string (really_input_string ic (in_channel_length ic))))
  with
  | Sys_error msg ->
    Error (Printf.sprintf
             "scheme %s cannot digest %S: %s; every regular file reachable from \
              the subject root must be readable, so an unreadable entry refuses \
              the snapshot rather than being silently omitted" directory_merkle path msg)
  | End_of_file | Invalid_argument _ ->
    Error (Printf.sprintf
             "scheme %s cannot digest %S: it is not a readable regular file"
             directory_merkle path)

(* The scheme's MANIFEST — the exact bytes that are digested. It is returned
   alongside the digest so the runtime can retain it as evidence and a reader
   can see what was measured, rather than being asked to trust a hex string. *)
let directory_merkle_manifest (root : string) : (string, string) result =
  let* lines =
    all (List.map
           (fun rel ->
              let* d = file_digest (Filename.concat root rel) in
              Ok (Printf.sprintf "%s  %s\n" d rel))
           (List.sort String.compare (collect_files ~root ~prefix:"")))
  in
  Ok (String.concat "" lines)

let snapshot ~(scheme : string) ~(root : string) : (string * string, string) result =
  if not (String.equal scheme directory_merkle) then
    Error (Printf.sprintf
             "subject scheme %S is not implemented by this runtime; known schemes \
              are [%s]" scheme
             (String.concat ", " (List.map (fun (s, _) -> Printf.sprintf "%S" s) snapshot_schemes)))
  else if not (Sys.file_exists root) then
    Error (Printf.sprintf "subject locator %S does not exist" root)
  else if not (Sys.is_directory root) then
    Error (Printf.sprintf "subject locator %S is not a directory; scheme %S \
                           snapshots directories" root scheme)
  else
    try
      let* manifest = directory_merkle_manifest root in
      Ok ("sha256:" ^ Sha256.digest_string manifest, manifest)
    with Sys_error msg ->
      Error (Printf.sprintf "scheme %s cannot walk %S: %s" scheme root msg)

(* ─────────────────────────── the typed request ───────────────────────── *)

type subject_entry = {
  subject_name   : string;    (* the CM input this artifact binds *)
  subject_kind   : string;
  subject_scheme : string;
  subject_digest : string;
}

type run_bounds = {
  rq_wall_time_ms : int;
  rq_output_bytes : int;
  rq_evidence_bytes : int;
}

type t = {
  format             : string;
  cm_ir_kind         : string;
  cm_ir_digest       : string;
  subject            : subject_entry list;
  profile            : string;
  capability_ceiling : string list;
  bounds             : run_bounds;
}

let digest_re_ok (s : string) : bool =
  let p = "sha256:" in
  String.length s = String.length p + 64
  && String.sub s 0 (String.length p) = p
  && String.for_all (function '0' .. '9' | 'a' .. 'f' -> true | _ -> false)
       (String.sub s (String.length p) 64)

let required_digest ~(ctx : string) (key : string) (j : J.t) : (string, string) result =
  let* s = required_string ~ctx key j in
  if digest_re_ok s then Ok s
  else Error (Printf.sprintf "%s%s %S is not a \"sha256:<64 lowercase hex>\" digest" ctx key s)

let subject_entry_of_json (name : string) (j : J.t) : (subject_entry, string) result =
  let ctx = Printf.sprintf "subject.%s." name in
  let* () = closed ~ctx ~allowed:[ "kind"; "scheme"; "digest" ] j in
  let* subject_kind = required_string ~ctx "kind" j in
  (* The scheme requirement, enforced here rather than deferred: an entry with
     no scheme cannot be recomputed by a verifier, so it never executes. *)
  let* subject_scheme =
    match field "scheme" j with
    | Some (J.Str s) -> Ok s
    | Some _ -> malformed ctx "scheme" "a string"
    | None ->
      Error (Printf.sprintf
               "%sscheme is missing; every subject entry must name a versioned \
                snapshot/digest scheme so its identity can be recomputed rather \
                than trusted (known: [%s])" ctx
               (String.concat ", "
                  (List.map (fun (s, _) -> Printf.sprintf "%S" s) snapshot_schemes)))
  in
  let* () =
    match List.assoc_opt subject_scheme snapshot_schemes with
    | None ->
      Error (Printf.sprintf
               "%sscheme %S is not recognized; known schemes are [%s]" ctx subject_scheme
               (String.concat ", "
                  (List.map (fun (s, _) -> Printf.sprintf "%S" s) snapshot_schemes)))
    | Some expected_kind when not (String.equal expected_kind subject_kind) ->
      Error (Printf.sprintf "%sscheme %S snapshots kind %S, but this entry declares kind %S"
               ctx subject_scheme expected_kind subject_kind)
    | Some _ -> Ok ()
  in
  let* subject_digest = required_digest ~ctx "digest" j in
  Ok { subject_name = name; subject_kind; subject_scheme; subject_digest }

let bounds_of_json (j : J.t) : (run_bounds, string) result =
  let ctx = "bounds." in
  let* () =
    closed ~ctx ~allowed:[ "wall_time_ms"; "output_bytes"; "evidence_bytes" ] j in
  let* rq_wall_time_ms = required_int ~ctx "wall_time_ms" j in
  let* rq_output_bytes = required_int ~ctx "output_bytes" j in
  let* rq_evidence_bytes = required_int ~ctx "evidence_bytes" j in
  if rq_wall_time_ms <= 0 || rq_output_bytes <= 0 || rq_evidence_bytes <= 0 then
    Error "bounds must be positive"
  else Ok { rq_wall_time_ms; rq_output_bytes; rq_evidence_bytes }

let of_json (j : J.t) : (t, string) result =
  let ctx = "" in
  let* () = closed ~ctx ~allowed:canonical_blocks j in
  let* format = required_string ~ctx "format" j in
  let* () =
    if String.equal format format_pin then Ok ()
    else Error (Printf.sprintf "format %S is not the RunRequest format %S" format format_pin)
  in
  let* cm_ir = required_object ~ctx "cm_ir" j in
  let* () = closed ~ctx:"cm_ir." ~allowed:[ "kind"; "digest" ] cm_ir in
  let* cm_ir_kind = required_string ~ctx:"cm_ir." "kind" cm_ir in
  let* () =
    if String.equal cm_ir_kind "normalized_cm_ir" then Ok ()
    else Error (Printf.sprintf "cm_ir.kind %S is not \"normalized_cm_ir\"" cm_ir_kind)
  in
  let* cm_ir_digest = required_digest ~ctx:"cm_ir." "digest" cm_ir in
  let* subject_j = required_object ~ctx "subject" j in
  let* subject =
    match subject_j with
    | J.Obj kvs ->
      let* () = unique ~what:"subject entry" (List.map fst kvs) in
      all (List.map
             (fun (k, v) ->
                if is_obj v then subject_entry_of_json k v
                else malformed "subject." k "an object")
             kvs)
    | _ -> Error "subject must be an object"
  in
  let* () = if subject = [] then Error "subject binds no artifact" else Ok () in
  let* profile = required_string ~ctx "profile" j in
  let* () =
    if String.equal profile profile_pin then Ok ()
    else
      Error (Printf.sprintf
               "profile %S is not defined; v0 defines exactly one profile (%S) and \
                an unknown profile refuses rather than being ignored" profile profile_pin)
  in
  (* `parameters` is a canonical block AND is runtime-consumed: v0 interprets no
     parameter, so a non-empty map is refused. Silently ignoring it would let a
     methodology believe a knob was honoured. *)
  let* parameters = required_object ~ctx "parameters" j in
  let* () =
    match keys parameters with
    | [] -> Ok ()
    | ks ->
      Error (Printf.sprintf
               "parameters declares [%s]; v0 interprets no run parameter, and an \
                uninterpreted parameter refuses rather than being ignored"
               (String.concat ", " (List.map (Printf.sprintf "%S") ks)))
  in
  let* capability_ceiling = required_string_array ~ctx "capability_ceiling" j in
  let* bounds_j = required_object ~ctx "bounds" j in
  let* bounds = bounds_of_json bounds_j in
  Ok { format; cm_ir_kind; cm_ir_digest; subject; profile; capability_ceiling; bounds }

(* ───────────────────────────── serialization ─────────────────────────── *)

let to_json (r : t) : J.t =
  let s x = J.Str x in
  J.Obj [
    "format", s r.format;
    "cm_ir", J.Obj [ "kind", s r.cm_ir_kind; "digest", s r.cm_ir_digest ];
    "subject", J.Obj
      (List.map
         (fun e ->
            (e.subject_name,
             J.Obj [ "kind", s e.subject_kind;
                     "scheme", s e.subject_scheme;
                     "digest", s e.subject_digest ]))
         r.subject);
    "profile", s r.profile;
    "parameters", J.Obj [];
    "capability_ceiling", J.Arr (List.map s r.capability_ceiling);
    "bounds", J.Obj [
      "wall_time_ms", J.Int r.bounds.rq_wall_time_ms;
      "output_bytes", J.Int r.bounds.rq_output_bytes;
      "evidence_bytes", J.Int r.bounds.rq_evidence_bytes;
    ];
  ]

(* The canonical digest of the request artifact. Digesting the CANONICAL
   serialization (lexicographic keys, two-space indent, LF, trailing newline)
   rather than the bytes on disk is what makes the same request written by two
   different tools digest identically — "repeating the same request may create a
   new execution id, but must not change the canonical request digest". *)
let digest (r : t) : string = "sha256:" ^ J.digest (to_json r)

(* ──────────────────────── synthesis and verification ─────────────────── *)

(* SYNTHESIZE a request from an IR and host locators. This is what
   `run --ir … --target …` does: the request is ALWAYS an artifact, and the CLI
   simply builds it when the operator did not hand one over. Subject digests are
   computed from the located bytes with the declared scheme, so a synthesized
   request is exactly as recomputable as an authored one. *)
let synthesize (ir : Ir.t) ~(ir_digest : string) ~(locators : (string * string) list)
  : (t * (string * string) list, string) result =
  let* entries =
    all (List.map
           (fun (i : Ir.cm_input) ->
              match List.assoc_opt i.Ir.input_name locators with
              | None ->
                Error (Printf.sprintf
                         "CM input %S is declared but no locator was bound for it \
                          (use --bind %s=<path>)" i.Ir.input_name i.Ir.input_name)
              | Some root ->
                let* (d, manifest) = snapshot ~scheme:directory_merkle ~root in
                Ok ({ subject_name = i.Ir.input_name;
                      subject_kind = "directory_snapshot";
                      subject_scheme = directory_merkle;
                      subject_digest = d },
                    manifest))
           ir.Ir.inputs)
  in
  let p = ir.Ir.permissions in
  let request = {
    format = format_pin;
    cm_ir_kind = "normalized_cm_ir";
    cm_ir_digest = ir_digest;
    subject = List.map fst entries;
    profile = profile_pin;
    (* A synthesized ceiling is exactly the CM's own declared envelope — never
       wider. The linker still proves each step is inside it, so synthesis
       cannot be a way to grant a step authority the methodology did not ask
       for. *)
    capability_ceiling = p.Ir.permitted_capabilities;
    bounds = { rq_wall_time_ms = p.Ir.permitted_bounds.Ir.wall_time_ms;
               rq_output_bytes = p.Ir.permitted_bounds.Ir.output_bytes;
               rq_evidence_bytes = p.Ir.permitted_bounds.Ir.output_bytes * 16 };
  } in
  Ok (request, List.map (fun (e, m) -> (e.subject_name, m)) entries)

(* VERIFY an authored request against the artifacts it claims to bind: the IR
   digest must match the IR actually loaded, and each subject digest must match
   what the declared scheme computes over the host locator. This is the check
   that makes `--request` mean something — without it the digests would be
   decoration. *)
let verify (r : t) ~(ir_digest : string) ~(locators : (string * string) list)
  : ((string * string) list, string) result =
  let* () =
    if String.equal r.cm_ir_digest ir_digest then Ok ()
    else
      Error (Printf.sprintf
               "run request binds cm_ir digest %s, but the loaded IR canonicalizes \
                to %s" r.cm_ir_digest ir_digest)
  in
  all (List.map
         (fun e ->
            match List.assoc_opt e.subject_name locators with
            | None ->
              Error (Printf.sprintf
                       "run request binds subject %S but no locator was supplied \
                        for it (use --bind %s=<path>)" e.subject_name e.subject_name)
            | Some root ->
              let* (d, manifest) = snapshot ~scheme:e.subject_scheme ~root in
              if String.equal d e.subject_digest then Ok (e.subject_name, manifest)
              else
                Error (Printf.sprintf
                         "subject %S binds digest %s under scheme %S, but the bytes \
                          at %S digest to %s" e.subject_name e.subject_digest
                         e.subject_scheme root d))
         r.subject)
