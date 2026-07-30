(** Local LLM credential detection for auto-mode.

    "Credentials present" means the FULL provider configuration the
    HTTP route requires — LLM_PROVIDER, LLM_MODEL, and LLM_API_KEY all
    non-empty (bin/provider.ml, config_from_env, needs all three). A
    partial set must never route auto into hybrid: the provider call
    would fail downstream after the run already claimed the semantic
    path. Auto-mode surfaces a partial set as a visible warning naming
    the missing variables, then runs mechanical (Issue C of the
    meter-v3.2.4-prep wave — the k=5 audit found detection keyed on
    LLM_API_KEY alone).

    ANTHROPIC_API_KEY is deliberately NOT part of this contract: it is
    the CI witness secret shape (routed by the rendered workflows),
    not the engine's local provider route. *)

let provider_env_vars = [ "LLM_PROVIDER"; "LLM_MODEL"; "LLM_API_KEY" ]

(** Names of the provider variables that are unset or empty. *)
let missing_llm_credentials () =
  List.filter
    (fun v ->
      match Sys.getenv_opt v with
      | Some s when String.length s > 0 -> false
      | _ -> true)
    provider_env_vars

(** True iff the full provider configuration is present. *)
let has_llm_credentials () = missing_llm_credentials () = []

(** True iff SOME but not ALL provider variables are set — the
    misconfiguration auto-mode must warn about instead of guessing. *)
let partial_llm_credentials () =
  let missing = missing_llm_credentials () in
  missing <> [] && List.length missing < List.length provider_env_vars
