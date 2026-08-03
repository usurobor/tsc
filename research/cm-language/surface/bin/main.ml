(* cmc — the CM surface compiler CLI.
 *
 *   cmc <file.cm>            compile to the normalized JSON IR (default).
 *   cmc --source <file.cm>   compile to the FULL authored #CMSource JSON
 *                            (content-addressed digests + per-step contracts).
 *
 * Both projections come from the one .cm source. Exit codes: 0 on success;
 * 2 on a compile error (diagnostic on stderr); 1 on usage error. *)

let run mode path =
  try print_string (Cm_surface.compile_file ~mode path)
  with
  | Cm_surface.Compile_error msg -> Printf.eprintf "cmc: %s\n" msg; exit 2
  | Sys_error msg -> Printf.eprintf "cmc: %s\n" msg; exit 2

let () =
  match Sys.argv with
  | [| _; path |] -> run Cm_surface.Ir path
  | [| _; "--source"; path |] | [| _; "-e"; path |] -> run Cm_surface.Source path
  | _ ->
      prerr_endline "usage: cmc [--source] <file.cm>";
      exit 1
