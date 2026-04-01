(** Provider: LLM API client.

    Impure module — performs HTTP calls and reads environment.
    Lives in bin/, not lib/, because lib/ is pure.
    Secrets come from runtime environment only, never from repo. *)

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

(** Build a curl config string for --config - (stdin).
    Per ocaml skill §2.5: safe subprocess, no shell injection.
    All arguments are passed via config file, never interpolated into shell. *)
let build_curl_config ~url ~auth_header ~data_file =
  Printf.sprintf
    "url = \"%s\"\n\
     request = \"POST\"\n\
     header = \"Content-Type: application/json\"\n\
     header = \"%s\"\n\
     data = \"@%s\"\n\
     silent\n"
    url auth_header data_file

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

(** Call the LLM provider with a system message and user message.
    Returns the raw response body string.

    Uses curl subprocess with --config - for safe argument passing.
    No shell interpolation of user data. *)
let call_provider ~config ~system_message ~user_message =
  let url = api_url config in
  let request_body = build_request_body ~config ~system_message ~user_message in
  let auth_header =
    match config.provider_name with
    | "anthropic" ->
      Printf.sprintf "x-api-key: %s" config.provider_api_key
    | _ ->
      Printf.sprintf "Authorization: Bearer %s" config.provider_api_key
  in
  let tmp_file = Filename.temp_file "tsc_request_" ".json" in
  let oc = open_out tmp_file in
  Fun.protect ~finally:(fun () -> close_out oc) (fun () ->
    output_string oc request_body
  );
  let curl_config = build_curl_config ~url ~auth_header ~data_file:tmp_file in
  Fun.protect ~finally:(fun () -> Sys.remove tmp_file) (fun () ->
    (* Use Unix.create_process to avoid shell entirely *)
    let (r_out, w_out) = Unix.pipe () in
    let (r_in, w_in) = Unix.pipe () in
    let pid =
      Unix.create_process "curl"
        [| "curl"; "--config"; "-" |]
        r_in w_out Unix.stderr
    in
    Unix.close w_out;
    Unix.close r_in;
    (* Write config to curl stdin *)
    let oc_in = Unix.out_channel_of_descr w_in in
    output_string oc_in curl_config;
    close_out oc_in;
    (* Read response from curl stdout *)
    let ic_out = Unix.in_channel_of_descr r_out in
    let buf = Buffer.create 4096 in
    (try while true do
       Buffer.add_char buf (input_char ic_out)
     done with End_of_file -> ());
    close_in ic_out;
    let _, status = Unix.waitpid [] pid in
    match status with
    | Unix.WEXITED 0 -> Ok (Buffer.contents buf)
    | Unix.WEXITED n -> Error (Printf.sprintf "curl exited with code %d" n)
    | _ -> Error "curl terminated abnormally"
  )
