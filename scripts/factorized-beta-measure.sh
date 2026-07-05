#!/usr/bin/env bash
# scripts/factorized-beta-measure.sh — run the FROZEN factorized-β
# experiment (docs/beta/governance/CONSISTENCY-FACTORIZATION-PREREG.md
# rev 4) for one held-out target (Sub-2 of #73, issue #75).
#
# Per target it:
#   1. emits the deterministic pre-witness inventory + the bounded
#      per-locus adjudication prompt (coh factorized-beta-inventory);
#   2. runs k factorized-β witnesses over that prompt (the LLM adjudicates
#      each resolved locus; it never emits a scalar);
#   3. measures the SAME-TREE free-witness scalar β baseline B_β (for A2 /
#      B4) by running k scalar witnesses over the existing SELF-MEASURE
#      prompt and taking the β field's max-pairwise Coh_consistency;
#   4. ingests/validates/aggregates the factorized responses into the
#      per-target measurement record (coh factorized-beta-target), carrying
#      B_β for the gate step.
#
# The witness CALL is delegated to:
#     "$WITNESS_CMD" "<prompt-file>" "<response-file.json>"
# CI supplies the credentialed Claude-CLI wrapper (auth routing +
# acceptEdits settings, mirroring .github/workflows/tsc-self-measure.yml);
# the engine steps here are deterministic and reviewable. Without
# WITNESS_CMD the script performs only the deterministic emit half (a
# credential-free smoke of the route).
#
# Environment:
#   COH_BIN      engine binary (else PATH `coh`, else the in-repo build)
#   WITNESS_CMD  witness runner: `<cmd> <prompt> <response>` (optional)
#   OUTPUT       artifact dir (default .tsc/fb)
#   K            samples per target (default 3)
#   REGISTRY     target registry (default targets/registry.tsc)
#   INSTRUCTION  scalar witness instruction (default runtime/SELF-MEASURE.md)
#   ROOT         repo root (default .)
#
# Usage: scripts/factorized-beta-measure.sh <target>
# Exit: 0 on completion (a refused/absent witness sample is DATA, recorded
#       in the measurement record — not a pipeline failure); 2 on a
#       precondition error (no target, no engine binary).

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

OUTPUT="${OUTPUT:-.tsc/fb}"
K="${K:-3}"
REGISTRY="${REGISTRY:-targets/registry.tsc}"
INSTRUCTION="${INSTRUCTION:-runtime/SELF-MEASURE.md}"
ROOT="${ROOT:-.}"

TARGET=""
case "${1:-}" in
  ""|-h|--help)
    sed -n '/^# Usage:/,/precondition/p' "$0" | sed 's/^# \{0,1\}//' >&2
    exit 2 ;;
  --target) TARGET="${2:-}" ;;
  *) TARGET="$1" ;;
esac
[ -n "$TARGET" ] || { echo "factorized-beta-measure: no target" >&2; exit 2; }

resolve_coh() {
  if [ -n "${COH_BIN:-}" ]; then echo "$COH_BIN"; return; fi
  if command -v coh >/dev/null 2>&1; then echo "coh"; return; fi
  local build="engine/ocaml/_build/default/bin/main.exe"
  [ -x "$build" ] && { echo "$REPO_ROOT/$build"; return; }
  echo "factorized-beta-measure: no coh binary (set COH_BIN or dune build)" >&2
  exit 2
}
COH="$(resolve_coh)"

run() { echo "+ $*" >&2; "$@"; }

# Barrier applied to a spread delta: Coh = exp(-phi(d)), phi = d/(1-d),
# 0 at d>=1 (matches Coherence.coherence_link; used only for the scalar
# baseline, where the report gives the β spread not the Coh directly).
coh_from_delta() {
  awk -v d="$1" 'BEGIN { if (d < 0) d = 0; if (d >= 1) { print 0; exit }
                        printf "%.6f", exp(-(d/(1-d))) }'
}

# ── 1. Deterministic pre-witness inventory + adjudication prompt ──────────────
run "$COH" factorized-beta-inventory --target "$TARGET" \
  --registry "$REGISTRY" --root "$ROOT" --output "$OUTPUT"

INV="$OUTPUT/inventory/$TARGET.json"
ELIGIBLE="$(jq -r '.eligible_loci // 0' "$INV" 2>/dev/null || echo 0)"
echo "factorized-beta-measure: $TARGET eligible_loci=$ELIGIBLE" >&2

if [ -z "${WITNESS_CMD:-}" ]; then
  echo "factorized-beta-measure: WITNESS_CMD unset — deterministic emit only \
(inventory + prompt); no measurement" >&2
  exit 0
fi

# ── 2. Factorized-β witnesses (k samples) ─────────────────────────────────────
# When E=0 no locus is LLM-eligible: no calls, A0 not applicable. The
# aggregate step still records the (sparse) inventory.
FRESP_ARGS=()
if [ "$ELIGIBLE" -gt 0 ]; then
  mkdir -p "$OUTPUT/response"
  for i in $(seq 1 "$K"); do
    r="$OUTPUT/response/$TARGET.r$i.json"
    rm -f "$r"
    run "$WITNESS_CMD" "$OUTPUT/prompt/$TARGET.md" "$r" || true
    [ -f "$r" ] && FRESP_ARGS+=(--response "$r")
  done
fi

# ── 3. Free-witness scalar β baseline B_β (same tree, before comparison) ──────
BASELINE_ARG=()
run "$COH" --target "$TARGET" --registry "$REGISTRY" \
  --instruction "$INSTRUCTION" --root "$ROOT" \
  --emit-prompt "$OUTPUT/scalar-prompt/$TARGET.md" || true

if [ -f "$OUTPUT/scalar-prompt/$TARGET.md" ]; then
  mkdir -p "$OUTPUT/scalar-response"
  VALID=()
  for i in $(seq 1 "$K"); do
    sr="$OUTPUT/scalar-response/$TARGET.r$i.json"
    rm -f "$sr"
    run "$WITNESS_CMD" "$OUTPUT/scalar-prompt/$TARGET.md" "$sr" || true
    # A scalar sample counts toward the baseline only if it passes the
    # full witness funnel (same rule the self-measure consistency uses).
    if [ -f "$sr" ] && "$COH" --mode hybrid --target "$TARGET" \
         --registry "$REGISTRY" --instruction "$INSTRUCTION" --root "$ROOT" \
         --llm-response "$sr" --output "$OUTPUT/scalar-validate" >/dev/null 2>&1; then
      VALID+=("$sr")
    fi
  done
  if [ "${#VALID[@]}" -ge 2 ]; then
    COH_BIN="$COH" scripts/cm-consistency.sh llm-spread "$TARGET" "${VALID[@]}" || true
    CREP=".tsc/cm/consistency/$TARGET.llm.json"
    if [ -f "$CREP" ]; then
      mkdir -p "$OUTPUT/baseline"
      cp "$CREP" "$OUTPUT/baseline/$TARGET.llm.json"
      BSPREAD="$(jq -r '.fields.beta.spread // empty' "$CREP" 2>/dev/null || true)"
      if [ -n "$BSPREAD" ]; then
        BLC="$(coh_from_delta "$BSPREAD")"
        BASELINE_ARG=(--baseline-beta-coh "$BLC")
        echo "factorized-beta-measure: $TARGET free-witness β baseline \
spread=$BSPREAD Coh=$BLC" >&2
      fi
    fi
  else
    echo "factorized-beta-measure: $TARGET fewer than 2 valid scalar samples \
— no β baseline recorded (A2 will miss for this target)" >&2
  fi
fi

# ── 4. Ingest / validate / aggregate the factorized responses ─────────────────
run "$COH" factorized-beta-target --target "$TARGET" \
  --registry "$REGISTRY" --root "$ROOT" --output "$OUTPUT" \
  --declared "$K" "${BASELINE_ARG[@]}" "${FRESP_ARGS[@]}"

echo "factorized-beta-measure: $TARGET done -> $OUTPUT/measure/$TARGET.json" >&2
