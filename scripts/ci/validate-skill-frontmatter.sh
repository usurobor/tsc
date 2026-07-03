#!/usr/bin/env bash
# scripts/ci/validate-skill-frontmatter.sh — validate every SKILL.md
# frontmatter against schemas/skill.cue.
#
# Adapted from cnos:scripts/ci/validate-skill-frontmatter.sh (the I5
# coherence-CI job there). Same surface boundary: the CUE schema owns
# shape / type / enum constraints; this script owns file discovery,
# frontmatter extraction, and the tsc-specific cross-file checks that
# keep a `measurement` skill honest:
#
#   - every declared mechanical signal code exists in the declared
#     mechanical backend source file;
#   - every declared LLM estimate field appears in the declared scoring
#     instruction (the output contract);
#   - every path the skill points at (registry, instruction, backend,
#     render outputs) exists in the repository.
#
# Exit codes:
#   0  every SKILL.md (or fixture) passed
#   1  one or more validation failures
#   2  prerequisite missing (cue, python3+yaml, jq) — not a validation failure
#
# Usage:
#   ./scripts/ci/validate-skill-frontmatter.sh
#       Validate all SKILL.md under skills/.
#   ./scripts/ci/validate-skill-frontmatter.sh --self-test
#       Run schemas/fixtures/skill-frontmatter/{valid,invalid}/ as the
#       built-in positive/negative regression suite.
#   ./scripts/ci/validate-skill-frontmatter.sh --file <path>
#       Validate a single SKILL.md path.
#
# Honors NO_COLOR. Diagnostics are machine-readable: one finding per line,
# `path :: field :: rule :: reason`.

set -euo pipefail

# --- color / symbols ----------------------------------------------------
if [[ -n "${NO_COLOR:-}" || ! -t 1 ]]; then
  RED="" GREEN="" RESET=""
else
  RED=$'\033[0;31m' GREEN=$'\033[0;32m' RESET=$'\033[0m'
fi
SYM_OK="ok" SYM_FAIL="FAIL"

# --- prereqs ------------------------------------------------------------
need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "${RED}${SYM_FAIL}${RESET} prerequisite missing: $1" >&2
    exit 2
  }
}
need cue
need jq
need awk
need python3
python3 -c 'import yaml' 2>/dev/null || {
  echo "${RED}${SYM_FAIL}${RESET} prerequisite missing: python3 yaml module" >&2
  exit 2
}

# --- paths --------------------------------------------------------------
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SCHEMA="${REPO_ROOT}/schemas/skill.cue"
FIXTURE_VALID="${REPO_ROOT}/schemas/fixtures/skill-frontmatter/valid"
FIXTURE_INVALID="${REPO_ROOT}/schemas/fixtures/skill-frontmatter/invalid"
DEFAULT_ROOT="${REPO_ROOT}/skills"

[[ -f "$SCHEMA" ]] || {
  echo "${RED}${SYM_FAIL}${RESET} schema not found at: $SCHEMA" >&2
  exit 2
}

# --- args ---------------------------------------------------------------
mode="all"
single_file=""
while (($#)); do
  case "$1" in
    --self-test) mode="self-test"; shift;;
    --file)      mode="file"; single_file="$2"; shift 2;;
    -h|--help)
      awk '/^#!/ { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "$0"
      exit 0;;
    *)
      echo "${RED}${SYM_FAIL}${RESET} unknown argument: $1" >&2
      exit 2;;
  esac
done

# --- temp workspace -----------------------------------------------------
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- diagnostics --------------------------------------------------------
findings=0
emit_finding() {
  local path="$1" field="$2" rule="$3" reason="$4"
  printf "%s%s%s %s :: %s :: %s :: %s\n" \
    "$RED" "$SYM_FAIL" "$RESET" "$path" "$field" "$rule" "$reason"
  findings=$((findings + 1))
}

# --- per-skill validation ----------------------------------------------
validate_skill_file() {
  local file="$1"
  local rel="${file#"$REPO_ROOT"/}"

  # 1. Extract frontmatter: file starts with `---`, second `---` closes.
  local first_line
  first_line=$(head -n 1 "$file" 2>/dev/null || true)
  if [[ "$first_line" != "---" ]]; then
    emit_finding "$rel" "(frontmatter)" "extract" \
      "no opening '---' delimiter on line 1"
    return 1
  fi

  local fm
  fm=$(awk '/^---$/ { n++; if (n==1) next; if (n==2) exit } n==1 { print }' "$file")
  if [[ -z "$fm" ]]; then
    emit_finding "$rel" "(frontmatter)" "extract" \
      "frontmatter block is empty or has no closing '---'"
    return 1
  fi

  local yaml_path="${TMP}/skill.yaml"
  printf '%s\n' "$fm" > "$yaml_path"

  # 2. cue vet against the base #Skill definition.
  local cue_err
  if ! cue_err=$(cd "$REPO_ROOT" && cue vet -d '#Skill' "$SCHEMA" "$yaml_path" 2>&1); then
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      [[ "$line" =~ ^[[:space:]] || "$line" == *"$yaml_path"* ]] && continue
      emit_finding "$rel" "(cue)" "schema" "$line"
    done <<<"$cue_err"
    return 1
  fi

  # 3. Export to JSON for the script-side checks.
  local json_path="${TMP}/skill.json"
  python3 -c '
import json, sys, yaml
with open(sys.argv[1]) as f:
    print(json.dumps(yaml.safe_load(f)))
' "$yaml_path" > "$json_path"

  # 4. Measurement skills: also vet the typed methodology definition and
  #    run the cross-file consistency checks. The methodology block key
  #    picks the definition: `self_measure` -> #SelfMeasure (deployed,
  #    bindings required), `cm_of_cms` -> #CMOfCMs (essence-only).
  local artifact_class
  artifact_class=$(jq -r '.artifact_class // ""' "$json_path")
  if [[ "$artifact_class" == "measurement" ]]; then
    local block cue_def
    if jq -e '.self_measure' "$json_path" >/dev/null; then
      block="self_measure" cue_def="#SelfMeasure"
    elif jq -e '.cm_of_cms' "$json_path" >/dev/null; then
      block="cm_of_cms" cue_def="#CMOfCMs"
    else
      emit_finding "$rel" "(methodology)" "block-present" \
        "measurement skill has neither a self_measure nor a cm_of_cms block"
      return 1
    fi
    if ! cue_err=$(cd "$REPO_ROOT" && cue vet -d "$cue_def" "$SCHEMA" "$yaml_path" 2>&1); then
      while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^[[:space:]] || "$line" == *"$yaml_path"* ]] && continue
        emit_finding "$rel" "(cue)" "methodology-schema" "$line"
      done <<<"$cue_err"
      return 1
    fi
    validate_measurement_cross_checks "$rel" "$json_path" "$block" || return 1
  fi

  printf "%s%s%s %s\n" "$GREEN" "$SYM_OK" "$RESET" "$rel"
  return 0
}

# --- measurement cross-file checks ---------------------------------------
# The skill declares what the engine computes and what the LLM estimates.
# These checks pin the declaration to the sources of truth so the skill
# cannot drift from what actually runs. $3 is the methodology block key
# (`self_measure` or `cm_of_cms`); binding paths (render/ledger) are
# checked only when the block declares them — they are optional in the
# core contract and required only for deployed methodologies.
validate_measurement_cross_checks() {
  local rel="$1" json_path="$2" block="$3"
  local ok=0

  # 4a. Declared paths must exist. Essence paths are unconditional;
  #     binding paths are checked when present.
  local key path
  for key in \
    ".${block}.registry" \
    ".${block}.instruction" \
    ".${block}.mechanical.backend"
  do
    path=$(jq -r "$key // \"\"" "$json_path")
    if [[ -z "$path" ]]; then
      emit_finding "$rel" "$key" "path-declared" "field is empty"
      ok=1
    elif [[ ! -e "$REPO_ROOT/$path" ]]; then
      emit_finding "$rel" "$key" "path-exists" "declared path not found: $path"
      ok=1
    fi
  done
  for key in \
    ".${block}.consistency.script" \
    ".${block}.render.command_out" \
    ".${block}.render.workflow_out" \
    ".${block}.ledger.path" \
    ".${block}.ledger.script" \
    ".${block}.ledger.workflow_out"
  do
    path=$(jq -r "$key // \"\"" "$json_path")
    if [[ -n "$path" && ! -e "$REPO_ROOT/$path" ]]; then
      emit_finding "$rel" "$key" "path-exists" "declared path not found: $path"
      ok=1
    fi
  done

  # 4b. Every declared target must resolve in the registry.
  local registry
  registry=$(jq -r ".${block}.registry // \"\"" "$json_path")
  if [[ -n "$registry" && -f "$REPO_ROOT/$registry" ]]; then
    local target
    while IFS= read -r target; do
      if ! grep -q "^\[target\.${target}\]" "$REPO_ROOT/$registry"; then
        emit_finding "$rel" "${block}.targets" "target-registered" \
          "target '$target' not found in $registry"
        ok=1
      fi
    done < <(jq -r ".${block}.targets[]" "$json_path")
  fi

  # 4c. Every declared mechanical signal code must exist in the backend
  #     source (the engine is the source of truth for what is computed).
  local backend
  backend=$(jq -r ".${block}.mechanical.backend // \"\"" "$json_path")
  if [[ -n "$backend" && -f "$REPO_ROOT/$backend" ]]; then
    local sig
    while IFS= read -r sig; do
      if ! grep -q "\"$sig\"" "$REPO_ROOT/$backend"; then
        emit_finding "$rel" "${block}.mechanical.signals" "signal-in-engine" \
          "signal code '$sig' not found in $backend"
        ok=1
      fi
    done < <(jq -r ".${block}.mechanical.signals | (.alpha[], .beta[], .gamma[])" "$json_path")
  fi

  # 4d. Declared LLM estimate fields must equal EXACTLY the top-level keys
  #     of the scoring instruction's JSON output contract (its first fenced
  #     ```json block). Exact set comparison — not prose string presence —
  #     so a field mentioned in prose but absent from the contract fails,
  #     and a contract key missing from the declaration fails too.
  local instruction
  instruction=$(jq -r ".${block}.instruction // \"\"" "$json_path")
  if [[ -n "$instruction" && -f "$REPO_ROOT/$instruction" ]]; then
    local contract_diff
    if ! contract_diff=$(python3 - "$REPO_ROOT/$instruction" "$json_path" "$block" <<'PYEOF'
import json, re, sys

instruction_path, skill_json_path, block = sys.argv[1], sys.argv[2], sys.argv[3]
text = open(instruction_path).read()
m = re.search(r"```json\n(.*?)\n```", text, re.DOTALL)
if not m:
    print("no fenced ```json output contract block found in instruction")
    sys.exit(1)
try:
    contract_keys = set(json.loads(m.group(1)).keys())
except json.JSONDecodeError as e:
    print(f"output contract block is not valid JSON: {e}")
    sys.exit(1)
declared = set(json.load(open(skill_json_path))[block]["llm"]["estimates"])
missing_from_contract = sorted(declared - contract_keys)
missing_from_declaration = sorted(contract_keys - declared)
if missing_from_contract:
    print(f"declared but not in the output contract: {', '.join(missing_from_contract)}")
if missing_from_declaration:
    print(f"in the output contract but not declared: {', '.join(missing_from_declaration)}")
sys.exit(1 if (missing_from_contract or missing_from_declaration) else 0)
PYEOF
    ); then
      while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        emit_finding "$rel" "${block}.llm.estimates" "estimate-in-contract" "$line"
      done <<<"$contract_diff"
      ok=1
    fi
  fi

  return $ok
}

# --- run modes -----------------------------------------------------------
run_all() {
  local root="$1"
  local failed=0 count=0
  while IFS= read -r file; do
    count=$((count + 1))
    validate_skill_file "$file" || failed=1
  done < <(find "$root" -name 'SKILL.md' -type f | sort)
  if [[ $count -eq 0 ]]; then
    echo "${RED}${SYM_FAIL}${RESET} no SKILL.md files found under $root" >&2
    return 1
  fi
  return $failed
}

run_self_test() {
  local failed=0
  # Positive fixtures must pass.
  while IFS= read -r file; do
    if ! validate_skill_file "$file" >/dev/null; then
      emit_finding "${file#"$REPO_ROOT"/}" "(fixture)" "self-test" \
        "valid fixture failed validation"
      failed=1
    else
      printf "%s%s%s fixture(valid) %s\n" "$GREEN" "$SYM_OK" "$RESET" "${file#"$REPO_ROOT"/}"
    fi
  done < <(find "$FIXTURE_VALID" -name 'SKILL.md' -type f | sort)
  # Negative fixtures must fail, with the expected diagnostic substring.
  while IFS= read -r file; do
    local expect_file="${file%.md}.expect"
    local out
    if out=$(validate_skill_file "$file" 2>&1); then
      emit_finding "${file#"$REPO_ROOT"/}" "(fixture)" "self-test" \
        "invalid fixture unexpectedly passed"
      failed=1
    elif [[ -f "$expect_file" ]] && ! grep -qF "$(cat "$expect_file")" <<<"$out"; then
      emit_finding "${file#"$REPO_ROOT"/}" "(fixture)" "self-test" \
        "diagnostic did not contain expected substring: $(cat "$expect_file")"
      failed=1
    else
      printf "%s%s%s fixture(invalid) %s\n" "$GREEN" "$SYM_OK" "$RESET" "${file#"$REPO_ROOT"/}"
    fi
  done < <(find "$FIXTURE_INVALID" -name 'SKILL.md' -type f | sort)
  return $failed
}

case "$mode" in
  all)       run_all "$DEFAULT_ROOT" || exit 1;;
  file)      validate_skill_file "$single_file" || exit 1;;
  self-test) run_self_test || exit 1;;
esac

exit 0
