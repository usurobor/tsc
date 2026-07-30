#!/usr/bin/env bash
# scripts/ci/self-measure-smoke.sh — end-to-end smoke for the
# self-measurement surfaces declared by src/skills/self-measure/SKILL.md.
#
# Failure class this guards: the rendered command or the external witness
# route (emit-prompt -> witness response -> ingest) regressing silently.
# The LLM CI job is gated off by default, so without this smoke the
# external route has no always-on proof. Consumer: CI (ci.yml
# self-measure-smoke job) and anyone touching src/engine/ocaml/bin/main.ml,
# scripts/coh-self, or the skill.
#
# Proves, with a built engine and no credentials:
#   1. mechanical self-measurement produces per-target + cross-target reports
#   2. --emit-prompt writes the canonical prompt (instruction + bundle)
#   3. --ingest accepts a contract-valid witness response (hybrid report)
#   4. --ingest refuses a contract-invalid response (validation-failure
#      artifact, no report) — negative space is mandatory
#
# Usage: scripts/ci/self-measure-smoke.sh [path-to-coh-binary]
#   Default binary: src/engine/ocaml/_build/default/bin/main.exe

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

COH="${1:-src/engine/ocaml/_build/default/bin/main.exe}"
[[ -x "$COH" ]] || { echo "self-measure-smoke: engine binary not found at $COH" >&2; exit 2; }
export COH_BIN="$REPO_ROOT/$COH"
[[ -x "$COH_BIN" ]] || export COH_BIN="$COH"

OUT="$(mktemp -d)"
trap 'rm -rf "$OUT"' EXIT

fail() { echo "self-measure-smoke: FAIL: $*" >&2; exit 1; }

# 1. Mechanical run — one report per target + one cross-target report.
scripts/coh-self --mode mechanical --output "$OUT" >/dev/null 2>&1 \
  || fail "mechanical self-measurement exited non-zero"
for t in spec engine repo cross-target; do
  ls "$OUT"/tsc-"$t"-*.json >/dev/null 2>&1 || fail "missing $t report in $OUT"
done
echo "ok: mechanical run (spec, engine, repo, cross-target)"

# 2. Emit the witness prompt for spec — must start with the instruction
#    and contain the hashed bundle.
scripts/coh-self --emit-prompt spec --output "$OUT" >/dev/null 2>&1 \
  || fail "--emit-prompt spec exited non-zero"
[[ -s "$OUT/prompt/spec.md" ]] || fail "prompt file not written"
head -1 "$OUT/prompt/spec.md" | grep -q "Self-Measure" || fail "prompt does not start with the scoring instruction"
grep -q "FILE: spec/tsc-core.md" "$OUT/prompt/spec.md" || fail "prompt bundle missing spec/tsc-core.md"
echo "ok: emit-prompt (instruction + bundle present)"

# 3. Ingest a contract-valid witness response — hybrid report rendered.
#    Fresh output dir: report filenames are timestamped, so phase isolation
#    beats counting files.
OUT_VALID="$(mktemp -d)"
trap 'rm -rf "$OUT" "$OUT_VALID" "${OUT_INVALID:-}"' EXIT
mkdir -p "$OUT_VALID/response"
cp src/skills/self-measure/fixtures/witness-response-valid.json "$OUT_VALID/response/spec.json"
scripts/coh-self --ingest spec --output "$OUT_VALID" >/dev/null 2>&1 \
  || fail "--ingest spec (valid response) exited non-zero"
report=$(ls "$OUT_VALID"/tsc-spec-*.json 2>/dev/null | grep -v raw || true)
[[ -n "$report" ]] || fail "valid ingest produced no report"
grep -q '"mode": "hybrid"' $report || fail "ingested report is not hybrid"
echo "ok: ingest valid witness response (hybrid report)"

# 4. Ingest every invalid witness fixture — each must refuse with a
#    validation-failure artifact classified at the expected stage, and
#    render no report. Fixtures cover the funnel: prose, fenced JSON,
#    missing base fields, computed coherence, wrong target, bad deltas.
OUT_INVALID=""
for fixture in src/skills/self-measure/fixtures/invalid/*.json; do
  case_name=$(basename "$fixture" .json)
  expect_stage=$(cat "${fixture%.json}.expect")
  OUT_INVALID="$(mktemp -d)"
  mkdir -p "$OUT_INVALID/response"
  cp "$fixture" "$OUT_INVALID/response/spec.json"
  if scripts/coh-self --ingest spec --output "$OUT_INVALID" >/dev/null 2>&1; then
    fail "invalid witness response accepted: $case_name"
  fi
  artifact=$(ls "$OUT_INVALID"/tsc-spec-*-validation-failure.json 2>/dev/null | head -1)
  [[ -n "$artifact" ]] || fail "no validation-failure artifact: $case_name"
  stage=$(jq -r '.stage' "$artifact")
  [[ "$stage" == "$expect_stage" ]] \
    || fail "$case_name: stage '$stage' != expected '$expect_stage'"
  if ls "$OUT_INVALID"/tsc-spec-*.json 2>/dev/null | grep -v raw | grep -qv validation-failure; then
    fail "invalid ingest rendered a report: $case_name"
  fi
  rm -rf "$OUT_INVALID"
  echo "ok: refused $case_name (stage=$stage, artifact, no report)"
done

# 5. Medoid-of-k adjudication election (v3.2.3) — the rules live in the
#    engine (lib/witness_medoid.ml, pinned by test_consistency.ml); here
#    the CLI surface is exercised: outlier loses, election is visible.
MEDOID_DIR="$(mktemp -d)"
for n in 1 2 3; do
  a=0.9; [[ "$n" == 1 ]] && a=0.1
  jq -n --argjson a "$a" '{alpha:$a, beta:0.5, gamma:0.5,
    delta_alpha_beta:0.1, delta_beta_gamma:0.1, delta_gamma_alpha:0.1,
    confidence:0.8}' > "$MEDOID_DIR/r$n.json"
done
picked="$("$COH_BIN" witness-medoid "$MEDOID_DIR"/r1.json "$MEDOID_DIR"/r2.json "$MEDOID_DIR"/r3.json)"
[[ "$picked" == "$MEDOID_DIR/r2.json" ]] \
  || fail "witness-medoid CLI: expected r2 (outlier loses), got $picked"
rm -rf "$MEDOID_DIR"
echo "ok: witness-medoid election (engine CLI)"

# 5b. Funnel-valid medoid election (post-loop Issue 1): with --target,
#     a NUMERICALLY complete but funnel-invalid sample must never be
#     adjudicated, and zero funnel-valid samples must exit 2 (the
#     workflow then records the no-valid-samples artifact instead of
#     hard-failing ingest on a sample the funnel already refused).
VALID_DIR="$(mktemp -d)"
cp src/skills/self-measure/fixtures/witness-response-valid.json "$VALID_DIR/v1.json"
cp src/skills/self-measure/fixtures/witness-response-valid.json "$VALID_DIR/v2.json"
cp src/skills/self-measure/fixtures/invalid/cards-duplicate-id.json "$VALID_DIR/bad.json"
# Positive: invalid sample listed FIRST still loses; a valid sample is
# elected (tie between identical valids breaks earliest).
picked="$("$COH_BIN" witness-medoid --target spec \
  "$VALID_DIR"/bad.json "$VALID_DIR"/v1.json "$VALID_DIR"/v2.json)"
[[ "$picked" == "$VALID_DIR/v1.json" || "$picked" == "$VALID_DIR/v2.json" ]] \
  || fail "witness-medoid --target: funnel-invalid sample elected: $picked"
# Negative: zero funnel-valid samples -> exit 2, nothing on stdout.
if picked="$("$COH_BIN" witness-medoid --target spec "$VALID_DIR"/bad.json 2>/dev/null)"; then
  fail "witness-medoid --target: zero-valid case succeeded with: $picked"
fi
rm -rf "$VALID_DIR"
echo "ok: witness-medoid funnel-valid election (invalid never adjudicated, zero-valid exits 2)"

# 6. Source-of-truth guard (Issue A / F1): the consistency module must
#    route the barrier through Coherence.phi, never define it locally.
#    The k=5 pass caught exactly this regression once; grep keeps it dead.
if grep -nE '1\.0 -\. delta|1\. -\. delta' src/engine/ocaml/lib/consistency.ml; then
  fail "consistency.ml re-implements the barrier locally (must route through Coherence.phi)"
fi
echo "ok: consistency barrier routed through Coherence (no local duplicate)"

# 7. Error-string hygiene guard (post-loop Issue 2): refusal messages
#    are an operator-visible surface; a multi-space run baked inside a
#    single-line string literal is an editing artifact (an engine
#    witness found three in the v3.2.4 card errors). Multi-line string
#    continuations (backslash-newline) are fine — OCaml eats the
#    continuation whitespace — so only single-line literals are checked.
if grep -nE '"[^"]*[^ "]  +[^ "][^"]*"' src/engine/ocaml/lib/response_schema.ml; then
  fail "response_schema.ml: multi-space run inside a string literal (editing artifact)"
fi
echo "ok: response_schema error strings carry no baked multi-space runs"

echo "self-measure-smoke: pass"
