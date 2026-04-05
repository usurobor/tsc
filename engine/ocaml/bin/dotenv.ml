(** Dotenv: load key=value pairs from a file into the process environment.

    Real environment variables always take precedence over file values.
    Warns if the file has permissions more open than 0600.

    Lives in bin/ (impure — reads files, sets env, checks permissions). *)

(** Parse a single line into (key, value) option.
    Skips blank lines, comments (#), and malformed lines.
    Strips optional quotes around values. *)
let parse_line line =
  let line = String.trim line in
  if String.length line = 0 || line.[0] = '#' then None
  else
    match String.index_opt line '=' with
    | None -> None
    | Some i ->
      let key = String.trim (String.sub line 0 i) in
      let raw_value = String.trim (String.sub line (i + 1) (String.length line - i - 1)) in
      (* Strip matching quotes *)
      let value =
        let len = String.length raw_value in
        if len >= 2
           && ((raw_value.[0] = '"' && raw_value.[len - 1] = '"')
               || (raw_value.[0] = '\'' && raw_value.[len - 1] = '\''))
        then String.sub raw_value 1 (len - 2)
        else raw_value
      in
      if String.length key > 0 then Some (key, value) else None

(** Check file permissions. Warn if not 0600. *)
let check_permissions path =
  try
    let stat = Unix.stat path in
    let perm = stat.Unix.st_perm land 0o777 in
    if perm <> 0o600 then
      Printf.eprintf "Warning: %s has permissions %03o, recommend 0600\n%!" path perm
  with Unix.Unix_error _ -> ()

(** Load a dotenv file. Sets env vars only when not already set.
    Returns the number of variables loaded. *)
let load path =
  if not (Sys.file_exists path) then 0
  else begin
    check_permissions path;
    let ic = open_in path in
    let count = ref 0 in
    Fun.protect ~finally:(fun () -> close_in ic) (fun () ->
      try while true do
        let line = input_line ic in
        match parse_line line with
        | None -> ()
        | Some (key, value) ->
          (* Real env wins — only set if not already present *)
          match Sys.getenv_opt key with
          | Some _ -> ()
          | None ->
            Unix.putenv key value;
            incr count
      done with End_of_file -> ()
    );
    !count
  end
