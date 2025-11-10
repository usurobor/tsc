# C≡ v3.0.0: Self-Labeling Foundation

**Version:** 3.0.0  
**Date:** November 2025  
**Status:** Normative

---

## Kernel

**Atoms.** Nonempty set 𝔄.

**Terms.** Finite trees: T ::= e | a | tri(T,T,T) where a∈𝔄

**Equivalence.** Least congruence (~) with e ~ tri(e,e,e)

**Normalizer nf:**
```
nf(e) = e
nf(a) = a
nf(tri(t₁,t₂,t₃)) = contract(tri(nf(t₁), nf(t₂), nf(t₃)))

contract(tri(u₁,u₂,u₃)) = e              if u₁=u₂=u₃=e
                        = tri(u₁,u₂,u₃)  otherwise
```

**Soundness.** t ~ nf(t)

**Uniqueness.** t ~ u ⟺ nf(t) = nf(u)

**Projections.** On normal forms:
```
π_L(e)=e,  π_L(a)=a,  π_L(tri(x,y,z))=x
π_C(e)=e,  π_C(a)=a,  π_C(tri(x,y,z))=y
π_R(e)=e,  π_R(a)=a,  π_R(tri(x,y,z))=z
```

**Well-definedness.** π_i(nf(t)) = nf(π_i(t))

**Gauge action.** For σ∈S₃:
```
σ·e = e
σ·a = a
σ·tri(t₁,t₂,t₃) = tri(t_{σ(1)}, t_{σ(2)}, t_{σ(3)})
```

**Commutation.** nf(σ·t) = σ·nf(t)

**Remark.** The S₃ action is faithful but not free (e.g., tri(e,e,e) has nontrivial stabilizer).

**Evaluators.** All via nf:

α: (ℕ, ⊕, 0) where x⊕y = min(x+y, M), M≥3
```
E_α(e)=0,  E_α(a)=1,  E_α(tri)=⊕
⟦t⟧_α = E_α(nf(t))
```

β: (ℕ³, ⊔, 0³) where (x₁,x₂,x₃) ⊔ (y₁,y₂,y₃) := (max(x₁,y₁), max(x₂,y₂), max(x₃,y₃))
```
E_β(e)=0³,  E_β(a)=(1,0,0)
E_β(tri(T₁,T₂,T₃)) = E_β(T₁) ⊔ E_β(T₂) ⊔ E_β(T₃)
⟦t⟧_β = E_β(nf(t))
```

γ: (ℕ×ℕ, ⊗, (0,0)) where (x,u)⊗(y,v) = (x+y, u⊙v) and u⊙v = u+v+uv
```
E_γ(e)=(0,0),  E_γ(a)=(1,1),  E_γ(tri)=⊗
⟦t⟧_γ = E_γ(nf(t))
```

**Associativity.** γ second component via isomorphism u↦u+1: (u+1)(v+1)-1. Hence ⊙ is associative and commutative; so is ⊗.

**Independence.** Idempotent profiles:
- α: idempotents exactly {0, M}
- β: v ⊔ v = v for all v (fully idempotent)
- γ: only (0,0) is idempotent

**Scores.** s_α, s_β, s_γ: T/~ → [0,1]
- (P1) s_i(e) = 1
- (P2) 0 ≤ s_i ≤ 1
- (P3) S₃-invariant: the unordered triple (multiset) of scores is preserved
- (P4) Disruption-monotone: t ⪰ u ⟹ s_i(t) ≥ s_i(u)

**Aggregate.** C_Σ = (s_α · s_β · s_γ)^(1/3)

**Degeneracy.** Any s_i = 0 ⟹ C_Σ = 0

---

## Part I: Terms

### Definition 1.1 (Syntax)

Fix nonempty set 𝔄 of atoms. Terms are finite trees:
```
T ::= e | a | tri(T,T,T)    where a ∈ 𝔄
```

**Examples:**
- e (empty)
- a (atom)
- tri(e,e,e) (empty triad)
- tri(a,e,b) (mixed triad)
- tri(tri(a,b,c), e, tri(d,e,f)) (nested)

### Definition 1.2 (Equivalence)

The relation ~ is the smallest congruence containing:
```
e ~ tri(e,e,e)
```

**Properties:**
- Reflexive: t ~ t
- Symmetric: t ~ u ⟹ u ~ t
- Transitive: t ~ u ∧ u ~ v ⟹ t ~ v
- Compatible: t₁ ~ u₁ ∧ t₂ ~ u₂ ∧ t₃ ~ u₃ ⟹ tri(t₁,t₂,t₃) ~ tri(u₁,u₂,u₃)

### Definition 1.3 (Normal Form)

Define nf: T → T by:
```
nf(e) = e
nf(a) = a
nf(tri(T₁,T₂,T₃)) = contract(tri(nf(T₁), nf(T₂), nf(T₃)))
```

where:
```
contract(tri(U₁,U₂,U₃)) = e              if U₁ = U₂ = U₃ = e
contract(tri(U₁,U₂,U₃)) = tri(U₁,U₂,U₃)  otherwise
```

**Complexity:** O(|t|) time, O(height(t)) space.

**Examples:**
```
nf(tri(e,e,e)) = e
nf(tri(tri(e,e,e), a, e)) = tri(e,a,e)
nf(tri(a,b,c)) = tri(a,b,c)
```

### Lemma 1.4 (Soundness)

For all t: t ~ nf(t)

**Proof.** By induction on t. ∎

### Proposition 1.5 (Quotient)

**(a)** nf(nf(t)) = nf(t)

**(b)** t ~ u ⟺ nf(t) = nf(u)

**Proof.** (a) Induction. (b) Direction ⟸ uses Lemma 1.4. ∎

---

## Part II: Evaluators

### Proposition 2.1 (Minimality)

Define F: T → {0,1} by:
```
F(e) = 0
F(a) = 0
F(tri(X,Y,Z)) = 1  iff  nf(Y) ≠ e
```

No dyadic grammar realizes F.

**Proof.** Dyadic operations cannot distinguish center position. ∎

### Definition 2.2 (Evaluators)

Three monoid homomorphisms, defined via E_● ∘ nf:

**(α) Sequential**

Target: (ℕ, ⊕, 0) where x⊕y = min(x+y, M), M≥3
```
E_α(e) = 0
E_α(a) = 1
E_α(tri(T₁,T₂,T₃)) = E_α(T₁) ⊕ E_α(T₂) ⊕ E_α(T₃)
```

**Properties:**
- Associative: (x⊕y)⊕z = x⊕(y⊕z)
- Commutative: x⊕y = y⊕x
- Idempotents: {0, M} only

**(β) Structural**

Target: (ℕ³, ⊔, (0,0,0)) where:
```
(x₁,x₂,x₃) ⊔ (y₁,y₂,y₃) := (max(x₁,y₁), max(x₂,y₂), max(x₃,y₃))
```
```
E_β(e) = (0,0,0)
E_β(a) = (1,0,0)
E_β(tri(T₁,T₂,T₃)) = E_β(T₁) ⊔ E_β(T₂) ⊔ E_β(T₃)
```

**Properties:**
- Associative: (u⊔v)⊔w = u⊔(v⊔w)
- Commutative: u⊔v = v⊔u
- Idempotent: v⊔v = v for all v

**(γ) Generative**

Target: (ℕ×ℕ, ⊗, (0,0)) where:
```
(x,u)⊗(y,v) = (x+y, u⊙v)
u⊙v = u+v+uv
```
```
E_γ(e) = (0,0)
E_γ(a) = (1,1)
E_γ(tri(T₁,T₂,T₃)) = E_γ(T₁) ⊗ E_γ(T₂) ⊗ E_γ(T₃)
```

**Associativity of ⊙:** Via isomorphism u↦u+1:
```
u⊙v = (u+1)(v+1) - 1
```
So ⊙ is isomorphic to multiplication on positive integers, hence associative and commutative. Therefore ⊗ is also commutative.

**Properties:**
- Associative
- Commutative
- Idempotent only at (0,0)

**Evaluation notation:**

For all bullets: ⟦t⟧_● = E_●(nf(t))

### Theorem 2.3 (Independence)

The three monoids are pairwise non-isomorphic.

**Proof.** Idempotent profiles:
- α: exactly {0, M}
- β: all elements
- γ: only (0,0)

Monoid isomorphisms preserve idempotence structure. These profiles are distinct, hence no isomorphisms exist. ∎

---

## Part III: Symmetry

### Definition 3.1 (Projections)

For normal forms:
```
π_L(e) = e
π_L(a) = a
π_L(tri(T₁,T₂,T₃)) = T₁

π_C(e) = e
π_C(a) = a
π_C(tri(T₁,T₂,T₃)) = T₂

π_R(e) = e
π_R(a) = a
π_R(tri(T₁,T₂,T₃)) = T₃
```

**Well-definedness.** π_i(nf(t)) = nf(π_i(t))

### Proposition 3.2 (Gauge Action)

For σ ∈ S₃, define:
```
σ·e = e
σ·a = a
σ·tri(T₁,T₂,T₃) = tri(T_{σ(1)}, T_{σ(2)}, T_{σ(3)})
```

**Lemma (Commutation).** nf(σ·t) = σ·nf(t)

**Proof.** By induction. ∎

**Remark.** Action is faithful but not free.

### Definition 3.3 (S₃-Invariance)

Scores s_α, s_β, s_γ: T/~ → [0,1] are **S₃-invariant** if the unordered triple (multiset) of scores is preserved under gauge action.

**Formally:** For all t and all σ∈S₃, there exists a permutation ρ of {α,β,γ} such that:
```
s_α(σ·t) = s_{ρ(α)}(t)
s_β(σ·t) = s_{ρ(β)}(t)
s_γ(σ·t) = s_{ρ(γ)}(t)
```

### Corollary 3.4 (Aggregate Invariance)

If scores are S₃-invariant, then C_Σ = (s_α·s_β·s_γ)^(1/3) is invariant under σ.

**Proof.** Multiplication commutes. ∎

---

## Part IV: Measurement

### Definition 4.1 (Score Axioms)

Functions s_α, s_β, s_γ: T/~ → [0,1] satisfy:

**(P1) Perfect empty:** s_i(e) = 1

**(P2) Bounded:** 0 ≤ s_i(t) ≤ 1

**(P3) S₃-invariance:** Definition 3.3

**(P4) Disruption-monotone:** t ⪰ u ⟹ s_i(t) ≥ s_i(u)

### Definition 4.2 (Disruption Preorder)

**Contexts:**
```
𝒞[·] ::= [·] 
       | tri(𝒞[·],T,T) 
       | tri(T,𝒞[·],T) 
       | tri(T,T,𝒞[·])
```

**Disruption step:** t ⤳ u if there exist context 𝒞 and term v such that t = 𝒞[v] and u = 𝒞[e] (normalized in T/~).

**Preorder:** t ⪰ u is reflexive-transitive closure of ⤳.

### Definition 4.3 (Aggregate Coherence)
```
C_Σ(t) = (s_α(t) · s_β(t) · s_γ(t))^(1/3)
```

### Theorem 4.4 (Degeneracy)

If s_i(t) = 0 for any i ∈ {α,β,γ}, then C_Σ(t) = 0.

**Proof.** Direct. ∎

---

## Appendix: Notation

**Terms:**
- 𝔄: atoms
- e: unit
- tri: triadic node
- ~: equivalence
- nf: normal form
- T/~: quotient

**Operations:**
- π_L, π_C, π_R: projections
- σ·t: gauge action (σ∈S₃)
- ⟦·⟧_α, ⟦·⟧_β, ⟦·⟧_γ: evaluators
- ⊕: α operation (capped addition)
- ⊔: β operation (componentwise max)
- ⊗, ⊙: γ operations

**Measurement:**
- s_α, s_β, s_γ: scores
- C_Σ: aggregate
- t ⪰ u: disruption preorder

---

**End of Specification**