#!/usr/bin/env bash
# scripts/render-self-measure.sh — render the self-measurement skill into
# its substrate artifacts.
#
# Consumes skills/self-measure/SKILL.md (frontmatter `self_measure:` block,
# validated by schemas/skill.cue #SelfMeasure) and materializes:
#
#   - scripts/coh-self                          the local command
#                                               (`coh self` dispatches to it)
#   - .github/workflows/tsc-self-measure.yml    the CI surface
#
# Authority split (pattern imported from cnos cn-install-wake):
# - Skill authority: what self-measurement IS — targets, registry,
#   instruction, output root, modes, the LLM delegation prompt and its
#   constraints, CI gating intent.
# - Renderer authority (this script): substrate encoding only — YAML
#   structure, trigger encoding, action versions, runner image,
#   secret-name bindings, tool-permission encoding, step layout,
#   shell-script skeleton.
#
# The render is deterministic: identical skill -> byte-identical output.
# Writes are idempotent (no-op when bytes match).
#
# Usage:
#   scripts/render-self-measure.sh            render both artifacts
#   scripts/render-self-measure.sh --check    render to temp and diff against
#                                             the committed artifacts; exit 1
#                                             on drift (CI byte-identity gate)
#
# Exit codes:
#   0  rendered (or --check clean)
#   1  --check found drift between skill and committed artifacts
#   2  precondition/schema failure (missing skill, missing fields, no python3)

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SKILL="${REPO_ROOT}/skills/self-measure/SKILL.md"

command -v python3 >/dev/null 2>&1 || { echo "render-self-measure: python3 missing" >&2; exit 2; }
python3 -c 'import yaml' 2>/dev/null || { echo "render-self-measure: python3 yaml module missing" >&2; exit 2; }
[[ -f "$SKILL" ]] || { echo "render-self-measure: skill not found: $SKILL" >&2; exit 2; }

check=0
[[ "${1:-}" == "--check" ]] && check=1

python3 - "$SKILL" "$REPO_ROOT" "$check" <<'PYEOF'
import sys, yaml, os, tempfile, filecmp

skill_path, repo_root, check = sys.argv[1], sys.argv[2], sys.argv[3] == "1"

# --- extract frontmatter -------------------------------------------------
with open(skill_path) as f:
    text = f.read()
parts = text.split("---\n", 2)
if len(parts) < 3 or parts[0].strip():
    print("render-self-measure: malformed frontmatter", file=sys.stderr)
    sys.exit(2)
fm = yaml.safe_load(parts[1])

sm = fm.get("self_measure")
if not isinstance(sm, dict):
    print("render-self-measure: missing self_measure block", file=sys.stderr)
    sys.exit(2)

def req(d, key, ctx="self_measure"):
    cur = d
    for k in key.split("."):
        if not isinstance(cur, dict) or k not in cur:
            print(f"render-self-measure: missing required field {ctx}.{key}", file=sys.stderr)
            sys.exit(2)
        cur = cur[k]
    return cur

command       = req(sm, "command")
registry      = req(sm, "registry")
targets       = req(sm, "targets")
cross_target  = req(sm, "cross_target")
instruction   = req(sm, "instruction")
output_root   = req(sm, "output_root")
default_mode  = req(sm, "default_mode")
ci_prompt     = req(sm, "llm.ci_prompt")
command_out   = req(sm, "render.command_out")
workflow_out  = req(sm, "render.workflow_out")
llm_secret    = req(sm, "ci.llm_secret")
perm_intent   = req(sm, "ci.permission_intent")
ledger_path   = req(sm, "ledger.path")
ledger_script = req(sm, "ledger.script")
ledger_out    = req(sm, "ledger.workflow_out")

if not targets:
    print("render-self-measure: self_measure.targets is empty", file=sys.stderr)
    sys.exit(2)

header = (
    "# DO NOT EDIT. Rendered by `scripts/render-self-measure.sh` from:\n"
    "#   source: skills/self-measure/SKILL.md\n"
    "# Schema:  tsc.self-measure.v1 (schemas/skill.cue #SelfMeasure)\n"
    "#\n"
    "# Authority split: the skill owns the measurement contract (targets,\n"
    "# modes, LLM delegation + constraints); this renderer owns substrate\n"
    "# encoding (triggers / permissions / action versions / secret-name\n"
    "# bindings / step layout). Edit the skill, re-render, commit both.\n"
)

# --- render coh-self ------------------------------------------------------
# Substrate: POSIX sh skeleton. Skill data: targets, registry, instruction,
# output root, default mode, command name.
targets_sp = " ".join(targets)

coh_self = f"""#!/bin/sh
{header}#
# {command} — TSC self-measurement command (invoked as `coh self`).
#
# Usage:
#   {command} [--mode mechanical|llm|hybrid|auto] [--require-llm]
#             [--output DIR] [--root DIR]
#   {command} --emit-prompt <target> [--output DIR] [--root DIR]
#   {command} --ingest <target> [--output DIR] [--root DIR]
#
# Default run: measure each named target ({", ".join(targets)}) in the given
# mode (default: {default_mode} — hybrid when LLM credentials are present,
# mechanical otherwise; every report's `mode` field states which backend
# produced it). --require-llm forces the semantic path: it refuses to run
# at all when no LLM credentials are configured, instead of degrading to
# mechanical. --emit-prompt / --ingest are the two deterministic halves of
# the external witness route (skills/self-measure/SKILL.md section 5).
set -eu

TARGETS="{targets_sp}"
REGISTRY="{registry}"
INSTRUCTION="{instruction}"
OUTPUT="{output_root}"
MODE="{default_mode}"
ROOT="."
EMIT=""
INGEST=""
REQUIRE_LLM=0

usage() {{ sed -n '/^# Usage:/,/^set -eu/p' "$0" | sed '$d' | sed 's/^# \\{{0,1\\}}//'; }}

while [ $# -gt 0 ]; do
  case "$1" in
    --mode)        MODE="$2"; shift 2 ;;
    --require-llm) REQUIRE_LLM=1; shift ;;
    --output)      OUTPUT="$2"; shift 2 ;;
    --root)        ROOT="$2"; shift 2 ;;
    --emit-prompt) EMIT="$2"; shift 2 ;;
    --ingest)      INGEST="$2"; shift 2 ;;
    -h|--help)     usage; exit 0 ;;
    *) echo "{command}: unknown argument: $1" >&2; usage >&2; exit 1 ;;
  esac
done

if [ "$REQUIRE_LLM" = 1 ]; then
  # Loud refusal, never a silent mechanical downgrade.
  if [ -z "${{LLM_API_KEY:-}}" ]; then
    echo "{command}: --require-llm but no LLM credentials configured" >&2
    echo "  set LLM_PROVIDER / LLM_MODEL / LLM_API_KEY (or use the CI witness route)" >&2
    exit 2
  fi
  case "$MODE" in
    mechanical)
      echo "{command}: --require-llm conflicts with --mode mechanical" >&2
      exit 2 ;;
    auto) MODE="hybrid" ;;
  esac
fi

# Resolve the engine binary: COH_BIN override, sibling of this script,
# PATH, then the in-repo dune build output.
resolve_coh() {{
  if [ -n "${{COH_BIN:-}}" ]; then echo "$COH_BIN"; return; fi
  self_dir=$(dirname "$0")
  if [ -x "$self_dir/coh" ]; then echo "$self_dir/coh"; return; fi
  if command -v coh >/dev/null 2>&1; then echo "coh"; return; fi
  build="$ROOT/engine/ocaml/_build/default/bin/main.exe"
  if [ -x "$build" ]; then echo "$build"; return; fi
  echo "{command}: cannot find the coh engine binary (set COH_BIN, install coh, or dune build)" >&2
  exit 2
}}
COH=$(resolve_coh)

run() {{ echo "+ $*" >&2; "$@"; }}

if [ -n "$EMIT" ]; then
  mkdir -p "$OUTPUT/prompt"
  run "$COH" --target "$EMIT" \\
    --registry "$REGISTRY" --instruction "$INSTRUCTION" --root "$ROOT" \\
    --emit-prompt "$OUTPUT/prompt/$EMIT.md"
  exit 0
fi

if [ -n "$INGEST" ]; then
  resp="$OUTPUT/response/$INGEST.json"
  [ -f "$resp" ] || {{ echo "{command}: witness response not found: $resp" >&2; exit 2; }}
  run "$COH" --mode hybrid --target "$INGEST" \\
    --registry "$REGISTRY" --instruction "$INSTRUCTION" --root "$ROOT" \\
    --llm-response "$resp" --output "$OUTPUT"
  exit 0
fi

status=0
for t in $TARGETS; do
  run "$COH" --mode "$MODE" --target "$t" \\
    --registry "$REGISTRY" --instruction "$INSTRUCTION" --root "$ROOT" \\
    --output "$OUTPUT" || status=1
done
"""

if cross_target:
    cross_flags = " ".join(f"--target {t}" for t in targets)
    coh_self += f"""
# Cross-target aggregate (spec/tsc-oper.md section 7.4) is mechanical-only.
run "$COH" --mode mechanical {cross_flags} \\
  --registry "$REGISTRY" --instruction "$INSTRUCTION" --root "$ROOT" \\
  --output "$OUTPUT" || status=1
"""

coh_self += """
echo "self-measurement reports in $OUTPUT/ (requested mode: $MODE;" \\
     "each report's 'mode' field states the backend that produced it;" \\
     "cross-target is always mechanical)"
exit $status
"""

# --- render workflow ------------------------------------------------------
def perm_line(intent):
    scope, level = intent.rsplit(".", 1)
    return f"  {scope.replace('_', '-')}: {level}"

perms = "\n".join(perm_line(p) for p in perm_intent)
workflow_name = os.path.basename(workflow_out).rsplit(".", 1)[0]
matrix = ", ".join(targets)

prompt_body = ci_prompt.replace("{target}", "${{ matrix.target }}")
prompt_indented = "\n".join(
    ("            " + line).rstrip() for line in prompt_body.rstrip("\n").split("\n")
)

build_steps = """      - uses: actions/checkout@v4

      - name: Install system depexts (libcurl for ezcurl)
        run: |
          sudo apt-get update
          sudo apt-get install -y --no-install-recommends libcurl4-openssl-dev pkg-config

      - name: Set up OCaml
        uses: ocaml/setup-ocaml@v3
        with:
          ocaml-compiler: "5.2"

      - name: Install dependencies
        working-directory: engine/ocaml
        run: opam install . --deps-only -y

      - name: Build engine
        working-directory: engine/ocaml
        run: opam exec -- dune build"""

workflow = f"""{header}
name: {workflow_name}

on:
  pull_request:
    paths:
      - 'spec/**'
      - 'engine/ocaml/**'
      - 'targets/**'
      - 'runtime/**'
      - 'skills/**'
  push:
    branches: [main]
    paths:
      - 'spec/**'
      - 'engine/ocaml/**'
      - 'targets/**'
      - 'runtime/**'
      - 'skills/**'
  workflow_dispatch:

permissions:
{perms}

jobs:
  # Fully mechanical: deterministic structural scoring. No credentials,
  # no gate, no LLM. skills/self-measure/SKILL.md section 3.
  mechanical:
    runs-on: ubuntu-22.04
    steps:
{build_steps}

      - name: Self-measure (mechanical, all targets + cross-target)
        run: |
          export PATH="$PWD/engine/ocaml/_build/default/bin:$PATH"
          COH_BIN="$PWD/engine/ocaml/_build/default/bin/main.exe" \\
            {command_out} --mode mechanical --output {output_root}

      - name: Summary
        if: always()
        run: |
          echo "## Self-measurement (mechanical)" >> $GITHUB_STEP_SUMMARY
          for f in {output_root}/*.json; do
            [ -f "$f" ] || continue
            echo "### $(basename "$f")" >> $GITHUB_STEP_SUMMARY
            echo '```json' >> $GITHUB_STEP_SUMMARY
            python3 -m json.tool "$f" >> $GITHUB_STEP_SUMMARY 2>/dev/null || cat "$f" >> $GITHUB_STEP_SUMMARY
            echo '```' >> $GITHUB_STEP_SUMMARY
          done

      - name: Upload reports
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: tsc-self-mechanical-${{{{ github.sha }}}}
          path: {output_root}/**
          # {output_root} is under a dot-directory; without this the
          # default (include-hidden-files: false) uploads nothing.
          include-hidden-files: true
          retention-days: 90
          # A missing mechanical report is a failure, not an ignorable
          # condition — this job is the always-on measurement surface.
          if-no-files-found: error

  # Gate: the witness is enabled by the PRESENCE of the {llm_secret}
  # secret — no separate toggle to drift out of sync with it. Secrets
  # cannot appear in job-level `if:` conditions, so a one-step job
  # projects presence into an output. Its log states the decision either
  # way (skills/self-measure/SKILL.md section 6).
  witness-gate:
    runs-on: ubuntu-22.04
    outputs:
      enabled: ${{{{ steps.check.outputs.enabled }}}}
    steps:
      - name: Check witness credential
        id: check
        env:
          {llm_secret}: ${{{{ secrets.{llm_secret} }}}}
        run: |
          if [ -n "${{{llm_secret}}}" ]; then
            echo "enabled=true" >> "$GITHUB_OUTPUT"
            echo "witness: {llm_secret} present — llm-witness runs"
          else
            echo "enabled=false" >> "$GITHUB_OUTPUT"
            echo "witness: {llm_secret} not configured — llm-witness unavailable (mechanical job still runs)"
          fi

  # LLM witness: the single delegated cognitive step, run per target via
  # the Claude CLI when the credential exists. The engine emits the exact
  # prompt, the model estimates deltas/components/evidence, the engine
  # validates and renders the hybrid report.
  # skills/self-measure/SKILL.md sections 4-5.
  llm-witness:
    needs: witness-gate
    if: ${{{{ needs.witness-gate.outputs.enabled == 'true' }}}}
    runs-on: ubuntu-22.04
    strategy:
      fail-fast: false
      matrix:
        target: [{matrix}]
    steps:
{build_steps}

      - name: Emit witness prompt (deterministic)
        run: |
          COH_BIN="$PWD/engine/ocaml/_build/default/bin/main.exe" \\
            {command_out} --emit-prompt ${{{{ matrix.target }}}} --output {output_root}

      - name: Estimate deltas and evidence (LLM witness — Claude CLI)
        uses: anthropics/claude-code-action@v1
        with:
          claude_code_oauth_token: ${{{{ secrets.{llm_secret} }}}}
          claude_args: "--max-turns 16"
          settings: |
            {{
              "permissions": {{
                "allow": [
                  "Read({output_root}/prompt/**)",
                  "Write({output_root}/response/**)"
                ]
              }}
            }}
          prompt: |
{prompt_indented}

      - name: Validate and ingest witness response (deterministic)
        env:
          LLM_PROVIDER: claude-cli
          LLM_MODEL: claude-code-action
        run: |
          COH_BIN="$PWD/engine/ocaml/_build/default/bin/main.exe" \\
            {command_out} --ingest ${{{{ matrix.target }}}} --output {output_root}

      - name: Summary
        if: always()
        run: |
          echo "## Self-measurement (hybrid, ${{{{ matrix.target }}}})" >> $GITHUB_STEP_SUMMARY
          for f in {output_root}/*.json; do
            [ -f "$f" ] || continue
            echo "### $(basename "$f")" >> $GITHUB_STEP_SUMMARY
            echo '```json' >> $GITHUB_STEP_SUMMARY
            python3 -m json.tool "$f" >> $GITHUB_STEP_SUMMARY 2>/dev/null || cat "$f" >> $GITHUB_STEP_SUMMARY
            echo '```' >> $GITHUB_STEP_SUMMARY
          done

      - name: Upload reports
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: tsc-self-llm-${{{{ matrix.target }}}}-${{{{ github.sha }}}}
          # Reports, witness responses, and validation-failure artifacts —
          # but never the emitted prompts (full bundle text).
          path: |
            {output_root}/**
            !{output_root}/prompt/**
          # {output_root} is under a dot-directory; without this the
          # default (include-hidden-files: false) uploads nothing.
          include-hidden-files: true
          retention-days: 90
          # If the witness ran, something durable must exist (report or
          # validation-failure artifact + raw response).
          if-no-files-found: error
"""

# --- render ledger workflow -------------------------------------------------
# Skill authority: ledger path, cadence (version tags), mechanical mode,
# script. Renderer authority: tag-pattern encoding, branch resolution,
# commit/push mechanics, action versions.
ledger_name = os.path.basename(ledger_out).rsplit(".", 1)[0]
# build_steps begins with a plain checkout; the ledger job needs
# fetch-depth 0 (branch resolution), so drop that first block here.
ledger_build_steps = build_steps.split("\n\n", 1)[1]

ledger_workflow = f"""{header}
name: {ledger_name}

on:
  push:
    tags:
      - '[0-9]*'
      - 'v[0-9]*'

permissions:
  contents: write

jobs:
  # One mechanical ledger row per release tag (patch increments included).
  # Commits between releases do not write the ledger — per-run reports are
  # CI artifacts of the tsc-self-measure workflow instead.
  ledger:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

{ledger_build_steps}

      - name: Append ledger row and push
        run: |
          set -euo pipefail
          version="${{{{ github.ref_name }}}}"
          version="${{version#v}}"
          # Commit to the branch that carries the tagged commit (prefer main).
          branches=$(git branch -r --contains "$GITHUB_SHA" --format='%(refname:short)' | sed 's|origin/||' | grep -v '^HEAD' || true)
          branch=$(echo "$branches" | grep -m1 -x main || echo "$branches" | head -1)
          if [ -z "$branch" ]; then
            echo "::error::no branch contains the tagged commit; cannot record ledger row"
            exit 1
          fi
          git config user.name  "tsc-coherence-ledger"
          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
          git checkout "$branch"
          COH_BIN="$PWD/engine/ocaml/_build/default/bin/main.exe" \\
            {ledger_script} append "$version"
          git add {ledger_path}
          git diff --cached --quiet && {{ echo "ledger unchanged"; exit 0; }}
          git commit -m "ledger: coherence row for $version [skip ci]"
          git push origin "$branch"

      - name: Summary
        if: always()
        run: |
          echo "## Coherence ledger" >> $GITHUB_STEP_SUMMARY
          echo '```' >> $GITHUB_STEP_SUMMARY
          tail -5 {ledger_path} >> $GITHUB_STEP_SUMMARY 2>/dev/null || echo "no ledger" >> $GITHUB_STEP_SUMMARY
          echo '```' >> $GITHUB_STEP_SUMMARY
"""

# --- write (idempotent) ---------------------------------------------------
outputs = {
    os.path.join(repo_root, command_out): (coh_self, 0o755),
    os.path.join(repo_root, workflow_out): (workflow, 0o644),
    os.path.join(repo_root, ledger_out): (ledger_workflow, 0o644),
}

drift = False
for path, (content, mode) in outputs.items():
    rel = os.path.relpath(path, repo_root)
    if check:
        current = open(path).read() if os.path.exists(path) else None
        if current != content:
            print(f"render-self-measure: DRIFT {rel} (re-run scripts/render-self-measure.sh)", file=sys.stderr)
            drift = True
        else:
            print(f"render-self-measure: clean {rel}")
        continue
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if os.path.exists(path) and open(path).read() == content:
        print(f"render-self-measure: unchanged {rel}")
    else:
        with open(path, "w") as f:
            f.write(content)
        print(f"render-self-measure: wrote {rel}")
    os.chmod(path, mode)

sys.exit(1 if drift else 0)
PYEOF
