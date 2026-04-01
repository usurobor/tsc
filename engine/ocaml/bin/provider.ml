(** Provider: LLM API client.

    Impure module — performs HTTP calls and reads environment.
    Lives in bin/, not lib/, because lib/ is pure.
    Secrets come from runtime environment only, never from repo.

    Transport: ezcurl (libcurl bindings). No subprocess, no shell. *)

open Tsc_engine.Types

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

(** Build the JSON request body using Yojson to avoid injection. *)
let build_request_body ~config ~system_message ~user_message =
  let json =
    match config.provider_name with
    | "anthropic" ->
      `Assoc [
        ("model", `String config.provider_model);
        ("max_tokens", `Int 4096);
        ("system", `String system_message);
        ("messages", `List [
          `Assoc [
            ("role", `String "user");
            ("content", `String user_message);
          ]
        ]);
      ]
    | _ ->
      `Assoc [
        ("model", `String config.provider_model);
        ("max_tokens", `Int 4096);
        ("messages", `List [
          `Assoc [
            ("role", `String "system");
            ("content", `String system_message);
          ];
          `Assoc [
            ("role", `String "user");
            ("content", `String user_message);
          ];
        ]);
      ]
  in
  Yojson.Safe.to_string json

(** Build HTTP headers for the given provider. *)
let build_headers config =
  let content_type = "Content-Type", "application/json" in
  match config.provider_name with
  | "anthropic" ->
    [ content_type;
      "x-api-key", config.provider_api_key;
      "anthropic-version", "2023-06-01" ]
  | _ ->
    [ content_type;
      "Authorization", Printf.sprintf "Bearer %s" config.provider_api_key ]

(** Call the LLM provider with a system message and user message.
    Returns the raw response body string.

    Uses ezcurl for HTTP — no subprocess, no shell, no temp files. *)
let call_provider ~config ~system_message ~user_message =
  let url = api_url config in
  let content = build_request_body ~config ~system_message ~user_message in
  let headers = build_headers config in
  match Ezcurl.post ~url ~headers ~content:(`String content) ~params:[] () with
  | Ok response ->
    if response.Ezcurl.code >= 200 && response.Ezcurl.code < 300 then
      Ok response.Ezcurl.body
    else
      Error (Printf.sprintf "HTTP %d: %s" response.Ezcurl.code response.Ezcurl.body)
  | Error (_, msg) ->
    Error (Printf.sprintf "HTTP request failed: %s" msg)
