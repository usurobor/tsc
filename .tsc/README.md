# .tsc/ — TSC Measurement Infrastructure

This directory contains all TSC measurement data, methodologies, and tracking.

## Directory Structure

```
.tsc/
├── measurements/           # Actual measurement results
│   ├── tsc-v2.1.0.json    # Historic measurements
│   ├── tsc-v2.2.0.json
│   ├── tsc-v3.1.0.json    # Current measurement
│   └── README.md          # Auto-generated history (specs)
│
├── methodologies/          # How to measure things
│   └── readme.md          # README measurement methodology
│
└── trackers/              # Historical tracking data
    └── readme-tracker.json # README measurement history
```

## Contents

### measurements/

**Purpose:** Stores TSC measurement results

**Files:**

- `tsc-v*.json` — Self-measurement of TSC specs (α, β, γ, C_Σ)
- `README.md` — Auto-generated summary of all measurements

**Updated by:** `tsc self` command

______________________________________________________________________

### methodologies/

**Purpose:** Documents how to apply TSC measurement to different artifact types

**Files:**

- `readme.md` — How to measure README documents (witnesses, axes, verdicts)

**For:** Reference when measuring other systems

______________________________________________________________________

### trackers/

**Purpose:** Raw historical tracking data for various measurements

**Files:**

- `readme-tracker.json` — Historical README measurements from git

**Format:** JSON array of measurements over time

______________________________________________________________________

## Usage

### Measure TSC Specs

```bash
tsc self
# ✅ Written: .tsc/measurements/tsc-v3.1.0.json
# ✅ Updated: .tsc/measurements/README.md
```

### View Measurement History

```bash
cat .tsc/measurements/README.md
```

### Reference Methodology

```bash
cat .tsc/methodologies/readme.md
```

______________________________________________________________________

*This directory structure ensures all TSC measurement infrastructure is self-contained and organized.*
