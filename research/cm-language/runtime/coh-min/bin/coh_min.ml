(* coh-min CLI — the minimal standalone CM runner.

     coh_min run       --ir <ir.json> (--target <dir> | --bind <name>=<dir>)…
                       [--request <run-request.json>]
                       [--out <receipt.json>] [--plan-out <p>] [--request-out <q>]
     coh_min check     --kind <cm-ir|run-request|sandbox-plan|receipt> --file <f>
     coh_min negatives --kind <family> --from <artifact.json> --out-dir <dir>

   `run` loads and validates the NormalizedCMIR, binds or synthesizes the
   RunRequest, links the SandboxExecutionPlan, executes the checker DAG against
   the located subject, evaluates the CM's own rule table, and emits one
   MeasurementReceipt (canonical JSON) on stdout.

   `check` is STRUCTURAL ADMISSION for any of the four artifact families — are
   the canonical blocks present, well-typed and internally coherent? It is NOT
   `verify`: it does not check digests against the artifacts they bind, replay
   the result rule, or apply obligation rules. A standalone verifier is the next
   cell, and calling this one `check` rather than `verify` is deliberate.

   `negatives` writes one missing-block variant per canonical top-level block of
   the given artifact, each derived from that artifact by deleting exactly one
   field. It is the generator behind the gate-9 sweep: a negative fixture that is
   DERIVED from the shipped positive cannot drift away from it.

   Exit codes:
     0  the operation succeeded
     1  it failed closed — for `run`, NO receipt bytes are written anywhere
     2  a usage error (argv only; no input artifact can reach this code) *)

module J = Coh_min.Json
module R = Coh_min.Runner

(* ux-cli: colour encodes semantics (red = error), a symbol always accompanies
   it (never colour-only), and NO_COLOR disables the escape codes. Terminal
   detection would need Unix.isatty, which the stdlib-only contract forbids, so
   NO_COLOR is the documented escape hatch. *)
let red s =
  if Sys.getenv_opt "NO_COLOR" <> None then s else "\027[31m" ^ s ^ "\027[0m"

let usage =
  "usage:\n\
  \  coh_min run       --ir <ir.json> (--target <dir> | --bind <name>=<dir>)…\n\
  \                    [--request <run-request.json>]\n\
  \                    [--out <receipt.json>] [--plan-out <p>] [--request-out <q>]\n\
  \  coh_min check     --kind <cm-ir|run-request|sandbox-plan|receipt> --file <f>\n\
  \  coh_min negatives --kind <family> --from <artifact.json> --out-dir <dir>"

let die_usage msg = prerr_endline (usage ^ "\n" ^ msg); exit 2

let die_closed msg =
  prerr_endline (red (Printf.sprintf "\xe2\x9c\x97 coh_min: %s" msg));
  exit 1

let write_file path contents =
  let oc = open_out_bin path in
  Fun.protect ~finally:(fun () -> close_out oc) (fun () -> output_string oc contents)

let read_document path =
  match R.read_document path with Ok j -> j | Error msg -> die_closed msg

(* ───────────────────────────── flag parsing ─────────────────────────── *)

(* One generic pass over argv: repeated flags accumulate, unknown flags are a
   usage error, and a flag missing its value is a usage error. Each subcommand
   then reads what it needs from the same association list, so no two commands
   can disagree about how `--ir` is spelled. *)
let parse_flags (argv : string array) : ((string * string) list, string) result =
  let rec loop i acc =
    if i >= Array.length argv then Ok (List.rev acc)
    else
      let flag = argv.(i) in
      if String.length flag < 2 || String.sub flag 0 2 <> "--" then
        Error (Printf.sprintf "unexpected argument %S" flag)
      else if i + 1 >= Array.length argv then
        Error (Printf.sprintf "%s needs a value" flag)
      else loop (i + 2) ((flag, argv.(i + 1)) :: acc)
  in
  loop 2 []

let one ~(flag : string) (flags : (string * string) list) : (string, string) result =
  match List.filter (fun (f, _) -> f = flag) flags with
  | [ (_, v) ] -> Ok v
  | [] -> Error (flag ^ " is required")
  | _ -> Error (flag ^ " was given more than once")

let optional ~(flag : string) (flags : (string * string) list) : string option =
  match List.filter (fun (f, _) -> f = flag) flags with
  | (_, v) :: _ -> Some v
  | [] -> None

let known ~(allowed : string list) (flags : (string * string) list) : (unit, string) result =
  match List.filter (fun (f, _) -> not (List.mem f allowed)) flags with
  | [] -> Ok ()
  | (f, _) :: _ ->
    Error (Printf.sprintf "unknown argument %s (this command takes %s)" f
             (String.concat " " allowed))

(* ─────────────────────────────── run ─────────────────────────────────── *)

(* Bind CM inputs to host locators. `--bind name=path` is the general form;
   `--target path` is sugar for the SOLE declared input and is a usage error for
   a CM that declares more than one — guessing which input the operator meant
   would be exactly the kind of implicit binding this runtime refuses. *)
let locators_of (ir : Coh_min.Ir.t) (flags : (string * string) list)
  : ((string * string) list, string) result =
  let binds =
    List.filter_map
      (fun (f, v) ->
         if f <> "--bind" then None
         else
           match String.index_opt v '=' with
           | None -> Some (Error (Printf.sprintf "--bind %S must be <name>=<path>" v))
           | Some i ->
             Some (Ok (String.sub v 0 i, String.sub v (i + 1) (String.length v - i - 1))))
      flags
  in
  match Coh_min.Jread.all binds with
  | Error e -> Error e
  | Ok binds ->
    (match optional ~flag:"--target" flags with
     | None ->
       if binds = [] then Error "one of --target <dir> or --bind <name>=<dir> is required"
       else Ok binds
     | Some target ->
       (match ir.Coh_min.Ir.inputs with
        | [ i ] -> Ok ((i.Coh_min.Ir.input_name, target) :: binds)
        | inputs ->
          Error (Printf.sprintf
                   "--target binds the sole CM input, but this CM declares %d \
                    ([%s]); use --bind <name>=<dir> for each"
                   (List.length inputs)
                   (String.concat ", "
                      (List.map (fun i -> Printf.sprintf "%S" i.Coh_min.Ir.input_name) inputs)))))

let run_command (argv : string array) : unit =
  match parse_flags argv with
  | Error e -> die_usage e
  | Ok flags ->
    (match known flags
             ~allowed:[ "--ir"; "--target"; "--bind"; "--request"; "--out";
                        "--plan-out"; "--request-out" ] with
    | Error e -> die_usage e
    | Ok () ->
      let ir_path = match one ~flag:"--ir" flags with Ok v -> v | Error e -> die_usage e in
      (* The IR is loaded once, here, so `--target` can be resolved against the
         inputs the METHODOLOGY declares rather than against an assumption. *)
      let (ir, _) = match R.load_ir ir_path with Ok x -> x | Error e -> die_closed e in
      let locators =
        match locators_of ir flags with Ok l -> l | Error e -> die_usage e in
      let spec = { R.ir_path; request_path = optional ~flag:"--request" flags; locators } in
      (match R.run spec with
       | Error msg -> die_closed msg
       | Ok out ->
         let doc = J.document out.R.receipt in
         print_string doc;
         let write flag j =
           match optional ~flag flags with
           | None -> ()
           | Some path ->
             write_file path (J.document j);
             Printf.eprintf "%s written to %s\n" flag path
         in
         (match optional ~flag:"--out" flags with
          | Some path -> write_file path doc; Printf.eprintf "receipt written to %s\n" path
          | None -> ());
         write "--plan-out" out.R.plan_json;
         write "--request-out" out.R.request_json;
         Printf.eprintf "coh_min: %s\n" out.R.summary;
         exit 0))

(* ────────────────────────────── check ───────────────────────────────── *)

let kind_of flags =
  match one ~flag:"--kind" flags with
  | Error e -> die_usage e
  | Ok k -> (match R.family_of_string k with Ok f -> f | Error e -> die_usage e)

let check_command (argv : string array) : unit =
  match parse_flags argv with
  | Error e -> die_usage e
  | Ok flags ->
    (match known flags ~allowed:[ "--kind"; "--file" ] with
     | Error e -> die_usage e
     | Ok () ->
       let family = kind_of flags in
       let file = match one ~flag:"--file" flags with Ok v -> v | Error e -> die_usage e in
       let document = read_document file in
       (match R.admit family document with
        | Error msg -> die_closed (Printf.sprintf "%s: %s" file msg)
        | Ok () ->
          Printf.printf "admitted: %s\n" file;
          exit 0))

(* ──────────────────────────── negatives ─────────────────────────────── *)

let negatives_command (argv : string array) : unit =
  match parse_flags argv with
  | Error e -> die_usage e
  | Ok flags ->
    (match known flags ~allowed:[ "--kind"; "--from"; "--out-dir" ] with
     | Error e -> die_usage e
     | Ok () ->
       let family = kind_of flags in
       let from = match one ~flag:"--from" flags with Ok v -> v | Error e -> die_usage e in
       let out_dir =
         match one ~flag:"--out-dir" flags with Ok v -> v | Error e -> die_usage e in
       let document = read_document from in
       (* The source artifact must itself be ADMISSIBLE. Generating negatives
          from a document that was already invalid would make every case pass
          for the wrong reason — the sweep would prove nothing. *)
       (match R.admit family document with
        | Error msg ->
          die_closed
            (Printf.sprintf
               "%s is not an admissible artifact, so negatives derived from it \
                would prove nothing: %s" from msg)
        | Ok () ->
          if not (Sys.file_exists out_dir) then Sys.mkdir out_dir 0o755;
          let variants = R.missing_block_variants family document in
          List.iter
            (fun (block, j) ->
               let path = Filename.concat out_dir (Printf.sprintf "no-%s.json" block) in
               write_file path (J.document j);
               print_endline path)
            variants;
          Printf.eprintf "coh_min: wrote %d missing-block variant(s) of %s to %s\n"
            (List.length variants) from out_dir;
          exit 0))

let () =
  let argv = Sys.argv in
  if Array.length argv < 2 then die_usage "a command is required"
  else match argv.(1) with
    | "run" -> run_command argv
    | "check" -> check_command argv
    | "negatives" -> negatives_command argv
    | other -> die_usage (Printf.sprintf "unknown command %S" other)
