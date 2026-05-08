let has_llm_credentials () =
  match Sys.getenv_opt "LLM_API_KEY" with
  | Some v when String.length v > 0 -> true
  | _ -> false
