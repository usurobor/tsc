# Documentation System

How the `docs/` tree is organized and how documents evolve.

Adapted from [cnos DOCUMENTATION-SYSTEM.md](https://github.com/usurobor/cnos/blob/main/docs/beta/governance/DOCUMENTATION-SYSTEM.md).

---

## 1. Taxonomy

The docs tree has two dimensions:

1. **Triad axis** — every document has a dominant ontological character (α, β, γ)
2. **Feature bundle** — related documents grouped by the feature they serve

### 1.1 Triad axis

| Directory | Axis | Question it answers |
|-----------|------|---------------------|
| (root) | The whole | What is TSC? (`THESIS.md`) How to read these docs? (`README.md`) |
| `alpha/` | **Pattern** | What has been articulated? Doctrine, specs, engine design. |
| `beta/` | **Relation** | Do the parts reveal one system? Governance, guides, evidence. |
| `gamma/` | **Evolution** | How does it change? Plans, checklists, release history. |

### 1.2 Feature bundles

A feature bundle groups all documents that belong to a single feature or subsystem. A bundle lives as a subdirectory within its dominant axis.

```
docs/alpha/{scope}/
```

#### Bundle structure

```
docs/alpha/{feature}/
├── README.md           # Bundle index: names canonical spec, lists documents, reading order
├── 0.1.0/              # Frozen snapshot for v0.1.0
│   ├── README.md
│   ├── DESIGN.md
│   └── ...
└── ...
```

#### Bundle README requirements

- Feature name and one-sentence purpose
- Which document is the canonical spec (by name and path)
- Document map: every file in the bundle with one-line description
- Reading order for new readers

### 1.3 Root-level documents

- **THESIS.md** — the whole, above the triad. Always the entry point.
- **README.md** — reading guide, navigation, and bundle index.

---

## 2. Document classes

### 2.1 Whole

The thesis. Sits above the triad. One document: `THESIS.md`.

### 2.2 Canonical spec

Evolves in place. Never forked into versioned copies at the same level. The single source of truth for its scope.

In TSC, canonical specs live in `spec/` at the repo root (the theory target surface). The doctrine bundle in `docs/alpha/doctrine/` references them.

### 2.3 Feature README

The index document for a feature bundle. Lives at `docs/alpha/{feature}/README.md`.

### 2.4 Feature-scoped design doc

A design document scoped to a specific version. Lives inside a version directory within the feature bundle.

### 2.5 Reference document

Stable lookup material. Updated when terminology or conventions change, not per release.

### 2.6 Guide

Task-oriented procedures connecting operator to system. Lives in `beta/guides/`.

### 2.7 Plan

Implementation plan for a specific version. Lives in `gamma/plans/` or inside a feature bundle's version directory.

### 2.8 Evidence

Audits, self-coherence reports, and assessments. Lives in feature bundle version directories (e.g. `SELF-COHERENCE.md`) or in `beta/evidence/`.

### 2.9 Version directory

A version directory groups all frozen artifacts for a single release. Lives inside the feature bundle as `{MAJOR}.{MINOR}.{PATCH}/`.

Version directories are frozen by repository policy. After creation, their contents MUST NOT be modified in later commits. Corrections MUST be published as a new version directory.

**Exception:** path references MAY be updated when the target file has moved.

---

## 3. Versioning rules

### Single version lineage

All documents use TSC release versions. There is no independent per-document version lineage.

### When a document's version advances

| Change type | Advances version? |
|-------------|-------------------|
| Wording, examples, typos | Yes (next patch) |
| New section, additive content | Yes (next minor) |
| Scope change, structural rewrite | Yes (next minor or major) |
| No change in a release | No |

### Version directories

Version directories inside feature bundles use the TSC release version.

---

## 4. Placement rules

When adding a new document, ask: **what is its dominant ontological character?**

1. **Does it articulate substance?** (doctrine, spec, design, protocol) → `alpha/`
2. **Does it define relation?** (how parts connect, operator guides, evidence) → `beta/`
3. **Does it govern movement?** (method, process, plans, checklists) → `gamma/`

Within each axis:

| Location | What goes there |
|----------|-----------------|
| `alpha/{feature}/` | Feature bundle (spec + version snapshots) |
| `beta/guides/` | Task-oriented procedures |
| `beta/governance/` | System-level rules and conventions |
| `beta/evidence/` | Audits, RCAs, assessments |
| `gamma/plans/` | Implementation plans |
| `gamma/checklists/` | Release gate verification |

---

## 5. Current bundle map

| Bundle | Axis | Canonical spec | Path |
|--------|------|----------------|------|
| doctrine | α | `spec/tsc-core.md` | `docs/alpha/doctrine/` |
| engine | α | `engine/ocaml/` (implementation) | `docs/alpha/engine/` |

---

## 6. Reading order

1. `THESIS.md` — the whole
2. `README.md` — navigation
3. `alpha/` — what has been articulated? (follow bundles for depth)
4. `beta/` — do the parts cohere?
5. `gamma/` — how does it move?
