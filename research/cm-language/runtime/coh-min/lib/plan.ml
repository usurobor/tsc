(* plan.ml — `tsc-sandbox-plan/0.1`: the linker's closed, concrete answer for
   ONE request, as an artifact.

   The plan is the second of the two step moments the design insists on keeping
   apart. An `Ir.step` is what the METHODOLOGY REQUIRES: a capability, typed
   ports, a config, a capability request, bounds. A `Plan.step` is what the
   LINKER SELECTED AND GRANTED: a concrete provider pinned by version and
   digest, the adapters bound to each input slot, the grants actually issued,
   the limits actually imposed — and a `discharge` record citing, obligation by
   obligation, what was proved before execution was permitted.

   Fusing the two would destroy the distinction that makes measurement portable:
   the methodology would name a provider, and running the same CM on another
   host would mean editing the methodology.

   `discharge` is not decoration and not a claim the runtime makes about itself.
   Each flag corresponds to one obligation in the design's linker list, and the
   linker CANNOT construct a plan step with a flag set to false: [Linker] refuses
   before it builds the record. The flags are therefore a readable projection of
   which proofs were required, carried into the receipt so a verifier can see
   the obligation set the plan was admitted under rather than having to know it.

   This module owns the artifact — its type, its canonical serialization, and a
   TOTAL validator so a plan handed to the runtime from outside is refused for
   exactly the same reasons a malformed IR is. *)

module J = Json
open Jread

let ( let* ) = Result.bind

let format_pin = "tsc-sandbox-plan/0.1"

let canonical_blocks = [ "format"; "request_digest"; "cm_ir_digest"; "steps" ]

(* The linker's obligations, one flag each (design §SandboxExecutionPlan, plus
   `config_schema` for gate 11). Named once; the CUE contract and the receipt
   both derive their field set from this list. *)
let discharge_obligations =
  [ "checker_interface"; "input_schemas"; "output_schemas"; "evidence_schema";
    "config_schema"; "capability_subset"; "bounds_within_request" ]

type adapter = {
  adapter_slot   : string;
  adapter_kind   : string;
  adapter_handle : string;
}

type limits = {
  wall_time_ms : int;
  output_bytes : int;
}

type step = {
  step_id          : string;
  provider_id      : string;
  provider_version : string;
  provider_digest  : string;
  adapters         : adapter list;
  grants           : string list;
  limits           : limits;
}

type t = {
  format         : string;
  request_digest : string;
  cm_ir_digest   : string;
  steps          : step list;
}

(* ───────────────────────────── serialization ─────────────────────────── *)

let step_to_json (s : step) : J.t =
  let str x = J.Str x in
  J.Obj [
    "step_id", str s.step_id;
    "provider", J.Obj [
      "id", str s.provider_id;
      "version", str s.provider_version;
      "digest", str s.provider_digest;
    ];
    "adapters", J.Obj
      (List.map
         (fun a -> (a.adapter_slot,
                    J.Obj [ "kind", str a.adapter_kind; "handle", str a.adapter_handle ]))
         s.adapters);
    "grants", J.Arr (List.map str s.grants);
    "limits", J.Obj [
      "wall_time_ms", J.Int s.limits.wall_time_ms;
      "output_bytes", J.Int s.limits.output_bytes;
    ];
    (* Every obligation, always true — because a plan step for which one was
       false was never constructed. *)
    "discharge", J.Obj (List.map (fun o -> (o, J.Bool true)) discharge_obligations);
  ]

let to_json (p : t) : J.t =
  J.Obj [
    "format", J.Str p.format;
    "request_digest", J.Str p.request_digest;
    "cm_ir_digest", J.Str p.cm_ir_digest;
    "steps", J.Arr (List.map step_to_json p.steps);
  ]

let digest (p : t) : string = "sha256:" ^ J.digest (to_json p)

(* ────────────────────────────── validation ───────────────────────────── *)

let adapter_of_json (adapter_slot : string) (j : J.t) : (adapter, string) result =
  let ctx = Printf.sprintf "steps[].adapters.%s." adapter_slot in
  let* () = closed ~ctx ~allowed:[ "kind"; "handle" ] j in
  let* adapter_kind = required_string ~ctx "kind" j in
  let* adapter_handle = required_string ~ctx "handle" j in
  Ok { adapter_slot; adapter_kind; adapter_handle }

let step_of_json (index : int) (j : J.t) : (step, string) result =
  let ctx = Printf.sprintf "steps[%d]." index in
  let* () =
    closed ~ctx
      ~allowed:[ "step_id"; "provider"; "adapters"; "grants"; "limits"; "discharge" ] j in
  let* step_id = required_string ~ctx "step_id" j in
  let* provider = required_object ~ctx "provider" j in
  let pctx = ctx ^ "provider." in
  let* () = closed ~ctx:pctx ~allowed:[ "id"; "version"; "digest" ] provider in
  let* provider_id = required_string ~ctx:pctx "id" provider in
  let* provider_version = required_string ~ctx:pctx "version" provider in
  let* provider_digest = required_string ~ctx:pctx "digest" provider in
  let* adapters_j = required_object ~ctx "adapters" j in
  let* adapters =
    match adapters_j with
    | J.Obj kvs ->
      let* () = unique ~what:"adapter slot" (List.map fst kvs) in
      all (List.map
             (fun (k, v) ->
                if is_obj v then adapter_of_json k v
                else malformed (ctx ^ "adapters.") k "an object")
             kvs)
    | _ -> Error (ctx ^ "adapters must be an object")
  in
  let* grants = required_string_array ~ctx "grants" j in
  let* limits_j = required_object ~ctx "limits" j in
  let lctx = ctx ^ "limits." in
  let* () = closed ~ctx:lctx ~allowed:[ "wall_time_ms"; "output_bytes" ] limits_j in
  let* wall_time_ms = required_int ~ctx:lctx "wall_time_ms" limits_j in
  let* output_bytes = required_int ~ctx:lctx "output_bytes" limits_j in
  (* The discharge record must be COMPLETE and every obligation must be proved.
     An unproved obligation refuses linking (design §SandboxExecutionPlan), so a
     plan carrying `false` — or omitting a flag entirely — never executes. *)
  let* discharge = required_object ~ctx "discharge" j in
  let dctx = ctx ^ "discharge." in
  let* () = closed ~ctx:dctx ~allowed:discharge_obligations discharge in
  let* () =
    all (List.map
           (fun o ->
              let* v = required_bool ~ctx:dctx o discharge in
              if v then Ok ()
              else
                Error (Printf.sprintf
                         "%s%s is false; any unproved linker obligation refuses \
                          execution" dctx o))
           discharge_obligations)
    |> Result.map (fun _ -> ())
  in
  Ok { step_id; provider_id; provider_version; provider_digest; adapters; grants;
       limits = { wall_time_ms; output_bytes } }

let of_json (j : J.t) : (t, string) result =
  let ctx = "" in
  let* () = closed ~ctx ~allowed:canonical_blocks j in
  let* format = required_string ~ctx "format" j in
  let* () =
    if String.equal format format_pin then Ok ()
    else
      Error (Printf.sprintf "format %S is not the SandboxExecutionPlan format %S"
               format format_pin)
  in
  let* request_digest = required_string ~ctx "request_digest" j in
  let* cm_ir_digest = required_string ~ctx "cm_ir_digest" j in
  let* step_jsons = required_array ~ctx "steps" j in
  let* steps = all (List.mapi step_of_json step_jsons) in
  let* () =
    if steps = [] then Error "steps binds no checker; an empty plan executes nothing"
    else Ok () in
  let* () = unique ~what:"plan step id" (List.map (fun s -> s.step_id) steps) in
  Ok { format; request_digest; cm_ir_digest; steps }
