(* receipt.ml — `tsc-measurement-receipt/0.2`: one closed common core plus one
   closed, DISCRIMINATED family extension.

   §WHY THE VERSION MOVED. `tsc-measurement-receipt/0.1` is owned on `main` by
   the shipped coh-min receipt, whose core is `cm_id` / `source_digest` /
   `plan_digest` / `sandbox_execution_plan` / `execution_trace` /
   `skipped_steps`. The 0.2 core is `request` / `cm_ir` / `plan` / `runtime` /
   `trace` / `obligations` / `extension`. Those are not the same document with
   fields added; reusing the string would assert a compatibility that does not
   exist and destroy `format` as a discriminator for any verifier that meets
   both.

   §NOT A BAG OF OPTIONAL BLOCKS. Every core block is mandatory. Family-specific
   evidence lives in exactly one `extension`, whose `family` selects a closed
   schema. The alternative — a core full of optional blocks, each present for
   some families — makes "is this receipt complete?" unanswerable, because
   absence would never be distinguishable from inapplicability.

   §WHAT THE RECEIPT MUST CARRY. A standalone `verify` is the next cell, not
   this one, so the receipt's job here is to carry everything that verifier will
   need and to be refused if it does not:

     - the three DIGEST BINDINGS (`request`, `cm_ir`, `plan`), so a verifier can
       tie the receipt to the exact artifacts it was produced from;
     - the DERIVATION WITNESS: the matched `rule_id` and every fact reference
       the evaluator read, each with its value and content digest, so the rule
       can be replayed without re-running any provider;
     - the runtime and provider identities, pinned by digest;
     - the full trace including principled skips WITH the unpublished port that
       caused them, and lawful withholding recorded as `withheld` rather than as
       silence.

   §DIGEST BINDING IS CHECKED, NOT DECORATED (design gate 10). [binding_error]
   is applied by the runtime to its OWN receipt before a single byte is written,
   so a receipt whose bindings do not match the artifacts it was produced from
   never reaches disk. The same pure function is what a verifier will call. A
   digest that is never checked is decoration; this one is checked at both ends.

   §THE ONE FACT THIS FILE IS NOT ALLOWED TO KNOW. Nothing here consults a
   `cm_id`. The result class, the rule id, the reported facts and the obligation
   set all arrive as values derived from the IR by generic code. Adding a third
   methodology changes none of it. *)

module J = Json
open Jread

let ( let* ) = Result.bind

let format_pin = "tsc-measurement-receipt/0.2"

let canonical_blocks =
  [ "format"; "execution_id"; "request"; "cm_ir"; "plan"; "runtime"; "trace";
    "evidence"; "result"; "obligations"; "extension" ]

let runtime_id = "coh-min"
let runtime_version = "0.2.0"

(* The one receipt family v0 defines. An unknown family is REFUSED, not carried
   through: an extension whose schema nobody can check is not evidence. *)
let repository_measurement = "repository_measurement"
let repository_measurement_schema = "tsc://receipt/repository-measurement/0.1"
let families = [ (repository_measurement, repository_measurement_schema) ]

(* ─────────────────────────────── emission ───────────────────────────── *)

let s x = J.Str x
let i x = J.Int x
let b x = J.Bool x
let arr x = J.Arr x
let obj x = J.Obj x

let value_fields (v : Value.t) : (string * J.t) list =
  [ "value", Value.to_json v; "digest", s (Value.digest v) ]

let trace_entry_json (e : Exec.entry) : J.t =
  obj (
    [ "order", i e.Exec.order;
      "step_id", s e.Exec.entry_step;
      "status", s e.Exec.entry_status;
      "provider", obj [ "id", s e.Exec.entry_provider;
                        "digest", s e.Exec.entry_provider_digest ];
      "published", arr
        (List.map (fun (port, v) -> obj (("port", s port) :: value_fields v))
           e.Exec.published);
      (* Lawful withholding is RECORDED, not inferred from silence: a reader can
         see that the port was declared and deliberately not published. *)
      "withheld", arr (List.map s e.Exec.withheld);
      "diagnostics", arr (List.map s e.Exec.diagnostics) ]
    @ (match e.Exec.skip_reason with
       | Some why -> [ "skipped_because", s why ]
       | None -> []))

let evidence_json (e : Exec.entry) : J.t option =
  if e.Exec.entry_evidence = [] then None
  else
    let payload =
      obj (List.map (fun (k, v) -> (k, Value.to_json v)) e.Exec.entry_evidence) in
    Some (obj [
        "step_id", s e.Exec.entry_step;
        "schema", s e.Exec.entry_evidence_schema;
        "digest", s ("sha256:" ^ J.digest payload);
        "predicates", arr
          (List.map (fun (k, v) -> obj (("name", s k) :: value_fields v))
             e.Exec.entry_evidence);
      ])

let reading_json (r : Rule.reading) : J.t =
  let base =
    [ "ref", s (Rule.reference_to_string r.Rule.read_reference);
      "kind", s (Rule.reference_kind r.Rule.read_reference) ] in
  match r.Rule.read_value with
  | Some v -> obj (base @ [ "available", b true ] @ value_fields v)
  | None -> obj (base @ [ "available", b false ])

(* One `receipt.reports` entry, resolved against the fact set. Discriminated the
   same way a fact reference is: an unavailable report says so and says why, and
   never carries a value. *)
let report_json (env : Rule.env) (r : Rule.reference) : J.t =
  let base = [ "ref", s (Rule.reference_to_string r);
               "kind", s (Rule.reference_kind r) ] in
  match Rule.lookup env r with
  | Some v -> obj (base @ [ "available", b true ] @ value_fields v)
  | None ->
    obj (base @ [ "available", b false;
                  "reason", s "the producing step published no such fact in this run" ])

let obligation_json (d : Rule.discharge) : J.t =
  obj [
    "class", s d.Rule.discharged_class;
    "requirement", s d.Rule.discharged_requirement;
    "discharged", b d.Rule.discharged;
    "note", s d.Rule.discharge_note;
  ]

let extension_json (ir : Ir.t) (rq : Request.t) (env : Rule.env)
    ~(manifests : (string * string) list) : J.t =
  obj [
    "family", s ir.Ir.receipt.Ir.family;
    "schema", s ir.Ir.receipt.Ir.family_schema;
    "value", obj [
      (* The governing measurement question is family evidence, not core: it is
         what a repository measurement is FOR, and it is the only place the IR's
         `question` block is consumed. *)
      "question", s ir.Ir.question;
      "measure_only", b ir.Ir.receipt.Ir.measure_only;
      "subject", arr
        (List.map
           (fun (e : Request.subject_entry) ->
              obj [
                "name", s e.Request.subject_name;
                "kind", s e.Request.subject_kind;
                "scheme", s e.Request.subject_scheme;
                "digest", s e.Request.subject_digest;
                (* The snapshot MANIFEST digest: the digest of the exact byte
                   sequence the scheme digested, so a verifier can recompute the
                   subject digest step by step rather than all at once. *)
                "manifest_digest", s
                  ("sha256:" ^
                   Sha256.digest_string
                     (match List.assoc_opt e.Request.subject_name manifests with
                      | Some m -> m
                      | None -> ""));
              ])
           rq.Request.subject);
      "reports", arr (List.map (report_json env) ir.Ir.receipt.Ir.reports);
    ];
  ]

(* The execution id. Deterministic — a digest of the bindings, not a clock or a
   random source, because a receipt that cannot be reproduced byte for byte from
   the same request and plan cannot be diffed, and diffing two receipts is how
   input sensitivity is demonstrated. *)
let execution_id ~(request_digest : string) ~(plan_digest : string) : string =
  "exec:"
  ^ Sha256.digest_string
      (J.document (obj [ "plan", s plan_digest; "request", s request_digest ]))

let runtime_json () : J.t =
  obj [ "id", s runtime_id;
        "version", s runtime_version;
        "digest", s (Provider.surface_digest ()) ]

let emit (ir : Ir.t) (rq : Request.t) (pl : Plan.t) (st : Exec.state)
    (d : Rule.derivation) (discharges : Rule.discharge list)
    ~(request_digest : string) ~(manifests : (string * string) list) : J.t =
  let env = Exec.env_of_state st in
  let plan_digest = Plan.digest pl in
  obj [
    "format", s format_pin;
    "execution_id", s (execution_id ~request_digest ~plan_digest);
    "request", obj [ "digest", s request_digest ];
    "cm_ir", obj [ "digest", s rq.Request.cm_ir_digest ];
    "plan", obj [ "digest", s plan_digest ];
    "runtime", runtime_json ();
    "trace", arr (List.map trace_entry_json st.Exec.trace);
    "evidence", arr (List.filter_map evidence_json st.Exec.trace);
    "result", obj [
      "class", s d.Rule.emitted_class;
      "rule_id", s d.Rule.matched_rule;
      "fact_refs", arr (List.map reading_json d.Rule.witness);
    ];
    "obligations", arr (List.map obligation_json discharges);
    "extension", extension_json ir rq env ~manifests;
  ]

(* ─────────────────────────────── validation ─────────────────────────── *)

(* The typed projection a structural check yields. Deliberately small: this is
   ADMISSION (are the canonical blocks present and well-typed?), not
   VERIFICATION (do the digests match, does the rule replay, are the obligations
   discharged?). Verification is the next cell; conflating the two would let a
   structural pass be mistaken for a verified receipt. *)
type t = {
  format         : string;
  execution_id_  : string;
  request_digest : string;
  cm_ir_digest   : string;
  plan_digest    : string;
  result_class   : string;
  result_rule_id : string;
  family         : string;
}

let digest_field ~(ctx : string) (key : string) (j : J.t) : (string, string) result =
  let* o = required_object ~ctx key j in
  let* () = closed ~ctx:(ctx ^ key ^ ".") ~allowed:[ "digest" ] o in
  required_string ~ctx:(ctx ^ key ^ ".") "digest" o

let of_json (j : J.t) : (t, string) result =
  let ctx = "" in
  let* () = closed ~ctx ~allowed:canonical_blocks j in
  let* format = required_string ~ctx "format" j in
  let* () =
    if String.equal format format_pin then Ok ()
    else
      Error (Printf.sprintf "format %S is not the MeasurementReceipt format %S"
               format format_pin)
  in
  let* execution_id_ = required_string ~ctx "execution_id" j in
  let* request_digest = digest_field ~ctx "request" j in
  let* cm_ir_digest = digest_field ~ctx "cm_ir" j in
  let* plan_digest = digest_field ~ctx "plan" j in
  let* runtime = required_object ~ctx "runtime" j in
  let* () = closed ~ctx:"runtime." ~allowed:[ "id"; "version"; "digest" ] runtime in
  let* _ = required_string ~ctx:"runtime." "id" runtime in
  let* _ = required_string ~ctx:"runtime." "version" runtime in
  let* _ = required_string ~ctx:"runtime." "digest" runtime in
  let* trace = required_array ~ctx "trace" j in
  let* () =
    if trace = [] then
      Error "trace is empty; a receipt that records no step outcome witnesses \
             nothing"
    else Ok () in
  let* _evidence = required_array ~ctx "evidence" j in
  let* result = required_object ~ctx "result" j in
  let* () = closed ~ctx:"result." ~allowed:[ "class"; "rule_id"; "fact_refs" ] result in
  let* result_class = required_string ~ctx:"result." "class" result in
  let* result_rule_id = required_string ~ctx:"result." "rule_id" result in
  let* _ = required_array ~ctx:"result." "fact_refs" result in
  let* _obligations = required_array ~ctx "obligations" j in
  let* extension = required_object ~ctx "extension" j in
  let* () = closed ~ctx:"extension." ~allowed:[ "family"; "schema"; "value" ] extension in
  let* family = required_string ~ctx:"extension." "family" extension in
  let* schema = required_string ~ctx:"extension." "schema" extension in
  let* () =
    match List.assoc_opt family families with
    | None ->
      Error (Printf.sprintf
               "extension.family %S is not a known receipt family [%s]; an \
                extension whose schema cannot be checked is not evidence" family
               (String.concat ", " (List.map (fun (f, _) -> Printf.sprintf "%S" f) families)))
    | Some expected when not (String.equal expected schema) ->
      Error (Printf.sprintf
               "extension.family %S declares schema %S, but that family's schema is %S"
               family schema expected)
    | Some _ -> Ok ()
  in
  let* _ = required_object ~ctx:"extension." "value" extension in
  Ok { format; execution_id_; request_digest; cm_ir_digest; plan_digest;
       result_class; result_rule_id; family }

(* ───────────────────────── digest binding (gate 10) ──────────────────── *)

(* Refuse a receipt whose bindings do not match the artifacts it claims to have
   been produced from. Each of the three is checked SEPARATELY so the refusal
   names which binding broke — a single "digest mismatch" message would leave a
   reader to guess whether the request, the IR or the plan had drifted. *)
let binding_error (r : t) ~(request_digest : string) ~(cm_ir_digest : string)
    ~(plan_digest : string) : (unit, string) result =
  let check what actual expected =
    if String.equal actual expected then Ok ()
    else
      Error (Printf.sprintf
               "receipt binds %s digest %s, but the artifact it was produced from \
                digests to %s" what actual expected)
  in
  let* () = check "request" r.request_digest request_digest in
  let* () = check "cm_ir" r.cm_ir_digest cm_ir_digest in
  check "plan" r.plan_digest plan_digest
