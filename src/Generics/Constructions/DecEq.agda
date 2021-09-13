module Generics.Constructions.DecEq where

open import Agda.Builtin.Reflection
open import Generics.Prelude hiding (lookup)
open import Generics.Telescope
open import Generics.Desc
open import Generics.HasDesc
open import Data.Fin.Properties as Fin

open import Relation.Nullary.Decidable as Decidable
open import Data.Empty
open import Relation.Nullary
import Data.Product.Properties as Product
open import Relation.Binary renaming (DecidableEquality to DecEq)


module _ {P} {I : ExTele P} {ℓ} {A : Indexed P I ℓ} (H : HasDesc {P} {I} A) where


  open HasDesc H

  levelC : ∀ {V ℓ} (C : ConDesc P V I ℓ) → Level
  levelC (var i        ) = lzero
  levelC (π {ℓ} p i S C) = ℓ ⊔ levelC C
  levelC (A ⊗ B        ) = levelC A ⊔ levelC B

  DecEq<_> : ∀ {a} → Relevance → Set a → Set a
  DecEq< r > A = (x y : A) → < r > Dec (x ≡ y)

  HelperExtend′ : ∀ {V ℓ} (C : ConDesc P V I ℓ) → ⟦ P , V ⟧xtel → Set (levelC C)
  HelperExtend′ (var i) pv = ⊤
  HelperExtend′ (π p i S C) pv = Lift _ ⊥
  HelperExtend′ (A ⊗ B) pv = HelperExtend′ A pv × HelperExtend′ B pv

  Helper<_> : ∀ {i} → Relevance → Set i → Set i
  Helper< relevant   > A = A
  Helper< irrelevant > A = Lift _ ⊤

  HelperExtend : ∀ {V ℓ} (C : ConDesc P V I ℓ) → ⟦ P , V ⟧xtel → Set (levelC C)
  HelperExtend (var i) pv = ⊤
  HelperExtend (A ⊗ B) pv = HelperExtend′ A pv × HelperExtend B pv
  HelperExtend (π e i S C) pv@(p , v) =
    Helper< relevance i > (DecEq (S pv)) × ((s : < relevance i > S pv) → HelperExtend C (p , v , s))

  levelHelper : ∀ {ℓ n} → DataDesc P I ℓ n → Level
  levelHelper [] = lzero
  levelHelper (C ∷ D) = levelC C ⊔ levelHelper D

  Helper : ∀ {ℓ n} (D : DataDesc P I ℓ n) → ⟦ P ⟧tel tt → Set (levelHelper D)
  Helper [] p = ⊤
  Helper (C ∷ D) p = HelperExtend C (p , tt) × Helper D p

  lookupHelper : ∀ {ℓ n } {D : DataDesc P I ℓ n} {p} → Helper D p → (k : Fin n) → HelperExtend (lookupCon D k) (p , tt)
  lookupHelper {D = C ∷ D} (CH , DH) zero = CH
  lookupHelper {D = C ∷ D} (CH , DH) (suc k) = lookupHelper DH k


  module _ {p} (H : Helper D p) where
    mutual
      ≡-dec-⟦⟧ : ∀ {V} (C : ConDesc P V I ℓ) {v : ⟦ V ⟧tel p}
                → HelperExtend′ C (p , v)
                → DecEq (⟦ C ⟧Con (levelOfTel I) (μ D) (p , v))
      ≡-dec-⟦⟧ (var i) H x y = ≡-dec-μ x y
      ≡-dec-⟦⟧ (A ⊗ B) (HA , HB) x y = Product.≡-dec (≡-dec-⟦⟧ A HA) (≡-dec-⟦⟧ B HB) x y
      ≡-dec-⟦⟧ (π p i S C) ()

      ≡-dec-Extend : ∀ {V} (C : ConDesc P V I ℓ) {v : ⟦ V ⟧tel p} {i : ⟦ I ⟧tel p}
                   → HelperExtend C (p , v)
                   → DecEq (Extend C (levelOfTel I) (μ D) (p , v , i))
      ≡-dec-Extend (var i) H (lift refl) (lift refl) = yes refl
      ≡-dec-Extend (A ⊗ B) (HA , HB) x y = Product.≡-dec (≡-dec-⟦⟧ A HA) (≡-dec-Extend B HB) x y
      ≡-dec-Extend (π p i S C) (DS , HC) x y = ≡-dec-Extend′ p i S C DS HC x y

      aux : ∀ {i j} r {A : Set i} {B : < r > A → Set j}
          → Helper< r > (DecEq A)
          → (∀ x → DecEq (B x))
          → DecEq (Σ (< r > A) B)
      aux relevant HA HB (x₁ , b₁) (x₂ , b₂) with HA x₁ x₂
      ... | yes refl = map′ (cong (x₁ ,_)) (λ { refl → refl }) (HB (x₁) b₁ b₂)
      ... | no b₁≢b₂ = no (b₁≢b₂ ∘ λ { refl → refl })
      aux irrelevant HA HB (irrv x₁ , b₁) (irrv x₂ , b₂) with HB (irrv x₁) b₁ b₂
      ... | yes refl = yes refl
      ... | no b₁≢b₂ = no (b₁≢b₂ ∘ (λ { refl → refl }))

      ≡-dec-Extend′ : ∀ {V} {ℓ₁ ℓ₂}
                      (e : ℓ₁ ≡ ℓ₂ ⊔ ℓ)
                      (i : ArgInfo)
                      (S : ⟦ P , V ⟧xtel → Set ℓ₂)
                      (C : ConDesc P (V ⊢< i > S) I ℓ)
                      {v : ⟦ V ⟧tel p} {i′ : ⟦ I ⟧tel p}
                    → Helper< relevance i > (DecEq (S (p , v)))
                    → ((s : < relevance i > S (p , v)) → HelperExtend C (p , v , s))
                    → DecEq (Extendᵇ (levelOfTel I) e i (μ D) S C (p , v , i′))
      ≡-dec-Extend′ refl i S C DS HC x y = aux (relevance i) DS (λ s → ≡-dec-Extend C (HC s)) x y

      {-# TERMINATING #-}
      ≡-dec′ : ∀ {i : ⟦ I ⟧tel p} → DecEq (⟦ D ⟧Data (levelOfTel I) (μ D) (p , i))
      ≡-dec′ (kx , x) (ky , y) with kx Fin.≟ ky
      ... | no  kx≢ky = no (kx≢ky ∘ cong proj₁)
      ... | yes refl  = case ≡-dec-Extend (lookupCon D kx) (lookupHelper H kx) x y of λ where
                              (yes refl) → yes refl
                              (no  x≢y ) → no (x≢y ∘ λ { refl → refl })

      ≡-dec-μ : ∀ {i : ⟦ I ⟧tel p} → DecEq (μ D (p , i))
      ≡-dec-μ ⟨ x ⟩ ⟨ y ⟩ = map′ (cong ⟨_⟩) (cong ⟨_⟩⁻¹) (≡-dec′ x y)

      ≡-dec : ∀ {i : ⟦ I ⟧tel p} → DecEq (A′ (p , i))
      ≡-dec x y = map′ (λ p → trans (sym (from∘to _)) (trans (cong from p) (from∘to _))) (cong to) (≡-dec-μ (to x) (to y))
