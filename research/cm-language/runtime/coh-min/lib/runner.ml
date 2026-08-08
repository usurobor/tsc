(* coh-min runtime: the minimal, domain-neutral CM runner (M2), running the
   first ordinary CM end to end (M3).

   The path, harvested and generalized from the Ascent-0 runtime:

     load NormalizedCMIR (procedure.steps)
       -> LINK a SandboxExecutionPlan (each step's provider binding + capability)
       -> EXECUTE the finite DAG: a step runs only when its typed input surfaces
          are all present; an unrun step is a principled skip, never a crash
       -> INVOKE the real provider backend (here: `file.exists` stats the disk)
       -> EVALUATE a small result rule over the produced evidence
       -> EMIT one MeasurementReceipt (canonical JSON, content-addressed plan).

   Unlike Ascent-0 this has NO oracle, NO sealed reveal, NO Mealy enumeration:
   it is the ordinary-CM side of the two-sided kernel. The receipt is
   runtime-DERIVED (the provider reports an observation; the runner computes the
   result), and it CHANGES with the subject: run against a directory that has a
   README and the result is README_PRESENT; run against one that does not and it
   is README_ABSENT. Static IR validation does not produce this; execution does.

   Honest scope: the IR is hand-authored (not yet cmc-emitted), exactly as the
   Ascent-0 IR is; and `file.exists` is the only wired provider. This is the M2
   tracer for the portable runtime, not the production `coh cm` path. *)

module J = Json

(* ─────────────────────────── run request ─────────────────────────────── *)

type run_request = {
  ir_path     : string;
  target_root : string;   (* the repository/subject directory under assessment *)
}

(* ───────────────────────── the execution plan ────────────────────────── *)

type plan_step = {
  order          : int;
  step_id        : string;
  provider_class : string;
  provider_kind  : string;
  kind           : string;
  reads          : string list;
  produces       : string;
  config         : J.t;
  search_strength: string;
  may_access     : string list;
}

type plan = {
  cm_id         : string;
  cm_version    : string;
  source_digest : string;
  steps         : plan_step list;
}

(* LINK: normalize the IR steps into a SandboxExecutionPlan. Each step is bound
   with the capabilities it declared (may_access); no host control plane is
   contacted — this is the standalone boundary. *)
let link (ir : J.t) : plan =
  let proc = J.member "procedure" ir in
  let steps_json = J.to_list (J.member "steps" proc) in
  let steps =
    List.mapi
      (fun order sj ->
         let may_access =
           match J.member_opt "may_access" sj with
           | Some a -> List.map J.to_string (J.to_list a)
           | None -> []
         in
         let config =
           match J.member_opt "config" sj with Some c -> c | None -> J.Obj []
         in
         { order;
           step_id = J.to_string (J.member "id" sj);
           provider_class = J.to_string (J.member "provider_class" sj);
           provider_kind = J.to_string (J.member "provider_kind" sj);
           kind = J.to_string (J.member "kind" sj);
           reads = List.map J.to_string (J.to_list (J.member "reads" sj));
           produces = J.to_string (J.member "produces" sj);
           config;
           search_strength =
             (match J.member_opt "search_strength" sj with
              | Some (J.Str s) -> s | _ -> "exact");
           may_access })
      steps_json
  in
  { cm_id = J.to_string (J.member "cm_id" ir);
    cm_version = J.to_string (J.member "cm_version" ir);
    source_digest = J.to_string (J.member "source_digest" ir);
    steps }

(* ───────────────────────────── execution ─────────────────────────────── *)

type evidence = {
  ev_step_id : string;
  ev_json    : J.t;   (* the observation the provider actually captured *)
}

type state = {
  rr : run_request;
  mutable present   : string list;               (* surfaces available *)
  mutable exec_order: (int * string) list;
  mutable skipped   : (string * string list) list;  (* step_id, missing surfaces *)
  mutable evidence  : evidence list;
  mutable findings  : (string * bool) list;      (* produced surface -> boolean value *)
}

let fresh_state rr = {
  rr; present = []; exec_order = []; skipped = []; evidence = []; findings = [];
}

(* ─────────────────────────────── backends ────────────────────────────── *)
(* A backend returns the surfaces it ACTUALLY produced. `file.exists` is a real
   mechanical provider: it stats the subject directory and reports what it saw. *)

let backend (st : state) (ps : plan_step) : string list =
  match ps.provider_class with
  | "file.exists" ->
    let rel =
      match J.member_opt "relative_path" ps.config with
      | Some (J.Str s) -> s
      | _ -> failwith "file.exists: config.relative_path (string) is required" in
    (* path confinement (portable fail-closed invariant): the relative path must
       not escape the declared subject root. *)
    if String.length rel = 0 || rel.[0] = '/' || rel = ".."
       || (String.length rel >= 3 && String.sub rel 0 3 = "../")
       || (let rec has_dotdot i =
             i + 2 < String.length rel
             && ((rel.[i] = '/' && rel.[i+1] = '.' && rel.[i+2] = '.')
                 || has_dotdot (i + 1))
           in has_dotdot 0)
    then failwith (Printf.sprintf
                     "file.exists: relative_path %S escapes the subject root (denied)" rel);
    let full = Filename.concat st.rr.target_root rel in
    let exists = Sys.file_exists full in
    let size = if exists && not (Sys.is_directory full) then
        (let ic = open_in_bin full in
         let n = in_channel_length ic in close_in ic; n)
      else -1 in
    st.evidence <- {
      ev_step_id = ps.step_id;
      ev_json = J.Obj [
          "provider_class", J.Str "file.exists";
          "relative_path", J.Str rel;
          "checked_path", J.Str full;
          "exists", J.Bool exists;
          "is_directory", J.Bool (exists && Sys.is_directory full);
          "size_bytes", J.Int size;
        ];
    } :: st.evidence;
    st.findings <- (ps.produces, exists) :: st.findings;
    [ ps.produces ]
  | other ->
    failwith (Printf.sprintf
                "unknown provider_class %S (coh-min wires only file.exists so far)" other)

(* EXECUTE the DAG by input readiness. Base surfaces are seeded from the IR's
   input_contract required_artifacts (the subject the RunRequest supplies). *)
let execute (st : state) (ir : J.t) (pl : plan) : unit =
  let required =
    match J.member_opt "input_contract" ir with
    | Some ic ->
      (match J.member_opt "required_artifacts" ic with
       | Some (J.Arr l) ->
         List.filter_map
           (fun a -> match J.member_opt "role" a with Some (J.Str s) -> Some s | _ -> None)
           l
       | _ -> [])
    | None -> []
  in
  st.present <- required;
  let remaining = ref pl.steps in
  let ran = ref true in
  while !remaining <> [] && !ran do
    ran := false;
    (match List.find_opt
             (fun s -> List.for_all (fun r -> List.mem r st.present) s.reads)
             !remaining with
     | None -> ()  (* stuck: unrun steps become principled skips *)
     | Some s ->
       let produced = backend st s in
       st.exec_order <- (List.length st.exec_order, s.step_id) :: st.exec_order;
       st.present <- st.present @ produced;
       remaining := List.filter (fun x -> x.step_id <> s.step_id) !remaining;
       ran := true)
  done;
  st.skipped <-
    List.map
      (fun s -> (s.step_id, List.filter (fun r -> not (List.mem r st.present)) s.reads))
      !remaining

(* ───────────────────────── evaluate the result rule ──────────────────── *)

type verdict = { result_class : string; complete : bool }

let evaluate (st : state) (pl : plan) : verdict =
  (* Complete iff every declared step ran (no principled skip stalled the DAG). *)
  let complete = st.skipped = [] && List.length st.exec_order = List.length pl.steps in
  if not complete then { result_class = "INCOMPLETE"; complete }
  else
    match List.assoc_opt "readme_presence" st.findings with
    | Some true  -> { result_class = "README_PRESENT"; complete }
    | Some false -> { result_class = "README_ABSENT"; complete }
    | None -> { result_class = "INCOMPLETE"; complete = false }

(* ─────────────────────────────── emit ────────────────────────────────── *)

let s x = J.Str x
let i x = J.Int x
let b x = J.Bool x
let arr x = J.Arr x
let obj x = J.Obj x

let plan_json (pl : plan) : J.t =
  obj [
    "cm_id", s pl.cm_id;
    "cm_version", s pl.cm_version;
    "source_digest", s pl.source_digest;
    "steps", arr (List.map (fun st ->
        obj [
          "order", i st.order;
          "step_id", s st.step_id;
          "provider_class", s st.provider_class;
          "provider_kind", s st.provider_kind;
          "kind", s st.kind;
          "reads", arr (List.map s st.reads);
          "produces", s st.produces;
          "may_access", arr (List.map s st.may_access);
          "search_strength", s st.search_strength;
        ]) pl.steps);
  ]

let emit (st : state) (pl : plan) (v : verdict) : J.t =
  let plan_j = plan_json pl in
  obj [
    "format", s "tsc-measurement-receipt/0.1";
    "cm_id", s pl.cm_id;
    "cm_version", s pl.cm_version;
    "source_digest", s pl.source_digest;
    "run_request", obj [
      "target_root", s st.rr.target_root;
      "ir_path", s st.rr.ir_path;
    ];
    "plan_digest", s ("sha256:" ^ J.digest plan_j);
    "sandbox_execution_plan", plan_j;
    "execution_trace", arr (List.map (fun (order, sid) ->
        obj [ "order", i order; "step_id", s sid ]) (List.rev st.exec_order));
    "skipped_steps", arr (List.map (fun (sid, missing) ->
        obj [ "step_id", s sid; "missing_surfaces", arr (List.map s missing) ]) st.skipped);
    "evidence", arr (List.map (fun e ->
        obj [ "step_id", s e.ev_step_id; "observation", e.ev_json ])
        (List.rev st.evidence));
    "result", obj [
      "result_class", s v.result_class;
      "computed", b true;
      "complete", b v.complete;
      "rule", s "every declared step ran (else INCOMPLETE); then readme_presence \
                 true -> README_PRESENT, false -> README_ABSENT";
      "derived_from", arr (List.map s [ "execution_trace"; "evidence.readme_exists" ]);
    ];
  ]

(* ─────────────────────────────── driver ──────────────────────────────── *)

let run (rr : run_request) : J.t =
  Sha256.self_test ();
  let ir = J.parse_file rr.ir_path in
  let pl = link ir in
  let st = fresh_state rr in
  execute st ir pl;
  let v = evaluate st pl in
  emit st pl v
