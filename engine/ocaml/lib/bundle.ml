(** Bundle: build a target bundle from resolved file paths.

    Pure module — receives file contents as (path, content) pairs.
    Caller is responsible for reading files and expanding globs. *)

open Types

(** Compute SHA-256 hex digest of a string.
    Uses Digest module (MD5 in stdlib) as placeholder.
    Production should use a SHA-256 library. *)
let hash_content content =
  Digest.string content |> Digest.to_hex

(** Build a bundle_file from a path and its content. *)
let make_bundle_file ~target_kind ~path ~content =
  {
    file_path = path;
    file_content = content;
    file_hash = hash_content content;
    file_size = String.length content;
    file_target_kind = target_kind;
  }

(** Build a target bundle from a list of (path, content) pairs.
    Files are ordered by path for determinism. *)
let build_bundle ~target_name ~target_kind ~files =
  let sorted_files =
    List.sort (fun (a, _) (b, _) -> String.compare a b) files
  in
  let bundle_files =
    List.map (fun (path, content) ->
      make_bundle_file ~target_kind ~path ~content
    ) sorted_files
  in
  {
    bundle_target_name = target_name;
    bundle_target_kind = target_kind;
    bundle_files;
  }
