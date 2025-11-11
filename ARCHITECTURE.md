# TSC Self-Measurement Architecture v3.1.0

## Overview

TSC now uses a **structured report format** with JSON as the canonical source of truth and auto-generated markdown for human readability.

## Architecture

```
tsc self
    ↓
measure_self()
    ↓
  1. Compute C_Σ(TSC)
  2. Identify bottleneck (min axis)
  3. Declare next target
    ↓
write_report()
    ↓
  → docs/self-coherence-v3.1.0.json  (CANONICAL)
  → docs/self-coherence-v3.1.0.md    (GENERATED)
  → coherence_report.json            (backward compat)
    ↓
  git commit + push
```

## Next Cycle

```
tsc self (next time)
    ↓
gamma_axis()
    ↓
  1. Loads docs/self-coherence-v3.1.0.json
  2. Reads: bottleneck='alpha', target=0.85
  3. Measures current α_c
  4. γ_c = did we achieve target?
    ↓
measure_self()
    ↓
  → docs/self-coherence-v3.2.0.json
  → docs/self-coherence-v3.2.0.md
```

## JSON Schema

```json
{
  "version": "v3.1.0",
  "date": "2025-11-11T18:30:00Z",
  "verdict": "PASS" | "FAIL",
  
  "scores": {
    "alpha_c": float,
    "beta_c": float,
    "gamma_c": float,
    "C_sigma": float
  },
  
  "ci": {
    "C_sigma_lo": float,
    "C_sigma_hi": float,
    "n_boot": int
  },
  
  "bottleneck": {
    "axis": "alpha" | "beta" | "gamma",
    "score": float,
    "identified_at": "v3.1.0"
  },
  
  "roadmap": {
    "next_step": {
      "axis": "alpha" | "beta" | "gamma",
      "current_value": float,
      "target_value": float,
      "rationale": string
    }
  },
  
  "witnesses": {
    "S3_permutation": {...}
  },
  
  "axes_diag": {...},
  "params": {...},
  "provenance": {...}
}
```

## Key Changes

### 1. Bottleneck Identification (Automatic)

```python
scores_only = {'alpha': A.mean, 'beta': B.mean, 'gamma': G.mean}
bottleneck_axis = min(scores_only, key=scores_only.get)
```

The system automatically identifies which axis is the bottleneck.

### 2. Roadmap Declaration (Automatic)

```python
report['roadmap'] = {
    'next_step': {
        'axis': bottleneck_axis,
        'current_value': bottleneck_score,
        'target_value': 0.85,  # Default target
        'rationale': f"Improve {bottleneck_axis} axis to raise C_Σ"
    }
}
```

The system declares what it will work on next.

### 3. γ_c Self-Improvement Tracking (Simplified)

```python
def gamma_axis(..., current_scores):
    # Load previous JSON
    prev = json.loads(Path("docs/self-coherence-v3.0.0.json").read_text())
    
    # Extract declared intent
    bottleneck = prev['roadmap']['next_step']['axis']
    target = prev['roadmap']['next_step']['target_value']
    prev_value = prev['roadmap']['next_step']['current_value']
    
    # Check achievement
    curr_value = current_scores[f'{bottleneck}_c']
    
    if curr_value >= target:
        return 1.0  # Target achieved!
    else:
        progress = (curr_value - prev_value) / (target - prev_value)
        return max(0, min(1, progress))
```

No regex parsing! Just `json.loads()` and dictionary access.

### 4. Markdown Generation (Automatic)

```python
def generate_markdown_report(report: dict) -> str:
    """Generate human-readable MD from JSON."""
    # Extract values from JSON
    # Format as markdown
    # Return string
```

The markdown is **derived from** the JSON, never the other way around.

## Benefits

### 1. No Parsing Errors

- JSON is machine-readable
- No regex fragility
- Schema validation possible

### 2. Deterministic

- Same input → same output
- Reproducible measurements
- Clear format specification

### 3. Versionable

- JSON schema can evolve
- Old reports still readable
- Migration path clear

### 4. Queryable

- Tools can extract specific fields
- No need to parse markdown
- Easy to build tooling around

### 5. Human-Friendly

- Markdown still generated for docs
- Humans get nice formatting
- But machines use JSON

## Workflow

### Developer Workflow

```bash
# Run measurement
tsc self

# Output:
# ✅ Written: docs/self-coherence-v3.1.0.json
# ✅ Written: docs/self-coherence-v3.1.0.md

# Review human-readable report
cat docs/self-coherence-v3.1.0.md

# Commit both files
git add docs/self-coherence-v3.1.0.*
git commit -m "docs: add v3.1.0 self-coherence measurement"
git push
```

### CI/CD Integration

```bash
# In CI pipeline
tsc self --out report.json

# Parse JSON for decisions
verdict=$(jq -r '.verdict' report.json)
if [ "$verdict" = "PASS" ]; then
  echo "✅ Self-coherent"
  exit 0
else
  echo "❌ Not yet coherent"
  exit 1
fi
```

### Tooling Examples

```python
# Load latest report
import json
from pathlib import Path

reports = sorted(Path("docs").glob("self-coherence-v*.json"), reverse=True)
latest = json.loads(reports[0].read_text())

# Query specific fields
print(f"C_Σ = {latest['scores']['C_sigma']:.3f}")
print(f"Bottleneck: {latest['bottleneck']['axis']}")
print(f"Next target: {latest['roadmap']['next_step']['target_value']}")

# Track progress over time
all_reports = [json.loads(p.read_text()) for p in reports]
C_history = [r['scores']['C_sigma'] for r in all_reports]
print(f"Progress: {C_history}")
```

## Migration

### From v2.x to v3.1.0

Old v2.x reports (markdown-only) will still work:

- γ_c will return neutral 0.5 if no JSON found
- System will start tracking from v3.1.0 forward
- No breaking changes for existing workflows

### Future Schema Changes

If we need to change the JSON schema:

```json
{
  "version": "v4.0.0",
  "schema_version": "2.0",  // Add schema version
  ...
}
```

Then tools can handle multiple schema versions.

## Example Files

See:

- `example-self-coherence-v3.1.0.json` - What JSON looks like
- `example-self-coherence-v3.1.0.md` - What generated MD looks like

## Summary

**Before (v2.x):**

- Markdown only
- Regex parsing
- Fragile
- Hard to query

**After (v3.1.0):**

- JSON canonical
- Markdown generated
- Robust
- Easy to query
- Clean γ_c implementation

The ouroboros is complete: TSC measures itself, declares what it will fix, fixes it, and verifies the fix—all tracked in structured, machine-readable reports.
