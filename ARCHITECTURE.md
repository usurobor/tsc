# TSC Self-Measurement Architecture v3.1.0

## Overview

TSC measures its own coherence using three axes (α, β, γ) and tracks improvement over time. The system uses **JSON as canonical storage** with **auto-generated markdown history**.

**Key principle:** No hardcoded constants. The γ (gamma) axis reflects actual system health derived from observable state.

______________________________________________________________________

## Directory Structure

```
repo/
├── spec/                    # Files being measured
│   ├── tsc-core.md
│   ├── tsc-oper.md
│   ├── tsc-glossary.md
│   └── c-equiv.md
│
├── reference/python/
│   └── tsc_measure.py       # Measurement implementation
│
└── .tsc/                    # Hidden measurement directory
    ├── tsc-v2.1.0.json      # Historical measurements
    ├── tsc-v2.2.0.json
    ├── tsc-v3.1.0.json      # Current measurement
    └── README.md            # Auto-generated history (all versions)
```

**Why `.tsc/`?**

- Hidden directory (like `.git/`)
- TSC CLI can be used by any repo
- Self-contained measurement metadata
- Clean separation from source files

**Why `tsc-v*.json`?**

- Clear, concise naming
- "self-coherence" was redundant (TSC measuring TSC is implicit)
- Matches directory name

______________________________________________________________________

## Workflow

### Single Command Does Everything

```bash
tsc self
```

**Output:**

```
✅ Written: .tsc/tsc-v3.1.0.json
✅ Updated: .tsc/README.md
```

**What happens:**

1. Measures current α, β
1. Loads previous measurement from `.tsc/tsc-v3.0.0.json`
1. Computes γ based on achievement
1. Writes new measurement to `.tsc/tsc-v3.1.0.json`
1. Auto-generates `.tsc/README.md` from all JSON files

**One command. Everything done.** ✅

______________________________________________________________________

## The Three Axes

### α (Alpha) - Pattern Coherence

**Measures:** Consistency between content and structure

**How:**

1. Extract content tokens (words)
1. Extract structure elements (headers, bullets, definitions)
1. Compare using cosine similarity + Jensen-Shannon divergence
1. Score: `α = exp(-λ × distance)`

**Interpretation:**

- **High (0.8+):** Headers match content, good organization
- **Low (0.3):** Mismatch between structure and actual content

**Improve by:**

- Align headers with section content
- Use consistent terminology
- Add structure that mirrors content

______________________________________________________________________

### β (Beta) - Relational Coherence

**Measures:** Quality of cross-references between specs

**How:**

1. Extract terms from glossary (or bold terms)
1. Find explicit cross-references: `"see X"`, `"cf. X"`
1. Create two embeddings:
   - Degree distribution (connection patterns)
   - Reference counts (how often terms are explicitly linked)
1. Compare embeddings
1. Score: `β = exp(-λ × distance)`

**Interpretation:**

- **High (0.8+):** Well-connected specs, good cross-referencing
- **Low (0.06):** Isolated specs, missing links

**Improve by:**

- Add explicit cross-references: `"(see coherence in tsc-glossary)"`
- Use `"cf. witness"` patterns
- Link glossary terms throughout specs

______________________________________________________________________

### γ (Gamma) - Generative Process Health

**Measures:** Health of the process that generates specs

**Key insight:** γ is not a property of the specs themselves, but of the **generative process** that creates them.

**Principled Formula (No Hardcoded Constants):**

```python
# Baseline: Current health from outputs
baseline_health = sqrt(α × β)

if achieved_target:
    γ = 1.0  # Process proved it can self-improve
else:
    # Health = baseline + (distance to full health) × progress
    progress = (actual - start) / (target - start)
    γ = baseline_health + (1.0 - baseline_health) × progress
```

**Why this works:**

- `sqrt(α × β)` = current capacity of the generative process
- Healthy process (high α, β) → high baseline → misses hurt less
- Unhealthy process (low α, β) → low baseline → misses compound
- Achievement always leads to γ=1.0 (proof of health)

**Example:**

```python
# v2.2.0: Failed to improve β
α = 0.306, β = 0.061
baseline = sqrt(0.306 × 0.061) = 0.136
target: β 0.061 → 0.361
actual: β = 0.061 (no change)
progress = 0.0
γ = 0.136 + (1.0 - 0.136) × 0.0 = 0.136
# "Process is 13.6% healthy, failed to improve"

# v3.1.0: Achieved target
α = 0.282, β = 0.511
baseline = sqrt(0.282 × 0.511) = 0.380
target: β 0.061 → 0.361
actual: β = 0.511 (exceeded!)
achieved = True
γ = 1.0
# "Process proved it works!"
```

**Interpretation:**

- **γ = 1.0:** Process healthy, achieved improvement target
- **γ = 0.4:** Process struggling, made some progress
- **γ = baseline:** Process stuck, no improvement

______________________________________________________________________

## JSON Structure

### Top-Level Schema

```json
{
  "version": "v3.1.0",
  "date": "2025-11-11T18:30:00Z",
  "verdict": "PASS" | "FAIL",
  
  "current": {
    "scores": {...},
    "ci": {...},
    "bottleneck": {...}
  },
  
  "roadmap": {
    "next_target": {...}
  },
  
  "historical": {
    "previous_version": "v3.0.0",
    "previous_scores": {...},
    "achievement": {...},
    "changes": {...}
  },
  
  "witnesses": {...},
  "axes_diag": {...},
  "params": {...},
  "provenance": {...}
}
```

### Current State

```json
"current": {
  "scores": {
    "alpha_c": 0.282,
    "beta_c": 0.511,
    "gamma_c": 1.0,
    "C_sigma": 0.524
  },
  "ci": {
    "C_sigma_lo": 0.498,
    "C_sigma_hi": 0.551,
    "n_boot": 1000
  },
  "bottleneck": {
    "axis": "alpha",        // Only alpha or beta (not gamma)
    "score": 0.282
  }
}
```

**Note:** Bottleneck is only α or β. γ is a meta-metric (process health), not a bottleneck.

### Roadmap Declaration

```json
"roadmap": {
  "next_target": {
    "axis": "alpha",
    "current_value": 0.282,
    "target_value": 0.582,  // current + 0.30
    "rationale": "Improve alpha axis to raise C_Σ above threshold"
  }
}
```

The system declares what it will work on next.

### Historical Tracking

```json
"historical": {
  "previous_version": "v3.0.0",
  "previous_scores": {
    "alpha_c": 0.306,
    "beta_c": 0.061,
    "gamma_c": 0.136,
    "C_sigma": 0.136
  },
  "previous_roadmap": {
    "axis": "beta",
    "current_value": 0.061,
    "target_value": 0.361
  },
  "achievement": {
    "target_reached": true,
    "target_axis": "beta",
    "start_value": 0.061,
    "target_value": 0.361,
    "actual_value": 0.511,
    "improvement": 0.450,
    "gamma_c": 1.0,
    "baseline_health": 0.380
  },
  "changes": {
    "alpha_c": -0.024,
    "beta_c": +0.450,
    "gamma_c": +0.864,
    "C_sigma": +0.388
  }
}
```

Tracks what was promised, what was achieved, and how things changed.

______________________________________________________________________

## Implementation Details

### Measurement Flow

```python
def measure_self(params: Params) -> dict:
    """Compute C_Σ(TSC) with full tracking."""
    
    # 1. Load specs
    specs = load_specs()  # From spec/ directory
    glossary = load_glossary()
    
    # 2. Compute α and β
    A = alpha_axis(params, specs)
    B = beta_axis(params, specs, glossary)
    
    # 3. Load previous report
    prev_report = load_previous_report(current_version)
    
    # 4. Compute γ based on achievement
    baseline_health = sqrt(A.mean × B.mean)
    
    if prev_report and prev_report['roadmap']['next_target']:
        target_axis = prev_report['roadmap']['next_target']['axis']
        target_value = prev_report['roadmap']['next_target']['target_value']
        start_value = prev_report['roadmap']['next_target']['current_value']
        
        current_scores = {'alpha_c': A.mean, 'beta_c': B.mean}
        actual_value = current_scores[f'{target_axis}_c']
        
        if actual_value >= target_value:
            γ_c = 1.0  # Achieved!
        else:
            progress = (actual_value - start_value) / (target_value - start_value)
            γ_c = baseline_health + (1.0 - baseline_health) × progress
    else:
        γ_c = baseline_health  # First measurement
    
    # 5. Compute C_Σ
    C_Σ = (A.mean × B.mean × γ_c)^(1/3)
    
    # 6. Identify bottleneck (only α and β)
    bottleneck = min({'alpha': A.mean, 'beta': B.mean}, key=lambda x: x[1])
    
    # 7. Declare next target
    roadmap = {
        'next_target': {
            'axis': bottleneck,
            'current_value': scores[bottleneck],
            'target_value': scores[bottleneck] + 0.30
        }
    }
    
    # 8. Build report
    return {
        'version': current_version,
        'current': {...},
        'historical': {...},
        'roadmap': roadmap,
        ...
    }
```

### Auto-Generated README

```python
def generate_readme() -> str:
    """Generate README.md from all tsc-v*.json files."""
    
    # Load all JSON files from .tsc/
    json_files = sorted(Path('.tsc').glob('tsc-v*.json'))
    reports = [json.loads(f.read_text()) for f in json_files]
    
    # Generate markdown with:
    # - Overview (what α, β, γ mean)
    # - Principled γ formula
    # - Scores over time (table)
    # - Achievement tracking (table)
    # - Roadmap declarations (table)
    # - Changes between versions (table)
    # - Summary statistics
    
    return markdown
```

**Called automatically** by `write_report()` after writing JSON.

______________________________________________________________________

## Benefits

### 1. No Hardcoded Constants

**Before (hypothetical):**

```python
if progress >= 100%:
    γ = 1.0
else:
    γ = 0.4 + 0.6 × progress  # Magic 0.4 floor!
```

**After (principled):**

```python
baseline = sqrt(α × β)  # Derived from system state
γ = baseline + (1.0 - baseline) × progress
```

Everything derived from observable system health.

### 2. Self-Documenting

Single `.tsc/README.md` shows entire history:

- All versions in one place
- Auto-updated on every run
- No manual markdown editing

### 3. Clean Separation

- `.tsc/` = measurement metadata
- `spec/` = actual specs being measured
- Hidden directory keeps it out of the way

### 4. Contextual Penalties

Unhealthy system (low α, β):

```
baseline = sqrt(0.3 × 0.1) ≈ 0.17
Miss → γ = 0.17 (harsh penalty, compounds failure)
```

Healthy system (high α, β):

```
baseline = sqrt(0.8 × 0.8) = 0.8
Miss → γ = 0.8 (mild penalty, can recover)
```

Penalties scale with system health!

### 5. Machine Readable

```bash
# Query current state
cat .tsc/tsc-v3.1.0.json | jq '.current.scores.C_sigma'

# Track progress
for f in .tsc/tsc-v*.json; do
  jq -r '.current.scores.C_sigma' $f
done

# Check achievement
jq '.historical.achievement.target_reached' .tsc/tsc-v3.1.0.json
```

______________________________________________________________________

## Example: TSC's Journey

### v2.1.0 (Baseline)

```
α = 0.273 (low - structure doesn't match content)
β = 0.061 (catastrophic - almost no cross-references)
γ = 0.129 (baseline health from sqrt(α × β))
C_Σ = 0.129

Bottleneck: β
Roadmap: β 0.061 → 0.361
```

### v2.2.0 (Failed)

```
α = 0.306 (slightly better)
β = 0.061 (no change!)
γ = 0.136 (stuck at baseline, 0% progress)
C_Σ = 0.136

Status: ⚠️ Missed target
Achievement: 0% progress toward β goal
Bottleneck: β (still)
Roadmap: β 0.061 → 0.361 (same goal)
```

### v3.1.0 (Success!)

```
α = 0.282
β = 0.511 (HUGE improvement! +741%)
γ = 1.000 (achieved target, process proved it works!)
C_Σ = 0.524

Status: ✅ Achieved target
Achievement: 150% progress (exceeded goal)
Bottleneck: α (now α is the problem)
Roadmap: α 0.282 → 0.582
```

**Total Progress:**

- β: +741% (0.061 → 0.511)
- γ: +676% (0.129 → 1.000)
- C_Σ: +307% (0.129 → 0.524)

The process healed itself! 🎉

______________________________________________________________________

## CI/CD Integration

### GitHub Actions

```yaml
- name: Run self-measurement
  run: tsc self

- name: Get version
  id: version
  run: |
    VERSION=$(python -c "import tomllib; print('v' + tomllib.load(open('pyproject.toml', 'rb'))['project']['version'])")
    echo "report=.tsc/tsc-$VERSION.json" >> $GITHUB_OUTPUT

- name: Check verdict
  run: |
    VERDICT=$(jq -r '.verdict' ${{ steps.version.outputs.report }})
    C_SIGMA=$(jq -r '.current.scores.C_sigma' ${{ steps.version.outputs.report }})
    
    echo "C_Σ = $C_SIGMA"
    echo "Verdict: $VERDICT"
    
    if [ "$VERDICT" = "FAIL" ]; then
      echo "::warning::Self-coherence check failed"
    fi
```

### Querying Results

```python
import json
from pathlib import Path

# Load latest
latest = json.loads(Path('.tsc/tsc-v3.1.0.json').read_text())

# Extract metrics
α = latest['current']['scores']['alpha_c']
β = latest['current']['scores']['beta_c']
γ = latest['current']['scores']['gamma_c']
C_Σ = latest['current']['scores']['C_sigma']

print(f"Current: α={α:.3f}, β={β:.3f}, γ={γ:.3f}, C_Σ={C_Σ:.3f}")

# Check if we achieved last goal
if latest.get('historical', {}).get('achievement'):
    ach = latest['historical']['achievement']
    if ach['target_reached']:
        print(f"✅ Achieved {ach['target_axis']} goal!")
    else:
        print(f"⚠️ Missed {ach['target_axis']} goal")
```

______________________________________________________________________

## Migration from Old Versions

### If you have old `docs/self-coherence-v*.json` files:

```bash
# Move to new location
mkdir -p .tsc
mv docs/self-coherence-v*.json .tsc/

# Rename
cd .tsc
for f in self-coherence-v*.json; do
  mv "$f" "${f/self-coherence-/tsc-}"
done

# Regenerate README
cd ..
python -c "from reference.python.tsc_measure import generate_readme; \
           Path('.tsc/README.md').write_text(generate_readme())"
```

### If you have no previous measurements:

Just run `tsc self` and it will start fresh!

______________________________________________________________________

## Future Enhancements

### Potential Additions

1. **Trend Analysis**: Track rate of improvement
1. **Forecasting**: Predict when C_Σ > 0.90
1. **Visualization**: Generate plots from JSON
1. **Schema Versioning**: Handle format evolution
1. **Multi-Repo**: Track coherence across projects

### Schema Evolution

If we need to change the JSON format:

```json
{
  "schema_version": "2.0",
  "version": "v4.0.0",
  ...
}
```

Tools can handle multiple schema versions gracefully.

______________________________________________________________________

## Summary

**The ouroboros is complete:**

1. **Measures itself** (α, β from specs)
1. **Tracks health** (γ from achievement, no hardcoded constants)
1. **Declares intent** (roadmap: what to fix next)
1. **Verifies improvement** (did we achieve what we said?)
1. **Documents journey** (auto-generated README)

**All in one command:**

```bash
tsc self
```

**Result:**

```
.tsc/
├── tsc-v2.1.0.json  # "I'm unhealthy (γ=0.129)"
├── tsc-v2.2.0.json  # "I failed to improve (γ=0.136)"
├── tsc-v3.1.0.json  # "I healed myself! (γ=1.0)"
└── README.md        # "Here's my journey"
```

The system is self-coherent, self-improving, and self-documenting. ✨

______________________________________________________________________

*Architecture document v3.1.0 - Last updated 2025-11-11*
