(* runner.ml — the pipeline, and the only place the stages are wired together.

       load + validate the NormalizedCMIR        [Ir]
    -> bind or synthesize the RunRequest          [Request]
    -> link a SandboxExecutionPlan                [Linker]
    -> execute the checker DAG                    [Exec]
    -> evaluate the CM-owned rule table           [Rule]
    -> discharge warrant obligations              [Rule]
    -> emit one MeasurementReceipt                [Receipt]

   Read that list again and note what is NOT in it: no classification step, no
   methodology-identity lookup, no per-methodology branch. In #127 this file
   carried a `classify` function that compared the plan's CM identity against
   one hard-coded string and returned a result class for it. That function is
   DELETED. What replaced it is [Rule.derive] applied to a table that came out
   of the IR, and the difference is the whole cycle: a second methodology now
   runs by adding a JSON document, and a third would too.

   The claim is checkable, not rhetorical: `make genericity` discovers every
   shipped CM's identity from its IR and fails if any of them appears anywhere
   under `lib/` or `bin/` — which is why no comment in this tree quotes one.

   §THE FAIL-CLOSED CHANNEL. Every expected fault — a malformed IR, an
   unresolved port, a config the capability rejects, a subject whose digest does
   not match the request, an escaping path, an undischarged obligation, a
   receipt whose own bindings do not check out — is an [Error] carrying one
   sentence. The CLI maps that channel to exit 1 with NO receipt bytes. The only
   exceptions caught are the vendored parser's, which cannot be softened in
   place because `json.ml` is byte-identical to ascent-0's. *)

module J = Json

let ( let* ) = Result.bind

(* ─────────────────────────────── the request ─────────────────────────── *)

type spec = {
  ir_path      : string;
  request_path : string option;          (* an authored RunRequest, if any *)
  locators     : (string * string) list; (* CM input name -> host path *)
}

type outputs = {
  receipt      : J.t;
  plan_json    : J.t;
  request_json : J.t;
  summary      : string;
}

(* ────────────────────────── artifact families ────────────────────────── *)

(* The four canonical artifact families, so `check` and the gate-9 negative
   generator treat them uniformly instead of hard-coding one. Adding a family
   means adding a row here and nothing else. *)
type family = Cm_ir | Run_request | Sandbox_plan | Measurement_receipt

let families =
  [ "cm-ir", Cm_ir;
    "run-request", Run_request;
    "sandbox-plan", Sandbox_plan;
    "receipt", Measurement_receipt ]

let family_names = List.map fst families

let family_of_string (s : string) : (family, string) result =
  match List.assoc_opt s families with
  | Some f -> Ok f
  | None ->
    Error (Printf.sprintf "unknown artifact family %S; known families are [%s]"
             s (String.concat ", " (List.map (Printf.sprintf "%S") family_names)))

let canonical_blocks_of : family -> string list = function
  | Cm_ir -> Ir.canonical_blocks
  | Run_request -> Request.canonical_blocks
  | Sandbox_plan -> Plan.canonical_blocks
  | Measurement_receipt -> Receipt.canonical_blocks

(* STRUCTURAL ADMISSION — not verification. This answers "are the canonical
   blocks present and well-typed, and is the document internally coherent?" It
   does NOT check digests against the artifacts they bind, replay the result
   rule, or apply obligation rules; that is `verify`, and it is the next cell.
   Keeping the two apart is what stops a structural pass being reported as a
   verified receipt. *)
let admit (f : family) (j : J.t) : (unit, string) result =
  match f with
  | Cm_ir -> Ir.of_json j |> Result.map (fun _ -> ())
  | Run_request -> Request.of_json j |> Result.map (fun _ -> ())
  | Sandbox_plan -> Plan.of_json j |> Result.map (fun _ -> ())
  | Measurement_receipt -> Receipt.of_json j |> Result.map (fun _ -> ())

(* One missing-block variant per canonical top-level block (gate 9). Derived
   from the artifact under test by deleting exactly one field, so a negative
   fixture cannot drift from the positive one it is a negative OF. *)
let missing_block_variants (f : family) (j : J.t) : (string * J.t) list =
  match j with
  | J.Obj kvs ->
    List.map
      (fun block -> (block, J.Obj (List.filter (fun (k, _) -> k <> block) kvs)))
      (canonical_blocks_of f)
  | _ -> []

(* ────────────────────────────── the pipeline ─────────────────────────── *)

let read_document (path : string) : (J.t, string) result =
  (* `parse_file` raises on unreadable or malformed input, and the vendored
     parser is not limited to [Parse_error]: a malformed number literal raises
     [Failure] and a truncated `\u` escape raises [Invalid_argument]. All three
     funnel here so every artifact fault is a clean [Error]. *)
  try Ok (J.parse_file path) with
  | Sys_error msg -> Error msg
  | J.Parse_error msg -> Error (Printf.sprintf "%s: %s" path msg)
  | Failure msg -> Error (Printf.sprintf "%s: %s" path msg)
  | Invalid_argument msg -> Error (Printf.sprintf "%s: %s" path msg)

(* The IR's content address: the digest of its CANONICAL serialization, not of
   the bytes on disk. Two files differing only in whitespace or key order are
   the same methodology and must digest identically, or the request binding
   would be a binding to a formatting choice. *)
let ir_digest_of (document : J.t) : string = "sha256:" ^ J.digest document

let load_ir (path : string) : (Ir.t * string, string) result =
  let* document = read_document path in
  let* ir = Result.map_error (fun m -> "IR error: " ^ m) (Ir.of_json document) in
  Ok (ir, ir_digest_of document)

let resolve_request (ir : Ir.t) (sp : spec) ~(ir_digest : string)
  : (Request.t * (string * string) list, string) result =
  match sp.request_path with
  | None -> Request.synthesize ir ~ir_digest ~locators:sp.locators
  | Some path ->
    let* document = read_document path in
    let* rq =
      Result.map_error (fun m -> "run request error: " ^ m) (Request.of_json document) in
    let* manifests = Request.verify rq ~ir_digest ~locators:sp.locators in
    Ok (rq, manifests)

(* Warrant obligations for the emitted class. A strong class with an absent or
   unknown obligation is INVALID even when the rule table would emit it — the
   evidence gate is above the result gate, not beside it. *)
let discharge (ir : Ir.t) (st : Exec.state) (d : Rule.derivation)
  : (Rule.discharge list, string) result =
  let required = Rule.obligations_for ir.Ir.result d.Rule.emitted_class in
  let discharges =
    List.map (Rule.discharge_one ~retained:(Exec.retained_evidence st)) required in
  match List.filter (fun x -> not x.Rule.discharged) discharges with
  | [] -> Ok discharges
  | undischarged ->
    Error (Printf.sprintf
             "result class %S declares warrant obligation(s) that this run did not \
              discharge: %s" d.Rule.emitted_class
             (String.concat "; "
                (List.map
                   (fun x ->
                      Printf.sprintf "%S (%s)" x.Rule.discharged_requirement
                        x.Rule.discharge_note)
                   undischarged)))

let run (sp : spec) : (outputs, string) result =
  (* The SHA-256 self-test runs first so no emitted digest can be silently
     wrong. Every digest in the receipt depends on it. *)
  Sha256.self_test ();
  let* (ir, ir_digest) = load_ir sp.ir_path in
  let* (rq, manifests) = resolve_request ir sp ~ir_digest in
  let request_digest = Request.digest rq in
  let* linked = Result.map_error (fun m -> "link error: " ^ m) (Linker.link ir rq ~request_digest) in
  let* st =
    Exec.execute linked ~locators:sp.locators
      ~evidence_ceiling:rq.Request.bounds.Request.rq_evidence_bytes in
  let env = Exec.env_of_state st in
  let* derivation =
    Result.map_error (fun m -> "result error: " ^ m) (Rule.derive env ir.Ir.result) in
  let* discharges = discharge ir st derivation in
  let receipt =
    Receipt.emit ir rq linked.Linker.plan st derivation discharges
      ~request_digest ~manifests in
  (* SELF-BINDING CHECK (gate 10), applied before a byte is written. A receipt
     that does not admit structurally, or whose three bindings do not match the
     artifacts this very run produced, must not reach disk. *)
  let* parsed =
    Result.map_error (fun m -> "emitted receipt is not admissible: " ^ m)
      (Receipt.of_json receipt) in
  let* () =
    Receipt.binding_error parsed ~request_digest ~cm_ir_digest:rq.Request.cm_ir_digest
      ~plan_digest:(Plan.digest linked.Linker.plan) in
  Ok { receipt;
       plan_json = Plan.to_json linked.Linker.plan;
       request_json = Request.to_json rq;
       summary =
         Printf.sprintf "cm=%s/%s class=%s rule=%s steps=%d"
           ir.Ir.cm_id ir.Ir.cm_version derivation.Rule.emitted_class
           derivation.Rule.matched_rule (List.length st.Exec.trace) }
