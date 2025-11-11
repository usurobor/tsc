# TSC Measurement Methodology for README Documents

## Overview

This document defines how to apply TSC (Triadic Self-Coherence) measurement to README documents. A README is a specification document that orients multiple audiences to a system through structured text, links, and examples.

---

## The Three Axes (Adapted for README)

### α (Alpha) - Pattern Coherence
**Measures:** Consistency between document structure and content

**Observation A (Content):** Tokenize full text → word frequency distribution  
**Observation B (Structure):** Extract headers, bullets, bold terms → structural element distribution

**Question:** Do section headers accurately describe their content?

**Example:**
- High α: Header "Installation" → section discusses `pip install`, setup steps
- Low α: Header "For Engineers" → section discusses philosophical concepts

---

### β (Beta) - Relational Coherence
**Measures:** Quality of cross-references and links

**Observation A (Degree Distribution):** Which terms/documents are most connected?  
**Observation B (Cross-Reference Counts):** Which terms are explicitly referenced with "see X" or "cf. X" patterns?

**Question:** Are key terms and documents properly cross-referenced?

**Example:**
- High β: "TSC uses C≡ axioms (see spec/c-equiv.md) to measure coherence (cf. Glossary)"
- Low β: "TSC uses C≡ axioms to measure coherence" (no explicit links)

---

### γ (Gamma) - Trajectory/Evolution
**Measures:** Direction of document evolution over time

**Observation A (Historical):** Previous README versions from git history  
**Observation B (Current):** Current README state

**Question:** Is the document evolving toward or away from coherence?

**Computation:**
```python
if previous_version_measurable:
    baseline_health = sqrt(α_prev × β_prev)
    improvement = (C_Σ_current - C_Σ_prev) / C_Σ_prev
    γ = baseline_health + (1.0 - baseline_health) × improvement
else:
    γ = sqrt(α × β)  # Baseline only
```

---

## Witnesses (Safety Checks)

Witnesses determine if measurement is **valid** (PASS), **coherent but flawed** (FAIL), or **unmeasurable** (FAIL_DEGENERATE).

### Critical Witnesses (Must Pass for Valid Measurement)

#### 1. Accuracy Witness
**Checks:** Are internal file links valid?

**Method:**
```python
for link in internal_links:
    if not file_exists(link):
        return FAIL_DEGENERATE
```

**Excludes:**
- External URLs (http://)
- Anchor links (#section)

**Why critical:** Broken links indicate document rot. Cannot measure coherence of a document that references non-existent files.

**Example failures:**
- `[Self-Coherence Report](docs/self-coherence-v3.1.0.md)` when file doesn't exist
- `[C≡ Kernel](spec/c-equiv-kernel.md)` when kernel spec was removed

---

#### 2. Staleness Witness
**Checks:** Does documentation match actual implementation?

**Method:**
```python
if readme_claims_feature_X() and not implementation_has_feature_X():
    return FAIL_DEGENERATE
```

**Examples to check:**
- Command syntax (e.g., `--out` flag that was removed)
- Version numbers (claiming v4.0.0 when repo is v3.1.0)
- File locations (claiming `docs/` when moved to `.tsc/`)

**Why critical:** Stale documentation causes user confusion and indicates document hasn't been maintained alongside code.

---

#### 3. Completeness Witness
**Checks:** Are required sections present?

**Method:**
```python
required_sections = ['Installation', 'Contributing', 'License']
h2_headers = extract_h2_headers(readme)

for section in required_sections:
    if not any(section.lower() in h.lower() for h in h2_headers):
        return FAIL_DEGENERATE
```

**Why critical:** Missing critical sections means document is incomplete. Cannot measure coherence of a fragment.

---

### Non-Critical Witness

#### 4. Purpose Witness
**Checks:** Does document serve its stated audiences?

**Method:**
```python
stated_audiences = ['Engineers', 'Philosophers', 'Researchers', 'AI Systems']
h2_headers = extract_h2_headers(readme)

audience_sections_found = 0
for audience in stated_audiences:
    if any(audience.lower() in h.lower() for h in h2_headers):
        audience_sections_found += 1

if audience_sections_found < 3:
    return FAIL  # Low coherence, not invalid
```

**Why non-critical:** Missing audience sections indicates low β (unfulfilled promises), but doesn't make measurement invalid. We can measure and will find low coherence.

---

## Verdict Logic

```python
def determine_verdict(witnesses, alpha, beta, gamma, c_sigma):
    # Check critical witnesses
    if not witnesses['accuracy'].pass:
        return 'FAIL_DEGENERATE', 'accuracy'
    
    if not witnesses['staleness'].pass:
        return 'FAIL_DEGENERATE', 'staleness'
    
    if not witnesses['completeness'].pass:
        return 'FAIL_DEGENERATE', 'completeness'
    
    # Measurement is valid, compute C_Σ verdict
    if c_sigma >= 0.80:
        return 'PASS', None
    else:
        return 'FAIL', None
```

**Result categories:**
- **FAIL_DEGENERATE**: Measurement invalid, don't report C_Σ
- **FAIL**: Measurement valid, but C_Σ < 0.80
- **PASS**: Measurement valid, C_Σ ≥ 0.80

---

## Measurement Protocol

### 1. Run Witnesses First
```python
witnesses = {
    'accuracy': check_links(readme),
    'staleness': check_claims(readme),
    'completeness': check_sections(readme),
    'purpose': check_audiences(readme)
}

verdict, failed_witness = determine_verdict_from_witnesses(witnesses)

if verdict == 'FAIL_DEGENERATE':
    print(f"Cannot measure: {failed_witness} witness failed")
    exit(1)
```

### 2. Measure α and β Only If Valid
```python
if verdict != 'FAIL_DEGENERATE':
    alpha = measure_alpha(readme)
    beta = measure_beta(readme)
    gamma = measure_gamma(readme, history)
    c_sigma = (alpha * beta * gamma) ** (1/3)
    
    print(f"α={alpha:.3f} β={beta:.3f} γ={gamma:.3f} C_Σ={c_sigma:.3f}")
```

### 3. Report Results
```python
if c_sigma >= 0.80:
    print("README is coherent")
else:
    print(f"README has low coherence")
    print(f"Bottleneck: {'α' if alpha < beta else 'β'}")
```

---

## Example: TSC README History

### Historical Analysis (2025-10-31 to 2025-11-11)

**Finding:** Every version failed Accuracy witness (8-14 broken links)

**Sample failures:**
- `docs/self-coherence-v3.1.0.md` (file doesn't exist)
- `spec/c-equiv-kernel.md` (spec was removed)
- `docs/v3-overview.md` (never created)

**Result:** README has been **unmeasurable (FAIL_DEGENERATE)** for its entire git history.

### After Fixes (2025-11-11)

**Witnesses:**
- ✅ Accuracy: All links valid
- ✅ Staleness: No stale claims
- ✅ Completeness: All required sections present
- ✅ Purpose: 4 audiences served

**Measurements:**
- α = 0.026 (catastrophic - headers don't match content)
- β = 0.169 (very low - only 1 cross-reference)
- γ = 0.067 (baseline health)
- C_Σ = 0.067

**Verdict:** FAIL (measurable but incoherent)

**Bottleneck:** α (pattern coherence)

---

## Improvement Recommendations

### To Improve α (Pattern Coherence)

**Problem:** Headers are organizational labels, not content descriptors.

**Fix:** Make headers describe actual content:

```markdown
# Before (α = 0.026)
## For Engineers
Measure coherence of your codebase...

# After
## Measuring Codebase Coherence
Engineers can measure coherence...
```

**Result:** Headers share tokens with content → higher cosine similarity → higher α.

---

### To Improve β (Relational Coherence)

**Problem:** Only 1 explicit cross-reference in entire document.

**Fix:** Add explicit "see" and "cf." patterns:

```markdown
# Before (β = 0.169)
TSC uses C≡ axioms to define coherence.

# After
TSC uses C≡ axioms (see spec/c-equiv.md) to define 
coherence (cf. Glossary).
```

**Result:** More cross-references → better alignment between term usage and explicit links → higher β.

---

## Summary

**This methodology enables:**
1. **Valid measurement** - Witnesses catch broken/stale documentation
2. **Honest measurement** - Low scores indicate real problems (not measurement bugs)
3. **Actionable feedback** - Bottleneck identification shows what to fix
4. **Historical tracking** - γ shows trajectory over time

**Key insight:** README coherence is measurable using the same TSC framework as code, just with adapted articulations for documentation.

---

*README Measurement Methodology v1.0 - 2025-11-11*