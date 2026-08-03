(* cmc — the CM surface compiler CLI.
 *
 *   cmc <file.cm>     compile a .cm source to normalized JSON IR on stdout.
 *
 * Exit codes: 0 on success; 2 on a compile error (with a diagnostic on stderr);
 * 1 on usage error. *)

let () =
  match Sys.argv with
  | [| _; path |] -> (
      try print_string (Cm_surface.compile_file path)
      with
      | Cm_surface.Compile_error msg ->
          Printf.eprintf "cmc: %s\n" msg;
          exit 2
      | Sys_error msg ->
          Printf.eprintf "cmc: %s\n" msg;
          exit 2)
  | _ ->
      prerr_endline "usage: cmc <file.cm>";
      exit 1
