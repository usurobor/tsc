(* provider.ml — the coh-min provider layer.

   One provider is wired: `file.exists`. It is a REAL mechanical provider — it
   stats the subject directory and reports what it actually saw, so the emitted
   receipt CHANGES with the subject (present vs absent README). Static IR
   validation cannot produce that; only running the provider against the disk
   can.

   PURITY BOUNDARY (ocaml skill §2.2 / write-functional §1):
     - [confine] is a pure, total function over strings. It performs no I/O, so
       its whole behaviour — including its negative space (the paths it DENIES)
       — is trivially testable without a filesystem.
     - [file_exists] is the thin effectful shell that stats the confined path.

   Both report expected failure through [result] (ocaml skill §2.3), never
   through exceptions: a denied path is a first-class, fail-closed outcome, not
   a crash. *)

(* What `file.exists` observed on disk. This is the provider's own shape; the
   provider owns its serialization ([observation_to_json]) so the runner never
   reaches into the provider's internals. *)
type observation = {
  provider_class : string;
  relative_path  : string;
  checked_path   : string;
  exists         : bool;
  is_directory   : bool;
  size_bytes     : int;   (* regular-file length, or -1 when absent / a directory *)
}

(* PATH CONFINEMENT (pure; the portable fail-closed invariant, AC6).

   A relative path is ADMITTED iff it is non-empty, not absolute, and contains
   no parent-directory (`..`) segment. Such a path cannot lexically escape
   [root], so joining it to [root] stays within the subject. Anything else is
   DENIED: the provider refuses to read rather than resolving a path that could
   climb out of the subject root. Lexical (component-wise) confinement is used
   deliberately — the stdlib carries no `realpath`, and the contract forbids
   Unix — so admission never depends on I/O. *)
let confine ~(root : string) ~(rel : string) : (string, string) result =
  if String.length rel = 0 then
    Error "relative_path is empty"
  else if not (Filename.is_relative rel) then
    Error (Printf.sprintf
             "relative_path %S is absolute; it must stay within the subject root" rel)
  else if List.mem Filename.parent_dir_name (String.split_on_char '/' rel) then
    Error (Printf.sprintf
             "relative_path %S contains a %S segment and could escape the subject root"
             rel Filename.parent_dir_name)
  else
    Ok (Filename.concat root rel)

(* Effectful shell: the length of a regular file, with the channel always
   closed (write-functional §4.3). *)
let regular_file_size (path : string) : int =
  let ic = open_in_bin path in
  Fun.protect ~finally:(fun () -> close_in_noerr ic)
    (fun () -> in_channel_length ic)

(* Invoke the real provider: confine, then stat. Returns the observation it
   captured, or a denial reason (fail-closed). *)
let file_exists ~(root : string) ~(rel : string) : (observation, string) result =
  match confine ~root ~rel with
  | Error _ as denied -> denied
  | Ok checked_path ->
    let exists = Sys.file_exists checked_path in
    let is_directory = exists && Sys.is_directory checked_path in
    let size_bytes =
      if exists && not is_directory then regular_file_size checked_path else -1 in
    Ok { provider_class = "file.exists";
         relative_path = rel;
         checked_path;
         exists;
         is_directory;
         size_bytes }

let observation_to_json (o : observation) : Json.t =
  Json.Obj [
    "provider_class", Json.Str o.provider_class;
    "relative_path", Json.Str o.relative_path;
    "checked_path", Json.Str o.checked_path;
    "exists", Json.Bool o.exists;
    "is_directory", Json.Bool o.is_directory;
    "size_bytes", Json.Int o.size_bytes;
  ]
