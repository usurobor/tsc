# TSC Glossary v2.2.2

**Version:** 2.2.2 (Braided Algebra)
**Status:** Informative (multi-audience terminology reference)
**Corresponds to:** C≡ v2.2.2, Core v2.2.2, Operational v2.2.2

---

## Purpose and Navigation

**Purpose:** Multi-audience terminology reference for the TSC specification stack.

## How to Navigate This Glossary

**If you're a practitioner:** Read **Quick** + **Intuition** for workflow guidance.

**If you're implementing TSC:** Read **Quick** + **Engineering** for procedural guidance.

**If you're verifying proofs:** Read **Math** + cross-references to specs.

**If you're evaluating TSC philosophically:** Read **Philosophy** + see C≡ Kernel for bootstrap.

**Format convention:**
- [Term] = cross-reference to another glossary entry
- (Spec §N) = reference to specification section
- **Bold** = emphasis or defined term

---

## Core Concepts

### Cohering ($\mathbf{C}, \equiv$)

**Quick:** The unitary, ongoing process of holding-together that TSC measures.

**Intuition:** "Cohering" is whatever keeps a system **recognizably that thing** over time, despite constant internal change. We measure whether our three structural views fit together as descriptions of this one happening.

**Math:** The unique structure (up to isomorphism) satisfying axioms C1-C6. Formally: a duoidal-style triple of braided monoids on carrier set $D$, with designated element $\mathbf{C} \in D$ such that $\mathbf{C}^{I}_{a}(\mathbf{C}, \mathbf{C}) = \mathbf{C}$ for all axes $a$. See C≡ v2.2.2 $\S 0-3$.

**Philosophy:** Not a substance, property, or relation—a **process**. The framework is validated by **self-application** (empirically testing $\mathbf{C}_{\Sigma}(\text{TSC})$).

**Engineering:** $\mathbf{C}$ is the system-under-test. You define three articulation functions ($A_{\alpha}, A_{\beta}, A_{\gamma}$) that produce observations used to compute $C_{\Sigma}$.

---

### Axis ($\alpha, \beta, \gamma$)

**Quick:** The three orthogonal coordinates of action and articulation.

**Intuition:** Axes are the three **structural directions** we use to measure a system: Pattern ($\alpha$), Relation ($\beta$), and Process ($\gamma$). None is more fundamental; they are independent coordinates.

**Math:** Elements of $\mathcal{A} = \{\alpha, \beta, \gamma\}$. Each axis corresponds to a **typed unit $1_a$** and a binary operation $\odot_a$. Axes must satisfy $\mathbf{S}_3$ symmetry and **Braided Interchange (C5')**.

**Philosophy:** Axes are **epistemic coordinates**. The braiding axiom ensures they are **structurally orthogonal** and independent monoids, required to prevent algebraic collapse.

**Engineering:** Treat axes as immutable configuration labels. The **Axis-Permutation Witness** (Operational $\S 4.2$) tests whether your measurement pipeline respects the required $\mathbf{S}_3$ symmetry.

---

### Articulation ($\mathbf{A}_{a}$)

**Quick:** A function that projects an element from the carrier set into the observable context of one axis.

**Intuition:** Articulation is simply **how you generate data** from the system. If $\mathbf{C}$ is your system, $A_{\alpha}$ might sample its structure, $A_{\beta}$ might measure its interactions, and $A_{\gamma}$ might track changes over time. Each articulation gives you a different view of the same thing—it is the happening as it presents itself in the measurement frame.

**Math:** $A_a: D \to \mathcal{P}(\Omega_a)$ mapping from the carrier set $D$ to the powerset of the observation context $\Omega_a$. The image $O_a = A_a(\mathbf{C})$ is the finite set of observations.

**Philosophy:** Articulation must respect the unity of $\mathbf{C}$: $A_{\alpha}(\mathbf{C})$, $A_{\beta}(\mathbf{C})$, and $A_{\gamma}(\mathbf{C})$ are three images of the *same* process.

**Engineering:** Write three reliable data capture functions (e.g., $\text{articulate}_{\alpha}()$). The image $O_a$ must be structured (vectors, graphs, time series) to fit the axis.

---

### Role ($\mathbf{R}, \mathbf{I}, \mathbf{E}$)

**Quick:** The three interchangeable epistemic views (Coherer, Cohering, Cohered).

**Intuition:** Roles are merely **labels** for the three necessary components of agency—Source ($R$), Action ($I$), and Target ($E$). They prove the primitive $\mathbf{C}$ is **gauge-symmetric**.

**Math:** Elements of $\{R, I, E\}$, defined as views of the $\mathbf{C}^{I}_{a}$ operator via currying. The **Role Rotation Axiom (C2)** proves structural identity: $\rho: R \to I \to E \to R$.

**Philosophy:** Roles exist to prove that the structure is **gauge-symmetric**; we can swap labels ($R \leftrightarrow E$) without changing the underlying structural fact.

**Engineering:** Roles are **hidden** from the Core measurement metrics. They are tested by the **Role-Gauge Witness** (Operational $\S 4.3$) to ensure implementation independence.

---

## Measurement Terms

### $\mathbf{C}_{\Sigma}$ (Aggregate Coherence)

**Quick:** The overall measure of dimensional consistency for a phenomenon, used as the system's verdict.

**Intuition:** $\mathbf{C}_{\Sigma}$ is your **final score** ($\in [0, 1]$). It tells you whether the system's pattern, relations, and process fit together correctly.

**Math:** The geometric mean of the three dimensional scores: $C_{\Sigma} = (\alpha_c \cdot \beta_c \cdot \gamma_c)^{1/3}$. The geometric mean enforces the **Degeneracy Guard** (Core $\S 4$).

**Philosophy:** $\mathbf{C}_{\Sigma}$ is the **empirical falsifier**. If $\text{CI}_{\text{lo}}(C_{\Sigma}) < \Theta$, the framework asserts that the phenomenon is incoherent *relative to the measurement context*.

**Engineering:** The **Verdict Gate** (Operational $\S 6$) requires $\text{CI}_{\text{lo}}(C_{\Sigma}) \ge \Theta$ for a $\text{PASS}$ result. It is maximized by minimizing **Leverage ($\lambda_{\Sigma}$)**.

---

### $\mathbf{\lambda}_{\Sigma}$ (Aggregate Leverage)

**Quick:** A diagnostic measure of the total incoherence (or "friction") in the system.

**Intuition:** Leverage is the **cost** of incoherence. A high $\lambda_{a}$ indicates the primary **coherence bottleneck** in that dimension, guiding targeted refactoring efforts.

**Math:** The negative natural logarithm of the aggregate coherence: $\lambda_{\Sigma} = -\ln(C_{\Sigma})$. The total leverage is the arithmetic mean of the dimensional leverages: $\lambda_{\Sigma} = \frac{1}{3}\sum \lambda_a$. See Core $\S 8$.

**Philosophy:** $\lambda_{\Sigma}$ represents **Coherence-Energy Duality**—minimizing leverage is equivalent to maximizing coherence. It provides an additive diagnostic objective.

**Engineering:** $\lambda_{a}$ is used for **Leverage-Driven Budget Allocation** (Operational $\S 8.1$): effort is proportional to the dimension with the highest leverage ($\max \lambda_a$).

---

## Operational Terms

### Witness

**Quick:** A degeneracy guard that tests whether the measurement itself is valid.

**Intuition:** Witnesses are **safety checks**. Before trusting $C_{\Sigma}$, we verify that the measurement process didn't break (e.g., Braiding holds, Variance is stable). If any witness fails, $C_{\Sigma}$ is deemed unreliable.

**Math:** A computable predicate $W$: Observations $\to$ $\{\text{PASS, FAIL}\}$ with threshold $\tau$. If $W(O) = \text{FAIL}$, the verdict is **FAIL\_DEGENERATE** regardless of $C_{\Sigma}$ value. See Operational $\S 4$ for the five required witnesses.

**Philosophy:** Witnesses embody **falsifiability**—they test whether the C≡ axioms empirically hold for the phenomenon.

**Engineering:** Each witness has a threshold ($\tau_{\text{braid}}, \tau_{\text{var}}$, etc.). $\text{FAIL\_DEGENERATE}$ is the critical flag: investigate which witness failed and why.

---

### Provenance Bundle

**Quick:** The complete reproducibility record required for third-party recomputation.

**Intuition:** Everything someone would need to exactly reproduce your $C_{\Sigma}$ score: **random seeds, parameters, alignment methods, and witness stats**. Without provenance, TSC is not science—it's just numbers.

**Math:** A complete record of the input tuple sufficient for deterministic recomputation. See Operational $\S 7$.

**Philosophy:** Provenance operationalizes **transparency**. TSC makes no "black box" claims; every measurement is auditable.

**Engineering:** Use structured formats (YAML/JSON) with schema validation. Include git commit hashes for code, artifact checksums, and full parameter snapshots.

---

### Verdict

**Quick:** The final $\text{PASS}/\text{FAIL}/\text{FAIL\_DEGENERATE}$ decision based on $C_{\Sigma}$ and witnesses.

**Intuition:** The verdict tells you: "Does this system cohere by TSC's standards?" $\text{PASS}$ means yes. $\text{FAIL}$ means no. $\text{FAIL\_DEGENERATE}$ means the measurement itself broke.

**Math:** A function $V: (C_{\Sigma}, \text{CI}, \text{Witnesses}) \to \{\text{PASS, FAIL, FAIL\_DEGENERATE}\}$ defined by normative rules in Operational $\S 6$. $\text{PASS}$ requires $\text{CI}_{\text{lo}}(C_{\Sigma}) \ge \Theta$.

**Philosophy:** Verdicts are **falsifiable claims** about coherence relative to measurement context—not absolute judgments.

**Engineering:** $\text{FAIL\_DEGENERATE}$ is the critical flag: investigate which witness failed and why. $\text{FAIL}$ means insufficient coherence was achieved.

---

### Summary ($\mathbf{S}_{a}$)

**Quick:** A compressed representation of observations along one axis.

**Intuition:** Raw observations ($O_{\alpha}$) are compressed into a few key statistics: dimension ($d_{\alpha}$), distribution ($p_{\alpha}$), entropy ($\mathcal{H}_{\alpha}$), and invariants ($\mathcal{I}_{\alpha}$). Summaries are what we actually compare across axes.

**Math:** A 4-tuple $S_a = (d_a, p_a, \mathcal{H}_a, \mathcal{I}_a)$ where $d_a$ is intrinsic dimension, $p_a$ is probability distribution, $\mathcal{H}_a$ is Shannon entropy, and $\mathcal{I}_a$ is a set of invariants. See Core $\S 0$.

**Philosophy:** Summaries respect the measurement stance: we don't claim to "capture" the phenomenon, only to produce a **finite description adequate for comparison**.

**Engineering:** Summary construction is where domain knowledge enters. Make schemas explicit in provenance. Summaries are the inputs to the **Alignment** process.

---

### Alignment ($\sigma, \mathcal{A}_{ab}$)

**Quick:** A correspondence method that enables comparing summaries from different axes.

**Intuition:** Alignment solves: "How do I compare an $\alpha$ summary (structure) to a $\beta$ summary (relations)?" We use an **ensemble** ($\mathcal{A}_{ab}$) of different alignment methods (Optimal Transport, Graph Matching, etc.) to ensure the comparison is stable.

**Math:** An alignment $\sigma \in \mathcal{A}_{ab}$ is a correspondence that yields discrepancy $\Delta(S_a, S_b; \sigma)$. The ensemble mean is $\overline{\mathrm{Coh}}_{ab}$. See Core $\S 2$.

**Philosophy:** Alignments are **comparison devices**, not truth-preserving maps. Ensemble variance ($\mathrm{Var}_{ab}$) witnesses whether the comparison is statistically stable.

**Engineering:** Build ensembles with $\ge 3$ diverse methods (never just one). If $\mathrm{Var}_{ab} > \tau_{\text{var}}$, comparison is unstable $\to$ $\text{FAIL\_DEGENERATE}$.

---

### OOD (Out-of-Distribution)

**Quick:** Detection of when current observations diverge from historical patterns.

**Intuition:** OOD detection catches: "This measurement looks nothing like our past measurements." This signals concept drift, context shift, or measurement failure. Trust in $C_{\Sigma}$ is compromised until investigation.

**Math:** Compute robust z-score $Z_t = |C_{\Sigma}^{(t)} - \text{median}(\text{ref})| / (1.4826 \cdot \text{MAD}(\text{ref}))$ against a reference distribution ($\text{ref}$). If $Z_t \ge Z_{\text{crit}}$, flag OOD. See Operational $\S 10$.

**Philosophy:** OOD acknowledges **measurement context-dependence**. $C_{\Sigma}$ has meaning relative to a stable measurement regime. When that regime shifts, we must recalibrate.

**Engineering:** Maintain a rolling reference distribution. When $Z_t \ge Z_{\text{crit}}$, trigger controller transition to **LOCKDOWN** (Operational $\S 5$). Investigate cause before trusting new verdicts.

---

## Algebraic Terms

### Braided Interchange ($\varphi_{ab}$)

**Quick:** The structural mechanism that allows the three axes to interact without collapsing into a single, commutative operation.

**Intuition:** It's the **rule for swapping order** when two different types of composition ($\odot_{\alpha}$ and $\odot_{\beta}$) are nested. This structural guarantee prevents the algebraic short-circuit (Eckmann-Hilton collapse).

**Math:** The **Natural Isomorphism** $\varphi_{ab}$ governing the middle-four interchange of nested operations. It is governed by **Axiom C5'** and the **Hexagon Coherence** (C≡ $\S 3$).

**Philosophy:** This feature validates the *orthogonal* claim: $\alpha$ and $\beta$ are independent monoids, but they must be compatible (braided) because they act on the same carrier set $D$.

**Engineering:** The **Braided Interchange Witness ($\delta_{\text{MFI}}$)** (Operational $\S 4.1$) is the empirical test that verifies this axiom holds for the specific artifacts being measured. Failure yields $\text{FAIL\_DEGENERATE}$.

---

### Normalization ($\mathbf{NF}[\cdot]$)

**Quick:** The canonical procedure for reducing a complex algebraic expression to its simplest, unique form.

**Intuition:** It is the required procedure for finding the **simplest, equivalent statement** for any composite process. $\mathrm{NF}[\cdot]$ operationalizes the ideal of **self-application stability** ($\mathbf{C} \odot \mathbf{C} \to \mathbf{C}$).

**Math:** $\mathrm{NF}[\cdot]$ must satisfy **four normative requirements** (Termination, Confluence, $S_3$-Equivariance, Isomorphism Quotient). It is the target of the MFI witness discrepancy. See C≡ $\S 4$.

**Philosophy:** $\mathrm{NF}[\cdot]$ provides a canonical state for comparing complex compositions, essential for the testability of the braided algebra.

**Engineering:** $\mathrm{NF}[\cdot]$ is an implementation-defined algorithm (e.g., right-association + unit elimination). The chosen strategy MUST be recorded in the Provenance Bundle ($\S 7$) for reproducibility.

---

### Typed Unit ($\mathbf{1}_{a}$)

**Quick:** The neutral element for composition along one specific axis.

**Intuition:** The unit is the observation of **perfect neutrality**. $\mathbf{1}_{\alpha}$ is an empty pattern; $\mathbf{1}_{\gamma}$ is a perfectly static process. Combining a system $x$ with its unit ($\mathbf{1}_{a} \odot_{a} x$) leaves $x$ unchanged.

**Math:** $1_a \in D$ such that $1_a \odot_a x = x$. The units are **typed** ($\mathbf{1}_{\alpha} \neq \mathbf{1}_{\beta}$) and **dually fixed** ($\mathbf{1}_{a}^{\top} = \mathbf{1}_{a}$). See C≡ $\S 1.3, \S 2$ (Axiom C3).

**Philosophy:** The typed nature of the unit is necessary to prevent algebraic collapse (C≡ Axiom C5'). It signifies that neutrality is **specific to the dimension** of observation—there's no "universal neutral" that works across all axes.

**Engineering:** The numerical floor $\varepsilon$ (default $10^{-5}$) is the operational manifestation of the unit: $a_c = \max(a_c, \varepsilon)$ prevents $\ln(a_c)$ from collapsing to $-\infty$ when the measured system state approaches the mathematical unit $1_a$.

---

## Common Confusions Clarified

**Q: Are $\alpha/\beta/\gamma$ the same as the roles $\mathbf{R}/\mathbf{I}/\mathbf{E}$?**
A: No. **Axes** ($\alpha/\beta/\gamma$) are coordinates of measurement (ontological primitives in the algebra). **Roles** ($\mathbf{R}/\mathbf{I}/\mathbf{E}$) are epistemic views (gauge-equivalent labels). Axes are measured; roles are hidden. See [Axis] and [Role].

**Q: Is "cohering" a metaphysical claim about reality?**
A: No. "Cohering" is a name for the measurement primitive $\mathbf{C}$, validated by self-application ($C_{\Sigma}(\text{TSC})$). It's not a claim about substance, essence, or ultimate reality. See [Cohering], Philosophy level.

**Q: Why geometric mean for $C_{\Sigma}$ instead of arithmetic?**
A: Geometric mean enforces the **Degeneracy Guard**—any single dimension with score 0 makes $C_{\Sigma} = 0$ (no compensation). Arithmetic mean would allow a bad dimension to be "averaged away." See [$C_{\Sigma}$], Math level, and Core $\S 4$.

**Q: What's the difference between FAIL and FAIL\_DEGENERATE?**
A: **FAIL** means low coherence ($C_{\Sigma} < \Theta$). **FAIL\_DEGENERATE** means measurement broke (witness failed). FAIL is interpretable; $\text{FAIL\_DEGENERATE}$ is not—investigate the witness failure. See [Verdict] and Operational $\S 6$.

**Q: Can I change parameters between runs?**
A: Only in **HANDSHAKE** state (calibration). Once in OPTIMIZE, parameters must be frozen. Changing $\lambda$ or $\theta$ mid-measurement invalidates comparability. See Operational $\S 5$ and Core $\S 2.1$ (parameter provenance).

**Q: Is TSC deterministic?**
A: With fixed seeds, yes. Bootstrap resampling uses random sampling, but if you log seeds (provenance requirement), third parties can reproduce exact results. See [Provenance Bundle] and Operational $\S 7$.

**Q: Why three axes? Why not two or four?**
A: Three is the minimum to avoid Eckmann-Hilton collapse (two commutative monoids on shared carrier must be identical). Three provides orthogonality without redundancy. See [Braided Interchange], Philosophy level.

---

## See Also

- **C≡ Kernel v2.0.0** — Intuitive bootstrap (focus on Intuition + Philosophy levels)
- **C≡ v2.2.2** — Axiomatic foundation (focus on Math level)
- **Core v2.2.2** — Measurement calculus (focus on Math + Engineering levels)
- **Operational v2.2.2** — Protocol and policy (focus on Engineering level)

---

**End — TSC Glossary v2.2.2 (Multi-Audience Terminology Reference).**
