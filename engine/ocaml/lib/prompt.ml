(** Prompt construction: target bundle + self-measure instruction → prompt.

    Pure module — no I/O. Receives instruction text and bundle as values. *)

open Types

let target_kind_to_string = function
  | Theory -> "spec"
  | Implementation -> "engine"
  | Aggregate -> "repo"

(** Render the file bundle section of the prompt. *)
let render_bundle_section bundle =
  let file_sections =
    List.map (fun f ->
      Printf.sprintf "--- FILE: %s (hash: %s, size: %d bytes) ---\n%s\n--- END FILE ---"
        f.file_path f.file_hash f.file_size f.file_content
    ) bundle.bundle_files
  in
  String.concat "\n\n" file_sections

(** Render target metadata. *)
let render_target_metadata bundle =
  Printf.sprintf "Target: %s\nKind: %s\nFile count: %d"
    bundle.bundle_target_name
    (target_kind_to_string bundle.bundle_target_kind)
    (List.length bundle.bundle_files)

(** Build the complete prompt from instruction + bundle.
    The instruction is the content of runtime/SELF-MEASURE.md. *)
let build_prompt ~instruction ~bundle =
  let metadata = render_target_metadata bundle in
  let files = render_bundle_section bundle in
  Printf.sprintf
    "%s\n\n---\n\n## Target Metadata\n\n%s\n\n## File Bundle\n\n%s"
    instruction metadata files

(** Build the system message (instruction only, no bundle). *)
let build_system_message ~instruction =
  instruction

(** Build the user message (metadata + bundle). *)
let build_user_message ~bundle =
  let metadata = render_target_metadata bundle in
  let files = render_bundle_section bundle in
  Printf.sprintf "## Target Metadata\n\n%s\n\n## File Bundle\n\n%s"
    metadata files
