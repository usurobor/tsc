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

# The witness rides the Claude CLI directly (npm-pinned) rather than
# claude-code-action: the action rejects `push` events, and both rendered
# workflows fire on tag / VERSION / path pushes. The CLI is the narrower
# pipe anyway — one prompt in, tool permissions from a settings file, one
# JSON artifact out. Renderer authority: CLI version pin, settings
# encoding, step layout.
CLAUDE_CLI_VERSION = "2.1.199"

# The witness response path inside the matrix job (GitHub expression is
# substituted by the runner, not the shell).
witness_resp = output_root + "/response/${{ matrix.target }}.json"

# The LLM-consistency standing floor is doctrine owned by the 0th
# methodology (skills/cm-of-cms/SKILL.md, standing block) — read, never
# assumed.
with open(os.path.join(repo_root, "skills/cm-of-cms/SKILL.md")) as f:
    cm0 = yaml.safe_load(f.read().split("---\n", 2)[1])
llm_consistency_floor = cm0["cm_of_cms"]["standing"]["llm_consistency_floor"]


def consistency_standing_run(t_expr):
    """Run-block body for the per-target consistency + standing step,
    shared by the measurement workflow (matrix target) and the ledger
    workflow (literal target). Every extra sample is validated through
    the same witness funnel; the spread of validated samples maps
    through the barrier; the result is a STANDING gate, never a
    publishing gate."""
    ind = "          "
    return f"""{ind}T="{t_expr}"
{ind}BASE="{output_root}/response/$T"
{ind}COH="$PWD/engine/ocaml/_build/default/bin/main.exe"
{ind}valid=""
{ind}for r in "$BASE".r*.json; do
{ind}  [ -f "$r" ] || continue
{ind}  if "$COH" --mode hybrid --target "$T" \\
{ind}       --registry targets/registry.tsc --instruction runtime/SELF-MEASURE.md \\
{ind}       --root . --llm-response "$r" --output "{output_root}/validate" >/dev/null 2>&1; then
{ind}    valid="$valid $r"
{ind}  fi
{ind}done
{ind}n=$(echo $valid | wc -w)
{ind}coh_c="0"
{ind}if [ "$n" -ge 2 ]; then
{ind}  COH_BIN="$COH" scripts/cm-consistency.sh llm-spread "$T" $valid || true
{ind}  coh_c=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['coh_consistency'])" ".tsc/cm/consistency/$T.llm.json" 2>/dev/null || echo 0)
{ind}  cp ".tsc/cm/consistency/$T.llm.json" "{output_root}/consistency-$T.json" 2>/dev/null || true
{ind}fi
{ind}gate=$(python3 -c "import sys; print('passed' if float(sys.argv[1]) >= {llm_consistency_floor} else 'failed')" "$coh_c")
{ind}python3 -c "import json,sys; json.dump({{'standing_scope': 'house-authored-public-commons', 'admissibility': 'public-only', 'heldout_status': 'none', 'external_anchor_count': 0, 'llm_consistency_gate': sys.argv[4], 'llm_consistency_floor': {llm_consistency_floor}, 'coh_consistency': float(sys.argv[3]), 'validated_samples': int(sys.argv[2]), 'target': sys.argv[1]}}, open('{output_root}/standing-' + sys.argv[1] + '.json', 'w'), indent=2)" "$T" "$n" "$coh_c" "$gate"
{ind}echo \"consistency: $T k=$n Coh_consistency=$coh_c gate=$gate (standing gate, never a publishing gate)\""""

def cli_witness_run(prompt_text, k=1, resp=None):
    """Run-block body for a CLI witness step. Every emitted line sits at
    the run block's base indentation (10 spaces), so after YAML strips
    the block indent the heredoc delimiters land at column 0. With k>1
    the witness is sampled k times against the same frozen prompt
    (consistency protocol, cm-of-cms skill section 3): each sample is
    moved aside as .rN.json and the first sample is restored as the
    response the ingest step adjudicates."""
    ind = "          "
    prompt_block = "\n".join(
        (ind + line).rstrip() for line in prompt_text.rstrip("\n").split("\n")
    )
    if k > 1:
        claude_call = f"""{ind}RESP="{resp}"; BASE="${{RESP%.json}}"
{ind}for i in $(seq 1 {k}); do
{ind}  claude -p "$(cat "$RUNNER_TEMP/witness-prompt.md")" \\
{ind}    --settings "$RUNNER_TEMP/witness-settings.json" \\
{ind}    --permission-mode acceptEdits \\
{ind}    --max-turns 50 || true
{ind}  if [ -f "$RESP" ]; then mv "$RESP" "$BASE.r$i.json"; fi
{ind}done
{ind}# The first sample is the adjudicated response; all samples feed
{ind}# the consistency spread.
{ind}if [ -f "$BASE.r1.json" ]; then cp "$BASE.r1.json" "$RESP"; fi
{ind}ls -l "$(dirname "$RESP")" || true"""
    else:
        claude_call = f"""{ind}claude -p "$(cat "$RUNNER_TEMP/witness-prompt.md")" \\
{ind}  --settings "$RUNNER_TEMP/witness-settings.json" \\
{ind}  --permission-mode acceptEdits \\
{ind}  --max-turns 50"""
    return f"""{ind}npm install -g @anthropic-ai/claude-code@{CLAUDE_CLI_VERSION}
{ind}# The secret slot is named for the OAuth token, but route by shape:
{ind}# an sk-ant-api key belongs in ANTHROPIC_API_KEY. Never printed.
{ind}if [ "${{CLAUDE_CODE_OAUTH_TOKEN#sk-ant-api}}" != "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
{ind}  export ANTHROPIC_API_KEY="$CLAUDE_CODE_OAUTH_TOKEN"
{ind}  unset CLAUDE_CODE_OAUTH_TOKEN
{ind}fi
{ind}# Allow rules in both spellings (relative to cwd and filesystem-
{ind}# absolute) — the settings file lives in RUNNER_TEMP, and rule-path
{ind}# resolution has already denied the workspace write once. The
{ind}# acceptEdits permission mode is the load-bearing grant: file writes
{ind}# inside the workspace auto-accept, everything else stays denied,
{ind}# and the engine funnel enforces content and target downstream.
{ind}cat > "$RUNNER_TEMP/witness-settings.json" <<SETTINGS
{ind}{{
{ind}  "permissions": {{
{ind}    "allow": [
{ind}      "Read({output_root}/prompt/**)",
{ind}      "Write({output_root}/response/**)",
{ind}      "Read(//${{PWD#/}}/{output_root}/prompt/**)",
{ind}      "Write(//${{PWD#/}}/{output_root}/response/**)"
{ind}    ]
{ind}  }}
{ind}}}
{ind}SETTINGS
{ind}cat > "$RUNNER_TEMP/witness-prompt.md" <<'WITNESS_PROMPT'
{prompt_block}
{ind}WITNESS_PROMPT
{ind}# 50 turns: the repo bundle's emitted prompt runs to hundreds of
{ind}# files, and the Read tool pages large files — 16 turns starved the
{ind}# repo witness mid-read (run 3).
{claude_call}"""

matrix_consistency = consistency_standing_run("${{ matrix.target }}")

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
  # Measure on every branch: a measurement surface that only reads main
  # never sees the work while it can still be repaired. Firing on this
  # workflow's own file makes installation itself the first measurement
  # (same self-installation pattern as the ledger workflow).
  push:
    branches:
      - '**'
    paths:
      - 'spec/**'
      - 'engine/ocaml/**'
      - 'targets/**'
      - 'runtime/**'
      - 'skills/**'
      - '.github/workflows/tsc-self-measure.yml'
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

      - name: Estimate deltas and evidence (LLM witness — Claude CLI, k=3 samples)
        env:
          CLAUDE_CODE_OAUTH_TOKEN: ${{{{ secrets.{llm_secret} }}}}
        run: |
{cli_witness_run(prompt_body, k=3, resp=witness_resp)}

      - name: Validate and ingest witness response (deterministic)
        env:
          LLM_PROVIDER: claude-cli
          LLM_MODEL: claude-code-cli@{CLAUDE_CLI_VERSION}
        run: |
          COH_BIN="$PWD/engine/ocaml/_build/default/bin/main.exe" \\
            {command_out} --ingest ${{{{ matrix.target }}}} --output {output_root}

      # Consistency protocol, LLM arm (cm-of-cms skill section 3): every
      # extra sample is validated through the same witness funnel; the
      # spread of the validated samples maps through the barrier. The
      # result is a STANDING gate, not a publishing gate — a failing
      # spread never blocks the report, it scopes its standing.
      - name: Witness consistency (k=3 spread) and standing scope
        if: always()
        run: |
{matrix_consistency}
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

# Witness steps for the ledger job: per target, emit the prompt, run the
# Claude CLI witness, ingest through the engine funnel — each gated on
# the credential so a secretless repo degrades to a labeled mechanical
# row, never a failure. Skill authority: the ci_prompt; renderer
# authority: step layout and gating encoding.
def ledger_witness_steps():
    blocks = []
    for t in targets:
        # The job-level env already projects the {llm_secret} secret, and
        # the Claude CLI reads exactly that variable — no step env needed.
        blocks.append(f"""      - name: Emit witness prompt ({t})
        if: ${{{{ env.{llm_secret} != '' }}}}
        run: |
          COH_BIN="$PWD/engine/ocaml/_build/default/bin/main.exe" \\
            {command_out} --emit-prompt {t} --output {output_root}

      - name: Estimate deltas and evidence ({t} — Claude CLI witness, k=3 samples)
        if: ${{{{ env.{llm_secret} != '' }}}}
        # The ledger contract (skill section 6): mechanical is the
        # explicit, labeled fallback. A witness that cannot run (bad
        # credential, provider outage) must not leave the release
        # rowless — the step stays visibly red via the warning
        # annotation, and the row's Mode column says mechanical. The
        # ledger takes the SAME k=3 sampled route as the measurement
        # workflow: a release row is never a single-sample semantic
        # reading.
        continue-on-error: true
        run: |
{cli_witness_run(ci_prompt.replace("{target}", t), k=3, resp=f"{output_root}/response/{t}.json")}

      - name: Validate and ingest witness response ({t})
        if: ${{{{ env.{llm_secret} != '' }}}}
        continue-on-error: true
        env:
          LLM_PROVIDER: claude-cli
          LLM_MODEL: claude-code-cli@{CLAUDE_CLI_VERSION}
        run: |
          COH_BIN="$PWD/engine/ocaml/_build/default/bin/main.exe" \\
            {command_out} --ingest {t} --output {output_root}

      - name: Witness consistency ({t}, k=3 spread) and standing scope
        if: ${{{{ env.{llm_secret} != '' }}}}
        continue-on-error: true
        run: |
{consistency_standing_run(t)}""")
    return "\n\n".join(blocks)

ledger_witness = ledger_witness_steps()

ledger_workflow = f"""{header}
name: {ledger_name}

on:
  push:
    tags:
      - '[0-9]*'
      - 'v[0-9]*'
    # A version increment is the VERSION-bump commit; the tag follows.
    # Firing on the bump (and on this workflow's own installation) makes
    # the ledger record patch increments even when the tag arrives later
    # or from an environment that cannot push tags. The append is
    # idempotent, so overlapping triggers are no-ops.
    branches:
      - '**'
    paths:
      - 'VERSION'
      - '.github/workflows/tsc-coherence-ledger.yml'
  # Manual path: record (and, if missing, create) a release tag's row —
  # for recovery and backfill.
  workflow_dispatch:
    inputs:
      version:
        description: "Release version to record (e.g. 0.10.1)"
        required: true

permissions:
  contents: write

jobs:
  # One ledger row per version increment (patch releases included):
  # hybrid — mechanical backend + Claude CLI witness — when the
  # {llm_secret} secret is present; a labeled mechanical row when not.
  # Commits between releases do not write the ledger — per-run reports
  # are CI artifacts of the tsc-self-measure workflow instead.
  ledger:
    runs-on: ubuntu-22.04
    env:
      {llm_secret}: ${{{{ secrets.{llm_secret} }}}}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

{ledger_build_steps}

{ledger_witness}

      - name: Append ledger row and push
        run: |
          set -euo pipefail
          # Version resolution: explicit input > tag name > VERSION file.
          if [ -n "${{{{ github.event.inputs.version }}}}" ]; then
            version="${{{{ github.event.inputs.version }}}}"
          elif [ "${{{{ github.ref_type }}}}" = "tag" ]; then
            version="${{{{ github.ref_name }}}}"
          else
            version="$(tr -d '[:space:]' < VERSION)"
          fi
          version="${{version#v}}"
          # Materialize the release tag if it does not exist yet. (A
          # token-pushed tag deliberately does not cascade into other
          # workflows; releases are cut by pushing the tag directly.)
          if ! git rev-parse -q --verify "refs/tags/$version" >/dev/null \\
             && ! git rev-parse -q --verify "refs/tags/v$version" >/dev/null; then
            git tag "$version" "$GITHUB_SHA"
            git push origin "refs/tags/$version"
            echo "created tag $version at $GITHUB_SHA"
          fi
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
          # The branch may have advanced while the engine built; rebase the
          # one ledger commit onto the current head before pushing.
          for attempt in 1 2 3; do
            git push origin "$branch" && exit 0
            git pull --rebase origin "$branch"
          done
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
