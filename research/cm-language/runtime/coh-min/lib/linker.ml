(* linker.ml — select a concrete provider for every normalized step and PROVE
   the plan satisfies the methodology's requirements without granting more
   authority than was declared.

   The linker is where "a methodology is data" is either true or a slogan. It is
   handed a `NormalizedCMIR` (what is required), a `RunRequest` (what subject,
   under what ceiling) and the provider registry (what this host can do), and it
   answers with a `SandboxExecutionPlan` — or it refuses. It never consults a
   `cm_id`: every decision below is a function of a DECLARED requirement and a
   DECLARED capability contract.

   The obligations, in the design's order, each refused by name:

     1. every normalized step has exactly one binding      [capability lookup]
     2. the provider implements the required interface     [checker_interface]
     3. input, output and evidence schemas are compatible  [*_schemas]
     4. grants are sufficient AND do not exceed either the
        step request or the RunRequest ceiling             [capability_subset]
     5. plan limits are within normalized and request bounds
                                                           [bounds_within_request]
     6. every artifact adapter is confined to its declared subject surface
                                                           [adapters]
     7. provider identities are pinned by version and digest

   plus the correction pass's gate 11:

     8. the step's `config` validates against the schema owned by the CAPABILITY
        it binds                                           [config_schema]

   §MISSING AND EXCESS ARE BOTH ERRORS. A step that requests fewer capabilities
   than its provider needs cannot run (the provider would act outside what the
   methodology declared); a step that requests more than the run's ceiling
   permits must not run (the host would grant authority the operator did not
   offer). Both refuse. It is tempting to treat excess as harmless — it is not:
   an over-broad request that is silently trimmed makes the methodology's
   declared envelope a lie.

   §WHY REQUIREDNESS IS CHECKED HERE. A methodology may declare a capability's
   WITHHOLDABLE port as `required: false` and skip downstream when it is absent.
   It may NOT declare that port `required: true`: the capability does not promise
   it, so the methodology would be asserting a contract the provider never
   signed, and every run against a subject that triggers withholding would end
   in a provider-contract rejection instead of a principled skip. Refusing at
   link time turns a whole class of confusing runtime failures into one static
   message. *)

open Jread

let ( let* ) = Result.bind

(* One step, after linking: what the methodology required, who implements it,
   and what the plan granted. The three are kept together so the executor never
   has to re-derive a binding, and never has to re-open the IR. *)
type linked = {
  l_step : Ir.step;
  l_cap  : Provider.capability;
  l_plan : Plan.step;
}

type t = {
  plan   : Plan.t;
  linked : linked list;
}

(* ─────────────────────────── config validation ───────────────────────── *)

(* Gate 11. The CAPABILITY owns the shape; the methodology supplies the values;
   the linker is the only place the two meet. A provider is never handed a
   config it has not been proved to accept. *)
let validate_config ~(step_id : string) (cap : Provider.capability)
    (config : (string * Value.t) list) : (unit, string) result =
  let declared = List.map (fun f -> f.Provider.cfg_name) cap.Provider.cap_config in
  let* () =
    match List.filter (fun (k, _) -> not (List.mem k declared)) config with
    | [] -> Ok ()
    | extra ->
      Error (Printf.sprintf
               "step %S config carries field(s) [%s] that capability %S does not \
                declare; a capability's config schema is closed — a provider may \
                widen nothing and narrow nothing [declared: %s]"
               step_id
               (String.concat ", " (List.map (fun (k, _) -> Printf.sprintf "%S" k) extra))
               cap.Provider.cap_id
               (String.concat ", " (List.map (Printf.sprintf "%S") declared)))
  in
  let check (f : Provider.config_field) =
    match List.assoc_opt f.Provider.cfg_name config, f.Provider.cfg_required with
    | None, true ->
      Error (Printf.sprintf
               "step %S config is missing %S, which capability %S requires (%s)"
               step_id f.Provider.cfg_name cap.Provider.cap_id
               (Provider.config_type_name f.Provider.cfg_type))
    | None, false -> Ok ()
    | Some v, _ ->
      let mismatch () =
        Error (Printf.sprintf
                 "step %S config.%s is %s (%s), but capability %S declares it as %s"
                 step_id f.Provider.cfg_name (Value.to_display v) (Value.type_name v)
                 cap.Provider.cap_id (Provider.config_type_name f.Provider.cfg_type))
      in
      (match f.Provider.cfg_type, v with
       | Provider.Cfg_bool, Value.Bool _ -> Ok ()
       | Provider.Cfg_int_min floor, Value.Int i ->
         if i >= floor then Ok () else mismatch ()
       | Provider.Cfg_confined_path, Value.Str s ->
         (* Static confinement: an escaping literal is a property of the
            METHODOLOGY DOCUMENT, so it is refusable before anything runs — and
            refusing here is what keeps "path escape denies with zero receipt
            bytes" true, because no receipt can exist for a run that never
            linked. *)
         (match Provider.confine ~root:"/subject" ~rel:s with
          | Ok _ -> Ok ()
          | Error why ->
            Error (Printf.sprintf
                     "step %S config.%s is not a confined subject-relative path: %s"
                     step_id f.Provider.cfg_name why))
       | _ -> mismatch ())
  in
  all (List.map check cap.Provider.cap_config) |> Result.map (fun _ -> ())

(* ──────────────────────── port and slot compatibility ────────────────── *)

let validate_inputs ~(step_id : string) (cap : Provider.capability)
    (inputs : Ir.step_input list) : (unit, string) result =
  let check (i : Ir.step_input) =
    match Provider.slot cap i.Ir.in_name with
    | None ->
      Error (Printf.sprintf
               "step %S binds input %S, which capability %S does not declare \
                [slots: %s]" step_id i.Ir.in_name cap.Provider.cap_id
               (String.concat ", "
                  (List.map (fun s -> Printf.sprintf "%S" s.Provider.slot_name)
                     cap.Provider.cap_slots)))
    | Some slot ->
      if not (String.equal slot.Provider.slot_schema i.Ir.in_schema) then
        Error (Printf.sprintf
                 "step %S input %S declares schema %S, but capability %S declares \
                  %S" step_id i.Ir.in_name i.Ir.in_schema cap.Provider.cap_id
                 slot.Provider.slot_schema)
      else
        (* Kind compatibility: a subject artifact and a scalar produced by a peer
           step are not interchangeable, and a mismatch here would surface as an
           unbound adapter deep inside a provider. *)
        (match slot.Provider.slot_kind, i.Ir.in_from with
         | Provider.Slot_artifact, Ir.From_input _ -> Ok ()
         | Provider.Slot_value, Ir.From_output _ -> Ok ()
         | Provider.Slot_artifact, Ir.From_output _ ->
           Error (Printf.sprintf
                    "step %S binds %s into artifact slot %S; an artifact slot takes \
                     a CM subject input, not a step output"
                    step_id (Ir.binding_to_string i.Ir.in_from) i.Ir.in_name)
         | Provider.Slot_value, Ir.From_input _ ->
           Error (Printf.sprintf
                    "step %S binds %s into value slot %S; a value slot takes another \
                     step's output port, not a CM subject input"
                    step_id (Ir.binding_to_string i.Ir.in_from) i.Ir.in_name))
  in
  let* () = all (List.map check inputs) |> Result.map (fun _ -> ()) in
  (* Every slot the capability declares must be bound: a provider must not be
     invoked with a hole. *)
  let unbound =
    List.filter
      (fun s ->
         not (List.exists (fun i -> String.equal i.Ir.in_name s.Provider.slot_name) inputs))
      cap.Provider.cap_slots
  in
  match unbound with
  | [] -> Ok ()
  | _ ->
    Error (Printf.sprintf
             "step %S leaves capability %S input slot(s) [%s] unbound"
             step_id cap.Provider.cap_id
             (String.concat ", "
                (List.map (fun s -> Printf.sprintf "%S" s.Provider.slot_name) unbound)))

let validate_outputs ~(step_id : string) (cap : Provider.capability)
    (outputs : Ir.step_output list) : (unit, string) result =
  let check (o : Ir.step_output) =
    match Provider.port cap o.Ir.out_name with
    | None ->
      Error (Printf.sprintf
               "step %S declares output port %S, which capability %S does not \
                publish [ports: %s]" step_id o.Ir.out_name cap.Provider.cap_id
               (String.concat ", "
                  (List.map (fun p -> Printf.sprintf "%S" p.Provider.port_name)
                     cap.Provider.cap_ports)))
    | Some p ->
      if not (String.equal p.Provider.port_schema o.Ir.out_schema) then
        Error (Printf.sprintf
                 "step %S output %S declares schema %S, but capability %S publishes \
                  it as %S" step_id o.Ir.out_name o.Ir.out_schema cap.Provider.cap_id
                 p.Provider.port_schema)
      else if o.Ir.out_required && p.Provider.port_withholdable then
        Error (Printf.sprintf
                 "step %S declares output %S as required, but capability %S may \
                  lawfully withhold it; declare it \"required\": false and let the \
                  dependent step skip, or bind a capability that promises it"
                 step_id o.Ir.out_name cap.Provider.cap_id)
      else Ok ()
  in
  all (List.map check outputs) |> Result.map (fun _ -> ())

let validate_evidence ~(step_id : string) (cap : Provider.capability) (s : Ir.step)
  : (unit, string) result =
  if not (String.equal s.Ir.ev_schema cap.Provider.cap_evidence_schema) then
    Error (Printf.sprintf
             "step %S declares evidence schema %S, but capability %S produces %S"
             step_id s.Ir.ev_schema cap.Provider.cap_id cap.Provider.cap_evidence_schema)
  else
    match
      List.filter (fun p -> not (List.mem p cap.Provider.cap_evidence_predicates))
        s.Ir.ev_predicates
    with
    | [] -> Ok ()
    | unknown ->
      Error (Printf.sprintf
               "step %S declares evidence predicate(s) [%s] that capability %S does \
                not emit [%s]" step_id
               (String.concat ", " (List.map (Printf.sprintf "%S") unknown))
               cap.Provider.cap_id
               (String.concat ", "
                  (List.map (Printf.sprintf "%S") cap.Provider.cap_evidence_predicates)))

(* ─────────────────────────── grants and bounds ───────────────────────── *)

let validate_grants ~(step_id : string) (cap : Provider.capability) (s : Ir.step)
    (ceiling : string list) : (unit, string) result =
  let missing =
    List.filter (fun g -> not (List.mem g s.Ir.requested_capabilities))
      cap.Provider.cap_grants in
  let excess =
    List.filter (fun g -> not (List.mem g ceiling)) s.Ir.requested_capabilities in
  if missing <> [] then
    Error (Printf.sprintf
             "step %S requests [%s], but provider for %S needs [%s]: capability/ies \
              [%s] are missing" step_id
             (String.concat ", " (List.map (Printf.sprintf "%S") s.Ir.requested_capabilities))
             cap.Provider.cap_id
             (String.concat ", " (List.map (Printf.sprintf "%S") cap.Provider.cap_grants))
             (String.concat ", " (List.map (Printf.sprintf "%S") missing)))
  else if excess <> [] then
    Error (Printf.sprintf
             "step %S requests capability/ies [%s] outside the run request's \
              capability_ceiling [%s]; excess capability is an error, not a \
              harmless over-request" step_id
             (String.concat ", " (List.map (Printf.sprintf "%S") excess))
             (String.concat ", " (List.map (Printf.sprintf "%S") ceiling)))
  else Ok ()

let validate_bounds ~(step_id : string) (s : Ir.step) (rq : Request.run_bounds)
  : (unit, string) result =
  if s.Ir.step_bounds.Ir.wall_time_ms > rq.Request.rq_wall_time_ms then
    Error (Printf.sprintf
             "step %S declares wall_time_ms %d above the run request's %d"
             step_id s.Ir.step_bounds.Ir.wall_time_ms rq.Request.rq_wall_time_ms)
  else if s.Ir.step_bounds.Ir.output_bytes > rq.Request.rq_output_bytes then
    Error (Printf.sprintf
             "step %S declares output_bytes %d above the run request's %d"
             step_id s.Ir.step_bounds.Ir.output_bytes rq.Request.rq_output_bytes)
  else Ok ()

(* ─────────────────────────────── adapters ────────────────────────────── *)

(* An adapter binds one input slot to a concrete surface, and every artifact
   adapter must name a subject entry the REQUEST actually carries. A step cannot
   reach a subject the request did not bind — that is the confinement obligation
   at the plan level, above the per-path confinement the provider applies. *)
let adapters_of ~(step_id : string) (rq : Request.t) (s : Ir.step)
  : (Plan.adapter list, string) result =
  all (List.map
         (fun (i : Ir.step_input) ->
            match i.Ir.in_from with
            | Ir.From_input name ->
              if List.exists (fun e -> String.equal e.Request.subject_name name) rq.Request.subject
              then
                Ok { Plan.adapter_slot = i.Ir.in_name;
                     adapter_kind = "readonly_directory";
                     adapter_handle = "subject:" ^ name }
              else
                Error (Printf.sprintf
                         "step %S input %S binds CM input %S, which the run request's \
                          subject does not carry [%s]" step_id i.Ir.in_name name
                         (String.concat ", "
                            (List.map (fun e -> Printf.sprintf "%S" e.Request.subject_name)
                               rq.Request.subject)))
            | Ir.From_output (sid, port) ->
              Ok { Plan.adapter_slot = i.Ir.in_name;
                   adapter_kind = "step_output";
                   adapter_handle = Printf.sprintf "%s.%s" sid port })
         s.Ir.step_inputs)

(* ────────────────────────────── link one step ────────────────────────── *)

let link_step (rq : Request.t) (s : Ir.step) : (linked, string) result =
  let step_id = s.Ir.step_id in
  let* cap =
    match Provider.find_capability s.Ir.capability with
    | Some c -> Ok c
    | None ->
      Error (Printf.sprintf
               "step %S requires checker capability %S, for which no provider is \
                registered [registered: %s]" step_id s.Ir.capability
               (String.concat ", " (List.map (Printf.sprintf "%S") (Provider.known_capability_ids ()))))
  in
  let* () =
    if String.equal cap.Provider.cap_interface s.Ir.interface then Ok ()
    else
      Error (Printf.sprintf
               "step %S requires checker interface %S, but the provider for %S \
                implements %S" step_id s.Ir.interface cap.Provider.cap_id
               cap.Provider.cap_interface)
  in
  let* () = validate_inputs ~step_id cap s.Ir.step_inputs in
  let* () = validate_outputs ~step_id cap s.Ir.step_outputs in
  let* () = validate_evidence ~step_id cap s in
  let* () = validate_config ~step_id cap s.Ir.step_config in
  let* () = validate_grants ~step_id cap s rq.Request.capability_ceiling in
  let* () = validate_bounds ~step_id s rq.Request.bounds in
  let* adapters = adapters_of ~step_id rq s in
  Ok { l_step = s;
       l_cap = cap;
       l_plan = {
         Plan.step_id;
         provider_id = cap.Provider.cap_provider_id;
         provider_version = cap.Provider.cap_provider_version;
         provider_digest = Provider.capability_digest cap;
         adapters;
         (* Granted is exactly what the provider needs — never the whole set the
            step was permitted to ask for. Least authority is the plan's job. *)
         grants = cap.Provider.cap_grants;
         limits = { Plan.wall_time_ms = s.Ir.step_bounds.Ir.wall_time_ms;
                    output_bytes = s.Ir.step_bounds.Ir.output_bytes };
       } }

let link (ir : Ir.t) (rq : Request.t) ~(request_digest : string) : (t, string) result =
  (* The request's own ceiling must be inside what the methodology permits:
     a request cannot widen a CM's declared envelope. *)
  let* () =
    match
      List.filter (fun c -> not (List.mem c ir.Ir.permissions.Ir.permitted_capabilities))
        rq.Request.capability_ceiling
    with
    | [] -> Ok ()
    | extra ->
      Error (Printf.sprintf
               "run request offers capability/ies [%s] the CM's permissions do not \
                declare [%s]"
               (String.concat ", " (List.map (Printf.sprintf "%S") extra))
               (String.concat ", "
                  (List.map (Printf.sprintf "%S") ir.Ir.permissions.Ir.permitted_capabilities)))
  in
  let* linked = all (List.map (link_step rq) ir.Ir.steps) in
  Ok { plan = { Plan.format = Plan.format_pin;
                request_digest;
                cm_ir_digest = rq.Request.cm_ir_digest;
                steps = List.map (fun l -> l.l_plan) linked };
       linked }
