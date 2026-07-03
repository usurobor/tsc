# TSC Glossary v3.2.0

**Version:** v3.2.0 (Triadic Foundation + Measurement Framework + Barrier Transform)\
**Status:** Informative (accessible terminology guide)\
**Corresponds to:** C≡ v3.1.0, TSC Core v3.2.0, TSC Operational v3.2.1, TSC Observation Dynamics v1.0.13\
**Changelog:** `CHANGELOG.md` § Spec releases

______________________________________________________________________

## How to Read This Glossary

This isn't a dictionary—it's a guide to understanding. Each entry unfolds from **intuition** (what it feels like) through **practical use** (how to work with it) to **mathematical precision** (what it formally means). Start wherever makes sense for you.

**If you're learning TSC:** Read straight through. Each concept builds on the previous ones.

**If you're implementing:** Look for the "When you implement" sections—they connect theory to practice.

**If you're verifying proofs:** The mathematical definitions link directly to the specifications.

**If you're asking "why does this matter?":** The philosophical grounding shows how each piece connects to the whole.

______________________________________________________________________

## Part I: The Foundation (What We're Measuring)

### Wholeness

Imagine silence. Not the absence of sound—the wholeness before any sound begins. That's what we mean by **wholeness** in C≡. It's the unarticulated, indivisible ground from which all distinction emerges.

In the formal language, we write this as **e** (for "empty" or "undifferentiated"). But wholeness isn't nothing—it's everything before it articulates itself into particular things. It's like the blank page before the first word, the stillness before the first breath.

**Why this matters:** Every measurement starts here. When you compute coherence, you're measuring how far a system is from this perfect, unarticulated wholeness. A score of 1.0 means "still wholly itself, undifferentiated." As articulation increases—as the system becomes more complex, more differentiated—the score drops.

**In the mathematics:** The term `e` satisfies the equivalence `e ~ tri(e,e,e)`. This says: when all three positions see only wholeness (no distinction has been made), the structure dissolves back into pure wholeness. It's not a collapse—it's recognition that nothing was actually articulated. (See C≡ §2.2)

**When you implement:** The normal form function `nf` returns `e` whenever it encounters `tri(e,e,e)`. You're recognizing: "No atom is present here; this is just wholeness." This isn't an optimization trick—it's the mathematics telling you something true about the structure.

______________________________________________________________________

### Atom (The Act of Articulation)

Now imagine that first breath. Not two separate things—"inside air" and "outside air"—but **one breath articulating as two aspects**. The inhale and exhale are distinguishable, but you can't separate them and still have breathing. This is what we mean by an **atom**: not a thing, but the **one-as-two** pattern.

An atom is wholeness articulating itself as unity-as-duality. It's indivisible—you can't break it into parts—but it shows two faces. The coherer and the cohered are one happening seen from two sides.

Think about the word "cohering" itself. There's the one who coheres (agent) and what is cohered (patient). Can you separate them? Not really—they're two aspects of one process. That's the atom: one-as-two.

**The set of atoms** is written **𝔄** (a fancy A). Each element `a ∈ 𝔄` represents one instance of this one-as-two articulation. In the TSC specs themselves, atoms are the definitions, axioms, and formulas—each one a moment where wholeness articulates itself into a particular distinction.

**Why this matters:** Atoms are what you count, what you measure. When you compute `⟦t⟧_α`, you're counting how many times wholeness has articulated as one-as-two. When you compute `⟦t⟧_γ`, you're measuring how deeply these articulations nest within themselves.

**The philosophical depth:** This is Bohm's resolution to the paradox of limitation. Is limitation itself limited or unlimited? Both answers create problems. Bohm's insight: **Limitation is the unlimited limiting itself**—not a thing (limited or unlimited), but a movement. The Unlimited doesn't "become" limited—it **limits itself** while remaining unlimited. The atom is the movement of this self-limitation. (See C≡ §7)

**When you implement:** In self-measurement, you parse spec documents to extract atoms. Each definition, each axiom, each theorem is an articulation—a place where wholeness has made itself explicit.

______________________________________________________________________

### Triadic Term (Holding One-as-Two)

Here's the puzzle: how do you hold **one-as-two** without it collapsing back to one or fragmenting into separate two?

**The answer: three positions.**

Think of it like this. With **one position**, you have only undifferentiated wholeness—no duality can appear. There's nothing to distinguish yet.

With **two positions**, you can show the duality (left/right, inside/outside). But here's the problem: the unity is lost. It looks like two separate things. The indivisibility breaks. You have two, not one-as-two.

But with **three positions**, something remarkable happens. You can hold:

- **Left and Right** carrying the duality (the two aspects)
- **Center** carrying the unity (the one-ness that both are)

Together, they preserve **one-as-two** without collapse or fragmentation. It's like a three-legged stool—remove any leg and it falls. But with all three, it stands stable.

**The formal structure:** We write this as **tri(T₁, T₂, T₃)**—a tree with three children. This is the *only* way to build structure in C≡. Every term is either wholeness (`e`), an atom (`a`), or a triadic holding of other terms.

**The equivalence:** When all three positions see only wholeness—`tri(e,e,e)`—the structure dissolves back to `e`. This isn't a rule we impose; it's recognition that when no atom is actually present, there's nothing to hold. The three-position form was never needed because no distinction was being made. (See C≡ §2.1–2.2)

**Why triadic is minimal:** This isn't arbitrary. Two positions can't distinguish the center from the sides. In a binary tree (left/right only), you can't ask "is the center occupied?" because there is no center—only the two sides. The fundamental predicate "is unity present?" requires three positions to express. This is provable—the minimality theorem in C≡ §6 shows that no dyadic (two-position) grammar can capture center-sensitive predicates.

**When you implement:** Every input gets normalized to tri-tree structure before evaluation. You're asking: "How has this phenomenon articulated itself into one-as-two patterns, held in three-position form?"

______________________________________________________________________

### The Three Axes (Three Ways of Seeing)

Imagine looking at a sculpture. From one angle, you see its **shape** (how much material, how many pieces). From another angle, you see its **structure** (which parts connect to which). From a third angle, you see its **becoming** (how it was built, layer by layer).

These are the three axes: **α (Pattern)**, **β (Relation)**, and **γ (Process)**.

**α asks:** How many? How extensive is the articulation? It's quantitative—counting atoms, measuring extent. Think of it as the "how much" dimension.

**β asks:** Where? Which positions are occupied? It's configurational—mapping which of the three global positions (Left/Center/Right) hold atoms. Think of it as the "which places" dimension.

**γ asks:** How deep? How nested is the articulation? It's generative—measuring how articulations nest within articulations. Think of it as the "how deeply" dimension.

**Why three axes?** This isn't arbitrary either. There's a theorem (Eckmann-Hilton) that says: if you have two commutative operations on the same carrier, they must be identical. They collapse into one. So two axes can't give you genuine independence—they'd merge.

Three gives you genuine independence without redundancy. The formal proof is that they target monoids with **distinct idempotent profiles**. An idempotent is an element that equals itself when combined: x ∗ x = x. The three axes have completely different idempotent structures:

- α has idempotents exactly {0, M} (just the boundaries—nothing and everything)
- β is fully idempotent (every element equals itself when combined)
- γ has only (0,0) as idempotent (only the identity element)

These profiles are like fingerprints. No two can be isomorphic because their idempotent structures are fundamentally different. This guarantees the axes measure genuinely different things. (See C≡ §3.4, TSC Core §7.2)

**When you measure:** You provide three independent articulation functions—three ways of seeing the same phenomenon. For the TSC specs themselves, α might count definitions, β might map cross-references, γ might track version history. Same phenomenon, three views.

______________________________________________________________________

## Part II: The Operations (How We Work With Terms)

### Normal Form (Finding the Canonical State)

Imagine simplifying an expression in algebra: `(0 + x)` becomes just `x`. That's what **normal form** does for tri-terms, but with a deeper meaning.

The rule is simple: whenever you encounter `tri(e,e,e)`—all three positions seeing only wholeness—collapse it to `e`. But this isn't simplification for efficiency; it's **recognition**. When no atom is present (all positions are empty), the three-position structure was never actually articulated. It dissolves back into wholeness.

**The function nf:** Starting from any term `t`, recursively apply this contraction until nothing more can collapse. The result is unique—there's only one normal form for each equivalence class. And it's fast: O(|t|) time, O(height) space.

**Why it matters:** All evaluators run *after* normalization. You write `⟦t⟧_α = E_α(nf(t))`. First reduce to canonical form, then measure. This ensures measurements are stable—equivalent terms give identical results.

**The soundness guarantee:** For any term `t`, we have `t ~ nf(t)`. Normalization preserves equivalence—it doesn't change what the term represents. And the uniqueness guarantee: `t ~ u` if and only if `nf(t) = nf(u)`. Equivalence is decidable via normal forms. (See C≡ §2.2)

**When you implement:** Run `nf` once at the start. Don't normalize repeatedly—the function is idempotent (`nf(nf(t)) = nf(t)`). Once normalized, it stays normalized.

______________________________________________________________________

### Projections (Looking at One Position)

How do you examine what's in the **Left** position of a tri-term? You use a **projection**: **π_L** (pi-L).

But here's the key: projection isn't "taking apart." The atom is indivisible—you can't break it into pieces. Instead, projection is **focusing attention** on one aspect without destroying the unity. Like looking at one face of a coin—you're not separating the face from the coin, just focusing on it.

**The three projections:**

- π_L(tri(X,Y,Z)) = X (focus on Left)
- π_C(tri(X,Y,Z)) = Y (focus on Center)
- π_R(tri(X,Y,Z)) = Z (focus on Right)

**For atoms and wholeness:** The projections return the term itself—π_L(a) = a, π_L(e) = e. Why? Because an atom occupies all positions simultaneously until placed in a tri structure. It hasn't been "positioned" yet—it's everywhere at once in its indivisibility.

**The commutation property:** Projections play nicely with normal form: π_i(nf(t)) = nf(π_i(t)). You can project-then-normalize or normalize-then-project—same result either way. This isn't obvious (it requires a proof by structural induction), but it's essential for β to work correctly. (See C≡ §4.1)

**When you implement:** Projections are how β "sees" the global structure. To check if Left is occupied, you project to Left and check for presence: `B(π_L(t))`. We'll see B next.

______________________________________________________________________

### Presence (The Binary Question)

Sometimes you don't need details—you just need to know: **"Is there any atom here, anywhere?"**

That's what **B** does. It's a binary detector: 0 for "pure wholeness," 1 for "at least one atom present somewhere in this term."

**The definition:**

- B(e) = 0 (wholeness has no atoms)
- B(a) = 1 (atoms are presence itself)
- B(tri(X,Y,Z)) = max(B(X), B(Y), B(Z)) (presence if *any* child has presence)

**Why max, not sum?** Because we're asking a yes/no question, not counting. If any branch contains an atom—even nested deep—the whole term is "lit up" with presence. It's like asking "is anyone home?" not "how many people are home?"

**Technical note:** B is a monoid homomorphism to ({0,1}, max, 0) (a submonoid of (ℕ, max, 0)). This means it respects the compositional structure—you can compute it bottom-up in one pass. And critically: **B commutes with nf**—you get the same answer whether you normalize first or detect presence first.

**When you implement:** Compute B once on the normalized term and cache it. You'll reuse this value for all three coordinates of β. One pass, three uses.

______________________________________________________________________

### The Three Evaluators (Three Measurements)

Now we can define how to **measure** articulation. Each evaluator asks its axis's question. All are applied after normalization: `⟦t⟧_● = E_●(nf(t))`.

#### α (Pattern): How Many?

**Target:** The monoid (ℕ, ⊕, 0) where x ⊕ y = min(x+y, M) with **M ≥ 3**. Natural numbers with capped addition.

**Definition:**

- E_α(e) = 0 (wholeness has no count)
- E_α(a) = 1 (each atom counts as one)
- E_α(tri(T₁,T₂,T₃)) = E_α(T₁) ⊕ E_α(T₂) ⊕ E_α(T₃) (add up the children, capped at M)

**What it measures:** The quantitative extent of articulation. How many times has wholeness articulated as one-as-two? The cap M (typically 10 or so) prevents overflow while preserving useful distinctions. Below M, you're counting; at M, you've saturated.

**Why the cap?** Near saturation, α becomes less discriminative, which is intentional—it prevents a few very large structures from dominating the score and keeps balance across dimensions.

**Why it's homomorphic:** The operation ⊕ combines measurements the same way tri combines terms. This makes α compositional—the measurement of a whole equals the combination of measurements of parts. That's what "homomorphism" means: structure-preserving map.

**Example:** For tri(κ,κ,e) where κ is an atom, you get:

- E_α(κ) = 1
- E_α(κ) = 1
- E_α(e) = 0
- Result: 1 ⊕ 1 ⊕ 0 = min(2, M) = 2

Two atoms are present.

______________________________________________________________________

#### β (Relation): Which Positions?

**Target:** The set (ℕ³, ⊔, (0,0,0)) where ⊔ is componentwise max. Triples of natural numbers.

**But here's the key:** β is *not* defined homomorphically. It uses a different construction. Instead of recursively combining, it uses **presence-by-projection**:

**E_β(t) = (B(π_L(nf(t))), B(π_C(nf(t))), B(π_R(nf(t))))**

Read this carefully: "Take the normalized term. Project to Left, check for presence. Project to Center, check for presence. Project to Right, check for presence. Bundle the three answers into a triple."

**Base cases:**

- E_β(e) = (0,0,0) (wholeness occupies no positions—all three are empty)
- E_β(a) = (1,1,1) (an atom occupies all positions simultaneously until placed in a tri)

**What it measures:** The configurational pattern—which of the three global positions are "lit up" with atoms. It's not counting (that's α's job) but mapping presence across positions. It answers: "If I look at the top-level structure, which slots contain articulation?"

**Why it's not homomorphic:** Because we're "stepping back" to look at the whole structure's top level, not recursively combining children. We need to see the global configuration, not build it up piece by piece.

**A helpful restatement:** If nf(t) = tri(U₁,U₂,U₃), then E_β(t) = (B(U₁), B(U₂), B(U₃)). "Look at the three immediate children of the normalized term. Check each for presence." But this is a *consequence* of the definition via projections, not the definition itself.

**Example:** For tri(κ,e,κ):

Step 1: Normalize (already normal in this case)\
Step 2: Project to each position:

- π_L(tri(κ,e,κ)) = κ
- π_C(tri(κ,e,κ)) = e
- π_R(tri(κ,e,κ)) = κ

Step 3: Check presence in each projection:

- B(κ) = 1 (Left has atom)
- B(e) = 0 (Center has wholeness)
- B(κ) = 1 (Right has atom)

Step 4: Bundle into triple:\
E_β(tri(κ,e,κ)) = (1, 0, 1)

Result: (1,0,1) — Left and Right global positions are occupied, Center is not.

**Why this is cleaner than it sounds:** We're just looking directly at what's in each position. No complicated recursion, no coordinate shuffling. Just: "Look left. Look center. Look right. What's there?"

______________________________________________________________________

#### γ (Process): How Deep?

**Target:** The monoid (ℕ×ℕ, ⊗, (0,0)) where (x,u) ⊗ (y,v) = (x+y, u⊙v) and u⊙v = (u+1)(v+1) - 1. Pairs of natural numbers with a special combination operation.

**Definition:**

- E_γ(e) = (0,0) (no articulation)
- E_γ(a) = (1,1) (one atom, depth 1)
- E_γ(tri(T₁,T₂,T₃)) = E_γ(T₁) ⊗ E_γ(T₂) ⊗ E_γ(T₃)

**What it measures:**

- First component: count of atoms (like α, but uncapped—it keeps growing)
- Second component: **depth of nested articulation**—how deeply the atom nests within itself

**The magic of ⊙:** The operation u⊙v = u+v+uv looks strange until you realize it's isomorphic to multiplication. Via the mapping u ↦ u+1, we get: u⊙v = (u+1)(v+1) - 1. *(The two forms are algebraically equivalent.)*

So u⊙v is really just multiplication in disguise. This makes it associative and commutative, which is why ⊗ is also associative and commutative.

**Why multiplication captures nesting:** When articulations nest, their depths multiply—not because we decided this arbitrarily, but because that's the pattern of how one-as-two articulates within one-as-two. Each level of nesting multiplies the complexity. The second component grows exponentially with nesting depth.

**Example:** For tri(κ,κ,e):

Step 1: Evaluate each child:

- E_γ(κ) = (1,1)
- E_γ(κ) = (1,1)
- E_γ(e) = (0,0)

Step 2: Combine first two with ⊗:

- (1,1) ⊗ (1,1) = (1+1, 1⊙1)
- = (2, 1+1+1·1)
- = (2, 3)

Step 3: Combine with third:

- (2,3) ⊗ (0,0) = (2+0, 3⊙0)
- = (2, 3+0+3·0)
- = (2, 3)

Result: (2, 3)

First component: 2 atoms present.\
Second component: 3—showing depth of process articulation. Not just "two atoms," but how they articulate in relation. The multiplication (via ⊙) captures the compounding depth.

______________________________________________________________________

**The normalization identity:** All three evaluators satisfy **E\_●(nf(t)) = E\_●(t)**—they commute with normalization. This means you don't need to normalize inside recursive calls; normalizing once at the start is sufficient. (See C≡ §4.1 for projection/normalization commutation and §5 for monotonicity and score axioms.)

______________________________________________________________________

### Gauge Symmetry (No Privileged Direction)

Here's a question: Does wholeness have a "preferred direction" when it articulates? When it becomes one-as-two held in three positions, does it care which position is "Left" versus "Right"?

No. The labels "Left," "Center," "Right" are our convention, not intrinsic to the pattern. This is **gauge symmetry**—like choosing coordinates on a sphere. The sphere doesn't care which way is "north."

**The S₃ action:** For any permutation σ of {1,2,3}, define:

- σ·e = e (wholeness is unchanged)
- σ·a = a (atoms are unchanged)
- σ·tri(T₁,T₂,T₃) = tri(T\_{σ(1)}, T\_{σ(2)}, T\_{σ(3)}) (permute the children)

This swaps the position labels. And it commutes with normalization: nf(σ·t) = σ·nf(t). Swapping labels doesn't change the essential structure—it's just relabeling.

**How evaluators respond:**

**α and γ are invariant:** E_α(σ·t) = E_α(t), E_γ(σ·t) = E_γ(t). They don't care about position order because their operations (⊕ and ⊗) are commutative. Add in any order, multiply in any order—same result.

**β is equivariant:** E_β(σ·t) = P_σ(E_β(t)). If you permute the term, the coordinates permute correspondingly. β *does* see positions (that's its job), but it sees them symmetrically—no position is privileged.

**Why this matters:** When you define coherence scores, you must respect this symmetry. The multiset {s_α, s_β, s_γ} must be preserved under permutation—no axis can be privileged. This is why axiom (P3) uses "multiset" (unordered collection) rather than "tuple" (ordered). (See C≡ §4.2–4.3)

**When you implement:** This becomes Witness W1—the axis-permutation test. Try all 6 permutations of the axes and verify you get the same aggregate coherence. If you don't, your implementation has hidden bias for one axis.

______________________________________________________________________

### Disruption (Returning to Source)

Imagine erasing a word from a sentence. You're removing articulation, returning that space to blank paper. The sentence becomes less articulated, closer to the empty page.

That's **disruption**: replacing an atom with wholeness, written `a → e`. It's the reverse of articulation—returning differentiation back to the undifferentiated source.

**Formally:** Write t ⤳ u ("t disrupts to u") if there's a context 𝒞 and a term v such that t = 𝒞[v] and u = nf(𝒞[e]). You've found some subterm v in t, replaced it with wholeness e, and normalized the result to get u.

**The preorder:** Define t ⪰ u ("t is at least as articulated as u") as the reflexive-transitive closure. If you can get from t to u by a sequence of disruptions, then t is "more articulated" than u. It's further from wholeness.

**The key theorem (Evaluator Monotonicity):** If t ⤳ u, then:

- ⟦t⟧\_α ≥ ⟦u⟧\_α (counts go down)
- ⟦t⟧\_β ≥ ⟦u⟧\_β (configuration simplifies, componentwise)
- ⟦t⟧\_γ ≥ ⟦u⟧\_γ (depth and count go down, product order)

Disruption **decreases** evaluation. Articulation goes down when you return atoms to wholeness. This is proven by examining what happens when you replace any subterm with (0,0,0) or 0—the result can only go down or stay the same. (Proven in C≡ §5.0)

**Why this matters for coherence:** This justifies the score axiom (P4′): disruption-antitone means s_i(t) ≤ s_i(u) when t ⪰ u. As you remove articulation, scores **rise** toward the perfect score of 1.0 at pure wholeness e. Why? Because perfect wholeness (e) scores 1.0 (axiom P1), and every disruption moves you closer to e. Coherence increases as you approach the source.

______________________________________________________________________

## Part III: Measurement (How We Use This to Measure Systems)

### Articulation (Getting Data)

Now we connect the abstract algebra to real systems. How do you take something like "the TSC specification" and turn it into terms that can be evaluated?

**Articulation** is the function that takes a term (representing a phenomenon) and produces **observations**—actual data you can measure.

**Formally:** For each axis a, you define A_a: T → 𝒫(Ω_a). This maps from terms to sets of observations in some context space Ω_a. The image O_a = A_a(C) is a finite set—your actual data points.

**The unity principle:** The three articulations A_α(C), A_β(C), A_γ(C) are three views of the **same** process C. You're not measuring three different things; you're measuring one thing three ways. The phenomenon is one; the views are three.

**In practice, for TSC self-measurement:**

- A_α might extract all section headers, definitions, theorem statements (structural features)
- A_β might extract all cross-references, citations, dependencies (relational graph)
- A_γ might extract commit history, version diffs, temporal evolution (process traces)

Same corpus (the TSC specs), three articulation functions, three observation sets.

**When you implement:** This is where domain knowledge enters. You design three reliable data capture functions. What counts as an "observation" depends on your phenomenon. For code: functions, modules, call graphs, execution traces. For documents: sections, citations, versions. For systems: states, transitions, histories.

Document your articulation schemas carefully—they go in the provenance bundle. Someone else should be able to reproduce your exact observation sets given your articulation functions.

______________________________________________________________________

### Summary (Compressing for Comparison)

Raw observations are too rich to compare directly. How do you compare a set of section headers to a dependency graph? You need a common representation.

So we **compress** observations into summaries—finite descriptions that capture what matters for comparison.

**A summary** S_a = (d_a, p_a, ℋ_a, ℐ_a) consists of four components:

**d_a: representative dimension.** How many degrees of freedom does this observation set have? Use PCA, manifold learning, or other dimension estimation techniques. This gives you a single number that captures the "size" of the space.

**p_a: probability distribution over features.** What's the statistical pattern? Histogram of feature values, kernel density estimate, whatever lets you describe "where the mass is" in observation space.

**ℋ_a: Shannon entropy.** How dispersed is the distribution? High entropy = spread out, low entropy = concentrated. This single number captures distributional shape.

**ℐ_a: detected invariants.** What structure is stable? Symmetries, conserved quantities, patterns that don't change under transformations. These are the structural fingerprints.

**Why summarize?** Because we need to **align** summaries across axes—compare structure to relations, relations to process. Raw observations aren't directly comparable (different types, different spaces), but compressed summaries are. They're all tuples of (dimension, distribution, entropy, invariants).

**The measurement stance:** Summaries don't claim to "capture" the phenomenon completely. They're finite descriptions adequate for comparison within a measurement context. We're not trying to reconstruct everything—just extract enough to assess coherence.

**When you implement:** Make summary construction deterministic wherever possible. Randomness in summarization (like random seeds in dimension reduction) inflates your confidence intervals unnecessarily. If you must use randomness, include the seed in provenance so results are reproducible. (See TSC Core §1, §12)

______________________________________________________________________

### Alignment (Comparing Different Views)

Here's the challenge: How do you compare an α summary (structural statistics: dimension 47, entropy 3.2) to a β summary (relational graph: dimension 152, entropy 5.8)?

They're in different spaces. Different dimensions. Different representations. How do you say "these cohere" or "these don't"?

**Answer: Alignment.** An alignment σ is a correspondence method—a way to map between the two representations. Think of it like translation between languages. The alignment establishes which parts of one summary "match" which parts of the other.

**Methods include:**

- Optimal Transport (move probability mass from one distribution to another at minimum cost)
- Gromov-Wasserstein (compare metric spaces even when point sets differ)
- Graph matching (align structural patterns)
- And more—the key is having multiple heterogeneous methods

**The normalized discrepancy:**

```
δ(S_a, S_b; σ) = θ · δ_struct + (1-θ) · δ_dist
```

Part structural (comparing dimensions d_a vs d_b and invariants ℐ_a vs ℐ_b), part distributional (comparing probability distributions p_a vs p_b). The parameter θ (default 0.7) weights how much you care about structural match versus statistical match.

Both components are normalized to [0,1]. A discrepancy of 0 means perfect match (the two summaries are identical under alignment σ). A discrepancy of 1 means complete mismatch (they share nothing).

Bounded δ matters: it preserves comparability across heterogeneous alignment methods, supports scale-equivariance (W3), and keeps the dependence-aware ledgers in tsc-observation-dynamics finite.

**The barrier transform (why bounded δ doesn't trap us at a coherence floor):**

A bounded δ ∈ [0,1] cannot, on its own, send coherence to a strict zero through `exp(−λ·δ)` — the best you ever achieve is `exp(−λ)`. That makes λ do double duty (sensitivity *and* floor), which is semantic overload.

Resolution: pass δ through a monotone barrier function φ: [0,1] → [0,∞] before exponentiating:

```
φ(0) = 0
lim{δ → 1⁻} φ(δ) = +∞
```

Canonical default: `φ(δ) = δ / (1 − δ)`, with `φ(1) = +∞` by convention.

**Discrepancy energy and coherence:**

```
D(S_a, S_b; σ) = λ_ab · φ(δ(S_a, S_b; σ))      D ∈ [0, ∞]
Coh(S_a, S_b; σ) = exp(−D(S_a, S_b; σ))         (with exp(−∞) = 0)
```

Now δ ∈ [0,1] cleanly carries the *duality* (the discernible mismatch between Left and Right material aspects), while D ∈ [0,∞] carries the *unity-collapse* limit: complete relational loss requires infinite energy to sustain, and that limit is exactly where Coh becomes strictly zero.

Crucially, λ_ab is purely a *sensitivity* parameter — it scales the energy curve, it does not set a floor. Coh = 0 if and only if δ = 1.

**The ensemble approach:** Don't trust one alignment method. Different methods make different assumptions. Build an ensemble 𝒜_ab with at least 3 heterogeneous methods. For each method σ in the ensemble, compute Coh(S_a, S_b; σ). Then:

**Mean coherence:** ⟨Coh⟩\_{ab} = average across the ensemble. This is your best estimate.

**Variance:** Var\_{ab} = variance across the ensemble. This is a witness—if variance is too high, the methods disagree too much. The comparison is unstable. You can't trust the mean.

Low variance = ensemble agreement = stable comparison = trustworthy coherence.\
High variance = ensemble disagreement = unstable comparison = don't trust the number.

(See TSC Core §3)

______________________________________________________________________

### Coherence Scores (From Evaluators to Measurements)

Now we connect evaluators (mathematical objects operating on terms) to scores (measurement values we report for systems).

**The score functions** s_α, s_β, s_γ: T/~ → [0,1] must satisfy four axioms:

**(P1) Perfect wholeness:** s_i(e) = 1. The unarticulated source scores perfectly. This makes sense: wholeness is the standard of coherence. Pure, undifferentiated wholeness has perfect coherence because nothing has differentiated to potentially conflict.

**(P2) Bounded:** 0 ≤ s_i ≤ 1. Scores are normalized. 1 is perfect, 0 is complete incoherence (or complete articulation, depending on interpretation).

**(P3) S₃-invariant:** The multiset {s_α(t), s_β(t), s_γ(t)} is preserved under gauge permutations. No axis is privileged. If you permute positions, the scores might individually permute (because β is equivariant), but the *set* of scores remains the same.

**(P4′) Disruption-antitone:** If t ⪰ u (t can disrupt to u), then s_i(t) ≤ s_i(u). Removing articulation raises scores toward the perfect 1.0 at wholeness e. More articulation = lower score (further from wholeness). Less articulation = higher score (closer to wholeness).

**The witness family (one simple construction that works):**

```
s_α(t) = 1/(1 + ⟦t⟧_α)
s_β(t) = 1/(1 + b_L + b_C + b_R)  where ⟦t⟧_β = (b_L, b_C, b_R)
s_γ(t) = 1/(1 + g_1 + g_2)  where ⟦t⟧_γ = (g_1, g_2)
```

**Why this works:** As evaluators increase (more articulation), denominators grow, scores decrease. As evaluators approach 0 (approaching wholeness), scores approach 1. The axiom checks:

- (P1): ⟦e⟧ = 0 for all evaluators, so s_i(e) = 1/(1+0) = 1 ✓
- (P2): Always positive, always ≤ 1 ✓
- (P3): β sums all coordinates (symmetric), α and γ are S₃-invariant ✓
- (P4′): Evaluators decrease under disruption (§5.0), so scores increase ✓

(See C≡ §5.2–5.3)

**Operational defaults vs. witness family.** In **TSC Core §4**, the operational score definitions are the defaults used in practice:

- **s_α** via perturbation stability (exponential of a distance),
- **s_β** via the **geometric mean of pairwise coherences** (built from **⟨Coh⟩\_{αβ}**, **⟨Coh⟩\_{βγ}**, **⟨Coh⟩\_{γα}**),
- **s_γ** via 1-Wasserstein temporal stability.

The **witness family** above exists to prove the axioms are satisfiable and to offer a simple sanity check; it is not the operational default **unless explicitly chosen and recorded in provenance**.

**When you implement:** You can use other transforms (exponential decay, power law, logistic) as long as they're monotone decreasing and respect S₃ symmetry. The witness family is just one option—simple and provably correct. Record your choice in provenance.

______________________________________________________________________

### Aggregate Coherence (The Final Verdict Input)

Three scores, one number: **C_Σ**. But to keep the mathematics honest *and* the computer happy, we maintain two compatible forms.

**Mathematical (normative — for proofs):**

```
C_Σ^math = (s_α · s_β · s_γ)^(1/3)
```

**Numerical (operational — for computation, CI, OOD, verdict):**

```
C_Σ^num = exp((1/3)(w_α ln(max(s_α, ε)) + w_β ln(max(s_β, ε)) + w_γ ln(max(s_γ, ε))))
```

When all three scores are at or above the floor ε, the two forms coincide exactly. They diverge **only** when at least one score is below ε.

This split exists for one reason: the math wants `s_i = 0 ⟹ C_Σ = 0` to be a strict, provable property (Degeneracy Axiom from C≡ §5.4). The computer wants no `log(0) = −∞`. Splitting the definitions lets both win — the spec proves things about C_Σ^math, the implementation computes C_Σ^num, and provenance records `zero_component_present` whenever the two would diverge.

Either way, the formula is still the **geometric mean**—the cube root of the product. Not the arithmetic mean (average), not the maximum, not the minimum. The geometric mean.

**Why geometric mean?** Because of the **Degeneracy Guard**: If any score is 0, the aggregate is 0. The product of anything with 0 is 0. The cube root of 0 is 0. You cannot compensate failure in one dimension with success in others.

Think about it with numbers:

- Arithmetic mean: (0.9 + 0.9 + 0.0) / 3 = 0.6 — this says "one dimension failed completely, but we're 60% coherent"
- Geometric mean: (0.9 × 0.9 × 0.0)^(1/3) = 0 — this says "one dimension failed, so overall coherence is zero"

The geometric mean is honest. The three-legged stool must have all three legs. Coherence requires all three dimensions. Lose any one and you lose coherence entirely.

**The weighted form:** If you need to emphasize one axis more than others, use:

```
C_Σ = exp((1/3)(w_α ln s_α + w_β ln s_β + w_γ ln s_γ))
```

with weights w_α, w_β, w_γ > 0 summing to 3. This is the weighted geometric mean in log space. Default: all weights = 1 (equal emphasis).

**Properties:**

- **S₃-invariant:** Multiplication commutes, so permuting axes doesn't change the product
- **Disruption-antitone:** Follows from axiom (P4′) for each score and monotonicity of products and cube roots
- **Degeneracy guard:** Any factor = 0 ⟹ product = 0

**When you implement:** Compute C_Σ^num for all numerical work (CI, OOD, verdict). Always record `numeric_floor_applied`, `epsilon`, and `zero_component_present` in provenance whenever any s_i < ε. The `zero_component_present` flag is what the verdict layer reads to enforce the strict mathematical degeneracy: when true, the verdict treats C_Σ^math = 0 as a coherence-threshold FAIL (not a witness FAIL_DEGENERATE). (See TSC Core §5, Operational §5)

______________________________________________________________________

### Leverage (Diagnosing Incoherence)

Coherence is multiplicative (via geometric mean), which makes it hard to see contributions. If C_Σ = 0.45, which dimension is the problem? Hard to say from the product.

**Leverage** transforms coherence into an additive diagnostic. It's the "incoherence energy"—how much each dimension contributes to lowering coherence.

**The transformation:**

```
λ_a = -ln(max(s_a, ε))
```

This is the negative log of the score. Higher leverage = lower coherence. And it's additive:

```
λ_Σ = (1/3)(λ_α + λ_β + λ_γ)
```

**The Coherence-Energy Duality:**

```
E_Σ = -(1/3)(ln s_α + ln s_β + ln s_γ) = λ_Σ
```

Minimizing leverage ⟺ maximizing coherence. It's like potential energy in physics—high leverage is high "incoherence potential" waiting to be resolved.

**The diagnostic use:** Look at which dimension has the highest leverage:

```
argmax{λ_α, λ_β, λ_γ}
```

That's your bottleneck. That's where the incoherence is concentrated. Route your improvement effort there.

**Example:** Suppose:

- s_α = 0.82 → λ_α = -ln(0.82) ≈ 0.20
- s_β = 0.22 → λ_β = -ln(0.22) ≈ 1.51
- s_γ = 0.74 → λ_γ = -ln(0.74) ≈ 0.30

The β dimension (relation) has leverage 1.51—seven times higher than α. That's the problem. The relations don't cohere. Fix cross-references, strengthen dependencies, clarify connections. That's where to push.

(See TSC Core §11)

______________________________________________________________________

### Confidence Intervals (Uncertainty Quantification)

Every measurement has uncertainty. Every score is an estimate. We quantify this via **bootstrap confidence intervals**.

**The procedure:**

1. **Resample your observations:** Draw N_boot samples (typically 1000) with replacement from your observation indices. If observations are temporally correlated, use block bootstrap (resample blocks of size ≥10 instead of individual points).

1. **Resample your alignment ensemble:** For each bootstrap sample, randomly select which alignment methods to use (sampling with replacement from your ensemble).

1. **Recompute C_Σ:** For each bootstrap sample, recompute summaries, alignments, scores, and aggregate. You now have 1000 C_Σ values.

1. **Report percentiles:** The 2.5th and 97.5th percentiles give you [CI_lo, CI_hi] at 95% confidence level. The middle 95% of your bootstrap distribution.

**Why bootstrap?** Because alignment and summary construction are complex, nonlinear operations. Analytical confidence intervals (based on formulas) would require distributional assumptions we can't justify. Bootstrap is non-parametric—it makes minimal assumptions—and it's robust to weird distributions.

**How to interpret:**

- If **CI_lo(C_Σ) ≥ Θ** (threshold), you have evidence of coherence even accounting for measurement noise. PASS.
- If **CI_hi(C_Σ) < Θ**, you have evidence of incoherence even with optimistic noise estimates. FAIL.
- If the interval **straddles Θ**, the evidence is inconclusive. Collect more data or tighten your measurement process.

**When you implement:** Always report confidence intervals. A point estimate without uncertainty is just a guess. And include the bootstrap seed in provenance so results are exactly reproducible. (See TSC Core §6)

______________________________________________________________________

### Out-of-Distribution Detection (Context Stability)

Measurements have context. You're measuring in some regime—some set of conditions, some parameter settings, some measurement procedures. What if that context shifts?

**OOD (out-of-distribution) detection** tracks whether your current measurement looks like past measurements. If it doesn't, something changed—maybe the system evolved, maybe the measurement process drifted, maybe you recalibrated without realizing.

**The statistic:** Compute a robust z-score against a rolling reference distribution (e.g., last 20 verifications):

```
Z_t = |C_Σ^(t) - median(ref)| / (1.4826 · MAD(ref))
```

where MAD is median absolute deviation: the median of |x - median(ref)| across all reference values.

**Why this formula?** The factor 1.4826 scales MAD to estimate standard deviation for normal distributions. But MAD is robust to outliers (unlike standard deviation), so this statistic is stable even if a few past measurements were anomalous.

**The test:** If Z_t ≥ Z_crit (default 2.5, ≈ two-sided 99% threshold for normal distributions), flag as out-of-distribution. The current measurement is unusually far from the historical pattern.

**What it means:**

**Not a witness failure:** OOD doesn't trigger FAIL_DEGENERATE (measurement isn't broken in the usual sense).

**But a PASS condition:** If OOD is flagged, the verdict is FAIL (not PASS). You don't have stable context (Operational §5).

**An investigation trigger:** Find out what changed. Did the system genuinely evolve? Did you recalibrate parameters? Did the measurement procedure drift? Decide whether to:

- **Recalibrate:** If context legitimately shifted, acknowledge it and start a new measurement epoch with new reference distribution.
- **Fix the problem:** If it's a bug or unintended drift, fix it and remeasure.

**When you implement:** Maintain the rolling reference distribution. When OOD fires, don't ignore it and don't panic. Investigate, understand the cause, make an informed decision. (See TSC Core §6, Operational §5)

______________________________________________________________________

## Part IV: Protocol (How We Ensure Measurement Validity)

### The Witness Suite (Degeneracy Guards)

Before trusting C_Σ, we test whether the **measurement itself is valid**. These are the witnesses—safety checks that detect when the math breaks down.

Think of witnesses like checking your thermometer before trusting the temperature reading. If the thermometer is broken, the reading is meaningless no matter what number it shows.

______________________________________________________________________

#### W1: S₃ Permutation (Mathematical Symmetry)

**What it tests:** Do you get the same C_Σ when you permute axis assignments?

**The procedure:** Compute C_Σ(O_α, O_β, O_γ) for all 6 permutations of {α,β,γ}. That means:

- Original: (α,β,γ)
- Swap α↔β: (β,α,γ)
- Swap α↔γ: (γ,β,α)
- Swap β↔γ: (α,γ,β)
- Cycle forward: (β,γ,α)
- Cycle backward: (γ,α,β)

Measure the maximum absolute difference across all 6 results.

**The threshold:** τ_S3 ≈ 0.05. If max difference > 0.05, the witness fails.

**If it fails:** Your implementation has privilege for one axis. Maybe you're using axis labels in the computation instead of treating them symmetrically. This is a bug—fix it before trusting results. The mathematics guarantees S₃ invariance; if your code doesn't show it, your code is wrong. (See TSC Operational §2)

______________________________________________________________________

#### W2: Gauge Independence (Computational Symmetry)

**What it tests:** Do you get the same C_Σ when you strip axis labels and auto-discover them — *and* you can't hide gauge dependence by cherry-picking the most flattering permutation?

**The procedure (two signals):**

1. Remove all axis labels from your observations and apply a *deterministic* canonical remap (e.g., lexicographic ordering of structural fingerprints) to assign observations to axes. Compare the resulting C_Σ to the labeled version. Difference = `w_gauge_ref`.
2. For all 6 permutations π ∈ S₃ of the unlabeled remap, compute C_Σ. The spread (max − min) is `w_gauge_spread`.

```
w_gauge_ref    = |C_Σ(labeled) − C_Σ(unlabeled, canonical-remap)|
w_gauge_spread = max{C_Σ(unlabeled, π·remap)} − min{C_Σ(unlabeled, π·remap)}
```

**The thresholds:**

- `w_gauge_ref ≤ τ_gauge` (default 0.05)
- `w_gauge_spread ≤ τ_gauge_spread` (default = τ_gauge)

**Why two signals?** Pre-v3.2.0 W2 took `max{π}` of the unlabeled C_Σ — that lets an implementation hide gauge dependence by selecting whichever π matches the labeled value best. The spread test closes that loophole: a label-blind implementation must agree across *all* permutations, not just the lucky one.

**If it fails:** If only `w_gauge_ref` fails — your canonical remap doesn't recover the labeled assignment; your structure detection is biased. If only `w_gauge_spread` fails — your implementation is sensitive to which permutation it lands on; the labels are leaking through somewhere. Either way: implementation bug — fix it.

**Note:** W1 tests mathematical invariance (permute and recompute). W2 tests computational invariance (can you rediscover the structure from scratch *and* be permutation-blind). Both are required. (See TSC Operational §2)

______________________________________________________________________

#### W3: Scale Equivariance (Dimensional Consistency)

**What it tests:** Does uniform scaling preserve coherence?

**The procedure:** Apply a uniform scale transform ψ (e.g., multiply all feature values by 2). Recompute C_Σ on the scaled observations. Measure the difference from the original. (Note: ψ denotes the W3 scale map; the barrier transform φ in Core §3.2 is a different object.)

**The threshold:** τ_scale ≈ 0.10.

**If it fails:** Your measurement has dimensional inconsistency. Maybe you're comparing apples (meters) to oranges (seconds) without proper normalization. Either:

- **Normalize properly:** Scale to unit variance or standard ranges
- **Apply calibration maps:** Transform to dimensionless quantities

Then retry. If it still fails, your normalized discrepancy δ isn't scale-equivariant. Review Core §3. (See TSC Operational §2)

______________________________________________________________________

#### W4: Stability (Ensemble Agreement + Contraction)

**What it tests:** Two things:

1. Does your alignment ensemble agree?
1. Do summary updates converge to a fixed point?

**The variance test:** For each pair (a,b), compute Var\_{ab} across the alignment ensemble. If max{Var\_{αβ}, Var\_{βγ}, Var\_{γα}} > τ_var (≈0.15), variance is too high.

**What high variance means:** Your alignment methods disagree too much. They're producing wildly different coherence estimates. The comparison is unstable—you can't trust the mean. Either:

- Use more similar methods (reduce diversity)
- Or collect more data (sometimes variance drops with larger sample)

**The Lipschitz test:** Compute κ = L_sum · L_align · max{L_link(λ\_{αβ}), L_link(λ\_{βγ}), L_link(λ\_{γα})}, where L_link is the link-Lipschitz constant for the barrier+exponential coherence map (Core §7.1). For the canonical barrier φ(δ) = δ/(1−δ): L_link(λ) = (4/λ)·exp(λ−2) when λ ≤ 2, and L_link(λ) = λ when λ ≥ 2. Pre-v3.2.0 specs used max{λ} directly, which underestimates the Lipschitz envelope when λ < 2.

**Pass rule:** κ ≤ τ_lip with default τ_lip = 0.95 (a safety margin strictly below 1).

**Interpretation:** κ ≪ τ_lip ⇒ strong contraction; κ ≲ τ_lip ⇒ fragile stability; κ > τ_lip ⇒ risk of divergence.

**What this means:** The iterative refinement T: (S_α, S_β, S_γ) → (T_α(S_β,S_γ), ...) requires κ ≤ τ_lip for guaranteed convergence to a unique fixed point. If κ > τ_lip, your measurements won't converge to stable mutual coherence. Either:

- Lower sensitivity parameters λ (reduce reaction strength)
- Or tighten Lipschitz bounds (make operations smoother)

**The thresholds:** τ_var ≈ 0.15, τ_lip = 0.95 (default).

**If it fails:** This is a calibration issue, not a fundamental problem. Tune your parameters and retry. (See TSC Operational §2, Core §7)

______________________________________________________________________

**Why witnesses exist:** Because coherence scores can be high even when the measurement process is broken. You could have C_Σ = 0.85 but W1 fails (not actually symmetric), and the 0.85 is meaningless. Witnesses detect the breakage.

**The verdict rule:** Any witness failure → FAIL_DEGENERATE, meaning "don't interpret the C_Σ value at all; something's wrong with the measurement itself."

______________________________________________________________________

### Verdict (The Final Decision)

Three possible outcomes: **PASS**, **FAIL**, or **FAIL_DEGENERATE**.

**PASS requires all of:**

1. **CI_lo(C_Σ) ≥ Θ** where Θ is the threshold (default **0.75**). The lower bound of your confidence interval must exceed the bar. This means even with pessimistic uncertainty estimates, you're above threshold.

1. **All witnesses (W1–W4) pass** their thresholds. The measurement process is valid.

1. **CI_hi - CI_lo ≤ δ_CI** where δ_CI is the precision requirement (default 0.20). Your confidence interval must be tight enough. Too much uncertainty and you can't make a reliable verdict.

1. **OOD stable:** Z_t < Z_crit. The measurement context hasn't shifted dramatically from historical patterns.

If all four conditions hold, the verdict is **PASS**. The system coheres by TSC's standards.

**FAIL means:** One of conditions 1, 3, or 4 failed. Three scenarios:

- **Low coherence:** CI_lo < Θ (condition 1) — the system doesn't cohere enough
- **Poor precision:** CI width > δ_CI (condition 3) — collect more data or tighten measurement
- **Context shift:** OOD flagged (condition 4) — investigate what changed

This is **interpretable**. You can see which condition failed and work on that specific issue.

**FAIL_DEGENERATE means:** Condition 2 failed (a witness). The measurement process itself is broken. This is **not interpretable**—you can't trust the C_Σ value at all, regardless of what number it shows.

Don't try to "fix the system" when you get FAIL_DEGENERATE. Fix the **measurement**: investigate the witness failure, repair your implementation or recalibrate parameters, then retry.

**About the threshold:** The normative default is **Θ = 0.75**. For self-application (TSC measuring itself) or safety-critical deployments, teams may choose a stricter threshold like 0.90. This is a **policy override**, not a change to the baseline. Document any override in provenance.

**Fail-fast principle:** Check conditions in order (1, 2, 3, 4). Log the first failure as the verdict cause. Don't compute everything just to say "multiple failures"—save time and give clear diagnosis. (See TSC Operational §5)

______________________________________________________________________

### Provenance Bundle (Reproducibility Record)

Science requires reproducibility. The **provenance bundle** is everything someone needs to exactly recreate your C_Σ measurement.

Without provenance, TSC measurements are just mysticism with equations. With complete provenance, anyone can verify your work, challenge your choices, and reproduce your results bit-for-bit.

**What must be included:**

**Parameters:** Every tunable knob:

- θ (structural vs distributional weight)
- λ_a for each axis (dimensional sensitivities)
- λ_ab for each pair (pairwise sensitivities)
- ε (numerical floor)
- Θ (decision threshold—and note if overridden from default)
- All τ\_\* (witness thresholds)
- δ_CI (CI width tolerance)
- Z_crit (OOD cutoff)

**Computation specifications:**

- Alignment methods: which algorithms, which parameters, which implementations
- Summary schemas: exact construction procedure for (d,p,ℋ,ℐ)
- Bootstrap configuration: random seed, N_boot (sample count), block size (if block bootstrap)
- CI level (e.g., 95%)

**Results (the numbers):**

- All dimensional scores: s_α, s_β, s_γ
- Aggregate: C_Σ
- Confidence intervals: [CI_lo, CI_hi]
- All pairwise coherences: ⟨Coh⟩_{αβ}, ⟨Coh⟩_{βγ}, ⟨Coh⟩\_{γα}
- All variances: Var\_{αβ}, Var\_{βγ}, Var\_{γα}
- All leverages: λ_α, λ_β, λ_γ, λ_Σ
- All witness signals: actual values for W1-W4 tests

**Calibration data:**

- Lipschitz constants: L_sum, L_align
- Contraction scalar: κ
- Scale calibration maps (if applied)
- Ground metrics for Wasserstein distances

**Verdict information:**

- Controller state sequence (HANDSHAKE → MEASURE → WITNESS → VERDICT)
- Pass/fail per witness (which ones passed, which failed)
- Final verdict: PASS, FAIL, or FAIL_DEGENERATE
- Failure cause (if any): which condition failed
- Timestamp
- Software versions
- Git commit hashes for all code
- Artifact checksums (for observation files)

**Format requirements:**

- JSON or YAML (machine-readable, structured)
- Schema validation (verify completeness)
- Human-readable is bonus but not required

**Wire format note:** In JSON/YAML, use ASCII keys: `s_alpha`, `s_beta`, `s_gamma` (not Unicode subscripts). For ensemble mean coherences, use `coh_ens_ab` or similar. This avoids encoding issues. Typeset documents can use the prettier s_α and ⟨Coh⟩ notation.

**Why this matters:** This isn't bureaucracy. This is what separates science from storytelling. Anyone with your provenance bundle can:

- Reproduce your exact C_Σ value
- Verify your parameter choices were reasonable
- Challenge your decisions if they disagree
- Build on your work with confidence

Transparency is non-negotiable in TSC. (See TSC Operational §6)

______________________________________________________________________

## Part V: Understanding the Choices

### Why Geometric Mean for C_Σ?

Imagine a three-legged stool. If any leg is missing or broken, the stool collapses—it doesn't matter how strong the other two legs are. The stool needs **all three legs** to stand.

That's the **degeneracy guard**. Any dimension scoring 0 makes the entire aggregate 0. You cannot hide catastrophic failure in one dimension by averaging with success in others.

**Compare:**

**Arithmetic mean (averaging):**

```
(0.0 + 0.9 + 0.9) / 3 = 0.6
```

This says "one dimension is totally broken (0.0), but we're still 60% coherent overall." That's dishonest. If one dimension has collapsed, how can the system be 60% coherent?

**Geometric mean (multiplicative):**

```
(0.0 × 0.9 × 0.9)^(1/3) = 0
```

This says "one dimension is broken, so overall coherence is zero." That's honest. The three-legged stool has a broken leg—it's not standing.

Coherence requires **all three dimensions**. Pattern, relation, and process must all cohere. Lose any one and you've lost coherence entirely. The geometric mean enforces this truth. (See C≡ §5.4)

______________________________________________________________________

### Why Three Positions (Not Two)?

This is about what's mathematically possible, not what's convenient.

**One position:** Only undifferentiated wholeness. No distinction can appear. You can't show "one-as-two" because you can't show "two."

**Two positions:** Duality appears (left vs right, inside vs outside). But the unity is lost. It looks like two separate things. You have "two," not "one-as-two." The indivisibility breaks.

**Three positions:** Now you can hold both:

- **Left and Right:** the duality (two distinguishable aspects)
- **Center:** the unity (the one-ness that both aspects are)

This is minimal. You can't do it with fewer.

**The formal proof (C≡ §6):** Define a predicate F on triadic terms: F(tri(X,Y,Z)) = 1 if and only if the center position Y contains an atom (nf(Y) ≠ e). This is asking: "Is the unity position occupied?"

Try to express F using only binary operations. You can't. Binary operations can only see two arguments at once. They can never distinguish "left vs right vs center" because there's no center in binary structure—just left and right.

The question "is the center occupied?" is inexpressible in dyadic grammar. Three positions is the minimum needed to hold one-as-two. (See C≡ §6)

______________________________________________________________________

### Why Is β Different from α and γ?

**α and γ** ask **counting questions**: "how many?" and "how deep?" These are compositional—the count of a whole is the sum of counts of parts. So they're defined recursively (homomorphically). You build up the answer by combining child answers.

**β** asks a **configurational question**: "which positions are lit?" This requires "stepping back" to see the whole term's top-level structure. You can't build this up recursively because the global configuration isn't the combination of local configurations.

Example: A term tri(tri(κ,e,e), e, κ) has atoms at multiple levels. But β doesn't ask "how are atoms distributed through the nested structure?" It asks: "Looking at the top level, which of the three global slots (Left, Center, Right) contain articulation somewhere inside them?"

That's why β uses **presence-by-projection**: normalize the term, project to each of the three global positions, check for presence in each projection. It's a global question, not a local one.

**Different questions require different constructions.** α and γ are homomorphisms because counting is compositional. β is not a homomorphism because configuration is global. (See C≡ §3.2)

______________________________________________________________________

### Why Three Axes (Not Two or Four)?

**Two axes:** There's a theorem (Eckmann-Hilton collapse) that says if you have two commutative monoid operations on the same carrier, they must be identical. You can't have genuine independence with just two—they collapse into one.

**Three axes:** Avoids collapse. Our three target monoids have **distinct idempotent profiles** (proven in C≡ §3.4):

- α: {0, M} (just the boundaries)
- β: all elements (fully idempotent)
- γ: {(0,0)} (unique identity)

These are like fingerprints—they prove the three are genuinely different. No two can be isomorphic.

**Four or more:** Redundant. Three captures the minimal orthogonal structure. Adding more axes doesn't give you new independent information—just redundant measurements. Three is the sweet spot.

______________________________________________________________________

### What's the Difference Between PASS, FAIL, and FAIL_DEGENERATE?

Think of measuring temperature with a thermometer:

**PASS:** Temperature is in the safe range (< 100°F). Everything's fine.

**FAIL:** Temperature is too high (103°F). This is a problem with the **system** (you have a fever). The thermometer works fine—it's giving you accurate bad news. You need to treat the fever.

**FAIL_DEGENERATE:** The thermometer is broken. The reading says "250°F" but that's physically impossible. This is a problem with the **measurement**, not the system. You can't trust the number at all. You need to fix or replace the thermometer before you can even assess whether you have a fever.

In TSC:

**PASS:** C_Σ ≥ Θ with all witnesses passing. The system coheres.

**FAIL:** C_Σ < Θ, or CI too wide, or OOD flagged. The system has problems (low coherence, uncertain measurement, or context shift). This is **interpretable**—you know what's wrong.

**FAIL_DEGENERATE:** A witness failed. The **measurement is broken**. You can't trust the C_Σ value. This is **not interpretable**—don't try to understand why coherence is low. Fix the measurement, then measure again.

Very different problems. Very different responses. (See TSC Operational §5)

______________________________________________________________________

### Is TSC Deterministic?

**With fixed seeds and complete provenance: yes, absolutely.**

Bootstrap resampling uses random number generation, but if you log the random seed (which provenance requires), anyone can regenerate the exact same sequence. Same inputs + same seed = same random sequence = same bootstrap samples = same C_Σ = same CI bounds.

**Without seed logging: no.** Different bootstrap samples give slightly different results. That's why seed logging is mandatory.

**The reproducibility guarantee:** Given your provenance bundle (with seed), I can reproduce your exact C_Σ value to floating-point precision. Not "approximately the same"—exactly the same, bit for bit.

This is what makes TSC falsifiable. (See TSC Core §6, Operational §6)

______________________________________________________________________

### Can Parameters Change Between Runs?

**During calibration: yes.** You're exploring parameter space, finding settings that give stable, interpretable results. Tune freely.

**During production measurement: no.** Once you freeze parameters and start accumulating measurements for comparison, changing them invalidates the comparison. You're measuring in a different regime now. Past and present measurements aren't comparable.

**If context genuinely shifts:** That's fine. Acknowledge it explicitly. Document the recalibration in provenance. Declare a new measurement epoch with new reference distributions. Start fresh.

What's not okay: silently changing parameters mid-stream and pretending measurements are comparable. They're not.

Think of it like changing the ruler while measuring. If you measure something as 10 inches, then change to a centimeter ruler and measure 25, you can't say "it grew from 10 to 25." You changed the measurement units.

Same with TSC parameters. Change them if needed, but **declare** the change. (See TSC Core §2.1, Operational §6)

______________________________________________________________________

## Quick Reference: Key Parameters at a Glance

| Parameter | Meaning                             | Default      | Where              |
| --------- | ----------------------------------- | ------------ | ------------------ |
| θ         | Structural vs distributional weight | 0.7          | Core §3            |
| λ_a       | Axis sensitivity (a∈{α,β,γ})        | tuned        | Core §4            |
| λ_ab      | Pairwise sensitivity                | tuned        | Core §3            |
| φ         | Barrier transform δ → D             | δ/(1−δ)      | Core §3.2          |
| η_φ       | Barrier clip near δ=1               | 10⁻¹²        | Core §3.2, §12     |
| ε         | Numerical floor                     | 10⁻⁵         | Core §5            |
| M         | α evaluator cap (≥ 3)               | 10 (example) | C≡ §3.1            |
| **Θ**     | **Decision threshold**              | **0.75**     | **Operational §5** |
| δ_CI      | CI width tolerance                  | 0.20         | Operational §5     |
| Z_crit    | OOD threshold                       | 2.5          | Operational §5     |
| τ_S3      | S₃ witness                          | 0.05         | Operational §2     |
| τ_gauge   | Gauge witness (ref)                 | 0.05         | Operational §2     |
| τ_gauge_spread | Gauge witness (spread)         | τ_gauge      | Operational §2     |
| τ_scale   | Scale witness                       | 0.10         | Operational §2     |
| τ_var     | Variance witness                    | 0.15         | Operational §2     |
| τ_lip     | Lipschitz witness (κ ≤ τ_lip)       | 0.95         | Operational §2     |

**Note on Θ:** The normative default is **0.75**. For self-application (TSC measuring itself) or safety-critical deployments, teams may choose a stricter threshold (e.g., 0.90) as a **policy choice**. This is not a change to the baseline—it's an override for specific contexts. Document any override clearly in provenance.

______________________________________________________________________

## Where to Go Next

**To understand the foundation deeply:**\
Read **C≡ v3.1.0** from beginning to end. It unfolds like a story: from intuition (§0-1) through formalization (§2-4) to measurement (§5). Follow the complete arc.

**To implement measurement:**\
Read **TSC Core v3.1.0** for the calculus—how to construct summaries, compute alignments, aggregate coherence. Then **TSC Operational v3.1.0** for the protocol—witnesses, verdicts, provenance requirements.

**To see it in action:**\
Explore `examples/`—cellular automata (Conway's Life, random soup) and philosophical queries (consciousness, emergence, free will). These show TSC measuring real phenomena, not toy problems.

**To verify proofs:**\
Follow the cross-references in this glossary. Every "See §X" points to the normative specification where the formal statement and proof live. The math is rigorous; this glossary is the interpretation layer.

**To contribute:**\
Read CONTRIBUTING.md. Then start conversations in GitHub Discussions. The framework is open—bring your perspectives, your use cases, your critiques.

______________________________________________________________________

## Legacy Notation Note

**For implementers migrating from earlier versions:** Dimensional scores were previously notated as α_c, β_c, γ_c in some documents. These are now unified as **s_α, s_β, s_γ** across all specifications for consistency with the C≡ foundation. In wire formats (JSON/YAML), use ASCII keys: `s_alpha`, `s_beta`, `s_gamma`. One-cycle compatibility support (reading both notations) is documented in Operational v3.1.0.

______________________________________________________________________

**End — TSC Glossary v3.2.0**
