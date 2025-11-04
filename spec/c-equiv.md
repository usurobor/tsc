# C≡ (Coherence Calculus, C-Calculus)

**Version:** 2.2.0 (Braided Algebra)\
**Status:** Normative (Axiomatic Semantics)

C≡ is a minimal language whose sole semantic object is the unitary process of **cohering ($\\mathbf{C}$)**. It provides the formal ground for TSC's ontology: **there is only $\\mathbf{C}$; everything else is articulation of $\\mathbf{C}$.**

______________________________________________________________________

## 0 · Ontological Status (Normative Context)

**Formal definition:** $\\mathbf{C}$ is the unique structure (up to isomorphism) satisfying Axioms C1-C6. This structure is formally a duoidal-style triple of braided monoids on a single carrier.

**Intuitive name:** We call $\\mathbf{C}$ "cohering" to provide a unified symbol and ground the measurement intuition, but this is **not a claim about ultimate reality**.

**Operational stance:** The axioms are validated by self-application (Core §4.1, Operational §11): if $C\_{\\Sigma}(\\text{TSC})$ remains high, the structure is **sufficient** for its stated purpose (measuring coherence).

______________________________________________________________________

## 1 · Primitives and Views

**Primitive.** $\\mathbf{C}$ denotes the unitary process of *cohering*. Let $D$ be the domain of discourse (the set of all coherents), and stipulate $\\mathbf{C}\\in D$ as a designated coherent.

**Decorations.** Every articulation of $\\mathbf{C}$ is denoted $C^{r}\_{a}$, where:

- **Role (Superscript $r \\in {R, I, E}$):** The epistemic view taken on $\\mathbf{C}$.
- **Articulation (Subscript $a \\in {\\alpha, \\beta, \\gamma}$):** The orthogonal coordinate of action.

**Core Arity (Process $\\mathbf{C}^{I}\_{a}$).** The fundamental action is the binary map $\\mathbf{C}^{I}\_{a}: D \\times D \\to D$.

**Role Unification (Views as Maps).** Roles $R$ and $E$ are **curried maps**, not elements of $D$. For each axis $a$, we have:

- $\\mathbf{C}^{I}\_{a}: D \\times D \\to D$ (binary operator)
- $\\mathbf{C}^{R}_{a}: D \\to (D \\to D)$ where $\\mathbf{C}^{R}_{a}(x)(y) = \\mathbf{C}^{I}\_{a}(x,y)$ (left-currying)
- $\\mathbf{C}^{E}_{a}: D \\to (D \\to D)$ where $\\mathbf{C}^{E}_{a}(y)(x) = \\mathbf{C}^{I}\_{a}(x,y)$ (right-currying)

### 1.3 Units (Typed Elements)

For each axis $a\\in{\\alpha,\\beta,\\gamma}$, fix a distinguished **two‑sided unit** $1_a\\in D$. Units are **typed by axis** and MUST NOT be identified across axes (e.g., $1\_\\alpha\\neq 1\_\\beta\\neq 1\_\\gamma$ by specification).

______________________________________________________________________

## 2 · Reflexive Cohering (C-Calculus Axioms)

**Axiom C1 · Self-Application.** The self-application of the cohering process is well-typed and yields the process itself:
$$
\\mathbf{C}^{I}\_{a}(\\mathbf{C}, \\mathbf{C}) = \\mathbf{C} \\quad \\text{for all } a \\in {\\alpha, \\beta, \\gamma}.
$$

**Axiom C2 · Role Rotation.** The operator $\\rho$ acts as an automorphism on the role index $r \\in {R, I, E}$:
$$
\\rho: (r,a) \\mapsto (r',a) \\quad \\text{with } \\rho^{3} = \\mathrm{id}.
$$
**Axiomatic intent:** This declares the three roles are **identical up to gauge** and provides the structure for the $\\rho$-invariance witness (Operational §4.3).

**Axiom C3 · Neutrality (Typed Monoid Units).** For each axis $a \\in {\\alpha,\\beta,\\gamma}$, the unit $1_a \\in D$ is a two-sided identity for $\\odot_a$:
$$
\\mathbf{C}^{I}_{a}(1_{a}, x) = x = \\mathbf{C}^{I}_{a}(x, 1_{a})
\\quad\\text{for all } x \\in D.
$$
**Typed separation (normative):** Units MUST NOT be identified across axes: $1\_\\alpha \\neq 1\_\\beta \\neq 1\_\\gamma$.

______________________________________________________________________

## 3 · Minimal Algebra (Fundamental Laws)

Let $x \\odot\_{a} y := \\mathbf{C}^{I}\_{a}(x, y)$.

**Axiom C4 · Associativity.** $(x \\odot\_{a} y) \\odot\_{a} z = x \\odot\_{a} (y \\odot\_{a} z)$.

**Axiom C5′ · Orthogonality (Braided Interchange).** For $a \\neq b$, there is a natural isomorphism $\\varphi\_{ab}$ such that:
$$
\\varphi\_{ab}\\big((x \\odot_a y) \\odot_b (z \\odot_a w)\\big);\\cong;(x \\odot_b z) \\odot_a (y \\odot_b w).
$$
**(C5a Natural)** $\\varphi\_{ab}$ is natural in all four arguments $x,y,z,w$.\
**(C5u Unitors)** $\\varphi\_{ab}$ commutes with the unitors of $\\odot_a$ and $\\odot_b$.\
**(C5h Hexagon Coherence)** For any three distinct axes $a, b, c$:
$$
\\varphi\_{ca} \\circ \\varphi\_{bc} \\circ \\varphi\_{ab} ;\\cong; \\text{id}
$$
where $\\circ$ denotes composition of natural transformations.

**Operational witness:** This is tested by the Braided Interchange Witness (Operational §4.1).

**Axiom C6 · Adjointness (Duality).** There is an involution $(\\cdot)^{\\top}: D \\to D$ satisfying:

1. $(x^{\\top})^{\\top} = x$ (involutive)
1. $(x \\odot_a y)^{\\top} = y^{\\top} \\odot_a x^{\\top}$ (order-reversing)
1. $(1_a)^{\\top} = 1_a$ for all $a$ (unit-fixing)

**Axiom C6′ · Dual Interchange Compatibility.**
$$
\\big(\\varphi\_{ab}((x\\odot_a y)\\odot_b(z\\odot_a w))\\big)^{\\top}
;=;
\\varphi\_{ab}\\big((w^{\\top} \\odot_a z^{\\top}) \\odot_b (y^{\\top} \\odot_a x^{\\top})\\big).
$$

______________________________________________________________________

## 4 · Semantics and Validation Link

**Domain $D$ (Carrier Set).** $D$ is closed under the operations:

1. $\\mathbf{C} \\in D$ (designated primitive)
1. $1_a \\in D$ for all $a \\in {\\alpha,\\beta,\\gamma}$ (typed units)
1. Closure: If $x, y \\in D$, then $\\mathbf{C}^{I}\_{a}(x,y) \\in D$ (binary operation)
1. Duality closure: If $x \\in D$, then $x^{\\top} \\in D$ (involution)

**Interpretation:** $D$ contains the primitive process $\\mathbf{C}$, its units, and all composite/derived processes formed by the axiom operations.

**Normalization Strategy ($\\mathrm{NF}[\\cdot]$) Requirements.**

A valid normalization strategy MUST satisfy:

1. **Termination:** All reduction sequences reach a normal form in finite steps
1. **Confluence:** Different reduction orders yield the same normal form (Church-Rosser property)
1. **$S_3$-equivariance:** For any permutation $\\sigma \\in S_3$ acting on axis labels ${\\alpha,\\beta,\\gamma}$:
   $$\\text{NF}[\\sigma(\\text{expr})] = \\sigma(\\text{NF}[\\text{expr}])$$
1. **Isomorphism quotient:** If $\\varphi\_{ab}(x) \\cong y$, then $\\text{NF}[x] = \\text{NF}[y]$

**Implementation note:** The Operational layer (§4) provides a concrete normalization strategy and empirically validates termination/confluence via the MFI witness (bounded $\\delta\_{\\text{MFI}}$).

______________________________________________________________________

### 4.1 Required Operational Witnesses (Link to Operational §4)

The Core mathematics requires that the Operational layer provides witnesses to empirically validate the following C≡ axioms:

1. **Braided Interchange Witness ($\\beta$-axis):** Empirically tests Axiom C5′ via $\\delta\_{\\text{MFI}} \\le \\tau\_{\\text{braid}}$ (default $10^{-3}$). See Operational §4.1.

1. **Axis-Permutation Witness ($S_3$):** Empirically tests the $S_3$ invariance required by the monoidal structure. Verifies all permuted runs fall within baseline confidence intervals. See Operational §4.2.

1. **Role-Gauge Witness ($\\rho$-invariance):** Empirically tests Axiom C2 by verifying measurement invariance under $\\rho$ rotation. See Operational §4.3.

**Validation Link.** The Core and Operational layers must demonstrate that the measured coherence $C\_{\\Sigma}$ satisfies the stability predicted by these algebraic laws.

______________________________________________________________________

**See also:**

- **C≡ Kernel** (c-equiv-kernel.md) — intuitive bootstrap and measurement bridge
- **Core v2.2.0** (tsc-core.md) — measurement calculus grounded in C≡
- **Operational v2.2.0** (tsc-oper.md) — witness protocols and policy

______________________________________________________________________

**End — C≡ v2.2.0 (Normative Semantics).**
