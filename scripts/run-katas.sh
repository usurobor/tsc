#!/usr/bin/env bash
# Run all defined katas. Gracefully exits 0 if no katas are defined.
# When katas/*/kata.toml files exist, this script will attempt to run them.
# Kata runner integration is provided by tsc #33.
set -euo pipefail

KATAS_DIR="katas"

if [ ! -d "$KATAS_DIR" ] || [ -z "$(ls -A "$KATAS_DIR" 2>/dev/null)" ]; then
  echo "kata-check: no katas defined (katas/ empty or missing) — skipping"
  echo "kata-check: kata framework will be wired in tsc #33"
  exit 0
fi

kata_count=0
fail_count=0
for toml in "$KATAS_DIR"/*/kata.toml; do
  [ -f "$toml" ] || continue
  id=$(basename "$(dirname "$toml")")
  echo "kata-check: running kata $id"
  if coh --kata "$id" --mode mechanical; then
    echo "kata-check: $id PASS"
    kata_count=$((kata_count + 1))
  else
    echo "kata-check: $id FAIL"
    fail_count=$((fail_count + 1))
  fi
done

if [ $kata_count -eq 0 ]; then
  echo "kata-check: no kata.toml files found in $KATAS_DIR/ — no katas to run"
  exit 0
fi

echo "kata-check: $kata_count kata(s) ran, $fail_count failed"
[ $fail_count -eq 0 ]
