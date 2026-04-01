(** Provider: LLM API client.

    This is the ONLY impure module in the engine library.
    It performs HTTP calls to an LLM provider API.
    Secrets come from runtime environment only, never from repo. *)

open Types

(** Read provider configuration from environment variables.
    Required: TSC_PROVIDER, TSC_MODEL, TSC_API_KEY
    Optional: TSC_BASE_URL *)
let config_from_env () =
  let get var =
    match Sys.getenv_opt var with
    | Some v when String.length v > 0 -> Ok v
    | _ -> Error (Printf.sprintf "environment variable %s is not set" var)
  in
  match get "TSC_PROVIDER", get "TSC_MODEL", get "TSC_API_KEY" with
  | Ok name, Ok model, Ok key ->
    Ok {
      provider_name = name;
      provider_model = model;
      provider_api_key = key;
      provider_base_url = Sys.getenv_opt "TSC_BASE_URL";
    }
  | Error e, _, _ | _, Error e, _ | _, _, Error e -> Error e

(** Build the API URL for a given provider. *)
let api_url config =
  match config.provider_base_url with
  | Some url -> url
  | None ->
    match config.provider_name with
    | "anthropic" -> "https://api.anthropic.com/v1/messages"
    | "openai" -> "https://api.openai.com/v1/chat/completions"
    | _ -> Printf.sprintf "https://api.%s.com/v1/messages" config.provider_name

(** Call the LLM provider with a system message and user message.
    Returns the raw response body string.

    Uses curl subprocess for HTTP — no OCaml HTTP library dependency.
    Per ocaml skill §2.5: safe subprocess, no shell injection. *)
let call_provider ~config ~system_message ~user_message =
  let url = api_url config in
  let request_body =
    match config.provider_name with
    | "anthropic" ->
      Printf.sprintf
        {|{"model":"%s","max_tokens":4096,"system":"%s","messages":[{"role":"user","content":"%s"}]}|}
        config.provider_model
        (String.escaped system_message)
        (String.escaped user_message)
    | _ ->
      Printf.sprintf
        {|{"model":"%s","max_tokens":4096,"messages":[{"role":"system","content":"%s"},{"role":"user","content":"%s"}]}|}
        config.provider_model
        (String.escaped system_message)
        (String.escaped user_message)
  in
  let auth_header =
    match config.provider_name with
    | "anthropic" ->
      Printf.sprintf "x-api-key: %s" config.provider_api_key
    | _ ->
      Printf.sprintf "Authorization: Bearer %s" config.provider_api_key
  in
  let tmp_file = Filename.temp_file "tsc_request_" ".json" in
  let oc = open_out tmp_file in
  output_string oc request_body;
  close_out oc;
  Fun.protect ~finally:(fun () -> Sys.remove tmp_file) (fun () ->
    let cmd =
      Printf.sprintf
        "curl -s -X POST '%s' -H 'Content-Type: application/json' -H '%s' -d @'%s'"
        url auth_header tmp_file
    in
    let ic = Unix.open_process_in cmd in
    Fun.protect ~finally:(fun () -> ignore (Unix.close_process_in ic)) (fun () ->
      let buf = Buffer.create 4096 in
      (try while true do
         Buffer.add_char buf (input_char ic)
       done with End_of_file -> ());
      Ok (Buffer.contents buf)
    )
  )
