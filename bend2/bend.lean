-- NOTE: this file has two parts:
-- 1. the specification, which is what humans must read and audit
-- 2. the proofs, which were written by AI, and checked by Lean
-- Even though we've reviewed the spec carefully, it doesn't fully match the
-- implementation (bend.ts) yet. Bugs in the implementation COULD result in
-- inconsistencies. Independent audits are needed to increase our confidence on
-- bend.ts even further, and will be done over time. 
-- 
-- ============================================================================
-- BEND-CORE — the bend2 calculus, as bend.ts implements it
-- ============================================================================
--
-- A model of the Bend core: the language (bend.ts's Types through Valid),
-- its reduction, typing, descent and validation, and the five claims the
-- bend.ts header trusts. PART I is the SPEC — the part a human must read.
-- PART II is the metatheory proving the claims.
--
-- THE HEADLINE. A dependent calculus with Type : Type, impredicativity and
-- negative recursive types, made consistent not by a universe hierarchy or a
-- positivity check but by a usage wall. Two checking demands, None (dead)
-- and Lone (live); binders graded None, Lone or Many; a Many binder forms
-- only at a Data type, and no function type is Data. So a live function
-- value is consumed at most once: self-replicating lambdas (omega, Curry,
-- Hurkens) contract a live function-valued binding and do not type. The
-- other way to loop is recursion, and every live self-call descends on a
-- strict subterm of the definition's own case-tree columns. Dead code is
-- specification, not proof: it may diverge and may inhabit Empty, and the
-- claims are stated for the live fragment only.
--
-- THE MAP. Part I mirrors bend.ts's core, section by section:
--
--   bend.ts section    | here          | contents
--   -------------------|---------------|------------------------------------
--   Types              | §1 Types      | Quant, Uses, Term, Bind, Ctx, DefD,
--                      |               | CtrD, AdtD, TLD, Book, LHS
--   Quant              | §2 Quant      | add, join, mul, le, dem
--   Uses               | §3 Uses       | zero, one, add, join, tail
--   Term, LHS          | §4 Term       | apps/spine, shift, subst, Closed,
--                      |               | the J motive, the lhs algebra
--   Ctx, Ctrs, Book    | §5 Ctx/Book   | get, δ (let expansion), tld, adt,
--                      |               | defn, ctr, LHS walks
--   Compare (descend)  | §6 Descent    | PEq/PLt (EQ/LT verdicts), SpineLt
--   Tele               | §7 Tele       | telescope shapes and openings
--   WNF, SNF, Compare  | §8 Equal      | Step/Red (wnf/snf), Value, Conv
--                      |               | (compare EQ), Le (compare LE)
--   Check              | §9 Check      | the one judgment: infer and check,
--                      |               | with the descent test at infer-ref
--   Valid              | §10 Valid     | Book.Ok (book_valid)
--   (header claims)    | §11 Claims    | the five claims as Props
--
-- THE ENCODING. Terms are de Bruijn and first-order; bend.ts's binder ids
-- and HOAS bodies are its way of being capture-free, and a de Bruijn index
-- is the same fact. Its Ann is inference's only help and has no rule here:
-- {x : T} is x checked at T, which the declarative judgment can always do
-- (cnv). Its Hol is ?TODO, which marks a book incomplete, and its Sub is a
-- flattener node: neither reaches a checked book. Its n-ary ADT and Ctr
-- nodes are application spines headed by Adt a r and Ctr a c, always full
-- in a parsed book; a constructor spine carries the family's parameters
-- as erased leading arguments (check-ctr reads them off the goal, and the
-- elaborated node records them in its Ann). Its parallel let x y = a b; f
-- is nested Lets, each value checked in the outer scope. The surface
-- syntax (match, case, do, the sugars) desugars and flattens into this
-- core at parse time; the flattener's output is a tree of Lam, Mat and
-- Efq over the definition's columns, in binder order (Tree, §10), and
-- check-mat's column peel is sound only for such a body, so Book.Ok
-- states the shape def_valid trusts.
--
-- LETS ARE TRANSPARENT. A let binds x with its value: the checker types x
-- from the context and counts its uses, while reduction, conversion and
-- descent step through x to the value (bend.ts's Var carries v). Here a
-- Bind carries the optional value, and Ctx.δ expands every let-bound
-- variable in a term (§5); every comparison the judgment makes (cnv, rfl,
-- the descent test) compares δ-expanded terms. Reduction itself is
-- context-free: a closed let fires by substitution.
--
-- THE MODEL ACCEPTS EVERY BOOK bend.ts ACCEPTS with a clean verdict, and
-- some more. The extra permissions are harmless for the claims, which are
-- negative, and are listed here so nobody reads the model as the checker:
--   (a) the judgment is declarative: a term may be checked at any type
--       that its inferred type fits (cnv anywhere), where bend.ts converts
--       only at check-any, rfl and rwt, and normalizes goals by wnf;
--   (b) a family or constructor head may be applied to fewer arguments
--       than its arity, where bend.ts spells only full nodes;
--   (c) a residual family Adt a r may be written anywhere, where bend.ts
--       mints residuals only in match goals;
--   (d) (x => f)(a) types by the app rule too when the lambda is typed,
--       where bend.ts takes one beta step first (both are here);
--   (e) check-efq reads a binding's type up to conversion, where bend.ts
--       reads its weak head normal form (the same verdict on every type
--       bend.ts normalizes; conversion is what a let value's reduction
--       preserves, which subject reduction under a let needs).
-- Two premises the declarative form needs that bend.ts gets for free from
-- its pipeline: check-lam kinds the binder's domain at the binder's
-- quantity (bend.ts kinded it when the arrow was formed, and every goal
-- it meets was formed), and a constructor head's parameter binders are
-- erased (a bend.ts value never carries them). Each keeps a Many binder
-- from ever copying a function: what the Data layer's soundness rests on.
-- THE MODEL REFUSES what bend.ts accepts outside the theory: a book with
-- an @unsafe def or a surviving ?TODO (bend.ts reports both in its
-- verdict, and the claims are for clean verdicts); a definition with no
-- body (a law bend.ts's base file leaves unfilled, such as F32.add, or a
-- body it imports from C); and a live call to a definition that comes
-- later in the file. bend.ts refuses that call too, except from the base
-- file, where a helper may call a law that is filled below it and calls
-- the helper back: that pair is mutual recursion the checker never tests
-- (descent is tested on self-calls only). The theory has no such call.
--
-- NOT MODELED. Char, PMap, the number sections, Show, Parse, Flatten,
-- imports and the error window are pipeline and presentation concerns.
-- Literals are base.bend constructors, not calculus.
--
-- QUANTITIES. None | Lone | Many, spelled -x, x, +x.
--   add  (sequential): None + q = q; two live uses saturate to Many
--   join (branches):   pointwise max
--   mul  (fields):     a match field binds at field times scrutinee
--   dem  (arguments):  an erased binder kills the demand, else the
--                      ambient demand passes, unscaled (certify-once)
-- A demand is None or Lone, never Many. An argument to a q binder checks
-- at dem q qt and its measure adds once: a Lone Data value may enter a
-- Many binder, let or field, and the callee copies it. A binder's
-- measured use must not exceed its declared quantity on close.
--
-- KINDS. Every type has a kind Kind(g) over a quantity term g: Type is
-- Kind(&1), Data is Kind(&2); a function type is Type, an equation is
-- Data, a family declares Kind(G) over its parameters. A binder q x: A
-- checks A against Kind(q). Le orders kinds by the quantity: Kind(g) fits
-- Kind(h) when h <= g, &0 and &1 one rung, so Data fits every kind, every
-- kind fits Type, a meet fits a kind under both sides, a kind fits a meet
-- under either, and a stuck quantity licenses nothing. The meet a <&> b is
-- the minimum, reduced only when forced (§8).
--
-- REDUCTION (§8), one rule set read at two strengths: STRONG may enter
-- any subterm (conversion's reach), WEAK never enters a binder (the
-- machine's reach: Lam body, Let body, All codomain, Kind argument).
--   beta  ((λ f) a)                      → f[0 := a]
--   let   (let q v; b)                   → b[0 := v]
--   dref  @k·as, |as| = arity            → book[k].body·as      (== wnf)
--   drefS @k·as, STRONG only             → book[k].body·as      (any arity)
--   eta   λ(F 0), STRONG, 0 ∉ F          → F                    (functions)
--   aref  @a, a nullary family           → Adt a []
--   matc  (Mat a c h m) (Ctr a c)·ps·xs  → h·xs                 (|xs| = fn)
--   matm  (Mat a c h m) (Ctr a' c')·as   → m ((Ctr a' c')·as)   (c' ≠ c)
--   rwt   (Rwt {==} P f)                 → f
--   min   &2 <&> b → b, &0 <&> b → &0, a <&> &2 → a, a <&> &0 → &0,
--         &1 <&> &1 → &1; a stuck side keeps the meet stuck
-- Values are weak-head: type formers, quantities, function values, stuck
-- meets and rewrites, Adt/Ctr-headed spines, and stuck reference spines
-- (a parameterized family head, an underapplied definition).
-- Conv is joinability of strong runs (compare EQ); Le is Conv made
-- directional at kinds, at ADT residuals (peeling more fits peeling
-- fewer) and at function domains, which compare swapped (compare LE).
--
-- TYPING (§9). One judgment, Check β Φ L sp q Γ t T π u: under the
-- equation L and the pending spine sp, at demand q, t has type T
-- consuming π and elaborates to u, the certified term with its dead
-- parts erased to the token Quant (bend.ts answers the elaborated term;
-- comp.ts erases exactly these parts). Φ names the judgment's two tests,
-- conversion (Le) and ex-falso (CtxDead): Pol.std, bend.ts's; PART II
-- also reads the rules under a coarser pair for dead code. Every rule is
-- bend.ts's rule of the same name, spelled as its derivation comment.
-- The var rule charges the ambient demand; a type position, an erased
-- argument, a kind's quantity, an equality endpoint and a motive check
-- dead; no rule coerces dead to live. A live reference points at a
-- definition checked before this one, or at this one; a live self-reference
-- must head a call whose pending spine descends against the equation's
-- columns (infer-ref), the equation being the def's own left-hand side
-- rebuilt as the walk binds a Lam column or peels a Mat column into a
-- constructor of fresh fields (check-lam, check-mat). Dead code carries
-- no descent obligation at all, which is what lets a negative recursive
-- type be defined. A live match consumes a live scrutinee; the empty
-- match accepts when no constructor remains or a LIVE binding in scope
-- has an emptied type (check-efq).
--
-- THE CLAIMS (§11), over any Ok book:
-- (1) confluence of strong reduction; (3) progress at live demand;
-- (2) subject reduction along live weak steps of closed live terms
-- (those at positions the
-- elaboration keeps: dead code preserves nothing, a dead arm may
-- inhabit Empty); (4) weak normalization of closed live terms;
-- (5) consistency: no closed live term inhabits an emptied family.
-- ============================================================================

namespace BendCore

-- ============================================================================
-- §1 Types (== bend.ts Types)
-- ============================================================================

inductive Quant : Type
  | None
  | Lone
  | Many
deriving DecidableEq

abbrev Uses := Nat → Quant

inductive Term : Type
  | Var : Nat → Term                          -- x
  | Ref : Nat → Term                          -- @k (a definition or a family)
  | Typ : Term → Term                         -- Kind(g); Type = Typ (Qua Lone)
  | Qnt : Term                                -- Quant
  | Qua : Quant → Term                        -- &0 &1 &2
  | Min : Term → Term → Term                  -- a <&> b
  | All : Quant → Term → Term → Term          -- @q x:A -> B   (binds in B)
  | Lam : Term → Term                         -- x => f        (binds)
  | App : Term → Term → Term                  -- f(x)
  | Adt : Nat → List Nat → Term               -- family head, peeled ctrs
  | Ctr : Nat → Nat → Term                    -- constructor head (family, index)
  | Mat : Nat → Nat → Term → Term → Term      -- \{c: h; m}
  | Efq : Term                                -- \{}
  | Eql : Term → Term → Term → Term           -- {a == b : T}
  | Rfl : Term                                -- {==}
  | Rwt : Term → Term → Term → Term           -- %e : P; f
  | Let : Quant → Term → Term → Term          -- q x = v; f    (binds in f)
deriving DecidableEq

-- a definition: n case-tree columns, their quantities, a closed type and
-- a closed body
structure DefD : Type where
  n    : Nat
  qs   : List Quant
  ty   : Term
  body : Term
deriving DecidableEq

-- a constructor: field count and closed telescope type (the family's pn
-- parameters, then fn fields, tipped at the family applied to its own
-- parameters — parse_adt builds exactly this shape)
structure CtrD : Type where
  fn : Nat
  ty : Term
deriving DecidableEq

-- a family: parameter count, closed signature, constructors
structure AdtD : Type where
  pn   : Nat
  sig  : Term
  ctrs : List CtrD
deriving DecidableEq

inductive TLD : Type
  | adt : AdtD → TLD
  | defn : DefD → TLD
deriving DecidableEq

-- the book, in file order (a law sits where its def fills it)
abbrev Book := List TLD

-- a context binding: quantity, type, and the value of a let binder
structure Bind : Type where
  q : Quant
  T : Term
  v : Option Term
deriving DecidableEq

abbrev Ctx := List Bind

-- the equation of the definition under check (bend.ts LHS): the def's
-- index, its left-hand side rebuilt as the walk binds columns, the
-- columns still to bind and the parameter quantities
structure LHS : Type where
  k  : Nat
  t  : Term
  n  : Nat
  qs : List Quant
deriving DecidableEq

-- ============================================================================
-- §2 Quant (== bend.ts Quant)
-- ============================================================================

def Quant.add : Quant → Quant → Quant
  | .None, q     => q
  | q,     .None => q
  | _,     _     => .Many

def Quant.join : Quant → Quant → Quant
  | .None, q     => q
  | .Lone, .None => .Lone
  | .Lone, q     => q
  | .Many, _     => .Many

-- a match field binds at field times scrutinee: a + field under a Lone
-- holder is Many (bend.ts quant_mul)
def Quant.mul : Quant → Quant → Quant
  | .None, _ => .None
  | .Lone, x => x
  | .Many, x => Quant.add x x

def Quant.le : Quant → Quant → Prop
  | .None, _     => True
  | .Lone, .None => False
  | .Lone, _     => True
  | .Many, .Many => True
  | .Many, _     => False

-- the demand on an argument: an erased binder kills the demand, any other
-- binder passes the ambient demand through (bend.ts quant_dem)
def Quant.dem : Quant → Quant → Quant
  | .None, _  => .None
  | _,     qt => qt

-- ============================================================================
-- §3 Uses (== bend.ts Uses)
-- ============================================================================

def Uses.zero : Uses := fun _ => .None
def Uses.one (i : Nat) (q : Quant) : Uses := fun j => if j = i then q else .None
def Uses.add (a b : Uses) : Uses := fun i => Quant.add (a i) (b i)
def Uses.join (a b : Uses) : Uses := fun i => Quant.join (a i) (b i)
def Uses.tail (a : Uses) : Uses := fun i => a (i + 1)

-- ============================================================================
-- §4 Term (== bend.ts Term: apply/unapply, shift, subst, the lhs algebra)
-- ============================================================================

def Term.apps : Term → List Term → Term
  | f, []      => f
  | f, a :: as => Term.apps (.App f a) as

-- a term is a head (never an App) — spine decompositions are unique
def Term.IsHead : Term → Prop
  | .App _ _ => False
  | _        => True

-- the spine decomposition: t = apps (spine t).1 (spine t).2 with a
-- non-App head (bend.ts term_unapply)
def Term.spine : Term → Term × List Term
  | .App f a => ((Term.spine f).1, (Term.spine f).2 ++ [a])
  | t        => (t, [])

def Term.shift (d : Nat) : Term → Term
  | .Var i         => if i < d then .Var i else .Var (i + 1)
  | .Ref k         => .Ref k
  | .Typ g         => .Typ (Term.shift d g)
  | .Qnt           => .Qnt
  | .Qua q         => .Qua q
  | .Min a b       => .Min (Term.shift d a) (Term.shift d b)
  | .All q A B     => .All q (Term.shift d A) (Term.shift (d + 1) B)
  | .Lam f         => .Lam (Term.shift (d + 1) f)
  | .App f a       => .App (Term.shift d f) (Term.shift d a)
  | .Adt a r       => .Adt a r
  | .Ctr a c       => .Ctr a c
  | .Mat a c h m   => .Mat a c (Term.shift d h) (Term.shift d m)
  | .Efq           => .Efq
  | .Eql x y T     => .Eql (Term.shift d x) (Term.shift d y) (Term.shift d T)
  | .Rfl           => .Rfl
  | .Rwt e P f     => .Rwt (Term.shift d e) (Term.shift d P) (Term.shift d f)
  | .Let q v f     => .Let q (Term.shift d v) (Term.shift (d + 1) f)

def Term.subst (d : Nat) (w : Term) : Term → Term
  | .Var i         => if i = d then w else if d < i then .Var (i - 1) else .Var i
  | .Ref k         => .Ref k
  | .Typ g         => .Typ (Term.subst d w g)
  | .Qnt           => .Qnt
  | .Qua q         => .Qua q
  | .Min a b       => .Min (Term.subst d w a) (Term.subst d w b)
  | .All q A B     => .All q (Term.subst d w A) (Term.subst (d + 1) (Term.shift 0 w) B)
  | .Lam f         => .Lam (Term.subst (d + 1) (Term.shift 0 w) f)
  | .App f a       => .App (Term.subst d w f) (Term.subst d w a)
  | .Adt a r       => .Adt a r
  | .Ctr a c       => .Ctr a c
  | .Mat a c h m   => .Mat a c (Term.subst d w h) (Term.subst d w m)
  | .Efq           => .Efq
  | .Eql x y T     => .Eql (Term.subst d w x) (Term.subst d w y) (Term.subst d w T)
  | .Rfl           => .Rfl
  | .Rwt e P f     => .Rwt (Term.subst d w e) (Term.subst d w P) (Term.subst d w f)
  | .Let q v f     => .Let q (Term.subst d w v) (Term.subst (d + 1) (Term.shift 0 w) f)

def Term.Closed : Nat → Term → Prop
  | n, .Var i         => i < n
  | _, .Ref _         => True
  | n, .Typ g         => g.Closed n
  | _, .Qnt           => True
  | _, .Qua _         => True
  | n, .Min a b       => a.Closed n ∧ b.Closed n
  | n, .All _ A B     => A.Closed n ∧ B.Closed (n + 1)
  | n, .Lam f         => f.Closed (n + 1)
  | n, .App f a       => f.Closed n ∧ a.Closed n
  | _, .Adt _ _       => True
  | _, .Ctr _ _       => True
  | n, .Mat _ _ h m   => h.Closed n ∧ m.Closed n
  | _, .Efq           => True
  | n, .Eql a b T     => a.Closed n ∧ b.Closed n ∧ T.Closed n
  | _, .Rfl           => True
  | n, .Rwt e P f     => e.Closed n ∧ P.Closed n ∧ f.Closed n
  | n, .Let _ v f     => v.Closed n ∧ f.Closed (n + 1)

def Term.shiftN : Nat → Term → Term
  | 0,     t => t
  | n + 1, t => Term.shift 0 (Term.shiftN n t)

-- the J motive's type: over an equation {a == b : T}, the motive binds
-- the second endpoint and the equation itself (bend.ts check-rwt's p_typ)
def Term.jmotive (a T : Term) : Term :=
  .All .Lone T (.All .Lone (.Eql (Term.shift 0 a) (.Var 0) (Term.shift 0 T))
    (.Typ (.Qua .Lone)))

-- the left-hand-side algebra (bend.ts term_apply and lhs_ext): applying
-- a lambda equation beta-reduces it, and a peeled column becomes the
-- constructor of fn fresh fields, bound by fn lambdas
def Term.applyB : Term → Term → Term
  | .Lam f, a => Term.subst 0 a f
  | f,      a => .App f a

def Term.occ (d : Nat) : Term → Nat
  | .Var i         => if i = d then 1 else 0
  | .Ref _         => 0
  | .Typ g         => Term.occ d g
  | .Qnt           => 0
  | .Qua _         => 0
  | .Min a b       => Term.occ d a + Term.occ d b
  | .All _ A B     => Term.occ d A + Term.occ (d + 1) B
  | .Lam f         => Term.occ (d + 1) f
  | .App f a       => Term.occ d f + Term.occ d a
  | .Adt _ _       => 0
  | .Ctr _ _       => 0
  | .Mat _ _ h m   => Nat.max (Term.occ d h) (Term.occ d m)
  | .Efq           => 0
  | .Eql a b T     => Term.occ d a + Term.occ d b + Term.occ d T
  | .Rfl           => 0
  | .Rwt e P f     => Term.occ d e + Term.occ d P + Term.occ d f
  | .Let _ v b     => Term.occ d v + Term.occ (d + 1) b

-- the erasure wrapper: a dead check leaves the token, a live one its term
def Term.era : Quant → Term → Term
  | .None, _ => .Qnt
  | _,     u => u

def Term.lams : Nat → Term → Term
  | 0,     t => t
  | n + 1, t => .Lam (Term.lams n t)

def Term.rvars : Nat → List Term
  | 0     => []
  | n + 1 => .Var n :: Term.rvars n

def Term.lhsExt (lhs : Term) (a c fn : Nat) : Term :=
  Term.lams fn (Term.applyB (Term.shiftN fn lhs)
    (Term.apps (.Ctr a c) (Term.rvars fn)))

-- ============================================================================
-- §5 Ctx and Book (== bend.ts Ctx, Ctrs, Book, LHS)
-- ============================================================================

def Bind.shift (b : Bind) : Bind :=
  { b with T := Term.shift 0 b.T, v := b.v.map (Term.shift 0) }

def Ctx.get : Ctx → Nat → Option Bind
  | [], _         => none
  | b :: _, 0     => some b.shift
  | _ :: Γ, i + 1 => (Ctx.get Γ i).map Bind.shift

-- the let expansion of a context (bend.ts's Var.v, followed by wnf,
-- compare and descend): every let-bound variable is replaced by its
-- value, innermost binder first. d counts the term's own binders above
-- the context; a binder without a value joins them and stays rigid, so
-- the result mentions rigid binders only, renumbered alike on every term
-- the judgment compares
def Ctx.δ : Ctx → Nat → Term → Term
  | [], _, t => t
  | b :: Γ, d, t =>
    match b.v with
    | some v => Ctx.δ Γ d (Term.subst d (Term.shiftN d v) t)
    | none   => Ctx.δ Γ (d + 1) t

def Book.tld : Book → Nat → Option TLD
  | [], _         => none
  | d :: _, 0     => some d
  | _ :: β, k + 1 => Book.tld β k

def Book.adt (β : Book) (a : Nat) : Option AdtD :=
  match Book.tld β a with
  | some (.adt A) => some A
  | _             => none

def Book.defn (β : Book) (k : Nat) : Option DefD :=
  match Book.tld β k with
  | some (.defn d) => some d
  | _              => none

def AdtD.ctr : AdtD → Nat → Option CtrD :=
  fun A c => go A.ctrs c
where go : List CtrD → Nat → Option CtrD
  | [], _         => none
  | C :: _, 0     => some C
  | _ :: cs, c + 1 => go cs c

-- a family with the peeled set r has no constructor left (bend.ts
-- book_adt's filtered list is empty)
def Book.empty (β : Book) (a : Nat) (r : List Nat) : Prop :=
  ∃ A, Book.adt β a = some A ∧ ∀ c, c < A.ctrs.length → c ∈ r

-- the equation's walks: entering any binder shifts it; a Lam binds the
-- next column while one remains (check-lam); a Mat peels the next column
-- into a constructor of fn fresh fields (check-mat); the columns are the
-- arguments of its spine (lhs_descend)
def LHS.shift (L : LHS) : LHS := { L with t := Term.shift 0 L.t }

def LHS.lam (L : LHS) : LHS :=
  if L.n = 0 then L.shift
  else { L with t := Term.applyB (Term.shift 0 L.t) (.Var 0), n := L.n - 1 }

def LHS.mat (L : LHS) (a c fn : Nat) : LHS :=
  if L.n = 0 then L
  else { L with t := Term.lhsExt L.t a c fn, n := L.n - 1 + fn }

def LHS.cols (L : LHS) : List Term := (Term.spine L.t).2

-- the equation of no definition: the index past the book, so no reference
-- is a self-reference and every backward reference is allowed (the claims
-- are stated under it; a def body checks under its own)
def LHS.void (β : Book) : LHS := ⟨β.length, .Ref β.length, 0, []⟩

-- ============================================================================
-- §6 Descent (== bend.ts term_descend and lhs_descend: EQ columns then
-- one strict subterm, erased columns skipped)
-- ============================================================================

-- PEq β t p: argument t matches column pattern p exactly. A pattern is a
-- variable or a constructor of patterns (fields only, built by the walk);
-- a constructor argument carries its erased parameters, which the
-- comparison skips. Both pin their field-list arity to the declared C.fn:
-- bend.ts constructor nodes are n-ary and always full.
mutual
inductive PEq (β : Book) : Term → Term → Prop
  | var : PEq β (.Var i) (.Var i)
  | ctr : Book.adt β a = some A → AdtD.ctr A c = some C →
          ps.length = A.pn → xs.length = C.fn →
          PEqs β xs ys →
          PEq β (Term.apps (.Ctr a c) (ps ++ xs)) (Term.apps (.Ctr a c) ys)
inductive PEqs (β : Book) : List Term → List Term → Prop
  | nil  : PEqs β [] []
  | cons : PEq β x y → PEqs β xs ys → PEqs β (x :: xs) (y :: ys)
end

-- PLt β t p: t is a strict subterm of the pattern p — the same
-- constructor with pointwise <= fields, at least one strict, or <= some
-- field of p (bend.ts term_descend's LT verdicts)
mutual
inductive PLt (β : Book) : Term → Term → Prop
  | subEq : Book.adt β a = some A → AdtD.ctr A c = some C →
            ys.length = C.fn → y ∈ ys → PEq β t y →
            PLt β t (Term.apps (.Ctr a c) ys)
  | subLt : Book.adt β a = some A → AdtD.ctr A c = some C →
            ys.length = C.fn → y ∈ ys → PLt β t y →
            PLt β t (Term.apps (.Ctr a c) ys)
  | ctr   : Book.adt β a = some A → AdtD.ctr A c = some C →
            ps.length = A.pn → xs.length = C.fn →
            PLts β xs ys →
            PLt β (Term.apps (.Ctr a c) (ps ++ xs)) (Term.apps (.Ctr a c) ys)
inductive PLts (β : Book) : List Term → List Term → Prop
  | here  : PLt β x y → PLes β xs ys → PLts β (x :: xs) (y :: ys)
  | there : PEq β x y → PLts β xs ys → PLts β (x :: xs) (y :: ys)
inductive PLes (β : Book) : List Term → List Term → Prop
  | nil    : PLes β [] []
  | consEq : PEq β x y → PLes β xs ys → PLes β (x :: xs) (y :: ys)
  | consLt : PLt β x y → PLes β xs ys → PLes β (x :: xs) (y :: ys)
end

-- SpineLt β qs j cols args: from column j on, live columns compare EQ left
-- to right until one is a strict subterm; an erased column is skipped
-- (lhs_descend; a missing quantity counts live)
inductive SpineLt (β : Book) (qs : List Quant) : Nat → List Term → List Term → Prop
  | here  : qs.getD j .Lone ≠ .None → PLt β t c →
            SpineLt β qs j (c :: cs) (t :: ts)
  | skip  : qs.getD j .Lone = .None → SpineLt β qs (j + 1) cs ts →
            SpineLt β qs j (c :: cs) (t :: ts)
  | there : qs.getD j .Lone ≠ .None → PEq β t c →
            SpineLt β qs (j + 1) cs ts →
            SpineLt β qs j (c :: cs) (t :: ts)

-- ============================================================================
-- §7 Tele (== bend.ts Tele: telescope shapes)
-- ============================================================================

-- FTele a r ps k T: T is a telescope of k more field binders tipped at
-- the family a (peeled r) applied to the instantiated parameters ps
-- (which shift as binders open)
def FTele (a : Nat) (r : List Nat) : List Term → Nat → Term → Prop
  | ps, 0,     T => T = Term.apps (.Adt a r) ps
  | ps, k + 1, T => ∃ qf F B, T = .All qf F B ∧
      FTele a r (ps.map (Term.shift 0)) k B

-- WTele a r ps pn fn T: T is a telescope of pn more parameter binders,
-- each of its own quantity, then fn field binders, tipped at the family
-- applied to the parameters (those already instantiated in ps, then the
-- pn to come) — parse_adt's one telescope per constructor
def WTele (a : Nat) (r : List Nat) : List Term → Nat → Nat → Term → Prop
  | ps, 0,      fn, T => FTele a r ps fn T
  | ps, pn + 1, fn, T => ∃ q K B, T = .All q K B ∧
      WTele a r (ps.map (Term.shift 0) ++ [.Var 0]) pn fn B

-- the constructor telescope shape
def CtrD.Shape (a pn : Nat) (C : CtrD) : Prop :=
  WTele a [] [] pn C.fn C.ty

-- Insts T ps T': T' is the telescope T with its first |ps| binders
-- instantiated at ps (bend.ts tele_fill of a constructor's parameters
-- with the goal's)
inductive Insts : Term → List Term → Term → Prop
  | nil  : Insts T [] T
  | cons : Insts (Term.subst 0 p B) ps T' →
           Insts (.All q A B) (p :: ps) T'

-- ============================================================================
-- §8 Equal (== bend.ts WNF/SNF/Compare: reduction at two strengths;
-- conversion is joinability of strong runs, eta included; Le adds the
-- directional cases of compare LE)
-- ============================================================================

inductive Strength : Type
  | weak
  | strong

inductive Step (β : Book) (p : Strength) : Term → Term → Prop
  | beta  : Step β p (.App (.Lam f) a) (Term.subst 0 a f)
  | let_  : Step β p (.Let q v b) (Term.subst 0 v b)
  | dref  : Book.defn β k = some d →
            (Term.spine s).1 = .Ref k →
            (Term.spine s).2.length = d.n →
            Step β p s (Term.apps d.body (Term.spine s).2)
  | drefS : p = .strong → Book.defn β k = some d →
            (Term.spine s).1 = .Ref k →
            Step β p s (Term.apps d.body (Term.spine s).2)
  | aref  : Book.adt β k = some A → A.pn = 0 → Step β p (.Ref k) (.Adt k [])
  | matc  : Book.adt β a = some A → AdtD.ctr A c = some C →
            ps.length = A.pn → xs.length = C.fn →
            Step β p (.App (.Mat a c h m) (Term.apps (.Ctr a c) (ps ++ xs)))
                     (Term.apps h xs)
  | matm  : (a', c') ≠ (a, c) →
            Step β p (.App (.Mat a c h m) (Term.apps (.Ctr a' c') as))
                     (.App m (Term.apps (.Ctr a' c') as))
  | rwt   : Step β p (.Rwt .Rfl P f) f
  | minLM : Step β p (.Min (.Qua .Many) b) b
  | minLN : Step β p (.Min (.Qua .None) b) (.Qua .None)
  | minRM : Step β p (.Min a (.Qua .Many)) a
  | minRN : Step β p (.Min a (.Qua .None)) (.Qua .None)
  | minLL : Step β p (.Min (.Qua .Lone) (.Qua .Lone)) (.Qua .Lone)
  | eta   : p = .strong → Term.occ 0 F = 0 →
            Step β p (.Lam (.App F (.Var 0))) (Term.subst 0 .Qnt F)
  | typ_g : p = .strong → Step β p g g' → Step β p (.Typ g) (.Typ g')
  | min_a : Step β p a a' → Step β p (.Min a b) (.Min a' b)
  | min_b : Step β p b b' → Step β p (.Min a b) (.Min a b')
  | all_a : p = .strong → Step β p A A' → Step β p (.All q A B) (.All q A' B)
  | all_b : p = .strong → Step β p B B' → Step β p (.All q A B) (.All q A B')
  | lam_f : p = .strong → Step β p f f' → Step β p (.Lam f) (.Lam f')
  | app_f : Step β p f f' → Step β p (.App f a) (.App f' a)
  | app_a : Step β p a a' → Step β p (.App f a) (.App f a')
  | mat_h : Step β p h h' → Step β p (.Mat a c h m) (.Mat a c h' m)
  | mat_m : Step β p m m' → Step β p (.Mat a c h m) (.Mat a c h m')
  | eql_a : Step β p x x' → Step β p (.Eql x y T) (.Eql x' y T)
  | eql_b : Step β p y y' → Step β p (.Eql x y T) (.Eql x y' T)
  | eql_t : Step β p T T' → Step β p (.Eql x y T) (.Eql x y T')
  | rwt_e : Step β p e e' → Step β p (.Rwt e P f) (.Rwt e' P f)
  | rwt_p : Step β p P P' → Step β p (.Rwt e P f) (.Rwt e P' f)
  | rwt_f : Step β p f f' → Step β p (.Rwt e P f) (.Rwt e P f')
  | let_v : Step β p v v' → Step β p (.Let q v b) (.Let q v' b)
  | let_b : p = .strong → Step β p b b' → Step β p (.Let q v b) (.Let q v b')

inductive Red (β : Book) (p : Strength) : Term → Term → Prop
  | refl : Red β p t t
  | step : Step β p a b → Red β p b c → Red β p a c

-- compare EQ: joinability of strong runs
def Conv (β : Book) (a b : Term) : Prop :=
  ∃ c, Red β .strong a c ∧ Red β .strong b c

-- the kind order (compare LE at Typ): Kind(g) fits Kind(h) when g is &2,
-- or h is a literal under &2, or a meet on the left fits under both
-- sides, or a meet on the right fits under either, or the quantities
-- convert; a stuck quantity fits only itself
inductive KLe (β : Book) : Term → Term → Prop
  | many : Red β .strong g (.Qua .Many) → KLe β g h
  | lone : Red β .strong h (.Qua q) → q ≠ .Many → KLe β g h
  | minL : Red β .strong g (.Min g1 g2) → KLe β g1 h → KLe β g2 h → KLe β g h
  | minR1 : Red β .strong h (.Min h1 h2) → KLe β g h1 → KLe β g h
  | minR2 : Red β .strong h (.Min h1 h2) → KLe β g h2 → KLe β g h
  | conv : Conv β g h → KLe β g h

-- compare LE: a fits b. Conv everywhere, except that a kind is ordered by
-- KLe, a family with more constructors peeled fits one with fewer, and a
-- function type compares its domains swapped and its codomains along;
-- every part that flows both ways compares EQ
inductive Le (β : Book) : Term → Term → Prop
  | conv : Conv β a b → Le β a b
  | red  : Red β .strong a a' → Red β .strong b b' → Le β a' b' → Le β a b
  | typ  : KLe β g h → Le β (.Typ g) (.Typ h)
  | all  : Le β A' A → Le β B B' → Le β (.All q A B) (.All q A' B')
  | adt  : (∀ c, c ∈ r' → c ∈ r) → ps.length = ps'.length →
           (∀ (i : Nat) p p', ps[i]? = some p → ps'[i]? = some p' → Conv β p p') →
           Le β (Term.apps (.Adt a r) ps) (Term.apps (.Adt a r') ps')

-- weak-head values (bend.ts term_wnf's break-focus forms): a head that
-- no weak rule fires on, applied to any spine. A reference is stuck
-- when it is a parameterized family, or a definition kept closed by its
-- arity gate; a match is stuck on a scrutinee that
-- is a value but no constructor
inductive Term.Value (β : Book) : Term → Prop
  | var  : Term.Value β (Term.apps (.Var i) as)
  | typ  : Term.Value β (Term.apps (.Typ g) as)
  | qnt  : Term.Value β (Term.apps .Qnt as)
  | qua  : Term.Value β (Term.apps (.Qua q) as)
  | all  : Term.Value β (Term.apps (.All q A B) as)
  | lam  : Term.Value β (.Lam f)
  | mat  : Term.Value β (.Mat a c h m)
  | efq  : Term.Value β (Term.apps .Efq as)
  | eql  : Term.Value β (Term.apps (.Eql a b T) as)
  | rfl  : Term.Value β (Term.apps .Rfl as)
  | adt  : Term.Value β (Term.apps (.Adt a r) as)
  | ctr  : Term.Value β (Term.apps (.Ctr a c) as)
  | fam  : Book.adt β k = some A → 0 < A.pn →
           Term.Value β (Term.apps (.Ref k) as)
  | ref  : Book.defn β k = some d → as.length < d.n →
           Term.Value β (Term.apps (.Ref k) as)
  | min  : Term.Value β a → a ≠ .Qua .Many → a ≠ .Qua .None →
           Term.Value β b → b ≠ .Qua .Many → b ≠ .Qua .None →
           ¬ (a = .Qua .Lone ∧ b = .Qua .Lone) →
           Term.Value β (Term.apps (.Min a b) as)
  | rwt  : Term.Value β e → e ≠ .Rfl →
           Term.Value β (Term.apps (.Rwt e P f) as)
  | matS : Term.Value β x → (∀ a' c' xs, x ≠ Term.apps (.Ctr a' c') xs) →
           Term.Value β (Term.apps (.Mat a c h m) (x :: as))

-- ============================================================================
-- §9 Check (== bend.ts Check: one bidirectional judgment, with the
-- descent test of infer-ref and the lhs threading of check-lam/check-mat)
-- ============================================================================

-- MatGoal q' n B s tel G: G is the goal for a match arm handling a
-- constructor with n fields — the instantiated field telescope tel, each
-- field's quantity multiplied by the scrutinee's q', tipped at the motive
-- B applied to the constructor spine s rebuilt from the fields
-- (bend.ts term_check_mat_goal)
inductive MatGoal (q' : Quant) : Nat → Term → Term → Term → Term → Prop
  | zero : MatGoal q' 0 B s tel (Term.subst 0 s B)
  | succ : MatGoal q' n (Term.shift 1 B) (.App (Term.shift 0 s) (.Var 0)) Bf G →
           MatGoal q' (n + 1) B s (.All qf F Bf) (.All (Quant.mul qf q') F G)

-- retip r pn n ty: the type of a constructor head, from its declared
-- telescope of pn parameters and n - pn fields: the parameter binders
-- are erased (a value never carries its family's parameters — bend.ts
-- check-ctr reads them off the goal and checks only the fields), and the
-- Adt at the tip is reannotated with the peeled set r. A constructor
-- checks against the REMAINDER of its family (ctrs_find over book_adt's
-- filtered constructors): its head type here carries any peeled set that
-- does not contain it, which is what lets a mismatched scrutinee re-check
-- at the peeled domain of a match's tail
def Term.retip (r : List Nat) : Nat → Nat → Term → Term
  | 0, 0, t =>
    match (Term.spine t).1 with
    | .Adt a _ => Term.apps (.Adt a r) (Term.spine t).2
    | _        => t
  | pn + 1, n + 1, .All _ A B => .All .None A (Term.retip r pn n B)
  | 0, n + 1, .All q A B => .All q A (Term.retip r 0 n B)
  | _, _, t => t

-- CtxDead β Γ: some LIVE binding in scope has an emptied datatype, so the
-- region is unreachable (bend.ts ctx_dead, up to conversion: permission
-- (e); an erased binding proves nothing, since dead code inhabits Empty)
def CtxDead (β : Book) (Γ : Ctx) : Prop :=
  ∃ i b a r ps, Ctx.get Γ i = some b ∧ b.q ≠ .None ∧
    Conv β (Ctx.δ Γ 0 b.T) (Term.apps (.Adt a r) ps) ∧ Book.empty β a r

-- the judgment's two tests, as parameters: its conversion (compare LE)
-- and its ex-falso test (ctx_dead). bend.ts's are Le and CtxDead; the
-- metatheory also reads the same rules under a coarser conversion and no
-- ex-falso test when it reasons about dead code (PART II §K), where
-- quantities are moot
structure Pol : Type where
  conv : Term → Term → Prop
  efq  : Ctx → Prop

def Pol.std (β : Book) : Pol := ⟨Le β, CtxDead β⟩

-- Check β Φ L sp q Γ t T π u: under the equation L and the pending spine
-- sp (the arguments above t, infer-app's sp), at demand q, t has type T
-- consuming π, and elaborates to u: the certified term with every part
-- checked dead replaced by the token Quant (what the compiler runs;
-- bend.ts's Infer/Check answer tm, the same term with its dead parts kept
-- for printing). Demands are None and Lone only in any derivation rooted
-- at Book.Ok; Many is a measure value. A None-demand derivation measures
-- only None and elaborates to the token, and the rule that checks a
-- premise dead drops its measure from the conclusion, as in bend.ts.
inductive Check (β : Book) (Φ : Pol) :
    LHS → List Term → Quant → Ctx → Term → Term → Uses → Term → Prop
  -- Γ[i] = q' A
  -- ------------------------- infer-var
  -- Γ ⊢ x_i : A ~ {i : q}
  | var : Ctx.get Γ i = some b →
          Check β Φ L sp q Γ (.Var i) b.T (Uses.one i q) (Term.era q (.Var i))
  -- β[j] = def(T, v)
  -- where a live j precedes the def under check, or is it: a live
  --       self-reference (j = L.k) descends: its pending spine sp
  --       compares against L's columns, both let-expanded (lhs_descend)
  -- --------------------------------------------------------- infer-ref
  -- Γ ⊢ @j : T ~ {}
  | ref : Book.defn β j = some d →
          (q ≠ .None → j ≤ L.k) →
          (q ≠ .None → j = L.k →
            SpineLt β L.qs 0 (L.cols.map (Ctx.δ Γ 0)) (sp.map (Ctx.δ Γ 0))) →
          Check β Φ L sp q Γ (.Ref j) d.ty Uses.zero (Term.era q (.Ref j))
  -- β[k] = adt(sig, cs), nullary: the one bare-head spelling (a
  -- parameterized family head is an error: D<..> is the one spelling)
  -- --------------------------------------------------------- infer-ref (adt)
  -- Γ ⊢ @k : sig ~ {}
  | refA : Book.adt β k = some A → A.pn = 0 →
           Check β Φ L sp q Γ (.Ref k) A.sig Uses.zero (Term.era q (.Ref k))
  -- β[a] = adt(sig, cs)
  -- ------------------------- infer-adt (head; the parameters apply)
  -- Γ ⊢ Adt a r : sig ~ {}
  | adt : Book.adt β a = some A →
          Check β Φ L sp q Γ (.Adt a r) A.sig Uses.zero (Term.era q (.Adt a r))
  -- β[a].cs[c] = ctr(T)    c not peeled by r
  -- ----------------------------------------- check-ctr (head; the erased
  -- Γ ⊢ Ctr a c : retip r T ~ {}                parameters and the fields apply)
  | ctr : Book.adt β a = some A → AdtD.ctr A c = some C → c ∉ r →
          Check β Φ L sp q Γ (.Ctr a c) (Term.retip r A.pn (A.pn + C.fn) C.ty) Uses.zero
            (Term.era q (.Ctr a c))
  -- Γ ⊢ g : Quant    (dead)
  -- ------------------------- infer-typ
  -- Γ ⊢ Kind(g) : Type ~ {}
  | typ : Check β Φ L [] .None Γ g .Qnt πg .Qnt →
          Check β Φ L sp q Γ (.Typ g) (.Typ (.Qua .Lone)) Uses.zero
            (Term.era q (.Typ .Qnt))
  -- ------------------------- infer-qnt
  -- Γ ⊢ Quant : Type ~ {}      Γ ⊢ &q : Quant ~ {}
  | qnt : Check β Φ L sp q Γ .Qnt (.Typ (.Qua .Lone)) Uses.zero .Qnt
  | qua : Check β Φ L sp q Γ (.Qua q') .Qnt Uses.zero (Term.era q (.Qua q'))
  -- Γ ⊢ a : Quant ~ πa    Γ ⊢ b : Quant ~ πb    (both at the ambient demand)
  -- ------------------------------------------------ infer-min
  -- Γ ⊢ a <&> b : Quant ~ πa + πb
  | min : Check β Φ L [] q Γ a .Qnt πa ua →
          Check β Φ L [] q Γ b .Qnt πb ub →
          Check β Φ L sp q Γ (.Min a b) .Qnt (Uses.add πa πb) (Term.era q (.Min ua ub))
  -- Γ ⊢ A : Kind(q')    Γ, q' A ⊢ B : Type    (both dead)
  -- ------------------------------------------------ infer-all
  -- Γ ⊢ @q' A -> B : Type ~ {}
  | all : Check β Φ L [] .None Γ A (.Typ (.Qua q')) πA .Qnt →
          Check β Φ L.shift [] .None (⟨q', A, none⟩ :: Γ) B (.Typ (.Qua .Lone)) πB .Qnt →
          Check β Φ L sp q Γ (.All q' A B) (.Typ (.Qua .Lone)) Uses.zero
            (Term.era q (.All q' .Qnt .Qnt))
  -- Γ ⊢ A : Kind(q')    (dead: the goal's arrow was formed under infer-all)
  -- Γ, q' A ⊢ f : B ~ π    π[0] <= q'
  -- where L binds the next column by x while one remains
  -- ------------------------------------------------ check-lam
  -- Γ ⊢ λ f : @q' A -> B ~ tail π
  | lam : Check β Φ L [] .None Γ A (.Typ (.Qua q')) πA .Qnt →
          Check β Φ L.lam [] q (⟨q', A, none⟩ :: Γ) f B π uf →
          Quant.le (π 0) q' →
          Check β Φ L sp q Γ (.Lam f) (.All q' A B) (Uses.tail π) (Term.era q (.Lam uf))
  -- Γ ⊢ f : @q' A -> B ~ πf (with x pending)    Γ ⊢ x : A ~ πx at dem q' q
  -- where x is dead if q' is -, and consumed once otherwise: its measure
  --       adds unscaled (certify-once), a + callee copies it
  -- --------------------------------------------------------------- infer-app
  -- Γ ⊢ f(x) : B[0 := x] ~ πf + πx
  | app : Check β Φ L (x :: sp) q Γ f (.All q' A B) πf uf →
          Check β Φ L [] (Quant.dem q' q) Γ x A πx ux →
          Check β Φ L sp q Γ (.App f x) (Term.subst 0 x B) (Uses.add πf πx)
            (Term.era q (.App uf ux))
  -- Γ ⊢ f[0 := a] : T ~ π    (a in scope: bend.ts terms are always well-scoped)
  -- ------------------------------ infer-app (a lambda head: one beta step)
  -- Γ ⊢ (λ f)(a) : T ~ π
  | appLam : Term.Closed Γ.length a →
             Check β Φ L sp q Γ (Term.subst 0 a f) T π u →
             Check β Φ L sp q Γ (.App (.Lam f) a) T π u
  -- Γ ⊢ v : A ~ πv at dem qb q    Γ ⊢ A : Kind(qb)    (dead)
  -- Γ, qb A = v ⊢ b : T↑ ~ π    π[0] <= qb
  -- ------------------------------------------------------------------- check-let
  -- Γ ⊢ qb x = v; b : T ~ πv + tail π
  | let_ : Check β Φ L [] (Quant.dem qb q) Γ v A πv uv →
           Check β Φ L [] .None Γ A (.Typ (.Qua qb)) πA .Qnt →
           Check β Φ L.shift [] q (⟨qb, A, some v⟩ :: Γ) b (Term.shift 0 T) π ub →
           Quant.le (π 0) qb →
           Check β Φ L sp q Γ (.Let qb v b) T (Uses.add πv (Uses.tail π))
             (Term.era q (.Let qb uv ub))
  -- Γ ⊢ T : Type    Γ ⊢ a : T    Γ ⊢ b : T    (all dead; evidence is erased)
  -- --------------------------------------------------- infer-eql
  -- Γ ⊢ {a == b : T} : Data ~ {}
  | eql : Check β Φ L [] .None Γ T (.Typ (.Qua .Lone)) πT .Qnt →
          Check β Φ L [] .None Γ a T πa .Qnt →
          Check β Φ L [] .None Γ b T πb .Qnt →
          Check β Φ L sp q Γ (.Eql a b T) (.Typ (.Qua .Many)) Uses.zero
            (Term.era q (.Eql .Qnt .Qnt .Qnt))
  -- a == b    (let-expanded, compare EQ)
  -- ------------------------------ check-rfl
  -- Γ ⊢ {==} : {a == b : T} ~ {}
  | rfl : Conv β (Ctx.δ Γ 0 a) (Ctx.δ Γ 0 b) →
          Check β Φ L sp q Γ .Rfl (.Eql a b T) Uses.zero (Term.era q .Rfl)
  -- Γ ⊢ e : {a == b : T} ~ πe
  -- Γ ⊢ P : @x:T -> @_:{a == x : T} -> Type    (dead; the J motive)
  -- Γ ⊢ f : P(a, {==}) ~ πf
  -- ------------------------------------------ check-rwt
  -- Γ ⊢ %e : P; f : P(b, e) ~ πe + πf
  | rwt : Check β Φ L [] q Γ e (.Eql a b T) πe ue →
          Check β Φ L [] .None Γ P (Term.jmotive a T) πP .Qnt →
          Check β Φ L [] q Γ f (.App (.App P a) .Rfl) πf uf →
          Check β Φ L sp q Γ (.Rwt e P f) (.App (.App P b) e) (Uses.add πe πf)
            (Term.era q (.Rwt ue .Qnt uf))
  -- β[a].cs[c] : telescope, params instantiated at ps leaving telF
  -- Γ ⊢ h : fields of telF at field times q', tipped at B[Ctr a c · ps · fields] ~ πh
  -- Γ ⊢ m : @q' (Adt a (c :: r)) · ps -> B ~ πm
  -- where c is not already peeled, q' is live in a live region, and
  --       L peels the next column into c's fields for h
  -- --------------------------------------------------------------------- check-mat
  -- Γ ⊢ \{c: h; m} : @q' (Adt a r) · ps -> B ~ πh | πm
  | mat : Book.adt β a = some A → AdtD.ctr A c = some C →
          c ∉ r → ps.length = A.pn →
          (q ≠ .None → q' ≠ .None) →
          Insts C.ty ps telF →
          MatGoal q' C.fn B (Term.apps (.Ctr a c) ps) telF G →
          Check β Φ (L.mat a c C.fn) [] q Γ h G πh uh →
          Check β Φ L [] q Γ m (.All q' (Term.apps (.Adt a (c :: r)) ps) B) πm um →
          Check β Φ L sp q Γ (.Mat a c h m) (.All q' (Term.apps (.Adt a r) ps) B)
            (Uses.join πh πm) (Term.era q (.Mat a c uh um))
  -- every constructor of β[a] is peeled, or a LIVE binding in scope has an
  -- emptied type (ctx_dead, the policy's efq); q' is live in a live region
  -- --------------------------------------------------------------------- check-efq
  -- Γ ⊢ \{} : @q' (Adt a r) · ps -> B ~ {}
  | efq : Book.adt β a = some A →
          (q ≠ .None → q' ≠ .None) →
          (Book.empty β a r ∨ Φ.efq Γ) →
          Check β Φ L sp q Γ .Efq (.All q' (Term.apps (.Adt a r) ps) B) Uses.zero
            (Term.era q .Efq)
  -- Γ ⊢ t : A ~ π    A <= B    (let-expanded, the policy's conversion)
  -- ------------------------ check-any
  -- Γ ⊢ t : B ~ π
  | cnv : Check β Φ L sp q Γ t A π u → Φ.conv (Ctx.δ Γ 0 A) (Ctx.δ Γ 0 B) →
          Check β Φ L sp q Γ t B π u

-- ============================================================================
-- §10 Valid (== bend.ts Valid: book_valid, adt_valid, def_valid)
-- ============================================================================

-- STele n T G: the family signature, pn parameter binders tipped at a
-- term that weak-reduces to the kind Kind(G) (tele_unbind then the Typ
-- test of adt_valid; the declared kind may be an alias)
def STele (β : Book) : Nat → Term → Term → Prop
  | 0,     T, G => Red β .weak T (.Typ G)
  | n + 1, T, G => ∃ q K B, T = .All q K B ∧ STele β n B G

-- TeleQs β T n qs: the quantities of the first n binders of a def's type,
-- each layer opened by wnf (tele_unbind; def_valid's qs)
inductive TeleQs (β : Book) : Term → Nat → List Quant → Prop
  | nil  : TeleQs β T 0 []
  | cons : Red β .weak T (.All q A B) → TeleQs β B n qs →
           TeleQs β T (n + 1) (q :: qs)

-- CtrOk β k pn G Γ i T: adt_valid's constructor walk. Binder i's domain
-- checks dead against Kind(q) for a parameter or a non-Lone field, and
-- against the family's kind Kind(G) (G shifted to the binder's depth)
-- for a live field, in the real constructor context
def CtrOk (β : Book) (k pn : Nat) (G : Term) : Ctx → Nat → Term → Prop
  | Γ, i, .All q A B =>
      (∃ π, Check β (Pol.std β) ⟨k, .Ref k, 0, []⟩ [] .None Γ A
        (.Typ (if pn ≤ i ∧ q = .Lone then Term.shiftN (i - pn) G else .Qua q)) π .Qnt) ∧
      CtrOk β k pn G (⟨q, A, none⟩ :: Γ) (i + 1) B
  | _, _, _ => True

-- Tree β n t: the flattener's output shape, a case tree over n columns
-- in binder order (match_flatten): a Lam binds a variable column, a Mat
-- peels a constructor column into fn field columns for its arm and keeps
-- the column for its tail, an Efq closes it, and below the columns any
-- term is a leaf. def_valid trusts this shape (parse_def_body builds it),
-- and check-mat's peel is sound only under it
inductive Tree (β : Book) : Nat → Term → Prop
  | leaf : Tree β 0 t
  | lam  : Tree β n f → Tree β (n + 1) (.Lam f)
  | mat  : Book.adt β a = some A → AdtD.ctr A c = some C →
           Tree β (n + C.fn) h → Tree β (n + 1) m → Tree β (n + 1) (.Mat a c h m)
  | efq  : Tree β (n + 1) .Efq

-- CtrsFull β n t: every constructor node of a body carries all of its
-- arguments (n pending ones above t). parse_def_body builds n-ary nodes,
-- so def_valid trusts this too; a lone or partial Ctr head is a function
-- value the model types (permission (b)) but the parser never emits
def Term.CtrsFull (β : Book) : Nat → Term → Prop
  | n, .App f a     => Term.CtrsFull β (n + 1) f ∧ Term.CtrsFull β 0 a
  | n, .Ctr a c     => ∀ A C, Book.adt β a = some A → AdtD.ctr A c = some C →
                       A.pn + C.fn ≤ n
  | _, .Lam f       => Term.CtrsFull β 0 f
  | _, .Let _ v b   => Term.CtrsFull β 0 v ∧ Term.CtrsFull β 0 b
  | _, .Mat _ _ h m => Term.CtrsFull β 0 h ∧ Term.CtrsFull β 0 m
  | _, .Min a b     => Term.CtrsFull β 0 a ∧ Term.CtrsFull β 0 b
  | _, .Rwt e _ f   => Term.CtrsFull β 0 e ∧ Term.CtrsFull β 0 f
  | _, _            => True

-- Book.Ok (book_valid): each family's signature checks dead against Type
-- and tips at a kind; each constructor has parse_adt's shape and passes
-- adt_valid's walk. Each definition's type checks dead against Type, its
-- column quantities are read off it, and its body is a case tree over
-- the columns that checks LIVE against the type under the def's own
-- equation, so every live call points backward or descends
def Book.Ok (β : Book) : Prop :=
  ∀ k t, Book.tld β k = some t →
    match t with
    | .adt A =>
        (∃ π, Check β (Pol.std β) ⟨k, .Ref k, 0, []⟩ [] .None [] A.sig
          (.Typ (.Qua .Lone)) π .Qnt) ∧
        ∃ G, STele β A.pn A.sig G ∧
        ∀ c C, AdtD.ctr A c = some C →
          CtrD.Shape k A.pn C ∧ CtrOk β k A.pn G [] 0 C.ty
    | .defn d =>
        (∃ π, Check β (Pol.std β) ⟨k, .Ref k, 0, []⟩ [] .None [] d.ty
          (.Typ (.Qua .Lone)) π .Qnt) ∧
        TeleQs β d.ty d.n d.qs ∧
        Tree β d.n d.body ∧ Term.CtrsFull β 0 d.body ∧
        ∃ π u, Check β (Pol.std β) ⟨k, .Ref k, d.n, d.qs⟩ [] .Lone [] d.body d.ty π u

-- ============================================================================
-- §11 Claims (bend.ts states these in prose; PART II proves them)
-- ============================================================================

def church_rosser : Prop :=
  ∀ (β : Book) (a b c : Term),
    Book.Ok β → Red β .strong a b → Red β .strong a c →
    ∃ d, Red β .strong b d ∧ Red β .strong c d

-- LiveStep β t u t': a weak step of t at a position its elaboration u
-- keeps. A dead argument, an equality endpoint or a motive never runs
-- (comp.ts erased it) and preserves nothing (a dead term may inhabit
-- Empty); and the argument of a beta redex is not stepped (bend.ts fires
-- the redex first: permission (d))
inductive LiveStep (β : Book) : Term → Term → Term → Prop
  | beta  : LiveStep β (.App (.Lam f) a) u (Term.subst 0 a f)
  | let_  : LiveStep β (.Let q v b) u (Term.subst 0 v b)
  | dref  : Book.defn β k = some d →
            (Term.spine s).1 = .Ref k → (Term.spine s).2.length = d.n →
            LiveStep β s u (Term.apps d.body (Term.spine s).2)
  | aref  : Book.adt β k = some A → A.pn = 0 → LiveStep β (.Ref k) u (.Adt k [])
  | matc  : Book.adt β a = some A → AdtD.ctr A c = some C →
            ps.length = A.pn → xs.length = C.fn →
            LiveStep β (.App (.Mat a c h m) (Term.apps (.Ctr a c) (ps ++ xs))) u
              (Term.apps h xs)
  | matm  : (a', c') ≠ (a, c) →
            LiveStep β (.App (.Mat a c h m) (Term.apps (.Ctr a' c') as)) u
              (.App m (Term.apps (.Ctr a' c') as))
  | rwt   : LiveStep β (.Rwt .Rfl P f) u f
  | minLM : LiveStep β (.Min (.Qua .Many) b) u b
  | minLN : LiveStep β (.Min (.Qua .None) b) u (.Qua .None)
  | minRM : LiveStep β (.Min a (.Qua .Many)) u a
  | minRN : LiveStep β (.Min a (.Qua .None)) u (.Qua .None)
  | minLL : LiveStep β (.Min (.Qua .Lone) (.Qua .Lone)) u (.Qua .Lone)
  | min_a : LiveStep β a ua a' → LiveStep β (.Min a b) (.Min ua ub) (.Min a' b)
  | min_b : LiveStep β b ub b' → LiveStep β (.Min a b) (.Min ua ub) (.Min a b')
  | app_f : LiveStep β f uf f' → LiveStep β (.App f x) (.App uf ux) (.App f' x)
  | app_a : (∀ g, f ≠ .Lam g) → ux ≠ .Qnt → LiveStep β x ux x' →
            LiveStep β (.App f x) (.App uf ux) (.App f x')
  | mat_h : LiveStep β h uh h' →
            LiveStep β (.Mat a c h m) (.Mat a c uh um) (.Mat a c h' m)
  | mat_m : LiveStep β m um m' →
            LiveStep β (.Mat a c h m) (.Mat a c uh um) (.Mat a c h m')
  | rwt_e : LiveStep β e ue e' → LiveStep β (.Rwt e P f) (.Rwt ue uP uf) (.Rwt e' P f)
  | rwt_f : LiveStep β f uf f' → LiveStep β (.Rwt e P f) (.Rwt ue uP uf) (.Rwt e P f')
  | let_v : LiveStep β v uv v' → uv ≠ .Qnt →
            LiveStep β (.Let q v b) (.Let q uv ub) (.Let q v' b)

def subject_reduction : Prop :=
  ∀ (β : Book) (t t' T : Term) (π : Uses) (u : Term),
    Book.Ok β →
    Check β (Pol.std β) (LHS.void β) [] .Lone [] t T π u → LiveStep β t u t' →
    ∃ π' u', Check β (Pol.std β) (LHS.void β) [] .Lone [] t' T π' u'

def progress : Prop :=
  ∀ (β : Book) (q : Quant) (t T : Term) (π : Uses) (u : Term),
    Book.Ok β → q ≠ .None → Check β (Pol.std β) (LHS.void β) [] q [] t T π u →
    Term.Value β t ∨ ∃ t', Step β .weak t t'

def normalization : Prop :=
  ∀ (β : Book) (t T : Term) (π : Uses) (u : Term),
    Book.Ok β →
    Check β (Pol.std β) (LHS.void β) [] .Lone [] t T π u →
    ∃ v π' u', Red β .weak t v ∧ Term.Value β v ∧
      Check β (Pol.std β) (LHS.void β) [] .Lone [] v T π' u'

-- no closed live term inhabits an emptied family: one with no
-- constructor, or one with every constructor peeled
def consistency : Prop :=
  ∀ (β : Book) (a : Nat) (r : List Nat) (ps : List Term)
    (t : Term) (π : Uses) (u : Term),
    Book.Ok β → Book.empty β a r →
    ¬ Check β (Pol.std β) (LHS.void β) [] .Lone [] t (Term.apps (.Adt a r) ps) π u



-- ============================================================================
-- ============================================================================
--
-- PART II — THE METATHEORY
--
-- Everything below proves the claims of §11. Nothing below is needed to
-- READ the language; nothing above depends on anything below. The
-- sections, in dependency order:
--
--   §A  the de Bruijn algebra of shift and subst
--   §B  parallel reduction and confluence (claim 1: church_rosser_holds)
--   §C  the Conv, KLe and Le preorders; head inversions and clashes
--   §D  closure, the dead fragment, weakening, closed substitution
--   §E  the inversion of every rule, spine typing, telescope transport
--   §G  value typing and canonical forms (claim 3: progress_holds)
--   §F  the erased book, live steps and subject reduction with the erasure
--       simulation (Check.step; claim 2 closes in §Z with consistency)
--   §N0 the machine's view: deep values, pricing (charges), weight
--   §N1 the multiset order on charges and its well-foundedness
--   §N2 the pricing algebra under substitution
--   §N3 what typing tells the machine: the affine occurrence bound, deep
--       values of Data type are inert, the strategy and its progress
--   §K  the dead policy (quantity-blind conversion, no ex-falso), open
--       substitution, preservation along strong steps modulo eta, and the
--       kinds of what a Data-kinded type reduces to (DataPol.dead)
--   §N4 the measure decreases at every strategy step; the unfold of a
--       definition decreases the charges (the descent verdicts)
--   §Z  the engine (norm_all) and claims 2, 4, 5 (normalization,
--       consistency, subject reduction)
--
-- ============================================================================
-- ============================================================================

-- ============================================================================
-- METATHEORY §A — the de Bruijn algebra of Term.shift / Term.subst
-- ============================================================================

theorem getD_append_left {d0 : α} : ∀ (l1 l2 : List α) (j : Nat),
    j < l1.length → (l1 ++ l2).getD j d0 = l1.getD j d0 := by
  intro l1
  induction l1 with
  | nil => intro l2 j hj; simp at hj
  | cons x xs ih =>
    intro l2 j hj
    cases j with
    | zero => rfl
    | succ j =>
      show (xs ++ l2).getD j d0 = xs.getD j d0
      exact ih l2 j (by simp only [List.length_cons] at hj; omega)

theorem getD_append_right {d0 : α} : ∀ (l1 l2 : List α) (j : Nat),
    (l1 ++ l2).getD (l1.length + j) d0 = l2.getD j d0 := by
  intro l1
  induction l1 with
  | nil =>
    intro l2 j
    simp only [List.nil_append, List.length_nil, Nat.zero_add]
  | cons x xs ih =>
    intro l2 j
    simp only [List.cons_append, List.length_cons]
    rw [show xs.length + 1 + j = (xs.length + j) + 1 from by omega]
    show (xs ++ l2).getD (xs.length + j) d0 = l2.getD j d0
    exact ih l2 j

theorem getD_mem {dft : α} : ∀ (l : List α) (i : Nat), i < l.length →
    l.getD i dft ∈ l := by
  intro l
  induction l with
  | nil => intro i hi; exact absurd hi (by simp)
  | cons x xs ih =>
    intro i hi
    cases i with
    | zero => exact List.mem_cons_self
    | succ i =>
      refine List.mem_cons_of_mem x ?_
      exact ih i (by simp only [List.length_cons] at hi; omega)

theorem map_getD (f : α → γ) (d0 : γ) (d1 : α) :
    ∀ (l : List α) (j : Nat), j < l.length →
    (l.map f).getD j d0 = f (l.getD j d1) := by
  intro l
  induction l with
  | nil => intro j hj; exact absurd hj (by simp)
  | cons x xs ih =>
    intro j hj
    cases j with
    | zero => rfl
    | succ j =>
      exact ih j (by simp only [List.length_cons] at hj; omega)

theorem Term.shift_shift (t : Term) : ∀ (d e : Nat), d ≤ e →
    (t.shift e).shift d = (t.shift d).shift (e + 1) := by
  induction t <;> intro d e h
  case Var i =>
    simp only [Term.shift]
    repeat' split
    all_goals try simp only [Term.shift]
    repeat' split
    all_goals first
    | rfl
    | (exfalso; omega)
    | (simp only [Term.Var.injEq]; omega)
  all_goals simp [Term.shift, *, Nat.succ_le_succ h]

theorem Term.shift_shift0 (t : Term) (d : Nat) :
    Term.shift (d + 1) (Term.shift 0 t) = Term.shift 0 (Term.shift d t) :=
  (Term.shift_shift t 0 d (Nat.zero_le d)).symm

theorem Term.subst_shift (t : Term) : ∀ (d : Nat) (w : Term),
    Term.subst d w (t.shift d) = t := by
  induction t <;> intro d w
  case Var i =>
    simp only [Term.shift]
    repeat' split
    all_goals try simp only [Term.subst]
    repeat' split
    all_goals first
    | rfl
    | (exfalso; omega)
    | (simp only [Term.Var.injEq]; omega)
  all_goals simp [Term.shift, Term.subst, *]

theorem Term.shift_subst_lt (t : Term) : ∀ (d e : Nat) (w : Term), d ≤ e →
    (Term.subst e w t).shift d = Term.subst (e + 1) (w.shift d) (t.shift d) := by
  induction t <;> intro d e w h
  case Var i =>
    simp only [Term.subst]
    repeat' split
    all_goals try simp only [Term.shift]
    repeat' split
    all_goals try simp only [Term.subst]
    repeat' split
    all_goals first
    | rfl
    | (exfalso; omega)
    | (simp only [Term.Var.injEq]; omega)
  all_goals simp [Term.shift, Term.subst, Term.shift_shift, *, Nat.succ_le_succ h]

theorem Term.shift_jmotive (a T : Term) (d : Nat) :
    Term.shift d (Term.jmotive a T)
      = Term.jmotive (Term.shift d a) (Term.shift d T) := by
  simp [Term.jmotive, Term.shift, Term.shift_shift0]

theorem Term.subst_jmotive (a T : Term) (d : Nat) (w : Term) :
    Term.subst d w (Term.jmotive a T)
      = Term.jmotive (Term.subst d w a) (Term.subst d w T) := by
  simp [Term.jmotive, Term.subst, Term.shift_subst_lt _ 0 d w (Nat.zero_le d)]

theorem Term.shift_subst_ge (t : Term) : ∀ (d e : Nat) (w : Term), e ≤ d →
    (Term.subst e w t).shift d = Term.subst e (w.shift d) (t.shift (d + 1)) := by
  induction t <;> intro d e w h
  case Var i =>
    simp only [Term.subst]
    repeat' split
    all_goals try simp only [Term.shift]
    repeat' split
    all_goals try simp only [Term.subst]
    repeat' split
    all_goals first
    | rfl
    | (exfalso; omega)
    | (simp only [Term.Var.injEq]; omega)
  all_goals simp [Term.shift, Term.subst, Term.shift_shift, *, Nat.succ_le_succ h]

theorem Term.subst_subst (t : Term) : ∀ (d e : Nat) (w u : Term), e ≤ d →
    Term.subst d w (Term.subst e u t)
      = Term.subst e (Term.subst d w u) (Term.subst (d + 1) (w.shift e) t) := by
  induction t <;> intro d e w u h
  case Var i =>
    simp only [Term.subst]
    repeat' split
    all_goals try simp only [Term.subst, Term.subst_shift]
    repeat' split
    all_goals first
    | rfl
    | (exfalso; omega)
    | (simp only [Term.Var.injEq]; omega)
  all_goals simp [Term.subst, Term.shift_shift, Term.shift_subst_lt,
                  *, Nat.succ_le_succ h]

theorem Term.shift_subst0 (t w : Term) (d : Nat) :
    (Term.subst 0 w t).shift d = Term.subst 0 (w.shift d) (t.shift (d + 1)) :=
  Term.shift_subst_ge t d 0 w (Nat.zero_le d)

theorem Term.subst_subst0 (t w u : Term) (d : Nat) :
    Term.subst d w (Term.subst 0 u t)
      = Term.subst 0 (Term.subst d w u) (Term.subst (d + 1) (w.shift 0) t) :=
  Term.subst_subst t d 0 w u (Nat.zero_le d)

theorem Term.Closed.mono (t : Term) : ∀ (n m : Nat), t.Closed n → n ≤ m →
    t.Closed m := by
  induction t <;> intro n m hc h <;> simp only [Term.Closed] at *
  case Var => omega
  case Typ ih => exact ih n m hc h
  case Min iha ihb => exact ⟨iha n m hc.1 h, ihb n m hc.2 h⟩
  case All ihA ihB => exact ⟨ihA n m hc.1 h, ihB (n+1) (m+1) hc.2 (by omega)⟩
  case Lam ihf => exact ihf (n+1) (m+1) hc (by omega)
  case App ihf iha => exact ⟨ihf n m hc.1 h, iha n m hc.2 h⟩
  case Mat ihh ihm => exact ⟨ihh n m hc.1 h, ihm n m hc.2 h⟩
  case Eql iha ihb ihT =>
    exact ⟨iha n m hc.1 h, ihb n m hc.2.1 h, ihT n m hc.2.2 h⟩
  case Rwt ihe ihP ihf =>
    exact ⟨ihe n m hc.1 h, ihP n m hc.2.1 h, ihf n m hc.2.2 h⟩
  case Let ihv ihb => exact ⟨ihv n m hc.1 h, ihb (n+1) (m+1) hc.2 (by omega)⟩

theorem Term.shift_closed (t : Term) : ∀ (n d : Nat), t.Closed n → n ≤ d →
    t.shift d = t := by
  induction t <;> intro n d hc h <;> simp only [Term.Closed] at hc <;>
    simp only [Term.shift]
  case Var => rw [if_pos (by omega)]
  case Typ ih => rw [ih n d hc h]
  case Min iha ihb => rw [iha n d hc.1 h, ihb n d hc.2 h]
  case All ihA ihB =>
    rw [ihA n d hc.1 h, ihB (n+1) (d+1) hc.2 (by omega)]
  case Lam ihf => rw [ihf (n+1) (d+1) hc (by omega)]
  case App ihf iha => rw [ihf n d hc.1 h, iha n d hc.2 h]
  case Mat ihh ihm => rw [ihh n d hc.1 h, ihm n d hc.2 h]
  case Eql iha ihb ihT =>
    rw [iha n d hc.1 h, ihb n d hc.2.1 h, ihT n d hc.2.2 h]
  case Rwt ihe ihP ihf =>
    rw [ihe n d hc.1 h, ihP n d hc.2.1 h, ihf n d hc.2.2 h]
  case Let ihv ihb =>
    rw [ihv n d hc.1 h, ihb (n+1) (d+1) hc.2 (by omega)]

theorem Term.occ_closed : ∀ (t : Term) (n d : Nat), t.Closed n → n ≤ d →
    Term.occ d t = 0 := by
  intro t
  induction t <;> intro n d hc hle <;>
    simp only [Term.occ, Term.Closed] at *
  case Var i => rw [if_neg (by omega)]
  case Typ ih => exact ih n d hc hle
  case Min iha ihb => rw [iha n d hc.1 hle, ihb n d hc.2 hle]
  case All ihA ihB =>
    rw [ihA n d hc.1 hle, ihB (n + 1) (d + 1) hc.2 (by omega)]
  case Lam ihf => exact ihf (n + 1) (d + 1) hc (by omega)
  case App ihf iha => rw [ihf n d hc.1 hle, iha n d hc.2 hle]
  case Mat ihh ihm =>
    rw [ihh n d hc.1 hle, ihm n d hc.2 hle]
    rfl
  case Eql iha ihb ihT =>
    rw [iha n d hc.1 hle, ihb n d hc.2.1 hle, ihT n d hc.2.2 hle]
  case Rwt ihe ihP ihf =>
    rw [ihe n d hc.1 hle, ihP n d hc.2.1 hle, ihf n d hc.2.2 hle]
  case Let ihv ihb =>
    rw [ihv n d hc.1 hle, ihb (n + 1) (d + 1) hc.2 (by omega)]

theorem Term.occ_shift_ge : ∀ (t : Term) (d e : Nat), e ≤ d →
    Term.occ (d + 1) (Term.shift e t) = Term.occ d t := by
  intro t
  induction t <;> intro d e he
  case Var i =>
    simp only [Term.shift]
    by_cases h1 : i < e
    · rw [if_pos h1]
      simp only [Term.occ]
      split <;> (try split) <;> omega
    · rw [if_neg h1]
      simp only [Term.occ]
      split <;> (try split) <;> omega
  all_goals simp [Term.shift, Term.occ, *, Nat.succ_le_succ he]

theorem Term.occ_apps (d : Nat) : ∀ (as : List Term) (f : Term),
    Term.occ d (Term.apps f as) = Term.occ d f + (as.map (Term.occ d)).sum := by
  intro as
  induction as with
  | nil => intro f; simp [Term.apps]
  | cons x xs ih =>
    intro f
    show Term.occ d (Term.apps (.App f x) xs) = _
    rw [ih (.App f x)]
    simp only [Term.occ, List.map, List.sum_cons]
    omega

-- substitution of a closed-value environment at depth d, one value at
-- a time — exactly the shape the drive's betas leave behind
def Term.msubstAt (d : Nat) : List Term → Term → Term
  | [],      t => t
  | v :: vs, t => Term.msubstAt d vs (Term.subst d v t)

theorem Term.occ_shift_lt : ∀ (t : Term) (i e : Nat), i < e →
    Term.occ i (Term.shift e t) = Term.occ i t := by
  intro t
  induction t <;> intro i e hie
  case Var j =>
    simp only [Term.shift]
    by_cases h1 : j < e
    · rw [if_pos h1]
    · rw [if_neg h1]
      simp only [Term.occ]
      rw [if_neg (by omega), if_neg (by omega)]
  all_goals simp [Term.shift, Term.occ, *, Nat.succ_lt_succ hie]

theorem Term.occ_shift_self : ∀ (t : Term) (e : Nat),
    Term.occ e (Term.shift e t) = 0 := by
  intro t
  induction t <;> intro e
  case Var j =>
    simp only [Term.shift]
    by_cases h1 : j < e
    · rw [if_pos h1]
      simp only [Term.occ]
      rw [if_neg (by omega)]
    · rw [if_neg h1]
      simp only [Term.occ]
      rw [if_neg (by omega)]
  all_goals simp [Term.shift, Term.occ, *]

-- occurrence bookkeeping for the eta rule: substitution at or above an
-- absent variable keeps it absent, and substituting an unused slot is
-- indifferent to the payload
theorem Term.occ_subst_lt_zero : ∀ (t : Term) (e i : Nat) (w : Term),
    i < e → Term.occ i t = 0 → Term.occ i w = 0 →
    Term.occ i (Term.subst e w t) = 0 := by
  intro t
  induction t <;> intro e i w hie ht hw <;>
    simp only [Term.subst, Term.occ] at ht ⊢
  case Var j =>
    by_cases h1 : j = e
    · rw [if_pos h1]; exact hw
    · rw [if_neg h1]
      by_cases h2 : e < j
      · rw [if_pos h2]
        simp only [Term.occ]
        rw [if_neg (by omega)]
      · rw [if_neg h2]
        simp only [Term.occ] at ht ⊢
        exact ht
  case Typ ih => exact ih e i w hie ht hw
  case Min iha ihb =>
    rw [iha e i w hie (by omega) hw, ihb e i w hie (by omega) hw]
  case All ihA ihB =>
    rw [ihA e i w hie (by omega) hw,
      ihB (e + 1) (i + 1) (Term.shift 0 w) (by omega) (by omega)
        (by rw [Term.occ_shift_ge w i 0 (Nat.zero_le i)]; exact hw)]
  case Lam ihf =>
    rw [ihf (e + 1) (i + 1) (Term.shift 0 w) (by omega) ht
      (by rw [Term.occ_shift_ge w i 0 (Nat.zero_le i)]; exact hw)]
  case App ihf iha =>
    rw [ihf e i w hie (by omega) hw, iha e i w hie (by omega) hw]
  case Mat ihh ihm =>
    rw [Nat.max_eq_zero_iff] at ht
    rw [ihh e i w hie (by omega) hw, ihm e i w hie (by omega) hw]
    simp
  case Eql iha ihb ihT =>
    rw [iha e i w hie (by omega) hw, ihb e i w hie (by omega) hw,
      ihT e i w hie (by omega) hw]
  case Rwt ihe ihP ihf =>
    rw [ihe e i w hie (by omega) hw, ihP e i w hie (by omega) hw,
      ihf e i w hie (by omega) hw]
  case Let ihv ihb =>
    rw [ihv e i w hie (by omega) hw,
      ihb (e + 1) (i + 1) (Term.shift 0 w) (by omega) (by omega)
        (by rw [Term.occ_shift_ge w i 0 (Nat.zero_le i)]; exact hw)]

theorem Term.occ_subst_zero : ∀ (t : Term) (e i : Nat) (w : Term),
    e ≤ i → Term.occ (i + 1) t = 0 → Term.occ i w = 0 →
    Term.occ i (Term.subst e w t) = 0 := by
  intro t
  induction t <;> intro e i w hei ht hw <;>
    simp only [Term.subst, Term.occ] at ht ⊢
  case Var j =>
    have hj : j ≠ i + 1 := by
      intro hj
      rw [if_pos hj] at ht
      simp at ht
    by_cases h1 : j = e
    · rw [if_pos h1]; exact hw
    · rw [if_neg h1]
      by_cases h2 : e < j
      · rw [if_pos h2]
        simp only [Term.occ]
        rw [if_neg (by omega)]
      · rw [if_neg h2]
        simp only [Term.occ]
        rw [if_neg (by omega)]
  case Typ ih => exact ih e i w hei ht hw
  case Min iha ihb =>
    rw [iha e i w hei (by omega) hw, ihb e i w hei (by omega) hw]
  case All ihA ihB =>
    rw [ihA e i w hei (by omega) hw,
      ihB (e + 1) (i + 1) (Term.shift 0 w) (by omega) (by omega)
        (by rw [Term.occ_shift_ge w i 0 (Nat.zero_le i)]; exact hw)]
  case Lam ihf =>
    rw [ihf (e + 1) (i + 1) (Term.shift 0 w) (by omega) ht
      (by rw [Term.occ_shift_ge w i 0 (Nat.zero_le i)]; exact hw)]
  case App ihf iha =>
    rw [ihf e i w hei (by omega) hw, iha e i w hei (by omega) hw]
  case Mat ihh ihm =>
    rw [Nat.max_eq_zero_iff] at ht
    rw [ihh e i w hei (by omega) hw, ihm e i w hei (by omega) hw]
    simp
  case Eql iha ihb ihT =>
    rw [iha e i w hei (by omega) hw, ihb e i w hei (by omega) hw,
      ihT e i w hei (by omega) hw]
  case Rwt ihe ihP ihf =>
    rw [ihe e i w hei (by omega) hw, ihP e i w hei (by omega) hw,
      ihf e i w hei (by omega) hw]
  case Let ihv ihb =>
    rw [ihv e i w hei (by omega) hw,
      ihb (e + 1) (i + 1) (Term.shift 0 w) (by omega) (by omega)
        (by rw [Term.occ_shift_ge w i 0 (Nat.zero_le i)]; exact hw)]

theorem Term.occ_zero_subst_irrel : ∀ (t : Term) (e : Nat) (w w' : Term),
    Term.occ e t = 0 → Term.subst e w t = Term.subst e w' t := by
  intro t
  induction t <;> intro e w w' ht <;>
    simp only [Term.subst, Term.occ] at ht ⊢
  case Var j =>
    by_cases h1 : j = e
    · exfalso
      rw [if_pos h1] at ht
      simp at ht
    · rw [if_neg h1, if_neg h1]
  case Typ ih => rw [ih e w w' ht]
  case Min iha ihb => rw [iha e w w' (by omega), ihb e w w' (by omega)]
  case All ihA ihB =>
    rw [ihA e w w' (by omega),
      ihB (e + 1) (Term.shift 0 w) (Term.shift 0 w') (by omega)]
  case Lam ihf => rw [ihf (e + 1) (Term.shift 0 w) (Term.shift 0 w') ht]
  case App ihf iha => rw [ihf e w w' (by omega), iha e w w' (by omega)]
  case Mat ihh ihm =>
    rw [Nat.max_eq_zero_iff] at ht
    rw [ihh e w w' (by omega), ihm e w w' (by omega)]
  case Eql iha ihb ihT =>
    rw [iha e w w' (by omega), ihb e w w' (by omega), ihT e w w' (by omega)]
  case Rwt ihe ihP ihf =>
    rw [ihe e w w' (by omega), ihP e w w' (by omega), ihf e w w' (by omega)]
  case Let ihv ihb =>
    rw [ihv e w w' (by omega),
      ihb (e + 1) (Term.shift 0 w) (Term.shift 0 w') (by omega)]

theorem Term.subst_var_eq_subst_above : ∀ (t : Term) (d : Nat) (w : Term),
    Term.occ (d + 1) t = 0 →
    Term.subst d (.Var d) t = Term.subst (d + 1) w t := by
  intro t
  induction t <;> intro d w ht <;>
    simp only [Term.subst, Term.occ] at ht ⊢
  case Var j =>
    have hj : j ≠ d + 1 := by
      intro he
      rw [if_pos he] at ht
      simp at ht
    by_cases h1 : j = d
    · rw [if_pos h1, if_neg (by omega), if_neg (by omega), h1]
    · rw [if_neg h1]
      by_cases h2 : d < j
      · rw [if_pos h2, if_neg (by omega), if_pos (by omega)]
      · rw [if_neg h2, if_neg (by omega), if_neg (by omega)]
  case Typ ih => rw [ih d w ht]
  case Min iha ihb => rw [iha d w (by omega), ihb d w (by omega)]
  case All ihA ihB =>
    rw [ihA d w (by omega)]
    have hs : Term.shift 0 (Term.Var d) = .Var (d + 1) := by
      simp only [Term.shift]
      rw [if_neg (by omega)]
    rw [hs, ihB (d + 1) (Term.shift 0 w) (by omega)]
  case Lam ihf =>
    have hs : Term.shift 0 (Term.Var d) = .Var (d + 1) := by
      simp only [Term.shift]
      rw [if_neg (by omega)]
    rw [hs, ihf (d + 1) (Term.shift 0 w) ht]
  case App ihf iha => rw [ihf d w (by omega), iha d w (by omega)]
  case Mat ihh ihm =>
    rw [Nat.max_eq_zero_iff] at ht
    rw [ihh d w (by omega), ihm d w (by omega)]
  case Eql iha ihb ihT =>
    rw [iha d w (by omega), ihb d w (by omega), ihT d w (by omega)]
  case Rwt ihe ihP ihf =>
    rw [ihe d w (by omega), ihP d w (by omega), ihf d w (by omega)]
  case Let ihv ihb =>
    rw [ihv d w (by omega)]
    have hs : Term.shift 0 (Term.Var d) = .Var (d + 1) := by
      simp only [Term.shift]
      rw [if_neg (by omega)]
    rw [hs, ihb (d + 1) (Term.shift 0 w) (by omega)]

theorem Term.subst_closed (t : Term) : ∀ (n d : Nat) (w : Term), t.Closed n →
    n ≤ d → Term.subst d w t = t := by
  induction t <;> intro n d w hc h <;> simp only [Term.Closed] at hc <;>
    simp only [Term.subst]
  case Var => rw [if_neg (by omega), if_neg (by omega)]
  case Typ ih => rw [ih n d w hc h]
  case Min iha ihb => rw [iha n d w hc.1 h, ihb n d w hc.2 h]
  case All ihA ihB =>
    rw [ihA n d w hc.1 h, ihB (n+1) (d+1) (w.shift 0) hc.2 (by omega)]
  case Lam ihf => rw [ihf (n+1) (d+1) (w.shift 0) hc (by omega)]
  case App ihf iha => rw [ihf n d w hc.1 h, iha n d w hc.2 h]
  case Mat ihh ihm => rw [ihh n d w hc.1 h, ihm n d w hc.2 h]
  case Eql iha ihb ihT =>
    rw [iha n d w hc.1 h, ihb n d w hc.2.1 h, ihT n d w hc.2.2 h]
  case Rwt ihe ihP ihf =>
    rw [ihe n d w hc.1 h, ihP n d w hc.2.1 h, ihf n d w hc.2.2 h]
  case Let ihv ihb =>
    rw [ihv n d w hc.1 h, ihb (n+1) (d+1) (w.shift 0) hc.2 (by omega)]

-- substituting an absent variable is a renaming that shift undoes
theorem Term.shift_subst_occ : ∀ (t : Term) (d : Nat) (w : Term),
    Term.occ d t = 0 → Term.shift d (Term.subst d w t) = t := by
  intro t
  induction t <;> intro d w ht <;> simp only [Term.subst, Term.occ] at ht ⊢
  case Var i =>
    have hne : i ≠ d := by intro h; rw [if_pos h] at ht; simp at ht
    rw [if_neg hne]
    split <;> simp only [Term.shift] <;> split <;>
      first | rfl | (exfalso; omega) | (simp only [Term.Var.injEq]; omega)
  case Typ ih => simp only [Term.shift, ih d w ht]
  case Min iha ihb => simp only [Term.shift, iha d w (by omega), ihb d w (by omega)]
  case All ihA ihB =>
    simp only [Term.shift, ihA d w (by omega), ihB (d + 1) _ (by omega)]
  case Lam ihf => simp only [Term.shift, ihf (d + 1) _ ht]
  case App ihf iha => simp only [Term.shift, ihf d w (by omega), iha d w (by omega)]
  case Mat ihh ihm =>
    rw [Nat.max_eq_zero_iff] at ht
    simp only [Term.shift, ihh d w ht.1, ihm d w ht.2]
  case Eql iha ihb ihT =>
    simp only [Term.shift, iha d w (by omega), ihb d w (by omega), ihT d w (by omega)]
  case Rwt ihe ihP ihf =>
    simp only [Term.shift, ihe d w (by omega), ihP d w (by omega), ihf d w (by omega)]
  case Let ihv ihb =>
    simp only [Term.shift, ihv d w (by omega), ihb (d + 1) _ (by omega)]
  all_goals simp [Term.shift]

theorem Ctx.get_succ (b : Bind) (Γ : Ctx) (i : Nat) :
    Ctx.get (b :: Γ) (i + 1) = (Ctx.get Γ i).map Bind.shift := rfl

theorem Ctx.δ_closed : ∀ (Γ : Ctx) (d : Nat) (t : Term), Term.Closed d t →
    Ctx.δ Γ d t = t := by
  intro Γ
  induction Γ with
  | nil => intro d t _; rfl
  | cons b Γ ih =>
    intro d t hc
    simp only [Ctx.δ]
    split
    · rw [Term.subst_closed t d d _ hc (Nat.le_refl d)]; exact ih d t hc
    · exact ih (d + 1) t (Term.Closed.mono t d (d + 1) hc (by omega))

-- ============================================================================
-- METATHEORY §A2 — the spine kit: Term.apps algebra and inversion.
-- Constructor values are Adt/Ctr-headed application spines; these are
-- the lemmas that let the redex rules (matc, matm) and the canonical-
-- form arguments decompose them.
-- ============================================================================

theorem Term.apps_append (f : Term) (xs ys : List Term) :
    Term.apps f (xs ++ ys) = Term.apps (Term.apps f xs) ys := by
  induction xs generalizing f with
  | nil => rfl
  | cons x xs ih => simp only [List.cons_append, Term.apps, ih]

theorem Term.apps_snoc (f : Term) (xs : List Term) (x : Term) :
    Term.apps f (xs ++ [x]) = .App (Term.apps f xs) x := by
  rw [Term.apps_append]; rfl

theorem getD_take {d0 : α} : ∀ (l : List α) (m i : Nat), i < m →
    (l.take m).getD i d0 = l.getD i d0 := by
  intro l
  induction l with
  | nil => intro m i _; simp
  | cons x xs ih =>
    intro m i him
    cases m with
    | zero => omega
    | succ m =>
      cases i with
      | zero => rfl
      | succ i =>
        show (xs.take m).getD i d0 = xs.getD i d0
        exact ih m i (by omega)

theorem take_getD_self (d0 : α) : ∀ (l : List α) (m : Nat),
    l.length = m + 1 → l.take m ++ [l.getD m d0] = l := by
  intro l
  induction l with
  | nil => intro m h; simp at h
  | cons x xs ih =>
    intro m h
    cases m with
    | zero =>
      simp only [List.length_cons] at h
      cases xs with
      | nil => rfl
      | cons y ys => simp at h
    | succ m =>
      show x :: (xs.take m ++ [xs.getD m d0]) = x :: xs
      rw [ih m (by simp only [List.length_cons] at h; omega)]

theorem Term.shift_apps (d : Nat) (f : Term) (xs : List Term) :
    Term.shift d (Term.apps f xs)
      = Term.apps (Term.shift d f) (xs.map (Term.shift d)) := by
  induction xs generalizing f with
  | nil => rfl
  | cons x xs ih => simp only [Term.apps, List.map, ih, Term.shift]

theorem Term.subst_apps (d : Nat) (w f : Term) (xs : List Term) :
    Term.subst d w (Term.apps f xs)
      = Term.apps (Term.subst d w f) (xs.map (Term.subst d w)) := by
  induction xs generalizing f with
  | nil => rfl
  | cons x xs ih => simp only [Term.apps, List.map, ih, Term.subst]

theorem Term.subst_apps_closed (d : Nat) (w : Term) {b : Term}
    (hbc : b.Closed 0) : ∀ (xs : List Term),
    Term.subst d w (Term.apps b xs) = Term.apps b (xs.map (Term.subst d w)) := by
  intro xs
  rw [Term.subst_apps, Term.subst_closed b 0 d w hbc (Nat.zero_le d)]

theorem Term.spine_apps_of (g : Term) :
    ∀ (xs : List Term), Term.spine (Term.apps g xs)
      = ((Term.spine g).1, (Term.spine g).2 ++ xs) := by
  intro xs
  induction xs generalizing g with
  | nil => simp [Term.apps]
  | cons x rest ih =>
    show Term.spine (Term.apps (.App g x) rest) = _
    rw [ih (.App g x)]
    simp [Term.spine]

theorem Term.spine_apps {h : Term} (hh : h.IsHead) (xs : List Term) :
    Term.spine (Term.apps h xs) = (h, xs) := by
  have hs : Term.spine h = (h, []) := by
    cases h <;> first
    | rfl
    | exact absurd hh (by simp [Term.IsHead])
  rw [Term.spine_apps_of h xs, hs]
  simp

theorem Term.apps_spine : ∀ (t : Term),
    Term.apps (Term.spine t).1 (Term.spine t).2 = t := by
  intro t
  induction t <;> try rfl
  case App f a ihf _ =>
    show Term.apps (Term.spine f).1 ((Term.spine f).2 ++ [a]) = _
    rw [Term.apps_snoc, ihf]

theorem Term.apps_head_inv {h h' : Term} (hh : h.IsHead) (hh' : h'.IsHead)
    {xs ys : List Term} (heq : Term.apps h xs = Term.apps h' ys) :
    h = h' ∧ xs = ys := by
  have e := congrArg Term.spine heq
  rw [Term.spine_apps hh, Term.spine_apps hh'] at e
  exact ⟨congrArg Prod.fst e, congrArg Prod.snd e⟩

-- an App equal to a spine over a head splits at the last argument
theorem apps_shape : ∀ (as : List Term) (h t : Term),
    Term.apps h as = t →
    (as = [] ∧ t = h) ∨
    ∃ as0 alast, as = as0 ++ [alast] ∧ t = .App (Term.apps h as0) alast := by
  intro as
  induction as with
  | nil => intro h t he; exact .inl ⟨_root_.rfl, he.symm⟩
  | cons x rest ih =>
    intro h t he
    rcases ih (.App h x) t he with ⟨h1, h2⟩ | ⟨r0, rl, h1, h2⟩
    · subst h1
      exact .inr ⟨[], x, _root_.rfl, h2⟩
    · subst h1
      exact .inr ⟨x :: r0, rl, _root_.rfl, h2⟩

theorem Term.app_eq_apps {h f a : Term} (hh : h.IsHead)
    {xs : List Term} (heq : Term.App f a = Term.apps h xs) :
    ∃ ys, xs = ys ++ [a] ∧ f = Term.apps h ys := by
  have e := congrArg Term.spine heq
  rw [Term.spine_apps hh] at e
  simp only [Term.spine] at e
  refine ⟨(Term.spine f).2, ?_, ?_⟩
  · have e2 := congrArg Prod.snd e
    simp only at e2
    exact e2.symm
  · have e1 : (Term.spine f).1 = h := congrArg Prod.fst e
    rw [← e1, Term.apps_spine]

-- the function of an application value is a value: the head is the same
-- and the spine is one shorter
theorem Term.Value.app_inv (hv : Term.Value β (.App f a)) : Term.Value β f := by
  generalize ht : Term.App f a = t0 at hv
  cases hv with
  | lam => exact Term.noConfusion ht
  | mat => exact Term.noConfusion ht
  | ref hk hg =>
    obtain ⟨ys, hys, hf⟩ := Term.app_eq_apps (by trivial) ht
    subst hf hys
    exact .ref hk (by simp at hg; omega)
  | @matS x as _ _ _ _ hx hne =>
    obtain ⟨ys, hys, hf⟩ := Term.app_eq_apps (by trivial) ht
    subst hf
    cases ys with
    | nil => exact .mat
    | cons y ys =>
      have h1 : x = y := (List.cons.inj hys).1
      subst h1
      exact .matS hx hne
  | _ =>
    obtain ⟨ys, _, hf⟩ := Term.app_eq_apps (by trivial) ht
    subst hf
    constructor <;> assumption

-- a value stays a value under a shift, and under the substitution of a
-- variable it does not mention
theorem Term.shift_inj (h : Term.shift d a = Term.shift d b) : a = b := by
  have := congrArg (Term.subst d .Qnt) h
  rwa [Term.subst_shift, Term.subst_shift] at this

theorem Term.Value.shift (hv : Term.Value β t) (d : Nat) :
    Term.Value β (Term.shift d t) := by
  induction hv <;> simp only [Term.shift_apps, Term.shift]
  case var => split <;> exact .var
  case ref hk hg => exact .ref hk (by simpa using hg)
  case min ha hb hab iha ihb =>
    exact .min iha (fun h => ‹_ ≠ _› (Term.shift_inj (b := .Qua .Many) h))
      (fun h => ‹_ ≠ _› (Term.shift_inj (b := .Qua .None) h)) ihb
      (fun h => ‹_ ≠ _› (Term.shift_inj (b := .Qua .Many) h))
      (fun h => ‹_ ≠ _› (Term.shift_inj (b := .Qua .None) h))
      (fun h => hab ⟨Term.shift_inj (b := .Qua .Lone) h.1,
        Term.shift_inj (b := .Qua .Lone) h.2⟩)
  case rwt hne ih => exact .rwt ih (fun h => hne (Term.shift_inj (b := .Rfl) h))
  case matS hne ih =>
    refine .matS ih ?_
    intro a' c' xs heq
    apply hne a' c' (xs.map (Term.subst d .Qnt))
    have := congrArg (Term.subst d .Qnt) heq
    rwa [Term.subst_shift, Term.subst_apps] at this
  all_goals constructor <;> assumption

theorem Term.Value.subst (hv : Term.Value β t) (ho : Term.occ d t = 0) (w : Term) :
    Term.Value β (Term.subst d w t) := by
  have inj : ∀ {a b : Term}, Term.occ d a = 0 → Term.subst d w a = b →
      Term.shift d b = b → a = b := by
    intro a b ha h hb
    rw [← Term.shift_subst_occ a d w ha, h, hb]
  induction hv <;> simp only [Term.subst_apps, Term.subst]
  case var i as =>
    rw [Term.occ_apps] at ho
    simp only [Term.occ] at ho
    rw [if_neg (by intro h; rw [if_pos h] at ho; omega)]
    split <;> exact .var
  case ref hk hg => exact .ref hk (by simpa using hg)
  case min a b as ha hb hab iha ihb =>
    rw [Term.occ_apps] at ho
    simp only [Term.occ] at ho
    exact .min (iha (by omega)) (fun h => ‹_ ≠ _› (inj (by omega) h _root_.rfl))
      (fun h => ‹_ ≠ _› (inj (by omega) h _root_.rfl)) (ihb (by omega))
      (fun h => ‹_ ≠ _› (inj (by omega) h _root_.rfl))
      (fun h => ‹_ ≠ _› (inj (by omega) h _root_.rfl))
      (fun h => hab ⟨inj (by omega) h.1 _root_.rfl, inj (by omega) h.2 _root_.rfl⟩)
  case rwt e P f as he hne ih =>
    rw [Term.occ_apps] at ho
    simp only [Term.occ] at ho
    exact .rwt (ih (by omega)) (fun h => hne (inj (by omega) h _root_.rfl))
  case matS x as hx hne ih =>
    rw [Term.occ_apps] at ho
    simp only [Term.occ, List.map_cons, List.sum_cons] at ho
    refine .matS (ih (by omega)) ?_
    intro a' c' xs heq
    apply hne a' c' (xs.map (Term.shift d))
    have := congrArg (Term.shift d) heq
    rwa [Term.shift_subst_occ _ _ _ (by omega), Term.shift_apps] at this
  all_goals constructor <;> assumption

-- a Ctr-headed spine is never a binder-former: the redex heads a spine
-- cannot be
theorem Term.apps_ctr_ne {a c : Nat} {as : List Term} {t : Term}
    (ht : t.IsHead) (hne : t ≠ .Ctr a c) :
    Term.apps (.Ctr a c) as ≠ t := by
  intro heq
  have e := congrArg Term.spine heq
  rw [Term.spine_apps (by trivial)] at e
  have hs : Term.spine t = (t, []) := by
    cases t <;> first
    | rfl
    | exact absurd ht (by simp [Term.IsHead])
  rw [hs] at e
  exact hne (congrArg Prod.fst e).symm

theorem Term.apps_adt_ne {a : Nat} {r : List Nat} {as : List Term} {t : Term}
    (ht : t.IsHead) (hne : t ≠ .Adt a r) :
    Term.apps (.Adt a r) as ≠ t := by
  intro heq
  have e := congrArg Term.spine heq
  rw [Term.spine_apps (by trivial)] at e
  have hs : Term.spine t = (t, []) := by
    cases t <;> first
    | rfl
    | exact absurd ht (by simp [Term.IsHead])
  rw [hs] at e
  exact hne (congrArg Prod.fst e).symm

def Term.size : Term → Nat
  | .Var _         => 1
  | .Ref _         => 1
  | .Typ g         => 1 + Term.size g
  | .Qnt           => 1
  | .Qua _         => 1
  | .Min a b       => 1 + Term.size a + Term.size b
  | .All _ A B     => 1 + Term.size A + Term.size B
  | .Lam f         => 1 + Term.size f
  | .App f a       => 1 + Term.size f + Term.size a
  | .Adt _ _       => 1
  | .Ctr _ _       => 1
  | .Mat _ _ h m   => 1 + Term.size h + Term.size m
  | .Efq           => 1
  | .Eql a b T     => 1 + Term.size a + Term.size b + Term.size T
  | .Rfl           => 1
  | .Rwt e P f     => 1 + Term.size e + Term.size P + Term.size f
  | .Let _ v b     => 1 + Term.size v + Term.size b

theorem Term.size_spine_arg : ∀ (t : Term), ∀ x ∈ (Term.spine t).2,
    Term.size x < Term.size t := by
  intro t
  induction t with
  | App f a ihf iha =>
    intro x hx
    simp only [Term.spine] at hx
    rcases List.mem_append.mp hx with h1 | h2
    · have := ihf x h1
      simp only [Term.size]
      omega
    · rw [List.mem_singleton.mp h2]
      simp only [Term.size]
      omega
  | _ =>
    intro x hx
    first
    | exact nomatch hx
    | (simp only [Term.spine] at hx; exact nomatch hx)

theorem Term.size_pos : ∀ t : Term, 1 ≤ Term.size t := by
  intro t
  cases t <;> simp only [Term.size] <;> omega

-- ============================================================================

-- ============================================================================
-- METATHEORY §B — confluence: parallel reduction and claim (1).
-- The parallel step develops redexes and congruences at once; the mat
-- redexes leave their spine arguments undeveloped (the congruent
-- closure catches them next lap), which keeps the relation first-order
-- and the diamond a derivation induction. Books must be closed for the
-- δ-rule to commute with substitution.
-- ============================================================================

def Book.Closed (β : Book) : Prop :=
  ∀ k t, Book.tld β k = some t →
    match t with
    | .adt A  => A.sig.Closed 0 ∧ ∀ c C, AdtD.ctr A c = some C → C.ty.Closed 0
    | .defn d => d.ty.Closed 0 ∧ d.body.Closed 0

theorem Book.Closed.defn (hβ : Book.Closed β) (h : Book.defn β k = some d) :
    d.ty.Closed 0 ∧ d.body.Closed 0 := by
  unfold Book.defn at h
  split at h
  case _ heq => cases h; exact hβ _ _ heq
  case _ => cases h

theorem Book.Closed.adtd (hβ : Book.Closed β) (h : Book.adt β a = some A) :
    A.sig.Closed 0 ∧ ∀ c C, AdtD.ctr A c = some C → C.ty.Closed 0 := by
  unfold Book.adt at h
  split at h
  case _ heq => cases h; exact hβ _ _ heq
  case _ => cases h

theorem Book.defn_adt_clash (hd : Book.defn β k = some d)
    (ha : Book.adt β k = some A) : False := by
  cases h : Book.tld β k with
  | none => simp [Book.defn, h] at hd
  | some t => cases t <;> simp [Book.defn, Book.adt, h] at hd ha

-- a spine never equals a different head
theorem Term.apps_ne {h t : Term} {xs : List Term} (hh : h.IsHead) (ht : t.IsHead)
    (hne : h ≠ t) : Term.apps h xs ≠ t :=
  fun heq => hne (Term.apps_head_inv (ys := []) hh ht heq).1

-- spine transport: shifting or substituting under a spine with a
-- shift-invariant head maps the arguments and keeps the head
theorem Term.spine_shift {s h : Term} (hh : (Term.spine s).1 = h)
    (hd : h.IsHead) (hs : Term.shift d h = h) :
    Term.spine (Term.shift d s) = (h, (Term.spine s).2.map (Term.shift d)) := by
  obtain ⟨ts, hts⟩ : ∃ ts, (Term.spine s).2 = ts := ⟨_, rfl⟩
  have hsp : s = Term.apps h ts := by
    rw [← hts, ← hh]; exact (Term.apps_spine s).symm
  rw [hts, hsp, Term.shift_apps, hs, Term.spine_apps hd]

theorem Term.spine_subst {s h : Term} (hh : (Term.spine s).1 = h)
    (hd : h.IsHead) (hs : Term.subst d w h = h) :
    Term.spine (Term.subst d w s) = (h, (Term.spine s).2.map (Term.subst d w)) := by
  obtain ⟨ts, hts⟩ : ∃ ts, (Term.spine s).2 = ts := ⟨_, rfl⟩
  have hsp : s = Term.apps h ts := by
    rw [← hts, ← hh]; exact (Term.apps_spine s).symm
  rw [hts, hsp, Term.subst_apps, hs, Term.spine_apps hd]

-- parallel reduction: every redex and congruence develops at once.
-- The mat rules treat the scrutinee as ONE developed premise and
-- extract its fields by spine surgery, which keeps the relation
-- first-order (no lists of sub-derivations).
inductive Par (β : Book) : Term → Term → Prop
  | var  : Par β (.Var i) (.Var i)
  | ref  : Par β (.Ref k) (.Ref k)
  | typ  : Par β g g' → Par β (.Typ g) (.Typ g')
  | qnt  : Par β .Qnt .Qnt
  | qua  : Par β (.Qua q) (.Qua q)
  | min  : Par β a a' → Par β b b' → Par β (.Min a b) (.Min a' b')
  | adt  : Par β (.Adt a r) (.Adt a r)
  | ctr  : Par β (.Ctr a c) (.Ctr a c)
  | efq  : Par β .Efq .Efq
  | rfl  : Par β .Rfl .Rfl
  | all  : Par β A A' → Par β B B' → Par β (.All q A B) (.All q A' B')
  | eta  : Term.occ 0 F = 0 → Par β F F' →
           Par β (.Lam (.App F (.Var 0))) (Term.subst 0 .Qnt F')
  | lam  : Par β f f' → Par β (.Lam f) (.Lam f')
  | app  : Par β f f' → Par β a a' → Par β (.App f a) (.App f' a')
  | mat  : Par β h h' → Par β m m' → Par β (.Mat a c h m) (.Mat a c h' m')
  | eql  : Par β x x' → Par β y y' → Par β T T' →
           Par β (.Eql x y T) (.Eql x' y' T')
  | rwt  : Par β e e' → Par β P P' → Par β f f' →
           Par β (.Rwt e P f) (.Rwt e' P' f')
  | let_ : Par β v v' → Par β b b' → Par β (.Let q v b) (.Let q v' b')
  | beta : Par β f f' → Par β a a' →
           Par β (.App (.Lam f) a) (Term.subst 0 a' f')
  | letr : Par β v v' → Par β b b' →
           Par β (.Let q v b) (Term.subst 0 v' b')
  | dref : Book.defn β k = some d →
           (Term.spine s).1 = .Ref k →
           (Term.spine s).2.length = args'.length →
           (∀ i, i < (Term.spine s).2.length →
             Par β ((Term.spine s).2.getD i .Qnt) (args'.getD i .Qnt)) →
           Par β s (Term.apps d.body args')
  | aref : Book.adt β k = some A → A.pn = 0 → Par β (.Ref k) (.Adt k [])
  | matc : Book.adt β a = some A → AdtD.ctr A c = some C →
           (Term.spine s).1 = .Ctr a c →
           (Term.spine s).2.length = A.pn + C.fn →
           Par β s s' → Par β h h' →
           Par β (.App (.Mat a c h m) s)
                 (Term.apps h' ((Term.spine s').2.drop A.pn))
  | matm : (Term.spine s).1 = .Ctr a' c' → (a', c') ≠ (a, c) →
           Par β s s' → Par β m m' →
           Par β (.App (.Mat a c h m) s) (.App m' s')
  | rwtr : Par β f f' → Par β (.Rwt .Rfl P f) f'
  | minLM : Par β b b' → Par β (.Min (.Qua .Many) b) b'
  | minLN : Par β (.Min (.Qua .None) b) (.Qua .None)
  | minRM : Par β a a' → Par β (.Min a (.Qua .Many)) a'
  | minRN : Par β (.Min a (.Qua .None)) (.Qua .None)
  | minLL : Par β (.Min (.Qua .Lone) (.Qua .Lone)) (.Qua .Lone)

-- pointwise parallel reduction on lists (a plain relation)
inductive Pars (β : Book) : List Term → List Term → Prop
  | nil  : Pars β [] []
  | cons : Par β x y → Pars β xs ys → Pars β (x :: xs) (y :: ys)

theorem Par.refl : ∀ (t : Term), Par β t t := by
  intro t
  induction t with
  | Var i => exact .var
  | Ref k => exact .ref
  | Typ g ih => exact .typ ih
  | Qnt => exact .qnt
  | Qua q => exact .qua
  | Min a b iha ihb => exact .min iha ihb
  | All q A B ihA ihB => exact .all ihA ihB
  | Lam f ihf => exact .lam ihf
  | App f a ihf iha => exact .app ihf iha
  | Adt a r => exact .adt
  | Ctr a c => exact .ctr
  | Mat a c h m ihh ihm => exact .mat ihh ihm
  | Efq => exact .efq
  | Eql x y T ihx ihy ihT => exact .eql ihx ihy ihT
  | Rfl => exact .rfl
  | Rwt e P f ihe ihP ihf => exact .rwt ihe ihP ihf
  | Let q v b ihv ihb => exact .let_ ihv ihb

theorem Pars.length (h : Pars β xs ys) : xs.length = ys.length := by
  induction h with
  | nil => rfl
  | cons _ _ ih => simp [ih]

theorem Pars.append (h1 : Pars β xs ys) (h2 : Pars β as bs) :
    Pars β (xs ++ as) (ys ++ bs) := by
  induction h1 with
  | nil => exact h2
  | cons hp _ ih => exact .cons hp ih

theorem Pars.drop (h : Pars β xs ys) : ∀ n, Pars β (xs.drop n) (ys.drop n) := by
  induction h with
  | nil => intro n; simp; exact Pars.nil
  | cons hp hrest ih =>
    intro n
    cases n with
    | zero => exact .cons hp hrest
    | succ n => exact ih n

-- parallel congruence through a spine
theorem Par.apps (hh : Par β h h') (has : Pars β as as') :
    Par β (Term.apps h as) (Term.apps h' as') := by
  induction has generalizing h h' with
  | nil => exact hh
  | cons hp _ ih => exact ih (.app hh hp)

theorem Step.par (s : Step β p a b) : Par β a b := by
  induction s with
  | beta => exact .beta (Par.refl _) (Par.refl _)
  | eta _ hocc => exact .eta hocc (Par.refl _)
  | drefS _ hk hsp =>
    exact .dref hk hsp _root_.rfl (fun i _ => Par.refl _)
  | let_ => exact .letr (Par.refl _) (Par.refl _)
  | dref hk hsp hlen =>
    exact Par.dref hk hsp _root_.rfl (fun i _ => Par.refl _)
  | aref hk h0 => exact .aref hk h0
  | matc h1 h2 h3 h4 =>
    rename_i a A c C h m ps xs
    have hd : ((Term.spine (Term.apps (.Ctr a c) (ps ++ xs))).2.drop A.pn) = xs := by
      rw [Term.spine_apps (by trivial)]
      show (ps ++ xs).drop A.pn = xs
      rw [← h3]
      exact List.drop_left
    have hp := Par.matc (m := m) h1 h2
      (by rw [Term.spine_apps (by trivial)])
      (by rw [Term.spine_apps (by trivial)]; simp [h3, h4])
      (Par.refl (Term.apps (.Ctr a c) (ps ++ xs))) (Par.refl h)
    rwa [hd] at hp
  | matm hne =>
    rename_i a' c' a c h m as
    exact Par.matm (s := Term.apps (.Ctr a' c') as)
      (by rw [Term.spine_apps (by trivial)]) hne (Par.refl _) (Par.refl _)
  | rwt => exact .rwtr (Par.refl _)
  | minLM => exact .minLM (Par.refl _)
  | minLN => exact .minLN
  | minRM => exact .minRM (Par.refl _)
  | minRN => exact .minRN
  | minLL => exact .minLL
  | typ_g _ _ ih => exact .typ ih
  | min_a _ ih => exact .min ih (Par.refl _)
  | min_b _ ih => exact .min (Par.refl _) ih
  | all_a _ _ ih => exact .all ih (Par.refl _)
  | all_b _ _ ih => exact .all (Par.refl _) ih
  | lam_f _ _ ih => exact .lam ih
  | app_f _ ih => exact .app ih (Par.refl _)
  | app_a _ ih => exact .app (Par.refl _) ih
  | mat_h _ ih => exact .mat ih (Par.refl _)
  | mat_m _ ih => exact .mat (Par.refl _) ih
  | eql_a _ ih => exact .eql ih (Par.refl _) (Par.refl _)
  | eql_b _ ih => exact .eql (Par.refl _) ih (Par.refl _)
  | eql_t _ ih => exact .eql (Par.refl _) (Par.refl _) ih
  | rwt_e _ ih => exact .rwt ih (Par.refl _) (Par.refl _)
  | rwt_p _ ih => exact .rwt (Par.refl _) ih (Par.refl _)
  | rwt_f _ ih => exact .rwt (Par.refl _) (Par.refl _) ih
  | let_v _ ih => exact .let_ ih (Par.refl _)
  | let_b _ _ ih => exact .let_ (Par.refl _) ih

-- the Red kit: strengths, chains, congruences at each rule's strength
theorem Step.strong (s : Step β p a b) : Step β .strong a b := by
  induction s with
  | beta => exact .beta
  | eta _ hocc => exact .eta _root_.rfl hocc
  | drefS _ hk hsp => exact .drefS _root_.rfl hk hsp
  | let_ => exact .let_
  | dref hk hsp hlen => exact .dref hk hsp hlen
  | aref hk h0 => exact .aref hk h0
  | matc h1 h2 h3 h4 => exact .matc h1 h2 h3 h4
  | matm h => exact .matm h
  | rwt => exact .rwt
  | minLM => exact .minLM
  | minLN => exact .minLN
  | minRM => exact .minRM
  | minRN => exact .minRN
  | minLL => exact .minLL
  | typ_g _ _ ih => exact .typ_g rfl ih
  | min_a _ ih => exact .min_a ih
  | min_b _ ih => exact .min_b ih
  | all_a _ _ ih => exact .all_a rfl ih
  | all_b _ _ ih => exact .all_b rfl ih
  | lam_f _ _ ih => exact .lam_f rfl ih
  | app_f _ ih => exact .app_f ih
  | app_a _ ih => exact .app_a ih
  | mat_h _ ih => exact .mat_h ih
  | mat_m _ ih => exact .mat_m ih
  | eql_a _ ih => exact .eql_a ih
  | eql_b _ ih => exact .eql_b ih
  | eql_t _ ih => exact .eql_t ih
  | rwt_e _ ih => exact .rwt_e ih
  | rwt_p _ ih => exact .rwt_p ih
  | rwt_f _ ih => exact .rwt_f ih
  | let_v _ ih => exact .let_v ih
  | let_b _ _ ih => exact .let_b rfl ih

theorem Red.strong (r : Red β p a b) : Red β .strong a b := by
  induction r with
  | refl => exact .refl
  | step s _ ih => exact .step s.strong ih

theorem Red.trans (r1 : Red β p a b) (r2 : Red β p b c) : Red β p a c := by
  induction r1 with
  | refl => exact r2
  | step s _ ih => exact .step s (ih r2)

theorem Red.one (s : Step β p a b) : Red β p a b := .step s .refl

-- a step congruence lifts to runs
theorem Red.congr {F : Term → Term}
    (hF : ∀ {a b}, Step β p a b → Step β p (F a) (F b))
    (r : Red β p a b) : Red β p (F a) (F b) := by
  induction r with
  | refl => exact .refl
  | step s _ ih => exact .step (hF s) ih

theorem Red.typ_g (r : Red β .strong g g') : Red β .strong (.Typ g) (.Typ g') :=
  Red.congr (F := fun g => .Typ g) (fun s => .typ_g rfl s) r
theorem Red.min_a (r : Red β p a a') : Red β p (.Min a b) (.Min a' b) :=
  Red.congr (F := fun a => .Min a b) (fun s => .min_a s) r
theorem Red.min_b (r : Red β p b b') : Red β p (.Min a b) (.Min a b') :=
  Red.congr (F := fun b => .Min a b) (fun s => .min_b s) r
theorem Red.all_a (r : Red β .strong A A') :
    Red β .strong (.All q A B) (.All q A' B) :=
  Red.congr (F := fun A => .All q A B) (fun s => .all_a rfl s) r
theorem Red.all_b (r : Red β .strong B B') :
    Red β .strong (.All q A B) (.All q A B') :=
  Red.congr (F := fun B => .All q A B) (fun s => .all_b rfl s) r
theorem Red.lam_f (r : Red β .strong f f') : Red β .strong (.Lam f) (.Lam f') :=
  Red.congr (F := fun f => .Lam f) (fun s => .lam_f rfl s) r
theorem Red.app_f (r : Red β p f f') : Red β p (.App f a) (.App f' a) :=
  Red.congr (F := fun f => .App f a) (fun s => .app_f s) r
theorem Red.app_a (r : Red β p a a') : Red β p (.App f a) (.App f a') :=
  Red.congr (F := fun a => .App f a) (fun s => .app_a s) r
theorem Red.mat_h (r : Red β p h h') : Red β p (.Mat a c h m) (.Mat a c h' m) :=
  Red.congr (F := fun h => .Mat a c h m) (fun s => .mat_h s) r
theorem Red.mat_m (r : Red β p m m') : Red β p (.Mat a c h m) (.Mat a c h m') :=
  Red.congr (F := fun m => .Mat a c h m) (fun s => .mat_m s) r
theorem Red.eql_a (r : Red β p x x') : Red β p (.Eql x y T) (.Eql x' y T) :=
  Red.congr (F := fun x => .Eql x y T) (fun s => .eql_a s) r
theorem Red.eql_b (r : Red β p y y') : Red β p (.Eql x y T) (.Eql x y' T) :=
  Red.congr (F := fun y => .Eql x y T) (fun s => .eql_b s) r
theorem Red.eql_t (r : Red β p T T') : Red β p (.Eql x y T) (.Eql x y T') :=
  Red.congr (F := fun T => .Eql x y T) (fun s => .eql_t s) r
theorem Red.rwt_e (r : Red β p e e') : Red β p (.Rwt e P f) (.Rwt e' P f) :=
  Red.congr (F := fun e => .Rwt e P f) (fun s => .rwt_e s) r
theorem Red.rwt_p (r : Red β p P P') : Red β p (.Rwt e P f) (.Rwt e P' f) :=
  Red.congr (F := fun P => .Rwt e P f) (fun s => .rwt_p s) r
theorem Red.rwt_f (r : Red β p f f') : Red β p (.Rwt e P f) (.Rwt e P f') :=
  Red.congr (F := fun f => .Rwt e P f) (fun s => .rwt_f s) r
theorem Red.let_v (r : Red β p v v') : Red β p (.Let q v b) (.Let q v' b) :=
  Red.congr (F := fun v => .Let q v b) (fun s => .let_v s) r
theorem Red.let_b (r : Red β .strong b b') :
    Red β .strong (.Let q v b) (.Let q v b') :=
  Red.congr (F := fun b => .Let q v b) (fun s => .let_b rfl s) r

-- a spine's head reduces
theorem Red.apps_f (r : Red β p f f') : ∀ (xs : List Term),
    Red β p (Term.apps f xs) (Term.apps f' xs) := by
  intro xs
  induction xs generalizing f f' with
  | nil => exact r
  | cons x xs ih => exact ih (Red.app_f r)

-- pointwise runs on lists
inductive Reds (β : Book) (p : Strength) : List Term → List Term → Prop
  | nil  : Reds β p [] []
  | cons : Red β p x y → Reds β p xs ys → Reds β p (x :: xs) (y :: ys)

theorem Reds.refl : ∀ (xs : List Term), Reds β p xs xs := by
  intro xs
  induction xs with
  | nil => exact .nil
  | cons x xs ih => exact .cons .refl ih

theorem Reds.length (h : Reds β p xs ys) : xs.length = ys.length := by
  induction h with
  | nil => rfl
  | cons _ _ ih => simp [ih]

theorem Reds.trans (h1 : Reds β p xs ys) (h2 : Reds β p ys zs) :
    Reds β p xs zs := by
  induction h1 generalizing zs with
  | nil => cases h2; exact .nil
  | cons hr hrest ih =>
    cases h2 with
    | cons hr2 hrest2 => exact .cons (hr.trans hr2) (ih hrest2)

theorem Reds.append (h1 : Reds β p xs ys) (h2 : Reds β p as bs) :
    Reds β p (xs ++ as) (ys ++ bs) := by
  induction h1 with
  | nil => exact h2
  | cons hr _ ih => exact .cons hr ih

-- indexed pointwise runs assemble into a Reds
theorem Reds.of_getD : ∀ {xs ys : List Term}, xs.length = ys.length →
    (∀ i, i < xs.length → Red β p (xs.getD i .Qnt) (ys.getD i .Qnt)) →
    Reds β p xs ys := by
  intro xs
  induction xs with
  | nil => intro ys hl _; cases ys with | nil => exact .nil | cons => simp at hl
  | cons x xs ih =>
    intro ys hl hr
    cases ys with
    | nil => simp at hl
    | cons y ys =>
      exact .cons (hr 0 (by simp)) (ih (by simp at hl; omega)
        (fun i hi => hr (i + 1) (by simp; omega)))

-- a spine's arguments reduce pointwise
theorem Red.apps_args (h : Reds β p as bs) : ∀ (f : Term),
    Red β p (Term.apps f as) (Term.apps f bs) := by
  induction h with
  | nil => intro f; exact .refl
  | cons hr _ ih => intro f; exact ((Red.app_a hr).apps_f _).trans (ih _)

-- stability: a parallel reduct of a Ctr-headed spine is a Ctr-headed
-- spine with pointwise-parallel arguments
theorem Par.ctr_spine_inv (hp : Par β s t) :
    ∀ {a c : Nat} {as : List Term}, s = Term.apps (.Ctr a c) as →
    ∃ as', t = Term.apps (.Ctr a c) as' ∧ Pars β as as' := by
  induction hp <;> intro a c as heq
  all_goals try exact absurd heq.symm (Term.apps_ne (by trivial) (by trivial) (fun h => Term.noConfusion h))
  all_goals try (obtain ⟨ys, _, hfy⟩ := Term.app_eq_apps (by trivial) heq
                 exact absurd hfy.symm (Term.apps_ne (by trivial) (by trivial) (fun h => Term.noConfusion h)))
  case ctr =>
    obtain ⟨h1, h2⟩ := Term.apps_head_inv (h := Term.Ctr _ _) (by trivial)
      (by trivial) (xs := []) heq
    cases h1
    cases h2
    exact ⟨[], _root_.rfl, .nil⟩
  case app _ _ _ _ hf ha ihf _ =>
    obtain ⟨ys, hys, hfy⟩ := Term.app_eq_apps (by trivial) heq
    obtain ⟨ys', hy1, hy2⟩ := ihf hfy
    subst hys hy1
    exact ⟨ys' ++ [_], (Term.apps_snoc _ _ _).symm,
      Pars.append hy2 (.cons ha .nil)⟩
  case dref _ _ _ _ _ hsp _ _ _ =>
    rw [heq, Term.spine_apps (by trivial)] at hsp
    exact Term.noConfusion hsp

-- spine-form of stability
theorem Par.spine_stable (hp : Par β s t) (hh : (Term.spine s).1 = .Ctr a c) :
    (Term.spine t).1 = .Ctr a c ∧ Pars β (Term.spine s).2 (Term.spine t).2 := by
  have hs : s = Term.apps (.Ctr a c) (Term.spine s).2 := by
    rw [← hh]; exact (Term.apps_spine s).symm
  obtain ⟨as', ht, hps⟩ := hp.ctr_spine_inv hs
  rw [ht, Term.spine_apps (by trivial)]
  exact ⟨_root_.rfl, hps⟩

-- occurrence sums over spines
theorem List.occ_sum_zero_of_getD (d : Nat) : ∀ (as : List Term),
    (∀ i, i < as.length → Term.occ d (as.getD i .Qnt) = 0) →
    (as.map (Term.occ d)).sum = 0 := by
  intro as
  induction as with
  | nil => intro _; rfl
  | cons x xs ih =>
    intro h
    simp only [List.map, List.sum_cons]
    have h0 : Term.occ d x = 0 := h 0 (by simp)
    rw [h0, ih (fun i hi => h (i + 1) (by simp; omega))]

theorem List.occ_getD_zero_of_sum (d : Nat) : ∀ (as : List Term),
    (as.map (Term.occ d)).sum = 0 →
    ∀ i, i < as.length → Term.occ d (as.getD i .Qnt) = 0 := by
  intro as
  induction as with
  | nil => intro _ i hi; simp at hi
  | cons x xs ih =>
    intro h i hi
    simp only [List.map, List.sum_cons] at h
    cases i with
    | zero =>
      show Term.occ d x = 0
      omega
    | succ i =>
      refine ih (by omega) i (by simp only [List.length_cons] at hi; omega)

theorem List.occ_sum_drop_le (d : Nat) (n : Nat) : ∀ (as : List Term),
    ((as.drop n).map (Term.occ d)).sum ≤ (as.map (Term.occ d)).sum := by
  intro as
  induction as generalizing n with
  | nil => simp
  | cons x xs ih =>
    cases n with
    | zero => exact Nat.le_refl _
    | succ n =>
      simp only [List.drop, List.map, List.sum_cons]
      exact Nat.le_trans (ih n) (by omega)

-- parallel reduction preserves absence of a variable (each rule either
-- keeps subterms, substitutes an absent slot, or splices a closed body)
theorem Par.occ_zero (hβ : Book.Closed β) (hp : Par β t t') :
    ∀ (d : Nat), Term.occ d t = 0 → Term.occ d t' = 0 := by
  induction hp with
  | var => exact fun _ h => h
  | ref => exact fun _ h => h
  | typ _ ih => exact fun d h => ih d h
  | qnt => exact fun _ h => h
  | qua => exact fun _ h => h
  | adt => exact fun _ h => h
  | ctr => exact fun _ h => h
  | efq => exact fun _ h => h
  | rfl => exact fun _ h => h
  | aref _ => exact fun _ _ => _root_.rfl
  | min _ _ iha ihb =>
    intro d h
    simp only [Term.occ] at h ⊢
    rw [iha d (by omega), ihb d (by omega)]
  | all _ _ ihA ihB =>
    intro d h
    simp only [Term.occ] at h ⊢
    rw [ihA d (by omega), ihB (d + 1) (by omega)]
  | lam _ ihf =>
    intro d h
    simp only [Term.occ] at h ⊢
    exact ihf (d + 1) h
  | app _ _ ihf iha =>
    intro d h
    simp only [Term.occ] at h ⊢
    rw [ihf d (by omega), iha d (by omega)]
  | mat _ _ ihh ihm =>
    intro d h
    simp only [Term.occ] at h ⊢
    rw [Nat.max_eq_zero_iff] at h
    rw [ihh d (by omega), ihm d (by omega)]
    simp
  | eql _ _ _ iha ihb ihT =>
    intro d h
    simp only [Term.occ] at h ⊢
    rw [iha d (by omega), ihb d (by omega), ihT d (by omega)]
  | rwt _ _ _ ihe ihP ihf =>
    intro d h
    simp only [Term.occ] at h ⊢
    rw [ihe d (by omega), ihP d (by omega), ihf d (by omega)]
  | let_ _ _ ihv ihb =>
    intro d h
    simp only [Term.occ] at h ⊢
    rw [ihv d (by omega), ihb (d + 1) (by omega)]
  | beta _ _ ihf iha =>
    intro d h
    simp only [Term.occ] at h
    exact Term.occ_subst_zero _ 0 d _ (Nat.zero_le d)
      (ihf (d + 1) (by omega)) (iha d (by omega))
  | letr _ _ ihv ihb =>
    intro d h
    simp only [Term.occ] at h
    exact Term.occ_subst_zero _ 0 d _ (Nat.zero_le d)
      (ihb (d + 1) (by omega)) (ihv d (by omega))
  | @eta F F' hocc hF ihF =>
    intro d h
    simp only [Term.occ] at h
    exact Term.occ_subst_zero F' 0 d .Qnt (Nat.zero_le d)
      (ihF (d + 1) (by omega)) _root_.rfl
  | @dref k dd s2 args' hk hsp hlen2 hargs ih =>
    intro d h
    have hs2 : s2 = Term.apps (.Ref k) (Term.spine s2).2 := by
      have h0 := Term.apps_spine s2
      rw [hsp] at h0
      exact h0.symm
    rw [hs2, Term.occ_apps] at h
    rw [Term.occ_apps]
    have hb0 : Term.occ d dd.body = 0 :=
      Term.occ_closed dd.body 0 d (hβ.defn hk).2 (Nat.zero_le d)
    rw [hb0]
    have hzs := List.occ_getD_zero_of_sum d (Term.spine s2).2 (by
      simp only [Term.occ] at h
      omega)
    have hz2 : (args'.map (Term.occ d)).sum = 0 := by
      refine List.occ_sum_zero_of_getD d args' ?_
      intro i hi
      exact ih i (by omega) d (hzs i (by omega))
    omega
  | @matc a A c C s2 s2' h0 h0' m0 hk hc hsp hlen hs hh ihs ihh =>
    intro d h
    simp only [Term.occ] at h
    rw [Term.occ_apps]
    have hh0 : Term.occ d h0 = 0 := by
      have hX : Nat.max (Term.occ d h0) (Term.occ d m0) = 0 := by omega
      exact (Nat.max_eq_zero_iff.mp hX).1
    have hs0 : Term.occ d s2' = 0 := ihs d (by omega)
    have hdec : s2' = Term.apps (Term.spine s2').1 (Term.spine s2').2 :=
      (Term.apps_spine s2').symm
    rw [hdec, Term.occ_apps] at hs0
    have hdrop := List.occ_sum_drop_le d A.pn (Term.spine s2').2
    have hh1 := ihh d hh0
    omega
  | @matm s2 a' c' a c s2' m0 m0' h0 hsp hne hs hm ihs ihm =>
    intro d h
    simp only [Term.occ] at h ⊢
    have hX : Nat.max (Term.occ d h0) (Term.occ d m0) = 0 := by omega
    rw [ihm d (Nat.max_eq_zero_iff.mp hX).2, ihs d (by omega)]
  | rwtr _ ihf =>
    intro d h
    simp only [Term.occ] at h
    exact ihf d (by omega)
  | minLM _ ih =>
    intro d h
    simp only [Term.occ] at h
    exact ih d (by omega)
  | minLN => exact fun _ _ => _root_.rfl
  | minRM _ ih =>
    intro d h
    simp only [Term.occ] at h
    exact ih d (by omega)
  | minRN => exact fun _ _ => _root_.rfl
  | minLL => exact fun _ _ => _root_.rfl

theorem Par.red (hβ : Book.Closed β) (hp : Par β a b) :
    Red β .strong a b := by
  induction hp with
  | @eta F F' hocc hF ih =>
    have hocc' : Term.occ 0 F' = 0 := Par.occ_zero hβ hF 0 hocc
    exact Red.trans (Red.lam_f (Red.app_f ih))
      (Red.one (Step.eta _root_.rfl hocc'))
  | var => exact .refl
  | ref => exact .refl
  | typ _ ih => exact Red.typ_g ih
  | qnt => exact .refl
  | qua => exact .refl
  | min _ _ iha ihb => exact (Red.min_a iha).trans (Red.min_b ihb)
  | adt => exact .refl
  | ctr => exact .refl
  | efq => exact .refl
  | rfl => exact .refl
  | all _ _ ihA ihB => exact (Red.all_a ihA).trans (Red.all_b ihB)
  | lam _ ihf => exact Red.lam_f ihf
  | app _ _ ihf iha => exact (Red.app_f ihf).trans (Red.app_a iha)
  | mat _ _ ihh ihm => exact (Red.mat_h ihh).trans (Red.mat_m ihm)
  | eql _ _ _ ihx ihy ihT =>
    exact ((Red.eql_a ihx).trans (Red.eql_b ihy)).trans (Red.eql_t ihT)
  | rwt _ _ _ ihe ihP ihf =>
    exact ((Red.rwt_e ihe).trans (Red.rwt_p ihP)).trans (Red.rwt_f ihf)
  | let_ _ _ ihv ihb => exact (Red.let_v ihv).trans (Red.let_b ihb)
  | beta _ _ ihf iha =>
    exact (((Red.app_f (Red.lam_f ihf)).trans (Red.app_a iha)).trans
      (Red.one .beta))
  | letr _ _ ihv ihb =>
    exact (((Red.let_v ihv).trans (Red.let_b ihb)).trans (Red.one .let_))
  | @dref k d s args' hk hsp hlen' hpar ih =>
    have hs : s = Term.apps (.Ref k) (Term.spine s).2 := by
      rw [← hsp]
      exact (Term.apps_spine s).symm
    have hstep : Step β .strong (Term.apps (.Ref k) args')
        (Term.apps d.body args') := by
      have h := Step.drefS (s := Term.apps (.Ref k) args') (p := .strong)
        _root_.rfl hk (by rw [Term.spine_apps (by trivial)])
      rw [Term.spine_apps (by trivial)] at h
      exact h
    rw [hs]
    exact (Red.apps_args (Reds.of_getD hlen' ih) _).trans (Red.one hstep)
  | aref hk h0 => exact Red.one (.aref hk h0)
  | matc h1 h2 h3 h4 hps hph ihs ihh =>
    rename_i a A c C s s' h h' m
    obtain ⟨hh', hargs⟩ := hps.spine_stable h3
    have hlen : (Term.spine s').2.length = A.pn + C.fn := by
      rw [← hargs.length]; exact h4
    obtain ⟨ts, hts⟩ : ∃ ts, (Term.spine s').2 = ts := ⟨_, _root_.rfl⟩
    rw [hts] at hlen
    rw [hts]
    have hs' : s' = Term.apps (.Ctr a c) (ts.take A.pn ++ ts.drop A.pn) := by
      rw [List.take_append_drop, ← hts, ← hh']
      exact (Term.apps_spine s').symm
    have hstep : Step β .strong (.App (.Mat a c h m) s')
        (Term.apps h (ts.drop A.pn)) := by
      rw [hs']
      exact Step.matc h1 h2 (by simp [List.length_take]; omega)
        (by simp [List.length_drop]; omega)
    exact ((Red.app_a ihs).trans (Red.one hstep)).trans (ihh.apps_f _)
  | matm h1 hne hps hphm ihs ihm =>
    rename_i s a' c' a c s' m m' h
    obtain ⟨hh', _⟩ := hps.spine_stable h1
    have hs' : s' = Term.apps (.Ctr a' c') (Term.spine s').2 := by
      rw [← hh']; exact (Term.apps_spine s').symm
    have hstep : Step β .strong (.App (.Mat a c h m) s') (.App m s') := by
      rw [hs']
      exact Step.matm hne
    exact ((Red.app_a ihs).trans (Red.one hstep)).trans (Red.app_f ihm)
  | rwtr _ ihf => exact (Red.one .rwt).trans ihf
  | minLM _ ih => exact (Red.one .minLM).trans ih
  | minLN => exact Red.one .minLN
  | minRM _ ih => exact (Red.one .minRM).trans ih
  | minRN => exact Red.one .minRN
  | minLL => exact Red.one .minLL

-- parallel reduction commutes with shift (closed book: δ-bodies are
-- fixed points of shift)
theorem Par.shift (hβ : Book.Closed β) (hp : Par β t t') :
    ∀ d, Par β (t.shift d) (t'.shift d) := by
  induction hp with
  | @eta F F' hocc hF ih =>
    intro d
    show Par β (.Lam (.App (Term.shift (d + 1) F)
      (Term.shift (d + 1) (.Var 0))))
      (Term.shift d (Term.subst 0 .Qnt F'))
    have h0 : Term.shift (d + 1) (Term.Var 0) = .Var 0 := by
      simp only [Term.shift]
      rw [if_pos (by omega)]
    have h1 : Term.shift d (Term.subst 0 .Qnt F')
        = Term.subst 0 .Qnt (Term.shift (d + 1) F') := by
      rw [Term.shift_subst_ge F' d 0 .Qnt (Nat.zero_le d)]
      rfl
    rw [h0, h1]
    exact .eta (by
        rw [Term.occ_shift_lt F 0 (d + 1) (by omega)]
        exact hocc)
      (ih (d + 1))
  | var => intro d; simp only [Term.shift]; split <;> exact .var
  | ref => intro d; exact .ref
  | typ _ ih => intro d; exact .typ (ih d)
  | qnt => intro d; exact .qnt
  | qua => intro d; exact .qua
  | min _ _ iha ihb => intro d; exact .min (iha d) (ihb d)
  | adt => intro d; exact .adt
  | ctr => intro d; exact .ctr
  | efq => intro d; exact .efq
  | rfl => intro d; exact .rfl
  | all _ _ ihA ihB => intro d; exact .all (ihA d) (ihB (d + 1))
  | lam _ ihf => intro d; exact .lam (ihf (d + 1))
  | app _ _ ihf iha => intro d; exact .app (ihf d) (iha d)
  | mat _ _ ihh ihm => intro d; exact .mat (ihh d) (ihm d)
  | eql _ _ _ ihx ihy ihT => intro d; exact .eql (ihx d) (ihy d) (ihT d)
  | rwt _ _ _ ihe ihP ihf => intro d; exact .rwt (ihe d) (ihP d) (ihf d)
  | let_ _ _ ihv ihb => intro d; exact .let_ (ihv d) (ihb (d + 1))
  | beta _ _ ihf iha =>
    intro d
    rw [Term.shift_subst0]
    exact .beta (ihf (d + 1)) (iha d)
  | letr _ _ ihv ihb =>
    intro d
    rw [Term.shift_subst0]
    exact .letr (ihv d) (ihb (d + 1))
  | @dref k dd s args' hk hsp hlen' hpar ih =>
    intro d
    have hc := (hβ.defn hk).2
    have hs : s = Term.apps (.Ref k) (Term.spine s).2 := by
      rw [← hsp]
      exact (Term.apps_spine s).symm
    rw [hs, Term.shift_apps, Term.shift_apps]
    simp only [Term.shift]
    rw [Term.shift_closed dd.body 0 d hc (Nat.zero_le d)]
    refine Par.dref hk
      (by rw [Term.spine_apps (by trivial)])
      (by
        rw [Term.spine_apps (by trivial)]
        simp only [List.length_map]
        exact hlen') ?_
    rw [Term.spine_apps (by trivial)]
    intro i hi
    simp only [List.length_map] at hi
    rw [map_getD (Term.shift d) .Qnt .Qnt _ i (by omega),
      map_getD (Term.shift d) .Qnt .Qnt args' i (by omega)]
    exact ih i (by omega) d
  | aref hk h0 => intro d; exact .aref hk h0
  | matc h1 h2 h3 h4 hps hph ihs ihh =>
    rename_i a A c C s s' h h' m
    intro d
    obtain ⟨hh', hargs⟩ := hps.spine_stable h3
    have e1 : (Term.spine (Term.shift d s)).1 = Term.Ctr a c := by
      rw [Term.spine_shift h3 (by trivial) _root_.rfl]
    have e2 : (Term.spine (Term.shift d s)).2.length = A.pn + C.fn := by
      rw [Term.spine_shift h3 (by trivial) _root_.rfl]; simpa using h4
    have e3 : Term.shift d (Term.apps h' ((Term.spine s').2.drop A.pn))
        = Term.apps (Term.shift d h')
            ((Term.spine (Term.shift d s')).2.drop A.pn) := by
      rw [Term.shift_apps, Term.spine_shift hh' (by trivial) _root_.rfl]
      show _ = Term.apps _ (((Term.spine s').2.map (Term.shift d)).drop A.pn)
      rw [List.map_drop]
    rw [show Term.shift d (.App (.Mat a c h m) s)
        = .App (.Mat a c (Term.shift d h) (Term.shift d m)) (Term.shift d s)
      from _root_.rfl, e3]
    exact Par.matc h1 h2 e1 e2 (ihs d) (ihh d)
  | matm h1 hne hps hphm ihs ihm =>
    rename_i s a' c' a c s' m m' h
    intro d
    exact Par.matm (by rw [Term.spine_shift h1 (by trivial) _root_.rfl]) hne
      (ihs d) (ihm d)
  | rwtr _ ihf => intro d; exact .rwtr (ihf d)
  | minLM _ ih => intro d; exact .minLM (ih d)
  | minLN => intro d; exact .minLN
  | minRM _ ih => intro d; exact .minRM (ih d)
  | minRN => intro d; exact .minRN
  | minLL => intro d; exact .minLL

-- parallel reduction is closed under substitution of parallel-reduced
-- terms (the beta case of the diamond)
theorem Par.subst (hβ : Book.Closed β) (hp : Par β t t') :
    ∀ d {w w'}, Par β w w' → Par β (Term.subst d w t) (Term.subst d w' t') := by
  induction hp with
  | @eta F F' hocc hF ih =>
    intro d w w' hw
    show Par β (.Lam (.App
      (Term.subst (d + 1) (Term.shift 0 w) F)
      (Term.subst (d + 1) (Term.shift 0 w) (.Var 0))))
      (Term.subst d w' (Term.subst 0 .Qnt F'))
    have h0 : Term.subst (d + 1) (Term.shift 0 w) (Term.Var 0)
        = .Var 0 := by
      simp only [Term.subst]
      rw [if_neg (by omega), if_neg (by omega)]
    have h1 : Term.subst d w' (Term.subst 0 .Qnt F')
        = Term.subst 0 .Qnt (Term.subst (d + 1) (Term.shift 0 w') F') := by
      rw [Term.subst_subst0 F' w' .Qnt d]
      rfl
    rw [h0, h1]
    refine .eta ?_ (ih (d + 1) (Par.shift hβ hw 0))
    exact Term.occ_subst_lt_zero F (d + 1) 0 (Term.shift 0 w) (by omega)
      hocc (Term.occ_shift_self w 0)
  | var =>
    intro d w w' hw
    simp only [Term.subst]
    split
    · exact hw
    · split <;> exact .var
  | ref => intro d w w' _; exact .ref
  | typ _ ih => intro d w w' hw; exact .typ (ih d hw)
  | qnt => intro d w w' _; exact .qnt
  | qua => intro d w w' _; exact .qua
  | min _ _ iha ihb => intro d w w' hw; exact .min (iha d hw) (ihb d hw)
  | adt => intro d w w' _; exact .adt
  | ctr => intro d w w' _; exact .ctr
  | efq => intro d w w' _; exact .efq
  | rfl => intro d w w' _; exact .rfl
  | all _ _ ihA ihB =>
    intro d w w' hw
    exact .all (ihA d hw) (ihB (d + 1) (hw.shift hβ 0))
  | lam _ ihf =>
    intro d w w' hw
    exact .lam (ihf (d + 1) (hw.shift hβ 0))
  | app _ _ ihf iha =>
    intro d w w' hw
    exact .app (ihf d hw) (iha d hw)
  | mat _ _ ihh ihm =>
    intro d w w' hw
    exact .mat (ihh d hw) (ihm d hw)
  | eql _ _ _ ihx ihy ihT =>
    intro d w w' hw
    exact .eql (ihx d hw) (ihy d hw) (ihT d hw)
  | rwt _ _ _ ihe ihP ihf =>
    intro d w w' hw
    exact .rwt (ihe d hw) (ihP d hw) (ihf d hw)
  | let_ _ _ ihv ihb =>
    intro d w w' hw
    exact .let_ (ihv d hw) (ihb (d + 1) (hw.shift hβ 0))
  | beta _ _ ihf iha =>
    intro d w w' hw
    rw [Term.subst_subst0]
    exact .beta (ihf (d + 1) (hw.shift hβ 0)) (iha d hw)
  | letr _ _ ihv ihb =>
    intro d w w' hw
    rw [Term.subst_subst0]
    exact .letr (ihv d hw) (ihb (d + 1) (hw.shift hβ 0))
  | @dref k dd s args' hk hsp hlen' hpar ih =>
    intro d w w' hw
    have hc := (hβ.defn hk).2
    have hs : s = Term.apps (.Ref k) (Term.spine s).2 := by
      rw [← hsp]
      exact (Term.apps_spine s).symm
    rw [hs, Term.subst_apps, Term.subst_apps]
    simp only [Term.subst]
    rw [Term.subst_closed dd.body 0 d w' hc (Nat.zero_le d)]
    refine Par.dref hk
      (by rw [Term.spine_apps (by trivial)])
      (by
        rw [Term.spine_apps (by trivial)]
        simp only [List.length_map]
        exact hlen') ?_
    rw [Term.spine_apps (by trivial)]
    intro i hi
    simp only [List.length_map] at hi
    rw [map_getD (Term.subst d w) .Qnt .Qnt _ i (by omega),
      map_getD (Term.subst d w') .Qnt .Qnt args' i (by omega)]
    exact ih i (by omega) d hw
  | aref hk h0 => intro d w w' _; exact .aref hk h0
  | matc h1 h2 h3 h4 hps hph ihs ihh =>
    rename_i a A c C s s' h h' m
    intro d w w' hw
    obtain ⟨hh', hargs⟩ := hps.spine_stable h3
    have e1 : (Term.spine (Term.subst d w s)).1 = Term.Ctr a c := by
      rw [Term.spine_subst h3 (by trivial) _root_.rfl]
    have e2 : (Term.spine (Term.subst d w s)).2.length = A.pn + C.fn := by
      rw [Term.spine_subst h3 (by trivial) _root_.rfl]; simpa using h4
    have e3 : Term.subst d w' (Term.apps h' ((Term.spine s').2.drop A.pn))
        = Term.apps (Term.subst d w' h')
            ((Term.spine (Term.subst d w' s')).2.drop A.pn) := by
      rw [Term.subst_apps, Term.spine_subst hh' (by trivial) _root_.rfl]
      show _ = Term.apps _ (((Term.spine s').2.map (Term.subst d w')).drop A.pn)
      rw [List.map_drop]
    rw [show Term.subst d w (.App (.Mat a c h m) s)
        = .App (.Mat a c (Term.subst d w h) (Term.subst d w m))
            (Term.subst d w s)
      from _root_.rfl, e3]
    exact Par.matc h1 h2 e1 e2 (ihs d hw) (ihh d hw)
  | matm h1 hne hps hphm ihs ihm =>
    rename_i s a' c' a c s' m m' h
    intro d w w' hw
    exact Par.matm (by rw [Term.spine_subst h1 (by trivial) _root_.rfl]) hne
      (ihs d hw) (ihm d hw)
  | rwtr _ ihf =>
    intro d w w' hw
    exact .rwtr (ihf d hw)
  | minLM _ ih => intro d w w' hw; exact .minLM (ih d hw)
  | minLN => intro d w w' _; exact .minLN
  | minRM _ ih => intro d w w' hw; exact .minRM (ih d hw)
  | minRN => intro d w w' _; exact .minRN
  | minLL => intro d w w' _; exact .minLL

-- inversion: parallel reducts of the binder-formers and literals keep
-- their shape
theorem Par.lam_inv (hp : Par β (.Lam f) t) :
    (∃ f', t = .Lam f' ∧ Par β f f')
    ∨ (∃ G G', f = .App G (.Var 0) ∧ Term.occ 0 G = 0 ∧
        t = Term.subst 0 .Qnt G' ∧ Par β G G') := by
  cases hp with
  | lam hf => exact Or.inl ⟨_, _root_.rfl, hf⟩
  | @eta G G' hocc hG =>
    exact Or.inr ⟨G, G', _root_.rfl, hocc, _root_.rfl, hG⟩
  | dref _ hsp _ _ => exact Term.noConfusion hsp

theorem Par.mat_inv (hp : Par β (.Mat a c h m) t) :
    ∃ h' m', t = .Mat a c h' m' ∧ Par β h h' ∧ Par β m m' := by
  cases hp with
  | mat hh hm => exact ⟨_, _, _root_.rfl, hh, hm⟩
  | dref _ hsp _ _ => exact Term.noConfusion hsp

theorem Par.rfl_inv (hp : Par β .Rfl t) : t = .Rfl := by
  cases hp with
  | rfl => exact _root_.rfl
  | dref _ hsp _ _ => exact Term.noConfusion hsp

theorem Par.qua_inv (hp : Par β (.Qua q) t) : t = .Qua q := by
  cases hp with
  | qua => exact _root_.rfl
  | dref _ hsp _ _ => exact Term.noConfusion hsp

-- a parallel reduct of a defined-reference-headed spine: either the
-- head survives with pointwise-parallel arguments, or the definition
-- fired (at or above arity) and the reduct is the body's spine
theorem Par.ref_spine_cases (hd : Book.defn β k = some d)
    (hp : Par β s t) :
    ∀ {as : List Term}, s = Term.apps (.Ref k) as →
    (∃ as', t = Term.apps (.Ref k) as' ∧ as.length = as'.length ∧
      (∀ i, i < as.length → Par β (as.getD i .Qnt) (as'.getD i .Qnt)))
    ∨ (∃ as', as.length = as'.length ∧
      (∀ i, i < as.length → Par β (as.getD i .Qnt) (as'.getD i .Qnt)) ∧
      t = Term.apps d.body as') := by
  induction hp <;> intro as heq
  all_goals try exact absurd heq.symm (Term.apps_ne (by trivial) (by trivial) (fun h => Term.noConfusion h))
  all_goals try (obtain ⟨ys, _, hfy⟩ := Term.app_eq_apps (by trivial) heq
                 exact absurd hfy.symm (Term.apps_ne (by trivial) (by trivial) (fun h => Term.noConfusion h)))
  case app f f' a a' hf ha ihf iha =>
    obtain ⟨as0, hys, hfy⟩ := Term.app_eq_apps (by trivial) heq
    subst hys
    have hsnocp : ∀ (xs xs' : List Term) (x x' : Term),
        xs.length = xs'.length →
        (∀ i, i < xs.length →
          Par β (xs.getD i .Qnt) (xs'.getD i .Qnt)) →
        Par β x x' →
        ∀ i, i < (xs ++ [x]).length →
          Par β ((xs ++ [x]).getD i .Qnt)
            ((xs' ++ [x']).getD i .Qnt) := by
      intro xs xs' x x' hl hp hx i hi
      simp only [List.length_append, List.length_cons,
        List.length_nil] at hi
      by_cases hix : i < xs.length
      · rw [getD_append_left _ _ i hix,
          getD_append_left _ _ i (by omega)]
        exact hp i hix
      · have hie : i = xs.length := by omega
        subst hie
        rw [show xs.length = xs.length + 0 from _root_.rfl,
          getD_append_right,
          show xs.length + 0 = xs'.length + 0 from by omega,
          getD_append_right]
        exact hx
    rcases ihf hfy with ⟨as0', ht', hl', hp'⟩ |
      ⟨as0', hl', hp', ht'⟩
    · subst ht'
      left
      refine ⟨as0' ++ [a'], by rw [Term.apps_snoc], by
        simp only [List.length_append, List.length_cons,
          List.length_nil]
        omega, hsnocp as0 as0' a a' hl' hp' ha⟩
    · subst ht'
      refine Or.inr ⟨as0' ++ [a'], by
        simp only [List.length_append, List.length_cons,
          List.length_nil]
        omega, hsnocp as0 as0' a a' hl' hp' ha, by
        rw [Term.apps_snoc]⟩
  case dref _ k2 s2 args2' hk2 hsp2 hlen2' hps2 _ =>
    subst heq
    rw [Term.spine_apps (by trivial)] at hsp2 hlen2' hps2
    injection hsp2 with hkk
    subst hkk
    rw [hk2] at hd
    cases hd
    exact Or.inr ⟨args2', hlen2', hps2, _root_.rfl⟩
  case aref hk2 _ =>
    obtain ⟨h1, h2⟩ := Term.apps_head_inv (xs := []) (by trivial) (by trivial) heq
    cases h1
    exact absurd hk2 (fun hA => Book.defn_adt_clash hd hA)
  case ref =>
    obtain ⟨h1, h2⟩ := Term.apps_head_inv (xs := []) (by trivial) (by trivial) heq
    cases h1
    subst h2
    exact Or.inl ⟨[], _root_.rfl, _root_.rfl, fun i hi => absurd hi (by simp)⟩

-- parallel congruence over an application spine
theorem Par.apps_congr {h h' : Term} (hh : Par β h h') :
    ∀ {args args' : List Term},
    args.length = args'.length →
    (∀ i, i < args.length →
      Par β (args.getD i .Qnt) (args'.getD i .Qnt)) →
    Par β (Term.apps h args) (Term.apps h' args') := by
  intro args
  induction args generalizing h h' with
  | nil =>
    intro args' hlen _
    cases args' with
    | cons _ _ => simp at hlen
    | nil => exact hh
  | cons a as ih =>
    intro args' hlen hp
    cases args' with
    | nil => simp at hlen
    | cons a' as' =>
      show Par β (Term.apps (.App h a) as) (Term.apps (.App h' a') as')
      refine ih (.app hh (hp 0 (by simp))) (by
          simp only [List.length_cons] at hlen
          omega)
        (fun i hi => hp (i + 1) (by
          simp only [List.length_cons]
          omega))

-- assemble pointwise joins into a joined list
theorem Par.pointwise_join : ∀ (n : Nat) (f g : Nat → Term),
    (∀ i, i < n → ∃ q, Par β (f i) q ∧ Par β (g i) q) →
    ∃ qs : List Term, qs.length = n ∧
      (∀ i, i < n →
        Par β (f i) (qs.getD i .Qnt) ∧ Par β (g i) (qs.getD i .Qnt)) := by
  intro n
  induction n with
  | zero =>
    intro f g h
    exact ⟨[], _root_.rfl, fun i hi => absurd hi (by omega)⟩
  | succ m ih =>
    intro f g h
    obtain ⟨q0, hq0⟩ := h 0 (by omega)
    obtain ⟨qs, hql, hqs⟩ := ih (fun i => f (i + 1)) (fun i => g (i + 1))
      (fun i hi => h (i + 1) (by omega))
    refine ⟨q0 :: qs, by simp [hql], ?_⟩
    intro i hi
    cases i with
    | zero => exact hq0
    | succ j => exact hqs j (by omega)

-- ============================================================================
-- METATHEORY §B2 — the diamond and claim (1). Induction on the first
-- derivation, inversion on the second; the mat cases are fed by spine
-- stability, the beta/let cases by Par.subst.
-- ============================================================================

theorem Par.diamond (hβ : Book.Closed β) :
    ∀ {t p1 p2 : Term}, Par β t p1 → Par β t p2 →
    ∃ q, Par β p1 q ∧ Par β p2 q := by
  suffices hall : ∀ (n : Nat) {t p1 p2 : Term}, Term.size t ≤ n →
      Par β t p1 → Par β t p2 → ∃ q, Par β p1 q ∧ Par β p2 q by
    intro t p1 p2 h1 h2
    exact hall (Term.size t) (Nat.le_refl _) h1 h2
  intro n
  induction n with
  | zero =>
    intro t p1 p2 hsz _ _
    have := Term.size_pos t
    omega
  | succ n IH =>
  intro t p1 p2 hsz h1 h2
  -- the eta interaction, shared by both orientations: one side
  -- contracts the wrapper, the other reduces inside the body
  have hetalam : ∀ {F F' B2' : Term}, Term.size F + 3 ≤ n + 1 →
      Term.occ 0 F = 0 → Par β F F' → Par β (.App F (.Var 0)) B2' →
      ∃ q, Par β (Term.subst 0 .Qnt F') q ∧ Par β (.Lam B2') q := by
    intro F F' B2' hszF hocc hF hB2
    cases hB2 with
    | @app _ Fa _ V' hFa hVa =>
      have hV : V' = .Var 0 := by
        cases hVa with
        | var => rfl
        | dref _ hsp _ _ => exact Term.noConfusion hsp
      subst hV
      have hocc2 : Term.occ 0 Fa = 0 := Par.occ_zero hβ hFa 0 hocc
      obtain ⟨F3, hF31, hF32⟩ := IH (t := F) (by omega) hF hFa
      exact ⟨Term.subst 0 .Qnt F3,
        Par.subst hβ hF31 0 .qnt,
        Par.eta hocc2 hF32⟩
    | @beta F0 F0' _ V' hf0 hv0 =>
      have hV : V' = .Var 0 := by
        cases hv0 with
        | var => rfl
        | dref _ hsp _ _ => exact Term.noConfusion hsp
      subst hV
      have hocc1 : Term.occ 1 F0 = 0 := hocc
      have hocc1' : Term.occ 1 F0' = 0 := Par.occ_zero hβ hf0 1 hocc1
      obtain ⟨Q, hQ1, hQ2⟩ := IH (t := .Lam F0) (by
        simp only [Term.size] at hszF ⊢
        omega) (Par.lam hf0) hF
      refine ⟨Term.subst 0 .Qnt Q, Par.subst hβ hQ2 0 .qnt, ?_⟩
      have hrw : Term.Lam (Term.subst 0 (.Var 0) F0')
          = Term.subst 0 .Qnt (.Lam F0') := by
        show _ = Term.Lam (Term.subst 1 (Term.shift 0 .Qnt) F0')
        rw [Term.subst_var_eq_subst_above F0' 0 (Term.shift 0 .Qnt)
          hocc1']
      rw [hrw]
      exact Par.subst hβ hQ1 0 .qnt
    | @dref k d s2x args' hk hsp hlen' hpar =>
      have hspF : (Term.spine F).1 = .Ref k := hsp
      have hsF : F = Term.apps (.Ref k) (Term.spine F).2 := by
        rw [← hspF]
        exact (Term.apps_spine F).symm
      have hbc : d.body.Closed 0 := (hβ.defn hk).2
      have hsp2eq : (Term.spine (Term.App F (.Var 0))).2
          = (Term.spine F).2 ++ [Term.Var 0] := _root_.rfl
      rw [hsp2eq, List.length_append] at hlen'
      have hm1 : (Term.spine F).2.length + 1 = args'.length := by
        simp only [List.length_cons, List.length_nil] at hlen'
        omega
      have hoccas : ∀ i, i < (Term.spine F).2.length →
          Term.occ 0 ((Term.spine F).2.getD i .Qnt) = 0 := by
        refine List.occ_getD_zero_of_sum 0 _ ?_
        have h0 : Term.occ 0 F = 0 := hocc
        rw [hsF, Term.occ_apps] at h0
        omega
      -- the fresh variable rides in the last argument slot
      have hlast : args'.getD (Term.spine F).2.length .Qnt = .Var 0 := by
        have hp := hpar (Term.spine F).2.length (by
          rw [hsp2eq, List.length_append]
          simp only [List.length_cons, List.length_nil]
          omega)
        have hg : ((Term.spine F).2 ++ [Term.Var 0]).getD
            (Term.spine F).2.length .Qnt = .Var 0 := by
          rw [show (Term.spine F).2.length
              = (Term.spine F).2.length + 0 from _root_.rfl,
            getD_append_right]
          rfl
        rw [hsp2eq, hg] at hp
        generalize hx : args'.getD (Term.spine F).2.length .Qnt = X at hp ⊢
        cases hp with
        | var => rfl
        | dref _ hsp2 _ _ => exact Term.noConfusion hsp2
      have hsplit : args' = args'.take (Term.spine F).2.length
          ++ [.Var 0] := by
        rw [← hlast]
        exact (take_getD_self .Qnt args' (Term.spine F).2.length
          (by omega)).symm
      have hpre : ∀ i, i < (Term.spine F).2.length →
          Par β ((Term.spine F).2.getD i .Qnt) (args'.getD i .Qnt) := by
        intro i hi
        have hp := hpar i (by
          rw [hsp2eq, List.length_append]
          simp only [List.length_cons, List.length_nil]
          omega)
        rw [hsp2eq, getD_append_left _ _ i hi] at hp
        exact hp
      have hoccpre : ∀ i, i < (Term.spine F).2.length →
          Term.occ 0 (args'.getD i .Qnt) = 0 := fun i hi =>
        Par.occ_zero hβ (hpre i hi) 0 (hoccas i hi)
      -- the joined spine, shared by both shapes of the eta side
      have hjoin : ∀ (bs : List Term), (Term.spine F).2.length = bs.length →
          (∀ i, i < (Term.spine F).2.length →
            Par β ((Term.spine F).2.getD i .Qnt) (bs.getD i .Qnt)) →
          ∃ QS : List Term, QS.length = (Term.spine F).2.length ∧
            (∀ i, i < (Term.spine F).2.length →
              Par β (Term.subst 0 .Qnt (bs.getD i .Qnt))
                (Term.subst 0 .Qnt (QS.getD i .Qnt))) ∧
            Par β (.Lam (Term.apps d.body args'))
              (Term.apps d.body (QS.map (Term.subst 0 .Qnt))) := by
        intro bs hlb hpb
        obtain ⟨QS, hqlen, hqs⟩ := Par.pointwise_join
          ((Term.spine F).2.length)
          (fun i => args'.getD i .Qnt) (fun i => bs.getD i .Qnt)
          (fun i hi => by
            refine IH (t := (Term.spine F).2.getD i .Qnt) ?_
              (hpre i hi) (hpb i hi)
            have h5 := Term.size_spine_arg F
              ((Term.spine F).2.getD i .Qnt) (getD_mem _ i hi)
            omega)
        refine ⟨QS, hqlen, fun i hi => Par.subst hβ (hqs i hi).2 0 .qnt, ?_⟩
        rw [hsplit]
        have hhead : Par β
            (Term.apps d.body (args'.take (Term.spine F).2.length))
            (Term.apps d.body QS) := by
          refine Par.apps_congr (Par.refl d.body) (by
            simp only [List.length_take]
            omega) ?_
          intro i hi
          simp only [List.length_take] at hi
          rw [getD_take args' (Term.spine F).2.length i (by omega)]
          exact (hqs i (by omega)).1
        have hocch : Term.occ 0
            (Term.apps d.body (args'.take (Term.spine F).2.length)) = 0 := by
          rw [Term.occ_apps,
            Term.occ_closed d.body 0 0 hbc (Nat.le_refl 0)]
          have hz := List.occ_sum_zero_of_getD 0
            (args'.take (Term.spine F).2.length) (by
              intro i hi
              simp only [List.length_take] at hi
              rw [getD_take args' (Term.spine F).2.length i (by omega)]
              exact hoccpre i (by omega))
          omega
        have he := Par.eta hocch hhead
        rw [Term.subst_apps_closed 0 .Qnt hbc QS] at he
        rw [Term.apps_snoc]
        exact he
      rcases Par.ref_spine_cases hk hF hsF with
        ⟨bs, hFeq, hlb, hpb⟩ | ⟨bs, hlb, hpb, hFeq⟩
      · -- the head survived on the eta side: unfold it after the cut
        subst hFeq
        obtain ⟨QS, hqlen, hqs, hq2⟩ := hjoin bs hlb hpb
        refine ⟨Term.apps d.body (QS.map (Term.subst 0 .Qnt)), ?_, hq2⟩
        rw [Term.subst_apps,
          show Term.subst 0 .Qnt (Term.Ref k) = .Ref k from _root_.rfl]
        refine Par.dref (s := Term.apps (.Ref k)
            (bs.map (Term.subst 0 .Qnt))) hk
          (by rw [Term.spine_apps (by trivial)])
          (by
            rw [Term.spine_apps (by trivial)]
            simp only [List.length_map]
            omega) ?_
        rw [Term.spine_apps (by trivial)]
        intro i hi
        simp only [List.length_map] at hi
        rw [map_getD (Term.subst 0 .Qnt) .Qnt .Qnt bs i (by omega),
          map_getD (Term.subst 0 .Qnt) .Qnt .Qnt QS i (by omega)]
        exact hqs i (by omega)
      · -- both sides unfolded
        subst hFeq
        obtain ⟨QS, hqlen, hqs, hq2⟩ := hjoin bs hlb hpb
        refine ⟨Term.apps d.body (QS.map (Term.subst 0 .Qnt)), ?_, hq2⟩
        rw [Term.subst_apps_closed 0 .Qnt hbc bs]
        refine Par.apps_congr (Par.refl d.body) (by
          simp only [List.length_map]
          omega) ?_
        intro i hi
        simp only [List.length_map] at hi
        rw [map_getD (Term.subst 0 .Qnt) .Qnt .Qnt bs i (by omega),
          map_getD (Term.subst 0 .Qnt) .Qnt .Qnt QS i (by omega)]
        exact hqs i (by omega)
    | matc _ _ hhead _ _ _ =>
      exact Term.noConfusion hhead
    | matm hhead _ _ _ =>
      exact Term.noConfusion hhead
  cases h1 with
  | @eta F F' hocc hF =>
    cases h2 with
    | eta hocc2 hF2 =>
      rename_i F2'
      obtain ⟨F3, hF31, hF32⟩ := IH (t := F) (by
        simp only [Term.size] at hsz
        omega) hF hF2
      exact ⟨Term.subst 0 .Qnt F3, Par.subst hβ hF31 0 .qnt,
        Par.subst hβ hF32 0 .qnt⟩
    | lam hB2 =>
      exact hetalam (by simp only [Term.size] at hsz; omega) hocc hF hB2
    | dref _ hsp _ _ => exact Term.noConfusion hsp
  | var =>
    cases h2 with
    | var => exact ⟨_, .var, .var⟩
    | dref _ hsp _ _ => exact Term.noConfusion hsp
  | ref =>
    cases h2 with
    | ref => exact ⟨_, .ref, .ref⟩
    | dref hk2 hsp2 hlen2' hps2 =>
      exact ⟨_, Par.dref hk2 hsp2 hlen2' hps2, Par.refl _⟩
    | aref hk h0 => exact ⟨_, .aref hk h0, Par.refl _⟩
  | @typ g g' hg =>
    cases h2 with
    | typ hg2 =>
      obtain ⟨g3, h31, h32⟩ := IH (t := g) (by
        simp only [Term.size] at hsz; omega) hg hg2
      exact ⟨.Typ g3, .typ h31, .typ h32⟩
    | dref _ hsp _ _ => exact Term.noConfusion hsp
  | qnt =>
    cases h2 with
    | qnt => exact ⟨_, .qnt, .qnt⟩
    | dref _ hsp _ _ => exact Term.noConfusion hsp
  | qua =>
    cases h2 with
    | qua => exact ⟨_, .qua, .qua⟩
    | dref _ hsp _ _ => exact Term.noConfusion hsp
  | @min a a' b b' ha hb =>
    have iha : ∀ {p2 : Term}, Par β a p2 →
        ∃ q2, Par β a' q2 ∧ Par β p2 q2 := fun h2' =>
      IH (t := a) (by simp only [Term.size] at hsz; omega) ha h2'
    have ihb : ∀ {p2 : Term}, Par β b p2 →
        ∃ q2, Par β b' q2 ∧ Par β p2 q2 := fun h2' =>
      IH (t := b) (by simp only [Term.size] at hsz; omega) hb h2'
    cases h2 with
    | min ha2 hb2 =>
      obtain ⟨a3, ha31, ha32⟩ := iha ha2
      obtain ⟨b3, hb31, hb32⟩ := ihb hb2
      exact ⟨.Min a3 b3, .min ha31 hb31, .min ha32 hb32⟩
    | minLM hb2 =>
      cases Par.qua_inv ha
      obtain ⟨b3, hb31, hb32⟩ := ihb hb2
      exact ⟨b3, .minLM hb31, hb32⟩
    | minLN =>
      cases Par.qua_inv ha
      exact ⟨_, .minLN, .qua⟩
    | minRM ha2 =>
      cases Par.qua_inv hb
      obtain ⟨a3, ha31, ha32⟩ := iha ha2
      exact ⟨a3, .minRM ha31, ha32⟩
    | minRN =>
      cases Par.qua_inv hb
      exact ⟨_, .minRN, .qua⟩
    | minLL =>
      cases Par.qua_inv ha
      cases Par.qua_inv hb
      exact ⟨_, .minLL, .qua⟩
    | dref _ hsp _ _ => exact Term.noConfusion hsp
  | @minLM b b' hb =>
    have ihb : ∀ {p2 : Term}, Par β b p2 →
        ∃ q2, Par β p1 q2 ∧ Par β p2 q2 := fun h2' =>
      IH (t := b) (by simp only [Term.size] at hsz; omega) hb h2'
    cases h2 with
    | min ha2 hb2 =>
      cases Par.qua_inv ha2
      obtain ⟨b3, hb31, hb32⟩ := ihb hb2
      exact ⟨b3, hb31, .minLM hb32⟩
    | minLM hb2 => exact ihb hb2
    | minRM ha2 =>
      cases Par.qua_inv ha2
      cases Par.qua_inv hb
      exact ⟨_, .qua, .qua⟩
    | minRN =>
      cases Par.qua_inv hb
      exact ⟨_, .qua, .qua⟩
    | dref _ hsp _ _ => exact Term.noConfusion hsp
  | minLN =>
    cases h2 with
    | min ha2 hb2 =>
      cases Par.qua_inv ha2
      exact ⟨_, .qua, .minLN⟩
    | minLN => exact ⟨_, .qua, .qua⟩
    | minRM ha2 =>
      cases Par.qua_inv ha2
      exact ⟨_, .qua, .qua⟩
    | minRN => exact ⟨_, .qua, .qua⟩
    | dref _ hsp _ _ => exact Term.noConfusion hsp
  | @minRM a a' ha =>
    have iha : ∀ {p2 : Term}, Par β a p2 →
        ∃ q2, Par β p1 q2 ∧ Par β p2 q2 := fun h2' =>
      IH (t := a) (by simp only [Term.size] at hsz; omega) ha h2'
    cases h2 with
    | min ha2 hb2 =>
      cases Par.qua_inv hb2
      obtain ⟨a3, ha31, ha32⟩ := iha ha2
      exact ⟨a3, ha31, .minRM ha32⟩
    | minLM hb2 =>
      cases Par.qua_inv hb2
      cases Par.qua_inv ha
      exact ⟨_, .qua, .qua⟩
    | minLN =>
      cases Par.qua_inv ha
      exact ⟨_, .qua, .qua⟩
    | minRM ha2 => exact iha ha2
    | dref _ hsp _ _ => exact Term.noConfusion hsp
  | minRN =>
    cases h2 with
    | min ha2 hb2 =>
      cases Par.qua_inv hb2
      exact ⟨_, .qua, .minRN⟩
    | minLM hb2 =>
      cases Par.qua_inv hb2
      exact ⟨_, .qua, .qua⟩
    | minLN => exact ⟨_, .qua, .qua⟩
    | minRN => exact ⟨_, .qua, .qua⟩
    | dref _ hsp _ _ => exact Term.noConfusion hsp
  | minLL =>
    cases h2 with
    | min ha2 hb2 =>
      cases Par.qua_inv ha2
      cases Par.qua_inv hb2
      exact ⟨_, .qua, .minLL⟩
    | minLL => exact ⟨_, .qua, .qua⟩
    | dref _ hsp _ _ => exact Term.noConfusion hsp
  | adt =>
    cases h2 with
    | adt => exact ⟨_, .adt, .adt⟩
    | dref _ hsp _ _ => exact Term.noConfusion hsp
  | ctr =>
    cases h2 with
    | ctr => exact ⟨_, .ctr, .ctr⟩
    | dref _ hsp _ _ => exact Term.noConfusion hsp
  | efq =>
    cases h2 with
    | efq => exact ⟨_, .efq, .efq⟩
    | dref _ hsp _ _ => exact Term.noConfusion hsp
  | rfl =>
    cases h2 with
    | rfl => exact ⟨_, .rfl, .rfl⟩
    | dref _ hsp _ _ => exact Term.noConfusion hsp
  | @dref k d s2 args' hk hsp hlen' hpar =>
    have hs : t = Term.apps (.Ref k) (Term.spine t).2 := by
      rw [← hsp]
      exact (Term.apps_spine t).symm
    have hjoins : ∀ (cs : List Term),
        (∀ i, i < (Term.spine t).2.length →
          Par β ((Term.spine t).2.getD i .Qnt) (cs.getD i .Qnt)) →
        ∀ i, i < (Term.spine t).2.length →
        ∃ q, Par β (args'.getD i .Qnt) q ∧
          Par β (cs.getD i .Qnt) q := by
      intro cs hcs i hi
      refine IH (t := (Term.spine t).2.getD i .Qnt) ?_ (hpar i hi)
        (hcs i hi)
      have h5 := Term.size_spine_arg t ((Term.spine t).2.getD i .Qnt)
        (getD_mem _ i hi)
      omega
    have hL2 : (Term.spine t).2.length = args'.length := hlen'
    rcases Par.ref_spine_cases hk h2 hs with
      ⟨bs, hp2eq, hlb, hpb⟩ | ⟨bs, hlb, hpb, hp2eq⟩
    · subst hp2eq
      have hL3 : (Term.spine t).2.length = bs.length := hlb
      obtain ⟨qs, hqlen, hqs⟩ := Par.pointwise_join
        ((Term.spine t).2.length)
        (fun i => args'.getD i .Qnt) (fun i => bs.getD i .Qnt)
        (hjoins bs hpb)
      refine ⟨Term.apps d.body qs, ?_, ?_⟩
      · refine Par.apps_congr (Par.refl d.body) (by omega) ?_
        intro i hi
        exact (hqs i (by omega)).1
      · refine Par.dref (s := Term.apps (.Ref k) bs) hk
          (by rw [Term.spine_apps (by trivial)])
          (by
            rw [Term.spine_apps (by trivial)]
            show bs.length = qs.length
            omega) ?_
        rw [Term.spine_apps (by trivial)]
        intro i hi
        have hi2 : i < bs.length := hi
        exact (hqs i (by omega)).2
    · subst hp2eq
      have hL3 : (Term.spine t).2.length = bs.length := hlb
      obtain ⟨qs, hqlen, hqs⟩ := Par.pointwise_join
        ((Term.spine t).2.length)
        (fun i => args'.getD i .Qnt) (fun i => bs.getD i .Qnt)
        (hjoins bs hpb)
      refine ⟨Term.apps d.body qs, ?_, ?_⟩
      · refine Par.apps_congr (Par.refl d.body) (by omega) ?_
        intro i hi
        exact (hqs i (by omega)).1
      · refine Par.apps_congr (Par.refl d.body) (by omega) ?_
        intro i hi
        have h6 : i < (Term.spine t).2.length := by omega
        exact (hqs i h6).2
  | aref hk h0 =>
    cases h2 with
    | ref => exact ⟨_, Par.refl _, .aref hk h0⟩
    | aref hk2 => exact ⟨_, Par.refl _, Par.refl _⟩
    | dref hk2 hsp2 _ _ =>
      injection hsp2 with hkk
      subst hkk
      exact absurd hk (fun hA => Book.defn_adt_clash hk2 hA)
  | all hA hB =>
    rename_i A A' B B' q
    have ihA : ∀ {p2 : Term}, Par β A p2 →
        ∃ q2, Par β A' q2 ∧ Par β p2 q2 := fun h2' =>
      IH (t := A) (by simp only [Term.size] at hsz; omega) hA h2'
    have ihB : ∀ {p2 : Term}, Par β B p2 →
        ∃ q2, Par β B' q2 ∧ Par β p2 q2 := fun h2' =>
      IH (t := B) (by simp only [Term.size] at hsz; omega) hB h2'
    cases h2 with
    | all hA2 hB2 =>
      obtain ⟨A3, hA31, hA32⟩ := ihA hA2
      obtain ⟨B3, hB31, hB32⟩ := ihB hB2
      exact ⟨.All _ A3 B3, .all hA31 hB31, .all hA32 hB32⟩
    | dref _ hsp _ _ => exact Term.noConfusion hsp
  | @lam f f' hf =>
    have ihf : ∀ {p2 : Term}, Par β f p2 →
        ∃ q2, Par β f' q2 ∧ Par β p2 q2 := fun h2' =>
      IH (t := f) (by simp only [Term.size] at hsz; omega) hf h2'
    cases h2 with
    | lam hf2 =>
      obtain ⟨f3, h31, h32⟩ := ihf hf2
      exact ⟨.Lam f3, .lam h31, .lam h32⟩
    | eta hocc2 hF2 =>
      obtain ⟨q, hq1, hq2⟩ := hetalam
        (by simp only [Term.size] at hsz; omega) hocc2 hF2 hf
      exact ⟨q, hq2, hq1⟩
    | dref _ hsp _ _ => exact Term.noConfusion hsp
  | @mat h0 h0' m0 m0' a c hh hm =>
    have ihh : ∀ {p2 : Term}, Par β h0 p2 →
        ∃ q2, Par β h0' q2 ∧ Par β p2 q2 := fun h2' =>
      IH (t := h0) (by simp only [Term.size] at hsz; omega) hh h2'
    have ihm : ∀ {p2 : Term}, Par β m0 p2 →
        ∃ q2, Par β m0' q2 ∧ Par β p2 q2 := fun h2' =>
      IH (t := m0) (by simp only [Term.size] at hsz; omega) hm h2'
    cases h2 with
    | mat hh2 hm2 =>
      obtain ⟨h3, hh31, hh32⟩ := ihh hh2
      obtain ⟨m3, hm31, hm32⟩ := ihm hm2
      exact ⟨.Mat _ _ h3 m3, .mat hh31 hm31, .mat hh32 hm32⟩
    | dref _ hsp _ _ => exact Term.noConfusion hsp
  | @eql x x' y y' T0 T0' hx hy hT =>
    have ihx : ∀ {p2 : Term}, Par β x p2 →
        ∃ q2, Par β x' q2 ∧ Par β p2 q2 := fun h2' =>
      IH (t := x) (by simp only [Term.size] at hsz; omega) hx h2'
    have ihy : ∀ {p2 : Term}, Par β y p2 →
        ∃ q2, Par β y' q2 ∧ Par β p2 q2 := fun h2' =>
      IH (t := y) (by simp only [Term.size] at hsz; omega) hy h2'
    have ihT : ∀ {p2 : Term}, Par β T0 p2 →
        ∃ q2, Par β T0' q2 ∧ Par β p2 q2 := fun h2' =>
      IH (t := T0) (by simp only [Term.size] at hsz; omega) hT h2'
    cases h2 with
    | eql hx2 hy2 hT2 =>
      obtain ⟨x3, hx31, hx32⟩ := ihx hx2
      obtain ⟨y3, hy31, hy32⟩ := ihy hy2
      obtain ⟨T3, hT31, hT32⟩ := ihT hT2
      exact ⟨.Eql x3 y3 T3, .eql hx31 hy31 hT31, .eql hx32 hy32 hT32⟩
    | dref _ hsp _ _ => exact Term.noConfusion hsp
  | @rwt e e' P P' f f' he hP hf =>
    have ihe : ∀ {p2 : Term}, Par β e p2 →
        ∃ q2, Par β e' q2 ∧ Par β p2 q2 := fun h2' =>
      IH (t := e) (by simp only [Term.size] at hsz; omega) he h2'
    have ihP : ∀ {p2 : Term}, Par β P p2 →
        ∃ q2, Par β P' q2 ∧ Par β p2 q2 := fun h2' =>
      IH (t := P) (by simp only [Term.size] at hsz; omega) hP h2'
    have ihf : ∀ {p2 : Term}, Par β f p2 →
        ∃ q2, Par β f' q2 ∧ Par β p2 q2 := fun h2' =>
      IH (t := f) (by simp only [Term.size] at hsz; omega) hf h2'
    cases h2 with
    | rwt he2 hP2 hf2 =>
      obtain ⟨e3, he31, he32⟩ := ihe he2
      obtain ⟨P3, hP31, hP32⟩ := ihP hP2
      obtain ⟨f3, hf31, hf32⟩ := ihf hf2
      exact ⟨.Rwt e3 P3 f3, .rwt he31 hP31 hf31, .rwt he32 hP32 hf32⟩
    | rwtr hf2 =>
      obtain ⟨f3, hf31, hf32⟩ := ihf hf2
      cases Par.rfl_inv he
      exact ⟨f3, .rwtr hf31, hf32⟩
    | dref _ hsp _ _ => exact Term.noConfusion hsp
  | rwtr hf =>
    rename_i f P
    have ihf : ∀ {p2x : Term}, Par β f p2x →
        ∃ q2, Par β p1 q2 ∧ Par β p2x q2 := fun h2' =>
      IH (t := f) (by simp only [Term.size] at hsz; omega) hf h2'
    cases h2 with
    | rwt he2 hP2 hf2 =>
      obtain ⟨f3, hf31, hf32⟩ := ihf hf2
      cases Par.rfl_inv he2
      exact ⟨f3, hf31, .rwtr hf32⟩
    | rwtr hf2 => exact ihf hf2
    | dref _ hsp _ _ => exact Term.noConfusion hsp
  | @let_ v v' b0 b0' q0 hv hb =>
    have ihv : ∀ {p2 : Term}, Par β v p2 →
        ∃ q2, Par β v' q2 ∧ Par β p2 q2 := fun h2' =>
      IH (t := v) (by simp only [Term.size] at hsz; omega) hv h2'
    have ihb : ∀ {p2 : Term}, Par β b0 p2 →
        ∃ q2, Par β b0' q2 ∧ Par β p2 q2 := fun h2' =>
      IH (t := b0) (by simp only [Term.size] at hsz; omega) hb h2'
    cases h2 with
    | let_ hv2 hb2 =>
      obtain ⟨v3, hv31, hv32⟩ := ihv hv2
      obtain ⟨b3, hb31, hb32⟩ := ihb hb2
      exact ⟨.Let _ v3 b3, .let_ hv31 hb31, .let_ hv32 hb32⟩
    | letr hv2 hb2 =>
      obtain ⟨v3, hv31, hv32⟩ := ihv hv2
      obtain ⟨b3, hb31, hb32⟩ := ihb hb2
      exact ⟨Term.subst 0 v3 b3, .letr hv31 hb31, Par.subst hβ hb32 0 hv32⟩
    | dref _ hsp _ _ => exact Term.noConfusion hsp
  | @letr v v' b0 b0' q0 hv hb =>
    have ihv : ∀ {p2 : Term}, Par β v p2 →
        ∃ q2, Par β v' q2 ∧ Par β p2 q2 := fun h2' =>
      IH (t := v) (by simp only [Term.size] at hsz; omega) hv h2'
    have ihb : ∀ {p2 : Term}, Par β b0 p2 →
        ∃ q2, Par β b0' q2 ∧ Par β p2 q2 := fun h2' =>
      IH (t := b0) (by simp only [Term.size] at hsz; omega) hb h2'
    cases h2 with
    | let_ hv2 hb2 =>
      obtain ⟨v3, hv31, hv32⟩ := ihv hv2
      obtain ⟨b3, hb31, hb32⟩ := ihb hb2
      exact ⟨Term.subst 0 v3 b3, Par.subst hβ hb31 0 hv31, .letr hv32 hb32⟩
    | letr hv2 hb2 =>
      obtain ⟨v3, hv31, hv32⟩ := ihv hv2
      obtain ⟨b3, hb31, hb32⟩ := ihb hb2
      exact ⟨Term.subst 0 v3 b3, Par.subst hβ hb31 0 hv31,
        Par.subst hβ hb32 0 hv32⟩
    | dref _ hsp _ _ => exact Term.noConfusion hsp
  | @beta f f' a a' hf ha =>
    have iha : ∀ {p2 : Term}, Par β a p2 →
        ∃ q2, Par β a' q2 ∧ Par β p2 q2 := fun h2' =>
      IH (t := a) (by simp only [Term.size] at hsz; omega) ha h2'
    have ihfb : ∀ {p2 : Term}, Par β f p2 →
        ∃ q2, Par β f' q2 ∧ Par β p2 q2 := fun h2' =>
      IH (t := f) (by simp only [Term.size] at hsz; omega) hf h2'
    cases h2 with
    | app hf2 ha2 =>
      rename_i F2 a2
      obtain ⟨a3, ha31, ha32⟩ := iha ha2
      rcases Par.lam_inv hf2 with ⟨g2, hg2eq, hg2⟩ |
        ⟨G, G', hfeq, hoccG, hteq, hG⟩
      · subst hg2eq
        obtain ⟨f3, hf31, hf32⟩ := ihfb hg2
        exact ⟨Term.subst 0 a3 f3, Par.subst hβ hf31 0 ha31,
          .beta hf32 ha32⟩
      · subst hfeq
        subst hteq
        have hocc' : Term.occ 0 G' = 0 := Par.occ_zero hβ hG 0 hoccG
        obtain ⟨f3, hf31, hf32⟩ := ihfb (.app hG .var)
        refine ⟨Term.subst 0 a3 f3, Par.subst hβ hf31 0 ha31, ?_⟩
        have hrw : Term.subst 0 a2 (.App G' (.Var 0))
            = .App (Term.subst 0 .Qnt G') a2 := by
          show Term.App (Term.subst 0 a2 G')
            (if 0 = 0 then a2 else _) = _
          rw [if_pos _root_.rfl,
            Term.occ_zero_subst_irrel G' 0 a2 .Qnt hocc']
        rw [← hrw]
        exact Par.subst hβ hf32 0 ha32
    | beta hf2 ha2 =>
      obtain ⟨f3, hf31, hf32⟩ := ihfb hf2
      obtain ⟨a3, ha31, ha32⟩ := iha ha2
      exact ⟨Term.subst 0 a3 f3, Par.subst hβ hf31 0 ha31,
        Par.subst hβ hf32 0 ha32⟩
    | dref _ hsp _ _ => exact Term.noConfusion hsp
  | @app f f' a a' hf ha =>
    have ihf : ∀ {p2 : Term}, Par β f p2 →
        ∃ q2, Par β f' q2 ∧ Par β p2 q2 := fun h2' =>
      IH (t := f) (by simp only [Term.size] at hsz; omega) hf h2'
    have iha : ∀ {p2 : Term}, Par β a p2 →
        ∃ q2, Par β a' q2 ∧ Par β p2 q2 := fun h2' =>
      IH (t := a) (by simp only [Term.size] at hsz; omega) ha h2'
    cases h2 with
    | app hf2 ha2 =>
      obtain ⟨f3, hf31, hf32⟩ := ihf hf2
      obtain ⟨a3, ha31, ha32⟩ := iha ha2
      exact ⟨.App f3 a3, .app hf31 ha31, .app hf32 ha32⟩
    | beta hf2 ha2 =>
      rename_i f0 f02 a2
      obtain ⟨a3, ha31, ha32⟩ := iha ha2
      have ihf0 : ∀ {p2 : Term}, Par β f0 p2 →
          ∃ q2, Par β f02 q2 ∧ Par β p2 q2 := fun h2' =>
        IH (t := f0) (by simp only [Term.size] at hsz; omega) hf2 h2'
      rcases Par.lam_inv hf with ⟨g1, hg1eq, hg1⟩ |
        ⟨G, G', hfeq, hoccG, hteq, hG⟩
      · subst hg1eq
        obtain ⟨F3, hF31, hF32⟩ := ihf0 hg1
        exact ⟨Term.subst 0 a3 F3, .beta hF32 ha31,
          Par.subst hβ hF31 0 ha32⟩
      · subst hfeq
        subst hteq
        have hocc' : Term.occ 0 G' = 0 := Par.occ_zero hβ hG 0 hoccG
        obtain ⟨F3, hF31, hF32⟩ := ihf0 (.app hG .var)
        refine ⟨Term.subst 0 a3 F3, ?_, Par.subst hβ hF31 0 ha32⟩
        have hrw : Term.subst 0 a' (.App G' (.Var 0))
            = .App (Term.subst 0 .Qnt G') a' := by
          show Term.App (Term.subst 0 a' G')
            (if 0 = 0 then a' else _) = _
          rw [if_pos _root_.rfl,
            Term.occ_zero_subst_irrel G' 0 a' .Qnt hocc']
        rw [← hrw]
        exact Par.subst hβ hF32 0 ha31
    | matc hk1 hk2 hhead hlen hs2 hh2 =>
      obtain ⟨mh1, mm1, hmeq, hmh1, hmm1⟩ := Par.mat_inv hf
      subst hmeq
      obtain ⟨M3, hM31, hM32⟩ := ihf (Par.mat hh2 (Par.refl _))
      obtain ⟨h3t, m3t, hMeq, hh31, hm31⟩ := Par.mat_inv hM31
      subst hMeq
      obtain ⟨h3t', m3t', hMeq2, hh32, hm32⟩ := Par.mat_inv hM32
      cases hMeq2
      obtain ⟨s3, hs31, hs32⟩ := iha hs2
      have hstab1 := ha.spine_stable hhead
      have hstab2 := hs2.spine_stable hhead
      have hstab32 := hs32.spine_stable hstab2.1
      refine ⟨_, Par.matc hk1 hk2 hstab1.1 ?_ hs31 hh31, ?_⟩
      · rw [← hstab1.2.length]; exact hlen
      · exact Par.apps hh32 (Pars.drop hstab32.2 _)
    | matm hhead hne hs2 hm2 =>
      obtain ⟨mh1, mm1, hmeq, hmh1, hmm1⟩ := Par.mat_inv hf
      subst hmeq
      obtain ⟨M3, hM31, hM32⟩ := ihf (Par.mat (Par.refl _) hm2)
      obtain ⟨h3t, m3t, hMeq, hh31, hm31⟩ := Par.mat_inv hM31
      subst hMeq
      obtain ⟨h3t', m3t', hMeq2, hh32, hm32⟩ := Par.mat_inv hM32
      cases hMeq2
      obtain ⟨s3, hs31, hs32⟩ := iha hs2
      have hstab1 := ha.spine_stable hhead
      refine ⟨.App m3t s3, Par.matm hstab1.1 hne hs31 hm31, .app hm32 hs32⟩
    | @dref k2 d2 s2x args2' hk2 hsp2 hlen2' hps2 =>
      have h1' : Par β (.App f a) (.App f' a') := .app hf ha
      have hs : Term.App f a
          = Term.apps (.Ref k2) (Term.spine (Term.App f a)).2 := by
        rw [← hsp2]
        exact (Term.apps_spine _).symm
      have hjoins : ∀ (cs : List Term),
          (∀ i, i < (Term.spine (Term.App f a)).2.length →
            Par β ((Term.spine (Term.App f a)).2.getD i .Qnt)
              (cs.getD i .Qnt)) →
          ∀ i, i < (Term.spine (Term.App f a)).2.length →
          ∃ q2, Par β (args2'.getD i .Qnt) q2 ∧
            Par β (cs.getD i .Qnt) q2 := by
        intro cs hcs i hi
        refine IH (t := (Term.spine (Term.App f a)).2.getD i .Qnt) ?_
          (hps2 i hi) (hcs i hi)
        have h5 := Term.size_spine_arg (Term.App f a)
          ((Term.spine (Term.App f a)).2.getD i .Qnt) (getD_mem _ i hi)
        omega
      have hL2 : (Term.spine (Term.App f a)).2.length = args2'.length :=
        hlen2'
      rcases Par.ref_spine_cases hk2 h1' hs with
        ⟨bs, hp1eq, hlb, hpb⟩ | ⟨bs, hlb, hpb, hp1eq⟩
      · rw [hp1eq]
        have hL3 : (Term.spine (Term.App f a)).2.length = bs.length := hlb
        obtain ⟨qs, hqlen, hqs⟩ := Par.pointwise_join
          ((Term.spine (Term.App f a)).2.length)
          (fun i => args2'.getD i .Qnt) (fun i => bs.getD i .Qnt)
          (hjoins bs hpb)
        refine ⟨Term.apps d2.body qs, ?_, ?_⟩
        · refine Par.dref (s := Term.apps (.Ref k2) bs) hk2
            (by rw [Term.spine_apps (by trivial)])
            (by
              rw [Term.spine_apps (by trivial)]
              show bs.length = qs.length
              omega) ?_
          rw [Term.spine_apps (by trivial)]
          intro i hi
          have hi2 : i < bs.length := hi
          exact (hqs i (by omega)).2
        · refine Par.apps_congr (Par.refl d2.body) (by omega) ?_
          intro i hi
          exact (hqs i (by omega)).1
      · rw [hp1eq]
        have hL3 : (Term.spine (Term.App f a)).2.length = bs.length := hlb
        obtain ⟨qs, hqlen, hqs⟩ := Par.pointwise_join
          ((Term.spine (Term.App f a)).2.length)
          (fun i => args2'.getD i .Qnt) (fun i => bs.getD i .Qnt)
          (hjoins bs hpb)
        refine ⟨Term.apps d2.body qs, ?_, ?_⟩
        · refine Par.apps_congr (Par.refl d2.body) (by omega) ?_
          intro i hi
          have h6 : i < (Term.spine (Term.App f a)).2.length := by omega
          exact (hqs i h6).2
        · refine Par.apps_congr (Par.refl d2.body) (by omega) ?_
          intro i hi
          exact (hqs i (by omega)).1
  | @matc a A c C s2m s2m' h0 h0' m0 hk1 hk2 hhead hlen hs hh =>
    have ihs : ∀ {p2 : Term}, Par β s2m p2 →
        ∃ q2, Par β s2m' q2 ∧ Par β p2 q2 := fun h2' =>
      IH (t := s2m) (by simp only [Term.size] at hsz; omega) hs h2'
    have ihh : ∀ {p2 : Term}, Par β h0 p2 →
        ∃ q2, Par β h0' q2 ∧ Par β p2 q2 := fun h2' =>
      IH (t := h0) (by simp only [Term.size] at hsz; omega) hh h2'
    cases h2 with
    | app hf2 ha2 =>
      obtain ⟨mh2, mm2, hmeq, hmh2, hmm2⟩ := Par.mat_inv hf2
      subst hmeq
      obtain ⟨h3, hh31, hh32⟩ := ihh hmh2
      obtain ⟨s3, hs31, hs32⟩ := ihs ha2
      have hstab1 := hs.spine_stable hhead
      have hstab2 := ha2.spine_stable hhead
      have hstab31 := hs31.spine_stable hstab1.1
      refine ⟨_, Par.apps hh31 (Pars.drop hstab31.2 _),
        Par.matc hk1 hk2 hstab2.1 ?_ hs32 hh32⟩
      rw [← hstab2.2.length]; exact hlen
    | matc hk1' hk2' hhead' hlen' hs2 hh2 =>
      rw [hk1] at hk1'
      cases hk1'
      rw [hk2] at hk2'
      cases hk2'
      obtain ⟨h3, hh31, hh32⟩ := ihh hh2
      obtain ⟨s3, hs31, hs32⟩ := ihs hs2
      have hstab1 := hs.spine_stable hhead
      have hstab2 := hs2.spine_stable hhead
      have hstab31 := hs31.spine_stable hstab1.1
      have hstab32 := hs32.spine_stable hstab2.1
      exact ⟨_, Par.apps hh31 (Pars.drop hstab31.2 _),
        Par.apps hh32 (Pars.drop hstab32.2 _)⟩
    | matm hhead' hne hs2 hm2 =>
      exfalso
      rw [hhead] at hhead'
      cases hhead'
      exact hne _root_.rfl
    | dref _ hsp _ _ => exact Term.noConfusion hsp
  | @matm s2m a' c' a c s2m' m0 m0' h0 hhead hne hs hm =>
    have ihs : ∀ {p2 : Term}, Par β s2m p2 →
        ∃ q2, Par β s2m' q2 ∧ Par β p2 q2 := fun h2' =>
      IH (t := s2m) (by simp only [Term.size] at hsz; omega) hs h2'
    have ihm : ∀ {p2 : Term}, Par β m0 p2 →
        ∃ q2, Par β m0' q2 ∧ Par β p2 q2 := fun h2' =>
      IH (t := m0) (by simp only [Term.size] at hsz; omega) hm h2'
    cases h2 with
    | app hf2 ha2 =>
      obtain ⟨mh2, mm2, hmeq, hmh2, hmm2⟩ := Par.mat_inv hf2
      subst hmeq
      obtain ⟨m3, hm31, hm32⟩ := ihm hmm2
      obtain ⟨s3, hs31, hs32⟩ := ihs ha2
      have hstab2 := ha2.spine_stable hhead
      exact ⟨.App m3 s3, .app hm31 hs31,
        Par.matm hstab2.1 hne hs32 hm32⟩
    | matm hhead' hne' hs2 hm2 =>
      obtain ⟨m3, hm31, hm32⟩ := ihm hm2
      obtain ⟨s3, hs31, hs32⟩ := ihs hs2
      exact ⟨.App m3 s3, .app hm31 hs31, .app hm32 hs32⟩
    | matc hk1' hk2' hhead' hlen' hs2 hh2 =>
      exfalso
      rw [hhead] at hhead'
      cases hhead'
      exact hne _root_.rfl
    | dref _ hsp _ _ => exact Term.noConfusion hsp

-- chains of parallel steps (= strong runs, both directions)
inductive ParRed (β : Book) : Term → Term → Prop
  | refl : ParRed β t t
  | step : Par β a b → ParRed β b c → ParRed β a c

theorem ParRed.of_red (r : Red β .strong a b) : ParRed β a b := by
  induction r with
  | refl => exact .refl
  | step s _ ih => exact .step s.par ih

theorem ParRed.red (hβ : Book.Closed β) (r : ParRed β a b) :
    Red β .strong a b := by
  induction r with
  | refl => exact .refl
  | step p _ ih => exact (p.red hβ).trans ih

theorem ParRed.strip (hβ : Book.Closed β) (hp : Par β a b)
    (hr : ParRed β a c) : ∃ d, ParRed β b d ∧ Par β c d := by
  induction hr generalizing b with
  | refl => exact ⟨b, .refl, hp⟩
  | step p _ ih =>
    obtain ⟨e, hpe, hbe⟩ := Par.diamond hβ p hp
    obtain ⟨d, hd1, hd2⟩ := ih hpe
    exact ⟨d, .step hbe hd1, hd2⟩

theorem ParRed.confluent (hβ : Book.Closed β) (h1 : ParRed β a b)
    (h2 : ParRed β a c) : ∃ d, ParRed β b d ∧ ParRed β c d := by
  induction h1 generalizing c with
  | refl => exact ⟨c, h2, .refl⟩
  | step p _ ih =>
    obtain ⟨e, he1, he2⟩ := ParRed.strip hβ p h2
    obtain ⟨d, hd1, hd2⟩ := ih he1
    exact ⟨d, hd1, .step he2 hd2⟩

-- confluence over a closed book
theorem church_rosser_closed (hβ : Book.Closed β)
    (h1 : Red β .strong a b) (h2 : Red β .strong a c) :
    ∃ d, Red β .strong b d ∧ Red β .strong c d := by
  obtain ⟨d, hd1, hd2⟩ :=
    ParRed.confluent hβ (ParRed.of_red h1) (ParRed.of_red h2)
  exact ⟨d, hd1.red hβ, hd2.red hβ⟩

-- ============================================================================
-- METATHEORY §B3 — the reduction kit: steps and runs commute with shift
-- and substitution (closed book), a substituted argument reduces under
-- its term, and conversion is an equivalence and a congruence.
-- ============================================================================

theorem Step.shift (hβ : Book.Closed β) (s : Step β p a b) :
    ∀ d, Step β p (Term.shift d a) (Term.shift d b) := by
  induction s with
  | beta => intro d; rw [Term.shift_subst0]; exact .beta
  | let_ => intro d; rw [Term.shift_subst0]; exact .let_
  | @dref k dd s hk hsp hlen =>
    intro d
    have hc := (hβ.defn hk).2
    have hs := Term.spine_shift hsp (by trivial) (d := d) rfl
    rw [Term.shift_apps, Term.shift_closed dd.body 0 d hc (Nat.zero_le d)]
    have h := Step.dref (p := p) (s := Term.shift d s) hk (by rw [hs])
      (by rw [hs]; simpa using hlen)
    simpa [hs] using h
  | @drefS k dd s hp hk hsp =>
    intro d
    have hc := (hβ.defn hk).2
    have hs := Term.spine_shift hsp (by trivial) (d := d) rfl
    rw [Term.shift_apps, Term.shift_closed dd.body 0 d hc (Nat.zero_le d)]
    have h := Step.drefS (s := Term.shift d s) hp hk (by rw [hs])
    simpa [hs] using h
  | aref hk h0 => intro d; exact .aref hk h0
  | matc h1 h2 h3 h4 =>
    intro d
    simp only [Term.shift, Term.shift_apps, List.map_append]
    exact .matc h1 h2 (by simp [h3]) (by simp [h4])
  | matm hne =>
    intro d
    simp only [Term.shift, Term.shift_apps]
    exact .matm hne
  | rwt => intro d; exact .rwt
  | minLM => intro d; exact .minLM
  | minLN => intro d; exact .minLN
  | minRM => intro d; exact .minRM
  | minRN => intro d; exact .minRN
  | minLL => intro d; exact .minLL
  | eta hp hocc =>
    intro d
    rw [Term.shift_subst_ge _ d 0 .Qnt (Nat.zero_le d)]
    simp only [Term.shift, Nat.zero_lt_succ, ↓reduceIte]
    exact .eta hp (by rw [Term.occ_shift_lt _ 0 (d + 1) (by omega)]; exact hocc)
  | typ_g hp _ ih => intro d; exact .typ_g hp (ih d)
  | min_a _ ih => intro d; exact .min_a (ih d)
  | min_b _ ih => intro d; exact .min_b (ih d)
  | all_a hp _ ih => intro d; exact .all_a hp (ih d)
  | all_b hp _ ih => intro d; exact .all_b hp (ih (d + 1))
  | lam_f hp _ ih => intro d; exact .lam_f hp (ih (d + 1))
  | app_f _ ih => intro d; exact .app_f (ih d)
  | app_a _ ih => intro d; exact .app_a (ih d)
  | mat_h _ ih => intro d; exact .mat_h (ih d)
  | mat_m _ ih => intro d; exact .mat_m (ih d)
  | eql_a _ ih => intro d; exact .eql_a (ih d)
  | eql_b _ ih => intro d; exact .eql_b (ih d)
  | eql_t _ ih => intro d; exact .eql_t (ih d)
  | rwt_e _ ih => intro d; exact .rwt_e (ih d)
  | rwt_p _ ih => intro d; exact .rwt_p (ih d)
  | rwt_f _ ih => intro d; exact .rwt_f (ih d)
  | let_v _ ih => intro d; exact .let_v (ih d)
  | let_b hp _ ih => intro d; exact .let_b hp (ih (d + 1))

theorem Step.subst (hβ : Book.Closed β) (s : Step β p a b) :
    ∀ d w, Step β p (Term.subst d w a) (Term.subst d w b) := by
  induction s with
  | beta => intro d w; rw [Term.subst_subst0]; exact .beta
  | let_ => intro d w; rw [Term.subst_subst0]; exact .let_
  | @dref k dd s hk hsp hlen =>
    intro d w
    have hc := (hβ.defn hk).2
    have hs := Term.spine_subst hsp (by trivial) (d := d) (w := w) rfl
    rw [Term.subst_apps, Term.subst_closed dd.body 0 d w hc (Nat.zero_le d)]
    have h := Step.dref (p := p) (s := Term.subst d w s) hk (by rw [hs])
      (by rw [hs]; simpa using hlen)
    simpa [hs] using h
  | @drefS k dd s hp hk hsp =>
    intro d w
    have hc := (hβ.defn hk).2
    have hs := Term.spine_subst hsp (by trivial) (d := d) (w := w) rfl
    rw [Term.subst_apps, Term.subst_closed dd.body 0 d w hc (Nat.zero_le d)]
    have h := Step.drefS (s := Term.subst d w s) hp hk (by rw [hs])
    simpa [hs] using h
  | aref hk h0 => intro d w; exact .aref hk h0
  | matc h1 h2 h3 h4 =>
    intro d w
    simp only [Term.subst, Term.subst_apps, List.map_append]
    exact .matc h1 h2 (by simp [h3]) (by simp [h4])
  | matm hne =>
    intro d w
    simp only [Term.subst, Term.subst_apps]
    exact .matm hne
  | rwt => intro d w; exact .rwt
  | minLM => intro d w; exact .minLM
  | minLN => intro d w; exact .minLN
  | minRM => intro d w; exact .minRM
  | minRN => intro d w; exact .minRN
  | minLL => intro d w; exact .minLL
  | @eta F hp hocc =>
    intro d w
    rw [Term.subst_subst0]
    have h0 : Term.subst (d + 1) (Term.shift 0 w) (Term.Var 0) = .Var 0 := by
      simp only [Term.subst]
      rw [if_neg (by omega), if_neg (by omega)]
    show Step β p (.Lam (.App (Term.subst (d + 1) (Term.shift 0 w) F)
      (Term.subst (d + 1) (Term.shift 0 w) (.Var 0)))) _
    rw [h0]
    exact .eta hp (Term.occ_subst_lt_zero F (d + 1) 0 (Term.shift 0 w)
      (by omega) hocc (Term.occ_shift_self w 0))
  | typ_g hp _ ih => intro d w; exact .typ_g hp (ih d w)
  | min_a _ ih => intro d w; exact .min_a (ih d w)
  | min_b _ ih => intro d w; exact .min_b (ih d w)
  | all_a hp _ ih => intro d w; exact .all_a hp (ih d w)
  | all_b hp _ ih => intro d w; exact .all_b hp (ih (d + 1) _)
  | lam_f hp _ ih => intro d w; exact .lam_f hp (ih (d + 1) _)
  | app_f _ ih => intro d w; exact .app_f (ih d w)
  | app_a _ ih => intro d w; exact .app_a (ih d w)
  | mat_h _ ih => intro d w; exact .mat_h (ih d w)
  | mat_m _ ih => intro d w; exact .mat_m (ih d w)
  | eql_a _ ih => intro d w; exact .eql_a (ih d w)
  | eql_b _ ih => intro d w; exact .eql_b (ih d w)
  | eql_t _ ih => intro d w; exact .eql_t (ih d w)
  | rwt_e _ ih => intro d w; exact .rwt_e (ih d w)
  | rwt_p _ ih => intro d w; exact .rwt_p (ih d w)
  | rwt_f _ ih => intro d w; exact .rwt_f (ih d w)
  | let_v _ ih => intro d w; exact .let_v (ih d w)
  | let_b hp _ ih => intro d w; exact .let_b hp (ih (d + 1) _)

-- a substituted term reduces when its argument does (strong: the
-- argument's copies sit under binders)
theorem Step.substR (hβ : Book.Closed β) : ∀ (t : Term) (d : Nat) {w w' : Term},
    Step β .strong w w' → Red β .strong (Term.subst d w t) (Term.subst d w' t) := by
  intro t
  induction t with
  | Var i =>
    intro d w w' s
    simp only [Term.subst]
    split
    · exact Red.one s
    · split <;> exact .refl
  | Ref k => intro d w w' _; exact .refl
  | Typ g ih => intro d w w' s; exact Red.typ_g (ih d s)
  | Qnt => intro d w w' _; exact .refl
  | Qua q => intro d w w' _; exact .refl
  | Min a b iha ihb =>
    intro d w w' s; exact (Red.min_a (iha d s)).trans (Red.min_b (ihb d s))
  | All q A B ihA ihB =>
    intro d w w' s
    exact (Red.all_a (ihA d s)).trans (Red.all_b (ihB (d + 1) (s.shift hβ 0)))
  | Lam f ih => intro d w w' s; exact Red.lam_f (ih (d + 1) (s.shift hβ 0))
  | App f a ihf iha =>
    intro d w w' s; exact (Red.app_f (ihf d s)).trans (Red.app_a (iha d s))
  | Adt a r => intro d w w' _; exact .refl
  | Ctr a c => intro d w w' _; exact .refl
  | Mat a c h m ihh ihm =>
    intro d w w' s; exact (Red.mat_h (ihh d s)).trans (Red.mat_m (ihm d s))
  | Efq => intro d w w' _; exact .refl
  | Eql x y T ihx ihy ihT =>
    intro d w w' s
    exact ((Red.eql_a (ihx d s)).trans (Red.eql_b (ihy d s))).trans
      (Red.eql_t (ihT d s))
  | Rfl => intro d w w' _; exact .refl
  | Rwt e P f ihe ihP ihf =>
    intro d w w' s
    exact ((Red.rwt_e (ihe d s)).trans (Red.rwt_p (ihP d s))).trans
      (Red.rwt_f (ihf d s))
  | Let q v b ihv ihb =>
    intro d w w' s
    exact (Red.let_v (ihv d s)).trans (Red.let_b (ihb (d + 1) (s.shift hβ 0)))

theorem Red.shift (hβ : Book.Closed β) (r : Red β p a b) (d : Nat) :
    Red β p (Term.shift d a) (Term.shift d b) := by
  induction r with
  | refl => exact .refl
  | step s _ ih => exact .step (s.shift hβ d) ih

theorem Red.subst (hβ : Book.Closed β) (r : Red β p a b) (d : Nat) (w : Term) :
    Red β p (Term.subst d w a) (Term.subst d w b) := by
  induction r with
  | refl => exact .refl
  | step s _ ih => exact .step (s.subst hβ d w) ih

theorem Red.substR (hβ : Book.Closed β) (r : Red β .strong w w') (d : Nat)
    (t : Term) : Red β .strong (Term.subst d w t) (Term.subst d w' t) := by
  induction r with
  | refl => exact .refl
  | step s _ ih => exact (Step.substR hβ t d s).trans ih

-- conversion: an equivalence (transitivity is confluence), stable under
-- shift and substitution, and a congruence
theorem Conv.refl (t : Term) : Conv β t t := ⟨t, .refl, .refl⟩

theorem Conv.symm (h : Conv β a b) : Conv β b a := by
  obtain ⟨c, h1, h2⟩ := h
  exact ⟨c, h2, h1⟩

theorem Conv.trans (hβ : Book.Closed β) (h1 : Conv β a b) (h2 : Conv β b c) :
    Conv β a c := by
  obtain ⟨u, hu1, hu2⟩ := h1
  obtain ⟨v, hv1, hv2⟩ := h2
  obtain ⟨w, hw1, hw2⟩ := church_rosser_closed hβ hu2 hv1
  exact ⟨w, hu1.trans hw1, hv2.trans hw2⟩

theorem Conv.of_red (h : Red β .strong a b) : Conv β a b := ⟨b, h, .refl⟩

theorem Conv.of_red_rev (h : Red β .strong b a) : Conv β a b := ⟨a, .refl, h⟩

theorem Conv.red_l (hβ : Book.Closed β) (r : Red β .strong a a')
    (h : Conv β a b) : Conv β a' b :=
  (Conv.of_red_rev r).trans hβ h

theorem Conv.red_r (hβ : Book.Closed β) (r : Red β .strong b b')
    (h : Conv β a b) : Conv β a b' :=
  h.trans hβ (Conv.of_red r)

theorem Conv.shift (hβ : Book.Closed β) (h : Conv β a b) (d : Nat) :
    Conv β (Term.shift d a) (Term.shift d b) := by
  obtain ⟨c, h1, h2⟩ := h
  exact ⟨Term.shift d c, h1.shift hβ d, h2.shift hβ d⟩

theorem Conv.subst (hβ : Book.Closed β) (ht : Conv β t t') (hw : Conv β w w')
    (d : Nat) : Conv β (Term.subst d w t) (Term.subst d w' t') := by
  obtain ⟨c, h1, h2⟩ := ht
  obtain ⟨e, g1, g2⟩ := hw
  exact ⟨Term.subst d e c, (h1.subst hβ d w).trans (Red.substR hβ g1 d c),
    (h2.subst hβ d w').trans (Red.substR hβ g2 d c)⟩

theorem Conv.substR (hβ : Book.Closed β) (hw : Conv β w w') (d : Nat)
    (t : Term) : Conv β (Term.subst d w t) (Term.subst d w' t) :=
  Conv.subst hβ (Conv.refl t) hw d

theorem Conv.typ (h : Conv β g g') : Conv β (.Typ g) (.Typ g') := by
  obtain ⟨c, h1, h2⟩ := h
  exact ⟨.Typ c, Red.typ_g h1, Red.typ_g h2⟩

theorem Conv.min (ha : Conv β a a') (hb : Conv β b b') :
    Conv β (.Min a b) (.Min a' b') := by
  obtain ⟨ca, ha1, ha2⟩ := ha
  obtain ⟨cb, hb1, hb2⟩ := hb
  exact ⟨.Min ca cb, (Red.min_a ha1).trans (Red.min_b hb1),
    (Red.min_a ha2).trans (Red.min_b hb2)⟩

theorem Conv.all (hA : Conv β A A') (hB : Conv β B B') :
    Conv β (.All q A B) (.All q A' B') := by
  obtain ⟨cA, hA1, hA2⟩ := hA
  obtain ⟨cB, hB1, hB2⟩ := hB
  exact ⟨.All q cA cB, (Red.all_a hA1).trans (Red.all_b hB1),
    (Red.all_a hA2).trans (Red.all_b hB2)⟩

theorem Conv.lam (h : Conv β f f') : Conv β (.Lam f) (.Lam f') := by
  obtain ⟨c, h1, h2⟩ := h
  exact ⟨.Lam c, Red.lam_f h1, Red.lam_f h2⟩

theorem Conv.app (hf : Conv β f f') (ha : Conv β a a') :
    Conv β (.App f a) (.App f' a') := by
  obtain ⟨cf, hf1, hf2⟩ := hf
  obtain ⟨ca, ha1, ha2⟩ := ha
  exact ⟨.App cf ca, (Red.app_f hf1).trans (Red.app_a ha1),
    (Red.app_f hf2).trans (Red.app_a ha2)⟩

theorem Conv.mat (hh : Conv β h h') (hm : Conv β m m') :
    Conv β (.Mat a c h m) (.Mat a c h' m') := by
  obtain ⟨ch, hh1, hh2⟩ := hh
  obtain ⟨cm, hm1, hm2⟩ := hm
  exact ⟨.Mat a c ch cm, (Red.mat_h hh1).trans (Red.mat_m hm1),
    (Red.mat_h hh2).trans (Red.mat_m hm2)⟩

theorem Conv.eql (hx : Conv β x x') (hy : Conv β y y') (hT : Conv β T T') :
    Conv β (.Eql x y T) (.Eql x' y' T') := by
  obtain ⟨cx, hx1, hx2⟩ := hx
  obtain ⟨cy, hy1, hy2⟩ := hy
  obtain ⟨cT, hT1, hT2⟩ := hT
  exact ⟨.Eql cx cy cT,
    ((Red.eql_a hx1).trans (Red.eql_b hy1)).trans (Red.eql_t hT1),
    ((Red.eql_a hx2).trans (Red.eql_b hy2)).trans (Red.eql_t hT2)⟩

theorem Conv.rwt (he : Conv β e e') (hP : Conv β P P') (hf : Conv β f f') :
    Conv β (.Rwt e P f) (.Rwt e' P' f') := by
  obtain ⟨ce, he1, he2⟩ := he
  obtain ⟨cP, hP1, hP2⟩ := hP
  obtain ⟨cf, hf1, hf2⟩ := hf
  exact ⟨.Rwt ce cP cf,
    ((Red.rwt_e he1).trans (Red.rwt_p hP1)).trans (Red.rwt_f hf1),
    ((Red.rwt_e he2).trans (Red.rwt_p hP2)).trans (Red.rwt_f hf2)⟩

theorem Conv.let_ (hv : Conv β v v') (hb : Conv β b b') :
    Conv β (.Let q v b) (.Let q v' b') := by
  obtain ⟨cv, hv1, hv2⟩ := hv
  obtain ⟨cb, hb1, hb2⟩ := hb
  exact ⟨.Let q cv cb, (Red.let_v hv1).trans (Red.let_b hb1),
    (Red.let_v hv2).trans (Red.let_b hb2)⟩

-- pointwise conversion on lists
inductive Convs (β : Book) : List Term → List Term → Prop
  | nil  : Convs β [] []
  | cons : Conv β x y → Convs β xs ys → Convs β (x :: xs) (y :: ys)

theorem Convs.refl : ∀ (xs : List Term), Convs β xs xs := by
  intro xs
  induction xs with
  | nil => exact .nil
  | cons x xs ih => exact .cons (Conv.refl x) ih

theorem Convs.length (h : Convs β xs ys) : xs.length = ys.length := by
  induction h with
  | nil => rfl
  | cons _ _ ih => simp [ih]

theorem Reds.convs (h1 : Reds β .strong xs zs) (h2 : Reds β .strong ys zs) :
    Convs β xs ys := by
  induction h1 generalizing ys with
  | nil => cases h2; exact .nil
  | cons hr hrest ih =>
    cases h2 with
    | cons hr2 hrest2 => exact .cons ⟨_, hr, hr2⟩ (ih hrest2)

theorem Conv.apps (hh : Conv β h h') : ∀ {as as' : List Term},
    Convs β as as' → Conv β (Term.apps h as) (Term.apps h' as') := by
  intro as
  induction as generalizing h h' with
  | nil => intro as' hc; cases hc; exact hh
  | cons x xs ih =>
    intro as' hc
    cases hc with
    | cons hx hxs => exact ih (Conv.app hh hx) hxs

-- ============================================================================
-- METATHEORY §B4 — typed terms are closed; Book.Ok closes the book, which
-- discharges claim (1).
-- ============================================================================

theorem Term.closed_of_subst : ∀ (t : Term) (n d : Nat) (w : Term), d ≤ n →
    Term.Closed n (Term.subst d w t) → Term.Closed (n + 1) t := by
  intro t
  induction t with
  | Var i =>
    intro n d w hd h
    simp only [Term.subst] at h
    show i < n + 1
    split at h
    · omega
    · split at h
      · simp only [Term.Closed] at h; omega
      · simp only [Term.Closed] at h; omega
  | Ref k => intro n d w _ _; trivial
  | Typ g ih => intro n d w hd h; exact ih n d w hd h
  | Qnt => intro n d w _ _; trivial
  | Qua q => intro n d w _ _; trivial
  | Min a b iha ihb =>
    intro n d w hd h; exact ⟨iha n d w hd h.1, ihb n d w hd h.2⟩
  | All q A B ihA ihB =>
    intro n d w hd h
    exact ⟨ihA n d w hd h.1, ihB (n + 1) (d + 1) _ (by omega) h.2⟩
  | Lam f ih => intro n d w hd h; exact ih (n + 1) (d + 1) _ (by omega) h
  | App f a ihf iha =>
    intro n d w hd h; exact ⟨ihf n d w hd h.1, iha n d w hd h.2⟩
  | Adt a r => intro n d w _ _; trivial
  | Ctr a c => intro n d w _ _; trivial
  | Mat a c h m ihh ihm =>
    intro n d w hd hh; exact ⟨ihh n d w hd hh.1, ihm n d w hd hh.2⟩
  | Efq => intro n d w _ _; trivial
  | Eql x y T ihx ihy ihT =>
    intro n d w hd h
    exact ⟨ihx n d w hd h.1, ihy n d w hd h.2.1, ihT n d w hd h.2.2⟩
  | Rfl => intro n d w _ _; trivial
  | Rwt e P f ihe ihP ihf =>
    intro n d w hd h
    exact ⟨ihe n d w hd h.1, ihP n d w hd h.2.1, ihf n d w hd h.2.2⟩
  | Let q v b ihv ihb =>
    intro n d w hd h
    exact ⟨ihv n d w hd h.1, ihb (n + 1) (d + 1) _ (by omega) h.2⟩

theorem Term.Closed.shift : ∀ (t : Term) (n d : Nat), t.Closed n →
    (Term.shift d t).Closed (n + 1) := by
  intro t
  induction t with
  | Var i =>
    intro n d h
    simp only [Term.shift]
    split <;> simp only [Term.Closed] at h ⊢ <;> omega
  | Ref k => intro n d _; trivial
  | Typ g ih => intro n d h; exact ih n d h
  | Qnt => intro n d _; trivial
  | Qua q => intro n d _; trivial
  | Min a b iha ihb => intro n d h; exact ⟨iha n d h.1, ihb n d h.2⟩
  | All q A B ihA ihB => intro n d h; exact ⟨ihA n d h.1, ihB (n + 1) (d + 1) h.2⟩
  | Lam f ih => intro n d h; exact ih (n + 1) (d + 1) h
  | App f a ihf iha => intro n d h; exact ⟨ihf n d h.1, iha n d h.2⟩
  | Adt a r => intro n d _; trivial
  | Ctr a c => intro n d _; trivial
  | Mat a c h m ihh ihm => intro n d hh; exact ⟨ihh n d hh.1, ihm n d hh.2⟩
  | Efq => intro n d _; trivial
  | Eql x y T ihx ihy ihT =>
    intro n d h; exact ⟨ihx n d h.1, ihy n d h.2.1, ihT n d h.2.2⟩
  | Rfl => intro n d _; trivial
  | Rwt e P f ihe ihP ihf =>
    intro n d h; exact ⟨ihe n d h.1, ihP n d h.2.1, ihf n d h.2.2⟩
  | Let q v b ihv ihb => intro n d h; exact ⟨ihv n d h.1, ihb (n + 1) (d + 1) h.2⟩

theorem Term.closed_apps : ∀ (as : List Term) (h : Term) (m : Nat),
    h.Closed m → (∀ x ∈ as, x.Closed m) → (Term.apps h as).Closed m := by
  intro as
  induction as with
  | nil => intro h m hh _; exact hh
  | cons a as ih =>
    intro h m hh has
    exact ih (.App h a) m ⟨hh, has a (by simp)⟩ (fun x hx => has x (by simp [hx]))

theorem Ctx.get_lt : ∀ {Γ : Ctx} {i : Nat} {b : Bind},
    Ctx.get Γ i = some b → i < Γ.length := by
  intro Γ
  induction Γ with
  | nil => intro i b h; cases h
  | cons A Γ ih =>
    intro i b h
    cases i with
    | zero => exact Nat.succ_pos _
    | succ i =>
      simp only [Ctx.get, Option.map_eq_some_iff] at h
      obtain ⟨b', hb', _⟩ := h
      exact Nat.succ_lt_succ (ih hb')

theorem Check.closed (h : Check β Φ L sp q Γ t T π u) : t.Closed Γ.length := by
  induction h with
  | var hg => exact Ctx.get_lt hg
  | ref _ _ _ => trivial
  | refA _ _ => trivial
  | adt _ => trivial
  | ctr _ _ _ => trivial
  | typ _ ih => exact ih
  | qnt => trivial
  | qua => trivial
  | min _ _ iha ihb => exact ⟨iha, ihb⟩
  | all _ _ ihA ihB => exact ⟨ihA, ihB⟩
  | lam _ _ _ _ ihf => exact ihf
  | app _ _ ihf ihx => exact ⟨ihf, ihx⟩
  | appLam ha _ ih =>
    exact ⟨Term.closed_of_subst _ _ 0 _ (Nat.zero_le _) ih, ha⟩
  | let_ _ _ _ _ ihv _ ihb => exact ⟨ihv, ihb⟩
  | eql _ _ _ ihT iha ihb => exact ⟨iha, ihb, ihT⟩
  | rfl _ => trivial
  | rwt _ _ _ ihe ihP ihf => exact ⟨ihe, ihP, ihf⟩
  | mat _ _ _ _ _ _ _ _ _ ihh ihm => exact ⟨ihh, ihm⟩
  | efq _ _ _ => trivial
  | cnv _ _ iht => exact iht

-- a constructor telescope that passes adt_valid's walk is closed
theorem FTele.closed : ∀ (fn : Nat) (ps : List Term) (Γ : Ctx) (i : Nat) (T : Term),
    FTele a r ps fn T → CtrOk β k pn G Γ i T → (∀ p ∈ ps, p.Closed Γ.length) →
    T.Closed Γ.length := by
  intro fn
  induction fn with
  | zero =>
    intro ps Γ i T hT _ hps
    have hT' : T = Term.apps (.Adt a r) ps := hT
    rw [hT']
    exact Term.closed_apps ps _ _ trivial hps
  | succ fn ih =>
    intro ps Γ i T hT hok hps
    obtain ⟨qf, F, B, hTeq, hB⟩ := hT
    subst hTeq
    obtain ⟨⟨π, hF⟩, hokB⟩ := hok
    refine ⟨hF.closed, ih _ _ _ _ hB hokB ?_⟩
    intro p hp
    obtain ⟨p', hp', rfl⟩ := List.mem_map.mp hp
    exact Term.Closed.shift p' _ 0 (hps p' hp')

theorem WTele.closed : ∀ (pn : Nat) (ps : List Term) (Γ : Ctx) (i : Nat) (T : Term),
    WTele a r ps pn fn T → CtrOk β k pn' G Γ i T → (∀ p ∈ ps, p.Closed Γ.length) →
    T.Closed Γ.length := by
  intro pn
  induction pn with
  | zero => intro ps Γ i T hT hok hps; exact FTele.closed fn ps Γ i T hT hok hps
  | succ pn ih =>
    intro ps Γ i T hT hok hps
    obtain ⟨q, K, B, hTeq, hB⟩ := hT
    subst hTeq
    obtain ⟨⟨π, hK⟩, hokB⟩ := hok
    refine ⟨hK.closed, ih _ _ _ _ hB hokB ?_⟩
    intro p hp
    rw [List.mem_append] at hp
    rcases hp with hp | hp
    · obtain ⟨p', hp', rfl⟩ := List.mem_map.mp hp
      exact Term.Closed.shift p' _ 0 (hps p' hp')
    · rw [List.mem_singleton] at hp
      subst hp
      show 0 < Γ.length + 1
      omega

theorem Book.Ok.closed (hok : Book.Ok β) : Book.Closed β := by
  intro k t hk
  have h := hok k t hk
  cases t with
  | adt A =>
    obtain ⟨⟨π, hs⟩, G, _, hc⟩ := h
    refine ⟨hs.closed, ?_⟩
    intro c C hcc
    obtain ⟨hshape, hok'⟩ := hc c C hcc
    have hshape' : WTele k [] [] A.pn C.fn C.ty := hshape
    exact WTele.closed A.pn [] [] 0 C.ty hshape' hok' (fun _ h => nomatch h)
  | defn d =>
    obtain ⟨⟨π, hs⟩, _, _, _, π', u, hc⟩ := h
    exact ⟨hs.closed, hc.closed⟩

theorem church_rosser_holds : church_rosser := by
  intro β a b c hok h1 h2
  exact church_rosser_closed hok.closed h1 h2

-- ============================================================================
-- METATHEORY §C — conversion and fitting. Head stability under strong
-- reduction (a rigid head keeps its spine; Typ, All and Eql reduce only
-- their parts), the head tag that separates the stable head classes, the
-- Conv and Le inversions, and the preorders KLe and Le.
-- ============================================================================

-- a rigid head never steps and heads no redex: its spine reduces only
-- in the arguments
def Term.Rigid : Term → Prop
  | .Var _ | .Qnt | .Qua _ | .Adt _ _ | .Ctr _ _ | .Efq | .Rfl => True
  | _ => False

theorem Term.Rigid.isHead (h : Term.Rigid t) : t.IsHead := by
  cases t <;> simp_all [Term.Rigid, Term.IsHead]

theorem Step.rigid_inv (s : Step β p t u) : ∀ {h : Term} {as : List Term},
    t = Term.apps h as → h.Rigid → ∃ bs, u = Term.apps h bs ∧ Reds β p as bs := by
  induction s <;> intro h as heq hr
  all_goals try
    (rcases apps_shape _ _ _ heq.symm with ⟨rfl, rfl⟩ | ⟨_, _, _, hX⟩
     · cases hr
     · cases hX)
  all_goals try
    (obtain ⟨ys, _, hfy⟩ := Term.app_eq_apps hr.isHead heq
     rcases apps_shape _ _ _ hfy.symm with ⟨rfl, rfl⟩ | ⟨_, _, _, hX⟩
     · cases hr
     · cases hX)
  case dref hsp _ =>
    rw [heq, Term.spine_apps hr.isHead] at hsp; subst hsp; cases hr
  case drefS hsp =>
    rw [heq, Term.spine_apps hr.isHead] at hsp; subst hsp; cases hr
  case app_f ih =>
    obtain ⟨ys, rfl, rfl⟩ := Term.app_eq_apps hr.isHead heq
    obtain ⟨bs, rfl, hred⟩ := ih rfl hr
    exact ⟨bs ++ [_], (Term.apps_snoc _ _ _).symm, hred.append (.cons .refl .nil)⟩
  case app_a sa _ =>
    obtain ⟨ys, rfl, rfl⟩ := Term.app_eq_apps hr.isHead heq
    exact ⟨ys ++ [_], (Term.apps_snoc _ _ _).symm,
      (Reds.refl ys).append (.cons (Red.one sa) .nil)⟩

theorem Red.rigid_inv (r : Red β p t u) : ∀ {h : Term} {as : List Term},
    t = Term.apps h as → h.Rigid → ∃ bs, u = Term.apps h bs ∧ Reds β p as bs := by
  induction r with
  | refl => intro h as heq _; exact ⟨as, heq, Reds.refl as⟩
  | step s _ ih =>
    intro h as heq hr
    obtain ⟨bs, hu, hred⟩ := s.rigid_inv heq hr
    obtain ⟨cs, hu2, hred2⟩ := ih hu hr
    exact ⟨cs, hu2, hred.trans hred2⟩

theorem Red.rigid_eq (r : Red β p h u) (hr : h.Rigid) : u = h := by
  obtain ⟨bs, hu, hred⟩ := r.rigid_inv (as := []) rfl hr
  cases hred; exact hu

theorem Red.adt_inv (r : Red β p (Term.apps (.Adt a rr) ps) u) :
    ∃ ps', u = Term.apps (.Adt a rr) ps' ∧ Reds β p ps ps' := r.rigid_inv rfl trivial

theorem Red.ctr_inv (r : Red β p (Term.apps (.Ctr a c) xs) u) :
    ∃ xs', u = Term.apps (.Ctr a c) xs' ∧ Reds β p xs xs' := r.rigid_inv rfl trivial

theorem Red.qnt_inv (r : Red β p .Qnt u) : u = .Qnt := r.rigid_eq trivial
theorem Red.qua_inv (r : Red β p (.Qua q) u) : u = .Qua q := r.rigid_eq trivial
theorem Red.rfl_inv (r : Red β p .Rfl u) : u = .Rfl := r.rigid_eq trivial
theorem Red.efq_inv (r : Red β p .Efq u) : u = .Efq := r.rigid_eq trivial

-- Typ, All and Eql reduce only in their parts
theorem Step.typ_inv (s : Step β p (.Typ g) u) : ∃ g', u = .Typ g' ∧ Step β p g g' := by
  cases s with
  | typ_g _ sg => exact ⟨_, rfl, sg⟩
  | dref _ hsp _ | drefS _ _ hsp => exact Term.noConfusion hsp

theorem Red.typ_inv (r : Red β p (.Typ g) u) : ∃ g', u = .Typ g' ∧ Red β p g g' := by
  generalize ht : Term.Typ g = t at r
  induction r generalizing g with
  | refl => exact ⟨g, ht.symm, .refl⟩
  | step s _ ih =>
    subst ht
    obtain ⟨g1, rfl, sg⟩ := Step.typ_inv s
    obtain ⟨g2, hu, hg⟩ := ih rfl
    exact ⟨g2, hu, .step sg hg⟩

theorem Step.all_inv (s : Step β p (.All q A B) u) :
    ∃ A' B', u = .All q A' B' ∧ Red β p A A' ∧ Red β p B B' := by
  cases s with
  | all_a _ sA => exact ⟨_, _, rfl, Red.one sA, .refl⟩
  | all_b _ sB => exact ⟨_, _, rfl, .refl, Red.one sB⟩
  | dref _ hsp _ | drefS _ _ hsp => exact Term.noConfusion hsp

theorem Red.all_inv (r : Red β p (.All q A B) u) :
    ∃ A' B', u = .All q A' B' ∧ Red β p A A' ∧ Red β p B B' := by
  generalize ht : Term.All q A B = t at r
  induction r generalizing A B with
  | refl => exact ⟨A, B, ht.symm, .refl, .refl⟩
  | step s _ ih =>
    subst ht
    obtain ⟨A1, B1, rfl, hA1, hB1⟩ := Step.all_inv s
    obtain ⟨A2, B2, hu, hA2, hB2⟩ := ih rfl
    exact ⟨A2, B2, hu, hA1.trans hA2, hB1.trans hB2⟩

theorem Step.eql_inv (s : Step β p (.Eql a b T) u) :
    ∃ a' b' T', u = .Eql a' b' T' ∧ Red β p a a' ∧ Red β p b b' ∧ Red β p T T' := by
  cases s with
  | eql_a sa => exact ⟨_, _, _, rfl, Red.one sa, .refl, .refl⟩
  | eql_b sb => exact ⟨_, _, _, rfl, .refl, Red.one sb, .refl⟩
  | eql_t st => exact ⟨_, _, _, rfl, .refl, .refl, Red.one st⟩
  | dref _ hsp _ | drefS _ _ hsp => exact Term.noConfusion hsp

theorem Red.eql_inv (r : Red β p (.Eql a b T) u) :
    ∃ a' b' T', u = .Eql a' b' T' ∧ Red β p a a' ∧ Red β p b b' ∧ Red β p T T' := by
  generalize ht : Term.Eql a b T = t at r
  induction r generalizing a b T with
  | refl => exact ⟨a, b, T, ht.symm, .refl, .refl, .refl⟩
  | step s _ ih =>
    subst ht
    obtain ⟨a1, b1, T1, rfl, h1, h2, h3⟩ := Step.eql_inv s
    obtain ⟨a2, b2, T2, hu, g1, g2, g3⟩ := ih rfl
    exact ⟨a2, b2, T2, hu, h1.trans g1, h2.trans g2, h3.trans g3⟩

-- a meet reduces in its parts until one side is a literal that fires
theorem Red.min_inv (r : Red β p (.Min a b) c) :
    (∃ a' b', c = .Min a' b' ∧ Red β p a a' ∧ Red β p b b') ∨
    (Red β p a (.Qua .Many) ∧ Red β p b c) ∨
    (Red β p b (.Qua .Many) ∧ Red β p a c) ∨
    (Red β p a (.Qua .None) ∧ c = .Qua .None) ∨
    (Red β p b (.Qua .None) ∧ c = .Qua .None) ∨
    (Red β p a (.Qua .Lone) ∧ Red β p b (.Qua .Lone) ∧ c = .Qua .Lone) := by
  generalize ht : Term.Min a b = t at r
  induction r generalizing a b with
  | refl => exact .inl ⟨a, b, ht.symm, .refl, .refl⟩
  | step s r ih =>
    subst ht
    cases s with
    | minLM => exact .inr (.inl ⟨.refl, r⟩)
    | minLN => exact .inr (.inr (.inr (.inl ⟨.refl, r.qua_inv⟩)))
    | minRM => exact .inr (.inr (.inl ⟨.refl, r⟩))
    | minRN => exact .inr (.inr (.inr (.inr (.inl ⟨.refl, r.qua_inv⟩))))
    | minLL => exact .inr (.inr (.inr (.inr (.inr ⟨.refl, .refl, r.qua_inv⟩))))
    | min_a sa =>
      rcases ih rfl with ⟨a', b', rfl, ha, hb⟩ | ⟨ha, hb⟩ | ⟨hb, ha⟩ | ⟨ha, hc⟩ | ⟨hb, hc⟩ | ⟨ha, hb, hc⟩
      · exact .inl ⟨a', b', rfl, .step sa ha, hb⟩
      · exact .inr (.inl ⟨.step sa ha, hb⟩)
      · exact .inr (.inr (.inl ⟨hb, .step sa ha⟩))
      · exact .inr (.inr (.inr (.inl ⟨.step sa ha, hc⟩)))
      · exact .inr (.inr (.inr (.inr (.inl ⟨hb, hc⟩))))
      · exact .inr (.inr (.inr (.inr (.inr ⟨.step sa ha, hb, hc⟩))))
    | min_b sb =>
      rcases ih rfl with ⟨a', b', rfl, ha, hb⟩ | ⟨ha, hb⟩ | ⟨hb, ha⟩ | ⟨ha, hc⟩ | ⟨hb, hc⟩ | ⟨ha, hb, hc⟩
      · exact .inl ⟨a', b', rfl, ha, .step sb hb⟩
      · exact .inr (.inl ⟨ha, .step sb hb⟩)
      · exact .inr (.inr (.inl ⟨.step sb hb, ha⟩))
      · exact .inr (.inr (.inr (.inl ⟨ha, hc⟩)))
      · exact .inr (.inr (.inr (.inr (.inl ⟨.step sb hb, hc⟩))))
      · exact .inr (.inr (.inr (.inr (.inr ⟨ha, .step sb hb, hc⟩))))
    | dref _ hsp _ | drefS _ _ hsp => exact Term.noConfusion hsp

-- the head tag: the spine head's constructor. Tags below 6 are the heads
-- a rule can rewrite (Ref, Min, Lam, Mat, Rwt, Let); a stable head keeps
-- its tag along any reduction
def Term.tag : Term → Nat
  | .Ref _       => 0
  | .Min _ _     => 1
  | .Lam _       => 2
  | .Mat _ _ _ _ => 3
  | .Rwt _ _ _   => 4
  | .Let _ _ _   => 5
  | .App f _     => Term.tag f
  | .Var _       => 6
  | .Typ _       => 7
  | .Qnt         => 8
  | .Qua _       => 9
  | .All _ _ _   => 10
  | .Adt _ _     => 11
  | .Ctr _ _     => 12
  | .Efq         => 13
  | .Eql _ _ _   => 14
  | .Rfl         => 15

@[simp] theorem Term.tag_apps : ∀ (as : List Term) (h : Term),
    Term.tag (Term.apps h as) = Term.tag h := by
  intro as
  induction as with
  | nil => intro h; rfl
  | cons a as ih => intro h; exact ih (.App h a)

theorem Term.tag_spine (t : Term) : Term.tag t = Term.tag (Term.spine t).1 := by
  induction t <;> simp [Term.tag, Term.spine, *]

theorem Step.tag (s : Step β p a b) (hs : 6 ≤ a.tag) : b.tag = a.tag := by
  induction s
  case dref hsp _ => rw [Term.tag_spine, hsp] at hs; simp [Term.tag] at hs
  case drefS hsp => rw [Term.tag_spine, hsp] at hs; simp [Term.tag] at hs
  all_goals simp_all [Term.tag]

theorem Red.tag (r : Red β p a b) (hs : 6 ≤ a.tag) : b.tag = a.tag := by
  induction r with
  | refl => rfl
  | step s _ ih => exact (ih (s.tag hs ▸ hs)).trans (s.tag hs)

theorem Conv.tag (h : Conv β a b) (ha : 6 ≤ a.tag) (hb : 6 ≤ b.tag) : a.tag = b.tag := by
  obtain ⟨c, h1, h2⟩ := h
  exact (h1.tag ha).symm.trans (h2.tag hb)

theorem Le.tag (h : Le β a b) (ha : 6 ≤ a.tag) (hb : 6 ≤ b.tag) : a.tag = b.tag := by
  induction h with
  | conv hc => exact hc.tag ha hb
  | red r1 r2 _ ih => rw [← r1.tag ha, ← r2.tag hb]; exact ih (r1.tag ha ▸ ha) (r2.tag hb ▸ hb)
  | typ => rfl
  | all => rfl
  | adt => simp [Term.tag]

-- head clashes: a fit between two stable head forms of different tags
-- is False (Le.tag / Conv.tag decide every pair; these are the named ones)
theorem Le.typ_all (h : Le β (.Typ g) (.All q A B)) : False := by simpa [Term.tag] using h.tag
theorem Le.all_adt (h : Le β (.All q A B) (Term.apps (.Adt a r) ps)) : False := by simpa [Term.tag] using h.tag
theorem Le.adt_all (h : Le β (Term.apps (.Adt a r) ps) (.All q A B)) : False := by simpa [Term.tag] using h.tag
theorem Le.all_eql (h : Le β (.All q A B) (.Eql x y T)) : False := by simpa [Term.tag] using h.tag
theorem Le.all_qnt (h : Le β (.All q A B) .Qnt) : False := by simpa [Term.tag] using h.tag
-- Le.adt's index form and the inductive Convs coincide
theorem Convs.get (h : Convs β xs ys) : ∀ (i : Nat) x y,
    xs[i]? = some x → ys[i]? = some y → Conv β x y := by
  induction h with
  | nil => intro i x y hx; simp at hx
  | cons hc _ ih =>
    intro i x y hx hy
    cases i with
    | zero => simp at hx hy; subst hx hy; exact hc
    | succ i => exact ih i x y hx hy

theorem Convs.of_index : ∀ {xs ys : List Term}, xs.length = ys.length →
    (∀ (i : Nat) x y, xs[i]? = some x → ys[i]? = some y → Conv β x y) → Convs β xs ys := by
  intro xs
  induction xs with
  | nil => intro ys hl _; cases ys with | nil => exact .nil | cons => simp at hl
  | cons x xs ih =>
    intro ys hl hc
    cases ys with
    | nil => simp at hl
    | cons y ys =>
      exact .cons (hc 0 x y rfl rfl)
        (ih (by simp at hl; omega) (fun i a b ha hb => hc (i + 1) a b ha hb))

-- the Conv inversions: conversion within a stable head class is componentwise
theorem Conv.typ_inv (h : Conv β (.Typ g) (.Typ g')) : Conv β g g' := by
  obtain ⟨c, h1, h2⟩ := h
  obtain ⟨g1, rfl, hg1⟩ := h1.typ_inv
  obtain ⟨g2, he, hg2⟩ := h2.typ_inv
  cases he; exact ⟨_, hg1, hg2⟩

theorem Conv.qua_inv (h : Conv β (.Qua q) (.Qua q')) : q = q' := by
  obtain ⟨c, h1, h2⟩ := h
  cases h1.qua_inv.symm.trans h2.qua_inv; rfl

theorem Conv.all_inv (h : Conv β (.All q A B) (.All q' A' B')) :
    q = q' ∧ Conv β A A' ∧ Conv β B B' := by
  obtain ⟨c, h1, h2⟩ := h
  obtain ⟨A1, B1, rfl, hA1, hB1⟩ := h1.all_inv
  obtain ⟨A2, B2, he, hA2, hB2⟩ := h2.all_inv
  cases he; exact ⟨rfl, ⟨A1, hA1, hA2⟩, ⟨B1, hB1, hB2⟩⟩

theorem Conv.eql_inv (h : Conv β (.Eql a b T) (.Eql a' b' T')) :
    Conv β a a' ∧ Conv β b b' ∧ Conv β T T' := by
  obtain ⟨c, h1, h2⟩ := h
  obtain ⟨a1, b1, T1, rfl, g1, g2, g3⟩ := h1.eql_inv
  obtain ⟨a2, b2, T2, he, f1, f2, f3⟩ := h2.eql_inv
  cases he; exact ⟨⟨a1, g1, f1⟩, ⟨b1, g2, f2⟩, ⟨T1, g3, f3⟩⟩

theorem Conv.adt_inv (h : Conv β (Term.apps (.Adt a r) ps) (Term.apps (.Adt a' r') ps')) :
    a = a' ∧ r = r' ∧ Convs β ps ps' := by
  obtain ⟨c, h1, h2⟩ := h
  obtain ⟨bs1, rfl, g1⟩ := h1.adt_inv
  obtain ⟨bs2, he, g2⟩ := h2.adt_inv
  obtain ⟨hh, rfl⟩ := Term.apps_head_inv (by trivial) (by trivial) he
  cases hh; exact ⟨rfl, rfl, g1.convs g2⟩

theorem Conv.ctr_inv (h : Conv β (Term.apps (.Ctr a c) xs) (Term.apps (.Ctr a' c') xs')) :
    a = a' ∧ c = c' ∧ Convs β xs xs' := by
  obtain ⟨d, h1, h2⟩ := h
  obtain ⟨bs1, rfl, g1⟩ := h1.ctr_inv
  obtain ⟨bs2, he, g2⟩ := h2.ctr_inv
  obtain ⟨hh, rfl⟩ := Term.apps_head_inv (by trivial) (by trivial) he
  cases hh; exact ⟨rfl, rfl, g1.convs g2⟩

-- KLe: reflexive, closed under reduction into either side (the easy way),
-- and its three inversions
theorem KLe.refl (g : Term) : KLe β g g := .conv (Conv.refl g)

theorem KLe.of_red_l (hr : Red β .strong g g') (h : KLe β g' k) : KLe β g k := by
  induction h with
  | many hm => exact .many (hr.trans hm)
  | lone hl hq => exact .lone hl hq
  | minL hm k1 k2 _ _ => exact .minL (hr.trans hm) k1 k2
  | minR1 hm _ ih => exact .minR1 hm (ih hr)
  | minR2 hm _ ih => exact .minR2 hm (ih hr)
  | conv hc => obtain ⟨c, h1, h2⟩ := hc; exact .conv ⟨c, hr.trans h1, h2⟩

theorem KLe.of_red_r (hr : Red β .strong k k') (h : KLe β g k') : KLe β g k := by
  induction h with
  | many hm => exact .many hm
  | lone hl hq => exact .lone (hr.trans hl) hq
  | minL hm _ _ ih1 ih2 => exact .minL hm (ih1 hr) (ih2 hr)
  | minR1 hm k1 _ => exact .minR1 (hr.trans hm) k1
  | minR2 hm k2 _ => exact .minR2 (hr.trans hm) k2
  | conv hc => obtain ⟨c, h1, h2⟩ := hc; exact .conv ⟨c, h1, hr.trans h2⟩

theorem KLe.many_inv (h : KLe β g (.Qua .Many)) : KLe β g k := by
  generalize hM : Term.Qua .Many = M at h
  induction h with
  | many hm => exact .many hm
  | lone hl hq => subst hM; exact absurd hl.qua_inv (by intro e; cases e; exact hq rfl)
  | minL hm _ _ ih1 ih2 => exact .minL hm (ih1 hM) (ih2 hM)
  | minR1 hm _ _ => subst hM; cases hm.qua_inv
  | minR2 hm _ _ => subst hM; cases hm.qua_inv
  | conv hc => subst hM; obtain ⟨c, h1, h2⟩ := hc; rw [h2.qua_inv] at h1; exact .many h1

theorem KLe.lone_inv (hq : q ≠ .Many) (h : KLe β (.Qua q) k) : KLe β g k := by
  generalize hQ : Term.Qua q = Q at h
  induction h with
  | many hm => subst hQ; exact absurd hm.qua_inv (by intro e; cases e; exact hq rfl)
  | lone hl hq' => exact .lone hl hq'
  | minL hm _ _ _ _ => subst hQ; cases hm.qua_inv
  | minR1 hm _ ih => exact .minR1 hm (ih hQ)
  | minR2 hm _ ih => exact .minR2 hm (ih hQ)
  | conv hc => subst hQ; obtain ⟨c, h1, h2⟩ := hc; rw [h1.qua_inv] at h2; exact .lone h2 hq

theorem KLe.minL_inv (h : KLe β (.Min h1 h2) k) : KLe β h1 k ∧ KLe β h2 k := by
  generalize hH : Term.Min h1 h2 = H at h
  induction h with
  | many hm =>
    subst hH
    rcases hm.min_inv with ⟨_, _, he, _⟩ | ⟨ha, hb⟩ | ⟨hb, ha⟩ | ⟨_, he⟩ | ⟨_, he⟩ | ⟨_, _, he⟩
    all_goals try cases he
    all_goals exact ⟨.many ha, .many hb⟩
  | lone hl hq => exact ⟨.lone hl hq, .lone hl hq⟩
  | minL hm k1 k2 _ _ =>
    subst hH
    rcases hm.min_inv with ⟨_, _, he, ha, hb⟩ | ⟨ha, hb⟩ | ⟨hb, ha⟩ | ⟨_, he⟩ | ⟨_, he⟩ | ⟨_, _, he⟩
    all_goals try cases he
    · exact ⟨.of_red_l ha k1, .of_red_l hb k2⟩
    · exact ⟨.many ha, .of_red_l hb (.minL .refl k1 k2)⟩
    · exact ⟨.of_red_l ha (.minL .refl k1 k2), .many hb⟩
  | minR1 hm _ ih => obtain ⟨i1, i2⟩ := ih hH; exact ⟨.minR1 hm i1, .minR1 hm i2⟩
  | minR2 hm _ ih => obtain ⟨i1, i2⟩ := ih hH; exact ⟨.minR2 hm i1, .minR2 hm i2⟩
  | conv hc =>
    subst hH
    obtain ⟨c, hm, hk⟩ := hc
    rcases hm.min_inv with ⟨_, _, rfl, ha, hb⟩ | ⟨ha, hb⟩ | ⟨hb, ha⟩ | ⟨ha, rfl⟩ | ⟨hb, rfl⟩ | ⟨ha, hb, rfl⟩
    · exact ⟨.minR1 hk (.conv ⟨_, ha, .refl⟩), .minR2 hk (.conv ⟨_, hb, .refl⟩)⟩
    · exact ⟨.many ha, .conv ⟨_, hb, hk⟩⟩
    · exact ⟨.conv ⟨_, ha, hk⟩, .many hb⟩
    all_goals exact ⟨.lone hk (by intro e; cases e), .lone hk (by intro e; cases e)⟩

-- Le: reflexive, and every derivation is a conversion or a reduction of
-- both sides into one of the three directional head forms
theorem Le.refl (t : Term) : Le β t t := .conv (Conv.refl t)

theorem Le.inv (h : Le β a b) :
    Conv β a b ∨
    (∃ g h', Red β .strong a (.Typ g) ∧ Red β .strong b (.Typ h') ∧ KLe β g h') ∨
    (∃ q A B A' B', Red β .strong a (.All q A B) ∧ Red β .strong b (.All q A' B') ∧
      Le β A' A ∧ Le β B B') ∨
    (∃ x r ps r' ps', Red β .strong a (Term.apps (.Adt x r) ps) ∧
      Red β .strong b (Term.apps (.Adt x r') ps') ∧
      (∀ c, c ∈ r' → c ∈ r) ∧ ps.length = ps'.length ∧
      (∀ (i : Nat) p p', ps[i]? = some p → ps'[i]? = some p' → Conv β p p')) := by
  induction h with
  | conv hc => exact .inl hc
  | red r1 r2 _ ih =>
    rcases ih with ⟨c, h1, h2⟩ | ⟨g, h', h1, h2, hk⟩ | ⟨q, A, B, A', B', h1, h2, hA, hB⟩
      | ⟨x, r, ps, r', ps', h1, h2, hr, hl, hc⟩
    · exact .inl ⟨c, r1.trans h1, r2.trans h2⟩
    · exact .inr (.inl ⟨g, h', r1.trans h1, r2.trans h2, hk⟩)
    · exact .inr (.inr (.inl ⟨q, A, B, A', B', r1.trans h1, r2.trans h2, hA, hB⟩))
    · exact .inr (.inr (.inr ⟨x, r, ps, r', ps', r1.trans h1, r2.trans h2, hr, hl, hc⟩))
  | typ hk => exact .inr (.inl ⟨_, _, .refl, .refl, hk⟩)
  | all hA hB => exact .inr (.inr (.inl ⟨_, _, _, _, _, .refl, .refl, hA, hB⟩))
  | adt hr hl hc => exact .inr (.inr (.inr ⟨_, _, _, _, _, .refl, .refl, hr, hl, hc⟩))

-- ----------------------------------------------------------------------------
-- with confluence: pointwise conversion composes, KLe and Le are closed
-- under reduction on either side and transitive, and a fit between two
-- head forms inverts componentwise
-- ----------------------------------------------------------------------------

theorem Convs.of_reds (h1 : Reds β .strong xs xs1) (h2 : Reds β .strong ys ys1)
    (hc : Convs β xs1 ys1) : Convs β xs ys := by
  induction h1 generalizing ys ys1 with
  | nil => cases hc; cases h2; exact .nil
  | cons r1 _ ih =>
    cases hc with
    | cons c hcs =>
      cases h2 with
      | cons r2 hrs =>
        obtain ⟨d, c1, c2⟩ := c
        exact .cons ⟨d, r1.trans c1, r2.trans c2⟩ (ih hrs hcs)

theorem Convs.red_l (hβ : Book.Closed β) (hr : Reds β .strong xs xs1) (hc : Convs β xs ys) :
    Convs β xs1 ys := by
  induction hr generalizing ys with
  | nil => exact hc
  | cons r _ ih => cases hc with | cons c hcs => exact .cons (Conv.red_l hβ r c) (ih hcs)

theorem Convs.red_r (hβ : Book.Closed β) (hr : Reds β .strong ys ys1) (hc : Convs β xs ys) :
    Convs β xs ys1 := by
  induction hr generalizing xs with
  | nil => exact hc
  | cons r _ ih => cases hc with | cons c hcs => exact .cons (Conv.red_r hβ r c) (ih hcs)

theorem Convs.trans (hβ : Book.Closed β) (h1 : Convs β xs ys) (h2 : Convs β ys zs) :
    Convs β xs zs := by
  induction h1 generalizing zs with
  | nil => exact h2
  | cons c1 _ ih => cases h2 with | cons c2 h2s => exact .cons (c1.trans hβ c2) (ih h2s)

theorem Convs.map (hc : Convs β xs ys) (F : Term → Term)
    (hF : ∀ p p', Conv β p p' → Conv β (F p) (F p')) : Convs β (xs.map F) (ys.map F) := by
  induction hc with
  | nil => exact .nil
  | cons c _ ih => exact .cons (hF _ _ c) ih

theorem KLe.red_l (hβ : Book.Closed β) (h : KLe β g k) :
    ∀ g', Red β .strong g g' → KLe β g' k := by
  induction h with
  | many hm =>
    intro g' hr
    obtain ⟨d, h1, h2⟩ := church_rosser_closed hβ hm hr
    rw [h1.qua_inv] at h2; exact .many h2
  | lone hl hq => intro g' _; exact .lone hl hq
  | minL hm _ _ ih1 ih2 =>
    intro g' hr
    obtain ⟨d, h1, h2⟩ := church_rosser_closed hβ hm hr
    refine .of_red_l h2 ?_
    rcases h1.min_inv with ⟨_, _, rfl, ha, hb⟩ | ⟨_, hb⟩ | ⟨_, ha⟩ | ⟨ha, rfl⟩ | ⟨hb, rfl⟩ | ⟨ha, _, rfl⟩
    · exact .minL .refl (ih1 _ ha) (ih2 _ hb)
    · exact ih2 _ hb
    · exact ih1 _ ha
    · exact ih1 _ ha
    · exact ih2 _ hb
    · exact ih1 _ ha
  | minR1 hm _ ih => intro g' hr; exact .minR1 hm (ih g' hr)
  | minR2 hm _ ih => intro g' hr; exact .minR2 hm (ih g' hr)
  | conv hc => intro g' hr; exact .conv (Conv.red_l hβ hr hc)

theorem KLe.red_r (hβ : Book.Closed β) (h : KLe β g k) :
    ∀ k', Red β .strong k k' → KLe β g k' := by
  induction h with
  | many hm => intro k' _; exact .many hm
  | lone hl hq =>
    intro k' hr
    obtain ⟨d, h1, h2⟩ := church_rosser_closed hβ hl hr
    rw [h1.qua_inv] at h2; exact .lone h2 hq
  | minL hm _ _ ih1 ih2 => intro k' hr; exact .minL hm (ih1 k' hr) (ih2 k' hr)
  | minR1 hm _ ih =>
    intro k' hr
    obtain ⟨d, h1, h2⟩ := church_rosser_closed hβ hm hr
    refine .of_red_r h2 ?_
    rcases h1.min_inv with ⟨_, _, rfl, ha, _⟩ | ⟨ha, _⟩ | ⟨_, ha⟩ | ⟨_, rfl⟩ | ⟨_, rfl⟩ | ⟨_, _, rfl⟩
    · exact .minR1 .refl (ih _ ha)
    · exact (ih _ ha).many_inv
    · exact ih _ ha
    all_goals exact .lone .refl (by intro e; cases e)
  | minR2 hm _ ih =>
    intro k' hr
    obtain ⟨d, h1, h2⟩ := church_rosser_closed hβ hm hr
    refine .of_red_r h2 ?_
    rcases h1.min_inv with ⟨_, _, rfl, _, hb⟩ | ⟨_, hb⟩ | ⟨hb, _⟩ | ⟨_, rfl⟩ | ⟨_, rfl⟩ | ⟨_, _, rfl⟩
    · exact .minR2 .refl (ih _ hb)
    · exact ih _ hb
    · exact (ih _ hb).many_inv
    all_goals exact .lone .refl (by intro e; cases e)
  | conv hc => intro k' hr; exact .conv (Conv.red_r hβ hr hc)

theorem KLe.trans (hβ : Book.Closed β) (h1 : KLe β g h) : ∀ k, KLe β h k → KLe β g k := by
  induction h1 with
  | many hm => intro k _; exact .many hm
  | lone hl hq => intro k h2; exact KLe.lone_inv hq (h2.red_l hβ _ hl)
  | minL hm _ _ ih1 ih2 => intro k h2; exact .minL hm (ih1 k h2) (ih2 k h2)
  | minR1 hm _ ih => intro k h2; exact ih k (h2.red_l hβ _ hm).minL_inv.1
  | minR2 hm _ ih => intro k h2; exact ih k (h2.red_l hβ _ hm).minL_inv.2
  | conv hc => intro k h2; obtain ⟨c, hc1, hc2⟩ := hc; exact .of_red_l hc1 (h2.red_l hβ _ hc2)

theorem KLe.shift (hβ : Book.Closed β) (h : KLe β g k) :
    ∀ d, KLe β (Term.shift d g) (Term.shift d k) := by
  induction h with
  | many hm => intro d; exact .many (hm.shift hβ d)
  | lone hl hq => intro d; exact .lone (hl.shift hβ d) hq
  | minL hm _ _ ih1 ih2 => intro d; exact .minL (hm.shift hβ d) (ih1 d) (ih2 d)
  | minR1 hm _ ih => intro d; exact .minR1 (hm.shift hβ d) (ih d)
  | minR2 hm _ ih => intro d; exact .minR2 (hm.shift hβ d) (ih d)
  | conv hc => intro d; exact .conv (hc.shift hβ d)

theorem KLe.subst (hβ : Book.Closed β) (h : KLe β g k) :
    ∀ d w, KLe β (Term.subst d w g) (Term.subst d w k) := by
  induction h with
  | many hm => intro d w; exact .many (hm.subst hβ d w)
  | lone hl hq => intro d w; exact .lone (hl.subst hβ d w) hq
  | minL hm _ _ ih1 ih2 => intro d w; exact .minL (hm.subst hβ d w) (ih1 d w) (ih2 d w)
  | minR1 hm _ ih => intro d w; exact .minR1 (hm.subst hβ d w) (ih d w)
  | minR2 hm _ ih => intro d w; exact .minR2 (hm.subst hβ d w) (ih d w)
  | conv hc => intro d w; exact .conv (hc.subst hβ (Conv.refl w) d)

theorem Le.red_lr (hβ : Book.Closed β) (h : Le β a b) :
    (∀ a', Red β .strong a a' → Le β a' b) ∧ (∀ b', Red β .strong b b' → Le β a b') := by
  induction h with
  | conv hc =>
    exact ⟨fun _ r => .conv (Conv.red_l hβ r hc), fun _ r => .conv (Conv.red_r hβ r hc)⟩
  | red r1 r2 _ ih =>
    refine ⟨fun a' r => ?_, fun b' r => ?_⟩
    · obtain ⟨d, h1, h2⟩ := church_rosser_closed hβ r1 r
      exact .red h2 r2 (ih.1 d h1)
    · obtain ⟨d, h1, h2⟩ := church_rosser_closed hβ r2 r
      exact .red r1 h2 (ih.2 d h1)
  | typ hk =>
    refine ⟨fun a' r => ?_, fun b' r => ?_⟩
    · obtain ⟨_, rfl, hg⟩ := r.typ_inv; exact .typ (hk.red_l hβ _ hg)
    · obtain ⟨_, rfl, hh⟩ := r.typ_inv; exact .typ (hk.red_r hβ _ hh)
  | all _ _ ihA ihB =>
    refine ⟨fun a' r => ?_, fun b' r => ?_⟩
    · obtain ⟨A1, B1, rfl, hA, hB⟩ := r.all_inv; exact .all (ihA.2 A1 hA) (ihB.1 B1 hB)
    · obtain ⟨A1, B1, rfl, hA, hB⟩ := r.all_inv; exact .all (ihA.1 A1 hA) (ihB.2 B1 hB)
  | adt hsub hlen hconv =>
    refine ⟨fun a' r => ?_, fun b' r => ?_⟩
    · obtain ⟨ps1, rfl, hps⟩ := r.adt_inv
      have hc := Convs.red_l hβ hps (Convs.of_index hlen hconv)
      exact .adt hsub hc.length hc.get
    · obtain ⟨ps1, rfl, hps⟩ := r.adt_inv
      have hc := Convs.red_r hβ hps (Convs.of_index hlen hconv)
      exact .adt hsub hc.length hc.get

theorem Le.red_l (hβ : Book.Closed β) (r : Red β .strong a a') (h : Le β a b) : Le β a' b :=
  (h.red_lr hβ).1 a' r

theorem Le.red_r (hβ : Book.Closed β) (r : Red β .strong b b') (h : Le β a b) : Le β a b' :=
  (h.red_lr hβ).2 b' r

theorem Le.trans_lr (hβ : Book.Closed β) (h : Le β a b) :
    (∀ c, Le β b c → Le β a c) ∧ (∀ x, Le β x a → Le β x b) := by
  induction h with
  | conv hc =>
    obtain ⟨d, h1, h2⟩ := hc
    exact ⟨fun c hbc => .red h1 .refl (hbc.red_l hβ h2),
           fun x hxa => .red .refl h2 (hxa.red_r hβ h1)⟩
  | red r1 r2 _ ih =>
    exact ⟨fun c hbc => .red r1 .refl (ih.1 c (hbc.red_l hβ r2)),
           fun x hxa => .red .refl r2 (ih.2 x (hxa.red_r hβ r1))⟩
  | typ hk =>
    refine ⟨fun c hbc => ?_, fun x hxa => ?_⟩
    · rcases hbc.inv with ⟨d, r1, r2⟩ | ⟨_, _, r1, r2, hk'⟩ | ⟨_, _, _, _, _, r1, _⟩
        | ⟨_, _, _, _, _, r1, _⟩
      · obtain ⟨_, rfl, hh⟩ := r1.typ_inv
        exact .red .refl r2 (.typ (hk.red_r hβ _ hh))
      · obtain ⟨_, he, hh⟩ := r1.typ_inv; cases he
        exact .red .refl r2 (.typ ((hk.red_r hβ _ hh).trans hβ _ hk'))
      · simpa [Term.tag] using r1.tag
      · simpa [Term.tag] using r1.tag
    · rcases hxa.inv with ⟨d, r1, r2⟩ | ⟨_, _, r1, r2, hk'⟩ | ⟨_, _, _, _, _, _, r2, _⟩
        | ⟨_, _, _, _, _, _, r2, _⟩
      · obtain ⟨_, rfl, hg⟩ := r2.typ_inv
        exact .red r1 .refl (.typ (hk.red_l hβ _ hg))
      · obtain ⟨_, he, hg⟩ := r2.typ_inv; cases he
        exact .red r1 .refl (.typ (hk'.trans hβ _ (hk.red_l hβ _ hg)))
      · simpa [Term.tag] using r2.tag
      · simpa [Term.tag] using r2.tag
  | all hA hB ihA ihB =>
    refine ⟨fun c hbc => ?_, fun x hxa => ?_⟩
    · rcases hbc.inv with ⟨d, r1, r2⟩ | ⟨_, _, r1, _⟩ | ⟨_, _, _, C1, C2, r1, r2, hC1, hC2⟩
        | ⟨_, _, _, _, _, r1, _⟩
      · obtain ⟨A1, B1, rfl, hA1, hB1⟩ := r1.all_inv
        exact .red .refl r2 (.all (hA.red_l hβ hA1) (hB.red_r hβ hB1))
      · simpa [Term.tag] using r1.tag
      · obtain ⟨A1, B1, he, hA1, hB1⟩ := r1.all_inv; cases he
        exact .red .refl r2 (.all (ihA.2 C1 (.red .refl hA1 hC1)) (ihB.1 C2 (.red hB1 .refl hC2)))
      · simpa [Term.tag] using r1.tag
    · rcases hxa.inv with ⟨d, r1, r2⟩ | ⟨_, _, _, r2, _⟩ | ⟨_, X1, X2, _, _, r1, r2, hX1, hX2⟩
        | ⟨_, _, _, _, _, _, r2, _⟩
      · obtain ⟨A1, B1, rfl, hA1, hB1⟩ := r2.all_inv
        exact .red r1 .refl (.all (hA.red_r hβ hA1) (hB.red_l hβ hB1))
      · simpa [Term.tag] using r2.tag
      · obtain ⟨A1, B1, he, hA1, hB1⟩ := r2.all_inv; cases he
        exact .red r1 .refl (.all (ihA.1 X1 (.red hA1 .refl hX1)) (ihB.2 X2 (.red .refl hB1 hX2)))
      · simpa [Term.tag] using r2.tag
  | adt hsub hlen hconv =>
    refine ⟨fun c hbc => ?_, fun x hxa => ?_⟩
    · rcases hbc.inv with ⟨d, r1, r2⟩ | ⟨_, _, r1, _⟩ | ⟨_, _, _, _, _, r1, _⟩
        | ⟨_, _, _, _, _, r1, r2, hsub', hlen', hconv'⟩
      · obtain ⟨ps1, rfl, hps⟩ := r1.adt_inv
        have hc := Convs.red_r hβ hps (Convs.of_index hlen hconv)
        exact .red .refl r2 (.adt hsub hc.length hc.get)
      · simpa [Term.tag] using r1.tag
      · simpa [Term.tag] using r1.tag
      · obtain ⟨ps1, he, hps⟩ := r1.adt_inv
        obtain ⟨hh, rfl⟩ := Term.apps_head_inv (by trivial) (by trivial) he; cases hh
        have hc := Convs.trans hβ (Convs.red_r hβ hps (Convs.of_index hlen hconv))
          (Convs.of_index hlen' hconv')
        exact .red .refl r2 (.adt (fun c hc => hsub c (hsub' c hc)) hc.length hc.get)
    · rcases hxa.inv with ⟨d, r1, r2⟩ | ⟨_, _, _, r2, _⟩ | ⟨_, _, _, _, _, _, r2, _⟩
        | ⟨_, _, _, _, _, r1, r2, hsub', hlen', hconv'⟩
      · obtain ⟨ps1, rfl, hps⟩ := r2.adt_inv
        have hc := Convs.red_l hβ hps (Convs.of_index hlen hconv)
        exact .red r1 .refl (.adt hsub hc.length hc.get)
      · simpa [Term.tag] using r2.tag
      · simpa [Term.tag] using r2.tag
      · obtain ⟨ps1, he, hps⟩ := r2.adt_inv
        obtain ⟨hh, rfl⟩ := Term.apps_head_inv (by trivial) (by trivial) he; cases hh
        have hc := Convs.trans hβ (Convs.of_index hlen' hconv')
          (Convs.red_l hβ hps (Convs.of_index hlen hconv))
        exact .red r1 .refl (.adt (fun c hc => hsub' c (hsub c hc)) hc.length hc.get)

theorem Le.trans (hβ : Book.Closed β) (h1 : Le β a b) (h2 : Le β b c) : Le β a c :=
  (h1.trans_lr hβ).1 c h2

theorem Le.conv_r (hβ : Book.Closed β) (h : Le β a b) (hc : Conv β b c) : Le β a c :=
  h.trans hβ (.conv hc)

theorem Le.shift (hβ : Book.Closed β) (h : Le β a b) :
    ∀ d, Le β (Term.shift d a) (Term.shift d b) := by
  induction h with
  | conv hc => intro d; exact .conv (hc.shift hβ d)
  | red r1 r2 _ ih => intro d; exact .red (r1.shift hβ d) (r2.shift hβ d) (ih d)
  | typ hk => intro d; exact .typ (hk.shift hβ d)
  | all _ _ ihA ihB => intro d; exact .all (ihA d) (ihB (d + 1))
  | adt hsub hlen hconv =>
    intro d
    rw [Term.shift_apps, Term.shift_apps]
    have hc := Convs.map (Convs.of_index hlen hconv) (Term.shift d) (fun _ _ h => h.shift hβ d)
    exact .adt hsub hc.length hc.get

theorem Le.subst (hβ : Book.Closed β) (h : Le β a b) :
    ∀ d w, Le β (Term.subst d w a) (Term.subst d w b) := by
  induction h with
  | conv hc => intro d w; exact .conv (hc.subst hβ (Conv.refl w) d)
  | red r1 r2 _ ih => intro d w; exact .red (r1.subst hβ d w) (r2.subst hβ d w) (ih d w)
  | typ hk => intro d w; exact .typ (hk.subst hβ d w)
  | all _ _ ihA ihB => intro d w; exact .all (ihA d w) (ihB (d + 1) (Term.shift 0 w))
  | adt hsub hlen hconv =>
    intro d w
    rw [Term.subst_apps, Term.subst_apps]
    have hc := Convs.map (Convs.of_index hlen hconv) (Term.subst d w)
      (fun _ _ h => h.subst hβ (Conv.refl w) d)
    exact .adt hsub hc.length hc.get

theorem Le.substR (hβ : Book.Closed β) (h : Le β a b) (hw : Conv β w w') (d : Nat) :
    Le β (Term.subst d w a) (Term.subst d w' b) :=
  (h.subst hβ d w).conv_r hβ (hw.substR hβ d b)

theorem Le.typ_inv (hβ : Book.Closed β) (h : Le β a b) (ra : Red β .strong a (.Typ g))
    (rb : Red β .strong b (.Typ k)) : KLe β g k := by
  rcases ((h.red_l hβ ra).red_r hβ rb).inv with hc | ⟨_, _, r1, r2, hk⟩
    | ⟨_, _, _, _, _, r1, _⟩ | ⟨_, _, _, _, _, r1, _⟩
  · exact .conv hc.typ_inv
  · obtain ⟨_, he1, hg⟩ := r1.typ_inv; cases he1
    obtain ⟨_, he2, hk1⟩ := r2.typ_inv; cases he2
    exact (hk.of_red_l hg).of_red_r hk1
  · simpa [Term.tag] using r1.tag
  · simpa [Term.tag] using r1.tag

theorem Le.all_inv (hβ : Book.Closed β) (h : Le β a b) (ra : Red β .strong a (.All q A B))
    (rb : Red β .strong b (.All q' A' B')) : q = q' ∧ Le β A' A ∧ Le β B B' := by
  rcases ((h.red_l hβ ra).red_r hβ rb).inv with hc | ⟨_, _, r1, _⟩
    | ⟨_, _, _, _, _, r1, r2, hA, hB⟩ | ⟨_, _, _, _, _, r1, _⟩
  · obtain ⟨rfl, hA, hB⟩ := hc.all_inv; exact ⟨rfl, .conv hA.symm, .conv hB⟩
  · simpa [Term.tag] using r1.tag
  · obtain ⟨_, _, he1, hA3, hB3⟩ := r1.all_inv; cases he1
    obtain ⟨_, _, he2, hA4, hB4⟩ := r2.all_inv; cases he2
    exact ⟨rfl, .red hA4 hA3 hA, .red hB3 hB4 hB⟩
  · simpa [Term.tag] using r1.tag

theorem Le.adt_inv (hβ : Book.Closed β) (h : Le β a b)
    (ra : Red β .strong a (Term.apps (.Adt x r) ps))
    (rb : Red β .strong b (Term.apps (.Adt x' r') ps')) :
    x = x' ∧ (∀ c, c ∈ r' → c ∈ r) ∧ Convs β ps ps' := by
  rcases ((h.red_l hβ ra).red_r hβ rb).inv with hc | ⟨_, _, r1, _⟩
    | ⟨_, _, _, _, _, r1, _⟩ | ⟨_, _, _, _, _, r1, r2, hsub, hlen, hconv⟩
  · obtain ⟨rfl, rfl, hcs⟩ := hc.adt_inv; exact ⟨rfl, fun _ hm => hm, hcs⟩
  · simpa [Term.tag] using r1.tag
  · simpa [Term.tag] using r1.tag
  · obtain ⟨_, he1, hps1⟩ := r1.adt_inv
    obtain ⟨hh1, rfl⟩ := Term.apps_head_inv (by trivial) (by trivial) he1; cases hh1
    obtain ⟨_, he2, hps2⟩ := r2.adt_inv
    obtain ⟨hh2, rfl⟩ := Term.apps_head_inv (by trivial) (by trivial) he2; cases hh2
    exact ⟨rfl, hsub, Convs.of_reds hps1 hps2 (Convs.of_index hlen hconv)⟩

theorem Le.eql_inv (hβ : Book.Closed β) (h : Le β a b) (ra : Red β .strong a (.Eql x y T))
    (rb : Red β .strong b (.Eql x' y' T')) : Conv β x x' ∧ Conv β y y' ∧ Conv β T T' := by
  rcases ((h.red_l hβ ra).red_r hβ rb).inv with hc | ⟨_, _, r1, _⟩
    | ⟨_, _, _, _, _, r1, _⟩ | ⟨_, _, _, _, _, r1, _⟩
  · exact hc.eql_inv
  all_goals simpa [Term.tag] using r1.tag

theorem Le.ctr_inv (hβ : Book.Closed β) (h : Le β a b)
    (ra : Red β .strong a (Term.apps (.Ctr x c) xs))
    (rb : Red β .strong b (Term.apps (.Ctr x' c') xs')) :
    x = x' ∧ c = c' ∧ Convs β xs xs' := by
  rcases ((h.red_l hβ ra).red_r hβ rb).inv with hc | ⟨_, _, r1, _⟩
    | ⟨_, _, _, _, _, r1, _⟩ | ⟨_, _, _, _, _, r1, _⟩
  · exact hc.ctr_inv
  all_goals simpa [Term.tag] using r1.tag

-- ============================================================================
-- METATHEORY §D0 — typed terms are closed; Book.Ok closes the book
-- ============================================================================

theorem Term.era_closed (q : Quant) (h : Term.Closed n u) :
    Term.Closed n (Term.era q u) := by
  cases q <;> first | trivial | exact h

theorem Check.closed_era (h : Check β Φ L sp q Γ t T π u) : u.Closed Γ.length := by
  induction h with
  | var hg => exact Term.era_closed _ (Ctx.get_lt hg)
  | min _ _ iha ihb => exact Term.era_closed _ ⟨iha, ihb⟩
  | all _ _ _ _ => exact Term.era_closed _ ⟨trivial, trivial⟩
  | lam _ _ _ _ ihf => exact Term.era_closed _ ihf
  | app _ _ ihf ihx => exact Term.era_closed _ ⟨ihf, ihx⟩
  | appLam _ _ ih => exact ih
  | let_ _ _ _ _ ihv _ ihb => exact Term.era_closed _ ⟨ihv, ihb⟩
  | eql _ _ _ _ _ _ => exact Term.era_closed _ ⟨trivial, trivial, trivial⟩
  | rwt _ _ _ ihe _ ihf => exact Term.era_closed _ ⟨ihe, trivial, ihf⟩
  | mat _ _ _ _ _ _ _ _ _ ihh ihm => exact Term.era_closed _ ⟨ihh, ihm⟩
  | cnv _ _ iht => exact iht
  | qnt => trivial
  | _ => exact Term.era_closed _ (by trivial)

-- ============================================================================
-- METATHEORY §D1 — the dead fragment: a None-demand derivation measures
-- nothing and elaborates to the token; any derivation replays dead
-- ============================================================================

theorem Quant.dem_none (q' : Quant) : Quant.dem q' .None = .None := by
  cases q' <;> rfl

theorem Check.none_era (h : Check β Φ L sp q Γ t T π u) : q = .None → u = .Qnt := by
  induction h with
  | appLam _ _ ih => exact ih
  | cnv _ _ ih => exact ih
  | qnt => intro _; exact _root_.rfl
  | _ => intro hq; subst hq; exact _root_.rfl

theorem Check.none_uses (h : Check β Φ L sp q Γ t T π u) : q = .None → π = Uses.zero := by
  induction h with
  | var _ => intro hq; subst hq; funext i; simp [Uses.one, Uses.zero]
  | min _ _ iha ihb =>
    intro hq; subst hq
    rw [iha _root_.rfl, ihb _root_.rfl]; funext i; exact _root_.rfl
  | lam _ _ _ _ ihf => intro hq; subst hq; rw [ihf _root_.rfl]; funext i; exact _root_.rfl
  | app _ _ ihf ihx =>
    intro hq; subst hq
    rw [ihf _root_.rfl, ihx (Quant.dem_none _)]; funext i; exact _root_.rfl
  | appLam _ _ ih => exact ih
  | let_ _ _ _ _ ihv _ ihb =>
    intro hq; subst hq
    rw [ihv (Quant.dem_none _), ihb _root_.rfl]; funext i; exact _root_.rfl
  | rwt _ _ _ ihe _ ihf =>
    intro hq; subst hq
    rw [ihe _root_.rfl, ihf _root_.rfl]; funext i; exact _root_.rfl
  | mat _ _ _ _ _ _ _ _ _ ihh ihm =>
    intro hq; subst hq
    rw [ihh _root_.rfl, ihm _root_.rfl]; funext i; exact _root_.rfl
  | cnv _ _ ih => exact ih
  | _ => intro _; exact _root_.rfl

-- any judgment replays at the dead demand
theorem Check.at_none (h : Check β Φ L sp q Γ t T π u) :
    ∃ π' u', Check β Φ L sp .None Γ t T π' u' := by
  induction h with
  | var hg => exact ⟨_, _, .var hg⟩
  | ref hk _ _ =>
    exact ⟨_, _, .ref hk (fun h => absurd _root_.rfl h) (fun h => absurd _root_.rfl h)⟩
  | refA hk h0 => exact ⟨_, _, .refA hk h0⟩
  | adt hk => exact ⟨_, _, .adt hk⟩
  | ctr hk hc hr => exact ⟨_, _, .ctr hk hc hr⟩
  | typ hg => exact ⟨_, _, .typ hg⟩
  | qnt => exact ⟨_, _, .qnt⟩
  | qua => exact ⟨_, _, .qua⟩
  | min _ _ iha ihb =>
    obtain ⟨_, _, ha⟩ := iha
    obtain ⟨_, _, hb⟩ := ihb
    exact ⟨_, _, .min ha hb⟩
  | all hA hB _ _ => exact ⟨_, _, .all hA hB⟩
  | lam hA _ _ _ ihf =>
    obtain ⟨π', _, hf'⟩ := ihf
    rw [hf'.none_uses _root_.rfl] at hf'
    exact ⟨_, _, .lam hA hf' trivial⟩
  | app _ _ ihf ihx =>
    obtain ⟨_, _, hf'⟩ := ihf
    obtain ⟨_, _, hx'⟩ := ihx
    exact ⟨_, _, .app hf' ((Quant.dem_none _).symm ▸ hx')⟩
  | appLam ha _ ih =>
    obtain ⟨_, _, h'⟩ := ih
    exact ⟨_, _, .appLam ha h'⟩
  | let_ _ hA _ _ ihv _ ihb =>
    obtain ⟨_, _, hv'⟩ := ihv
    obtain ⟨π', _, hb'⟩ := ihb
    rw [hb'.none_uses _root_.rfl] at hb'
    exact ⟨_, _, .let_ ((Quant.dem_none _).symm ▸ hv') hA hb' trivial⟩
  | eql hT ha hb _ _ _ => exact ⟨_, _, .eql hT ha hb⟩
  | rfl hc => exact ⟨_, _, .rfl hc⟩
  | rwt _ hP _ ihe _ ihf =>
    obtain ⟨_, _, he'⟩ := ihe
    obtain ⟨_, _, hf'⟩ := ihf
    exact ⟨_, _, .rwt he' hP hf'⟩
  | mat hk hc hr hlen _ hins hgoal _ _ ihh ihm =>
    obtain ⟨_, _, hh'⟩ := ihh
    obtain ⟨_, _, hm'⟩ := ihm
    exact ⟨_, _, .mat hk hc hr hlen (fun h => absurd _root_.rfl h) hins hgoal hh' hm'⟩
  | efq hk _ hd => exact ⟨_, _, .efq hk (fun h => absurd _root_.rfl h) hd⟩
  | cnv _ hc iht =>
    obtain ⟨_, _, ht'⟩ := iht
    exact ⟨_, _, .cnv ht' hc⟩

theorem Check.dead (h : Check β Φ L sp q Γ t T π u) :
    Check β Φ L sp .None Γ t T Uses.zero .Qnt := by
  obtain ⟨π', u', h'⟩ := h.at_none
  have e1 := h'.none_uses _root_.rfl
  have e2 := h'.none_era _root_.rfl
  subst e1 e2
  exact h'

-- ============================================================================
-- METATHEORY §D2 — the indices L and sp: every derivation replays under
-- the void equation with any pending spine, and with the wall up
-- ============================================================================

theorem Book.tld_lt : ∀ {β : Book} {k : Nat} {t : TLD},
    Book.tld β k = some t → k < β.length := by
  intro β
  induction β with
  | nil => intro k t h; cases h
  | cons d β ih =>
    intro k t h
    cases k with
    | zero => exact Nat.succ_pos _
    | succ k => exact Nat.succ_lt_succ (ih h)

theorem Book.defn_tld (h : Book.defn β k = some d) : Book.tld β k = some (.defn d) := by
  unfold Book.defn at h
  split at h
  case _ heq => cases h; exact heq
  case _ => cases h

theorem Book.tld_defn (h : Book.tld β k = some (.defn d)) : Book.defn β k = some d := by
  simp [Book.defn, h]

theorem Book.tld_adt (h : Book.tld β k = some (.adt A)) : Book.adt β k = some A := by
  simp [Book.adt, h]

theorem Book.adt_tld (h : Book.adt β k = some A) : Book.tld β k = some (.adt A) := by
  unfold Book.adt at h
  split at h
  case _ heq => cases h; exact heq
  case _ => cases h

theorem Book.defn_lt (h : Book.defn β k = some d) : k < β.length :=
  Book.tld_lt (Book.defn_tld h)

theorem Check.void_sp (h : Check β Φ L sp q Γ t T π u) :
    ∀ sp', Check β Φ (LHS.void β) sp' q Γ t T π u := by
  induction h with
  | var hg => intro sp'; exact .var hg
  | ref hk _ _ =>
    intro sp'
    have hj := Book.defn_lt hk
    exact .ref hk (fun _ => Nat.le_of_lt hj)
      (fun _ he => absurd he (Nat.ne_of_lt hj))
  | refA hk h0 => intro sp'; exact .refA hk h0
  | adt hk => intro sp'; exact .adt hk
  | ctr hk hc hr => intro sp'; exact .ctr hk hc hr
  | typ _ ihg => intro sp'; exact .typ (ihg [])
  | qnt => intro sp'; exact .qnt
  | qua => intro sp'; exact .qua
  | min _ _ iha ihb => intro sp'; exact .min (iha []) (ihb [])
  | all _ _ ihA ihB => intro sp'; exact .all (ihA []) (ihB [])
  | lam _ _ hle ihA ihf => intro sp'; exact .lam (ihA []) (ihf []) hle
  | app _ _ ihf ihx => intro sp'; exact .app (ihf _) (ihx [])
  | appLam ha _ ih => intro sp'; exact .appLam ha (ih sp')
  | let_ _ _ _ hle ihv ihA ihb => intro sp'; exact .let_ (ihv []) (ihA []) (ihb []) hle
  | eql _ _ _ ihT iha ihb => intro sp'; exact .eql (ihT []) (iha []) (ihb [])
  | rfl hc => intro sp'; exact .rfl hc
  | rwt _ _ _ ihe ihP ihf => intro sp'; exact .rwt (ihe []) (ihP []) (ihf [])
  | mat hk hc hr hlen hlive hins hgoal _ _ ihh ihm =>
    intro sp'; exact .mat hk hc hr hlen hlive hins hgoal (ihh []) (ihm [])
  | efq hk hlive hd => intro sp'; exact .efq hk hlive hd
  | cnv _ hc iht => intro sp'; exact .cnv (iht sp') hc

theorem Check.void (h : Check β Φ L sp q Γ t T π u) :
    Check β Φ (LHS.void β) sp q Γ t T π u :=
  h.void_sp sp

theorem Check.sp (h : Check β Φ (LHS.void β) s q Γ t T π u) (sp' : List Term) :
    Check β Φ (LHS.void β) sp' q Γ t T π u :=
  h.void_sp sp'

-- ============================================================================
-- METATHEORY §D3 — the let expansion δ: through append, spines, shifts,
-- context insertion and the closed substitution at the last position
-- ============================================================================

theorem Term.shift_shiftN : ∀ (n d : Nat) (t : Term), d ≤ n →
    Term.shift d (Term.shiftN n t) = Term.shiftN (n + 1) t := by
  intro n
  induction n with
  | zero => intro d t hd; cases Nat.eq_zero_of_le_zero hd; rfl
  | succ n ih =>
    intro d t hd
    cases d with
    | zero => rfl
    | succ d =>
      show Term.shift (d + 1) (Term.shift 0 (Term.shiftN n t))
        = Term.shift 0 (Term.shiftN (n + 1) t)
      rw [Term.shift_shift0, ih d t (by omega)]

theorem Term.subst_shiftN (n : Nat) (w t : Term) :
    Term.subst n w (Term.shiftN (n + 1) t) = Term.shiftN n t := by
  rw [← Term.shift_shiftN n n t (Nat.le_refl n)]
  exact Term.subst_shift _ n w

theorem Term.shift_shiftN_add : ∀ (d m : Nat) (v : Term),
    Term.shift (d + m) (Term.shiftN d v) = Term.shiftN d (Term.shift m v) := by
  intro d
  induction d with
  | zero => intro m v; rw [Nat.zero_add]; rfl
  | succ d ih =>
    intro m v
    show Term.shift (d + 1 + m) (Term.shift 0 (Term.shiftN d v))
      = Term.shift 0 (Term.shiftN d (Term.shift m v))
    rw [Nat.add_right_comm, Term.shift_shift0, ih]

theorem Term.shiftN_shift0 : ∀ (n : Nat) (t : Term),
    Term.shiftN n (Term.shift 0 t) = Term.shiftN (n + 1) t := by
  intro n
  induction n with
  | zero => intro t; rfl
  | succ n ih => intro t; show Term.shift 0 (Term.shiftN n (Term.shift 0 t)) = _; rw [ih]; rfl

theorem Term.shiftN_closed (hw : Term.Closed 0 w) : ∀ k, Term.shiftN k w = w := by
  intro k
  induction k with
  | zero => rfl
  | succ k ih =>
    show Term.shift 0 (Term.shiftN k w) = w
    rw [ih]; exact Term.shift_closed w 0 0 hw (Nat.le_refl 0)

-- a closed w is inert under subst at any index
theorem Term.subst_shiftN_add (hw : Term.Closed 0 w) : ∀ (d n : Nat) (v : Term),
    Term.subst (d + n) w (Term.shiftN d v) = Term.shiftN d (Term.subst n w v) := by
  intro d
  induction d with
  | zero => intro n v; rw [Nat.zero_add]; rfl
  | succ d ih =>
    intro n v
    show Term.subst (d + 1 + n) w (Term.shift 0 (Term.shiftN d v))
      = Term.shift 0 (Term.shiftN d (Term.subst n w v))
    rw [Nat.add_right_comm, ← ih, Term.shift_subst_lt _ 0 (d + n) w (Nat.zero_le _),
      Term.shift_closed w 0 0 hw (Nat.le_refl 0)]

theorem Term.closed_apps_inv : ∀ (as : List Term) (h : Term) (m : Nat),
    (Term.apps h as).Closed m → h.Closed m ∧ ∀ x ∈ as, x.Closed m := by
  intro as
  induction as with
  | nil => intro h m hc; exact ⟨hc, fun x hx => nomatch hx⟩
  | cons a as ih =>
    intro h m hc
    obtain ⟨⟨hh, ha⟩, hrest⟩ := ih (.App h a) m hc
    refine ⟨hh, fun x hx => ?_⟩
    rcases List.mem_cons.mp hx with rfl | hx
    · exact ha
    · exact hrest x hx

theorem Term.spine_closed {t : Term} {m : Nat} (h : t.Closed m) :
    (Term.spine t).1.Closed m ∧ ∀ x ∈ (Term.spine t).2, x.Closed m := by
  have := Term.closed_apps_inv (Term.spine t).2 (Term.spine t).1 m
  rw [Term.apps_spine t] at this
  exact this h

theorem Term.retip_closed (r : List Nat) : ∀ (n pn : Nat) (t : Term) (m : Nat),
    t.Closed m → (Term.retip r pn n t).Closed m := by
  intro n
  induction n with
  | zero =>
    intro pn t m hc
    cases pn with
    | zero =>
      simp only [Term.retip]
      split
      · obtain ⟨_, hargs⟩ := Term.spine_closed hc
        exact Term.closed_apps _ _ _ trivial hargs
      · exact hc
    | succ pn => simp only [Term.retip]; exact hc
  | succ n ih =>
    intro pn t m hc
    cases pn <;> cases t <;> simp only [Term.retip] <;> (try exact hc)
    · exact ⟨hc.1, ih 0 _ (m + 1) hc.2⟩
    · exact ⟨hc.1, ih _ _ (m + 1) hc.2⟩

theorem Term.shift_era (d : Nat) (q : Quant) (u : Term) :
    Term.shift d (Term.era q u) = Term.era q (Term.shift d u) := by
  cases q <;> rfl

theorem Term.subst_era (d : Nat) (w : Term) (q : Quant) (u : Term) :
    Term.subst d w (Term.era q u) = Term.era q (Term.subst d w u) := by
  cases q <;> rfl

-- the rigid binders of a context: the entries without a value
def Ctx.rigid : Ctx → Nat
  | [] => 0
  | b :: Γ =>
    match b.v with
    | some _ => Ctx.rigid Γ
    | none   => Ctx.rigid Γ + 1

theorem Ctx.δ_append : ∀ (Γ Δ : Ctx) (d : Nat) (t : Term),
    Ctx.δ (Γ ++ Δ) d t = Ctx.δ Δ (d + Γ.rigid) (Ctx.δ Γ d t) := by
  intro Γ
  induction Γ with
  | nil => intro Δ d t; rfl
  | cons b Γ ih =>
    intro Δ d t
    obtain ⟨q, T, v⟩ := b
    cases v <;> simp only [List.cons_append, Ctx.δ, Ctx.rigid]
    · rw [ih, show d + 1 + Ctx.rigid Γ = d + (Ctx.rigid Γ + 1) by omega]
    · exact ih Δ d _

theorem Ctx.δ_apps : ∀ (Γ : Ctx) (d : Nat) (f : Term) (xs : List Term),
    Ctx.δ Γ d (Term.apps f xs) = Term.apps (Ctx.δ Γ d f) (xs.map (Ctx.δ Γ d)) := by
  intro Γ
  induction Γ with
  | nil => intro d f xs; simp [Ctx.δ]
  | cons b Γ ih =>
    intro d f xs
    obtain ⟨q, T, v⟩ := b
    cases v <;> simp only [Ctx.δ]
    · exact ih _ f xs
    · rw [Term.subst_apps, ih, List.map_map]; rfl

-- δ commutes with a shift at or below its depth
theorem Ctx.δ_shift : ∀ (Γ : Ctx) (d d' : Nat) (t : Term), d ≤ d' →
    Ctx.δ Γ (d' + 1) (Term.shift d t) = Term.shift d (Ctx.δ Γ d' t) := by
  intro Γ
  induction Γ with
  | nil => intro d d' t _; rfl
  | cons b Γ ih =>
    intro d d' t h
    obtain ⟨q, T, v⟩ := b
    cases v <;> simp only [Ctx.δ]
    · exact ih d (d' + 1) t (by omega)
    · rw [← ih d d' _ h, Term.shift_subst_lt t d d' _ h, Term.shift_shiftN d' d _ h]

-- a term shifted above the whole context keeps only the rigid renumbering
theorem Ctx.δ_shiftN : ∀ (Γ : Ctx) (d k : Nat) (X : Term), d + Γ.length ≤ k →
    Ctx.δ Γ d (Term.shiftN k X) = Term.shiftN (k - Γ.length + Γ.rigid) X := by
  intro Γ
  induction Γ with
  | nil => intro d k X _; simp [Ctx.δ, Ctx.rigid]
  | cons b Γ ih =>
    intro d k X hk
    obtain ⟨q, T, v⟩ := b
    simp only [List.length_cons] at hk
    cases v <;> simp only [Ctx.δ, Ctx.rigid, List.length_cons]
    · rw [ih (d + 1) k X (by omega)]; congr 1; omega
    · obtain ⟨k', rfl⟩ : ∃ k', k = k' + 1 := ⟨k - 1, by omega⟩
      rw [← Term.shift_shiftN k' d X (by omega), Term.subst_shift, ih d k' X (by omega)]
      congr 1; omega

theorem Ctx.get_append : ∀ (Γ Δ : Ctx) (i : Nat), i < Γ.length →
    Ctx.get (Γ ++ Δ) i = Ctx.get Γ i := by
  intro Γ
  induction Γ with
  | nil => intro Δ i h; cases h
  | cons b Γ ih =>
    intro Δ i h
    cases i with
    | zero => rfl
    | succ i =>
      simp only [List.cons_append, Ctx.get]
      rw [ih Δ i (by simp only [List.length_cons] at h; omega)]

def Bind.shiftN : Nat → Bind → Bind
  | 0, b => b
  | n + 1, b => (Bind.shiftN n b).shift

theorem Bind.shiftN_q : ∀ (n : Nat) (b : Bind), (Bind.shiftN n b).q = b.q := by
  intro n; induction n with
  | zero => intro b; rfl
  | succ n ih => intro b; exact ih b

theorem Bind.shiftN_T : ∀ (n : Nat) (b : Bind), (Bind.shiftN n b).T = Term.shiftN n b.T := by
  intro n; induction n with
  | zero => intro b; rfl
  | succ n ih => intro b; show Term.shift 0 (Bind.shiftN n b).T = _; rw [ih]; rfl

theorem Ctx.get_append_ge : ∀ (Γ Δ : Ctx) (j : Nat),
    Ctx.get (Γ ++ Δ) (Γ.length + j) = (Ctx.get Δ j).map (Bind.shiftN Γ.length) := by
  intro Γ
  induction Γ with
  | nil => intro Δ j; simp only [List.nil_append, List.length_nil, Nat.zero_add]; cases Ctx.get Δ j <;> rfl
  | cons b Γ ih =>
    intro Δ j
    simp only [List.cons_append, List.length_cons]
    rw [show Γ.length + 1 + j = (Γ.length + j) + 1 by omega]
    simp only [Ctx.get]
    rw [ih, Option.map_map]; rfl

theorem Ctx.get_append_last (Γ : Ctx) (b0 : Bind) :
    Ctx.get (Γ ++ [b0]) Γ.length = some (Bind.shiftN (Γ.length + 1) b0) := by
  have := Ctx.get_append_ge Γ [b0] 0
  rw [Nat.add_zero] at this
  rw [this]
  simp only [Ctx.get, Option.map_some]
  congr 1
  induction Γ.length with
  | zero => rfl
  | succ n ih => show (Bind.shiftN n b0.shift).shift = (Bind.shiftN (n + 1) b0).shift; rw [ih]

-- context insertion: Γ' is Γ with U slotted in at depth n (the entries
-- above it shifted past it)
def Bind.shiftAt (n : Nat) (b : Bind) : Bind :=
  { b with T := Term.shift n b.T, v := b.v.map (Term.shift n) }

inductive Ins (U : Bind) : Nat → Ctx → Ctx → Prop
  | zero : Ins U 0 Γ (U :: Γ)
  | succ : Ins U n Γ Γ' → Ins U (n + 1) (b :: Γ) (b.shiftAt n :: Γ')

theorem Bind.shift_shiftAt (b : Bind) (n : Nat) :
    (b.shiftAt n).shift = b.shift.shiftAt (n + 1) := by
  obtain ⟨q, T, v⟩ := b
  cases v <;> simp [Bind.shiftAt, Bind.shift, Term.shift_shift0]

theorem Ins.get_lt (h : Ins U n Γ Γ') : ∀ {i : Nat} {b : Bind}, i < n →
    Ctx.get Γ i = some b → Ctx.get Γ' i = some (b.shiftAt n) := by
  induction h with
  | zero => intro i b hi; cases hi
  | @succ n Γ Γ' b0 _ ih =>
    intro i b hi hg
    cases i with
    | zero =>
      simp only [Ctx.get] at hg ⊢
      cases hg
      rw [Bind.shift_shiftAt]
    | succ j =>
      simp only [Ctx.get, Option.map_eq_some_iff] at hg ⊢
      obtain ⟨b', hb', rfl⟩ := hg
      exact ⟨_, ih (by omega) hb', Bind.shift_shiftAt b' n⟩

theorem Ins.get_ge (h : Ins U n Γ Γ') : ∀ {i : Nat} {b : Bind}, n ≤ i →
    Ctx.get Γ i = some b → Ctx.get Γ' (i + 1) = some (b.shiftAt n) := by
  induction h with
  | zero => intro i b _ hg; simp only [Ctx.get, hg, Option.map_some]; rfl
  | @succ n Γ Γ' b0 _ ih =>
    intro i b hi hg
    cases i with
    | zero => cases hi
    | succ j =>
      simp only [Ctx.get, Option.map_eq_some_iff] at hg ⊢
      obtain ⟨b', hb', rfl⟩ := hg
      exact ⟨_, ih (by omega) hb', Bind.shift_shiftAt b' n⟩

theorem Ins.length (h : Ins U n Γ Γ') : n ≤ Γ.length := by
  induction h with
  | zero => exact Nat.zero_le _
  | succ _ ih => exact Nat.succ_le_succ ih

-- δ through an insertion: a let entry is cancelled by the shift, a rigid
-- one renumbers the result
theorem Ins.δ (h : Ins U n Γ Γ') :
    (∀ d t, Ctx.δ Γ' d (Term.shift (d + n) t) = Ctx.δ Γ d t) ∨
    (∃ r, ∀ d t, Ctx.δ Γ' d (Term.shift (d + n) t) = Term.shift (d + r) (Ctx.δ Γ d t)) := by
  induction h with
  | @zero Γ =>
    obtain ⟨q, T, v⟩ := U
    cases v
    · right; exact ⟨0, fun d t => by simp only [Ctx.δ]; exact Ctx.δ_shift Γ d d t (Nat.le_refl d)⟩
    · left; intro d t; simp only [Ctx.δ]; rw [Nat.add_zero, Term.subst_shift]
  | @succ n Γ Γ' b _ ih =>
    obtain ⟨q, T, v⟩ := b
    cases v with
    | none =>
      simp only [Bind.shiftAt, Option.map_none, Ctx.δ]
      rcases ih with ih | ⟨r, ih⟩
      · left; intro d t
        rw [show d + (n + 1) = (d + 1) + n by omega]; exact ih (d + 1) t
      · right; refine ⟨r + 1, fun d t => ?_⟩
        rw [show d + (n + 1) = (d + 1) + n by omega, ih (d + 1) t,
          show d + 1 + r = d + (r + 1) by omega]
    | some v =>
      simp only [Bind.shiftAt, Option.map_some, Ctx.δ]
      have e : ∀ d t, Term.subst d (Term.shiftN d (Term.shift n v)) (Term.shift (d + (n + 1)) t)
          = Term.shift (d + n) (Term.subst d (Term.shiftN d v) t) := by
        intro d t
        rw [Term.shift_subst_ge t (d + n) d _ (by omega), Term.shift_shiftN_add,
          show d + (n + 1) = d + n + 1 by omega]
      rcases ih with ih | ⟨r, ih⟩
      · left; intro d t; rw [e, ih]
      · right; exact ⟨r, fun d t => by rw [e, ih]⟩

-- the closed substitution at the last position of a context: entry j
-- sees the last binder as index Γ.length - 1 - j
def Bind.substAt (k : Nat) (w : Term) (b : Bind) : Bind :=
  { b with T := Term.subst k w b.T, v := b.v.map (Term.subst k w) }

def Ctx.substLast (w : Term) : Ctx → Ctx
  | [] => []
  | b :: Γ => Bind.substAt Γ.length w b :: Ctx.substLast w Γ

theorem Ctx.substLast_length (w : Term) : ∀ (Γ : Ctx), (Ctx.substLast w Γ).length = Γ.length := by
  intro Γ; induction Γ with
  | nil => rfl
  | cons b Γ ih => simp only [Ctx.substLast, List.length_cons, ih]

theorem Bind.shift_substAt (hw : Term.Closed 0 w) (b : Bind) (k : Nat) :
    (b.substAt k w).shift = b.shift.substAt (k + 1) w := by
  obtain ⟨q, T, v⟩ := b
  have e : ∀ t, Term.shift 0 (Term.subst k w t) = Term.subst (k + 1) w (Term.shift 0 t) := by
    intro t
    rw [Term.shift_subst_lt t 0 k w (Nat.zero_le k), Term.shift_closed w 0 0 hw (Nat.le_refl 0)]
  cases v <;> simp [Bind.substAt, Bind.shift, e]

theorem Ctx.get_substLast (hw : Term.Closed 0 w) : ∀ (Γ : Ctx) (i : Nat) (b : Bind),
    Ctx.get Γ i = some b → Ctx.get (Ctx.substLast w Γ) i = some (b.substAt Γ.length w) := by
  intro Γ
  induction Γ with
  | nil => intro i b h; cases h
  | cons b0 Γ ih =>
    intro i b hg
    cases i with
    | zero =>
      simp only [Ctx.get, Ctx.substLast, List.length_cons] at hg ⊢
      cases hg
      rw [Bind.shift_substAt hw]
    | succ j =>
      simp only [Ctx.get, Ctx.substLast, List.length_cons, Option.map_eq_some_iff] at hg ⊢
      obtain ⟨b', hb', rfl⟩ := hg
      exact ⟨_, ih j b' hb', Bind.shift_substAt hw b' Γ.length⟩

-- δ of the substituted context on the substituted term is the substitution
-- of w into δ of the original, at the rigid depth
theorem Ctx.δ_substLast (hw : Term.Closed 0 w) : ∀ (Γ : Ctx) (d : Nat) (t : Term),
    Ctx.δ (Ctx.substLast w Γ) d (Term.subst (d + Γ.length) w t)
      = Term.subst (d + Γ.rigid) w (Ctx.δ Γ d t) := by
  intro Γ
  induction Γ with
  | nil => intro d t; rfl
  | cons b Γ ih =>
    intro d t
    obtain ⟨q, T, v⟩ := b
    cases v <;> simp only [Ctx.substLast, Bind.substAt, Option.map_none, Option.map_some, Ctx.δ,
      Ctx.rigid, List.length_cons]
    · rw [show d + (Γ.length + 1) = (d + 1) + Γ.length by omega, ih (d + 1) t,
        show d + 1 + Ctx.rigid Γ = d + (Ctx.rigid Γ + 1) by omega]
    · rw [show d + (Γ.length + 1) = (d + Γ.length) + 1 by omega, ← ih d,
        Term.subst_subst t (d + Γ.length) d w _ (by omega),
        Term.shift_closed w 0 d hw (Nat.zero_le d), Term.subst_shiftN_add hw]

-- δ of the extended context on a term in it
theorem Ctx.δ_append_none (hv : b0.v = none) (Γ : Ctx) (t : Term) :
    Ctx.δ (Γ ++ [b0]) 0 t = Ctx.δ Γ 0 t := by
  rw [Ctx.δ_append, Nat.zero_add]; simp only [Ctx.δ, hv]

theorem Ctx.δ_append_some (hw : Term.Closed 0 w) (hv : b0.v = some w) (Γ : Ctx) (t : Term) :
    Ctx.δ (Γ ++ [b0]) 0 t = Term.subst Γ.rigid w (Ctx.δ Γ 0 t) := by
  rw [Ctx.δ_append, Nat.zero_add]; simp only [Ctx.δ, hv]; rw [Term.shiftN_closed hw]

-- the use vectors of weakening and substitution
def Uses.lift (n : Nat) (π : Uses) : Uses :=
  fun i => if i < n then π i else if i = n then .None else π (i - 1)

def Uses.del (n : Nat) (π : Uses) : Uses :=
  fun i => if i < n then π i else π (i + 1)

theorem Uses.lift_one_lt (n i : Nat) (q : Quant) (h : i < n) :
    Uses.lift n (Uses.one i q) = Uses.one i q := by
  funext j
  simp only [Uses.lift, Uses.one]
  by_cases h1 : j < n
  · rw [if_pos h1]
  · rw [if_neg h1, if_neg (show ¬ j = i by omega)]
    by_cases h2 : j = n
    · rw [if_pos h2]
    · rw [if_neg h2, if_neg (show ¬ j - 1 = i by omega)]

theorem Uses.lift_one_ge (n i : Nat) (q : Quant) (h : n ≤ i) :
    Uses.lift n (Uses.one i q) = Uses.one (i + 1) q := by
  funext j
  simp only [Uses.lift, Uses.one]
  by_cases h1 : j < n
  · rw [if_pos h1, if_neg (show ¬ j = i by omega), if_neg (show ¬ j = i + 1 by omega)]
  · rw [if_neg h1]
    by_cases h2 : j = n
    · rw [if_pos h2, if_neg (show ¬ j = i + 1 by omega)]
    · rw [if_neg h2]
      by_cases h3 : j = i + 1
      · rw [if_pos h3, if_pos (show j - 1 = i by omega)]
      · rw [if_neg h3, if_neg (show ¬ j - 1 = i by omega)]

theorem Uses.lift_zero (n : Nat) : Uses.lift n Uses.zero = Uses.zero := by
  funext j; simp only [Uses.lift, Uses.zero]
  split
  · rfl
  · split <;> rfl

theorem Uses.lift_add (n : Nat) (a b : Uses) :
    Uses.lift n (Uses.add a b) = Uses.add (Uses.lift n a) (Uses.lift n b) := by
  funext j; simp only [Uses.lift, Uses.add]
  split
  · rfl
  · split <;> rfl

theorem Uses.lift_join (n : Nat) (a b : Uses) :
    Uses.lift n (Uses.join a b) = Uses.join (Uses.lift n a) (Uses.lift n b) := by
  funext j; simp only [Uses.lift, Uses.join]
  split
  · rfl
  · split <;> rfl

theorem Uses.lift_tail (n : Nat) (π : Uses) :
    Uses.lift n (Uses.tail π) = Uses.tail (Uses.lift (n + 1) π) := by
  funext j
  simp only [Uses.lift, Uses.tail]
  by_cases h1 : j < n
  · rw [if_pos h1, if_pos (show j + 1 < n + 1 by omega)]
  · rw [if_neg h1, if_neg (show ¬ j + 1 < n + 1 by omega)]
    by_cases h2 : j = n
    · rw [if_pos h2, if_pos (show j + 1 = n + 1 by omega)]
    · rw [if_neg h2, if_neg (show ¬ j + 1 = n + 1 by omega)]; congr 1; omega

theorem Uses.lift_head (n : Nat) (π : Uses) : Uses.lift (n + 1) π 0 = π 0 := by
  simp only [Uses.lift]; rw [if_pos (show 0 < n + 1 by omega)]

theorem Uses.del_one_lt (n i : Nat) (q : Quant) (h : i < n) :
    Uses.del n (Uses.one i q) = Uses.one i q := by
  funext j
  simp only [Uses.del, Uses.one]
  by_cases h1 : j < n
  · rw [if_pos h1]
  · rw [if_neg h1, if_neg (show ¬ j + 1 = i by omega), if_neg (show ¬ j = i by omega)]

theorem Uses.del_one_eq (n : Nat) (q : Quant) :
    Uses.del n (Uses.one n q) = Uses.zero := by
  funext j
  simp only [Uses.del, Uses.one, Uses.zero]
  by_cases h1 : j < n
  · rw [if_pos h1, if_neg (show ¬ j = n by omega)]
  · rw [if_neg h1, if_neg (show ¬ j + 1 = n by omega)]

theorem Uses.del_zero (n : Nat) : Uses.del n Uses.zero = Uses.zero := by
  funext j; simp only [Uses.del, Uses.zero]; split <;> rfl

theorem Uses.del_add (n : Nat) (a b : Uses) :
    Uses.del n (Uses.add a b) = Uses.add (Uses.del n a) (Uses.del n b) := by
  funext j; simp only [Uses.del, Uses.add]; split <;> rfl

theorem Uses.del_join (n : Nat) (a b : Uses) :
    Uses.del n (Uses.join a b) = Uses.join (Uses.del n a) (Uses.del n b) := by
  funext j; simp only [Uses.del, Uses.join]; split <;> rfl

theorem Uses.del_tail (n : Nat) (π : Uses) :
    Uses.del n (Uses.tail π) = Uses.tail (Uses.del (n + 1) π) := by
  funext j
  simp only [Uses.del, Uses.tail]
  by_cases h1 : j < n
  · rw [if_pos h1, if_pos (show j + 1 < n + 1 by omega)]
  · rw [if_neg h1, if_neg (show ¬ j + 1 < n + 1 by omega)]

theorem Uses.del_head (n : Nat) (π : Uses) : Uses.del (n + 1) π 0 = π 0 := by
  simp only [Uses.del]; rw [if_pos (show 0 < n + 1 by omega)]

theorem Quant.add_eq_none : ∀ {a b : Quant}, Quant.add a b = .None → a = .None ∧ b = .None := by
  intro a b h; cases a <;> cases b <;> simp_all [Quant.add]

theorem Quant.join_eq_none : ∀ {a b : Quant}, Quant.join a b = .None → a = .None ∧ b = .None := by
  intro a b h; cases a <;> cases b <;> simp_all [Quant.join]

theorem Quant.dem_ne_many : ∀ {q' q : Quant}, q ≠ .Many → Quant.dem q' q ≠ .Many := by
  intro q' q h; cases q' <;> cases q <;> simp_all [Quant.dem]

-- shift and subst transport for the mat premises
theorem Insts.shift (h : Insts T ps T') (d : Nat) :
    Insts (T.shift d) (ps.map (Term.shift d)) (T'.shift d) := by
  induction h generalizing d with
  | nil => exact .nil
  | cons _ ih =>
    refine Insts.cons ?_
    rw [← Term.shift_subst0]
    exact ih d

theorem MatGoal.shift (h : MatGoal q' n B s tel G) :
    ∀ d, MatGoal q' n (B.shift (d + 1)) (s.shift d) (tel.shift d) (G.shift d) := by
  induction h with
  | zero =>
    intro d
    rw [Term.shift_subst0]
    exact .zero
  | @succ n B s Bf G qf F _ ih =>
    intro d
    show MatGoal q' (n + 1) _ _ (.All qf (F.shift d) (Bf.shift (d + 1))) _
    have h2 := ih (d + 1)
    rw [← Term.shift_shift B 1 (d + 1) (by omega)] at h2
    have e : Term.shift (d + 1) (.App (Term.shift 0 s) (.Var 0))
        = .App (Term.shift 0 (s.shift d)) (.Var 0) := by
      show Term.App _ _ = _
      rw [Term.shift_shift0]
      rfl
    rw [e] at h2
    exact MatGoal.succ h2

theorem Insts.subst (h : Insts T ps T') :
    ∀ (d : Nat) (w : Term),
    Insts (Term.subst d w T) (ps.map (Term.subst d w)) (Term.subst d w T') := by
  induction h with
  | nil => intro d w; exact .nil
  | cons _ ih =>
    intro d w
    refine Insts.cons ?_
    rw [← Term.subst_subst0]
    exact ih d w

theorem MatGoal.subst (h : MatGoal q' n B s tel G) :
    ∀ (d : Nat) (w : Term),
    MatGoal q' n (Term.subst (d + 1) (Term.shift 0 w) B) (Term.subst d w s)
      (Term.subst d w tel) (Term.subst d w G) := by
  induction h with
  | zero =>
    intro d w
    rw [Term.subst_subst0]
    exact .zero
  | @succ n B s Bf G qf F _ ih =>
    intro d w
    show MatGoal q' (n + 1) _ _
      (.All qf (Term.subst d w F) (Term.subst (d + 1) (Term.shift 0 w) Bf))
      (.All (Quant.mul qf q') (Term.subst d w F)
        (Term.subst (d + 1) (Term.shift 0 w) G))
    have h2 := ih (d + 1) (Term.shift 0 w)
    have eB : Term.subst (d + 1 + 1) (Term.shift 0 (Term.shift 0 w)) (Term.shift 1 B)
        = Term.shift 1 (Term.subst (d + 1) (Term.shift 0 w) B) := by
      rw [Term.shift_subst_lt B 1 (d + 1) (Term.shift 0 w) (by omega), Term.shift_shift0]
    rw [eB] at h2
    have e1 : Term.subst (d + 1) (Term.shift 0 w) (.App (Term.shift 0 s) (.Var 0))
        = .App (Term.shift 0 (Term.subst d w s)) (.Var 0) := by
      show Term.App _ _ = _
      rw [← Term.shift_subst_lt s 0 d w (Nat.zero_le d)]
      simp only [Term.subst]
      rw [if_neg (by omega : ¬ (0 : Nat) = d + 1), if_neg (by omega : ¬ d + 1 < 0)]
    rw [e1] at h2
    exact MatGoal.succ h2

-- a derivation measures nothing past its context
theorem Check.uses_ge {sp : List Term} (h : Check β Φ L sp q Γ t T π u) :
    ∀ i, Γ.length ≤ i → π i = .None := by
  induction h with
  | var hg =>
    intro i hi
    have := Ctx.get_lt hg
    simp only [Uses.one]; rw [if_neg (by omega)]
  | min _ _ iha ihb => intro i hi; simp only [Uses.add, iha i hi, ihb i hi]; rfl
  | lam _ _ _ _ ihf => intro i hi; exact ihf (i + 1) (by simp only [List.length_cons]; omega)
  | app _ _ ihf ihx => intro i hi; simp only [Uses.add, ihf i hi, ihx i hi]; rfl
  | appLam _ _ ih => exact ih
  | let_ _ _ _ _ ihv _ ihb =>
    intro i hi
    simp only [Uses.add, Uses.tail, ihv i hi, ihb (i + 1) (by simp only [List.length_cons]; omega)]
    rfl
  | rwt _ _ _ ihe _ ihf => intro i hi; simp only [Uses.add, ihe i hi, ihf i hi]; rfl
  | mat _ _ _ _ _ _ _ _ _ ihh ihm => intro i hi; simp only [Uses.join, ihh i hi, ihm i hi]; rfl
  | cnv _ _ ih => exact ih
  | _ => intro i _; rfl

theorem Check.closed_uses {sp : List Term} (h : Check β Φ L sp q [] t T π u) : π = Uses.zero := by
  funext i; exact h.uses_ge i (Nat.zero_le i)

-- ============================================================================
-- METATHEORY §D4 — weakening under the void equation: appending a context
-- at the outer end (nothing shifts), and inserting an entry at any depth
-- (Ins: the subject, type, measure and elaboration lift past it)
-- ============================================================================

theorem Ctx.δ_rel (R : Term → Term → Prop)
    (hR : ∀ d w x y, R x y → R (Term.subst d w x) (Term.subst d w y)) (Δ : Ctx) :
    ∀ (d : Nat) (x y : Term), R x y → R (Ctx.δ Δ d x) (Ctx.δ Δ d y) := by
  induction Δ with
  | nil => intro d x y h; exact h
  | cons b Δ ih =>
    intro d x y h
    obtain ⟨q, T, v⟩ := b
    cases v <;> simp only [Ctx.δ]
    · exact ih (d + 1) x y h
    · exact ih d _ _ (hR d _ x y h)

theorem Ctx.δ_red (hβ : Book.Closed β) (Δ : Ctx) (d : Nat) (h : Red β p x y) :
    Red β p (Ctx.δ Δ d x) (Ctx.δ Δ d y) :=
  Ctx.δ_rel (Red β p) (fun d w _ _ h => h.subst hβ d w) Δ d x y h

theorem Ctx.δ_conv (hβ : Book.Closed β) (Δ : Ctx) (d : Nat) (h : Conv β x y) :
    Conv β (Ctx.δ Δ d x) (Ctx.δ Δ d y) :=
  Ctx.δ_rel (Conv β) (fun d w _ _ h => Conv.subst hβ h (Conv.refl w) d) Δ d x y h

theorem CtxDead.append (hβ : Book.Closed β) (Δ : Ctx) (hd : CtxDead β Γ) :
    CtxDead β (Γ ++ Δ) := by
  obtain ⟨i, b, a, r, ps, hg, hq, hred, hemp⟩ := hd
  refine ⟨i, b, a, r, ps.map (Ctx.δ Δ Γ.rigid), ?_, hq, ?_, hemp⟩
  · rw [Ctx.get_append _ _ _ (Ctx.get_lt hg)]; exact hg
  · rw [Ctx.δ_append, Nat.zero_add]
    have := Ctx.δ_conv hβ Δ Γ.rigid hred
    rwa [Ctx.δ_apps, Ctx.δ_closed Δ Γ.rigid (.Adt a r) (by trivial)] at this

-- a policy that survives the context moves of weakening: its conversion
-- is closed under substitution and shift, its emptiness test under
-- appending and inserting entries (Pol.std is one, see Pol.std_weak)
structure Pol.Weak (Φ : Pol) : Prop where
  subst : ∀ d w x y, Φ.conv x y → Φ.conv (Term.subst d w x) (Term.subst d w y)
  shift : ∀ d x y, Φ.conv x y → Φ.conv (Term.shift d x) (Term.shift d y)
  append : ∀ Γ Δ, Φ.efq Γ → Φ.efq (Γ ++ Δ)
  ins : ∀ U n Γ Γ', Ins U n Γ Γ' → Φ.efq Γ → Φ.efq Γ'

theorem Check.weaken (hβ : Book.Closed β) (hΦ : Φ.Weak) {sp : List Term}
    (h : Check β Φ L sp q Γ t T π u) (Δ : Ctx) :
    Check β Φ (LHS.void β) sp q (Γ ++ Δ) t T π u := by
  induction h with
  | var hg => rw [← Ctx.get_append _ Δ _ (Ctx.get_lt hg)] at hg; exact .var hg
  | ref hk _ _ =>
    have hj := Book.defn_lt hk
    exact .ref hk (fun _ => Nat.le_of_lt hj) (fun _ he => absurd he (Nat.ne_of_lt hj))
  | refA hk h0 => exact .refA hk h0
  | adt hk => exact .adt hk
  | ctr hk hc hr => exact .ctr hk hc hr
  | typ _ ihg => exact .typ ihg
  | qnt => exact .qnt
  | qua => exact .qua
  | min _ _ iha ihb => exact .min iha ihb
  | all _ _ ihA ihB => exact .all ihA ihB
  | lam _ _ hle ihA ihf => exact .lam ihA ihf hle
  | app _ _ ihf ihx => exact .app ihf ihx
  | appLam ha _ ih =>
    exact .appLam (Term.Closed.mono _ _ _ ha (by simp only [List.length_append]; omega)) ih
  | let_ _ _ _ hle ihv ihA ihb => exact .let_ ihv ihA ihb hle
  | eql _ _ _ ihT iha ihb => exact .eql ihT iha ihb
  | rfl hc =>
    refine .rfl ?_
    rw [Ctx.δ_append, Ctx.δ_append]
    exact Ctx.δ_conv hβ Δ _ hc
  | rwt _ _ _ ihe ihP ihf => exact .rwt ihe ihP ihf
  | mat hk hc hr hlen hlive hins hgoal _ _ ihh ihm =>
    exact .mat hk hc hr hlen hlive hins hgoal ihh ihm
  | efq hk hlive hd => exact .efq hk hlive (hd.imp id (hΦ.append _ Δ))
  | cnv _ hc iht =>
    refine .cnv iht ?_
    rw [Ctx.δ_append, Ctx.δ_append]
    exact Ctx.δ_rel Φ.conv hΦ.subst Δ _ _ _ hc

theorem Ins.δ0 (h : Ins U n Γ Γ') :
    (∀ t, Ctx.δ Γ' 0 (Term.shift n t) = Ctx.δ Γ 0 t) ∨
    (∃ r, ∀ t, Ctx.δ Γ' 0 (Term.shift n t) = Term.shift r (Ctx.δ Γ 0 t)) := by
  rcases h.δ with e | ⟨r, e⟩
  · left; intro t; have := e 0 t; rwa [Nat.zero_add] at this
  · right; exact ⟨r, fun t => by have := e 0 t; rwa [Nat.zero_add, Nat.zero_add] at this⟩

theorem Ins.length_eq (h : Ins U n Γ Γ') : Γ'.length = Γ.length + 1 := by
  induction h with
  | zero => rfl
  | succ _ ih => simp only [List.length_cons, ih]

theorem CtxDead.ins (hβ : Book.Closed β) (hins : Ins U n Γ Γ') (hd : CtxDead β Γ) :
    CtxDead β Γ' := by
  obtain ⟨i, b, a, r, ps, hg, hq, hred, hemp⟩ := hd
  have key : ∃ i', Ctx.get Γ' i' = some (b.shiftAt n) := by
    by_cases hi : i < n
    · exact ⟨i, hins.get_lt hi hg⟩
    · exact ⟨i + 1, hins.get_ge (by omega) hg⟩
  obtain ⟨i', hg'⟩ := key
  rcases hins.δ0 with e | ⟨r', e⟩
  · exact ⟨i', _, a, r, ps, hg', hq, by
      show Conv β (Ctx.δ Γ' 0 (Term.shift n b.T)) _
      rw [e]; exact hred, hemp⟩
  · refine ⟨i', _, a, r, ps.map (Term.shift r'), hg', hq, ?_, hemp⟩
    show Conv β (Ctx.δ Γ' 0 (Term.shift n b.T)) _
    rw [e]
    have := hred.shift hβ r'
    rwa [Term.shift_apps] at this

theorem Pol.std_weak (hβ : Book.Closed β) : (Pol.std β).Weak :=
  ⟨fun d w x y (h : Le β x y) => h.subst hβ d w, fun d x y (h : Le β x y) => h.shift hβ d,
   fun _ Δ h => CtxDead.append hβ Δ h, fun _ _ _ _ hins h => CtxDead.ins hβ hins h⟩

theorem Check.ins (hβ : Book.Closed β) (hΦ : Φ.Weak) {sp : List Term}
    (h : Check β Φ L sp q Γ t T π u) :
    ∀ {n : Nat} {U : Bind} {Γ' : Ctx}, Ins U n Γ Γ' → ∀ sp',
    Check β Φ (LHS.void β) sp' q Γ' (Term.shift n t) (Term.shift n T) (Uses.lift n π)
      (Term.shift n u) := by
  induction h with
  | @var Γ i b L sp q hg =>
    intro n U Γ' hins sp'
    simp only [Term.shift, Term.shift_era]
    by_cases hi : i < n
    · rw [if_pos hi, Uses.lift_one_lt n i q hi]
      exact .var (hins.get_lt hi hg)
    · rw [if_neg hi, Uses.lift_one_ge n i q (by omega)]
      exact .var (hins.get_ge (by omega) hg)
  | ref hk _ _ =>
    intro n U Γ' hins sp'
    rw [Term.shift_closed _ 0 n (hβ.defn hk).1 (Nat.zero_le n), Uses.lift_zero,
      Term.shift_era]
    have hj := Book.defn_lt hk
    exact .ref hk (fun _ => Nat.le_of_lt hj) (fun _ he => absurd he (Nat.ne_of_lt hj))
  | refA hk h0 =>
    intro n U Γ' hins sp'
    rw [Term.shift_closed _ 0 n (hβ.adtd hk).1 (Nat.zero_le n), Uses.lift_zero,
      Term.shift_era]
    exact .refA hk h0
  | adt hk =>
    intro n U Γ' hins sp'
    rw [Term.shift_closed _ 0 n (hβ.adtd hk).1 (Nat.zero_le n), Uses.lift_zero,
      Term.shift_era]
    exact .adt hk
  | ctr hk hc hr =>
    intro n U Γ' hins sp'
    rw [Term.shift_closed _ 0 n
      (Term.retip_closed _ _ _ _ 0 ((hβ.adtd hk).2 _ _ hc)) (Nat.zero_le n),
      Uses.lift_zero, Term.shift_era]
    exact .ctr hk hc hr
  | typ _ ihg =>
    intro n U Γ' hins sp'
    rw [Uses.lift_zero, Term.shift_era]
    exact .typ (ihg hins [])
  | qnt => intro n U Γ' hins sp'; rw [Uses.lift_zero]; exact .qnt
  | qua => intro n U Γ' hins sp'; rw [Uses.lift_zero, Term.shift_era]; exact .qua
  | min _ _ iha ihb =>
    intro n U Γ' hins sp'
    rw [Uses.lift_add, Term.shift_era]
    exact .min (iha hins []) (ihb hins [])
  | all _ _ ihA ihB =>
    intro n U Γ' hins sp'
    rw [Uses.lift_zero, Term.shift_era]
    exact .all (ihA hins []) (ihB (Ins.succ hins) [])
  | lam _ _ hle ihA ihf =>
    intro n U Γ' hins sp'
    rw [Uses.lift_tail, Term.shift_era]
    refine .lam (ihA hins []) (ihf (Ins.succ hins) []) ?_
    rw [Uses.lift_head]; exact hle
  | app _ _ ihf ihx =>
    intro n U Γ' hins sp'
    rw [Uses.lift_add, Term.shift_subst0, Term.shift_era]
    exact .app (ihf hins _) (ihx hins [])
  | appLam ha _ ih =>
    intro n U Γ' hins sp'
    have := ih hins sp'
    rw [Term.shift_subst0] at this
    refine .appLam ?_ this
    rw [hins.length_eq]; exact Term.Closed.shift _ _ _ ha
  | let_ _ _ _ hle ihv ihA ihb =>
    intro n U Γ' hins sp'
    rw [Uses.lift_add, Uses.lift_tail, Term.shift_era]
    have hb' := ihb (Ins.succ hins) []
    rw [Term.shift_shift0] at hb'
    refine .let_ (ihv hins []) (ihA hins []) hb' ?_
    rw [Uses.lift_head]; exact hle
  | eql _ _ _ ihT iha ihb =>
    intro n U Γ' hins sp'
    rw [Uses.lift_zero, Term.shift_era]
    exact .eql (ihT hins []) (iha hins []) (ihb hins [])
  | rfl hc =>
    intro n U Γ' hins sp'
    rw [Uses.lift_zero, Term.shift_era]
    refine .rfl ?_
    rcases hins.δ0 with e | ⟨r, e⟩
    · rw [e, e]; exact hc
    · rw [e, e]; exact hc.shift hβ r
  | rwt _ _ _ ihe ihP ihf =>
    intro n U Γ' hins sp'
    rw [Uses.lift_add, Term.shift_era]
    have hP' := ihP hins []
    rw [Term.shift_jmotive] at hP'
    exact .rwt (ihe hins []) hP' (ihf hins [])
  | mat hk hc hr hlen hlive hins hgoal _ _ ihh ihm =>
    intro n U Γ' hI sp'
    rw [Uses.lift_join, Term.shift_era]
    simp only [Term.shift, Term.shift_apps]
    have hi' := hins.shift n
    rw [Term.shift_closed _ 0 n ((hβ.adtd hk).2 _ _ hc) (Nat.zero_le n)] at hi'
    have hg' := hgoal.shift n
    rw [Term.shift_apps] at hg'
    refine Check.mat hk hc hr (by simp [hlen]) hlive hi' hg' (ihh hI []) ?_
    have := ihm hI []
    simp only [Term.shift, Term.shift_apps] at this
    exact this
  | efq hk hlive hd =>
    intro n U Γ' hins sp'
    rw [Uses.lift_zero, Term.shift_era]
    simp only [Term.shift, Term.shift_apps]
    exact .efq hk hlive (hd.imp id (hΦ.ins _ _ _ _ hins))
  | cnv _ hc iht =>
    intro n U Γ' hins sp'
    refine .cnv (iht hins sp') ?_
    rcases hins.δ0 with e | ⟨r, e⟩
    · rw [e, e]; exact hc
    · rw [e, e]; exact hΦ.shift r _ _ hc

-- a closed judgment replays in any context, its type shifted past it
theorem Check.weaken_closed (hβ : Book.Closed β) (hΦ : Φ.Weak) {sp : List Term}
    (h : Check β Φ L sp q [] t T π u) :
    ∀ (Δ : Ctx) (sp' : List Term),
    Check β Φ (LHS.void β) sp' q Δ t (Term.shiftN Δ.length T) π u := by
  have ht := h.closed
  have hu := h.closed_era
  have hπ := h.closed_uses
  intro Δ
  induction Δ with
  | nil => intro sp'; exact h.void_sp sp'
  | cons g Δ ih =>
    intro sp'
    have := (ih []).ins hβ hΦ (Ins.zero (U := g)) sp'
    rw [Term.shift_closed t 0 0 ht (Nat.le_refl 0), Term.shift_closed u 0 0 hu (Nat.le_refl 0),
      hπ, Uses.lift_zero] at this
    rw [hπ]
    exact this

-- ============================================================================
-- METATHEORY §D5 — the closed substitution at the last position of the
-- context: a var of index Γ.length becomes w (its dead or live closed
-- derivation replayed in the substituted context), every other index is
-- renumbered, and the measure drops the slot
-- ============================================================================

theorem Term.Closed.subst (hw : Term.Closed 0 w) : ∀ (t : Term) (n d : Nat), d ≤ n →
    t.Closed (n + 1) → (Term.subst d w t).Closed n := by
  intro t
  induction t <;> intro n d hd hc <;> simp only [Term.Closed, Term.subst] at *
  case Var =>
    split
    · exact Term.Closed.mono w 0 n hw (Nat.zero_le n)
    · split <;> simp only [Term.Closed] <;> omega
  case Typ ih => exact ih n d hd hc
  case Min iha ihb => exact ⟨iha n d hd hc.1, ihb n d hd hc.2⟩
  case All ihA ihB =>
    rw [Term.shift_closed w 0 0 hw (Nat.le_refl 0)]
    exact ⟨ihA n d hd hc.1, ihB (n + 1) (d + 1) (by omega) hc.2⟩
  case Lam ihf =>
    rw [Term.shift_closed w 0 0 hw (Nat.le_refl 0)]
    exact ihf (n + 1) (d + 1) (by omega) hc
  case App ihf iha => exact ⟨ihf n d hd hc.1, iha n d hd hc.2⟩
  case Mat ihh ihm => exact ⟨ihh n d hd hc.1, ihm n d hd hc.2⟩
  case Eql iha ihb ihT => exact ⟨iha n d hd hc.1, ihb n d hd hc.2.1, ihT n d hd hc.2.2⟩
  case Rwt ihe ihP ihf => exact ⟨ihe n d hd hc.1, ihP n d hd hc.2.1, ihf n d hd hc.2.2⟩
  case Let ihv ihb =>
    rw [Term.shift_closed w 0 0 hw (Nat.le_refl 0)]
    exact ⟨ihv n d hd hc.1, ihb (n + 1) (d + 1) (by omega) hc.2⟩

theorem Term.subst_shift0_closed (hw : Term.Closed 0 w) (n : Nat) (T : Term) :
    Term.subst (n + 1) w (Term.shift 0 T) = Term.shift 0 (Term.subst n w T) := by
  rw [Term.shift_subst_lt T 0 n w (Nat.zero_le n), Term.shift_closed w 0 0 hw (Nat.le_refl 0)]

theorem Ctx.δ_substLast0 (hw : Term.Closed 0 w) (Γ : Ctx) (t : Term) :
    Ctx.δ (Ctx.substLast w Γ) 0 (Term.subst Γ.length w t)
      = Term.subst Γ.rigid w (Ctx.δ Γ 0 t) := by
  have := Ctx.δ_substLast hw Γ 0 t
  rwa [Nat.zero_add, Nat.zero_add] at this

-- a comparison of let-expanded terms survives the substitution
theorem Ctx.δ_last (hw : Term.Closed 0 w) (hv : b0.v = none ∨ b0.v = some w)
    (R : Term → Term → Prop) (hR : ∀ d x y, R x y → R (Term.subst d w x) (Term.subst d w y))
    (Γ : Ctx) (a b : Term)
    (h : R (Ctx.δ (Γ ++ [b0]) 0 a) (Ctx.δ (Γ ++ [b0]) 0 b)) :
    R (Ctx.δ (Ctx.substLast w Γ) 0 (Term.subst Γ.length w a))
      (Ctx.δ (Ctx.substLast w Γ) 0 (Term.subst Γ.length w b)) := by
  rw [Ctx.δ_substLast0 hw, Ctx.δ_substLast0 hw]
  rcases hv with hv | hv
  · rw [Ctx.δ_append_none hv, Ctx.δ_append_none hv] at h; exact hR _ _ _ h
  · rw [Ctx.δ_append_some hw hv, Ctx.δ_append_some hw hv] at h; exact h

theorem CtxDead.substLast (hβ : Book.Closed β) (hw : Term.Closed 0 w)
    (hv : b0.v = none ∨ b0.v = some w)
    (hdead : b0.q ≠ .None → ∀ m a r ps,
      Conv β (Term.shiftN m b0.T) (Term.apps (.Adt a r) ps) → ¬ Book.empty β a r)
    (Γ : Ctx) (hd : CtxDead β (Γ ++ [b0])) : CtxDead β (Ctx.substLast w Γ) := by
  obtain ⟨i, b, a, r, ps, hg, hq, hred, hemp⟩ := hd
  have hi := Ctx.get_lt hg
  simp only [List.length_append, List.length_singleton] at hi
  by_cases hin : i < Γ.length
  · rw [Ctx.get_append _ _ _ hin] at hg
    have hg' := Ctx.get_substLast hw Γ i b hg
    rcases hv with hv | hv
    · refine ⟨i, _, a, r, ps.map (Term.subst Γ.rigid w), hg', hq, ?_, hemp⟩
      show Conv β (Ctx.δ (Ctx.substLast w Γ) 0 (Term.subst Γ.length w b.T)) _
      rw [Ctx.δ_substLast0 hw, ← Term.subst_apps_closed Γ.rigid w (b := .Adt a r) (by trivial),
        Ctx.δ_append_none hv] at *
      exact Conv.subst hβ hred (Conv.refl _) _
    · refine ⟨i, _, a, r, ps, hg', hq, ?_, hemp⟩
      show Conv β (Ctx.δ (Ctx.substLast w Γ) 0 (Term.subst Γ.length w b.T)) _
      rw [Ctx.δ_substLast0 hw, Ctx.δ_append_some hw hv] at *
      exact hred
  · exfalso
    have hi' : i = Γ.length := by omega
    subst hi'
    rw [Ctx.get_append_last] at hg
    cases hg
    rw [Bind.shiftN_q] at hq
    rw [Bind.shiftN_T, Ctx.δ_append, Nat.zero_add,
      Ctx.δ_shiftN Γ 0 _ _ (by simp only [Nat.zero_add]; omega),
      show Γ.length + 1 - Γ.length + Γ.rigid = Γ.rigid + 1 by omega] at hred
    rcases hv with hv | hv <;> simp only [Ctx.δ, hv] at hred
    · exact hdead hq _ a r ps hred hemp
    · rw [Term.subst_shiftN] at hred
      exact hdead hq _ a r ps hred hemp

theorem Check.none_at {sp : List Term} (h : Check β Φ L sp .None Γ t T π u) (i : Nat) :
    π i = .None := by
  rw [h.none_uses _root_.rfl]; rfl

theorem Check.subst (hβ : Book.Closed β) (hΦ : Φ.Weak) {sp : List Term}
    (h : Check β Φ L sp q Γb t T π u)
    (hw : Term.Closed 0 w) (huw : Term.Closed 0 uw) (hv : b0.v = none ∨ b0.v = some w)
    (h0 : Check β Φ (LHS.void β) [] .None [] w b0.T Uses.zero .Qnt)
    (hefq : ∀ Γ, Φ.efq (Γ ++ [b0]) → Φ.efq (Ctx.substLast w Γ)) :
    ∀ (Γ : Ctx), Γb = Γ ++ [b0] → q ≠ .Many →
    (π Γ.length ≠ .None → ∃ πw, Check β Φ (LHS.void β) [] .Lone [] w b0.T πw uw) →
    Check β Φ (LHS.void β) sp q (Ctx.substLast w Γ) (Term.subst Γ.length w t)
      (Term.subst Γ.length w T) (Uses.del Γ.length π) (Term.subst Γ.length uw u) := by
  have hw0 : Term.shift 0 w = w := Term.shift_closed w 0 0 hw (Nat.le_refl 0)
  have huw0 : Term.shift 0 uw = uw := Term.shift_closed uw 0 0 huw (Nat.le_refl 0)
  induction h with
  | @var Γb i b L sp q hg =>
    intro Γ hΓ hq h1
    subst hΓ
    have hi := Ctx.get_lt hg
    simp only [List.length_append, List.length_singleton] at hi
    by_cases hin : i < Γ.length
    · rw [Ctx.get_append _ _ _ hin] at hg
      have e1 : Term.subst Γ.length w (.Var i) = .Var i := by
        simp [Term.subst, show ¬ i = Γ.length by omega, show ¬ Γ.length < i by omega]
      have e2 : Term.subst Γ.length uw (.Var i) = .Var i := by
        simp [Term.subst, show ¬ i = Γ.length by omega, show ¬ Γ.length < i by omega]
      rw [e1, Term.subst_era, e2, Uses.del_one_lt _ _ _ hin]
      exact .var (Ctx.get_substLast hw Γ i b hg)
    · have hi' : i = Γ.length := by omega
      subst hi'
      rw [Ctx.get_append_last] at hg
      cases hg
      have e1 : Term.subst Γ.length w (.Var Γ.length) = w := by simp [Term.subst]
      have e2 : Term.subst Γ.length uw (.Var Γ.length) = uw := by simp [Term.subst]
      rw [e1, Term.subst_era, e2, Uses.del_one_eq, Bind.shiftN_T, Term.subst_shiftN]
      cases q with
      | None =>
        have := h0.weaken_closed hβ hΦ (Ctx.substLast w Γ) sp
        rwa [Ctx.substLast_length] at this
      | Lone =>
        obtain ⟨πw, hw1⟩ := h1 (by simp [Uses.one])
        have := hw1.weaken_closed hβ hΦ (Ctx.substLast w Γ) sp
        rwa [Ctx.substLast_length, hw1.closed_uses] at this
      | Many => exact absurd _root_.rfl hq
  | ref hk _ _ =>
    intro Γ hΓ hq h1
    rw [Term.subst_closed _ 0 _ w (hβ.defn hk).1 (Nat.zero_le _), Uses.del_zero, Term.subst_era]
    have hj := Book.defn_lt hk
    exact .ref hk (fun _ => Nat.le_of_lt hj) (fun _ he => absurd he (Nat.ne_of_lt hj))
  | refA hk h0' =>
    intro Γ hΓ hq h1
    rw [Term.subst_closed _ 0 _ w (hβ.adtd hk).1 (Nat.zero_le _), Uses.del_zero, Term.subst_era]
    exact .refA hk h0'
  | adt hk =>
    intro Γ hΓ hq h1
    rw [Term.subst_closed _ 0 _ w (hβ.adtd hk).1 (Nat.zero_le _), Uses.del_zero, Term.subst_era]
    exact .adt hk
  | ctr hk hc hr =>
    intro Γ hΓ hq h1
    rw [Term.subst_closed _ 0 _ w (Term.retip_closed _ _ _ _ 0 ((hβ.adtd hk).2 _ _ hc))
      (Nat.zero_le _), Uses.del_zero, Term.subst_era]
    exact .ctr hk hc hr
  | typ hg ihg =>
    intro Γ hΓ hq h1
    rw [Uses.del_zero, Term.subst_era]
    exact .typ (ihg Γ hΓ (by simp) (fun hne => absurd (hg.none_at _) hne))
  | qnt => intro Γ hΓ hq h1; rw [Uses.del_zero]; exact .qnt
  | qua => intro Γ hΓ hq h1; rw [Uses.del_zero, Term.subst_era]; exact .qua
  | min _ _ iha ihb =>
    intro Γ hΓ hq h1
    rw [Uses.del_add, Term.subst_era]
    exact .min (iha Γ hΓ hq (fun hne => h1 (fun he => hne (Quant.add_eq_none he).1)))
      (ihb Γ hΓ hq (fun hne => h1 (fun he => hne (Quant.add_eq_none he).2)))
  | all hA hB ihA ihB =>
    intro Γ hΓ hq h1
    subst hΓ
    rw [Uses.del_zero, Term.subst_era]
    simp only [Term.subst, hw0]
    exact .all (ihA Γ _root_.rfl (by simp) (fun hne => absurd (hA.none_at _) hne))
      (ihB (⟨_, _, none⟩ :: Γ) _root_.rfl (by simp) (fun hne => absurd (hB.none_at _) hne))
  | lam hA _ hle ihA ihf =>
    intro Γ hΓ hq h1
    subst hΓ
    rw [Uses.del_tail, Term.subst_era]
    simp only [Term.subst, hw0, huw0]
    refine .lam (ihA Γ _root_.rfl (by simp) (fun hne => absurd (hA.none_at _) hne))
      (ihf (⟨_, _, none⟩ :: Γ) _root_.rfl hq h1) ?_
    rw [Uses.del_head]; exact hle
  | app _ _ ihf ihx =>
    intro Γ hΓ hq h1
    subst hΓ
    rw [Uses.del_add, Term.subst_subst0, hw0, Term.subst_era]
    have hf' := ihf Γ _root_.rfl hq (fun hne => h1 (fun he => hne (Quant.add_eq_none he).1))
    simp only [Term.subst, hw0] at hf'
    exact .app (hf'.sp _)
      (ihx Γ _root_.rfl (Quant.dem_ne_many hq) (fun hne => h1 (fun he => hne (Quant.add_eq_none he).2)))
  | appLam ha _ ih =>
    intro Γ hΓ hq h1
    subst hΓ
    have := ih Γ _root_.rfl hq h1
    rw [Term.subst_subst0, hw0] at this
    simp only [Term.subst, hw0]
    refine .appLam ?_ this
    rw [Ctx.substLast_length]
    simp only [List.length_append, List.length_singleton] at ha
    exact Term.Closed.subst hw _ _ _ (Nat.le_refl _) ha
  | let_ _ hA _ hle ihv ihA ihb =>
    intro Γ hΓ hq h1
    subst hΓ
    rw [Uses.del_add, Uses.del_tail, Term.subst_era]
    simp only [Term.subst, hw0, huw0]
    have hb' := ihb (⟨_, _, some _⟩ :: Γ) _root_.rfl hq
      (fun hne => h1 (fun he => hne (Quant.add_eq_none he).2))
    simp only [List.length_cons, Ctx.substLast, Bind.substAt, Option.map_some,
      Term.subst_shift0_closed hw] at hb'
    refine .let_ (ihv Γ _root_.rfl (Quant.dem_ne_many hq)
      (fun hne => h1 (fun he => hne (Quant.add_eq_none he).1)))
      (ihA Γ _root_.rfl (by simp) (fun hne => absurd (hA.none_at _) hne)) hb' ?_
    rw [Uses.del_head]; exact hle
  | eql hT ha hb ihT iha ihb =>
    intro Γ hΓ hq h1
    rw [Uses.del_zero, Term.subst_era]
    exact .eql (ihT Γ hΓ (by simp) (fun hne => absurd (hT.none_at _) hne))
      (iha Γ hΓ (by simp) (fun hne => absurd (ha.none_at _) hne))
      (ihb Γ hΓ (by simp) (fun hne => absurd (hb.none_at _) hne))
  | rfl hc =>
    intro Γ hΓ hq h1
    subst hΓ
    rw [Uses.del_zero, Term.subst_era]
    exact .rfl (Ctx.δ_last hw hv (Conv β) (fun d x y h => Conv.subst hβ h (Conv.refl w) d) Γ _ _ hc)
  | rwt _ hP _ ihe ihP ihf =>
    intro Γ hΓ hq h1
    rw [Uses.del_add, Term.subst_era]
    have hP' := ihP Γ hΓ (by simp) (fun hne => absurd (hP.none_at _) hne)
    rw [Term.subst_jmotive] at hP'
    exact .rwt (ihe Γ hΓ hq (fun hne => h1 (fun he => hne (Quant.add_eq_none he).1))) hP'
      (ihf Γ hΓ hq (fun hne => h1 (fun he => hne (Quant.add_eq_none he).2)))
  | mat hk hc hr hlen hlive hins hgoal _ _ ihh ihm =>
    intro Γ hΓ hq h1
    rw [Uses.del_join, Term.subst_era]
    simp only [Term.subst, Term.subst_apps, hw0]
    have hi' := hins.subst Γ.length w
    rw [Term.subst_closed _ 0 _ w ((hβ.adtd hk).2 _ _ hc) (Nat.zero_le _)] at hi'
    have hg' := hgoal.subst Γ.length w
    simp only [Term.subst_apps, Term.subst, hw0] at hg'
    refine Check.mat hk hc hr (by simp [hlen]) hlive hi' hg'
      (ihh Γ hΓ hq (fun hne => h1 (fun he => hne (Quant.join_eq_none he).1))) ?_
    have := ihm Γ hΓ hq (fun hne => h1 (fun he => hne (Quant.join_eq_none he).2))
    simp only [Term.subst, Term.subst_apps, hw0] at this
    exact this
  | efq hk hlive hd =>
    intro Γ hΓ hq h1
    subst hΓ
    rw [Uses.del_zero, Term.subst_era]
    simp only [Term.subst, Term.subst_apps, hw0]
    exact .efq hk hlive (hd.imp id (hefq Γ))
  | cnv _ hc iht =>
    intro Γ hΓ hq h1
    subst hΓ
    exact .cnv (iht Γ _root_.rfl hq h1)
      (Ctx.δ_last hw hv Φ.conv (fun d x y h => hΦ.subst d w x y h) Γ _ _ hc)

-- the standard policy: the substituted binder must not be the live emptied
-- binding that justified an Efq (hdead), as no derivation survives that
theorem Check.subst_std (hβ : Book.Closed β) {sp : List Term}
    (h : Check β (Pol.std β) L sp q (Γ ++ [b0]) t T π u)
    (hq : q ≠ .Many) (hw : Term.Closed 0 w) (huw : Term.Closed 0 uw)
    (hv : b0.v = none ∨ b0.v = some w)
    (h0 : Check β (Pol.std β) (LHS.void β) [] .None [] w b0.T Uses.zero .Qnt)
    (h1 : π Γ.length ≠ .None →
      ∃ πw, Check β (Pol.std β) (LHS.void β) [] .Lone [] w b0.T πw uw)
    (hdead : b0.q ≠ .None → ∀ m a r ps,
      Conv β (Term.shiftN m b0.T) (Term.apps (.Adt a r) ps) → ¬ Book.empty β a r) :
    Check β (Pol.std β) (LHS.void β) sp q (Ctx.substLast w Γ) (Term.subst Γ.length w t)
      (Term.subst Γ.length w T) (Uses.del Γ.length π) (Term.subst Γ.length uw u) :=
  Check.subst hβ (Pol.std_weak hβ) h hw huw hv h0 (CtxDead.substLast hβ hw hv hdead) Γ
    _root_.rfl hq h1


-- ============================================================================
-- METATHEORY §E — generation: every derivation of a given subject shape
-- factors through its rule, modulo the conversion accumulated by cnv. The
-- inversions hold for any policy whose conversion is a preorder; the
-- standard policy is one (C's Le.refl / Le.trans).
-- ============================================================================

structure Pol.Pre (Φ : Pol) : Prop where
  refl  : ∀ a, Φ.conv a a
  trans : ∀ {a b c}, Φ.conv a b → Φ.conv b c → Φ.conv a c

theorem Pol.std_pre (hβ : Book.Closed β) : Pol.Pre (Pol.std β) :=
  ⟨fun a => Le.refl a, fun h1 h2 => Le.trans hβ h1 h2⟩

theorem Check.var_inv (hΦ : Pol.Pre Φ) {sp : List Term} (h : Check β Φ L sp q Γ (.Var i) T π u) :
    ∃ b, Ctx.get Γ i = some b ∧ Φ.conv (Ctx.δ Γ 0 b.T) (Ctx.δ Γ 0 T) ∧
      π = Uses.one i q ∧ u = Term.era q (.Var i) := by
  generalize he : Term.Var i = t0 at h
  induction h <;> try exact Term.noConfusion he
  case var hg => cases he; exact ⟨_, hg, hΦ.refl _, _root_.rfl, _root_.rfl⟩
  case cnv _ hc ih =>
    obtain ⟨b, hg, hcv, hπ, hu⟩ := ih he
    exact ⟨b, hg, hΦ.trans hcv hc, hπ, hu⟩

theorem Check.ref_inv (hΦ : Pol.Pre Φ) {sp : List Term} (h : Check β Φ L sp q Γ (.Ref j) T π u) :
    (∃ d, Book.defn β j = some d ∧
      (q ≠ .None → j ≤ L.k) ∧
      (q ≠ .None → j = L.k →
        SpineLt β L.qs 0 (L.cols.map (Ctx.δ Γ 0)) (sp.map (Ctx.δ Γ 0))) ∧
      Φ.conv (Ctx.δ Γ 0 d.ty) (Ctx.δ Γ 0 T) ∧ π = Uses.zero ∧ u = Term.era q (.Ref j)) ∨
    (∃ A, Book.adt β j = some A ∧ A.pn = 0 ∧
      Φ.conv (Ctx.δ Γ 0 A.sig) (Ctx.δ Γ 0 T) ∧ π = Uses.zero ∧ u = Term.era q (.Ref j)) := by
  generalize he : Term.Ref j = t0 at h
  induction h <;> try exact Term.noConfusion he
  case ref hk hw hd => cases he; exact .inl ⟨_, hk, hw, hd, hΦ.refl _, _root_.rfl, _root_.rfl⟩
  case refA hk h0 => cases he; exact .inr ⟨_, hk, h0, hΦ.refl _, _root_.rfl, _root_.rfl⟩
  case cnv _ hc ih =>
    rcases ih he with ⟨d, hk, hw, hd, hcv, hπ, hu⟩ | ⟨A, hk, h0, hcv, hπ, hu⟩
    · exact .inl ⟨d, hk, hw, hd, hΦ.trans hcv hc, hπ, hu⟩
    · exact .inr ⟨A, hk, h0, hΦ.trans hcv hc, hπ, hu⟩

theorem Check.adt_inv (hΦ : Pol.Pre Φ) {sp : List Term} (h : Check β Φ L sp q Γ (.Adt a r) T π u) :
    ∃ A, Book.adt β a = some A ∧ Φ.conv (Ctx.δ Γ 0 A.sig) (Ctx.δ Γ 0 T) ∧
      π = Uses.zero ∧ u = Term.era q (.Adt a r) := by
  generalize he : Term.Adt a r = t0 at h
  induction h <;> try exact Term.noConfusion he
  case adt hk => cases he; exact ⟨_, hk, hΦ.refl _, _root_.rfl, _root_.rfl⟩
  case cnv _ hc ih =>
    obtain ⟨A, hk, hcv, hπ, hu⟩ := ih he
    exact ⟨A, hk, hΦ.trans hcv hc, hπ, hu⟩

theorem Check.ctr_inv (hΦ : Pol.Pre Φ) {sp : List Term} (h : Check β Φ L sp q Γ (.Ctr a c) T π u) :
    ∃ A C r, Book.adt β a = some A ∧ AdtD.ctr A c = some C ∧ c ∉ r ∧
      Φ.conv (Ctx.δ Γ 0 (Term.retip r A.pn (A.pn + C.fn) C.ty)) (Ctx.δ Γ 0 T) ∧
      π = Uses.zero ∧ u = Term.era q (.Ctr a c) := by
  generalize he : Term.Ctr a c = t0 at h
  induction h <;> try exact Term.noConfusion he
  case ctr hk hc hr => cases he; exact ⟨_, _, _, hk, hc, hr, hΦ.refl _, _root_.rfl, _root_.rfl⟩
  case cnv _ hc ih =>
    obtain ⟨A, C, r, hk, hc0, hr, hcv, hπ, hu⟩ := ih he
    exact ⟨A, C, r, hk, hc0, hr, hΦ.trans hcv hc, hπ, hu⟩

theorem Check.typ_inv (hΦ : Pol.Pre Φ) {sp : List Term} (h : Check β Φ L sp q Γ (.Typ g) T π u) :
    ∃ πg, Check β Φ L [] .None Γ g .Qnt πg .Qnt ∧
      Φ.conv (Ctx.δ Γ 0 (.Typ (.Qua .Lone))) (Ctx.δ Γ 0 T) ∧
      π = Uses.zero ∧ u = Term.era q (.Typ .Qnt) := by
  generalize he : Term.Typ g = t0 at h
  induction h <;> try exact Term.noConfusion he
  case typ hg _ => cases he; exact ⟨_, hg, hΦ.refl _, _root_.rfl, _root_.rfl⟩
  case cnv _ hc ih =>
    obtain ⟨πg, hg, hcv, hπ, hu⟩ := ih he
    exact ⟨πg, hg, hΦ.trans hcv hc, hπ, hu⟩

theorem Check.qnt_inv (hΦ : Pol.Pre Φ) {sp : List Term} (h : Check β Φ L sp q Γ .Qnt T π u) :
    Φ.conv (Ctx.δ Γ 0 (.Typ (.Qua .Lone))) (Ctx.δ Γ 0 T) ∧ π = Uses.zero ∧ u = .Qnt := by
  generalize he : Term.Qnt = t0 at h
  induction h <;> try exact Term.noConfusion he
  case qnt => exact ⟨hΦ.refl _, _root_.rfl, _root_.rfl⟩
  case cnv _ hc ih =>
    obtain ⟨hcv, hπ, hu⟩ := ih he
    exact ⟨hΦ.trans hcv hc, hπ, hu⟩

theorem Check.qua_inv (hΦ : Pol.Pre Φ) {sp : List Term} (h : Check β Φ L sp q Γ (.Qua q') T π u) :
    Φ.conv (Ctx.δ Γ 0 .Qnt) (Ctx.δ Γ 0 T) ∧ π = Uses.zero ∧ u = Term.era q (.Qua q') := by
  generalize he : Term.Qua q' = t0 at h
  induction h <;> try exact Term.noConfusion he
  case qua => cases he; exact ⟨hΦ.refl _, _root_.rfl, _root_.rfl⟩
  case cnv _ hc ih =>
    obtain ⟨hcv, hπ, hu⟩ := ih he
    exact ⟨hΦ.trans hcv hc, hπ, hu⟩

theorem Check.min_inv (hΦ : Pol.Pre Φ) {sp : List Term} (h : Check β Φ L sp q Γ (.Min a b) T π u) :
    ∃ πa ua πb ub, Check β Φ L [] q Γ a .Qnt πa ua ∧ Check β Φ L [] q Γ b .Qnt πb ub ∧
      Φ.conv (Ctx.δ Γ 0 .Qnt) (Ctx.δ Γ 0 T) ∧
      π = Uses.add πa πb ∧ u = Term.era q (.Min ua ub) := by
  generalize he : Term.Min a b = t0 at h
  induction h <;> try exact Term.noConfusion he
  case min ha hb _ _ => cases he; exact ⟨_, _, _, _, ha, hb, hΦ.refl _, _root_.rfl, _root_.rfl⟩
  case cnv _ hc ih =>
    obtain ⟨πa, ua, πb, ub, ha, hb, hcv, hπ, hu⟩ := ih he
    exact ⟨πa, ua, πb, ub, ha, hb, hΦ.trans hcv hc, hπ, hu⟩

theorem Check.all_inv (hΦ : Pol.Pre Φ) {sp : List Term} (h : Check β Φ L sp q Γ (.All q' A B) T π u) :
    ∃ πA πB, Check β Φ L [] .None Γ A (.Typ (.Qua q')) πA .Qnt ∧
      Check β Φ L.shift [] .None (⟨q', A, none⟩ :: Γ) B (.Typ (.Qua .Lone)) πB .Qnt ∧
      Φ.conv (Ctx.δ Γ 0 (.Typ (.Qua .Lone))) (Ctx.δ Γ 0 T) ∧
      π = Uses.zero ∧ u = Term.era q (.All q' .Qnt .Qnt) := by
  generalize he : Term.All q' A B = t0 at h
  induction h <;> try exact Term.noConfusion he
  case all hA hB _ _ => cases he; exact ⟨_, _, hA, hB, hΦ.refl _, _root_.rfl, _root_.rfl⟩
  case cnv _ hc ih =>
    obtain ⟨πA, πB, hA, hB, hcv, hπ, hu⟩ := ih he
    exact ⟨πA, πB, hA, hB, hΦ.trans hcv hc, hπ, hu⟩

theorem Check.lam_inv (hΦ : Pol.Pre Φ) {sp : List Term} (h : Check β Φ L sp q Γ (.Lam f) T π u) :
    ∃ q' A B πA π' uf, Check β Φ L [] .None Γ A (.Typ (.Qua q')) πA .Qnt ∧
      Check β Φ L.lam [] q (⟨q', A, none⟩ :: Γ) f B π' uf ∧ Quant.le (π' 0) q' ∧
      Φ.conv (Ctx.δ Γ 0 (.All q' A B)) (Ctx.δ Γ 0 T) ∧
      π = Uses.tail π' ∧ u = Term.era q (.Lam uf) := by
  generalize he : Term.Lam f = t0 at h
  induction h <;> try exact Term.noConfusion he
  case lam hA hf hle _ _ =>
    cases he; exact ⟨_, _, _, _, _, _, hA, hf, hle, hΦ.refl _, _root_.rfl, _root_.rfl⟩
  case cnv _ hc ih =>
    obtain ⟨q', A, B, πA, π', uf, hA, hf, hle, hcv, hπ, hu⟩ := ih he
    exact ⟨q', A, B, πA, π', uf, hA, hf, hle, hΦ.trans hcv hc, hπ, hu⟩

theorem Check.app_inv (hΦ : Pol.Pre Φ) {sp : List Term} (h : Check β Φ L sp q Γ (.App f x) T π u) :
    (∃ q' A B πf uf πx ux, Check β Φ L (x :: sp) q Γ f (.All q' A B) πf uf ∧
      Check β Φ L [] (Quant.dem q' q) Γ x A πx ux ∧
      Φ.conv (Ctx.δ Γ 0 (Term.subst 0 x B)) (Ctx.δ Γ 0 T) ∧
      π = Uses.add πf πx ∧ u = Term.era q (.App uf ux)) ∨
    (∃ g T0, f = .Lam g ∧ Term.Closed Γ.length x ∧
      Check β Φ L sp q Γ (Term.subst 0 x g) T0 π u ∧
      Φ.conv (Ctx.δ Γ 0 T0) (Ctx.δ Γ 0 T)) := by
  generalize he : Term.App f x = t0 at h
  induction h <;> try exact Term.noConfusion he
  case app hf hx _ _ =>
    cases he; exact .inl ⟨_, _, _, _, _, _, _, hf, hx, hΦ.refl _, _root_.rfl, _root_.rfl⟩
  case appLam ha hb _ => cases he; exact .inr ⟨_, _, _root_.rfl, ha, hb, hΦ.refl _⟩
  case cnv _ hc ih =>
    rcases ih he with ⟨q', A, B, πf, uf, πx, ux, hf, hx, hcv, hπ, hu⟩ | ⟨g, T0, hg, ha, hb, hcv⟩
    · exact .inl ⟨q', A, B, πf, uf, πx, ux, hf, hx, hΦ.trans hcv hc, hπ, hu⟩
    · exact .inr ⟨g, T0, hg, ha, hb, hΦ.trans hcv hc⟩

theorem Check.let_inv (hΦ : Pol.Pre Φ) {sp : List Term} (h : Check β Φ L sp q Γ (.Let qb v b) T π u) :
    ∃ A T0 πv uv πA π' ub, Check β Φ L [] (Quant.dem qb q) Γ v A πv uv ∧
      Check β Φ L [] .None Γ A (.Typ (.Qua qb)) πA .Qnt ∧
      Check β Φ L.shift [] q (⟨qb, A, some v⟩ :: Γ) b (Term.shift 0 T0) π' ub ∧
      Quant.le (π' 0) qb ∧ Φ.conv (Ctx.δ Γ 0 T0) (Ctx.δ Γ 0 T) ∧
      π = Uses.add πv (Uses.tail π') ∧ u = Term.era q (.Let qb uv ub) := by
  generalize he : Term.Let qb v b = t0 at h
  induction h <;> try exact Term.noConfusion he
  case let_ hv hA hb hle _ _ _ =>
    cases he; exact ⟨_, _, _, _, _, _, _, hv, hA, hb, hle, hΦ.refl _, _root_.rfl, _root_.rfl⟩
  case cnv _ hc ih =>
    obtain ⟨A, T0, πv, uv, πA, π', ub, hv, hA, hb, hle, hcv, hπ, hu⟩ := ih he
    exact ⟨A, T0, πv, uv, πA, π', ub, hv, hA, hb, hle, hΦ.trans hcv hc, hπ, hu⟩

theorem Check.eql_inv (hΦ : Pol.Pre Φ) {sp : List Term} (h : Check β Φ L sp q Γ (.Eql a b T') T π u) :
    ∃ πT πa πb, Check β Φ L [] .None Γ T' (.Typ (.Qua .Lone)) πT .Qnt ∧
      Check β Φ L [] .None Γ a T' πa .Qnt ∧ Check β Φ L [] .None Γ b T' πb .Qnt ∧
      Φ.conv (Ctx.δ Γ 0 (.Typ (.Qua .Many))) (Ctx.δ Γ 0 T) ∧
      π = Uses.zero ∧ u = Term.era q (.Eql .Qnt .Qnt .Qnt) := by
  generalize he : Term.Eql a b T' = t0 at h
  induction h <;> try exact Term.noConfusion he
  case eql hT ha hb _ _ _ =>
    cases he; exact ⟨_, _, _, hT, ha, hb, hΦ.refl _, _root_.rfl, _root_.rfl⟩
  case cnv _ hc ih =>
    obtain ⟨πT, πa, πb, hT, ha, hb, hcv, hπ, hu⟩ := ih he
    exact ⟨πT, πa, πb, hT, ha, hb, hΦ.trans hcv hc, hπ, hu⟩

theorem Check.rfl_inv (hΦ : Pol.Pre Φ) {sp : List Term} (h : Check β Φ L sp q Γ .Rfl T π u) :
    ∃ a b T0, Conv β (Ctx.δ Γ 0 a) (Ctx.δ Γ 0 b) ∧
      Φ.conv (Ctx.δ Γ 0 (.Eql a b T0)) (Ctx.δ Γ 0 T) ∧
      π = Uses.zero ∧ u = Term.era q .Rfl := by
  generalize he : Term.Rfl = t0 at h
  induction h <;> try exact Term.noConfusion he
  case rfl hab => exact ⟨_, _, _, hab, hΦ.refl _, _root_.rfl, _root_.rfl⟩
  case cnv _ hc ih =>
    obtain ⟨a, b, T0, hab, hcv, hπ, hu⟩ := ih he
    exact ⟨a, b, T0, hab, hΦ.trans hcv hc, hπ, hu⟩

theorem Check.rwt_inv (hΦ : Pol.Pre Φ) {sp : List Term} (h : Check β Φ L sp q Γ (.Rwt e P f) T π u) :
    ∃ a b T0 πe ue πP πf uf, Check β Φ L [] q Γ e (.Eql a b T0) πe ue ∧
      Check β Φ L [] .None Γ P (Term.jmotive a T0) πP .Qnt ∧
      Check β Φ L [] q Γ f (.App (.App P a) .Rfl) πf uf ∧
      Φ.conv (Ctx.δ Γ 0 (.App (.App P b) e)) (Ctx.δ Γ 0 T) ∧
      π = Uses.add πe πf ∧ u = Term.era q (.Rwt ue .Qnt uf) := by
  generalize he : Term.Rwt e P f = t0 at h
  induction h <;> try exact Term.noConfusion he
  case rwt he0 hP hf _ _ _ =>
    cases he; exact ⟨_, _, _, _, _, _, _, _, he0, hP, hf, hΦ.refl _, _root_.rfl, _root_.rfl⟩
  case cnv _ hc ih =>
    obtain ⟨a, b, T0, πe, ue, πP, πf, uf, he0, hP, hf, hcv, hπ, hu⟩ := ih he
    exact ⟨a, b, T0, πe, ue, πP, πf, uf, he0, hP, hf, hΦ.trans hcv hc, hπ, hu⟩

theorem Check.mat_inv (hΦ : Pol.Pre Φ) {sp : List Term} (h : Check β Φ L sp q Γ (.Mat a c hh mm) T π u) :
    ∃ A C r ps q' telF B G πh uh πm um,
      Book.adt β a = some A ∧ AdtD.ctr A c = some C ∧ c ∉ r ∧ ps.length = A.pn ∧
      (q ≠ .None → q' ≠ .None) ∧ Insts C.ty ps telF ∧
      MatGoal q' C.fn B (Term.apps (.Ctr a c) ps) telF G ∧
      Check β Φ (L.mat a c C.fn) [] q Γ hh G πh uh ∧
      Check β Φ L [] q Γ mm (.All q' (Term.apps (.Adt a (c :: r)) ps) B) πm um ∧
      Φ.conv (Ctx.δ Γ 0 (.All q' (Term.apps (.Adt a r) ps) B)) (Ctx.δ Γ 0 T) ∧
      π = Uses.join πh πm ∧ u = Term.era q (.Mat a c uh um) := by
  generalize he : Term.Mat a c hh mm = t0 at h
  induction h <;> try exact Term.noConfusion he
  case mat hk hc0 hr hlen hlive hins hgoal hh0 hm0 _ _ =>
    cases he
    exact ⟨_, _, _, _, _, _, _, _, _, _, _, _, hk, hc0, hr, hlen, hlive, hins, hgoal, hh0, hm0,
      hΦ.refl _, _root_.rfl, _root_.rfl⟩
  case cnv _ hc ih =>
    obtain ⟨A, C, r, ps, q', telF, B, G, πh, uh, πm, um, hk, hc0, hr, hlen, hlive, hins, hgoal,
      hh0, hm0, hcv, hπ, hu⟩ := ih he
    exact ⟨A, C, r, ps, q', telF, B, G, πh, uh, πm, um, hk, hc0, hr, hlen, hlive, hins, hgoal,
      hh0, hm0, hΦ.trans hcv hc, hπ, hu⟩

theorem Check.efq_inv (hΦ : Pol.Pre Φ) {sp : List Term} (h : Check β Φ L sp q Γ .Efq T π u) :
    ∃ a A r q' ps B, Book.adt β a = some A ∧ (q ≠ .None → q' ≠ .None) ∧
      (Book.empty β a r ∨ Φ.efq Γ) ∧
      Φ.conv (Ctx.δ Γ 0 (.All q' (Term.apps (.Adt a r) ps) B)) (Ctx.δ Γ 0 T) ∧
      π = Uses.zero ∧ u = Term.era q .Efq := by
  generalize he : Term.Efq = t0 at h
  induction h <;> try exact Term.noConfusion he
  case efq hk hlive hd => exact ⟨_, _, _, _, _, _, hk, hlive, hd, hΦ.refl _, _root_.rfl, _root_.rfl⟩
  case cnv _ hc ih =>
    obtain ⟨a, A, r, q', ps, B, hk, hlive, hd, hcv, hπ, hu⟩ := ih he
    exact ⟨a, A, r, q', ps, B, hk, hlive, hd, hΦ.trans hcv hc, hπ, hu⟩

-- ============================================================================
-- METATHEORY §E2 — spines: a checked application spine walks the head's
-- type one fitted All at a time (Args: the arguments' demands, measures
-- and erasures collected along), and a walk rebuilds the checked spine.
-- ============================================================================

theorem Quant.add_assoc : ∀ a b c : Quant,
    Quant.add (Quant.add a b) c = Quant.add a (Quant.add b c) := by
  intro a b c; cases a <;> cases b <;> cases c <;> rfl

theorem Uses.add_zero (π : Uses) : Uses.add π Uses.zero = π := by
  funext i; show Quant.add (π i) .None = π i; cases π i <;> rfl

theorem Uses.zero_add (π : Uses) : Uses.add Uses.zero π = π := by
  funext i; rfl

theorem Uses.add_assoc (a b c : Uses) :
    Uses.add (Uses.add a b) c = Uses.add a (Uses.add b c) := by
  funext i; exact Quant.add_assoc _ _ _

theorem Term.era_apps_era (q : Quant) (f : Term) (us : List Term) :
    Term.era q (Term.apps (Term.era q f) us) = Term.era q (Term.apps f us) := by
  cases q <;> rfl

theorem Check.era_self {sp : List Term} (h : Check β Φ L sp q Γ t T π u) :
    Term.era q u = u := by
  cases q
  · exact (h.none_era _root_.rfl).symm
  all_goals rfl

-- the let expansion enters an All and commutes with a substitution below
-- its depth
theorem Ctx.δ_all : ∀ (Γ : Ctx) (d : Nat) (q : Quant) (A B : Term),
    Ctx.δ Γ d (.All q A B) = .All q (Ctx.δ Γ d A) (Ctx.δ Γ (d + 1) B) := by
  intro Γ
  induction Γ with
  | nil => intros; rfl
  | cons b Γ ih =>
    intro d q A B
    obtain ⟨_, _, v⟩ := b
    cases v <;> simp only [Ctx.δ, Term.subst, ih]
    rfl

theorem Ctx.δ_typ : ∀ (Γ : Ctx) (d : Nat) (g : Term),
    Ctx.δ Γ d (.Typ g) = .Typ (Ctx.δ Γ d g) := by
  intro Γ
  induction Γ with
  | nil => intros; rfl
  | cons b Γ ih =>
    intro d g
    obtain ⟨_, _, v⟩ := b
    cases v <;> simp only [Ctx.δ, Term.subst, ih]

theorem Ctx.δ_subst : ∀ (Γ : Ctx) (d e : Nat) (x B : Term), d ≤ e →
    Ctx.δ Γ e (Term.subst d x B) = Term.subst d (Ctx.δ Γ e x) (Ctx.δ Γ (e + 1) B) := by
  intro Γ
  induction Γ with
  | nil => intros; rfl
  | cons b Γ ih =>
    intro d e x B hde
    obtain ⟨_, _, v⟩ := b
    cases v <;> simp only [Ctx.δ]
    · exact ih d (e + 1) x B (by omega)
    · rw [Term.subst_subst B e d _ x hde, ih d e _ _ hde, Term.shift_shiftN e d _ hde]

inductive Args (β : Book) (Φ : Pol) (L : LHS) (q : Quant) (Γ : Ctx) :
    Term → List Term → Term → Uses → List Term → Prop
  | nil  : Args β Φ L q Γ T [] T Uses.zero []
  | cons : Φ.conv (Ctx.δ Γ 0 T0) (Ctx.δ Γ 0 (.All q' A B)) →
           Check β Φ L [] (Quant.dem q' q) Γ a A πa ua →
           Args β Φ L q Γ (Term.subst 0 a B) as T πs us →
           Args β Φ L q Γ T0 (a :: as) T (Uses.add πa πs) (ua :: us)

theorem Args.length (h : Args β Φ L q Γ T0 as T πs us) : us.length = as.length := by
  induction h with
  | nil => rfl
  | cons _ _ _ ih => simp [ih]

-- a walk restarts at any type fitting its start
theorem Args.le_start (hΦ : Pol.Pre Φ) (h : Args β Φ L q Γ T0 as T πs us)
    (hc : Φ.conv (Ctx.δ Γ 0 X) (Ctx.δ Γ 0 T0)) :
    ∃ T', Args β Φ L q Γ X as T' πs us ∧ Φ.conv (Ctx.δ Γ 0 T') (Ctx.δ Γ 0 T) := by
  cases h with
  | nil => exact ⟨X, .nil, hc⟩
  | cons hc0 ha hr => exact ⟨_, .cons (hΦ.trans hc hc0) ha hr, hΦ.refl _⟩

theorem Args.split (h : Args β Φ L q Γ T0 (as ++ bs) T πs us) :
    ∃ Tm πa ua πb ub, Args β Φ L q Γ T0 as Tm πa ua ∧ Args β Φ L q Γ Tm bs T πb ub ∧
      πs = Uses.add πa πb ∧ us = ua ++ ub := by
  induction as generalizing T0 πs us with
  | nil => exact ⟨T0, Uses.zero, [], πs, us, .nil, h, (Uses.zero_add πs).symm, _root_.rfl⟩
  | cons a as ih =>
    simp only [List.cons_append] at h
    cases h with
    | cons hc ha hr =>
      obtain ⟨Tm, πa, ua, πb, ub, h1, h2, hπ, hu⟩ := ih hr
      subst hπ hu
      exact ⟨Tm, _, _, πb, ub, .cons hc ha h1, h2, (Uses.add_assoc _ _ _).symm, _root_.rfl⟩

-- inversion of a whole application spine (a Lam head may be a beta redex:
-- excluded)
theorem Check.apps_inv (hΦ : Pol.Pre Φ) {sp : List Term} :
    ∀ (as : List Term) (f : Term), (∀ g, f ≠ .Lam g) →
    Check β Φ L sp q Γ (Term.apps f as) T π u →
    ∃ T0 π0 u0 T1 πs us, Check β Φ L (as ++ sp) q Γ f T0 π0 u0 ∧
      Args β Φ L q Γ T0 as T1 πs us ∧ Φ.conv (Ctx.δ Γ 0 T1) (Ctx.δ Γ 0 T) ∧
      π = Uses.add π0 πs ∧ u = Term.era q (Term.apps u0 us) := by
  intro as
  induction as with
  | nil =>
    intro f _ h
    exact ⟨T, π, u, T, Uses.zero, [], h, .nil, hΦ.refl _, (Uses.add_zero π).symm,
      h.era_self.symm⟩
  | cons a as ih =>
    intro f hl h
    obtain ⟨T0, π0, u0, T1, πs, us, hfa, hargs, hle, hπ, hu⟩ :=
      ih (.App f a) (fun _ e => Term.noConfusion e) h
    rcases hfa.app_inv hΦ with ⟨q', A, B, πf, uf, πa, ua, hf, ha, hle', hπ', hu'⟩ | ⟨g, _, hg, _⟩
    · obtain ⟨T1', hargs', hle''⟩ := hargs.le_start hΦ hle'
      subst hπ hu hπ' hu'
      exact ⟨_, πf, uf, T1', _, _, hf, .cons (hΦ.refl _) ha hargs', hΦ.trans hle'' hle,
        Uses.add_assoc _ _ _, Term.era_apps_era q (.App uf ua) us⟩
    · exact absurd hg (hl g)

-- a walk rebuilds the checked spine (cnv at each App)
theorem Check.apps {sp : List Term} (h : Check β Φ L (as ++ sp) q Γ f T0 π0 u0)
    (hargs : Args β Φ L q Γ T0 as T1 πs us) :
    Check β Φ L sp q Γ (Term.apps f as) T1 (Uses.add π0 πs) (Term.era q (Term.apps u0 us)) := by
  induction hargs generalizing f π0 u0 with
  | nil => simpa only [Term.apps, List.nil_append, Uses.add_zero, h.era_self] using h
  | cons hc ha _ ih =>
    have := ih (Check.app (Check.cnv h hc) ha)
    rw [Term.era_apps_era, Uses.add_assoc] at this
    exact this

-- ============================================================================
-- METATHEORY §E3 — telescopes: substitution and retip transport the shaped
-- constructor telescopes, a walk against one lands on the family instance,
-- and the fired arm's goal walks against the scrutinee's fields.
-- ============================================================================

theorem Term.map_subst_shift (x : Term) : ∀ (ps : List Term),
    (ps.map (Term.shift 0)).map (Term.subst 0 x) = ps := by
  intro ps
  induction ps with
  | nil => rfl
  | cons p ps ih => simp [ih, Term.subst_shift]

theorem Term.map_shift_subst (d : Nat) (w : Term) : ∀ (ps : List Term),
    (ps.map (Term.shift 0)).map (Term.subst (d + 1) (Term.shift 0 w))
      = (ps.map (Term.subst d w)).map (Term.shift 0) := by
  intro ps
  induction ps with
  | nil => rfl
  | cons p ps ih => simp only [List.map, ih, Term.shift_subst_lt p 0 d w (Nat.zero_le d)]

theorem FTele.subst : ∀ {k : Nat} {ps : List Term} {B : Term},
    FTele a r ps k B → ∀ (d : Nat) (w : Term),
    FTele a r (ps.map (Term.subst d w)) k (Term.subst d w B) := by
  intro k
  induction k with
  | zero =>
    intro ps B h d w
    simp only [FTele] at h ⊢
    subst h
    rw [Term.subst_apps]; rfl
  | succ k ih =>
    intro ps B h d w
    obtain ⟨qf, F, B0, hB, hrest⟩ := h
    subst hB
    refine ⟨qf, _, _, _root_.rfl, ?_⟩
    have h2 := ih hrest (d + 1) (Term.shift 0 w)
    rwa [Term.map_shift_subst] at h2

theorem WTele.subst : ∀ {pn : Nat} {ps : List Term} {B : Term},
    WTele a r ps pn fn B → ∀ (d : Nat) (w : Term),
    WTele a r (ps.map (Term.subst d w)) pn fn (Term.subst d w B) := by
  intro pn
  induction pn with
  | zero => intro ps B h d w; exact FTele.subst h d w
  | succ pn ih =>
    intro ps B h d w
    obtain ⟨q, K, B0, hB, hrest⟩ := h
    subst hB
    refine ⟨q, _, _, _root_.rfl, ?_⟩
    have h2 := ih hrest (d + 1) (Term.shift 0 w)
    rwa [List.map_append, Term.map_shift_subst, show [Term.Var 0].map (Term.subst (d + 1) (Term.shift 0 w))
      = [Term.Var 0] by simp [Term.subst]] at h2

-- one parameter step and one field step: binding the next binder to x
theorem WTele.param (h : WTele a r ps (pn + 1) fn T) :
    ∃ q K B, T = .All q K B ∧ WTele a r (ps.map (Term.shift 0) ++ [.Var 0]) pn fn B ∧
      WTele a r (ps ++ [x]) pn fn (Term.subst 0 x B) := by
  obtain ⟨q, K, B, hT, hrest⟩ := h
  refine ⟨q, K, B, hT, hrest, ?_⟩
  have h2 := WTele.subst hrest 0 x
  rwa [List.map_append, Term.map_subst_shift, show [Term.Var 0].map (Term.subst 0 x) = [x]
    by simp [Term.subst]] at h2

theorem FTele.field (h : FTele a r ps (k + 1) T) :
    ∃ qf F B, T = .All qf F B ∧ FTele a r (ps.map (Term.shift 0)) k B ∧
      FTele a r ps k (Term.subst 0 x B) := by
  obtain ⟨qf, F, B, hT, hrest⟩ := h
  refine ⟨qf, F, B, hT, hrest, ?_⟩
  have h2 := FTele.subst hrest 0 x
  rwa [Term.map_subst_shift] at h2

-- retip re-tips a shaped telescope (its first pn binders now erased)
theorem Term.retip_adt_apps (a : Nat) (r r' : List Nat) (ps : List Term) :
    Term.retip r' 0 0 (Term.apps (.Adt a r) ps) = Term.apps (.Adt a r') ps := by
  simp only [Term.retip, Term.spine_apps (h := .Adt a r) trivial]

theorem FTele.retip (r' : List Nat) : ∀ {k : Nat} {ps : List Term} {T : Term},
    FTele a r ps k T → FTele a r' ps k (Term.retip r' 0 k T) := by
  intro k
  induction k with
  | zero =>
    intro ps T h
    simp only [FTele] at h ⊢
    subst h
    exact Term.retip_adt_apps a r r' ps
  | succ k ih =>
    intro ps T h
    obtain ⟨qf, F, B, hT, hrest⟩ := h
    subst hT
    exact ⟨qf, F, _, _root_.rfl, ih hrest⟩

theorem WTele.retip (r' : List Nat) : ∀ {pn : Nat} {ps : List Term} {T : Term},
    WTele a r ps pn fn T → WTele a r' ps pn fn (Term.retip r' pn (pn + fn) T) := by
  intro pn
  induction pn with
  | zero => intro ps T h; rw [Nat.zero_add]; exact FTele.retip r' h
  | succ pn ih =>
    intro ps T h
    obtain ⟨q, K, B, hT, hrest⟩ := h
    subst hT
    rw [show pn + 1 + fn = pn + fn + 1 by omega]
    exact ⟨.None, K, _, _root_.rfl, ih hrest⟩

theorem FTele.retip_subst : ∀ {k : Nat} {ps : List Term} {B : Term},
    FTele a r ps k B → ∀ (r' : List Nat) (d : Nat) (w : Term),
    Term.subst d w (Term.retip r' 0 k B) = Term.retip r' 0 k (Term.subst d w B) := by
  intro k
  induction k with
  | zero =>
    intro ps B h r' d w
    simp only [FTele] at h
    subst h
    rw [Term.retip_adt_apps, Term.subst_apps, Term.subst_apps]
    exact (Term.retip_adt_apps a r r' _).symm
  | succ k ih =>
    intro ps B h r' d w
    obtain ⟨qf, F, B0, hB, hrest⟩ := h
    subst hB
    show Term.All qf (Term.subst d w F) (Term.subst (d + 1) (Term.shift 0 w) (Term.retip r' 0 k B0))
      = Term.All qf (Term.subst d w F) (Term.retip r' 0 k (Term.subst (d + 1) (Term.shift 0 w) B0))
    rw [ih hrest]

theorem WTele.retip_subst : ∀ {pn : Nat} {ps : List Term} {B : Term},
    WTele a r ps pn fn B → ∀ (r' : List Nat) (d : Nat) (w : Term),
    Term.subst d w (Term.retip r' pn (pn + fn) B)
      = Term.retip r' pn (pn + fn) (Term.subst d w B) := by
  intro pn
  induction pn with
  | zero => intro ps B h r' d w; rw [Nat.zero_add]; exact FTele.retip_subst h r' d w
  | succ pn ih =>
    intro ps B h r' d w
    obtain ⟨q, K, B0, hB, hrest⟩ := h
    subst hB
    rw [show pn + 1 + fn = pn + fn + 1 by omega]
    show Term.All .None (Term.subst d w K) (Term.subst (d + 1) (Term.shift 0 w) (Term.retip r' pn (pn + fn) B0))
      = Term.All .None (Term.subst d w K) (Term.retip r' pn (pn + fn) (Term.subst (d + 1) (Term.shift 0 w) B0))
    rw [ih hrest]

-- instantiating convertible telescopes at pointwise convertible arguments
theorem Insts.conv (hβ : Book.Closed β) :
    ∀ {ps : List Term} {T X : Term}, Insts T ps X →
    ∀ {T' Y : Term} {qs : List Term}, Insts T' qs Y →
    Conv β T T' → Convs β ps qs → Conv β X Y := by
  intro ps
  induction ps with
  | nil => intro T X h T' Y qs h' hc hcs; cases h; cases hcs; cases h'; exact hc
  | cons p ps ih =>
    intro T X h T' Y qs h' hc hcs
    cases h with
    | cons hrest =>
      cases hcs with
      | cons hpq hrest2 =>
        cases h' with
        | cons hrest' =>
          obtain ⟨_, hA, hB⟩ := hc.all_inv
          exact ih hrest hrest' (Conv.subst hβ hB hpq 0) hrest2

-- one step of a walk against a syntactic All: the argument checks at the
-- All's domain, and the rest walks the substituted codomains, still fitted
theorem Args.step (hβ : Book.Closed β)
    (hle : Le β (Ctx.δ Γ 0 (.All qw K Bw)) (Ctx.δ Γ 0 T0))
    (h : Args β (Pol.std β) L q Γ T0 (x :: as) T1 πs us) :
    ∃ πx ux πs' us' B1, πs = Uses.add πx πs' ∧ us = ux :: us' ∧
      Check β (Pol.std β) L [] (Quant.dem qw q) Γ x K πx ux ∧
      Le β (Ctx.δ Γ 0 (Term.subst 0 x Bw)) (Ctx.δ Γ 0 (Term.subst 0 x B1)) ∧
      Args β (Pol.std β) L q Γ (Term.subst 0 x B1) as T1 πs' us' := by
  cases h with
  | cons hc hx hr =>
    rename_i q1 A1 B1 πx ux πs' us'
    have ra : Red β .strong (Ctx.δ Γ 0 (.All qw K Bw)) (.All qw (Ctx.δ Γ 0 K) (Ctx.δ Γ 1 Bw)) := by
      rw [Ctx.δ_all]; exact .refl
    have rb : Red β .strong (Ctx.δ Γ 0 (.All q1 A1 B1)) (.All q1 (Ctx.δ Γ 0 A1) (Ctx.δ Γ 1 B1)) := by
      rw [Ctx.δ_all]; exact .refl
    obtain ⟨rfl, hA, hB⟩ := Le.all_inv hβ (Le.trans hβ hle hc) ra rb
    refine ⟨_, _, _, _, _, _root_.rfl, _root_.rfl, Check.cnv hx hA, ?_, hr⟩
    rw [Ctx.δ_subst Γ 0 0 _ _ (Nat.le_refl 0), Ctx.δ_subst Γ 0 0 _ _ (Nat.le_refl 0)]
    exact Le.subst hβ hB 0 _

-- the constructor walk: too few arguments leaves a function type, exactly
-- enough lands on the family instance, too many is impossible
theorem Args.wtele (hβ : Book.Closed β) :
    ∀ {as : List Term} {pn fn : Nat} {ps : List Term} {Tw T0 T1 : Term} {πs : Uses} {us : List Term},
    WTele a r ps pn fn Tw → Args β (Pol.std β) L q Γ T0 as T1 πs us →
    Le β (Ctx.δ Γ 0 Tw) (Ctx.δ Γ 0 T0) →
    (as.length < pn + fn ∧ ∃ qA A B, Le β (Ctx.δ Γ 0 (.All qA A B)) (Ctx.δ Γ 0 T1)) ∨
    (as.length = pn + fn ∧
      Le β (Ctx.δ Γ 0 (Term.apps (.Adt a r) (ps ++ as.take pn))) (Ctx.δ Γ 0 T1)) := by
  intro as
  induction as with
  | nil =>
    intro pn fn ps Tw T0 T1 πs us hw h hle
    cases h
    cases pn with
    | zero =>
      cases fn with
      | zero => simp only [WTele, FTele] at hw; subst hw; right; simpa using hle
      | succ fk => obtain ⟨qf, F, B, hT, _⟩ := hw; subst hT; left; exact ⟨by simp, _, _, _, hle⟩
    | succ pk => obtain ⟨q0, K, B, hT, _⟩ := hw; subst hT; left; exact ⟨by show 0 < pk + 1 + fn; omega, _, _, _, hle⟩
  | cons x as ih =>
    intro pn fn ps Tw T0 T1 πs us hw h hle
    cases pn with
    | succ pk =>
      obtain ⟨qw, K, Bw, hT, _, hw'⟩ := WTele.param (x := x) hw
      subst hT
      obtain ⟨πx, ux, πs', us', B1, _, _, _, hB, hr⟩ := Args.step hβ hle h
      rcases ih hw' hr hB with ⟨hlt, hex⟩ | ⟨hlen, hcv⟩
      · left; exact ⟨by simp; omega, hex⟩
      · right; refine ⟨by simp at hlen ⊢; omega, ?_⟩
        simpa [List.take, List.append_assoc] using hcv
    | zero =>
      cases fn with
      | zero =>
        exfalso
        simp only [WTele, FTele] at hw
        subst hw
        cases h with
        | cons hc _ _ =>
          have := Le.trans hβ hle hc
          rw [Ctx.δ_apps, Ctx.δ_closed Γ 0 (.Adt a r) (by trivial), Ctx.δ_all] at this
          exact this.adt_all
      | succ fk =>
        obtain ⟨qf, F, Bw, hT, _, hw'⟩ := FTele.field (x := x) hw
        subst hT
        obtain ⟨πx, ux, πs', us', B1, _, _, _, hB, hr⟩ := Args.step hβ hle h
        rcases ih (pn := 0) hw' hr hB with ⟨hlt, hex⟩ | ⟨hlen, hcv⟩
        · left; exact ⟨by simp at hlt ⊢; omega, hex⟩
        · right; exact ⟨by simp at hlen ⊢; omega, by simpa using hcv⟩

-- the parameter prefix of a walk against a re-tipped constructor telescope
-- instantiates the telescope, leaving the field telescope shaped and fitted
theorem Args.params (hβ : Book.Closed β) :
    ∀ {qs : List Term} {pn : Nat} {ps0 : List Term} {Tw T0 Tm : Term} {πp : Uses} {up : List Term},
    WTele a r ps0 pn fn Tw → Args β (Pol.std β) L q Γ T0 qs Tm πp up →
    Le β (Ctx.δ Γ 0 (Term.retip r' pn (pn + fn) Tw)) (Ctx.δ Γ 0 T0) → qs.length = pn →
    ∃ TS, Insts Tw qs TS ∧ FTele a r (ps0 ++ qs) fn TS ∧
      Le β (Ctx.δ Γ 0 (Term.retip r' 0 fn TS)) (Ctx.δ Γ 0 Tm) := by
  intro qs
  induction qs with
  | nil =>
    intro pn ps0 Tw T0 Tm πp up hw h hle hlen
    cases h
    cases pn with
    | zero => rw [Nat.zero_add] at hle; exact ⟨Tw, .nil, by rw [List.append_nil]; exact hw, hle⟩
    | succ pk => simp at hlen
  | cons x qs ih =>
    intro pn ps0 Tw T0 Tm πp up hw h hle hlen
    cases pn with
    | zero => simp at hlen
    | succ pk =>
      obtain ⟨qw, K, Bw, hT, hwB, hw'⟩ := WTele.param (x := x) hw
      subst hT
      rw [show pk + 1 + fn = pk + fn + 1 by omega] at hle
      obtain ⟨πx, ux, πs', us', B1, _, _, _, hB, hr⟩ :=
        Args.step hβ (qw := .None) (K := K) (Bw := Term.retip r' pk (pk + fn) Bw) hle h
      rw [WTele.retip_subst hwB r' 0 x] at hB
      obtain ⟨TS, hI, hF, hle'⟩ := ih hw' hr hB (by simp at hlen; omega)
      exact ⟨TS, .cons hI, by simpa [List.append_assoc] using hF, hle'⟩

-- the field walk restarts exactly on the shaped field telescope, whatever
-- re-tipping it was walked through, and lands on the family instance; the
-- walked re-tipped instance fits the walk's end
theorem Args.ftele (hβ : Book.Closed β) :
    ∀ {xs : List Term} {fn : Nat} {ps : List Term} {TS T0 T1 : Term} {πs : Uses} {us : List Term},
    FTele a r ps fn TS → Args β (Pol.std β) L q Γ T0 xs T1 πs us →
    Le β (Ctx.δ Γ 0 (Term.retip r' 0 fn TS)) (Ctx.δ Γ 0 T0) → xs.length = fn →
    Args β (Pol.std β) L q Γ TS xs (Term.apps (.Adt a r) ps) πs us ∧
      Le β (Ctx.δ Γ 0 (Term.apps (.Adt a r') ps)) (Ctx.δ Γ 0 T1) := by
  intro xs
  induction xs with
  | nil =>
    intro fn ps TS T0 T1 πs us hF h hle hlen
    cases h
    cases fn with
    | zero =>
      simp only [FTele] at hF; subst hF
      rw [Term.retip_adt_apps] at hle
      exact ⟨.nil, hle⟩
    | succ fk => simp at hlen
  | cons x xs ih =>
    intro fn ps TS T0 T1 πs us hF h hle hlen
    cases fn with
    | zero => simp at hlen
    | succ fk =>
      obtain ⟨qf, F, Bs, hT, hFB, hF'⟩ := FTele.field (x := x) hF
      subst hT
      obtain ⟨πx, ux, πs', us', B1, rfl, rfl, hx, hB, hr⟩ :=
        Args.step hβ (qw := qf) (K := F) (Bw := Term.retip r' 0 fk Bs) hle h
      rw [FTele.retip_subst hFB r' 0 x] at hB
      obtain ⟨hw, hle'⟩ := ih hF' hr hB (by simp at hlen; omega)
      exact ⟨.cons (Le.refl _) hx hw, hle'⟩

theorem Quant.dem_mul (h : q ≠ .None → q' ≠ .None) :
    Quant.dem (Quant.mul qf q') q = Quant.dem qf (Quant.dem q' q) := by
  cases q <;> cases q' <;> cases qf <;> simp_all [Quant.dem, Quant.mul, Quant.add]

-- the fired arm walks its goal against the scrutinee's field checks: the
-- goal's field telescope fits the walked one, the demands reassociate, and
-- the tip lands on the motive at the rebuilt constructor
theorem MatGoal.apply (hβ : Book.Closed β) :
    ∀ (n : Nat) {B s tel G : Term}, MatGoal q' n B s tel G → (q ≠ .None → q' ≠ .None) →
    ∀ {TS xs T1 πs us}, Args β (Pol.std β) L (Quant.dem q' q) Γ TS xs T1 πs us →
    Le β (Ctx.δ Γ 0 tel) (Ctx.δ Γ 0 TS) → xs.length = n →
    Args β (Pol.std β) L q Γ G xs (Term.subst 0 (Term.apps s xs) B) πs us := by
  intro n
  induction n with
  | zero =>
    intro B s tel G hg hq TS xs T1 πs us h hle hlen
    cases hg
    cases xs with
    | nil => cases h; exact .nil
    | cons => simp at hlen
  | succ n ih =>
    intro B s tel G hg hq TS xs T1 πs us h hle hlen
    cases hg with
    | succ hrest =>
      rename_i Bf G0 qf F
      cases xs with
      | nil => simp at hlen
      | cons x xs =>
        obtain ⟨πx, ux, πs', us', B1, rfl, rfl, hx, hB, hr⟩ := Args.step hβ hle h
        have hsub := hrest.subst 0 x
        rw [Term.subst_shift B 1 _] at hsub
        have es : Term.subst 0 x (.App (Term.shift 0 s) (.Var 0)) = .App s x := by
          show Term.App _ _ = _
          rw [Term.subst_shift s 0 x]; simp [Term.subst]
        rw [es] at hsub
        have hx' : Check β (Pol.std β) L [] (Quant.dem (Quant.mul qf q') q) Γ x F πx ux := by
          rw [Quant.dem_mul hq]; exact hx
        exact .cons (Le.refl _) hx' (ih hsub hq hr hB (by simp at hlen; omega))

-- the signature walk: a family head applied to fewer parameters than its
-- arity has a function type, to exactly its arity a kind
theorem STele.subst (hβ : Book.Closed β) : ∀ {n : Nat} {T G : Term}, STele β n T G →
    ∀ (d : Nat) (w : Term),
    STele β n (Term.subst d w T) (Term.subst (d + n) (Term.shiftN n w) G) := by
  intro n
  induction n with
  | zero => intro T G h d w; exact Red.subst hβ h d w
  | succ n ih =>
    intro T G h d w
    obtain ⟨q, K, B, hT, hr⟩ := h
    subst hT
    refine ⟨q, _, _, _root_.rfl, ?_⟩
    rw [show d + (n + 1) = d + 1 + n by omega, ← Term.shiftN_shift0]
    exact ih hr (d + 1) (Term.shift 0 w)

theorem Args.stele (hβ : Book.Closed β) :
    ∀ {as : List Term} {n : Nat} {Tw G T0 T1 : Term} {πs : Uses} {us : List Term},
    STele β n Tw G → Args β (Pol.std β) L q Γ T0 as T1 πs us →
    Le β (Ctx.δ Γ 0 Tw) (Ctx.δ Γ 0 T0) →
    (as.length < n ∧ ∃ qA A B, Le β (Ctx.δ Γ 0 (.All qA A B)) (Ctx.δ Γ 0 T1)) ∨
    (as.length = n ∧ ∃ G', Le β (Ctx.δ Γ 0 (.Typ G')) (Ctx.δ Γ 0 T1)) := by
  intro as
  induction as with
  | nil =>
    intro n Tw G T0 T1 πs us hs h hle
    cases h
    cases n with
    | zero => right; exact ⟨_root_.rfl, G, Le.red_l hβ (Ctx.δ_red hβ Γ 0 hs).strong hle⟩
    | succ n => obtain ⟨q0, K, B, hT, _⟩ := hs; subst hT; left; exact ⟨by simp, _, _, _, hle⟩
  | cons x as ih =>
    intro n Tw G T0 T1 πs us hs h hle
    cases n with
    | zero =>
      exfalso
      cases h with
      | cons hc _ _ =>
        have := Le.red_l hβ (Ctx.δ_red hβ Γ 0 hs).strong (Le.trans hβ hle hc)
        rw [Ctx.δ_typ, Ctx.δ_all] at this
        exact this.typ_all
    | succ n =>
      obtain ⟨q0, K, Bw, hT, hs'⟩ := hs
      subst hT
      obtain ⟨πx, ux, πs', us', B1, _, _, _, hB, hr⟩ := Args.step hβ hle h
      rcases ih (hs'.subst hβ 0 x) hr hB with ⟨hlt, hex⟩ | ⟨hlen, hcv⟩
      · left; exact ⟨by simp at hlt ⊢; omega, hex⟩
      · right; exact ⟨by simp at hlen ⊢; omega, hcv⟩


-- ============================================================================
-- METATHEORY §G — canonical forms and progress (claim 3). A closed live
-- value is classified by its head. A typed head (VT) carries the type its
-- rule gives it, fitted below the value's type; a stuck spine (VS) sits at
-- any type and keeps the live sub-derivation that holds it stuck. A
-- stuck spine hides, down its stuck positions, a closed live term of an
-- emptied family (Bad): what claim (5) refutes, so the exact forms are
-- stated under ¬ Bad. Every closed live term is a value or weak-steps.
-- ============================================================================

theorem Book.Ok.defn (hok : Book.Ok β) (hk : Book.defn β k = some d) :
    (∃ π, Check β (Pol.std β) ⟨k, .Ref k, 0, []⟩ [] .None [] d.ty (.Typ (.Qua .Lone)) π .Qnt) ∧
    TeleQs β d.ty d.n d.qs ∧ Tree β d.n d.body ∧ Term.CtrsFull β 0 d.body ∧
      ∃ π u, Check β (Pol.std β) ⟨k, .Ref k, d.n, d.qs⟩ [] .Lone [] d.body d.ty π u :=
  hok k _ (Book.defn_tld hk)

theorem Book.Ok.adt (hok : Book.Ok β) (hk : Book.adt β a = some A) :
    (∃ π, Check β (Pol.std β) ⟨a, .Ref a, 0, []⟩ [] .None [] A.sig (.Typ (.Qua .Lone)) π .Qnt) ∧
    ∃ G, STele β A.pn A.sig G ∧
    ∀ c C, AdtD.ctr A c = some C → CtrD.Shape a A.pn C ∧ CtrOk β a A.pn G [] 0 C.ty :=
  hok a _ (Book.adt_tld hk)

theorem AdtD.ctr_lt {A : AdtD} (h : AdtD.ctr A c = some C) : c < A.ctrs.length := by
  unfold AdtD.ctr at h
  generalize A.ctrs = cs at h ⊢
  induction cs generalizing c with
  | nil => cases h
  | cons C0 cs ih =>
    cases c with
    | zero => exact Nat.succ_pos _
    | succ c => exact Nat.succ_lt_succ (ih h)

-- the closed context is never dead
theorem CtxDead.nil : ¬ CtxDead β [] := by
  rintro ⟨i, b, _, _, _, hg, -⟩
  simp [Ctx.get] at hg

theorem Term.era_live (hq : q ≠ .None) (t : Term) : Term.era q t = t := by
  cases q <;> first | exact absurd _root_.rfl hq | rfl

theorem Quant.dem_live (hq' : q' ≠ .None) : Quant.dem q' q = q := by
  cases q' <;> first | exact absurd _root_.rfl hq' | rfl

theorem Ctx.δ_nil (d : Nat) (t : Term) : Ctx.δ [] d t = t := rfl

theorem Pol.std_conv (a b : Term) : (Pol.std β).conv a b = Le β a b := rfl

theorem Term.size_le_apps (h : Term) : ∀ (as : List Term), Term.size h ≤ Term.size (Term.apps h as) := by
  intro as
  induction as generalizing h with
  | nil => exact Nat.le_refl _
  | cons a as ih => exact Nat.le_trans (by simp only [Term.size]; omega) (ih (.App h a))

theorem Term.size_rwt (e P f : Term) (as : List Term) :
    Term.size e < Term.size (Term.apps (.Rwt e P f) as) :=
  Nat.lt_of_lt_of_le (by simp only [Term.size]; omega) (Term.size_le_apps _ as)

theorem Term.size_matS (a c : Nat) (h m x : Term) (as : List Term) :
    Term.size x < Term.size (Term.apps (.Mat a c h m) (x :: as)) :=
  Term.size_spine_arg _ x (by rw [Term.spine_apps (h := .Mat a c h m) (by trivial)]; simp)

theorem TeleQs.subst (hβ : Book.Closed β) : ∀ {T : Term} {n : Nat} {qs : List Quant},
    TeleQs β T n qs → ∀ (d : Nat) (w : Term), TeleQs β (Term.subst d w T) n qs := by
  intro T n qs h
  induction h with
  | nil => intros; exact .nil
  | cons hr _ ih => intro d w; exact .cons (hr.subst hβ d w) (ih (d + 1) (Term.shift 0 w))

-- the definition walk: fewer arguments than the columns leaves a function type
theorem Args.teleqs (hβ : Book.Closed β) :
    ∀ {as : List Term} {n : Nat} {Tw T0 T1 : Term} {qs : List Quant} {πs : Uses} {us : List Term},
    TeleQs β Tw n qs → Args β (Pol.std β) L q [] T0 as T1 πs us → Le β Tw T0 → as.length < n →
    ∃ qA A B, Le β (.All qA A B) T1 := by
  intro as
  induction as with
  | nil =>
    intro n Tw T0 T1 qs πs us hs h hle hlt
    cases h
    cases hs with
    | nil => simp at hlt
    | cons hr _ => exact ⟨_, _, _, Le.red_l hβ hr.strong hle⟩
  | cons x as ih =>
    intro n Tw T0 T1 qs πs us hs h hle hlt
    cases hs with
    | nil => simp at hlt
    | cons hr hs' =>
      obtain ⟨_, _, _, _, _, -, -, -, hB, hr'⟩ :=
        Args.step (Γ := []) hβ (Le.red_l hβ hr.strong hle) h
      exact ih (hs'.subst hβ 0 x) hr' hB (by simp at hlt; omega)

-- a walk from a stable non-function type takes no argument
theorem Args.nil_of (hβ : Book.Closed β) (h : Args β (Pol.std β) L q [] T0 as T1 πs us)
    (hle : Le β X T0) (hX : 6 ≤ X.tag) (hX' : X.tag ≠ 10) : as = [] ∧ T1 = T0 ∧ us = [] := by
  cases h with
  | nil => exact ⟨_root_.rfl, _root_.rfl, _root_.rfl⟩
  | cons hc _ _ =>
    simp only [Ctx.δ_nil, Pol.std_conv] at hc
    have := (Le.trans hβ hle hc).tag hX (by simp [Term.tag])
    simp [Term.tag] at this
    exact (hX' this).elim

-- the typed heads of a closed live value: its shape and the type its head
-- rule gives it, fitted below the value's type
inductive Check.VT (β : Book) : Term → Term → Prop
  | typ  : Le β (.Typ (.Qua .Lone)) T → Check.VT β (.Typ g) T
  | qnt  : Le β (.Typ (.Qua .Lone)) T → Check.VT β .Qnt T
  | all  : Le β (.Typ (.Qua .Lone)) T → Check.VT β (.All q A B) T
  | eql  : Le β (.Typ (.Qua .Many)) T → Check.VT β (.Eql a b T') T
  | adtT : Book.adt β a = some A → as.length = A.pn → Le β (.Typ G) T →
           Check.VT β (Term.apps (.Adt a r) as) T
  | qua  : Le β .Qnt T → Check.VT β (.Qua q) T
  | lam  : Le β (.All q A B) T → Check.VT β (.Lam f) T
  | mat  : q ≠ .None → Le β (.All q (Term.apps (.Adt a r) ps) B) T → Check.VT β (.Mat a c h m) T
  | efq  : Le β (.All q A B) T → Check.VT β .Efq T
  | adtF : Book.adt β a = some A → as.length < A.pn → Le β (.All q A' B) T →
           Check.VT β (Term.apps (.Adt a r) as) T
  | ctrF : Book.adt β a = some A → AdtD.ctr A c = some C → as.length < A.pn + C.fn →
           Le β (.All q A' B) T → Check.VT β (Term.apps (.Ctr a c) as) T
  | ref  : Book.defn β k = some d → as.length < d.n → Le β (.All q A B) T →
           Check.VT β (Term.apps (.Ref k) as) T
  | ctr  : Book.adt β a = some A → AdtD.ctr A c = some C → c ∉ r → as.length = A.pn + C.fn →
           Le β (Term.apps (.Adt a r) (as.take A.pn)) T → Check.VT β (Term.apps (.Ctr a c) as) T
  | rfl  : Le β (.Eql a b T') T → Check.VT β .Rfl T

-- the stuck spines of a closed live value, at any type: a stuck meet, a
-- rewrite on stuck evidence, a match on a stuck scrutinee, an empty match
-- applied; each keeps the live sub-derivation that holds it stuck, and
-- its erasure
inductive Check.VS (β : Book) (q : Quant) : Term → Term → Prop
  | min  : Term.Value β a → a ≠ .Qua .Many → a ≠ .Qua .None →
           Term.Value β b → b ≠ .Qua .Many → b ≠ .Qua .None →
           ¬ (a = .Qua .Lone ∧ b = .Qua .Lone) →
           Check β (Pol.std β) (LHS.void β) [] q [] a .Qnt πa ua →
           Check β (Pol.std β) (LHS.void β) [] q [] b .Qnt πb ub →
           Check.VS β q (.Min a b) (.Min ua ub)
  | rwt  : Term.Value β e → e ≠ .Rfl →
           Check β (Pol.std β) (LHS.void β) [] q [] e (.Eql a b T') πe ue →
           Check.VS β q (Term.apps (.Rwt e P f) as) (Term.apps (.Rwt ue .Qnt uf) us)
  | matS : Term.Value β x → (∀ a' c' xs, x ≠ Term.apps (.Ctr a' c') xs) →
           Check β (Pol.std β) (LHS.void β) [] q [] x (Term.apps (.Adt a r) ps) πx ux →
           Check.VS β q (Term.apps (.Mat a c h m) (x :: as)) (Term.apps (.Mat a c uh um) (ux :: us))
  | efqS : Book.empty β a r →
           Check β (Pol.std β) (LHS.void β) [] q [] x (Term.apps (.Adt a r) ps) πx ux →
           Check.VS β q (Term.apps .Efq (x :: as)) (Term.apps .Efq (ux :: us))

theorem Check.VS.ne_ctr (hvs : Check.VS β q v u) : ∀ a' c' xs, v ≠ Term.apps (.Ctr a' c') xs := by
  intro a' c' xs
  cases hvs with
  | min => exact fun h => Term.apps_ctr_ne (by trivial) (fun e => Term.noConfusion e) h.symm
  | rwt | matS | efqS =>
    exact fun h => Term.noConfusion (Term.apps_head_inv (by trivial) (by trivial) h).1

theorem Check.VS.ne_rfl (hvs : Check.VS β q v u) : v ≠ .Rfl := by
  cases hvs with
  | min => exact fun e => Term.noConfusion e
  | rwt | matS | efqS => exact Term.apps_ne (by trivial) (by trivial) (fun e => Term.noConfusion e)

-- the classification: a closed live value is a typed head or a stuck spine
theorem Check.value_inv (hok : Book.Ok β) (hq : q ≠ .None) {sp : List Term}
    (hv : Term.Value β v) (h : Check β (Pol.std β) (LHS.void β) sp q [] v T π u) :
    Check.VT β v T ∨ Check.VS β q v u := by
  have hβ := hok.closed
  have hpre := Pol.std_pre hβ
  cases hv with
  | var =>
    obtain ⟨_, _, _, _, _, _, h0, -, -, -, -⟩ := Check.apps_inv hpre _ _ (by intro _ e; cases e) h
    obtain ⟨b, hg, -⟩ := h0.var_inv hpre
    simp [Ctx.get] at hg
  | typ =>
    obtain ⟨T0, _, _, T1, _, _, h0, hargs, hle, -, -⟩ := Check.apps_inv hpre _ _ (by intro _ e; cases e) h
    obtain ⟨_, -, hc, -, -⟩ := h0.typ_inv hpre
    simp only [Ctx.δ_nil, Pol.std_conv] at hc hle
    obtain ⟨rfl, rfl, -⟩ := Args.nil_of hβ hargs hc (by simp [Term.tag]) (by simp [Term.tag])
    exact .inl (.typ (Le.trans hβ hc hle))
  | qnt =>
    obtain ⟨T0, _, _, T1, _, _, h0, hargs, hle, -, -⟩ := Check.apps_inv hpre _ _ (by intro _ e; cases e) h
    obtain ⟨hc, -, -⟩ := h0.qnt_inv hpre
    simp only [Ctx.δ_nil, Pol.std_conv] at hc hle
    obtain ⟨rfl, rfl, -⟩ := Args.nil_of hβ hargs hc (by simp [Term.tag]) (by simp [Term.tag])
    exact .inl (.qnt (Le.trans hβ hc hle))
  | qua =>
    obtain ⟨T0, _, _, T1, _, _, h0, hargs, hle, -, -⟩ := Check.apps_inv hpre _ _ (by intro _ e; cases e) h
    obtain ⟨hc, -, -⟩ := h0.qua_inv hpre
    simp only [Ctx.δ_nil, Pol.std_conv] at hc hle
    obtain ⟨rfl, rfl, -⟩ := Args.nil_of hβ hargs hc (by simp [Term.tag]) (by simp [Term.tag])
    exact .inl (.qua (Le.trans hβ hc hle))
  | all =>
    obtain ⟨T0, _, _, T1, _, _, h0, hargs, hle, -, -⟩ := Check.apps_inv hpre _ _ (by intro _ e; cases e) h
    obtain ⟨_, _, -, -, hc, -, -⟩ := h0.all_inv hpre
    simp only [Ctx.δ_nil, Pol.std_conv] at hc hle
    obtain ⟨rfl, rfl, -⟩ := Args.nil_of hβ hargs hc (by simp [Term.tag]) (by simp [Term.tag])
    exact .inl (.all (Le.trans hβ hc hle))
  | lam =>
    obtain ⟨_, _, _, _, _, _, -, -, -, hc, -, -⟩ := h.lam_inv hpre
    simp only [Ctx.δ_nil, Pol.std_conv] at hc
    exact .inl (.lam hc)
  | mat =>
    obtain ⟨_, _, _, _, _, _, _, _, _, _, _, _, -, -, -, -, hq', -, -, -, -, hc, -, -⟩ := h.mat_inv hpre
    simp only [Ctx.δ_nil, Pol.std_conv] at hc
    exact .inl (.mat (hq' hq) hc)
  | @efq as =>
    obtain ⟨T0, _, u0, T1, _, us, h0, hargs, hle, -, hu⟩ := Check.apps_inv hpre _ _ (by intro _ e; cases e) h
    obtain ⟨a, A, r, q', ps, B, -, hq', hemp, hc, -, hu0⟩ := h0.efq_inv hpre
    simp only [Ctx.δ_nil, Pol.std_conv] at hc hle
    have hemp := hemp.resolve_right CtxDead.nil
    cases as with
    | nil => cases hargs; exact .inl (.efq (Le.trans hβ hc hle))
    | cons x as =>
      obtain ⟨πx, ux, πs', us', B1, -, rfl, hx, -, -⟩ := Args.step (Γ := []) hβ hc hargs
      rw [Quant.dem_live (hq' hq)] at hx
      subst hu hu0
      simp only [Term.era_live hq]
      exact .inr (.efqS hemp hx)
  | eql =>
    obtain ⟨T0, _, _, T1, _, _, h0, hargs, hle, -, -⟩ := Check.apps_inv hpre _ _ (by intro _ e; cases e) h
    obtain ⟨_, _, _, -, -, -, hc, -, -⟩ := h0.eql_inv hpre
    simp only [Ctx.δ_nil, Pol.std_conv] at hc hle
    obtain ⟨rfl, rfl, -⟩ := Args.nil_of hβ hargs hc (by simp [Term.tag]) (by simp [Term.tag])
    exact .inl (.eql (Le.trans hβ hc hle))
  | rfl =>
    obtain ⟨T0, _, _, T1, _, _, h0, hargs, hle, -, -⟩ := Check.apps_inv hpre _ _ (by intro _ e; cases e) h
    obtain ⟨_, _, _, -, hc, -, -⟩ := h0.rfl_inv hpre
    simp only [Ctx.δ_nil, Pol.std_conv] at hc hle
    obtain ⟨rfl, rfl, -⟩ := Args.nil_of hβ hargs hc (by simp [Term.tag]) (by simp [Term.tag])
    exact .inl (.rfl (Le.trans hβ hc hle))
  | @adt a r as =>
    obtain ⟨T0, _, _, T1, _, _, h0, hargs, hle, -, -⟩ := Check.apps_inv hpre _ _ (by intro _ e; cases e) h
    obtain ⟨A, hA, hc, -, -⟩ := h0.adt_inv hpre
    simp only [Ctx.δ_nil, Pol.std_conv] at hc hle
    obtain ⟨-, G, hs, -⟩ := hok.adt hA
    rcases Args.stele (Γ := []) hβ hs hargs hc with ⟨hlt, _, _, _, hl⟩ | ⟨hlen, G', hl⟩
    · simp only [Ctx.δ_nil] at hl
      exact .inl (.adtF hA hlt (Le.trans hβ hl hle))
    · simp only [Ctx.δ_nil] at hl
      exact .inl (.adtT hA hlen (Le.trans hβ hl hle))
  | @ctr a c as =>
    obtain ⟨T0, _, _, T1, _, _, h0, hargs, hle, -, -⟩ := Check.apps_inv hpre _ _ (by intro _ e; cases e) h
    obtain ⟨A, C, r, hA, hC, hr, hc, -, -⟩ := h0.ctr_inv hpre
    simp only [Ctx.δ_nil, Pol.std_conv] at hc hle
    obtain ⟨-, _, _, hcs⟩ := hok.adt hA
    have hw := WTele.retip r (show WTele a [] [] A.pn C.fn C.ty from (hcs c C hC).1)
    rcases Args.wtele (Γ := []) hβ hw hargs hc with ⟨hlt, _, _, _, hl⟩ | ⟨hlen, hl⟩
    · simp only [Ctx.δ_nil] at hl
      exact .inl (.ctrF hA hC hlt (Le.trans hβ hl hle))
    · simp only [Ctx.δ_nil, List.nil_append] at hl
      exact .inl (.ctr hA hC hr hlen (Le.trans hβ hl hle))
  | @fam k A as hk hpn =>
    obtain ⟨_, _, _, _, _, _, h0, -, -, -, -⟩ := Check.apps_inv hpre _ _ (by intro _ e; cases e) h
    rcases h0.ref_inv hpre with ⟨d, hd, -, -, -, -, -, -⟩ | ⟨A', hA', h0', -, -, -⟩
    · exact (Book.defn_adt_clash hd hk).elim
    · rw [hk] at hA'; cases hA'; omega
  | @ref k d as hk hgate =>
    obtain ⟨T0, _, _, T1, _, _, h0, hargs, hle, -, -⟩ := Check.apps_inv hpre _ _ (by intro _ e; cases e) h
    rcases h0.ref_inv hpre with ⟨d', hd', -, -, hc, -, -⟩ | ⟨A', hA', -, -, -, -⟩
    · rw [hk] at hd'; cases hd'
      simp only [Ctx.δ_nil, Pol.std_conv] at hc hle
      obtain ⟨_, _, _, hl⟩ := Args.teleqs hβ (hok.defn hk).2.1 hargs hc hgate
      exact .inl (.ref hk hgate (Le.trans hβ hl hle))
    · exact (Book.defn_adt_clash hk hA').elim
  | min hva hna1 hna2 hvb hnb1 hnb2 hnab =>
    obtain ⟨T0, _, u0, T1, _, us, h0, hargs, hle, -, hu⟩ := Check.apps_inv hpre _ _ (by intro _ e; cases e) h
    obtain ⟨πa, ua, πb, ub, ha, hb, hc, -, hu0⟩ := h0.min_inv hpre
    simp only [Ctx.δ_nil, Pol.std_conv] at hc
    obtain ⟨rfl, rfl, rfl⟩ := Args.nil_of hβ hargs hc (by simp [Term.tag]) (by simp [Term.tag])
    subst hu hu0
    simp only [Term.apps, Term.era_live hq]
    exact .inr (.min hva hna1 hna2 hvb hnb1 hnb2 hnab ha hb)
  | rwt hve hne =>
    obtain ⟨T0, _, u0, T1, _, us, h0, hargs, hle, -, hu⟩ := Check.apps_inv hpre _ _ (by intro _ e; cases e) h
    obtain ⟨_, _, _, _, _, _, _, _, he, -, -, -, -, hu0⟩ := h0.rwt_inv hpre
    subst hu hu0
    simp only [Term.era_live hq]
    exact .inr (.rwt hve hne he)
  | matS hvx hnx =>
    obtain ⟨T0, _, u0, T1, _, us, h0, hargs, hle, -, hu⟩ := Check.apps_inv hpre _ _ (by intro _ e; cases e) h
    obtain ⟨_, _, _, _, _, _, _, _, _, _, _, _, -, -, -, -, hq', -, -, -, -, hc, -, hu0⟩ := h0.mat_inv hpre
    simp only [Ctx.δ_nil, Pol.std_conv] at hc
    obtain ⟨πx, ux, πs', us', B1, -, rfl, hx, -, -⟩ := Args.step (Γ := []) hβ hc hargs
    rw [Quant.dem_live (hq' hq)] at hx
    subst hu hu0
    simp only [Term.era_live hq]
    exact .inr (.matS hvx hnx hx)

-- the function values: what a closed live value at a function type is,
-- beside a stuck spine
inductive Term.FunV (β : Book) : Term → Prop
  | lam : Term.FunV β (.Lam f)
  | mat : Term.FunV β (.Mat a c h m)
  | efq : Term.FunV β .Efq
  | adt : Book.adt β a = some A → as.length < A.pn → Term.FunV β (Term.apps (.Adt a r) as)
  | ctr : Book.adt β a = some A → AdtD.ctr A c = some C → as.length < A.pn + C.fn →
          Term.FunV β (Term.apps (.Ctr a c) as)
  | ref : Book.defn β k = some d → as.length < d.n →
          Term.FunV β (Term.apps (.Ref k) as)

-- a typed head at a function, family, equation or Quant type: the heads
-- of the other classes clash
theorem Check.VT.at_all (hβ : Book.Closed β) (hvt : Check.VT β v T) (hT : Le β T (.All q' A B)) :
    Term.FunV β v := by
  cases hvt with
  | lam _ => exact .lam
  | mat _ _ => exact .mat
  | efq _ => exact .efq
  | adtF hA hlt _ => exact .adt hA hlt
  | ctrF hA hC hlt _ => exact .ctr hA hC hlt
  | ref hk hlt _ => exact .ref hk hlt
  | typ hl | qnt hl | all hl | eql hl | adtT _ _ hl | qua hl | ctr _ _ _ _ hl | rfl hl =>
    simpa [Term.tag] using (Le.trans hβ hl hT).tag

theorem Check.VT.at_adt (hβ : Book.Closed β) (hvt : Check.VT β v T)
    (hT : Le β T (Term.apps (.Adt a r) ps)) :
    ∃ c A C as, v = Term.apps (.Ctr a c) as ∧ Book.adt β a = some A ∧ AdtD.ctr A c = some C ∧
      c ∉ r ∧ as.length = A.pn + C.fn ∧ Convs β (as.take A.pn) ps := by
  cases hvt with
  | ctr hA hC hr hlen hl =>
    obtain ⟨rfl, hsub, hcv⟩ := Le.adt_inv hβ (Le.trans hβ hl hT) .refl .refl
    exact ⟨_, _, _, _, _root_.rfl, hA, hC, fun hc => hr (hsub _ hc), hlen, hcv⟩
  | typ hl | qnt hl | all hl | eql hl | adtT _ _ hl | qua hl | lam hl | mat _ hl | efq hl
  | adtF _ _ hl | ctrF _ _ _ hl | ref _ _ hl | rfl hl =>
    simpa [Term.tag] using (Le.trans hβ hl hT).tag

theorem Check.VT.at_eql (hβ : Book.Closed β) (hvt : Check.VT β v T) (hT : Le β T (.Eql a b T')) :
    v = .Rfl := by
  cases hvt with
  | rfl _ => exact _root_.rfl
  | typ hl | qnt hl | all hl | eql hl | adtT _ _ hl | qua hl | lam hl | mat _ hl | efq hl
  | adtF _ _ hl | ctrF _ _ _ hl | ref _ _ hl | ctr _ _ _ _ hl =>
    simpa [Term.tag] using (Le.trans hβ hl hT).tag

theorem Check.VT.at_qnt (hβ : Book.Closed β) (hvt : Check.VT β v T) (hT : Le β T .Qnt) :
    ∃ q', v = .Qua q' := by
  cases hvt with
  | qua _ => exact ⟨_, _root_.rfl⟩
  | typ hl | qnt hl | all hl | eql hl | adtT _ _ hl | lam hl | mat _ hl | efq hl
  | adtF _ _ hl | ctrF _ _ _ hl | ref _ _ hl | ctr _ _ _ _ hl | rfl hl =>
    simpa [Term.tag] using (Le.trans hβ hl hT).tag

theorem Check.canon_adt (hok : Book.Ok β) (hq : q ≠ .None) {sp : List Term} (hv : Term.Value β v)
    (h : Check β (Pol.std β) (LHS.void β) sp q [] v T π u)
    (hT : Le β T (Term.apps (.Adt a r) ps)) :
    (∃ c A C as, v = Term.apps (.Ctr a c) as ∧ Book.adt β a = some A ∧ AdtD.ctr A c = some C ∧
      c ∉ r ∧ as.length = A.pn + C.fn ∧ Convs β (as.take A.pn) ps) ∨ Check.VS β q v u :=
  (Check.value_inv hok hq hv h).imp (fun hvt => hvt.at_adt hok.closed hT) id

-- Term.Bad β q v u: the value v, erased to u, hides down its stuck positions a
-- closed live term of an emptied family (with its erasure). What holds a
-- stuck spine stuck; claim (5) says there is none
inductive Term.Bad (β : Book) (q : Quant) : Term → Term → Prop
  | efq  : Book.empty β a r →
           Check β (Pol.std β) (LHS.void β) [] q [] x (Term.apps (.Adt a r) ps) πx ux →
           Term.Bad β q (Term.apps .Efq (x :: as)) (Term.apps .Efq (ux :: us))
  | rwt  : Term.Bad β q e ue → Term.Bad β q (Term.apps (.Rwt e P f) as) (Term.apps (.Rwt ue .Qnt uf) us)
  | matS : Term.Bad β q x ux →
           Term.Bad β q (Term.apps (.Mat a c h m) (x :: as)) (Term.apps (.Mat a c uh um) (ux :: us))
  | minL : Term.Bad β q a ua → Term.Bad β q (.Min a b) (.Min ua ub)
  | minR : Term.Bad β q b ub → Term.Bad β q (.Min a b) (.Min ua ub)

-- a closed live value that hides no emptied-typed term is a typed head: a
-- stuck spine's stuck position is a smaller value of an equation, family
-- or Quant type, which its own exact form contradicts
theorem Check.value_head (hok : Book.Ok β) (hq : q ≠ .None) {sp : List Term}
    (hv : Term.Value β v) (h : Check β (Pol.std β) (LHS.void β) sp q [] v T π u)
    (hnb : ¬ Term.Bad β q v u) : Check.VT β v T := by
  have hβ := hok.closed
  suffices H : ∀ (n : Nat) (v : Term), Term.size v ≤ n → ∀ {sp : List Term} {T : Term} {π : Uses} {u : Term},
      Term.Value β v → Check β (Pol.std β) (LHS.void β) sp q [] v T π u →
      ¬ Term.Bad β q v u → Check.VT β v T from H _ v (Nat.le_refl _) hv h hnb
  intro n
  induction n with
  | zero => intro v hn; have := Term.size_pos v; omega
  | succ n ih =>
    intro v hn sp T π u hv h hnb
    rcases Check.value_inv hok hq hv h with hvt | hvs
    · exact hvt
    cases hvs with
    | min hva hna1 hna2 hvb hnb1 hnb2 hnab ha hb =>
      obtain ⟨qa, rfl⟩ := (ih _ (by simp only [Term.size] at hn; omega) hva ha
        fun hb => hnb (.minL hb)).at_qnt hβ (Le.refl _)
      obtain ⟨qb, rfl⟩ := (ih _ (by simp only [Term.size] at hn; omega) hvb hb
        fun hb => hnb (.minR hb)).at_qnt hβ (Le.refl _)
      cases qa <;> cases qb <;> simp at hna1 hna2 hnb1 hnb2 hnab
    | rwt hve hne he =>
      exact absurd ((ih _ (Nat.le_of_lt_succ (Nat.lt_of_lt_of_le (Term.size_rwt _ _ _ _) hn)) hve he
        fun hb => hnb (.rwt hb)).at_eql hβ (Le.refl _)) hne
    | matS hvx hnx hx =>
      obtain ⟨_, _, _, _, he, -⟩ :=
        (ih _ (Nat.le_of_lt_succ (Nat.lt_of_lt_of_le (Term.size_matS _ _ _ _ _ _) hn)) hvx hx
          fun hb => hnb (.matS hb)).at_adt hβ (Le.refl _)
      exact absurd he (hnx _ _ _)
    | efqS hemp hx => exact (hnb (.efq hemp hx)).elim

theorem Check.canon_adt' (hok : Book.Ok β) (hq : q ≠ .None) {sp : List Term}
    (hv : Term.Value β v) (h : Check β (Pol.std β) (LHS.void β) sp q [] v T π u)
    (hnb : ¬ Term.Bad β q v u) (hT : Le β T (Term.apps (.Adt a r) ps)) :
    ∃ c A C as, v = Term.apps (.Ctr a c) as ∧ Book.adt β a = some A ∧ AdtD.ctr A c = some C ∧
      c ∉ r ∧ as.length = A.pn + C.fn ∧ Convs β (as.take A.pn) ps :=
  (Check.value_head hok hq hv h hnb).at_adt hok.closed hT

-- a closed live value of an emptied family hides an emptied-typed term:
-- the constructor case contradicts the peeled set
theorem Check.canon_empty (hok : Book.Ok β) (hq : q ≠ .None) {sp : List Term}
    (hv : Term.Value β v) (h : Check β (Pol.std β) (LHS.void β) sp q [] v T π u)
    (hT : Le β T (Term.apps (.Adt a r) ps)) (hemp : Book.empty β a r) : Term.Bad β q v u := by
  refine Classical.byContradiction fun hnb => ?_
  obtain ⟨c, A, C, as, -, hA, hC, hr, -, -⟩ :=
    (Check.value_head hok hq hv h hnb).at_adt hok.closed hT
  obtain ⟨A', hA', hall⟩ := hemp
  rw [hA] at hA'
  cases hA'
  exact hr (hall c (AdtD.ctr_lt hC))

-- ============================================================================
-- progress (claim 3)
-- ============================================================================

-- a definition head: it fires at its arity, else stays stuck
theorem Check.progress_ref (hk : Book.defn β k = some d) :
    Term.Value β (.Ref k) ∨ ∃ t', Step β .weak (.Ref k) t' := by
  by_cases hn : d.n = 0
  · exact .inr ⟨_, Step.dref (s := .Ref k) hk _root_.rfl (by rw [hn]; exact _root_.rfl)⟩
  · exact .inl (Term.Value.ref (as := []) hk (by simp only [List.length_nil]; omega))

theorem Check.step_ref (hk : Book.defn β k = some d) (hlt : as.length < d.n) (x : Term) :
    Term.Value β (.App (Term.apps (.Ref k) as) x) ∨
    ∃ t', Step β .weak (.App (Term.apps (.Ref k) as) x) t' := by
  rw [← Term.apps_snoc]
  by_cases hn : as.length + 1 = d.n
  · exact .inr ⟨_, Step.dref hk (by rw [Term.spine_apps (h := .Ref k) (by trivial)])
      (by rw [Term.spine_apps (h := .Ref k) (by trivial)]; simpa using hn)⟩
  · exact .inl (Term.Value.ref hk (by simp only [List.length_append, List.length_singleton]; omega))

-- a meet of two values: a literal side fires a min rule, else it is stuck
theorem Check.step_min (hva : Term.Value β a) (hvb : Term.Value β b) :
    Term.Value β (.Min a b) ∨ ∃ t', Step β .weak (.Min a b) t' := by
  by_cases h1 : a = .Qua .Many
  · subst h1; exact .inr ⟨_, .minLM⟩
  by_cases h2 : a = .Qua .None
  · subst h2; exact .inr ⟨_, .minLN⟩
  by_cases h3 : b = .Qua .Many
  · subst h3; exact .inr ⟨_, .minRM⟩
  by_cases h4 : b = .Qua .None
  · subst h4; exact .inr ⟨_, .minRN⟩
  by_cases h5 : a = .Qua .Lone ∧ b = .Qua .Lone
  · obtain ⟨rfl, rfl⟩ := h5; exact .inr ⟨_, .minLL⟩
  · exact .inl (Term.Value.min (as := []) hva h1 h2 hvb h3 h4 h5)

-- a match applied to a value of its family: a constructor fires the arm or
-- the tail, a stuck scrutinee keeps the match stuck
theorem Check.step_mat (hok : Book.Ok β) (hq : q ≠ .None) (hvx : Term.Value β x)
    (hx : Check β (Pol.std β) (LHS.void β) [] q [] x (Term.apps (.Adt a r) ps) πx ux) :
    Term.Value β (.App (.Mat a c hh mm) x) ∨ ∃ t', Step β .weak (.App (.Mat a c hh mm) x) t' := by
  rcases Check.value_inv hok hq hvx hx with hvt | hvs
  · obtain ⟨c', A, C, as, rfl, hA, hC, -, hlen, -⟩ := hvt.at_adt hok.closed (Le.refl _)
    by_cases hcc : c' = c
    · subst hcc
      rw [← List.take_append_drop A.pn as]
      exact .inr ⟨_, Step.matc hA hC (by simp [List.length_take]; omega)
        (by simp [List.length_drop]; omega)⟩
    · exact .inr ⟨_, Step.matm (by intro e; cases e; exact hcc _root_.rfl)⟩
  · exact .inl (Term.Value.matS (as := []) hvx hvs.ne_ctr)

theorem progress_holds : progress := by
  intro β q t T π u hok hq h
  have hβ := hok.closed
  generalize hΓ : ([] : Ctx) = Γ0 at h
  generalize hL : LHS.void β = L0 at h
  generalize ([] : List Term) = sp0 at h
  induction h with
  | var hg => subst hΓ; simp [Ctx.get] at hg
  | ref hk _ _ => exact Check.progress_ref hk
  | refA hk h0 => exact .inr ⟨_, .aref hk h0⟩
  | adt _ => exact .inl (Term.Value.adt (as := []))
  | ctr _ _ _ => exact .inl (Term.Value.ctr (as := []))
  | typ _ _ => exact .inl (Term.Value.typ (as := []))
  | qnt => exact .inl (Term.Value.qnt (as := []))
  | qua => exact .inl (Term.Value.qua (as := []))
  | min _ _ iha ihb =>
    rcases iha hq hΓ hL with hva | ⟨a', hs⟩
    · rcases ihb hq hΓ hL with hvb | ⟨b', hs⟩
      · exact Check.step_min hva hvb
      · exact .inr ⟨_, .min_b hs⟩
    · exact .inr ⟨_, .min_a hs⟩
  | all _ _ _ _ => exact .inl (Term.Value.all (as := []))
  | lam _ _ _ _ _ => exact .inl .lam
  | app hf hx ihf ihx =>
    subst hΓ hL
    rcases ihf hq _root_.rfl _root_.rfl with hvf | ⟨f', hs⟩
    · rcases Check.value_inv hok hq hvf hf with hvt | hvs
      · cases hvt with
        | lam _ => exact .inr ⟨_, .beta⟩
        | mat hq' hl =>
          obtain ⟨rfl, hA, -⟩ := Le.all_inv hβ hl .refl .refl
          rw [Quant.dem_live hq'] at hx ihx
          rcases ihx hq _root_.rfl _root_.rfl with hvx | ⟨x', hs⟩
          · exact Check.step_mat hok hq hvx (Check.cnv hx hA)
          · exact .inr ⟨_, .app_a hs⟩
        | efq _ => exact .inl (Term.Value.efq (as := [_]))
        | adtF _ _ _ => rw [← Term.apps_snoc]; exact .inl .adt
        | ctrF _ _ _ _ => rw [← Term.apps_snoc]; exact .inl .ctr
        | ref hk hlt _ => exact Check.step_ref hk hlt _
        | typ hl | qnt hl | all hl | eql hl | adtT _ _ hl | qua hl | ctr _ _ _ _ hl | rfl hl =>
          simpa [Term.tag] using hl.tag
      · cases hvs with
        | min hva hna1 hna2 hvb hnb1 hnb2 hnab _ _ =>
          exact .inl (Term.Value.min (as := [_]) hva hna1 hna2 hvb hnb1 hnb2 hnab)
        | rwt hve hne _ => rw [← Term.apps_snoc]; exact .inl (Term.Value.rwt hve hne)
        | matS hvx hnx _ => rw [← Term.apps_snoc, List.cons_append]; exact .inl (Term.Value.matS hvx hnx)
        | efqS _ _ => rw [← Term.apps_snoc]; exact .inl .efq
    · exact .inr ⟨_, .app_f hs⟩
  | appLam _ _ _ => exact .inr ⟨_, .beta⟩
  | let_ _ _ _ _ _ _ _ => exact .inr ⟨_, .let_⟩
  | eql _ _ _ _ _ _ => exact .inl (Term.Value.eql (as := []))
  | rfl _ => exact .inl (Term.Value.rfl (as := []))
  | rwt he _ _ ihe _ _ =>
    subst hΓ hL
    rcases ihe hq _root_.rfl _root_.rfl with hve | ⟨e', hs⟩
    · rcases Check.value_inv hok hq hve he with hvt | hvs
      · obtain rfl := hvt.at_eql hβ (Le.refl _)
        exact .inr ⟨_, .rwt⟩
      · exact .inl (Term.Value.rwt (as := []) hve hvs.ne_rfl)
    · exact .inr ⟨_, .rwt_e hs⟩
  | mat _ _ _ _ _ _ _ _ _ _ _ => exact .inl .mat
  | efq _ _ _ => exact .inl (Term.Value.efq (as := []))
  | cnv _ _ ih => exact ih hq hΓ hL


-- ============================================================================
-- METATHEORY §F — subject reduction (claim 2) with the erasure simulation:
-- a weak step of a closed live term at a live position of its erasure
-- keeps its type, and the erasure takes the erased image of the step (or
-- stays, when the fired beta was typed by appLam). The book of erasures
-- Book.Era carries each definition's erased body for the dref case.
-- ============================================================================

@[simp] theorem Term.era_lone (u : Term) : Term.era .Lone u = u := rfl

theorem Convs.symm (h : Convs β xs ys) : Convs β ys xs := by
  induction h with
  | nil => exact .nil
  | cons h _ ih => exact .cons h.symm ih

theorem Convs.append (h1 : Convs β xs ys) (h2 : Convs β xs' ys') :
    Convs β (xs ++ xs') (ys ++ ys') := by
  induction h1 with
  | nil => exact h2
  | cons h _ ih => exact .cons h ih

-- ----------------------------------------------------------------------------
-- Book.Era β k bs bs': bs' is bs (the suffix of β from position k) with
-- every body replaced by one of its erasures under its own equation; adts
-- are kept
-- ----------------------------------------------------------------------------

inductive Book.Era (β : Book) : Nat → Book → Book → Prop
  | nil  : Book.Era β k [] []
  | keepA : Book.Era β (k + 1) bs bs' → Book.Era β k (.adt A :: bs) (.adt A :: bs')
  | era  : Check β (Pol.std β) ⟨k, .Ref k, d.n, d.qs⟩ [] .Lone [] d.body d.ty π ub →
           Book.Era β (k + 1) bs bs' →
           Book.Era β k (.defn d :: bs) (.defn { d with body := ub } :: bs')

theorem Book.Era.tld_adt (h : Book.Era β k bs bs') :
    ∀ j A, Book.tld bs j = some (.adt A) → Book.tld bs' j = some (.adt A) := by
  induction h with
  | nil => intro j A h; cases j <;> cases h
  | keepA _ ih => intro j A h; cases j with | zero => exact h | succ j => exact ih j A h
  | era _ _ ih => intro j A h; cases j with | zero => cases h | succ j => exact ih j A h

theorem Book.Era.tld_defn (h : Book.Era β k bs bs') :
    ∀ j d, Book.tld bs j = some (.defn d) →
    ∃ ub π, Book.tld bs' j = some (.defn { d with body := ub }) ∧
      Check β (Pol.std β) ⟨k + j, .Ref (k + j), d.n, d.qs⟩ [] .Lone [] d.body d.ty π ub := by
  induction h with
  | nil => intro j d h; cases j <;> cases h
  | keepA _ ih =>
    intro j d h
    cases j with
    | zero => cases h
    | succ j => simpa [Book.tld, Nat.add_assoc, Nat.add_comm 1 j] using ih j d h
  | era hc _ ih =>
    intro j d h
    cases j with
    | zero => cases h; exact ⟨_, _, rfl, hc⟩
    | succ j => simpa [Book.tld, Nat.add_assoc, Nat.add_comm 1 j] using ih j d h

theorem Book.Era.adt (h : Book.Era β 0 β βe) (hA : Book.adt β a = some A) :
    Book.adt βe a = some A :=
  Book.tld_adt (h.tld_adt a A (Book.adt_tld hA))

theorem Book.Era.defn (h : Book.Era β 0 β βe) (hd : Book.defn β k = some d) :
    ∃ ub π, Book.defn βe k = some { d with body := ub } ∧
      Check β (Pol.std β) ⟨k, .Ref k, d.n, d.qs⟩ [] .Lone [] d.body d.ty π ub := by
  obtain ⟨ub, π, h1, h2⟩ := h.tld_defn k d (Book.defn_tld hd)
  exact ⟨ub, π, Book.tld_defn h1, by simpa using h2⟩

theorem Book.Era.exists (hb : ∀ k d, Book.defn β k = some d →
    ∃ π u, Check β (Pol.std β) ⟨k, .Ref k, d.n, d.qs⟩ [] .Lone [] d.body d.ty π u) :
    ∃ βe, Book.Era β 0 β βe := by
  suffices H : ∀ (bs : Book) (k : Nat), (∀ j t, Book.tld bs j = some t → Book.tld β (k + j) = some t) →
      ∃ bs', Book.Era β k bs bs' from H β 0 (fun j t h => by simpa using h)
  intro bs
  induction bs with
  | nil => intro k _; exact ⟨[], .nil⟩
  | cons t bs ih =>
    intro k hk
    obtain ⟨bs', hbs'⟩ := ih (k + 1)
      (fun j t h => by rw [show k + 1 + j = k + (j + 1) by omega]; exact hk (j + 1) t h)
    cases t with
    | adt A => exact ⟨_, .keepA hbs'⟩
    | defn d =>
      obtain ⟨π, u, hc⟩ := hb k d (Book.tld_defn (by simpa using hk 0 _ rfl))
      exact ⟨_, .era hc hbs'⟩

theorem Book.Ok.era (hok : Book.Ok β) : ∃ βe, Book.Era β 0 β βe :=
  Book.Era.exists fun _ _ hd => (hok.defn hd).2.2.2.2

-- ----------------------------------------------------------------------------
-- LStep β V t u t': a weak step of t at a position that is live in its
-- erasure u (a dead subterm is the token, and no rule enters a token), whose
-- fired beta or let, when the erasure shows the argument (the app-typed
-- redex: appLam types no argument), takes one satisfying V with its erasure.
-- The argument of an appLam-typed redex is not entered (app_a's head is no
-- lambda): its erasure is the contractum's, which does not show it
-- ----------------------------------------------------------------------------

inductive LStep (β : Book) (V : Term → Term → Prop) : Term → Term → Term → Prop
  | beta  : (∀ uf ua, u = .App (.Lam uf) ua → V a ua) →
            LStep β V (.App (.Lam f) a) u (Term.subst 0 a f)
  | let_  : (∀ uv ub, u = .Let q uv ub → V v uv) →
            LStep β V (.Let q v b) u (Term.subst 0 v b)
  | dref  : Book.defn β k = some d →
            (Term.spine s).1 = .Ref k → (Term.spine s).2.length = d.n →
            LStep β V s u (Term.apps d.body (Term.spine s).2)
  | aref  : Book.adt β k = some A → A.pn = 0 → LStep β V (.Ref k) u (.Adt k [])
  | matc  : Book.adt β a = some A → AdtD.ctr A c = some C →
            ps.length = A.pn → xs.length = C.fn →
            LStep β V (.App (.Mat a c h m) (Term.apps (.Ctr a c) (ps ++ xs))) u (Term.apps h xs)
  | matm  : (a', c') ≠ (a, c) →
            LStep β V (.App (.Mat a c h m) (Term.apps (.Ctr a' c') as)) u
                      (.App m (Term.apps (.Ctr a' c') as))
  | rwt   : LStep β V (.Rwt .Rfl P f) u f
  | minLM : LStep β V (.Min (.Qua .Many) b) u b
  | minLN : LStep β V (.Min (.Qua .None) b) u (.Qua .None)
  | minRM : LStep β V (.Min a (.Qua .Many)) u a
  | minRN : LStep β V (.Min a (.Qua .None)) u (.Qua .None)
  | minLL : LStep β V (.Min (.Qua .Lone) (.Qua .Lone)) u (.Qua .Lone)
  | min_a : LStep β V a ua a' → LStep β V (.Min a b) (.Min ua ub) (.Min a' b)
  | min_b : LStep β V b ub b' → LStep β V (.Min a b) (.Min ua ub) (.Min a b')
  | app_f : LStep β V f uf f' → LStep β V (.App f x) (.App uf ux) (.App f' x)
  | app_a : (∀ g, f ≠ .Lam g) → ux ≠ .Qnt → LStep β V x ux x' →
            LStep β V (.App f x) (.App uf ux) (.App f x')
  | mat_h : LStep β V h uh h' → LStep β V (.Mat a c h m) (.Mat a c uh um) (.Mat a c h' m)
  | mat_m : LStep β V m um m' → LStep β V (.Mat a c h m) (.Mat a c uh um) (.Mat a c h m')
  | rwt_e : LStep β V e ue e' → LStep β V (.Rwt e P f) (.Rwt ue uP uf) (.Rwt e' P f)
  | rwt_f : LStep β V f uf f' → LStep β V (.Rwt e P f) (.Rwt ue uP uf) (.Rwt e P f')
  | let_v : LStep β V v uv v' → uv ≠ .Qnt → LStep β V (.Let q v b) (.Let q uv ub) (.Let q v' b)

theorem LStep.step (h : LStep β V t u t') : Step β .weak t t' := by
  induction h with
  | beta _ => exact .beta
  | let_ _ => exact .let_
  | dref hk hsp hn => exact .dref hk hsp hn
  | aref hk h0 => exact .aref hk h0
  | matc hA hC hp hx => exact .matc hA hC hp hx
  | matm hne => exact .matm hne
  | rwt => exact .rwt
  | minLM => exact .minLM
  | minLN => exact .minLN
  | minRM => exact .minRM
  | minRN => exact .minRN
  | minLL => exact .minLL
  | min_a _ ih => exact .min_a ih
  | min_b _ ih => exact .min_b ih
  | app_f _ ih => exact .app_f ih
  | app_a _ _ _ ih => exact .app_a ih
  | mat_h _ ih => exact .mat_h ih
  | mat_m _ ih => exact .mat_m ih
  | rwt_e _ ih => exact .rwt_e ih
  | rwt_f _ ih => exact .rwt_f ih
  | let_v _ _ ih => exact .let_v ih

theorem LStep.lam (h : LStep β V (.Lam g) u t') : False := by
  cases h with
  | dref _ hsp _ => simp [Term.spine] at hsp

-- ----------------------------------------------------------------------------
-- the root steps, at the void equation, in the empty context, at demand
-- Lone. Each takes the redex's derivation and gives the reduct's, with the
-- erasure pinned to the erased image of the rule
-- ----------------------------------------------------------------------------

-- a closed live argument, erased to ua, entering a binder of an emptied
-- type: what the caller refutes (G's canonical forms on a value with ¬Bad,
-- N3's deep_empty on a deep erasure, normalization in general)
abbrev Check.Dead (β : Book) (a ua : Term) : Prop :=
  ∀ {A πa}, Check β (Pol.std β) (LHS.void β) [] .Lone [] a A πa ua →
    ∀ e r ps, Conv β A (Term.apps (.Adt e r) ps) → Book.empty β e r → False

theorem Quant.le_none_eq (h : Quant.le q .None) : q = .None := by
  cases q <;> simp_all [Quant.le]

theorem Check.beta (hβ : Book.Closed β)
    (h : Check β (Pol.std β) (LHS.void β) [] .Lone [] (.App (.Lam f) a) T π u)
    (hd : ∀ uf ua, u = .App (.Lam uf) ua → Check.Dead β a ua) :
    ∃ π' u', Check β (Pol.std β) (LHS.void β) [] .Lone [] (Term.subst 0 a f) T π' u' ∧
      (u' = u ∨ ∃ uf ua, u = .App (.Lam uf) ua ∧ u' = Term.subst 0 ua uf) := by
  have hΦ := Pol.std_pre hβ
  rcases h.app_inv hΦ with ⟨q', A, B, πf, uf, πa, ua, hf, ha, hle, hπ, hu⟩ | ⟨g, T0, hg, _, hb, hle⟩
  · obtain ⟨q1, A1, B1, πA, π1, uf1, hA, hb, hle1, hleF, hπf, huf⟩ := hf.lam_inv hΦ
    obtain ⟨rfl, hAA, hBB⟩ := Le.all_inv hβ hleF .refl .refl
    have hA1 : Term.Closed 0 A1 := hA.closed
    have hres : Check β (Pol.std β) (LHS.void β) [] .Lone [] (Term.subst 0 a f)
        (Term.subst 0 a B1) (Uses.del 0 π1) (Term.subst 0 ua uf1) := by
      by_cases hq : q1 = .None
      · subst hq
        exact Check.subst_std hβ (Γ := []) (b0 := ⟨.None, A1, none⟩) hb (by decide) ha.closed
          ha.closed_era (.inl _root_.rfl) (ha.dead.cnv hAA)
          (fun hne => absurd (Quant.le_none_eq hle1) hne) (fun h => absurd _root_.rfl h)
      · rw [Quant.dem_live hq] at ha
        exact Check.subst_std hβ (Γ := []) (b0 := ⟨q1, A1, none⟩) hb (by decide) ha.closed
          ha.closed_era (.inl _root_.rfl) (ha.dead.cnv hAA) (fun _ => ⟨πa, ha.cnv hAA⟩)
          (fun _ m e r ps hred hemp => hd uf1 ua (by subst hu huf; rfl) (ha.cnv hAA) e r ps
            (by rwa [Term.shiftN_closed hA1] at hred) hemp)
    subst hu huf
    exact ⟨_, _, hres.cnv (Le.trans hβ (Le.subst hβ hBB 0 a) hle), .inr ⟨uf1, ua, _root_.rfl, _root_.rfl⟩⟩
  · cases hg; exact ⟨π, u, .cnv hb hle, .inl _root_.rfl⟩

theorem Check.let_step (hβ : Book.Closed β)
    (h : Check β (Pol.std β) (LHS.void β) [] .Lone [] (.Let qb v b) T π u)
    (hd : ∀ uv ub, u = .Let qb uv ub → Check.Dead β v uv) :
    ∃ π' uv ub, Check β (Pol.std β) (LHS.void β) [] .Lone [] (Term.subst 0 v b) T π'
      (Term.subst 0 uv ub) ∧ u = .Let qb uv ub := by
  have hΦ := Pol.std_pre hβ
  obtain ⟨A, T0, πv, uv, πA, π1, ub, hv, hA, hb, hle1, hle, hπ, hu⟩ := h.let_inv hΦ
  have hA0 : Term.Closed 0 A := hA.closed
  have hres : Check β (Pol.std β) (LHS.void β) [] .Lone [] (Term.subst 0 v b)
      (Term.subst 0 v (Term.shift 0 T0)) (Uses.del 0 π1) (Term.subst 0 uv ub) := by
    by_cases hq : qb = .None
    · subst hq
      exact Check.subst_std hβ (Γ := []) (b0 := ⟨.None, A, some v⟩) hb (by decide) hv.closed
        hv.closed_era (.inr _root_.rfl) hv.dead
        (fun hne => absurd (Quant.le_none_eq hle1) hne) (fun h => absurd _root_.rfl h)
    · rw [Quant.dem_live hq] at hv
      exact Check.subst_std hβ (Γ := []) (b0 := ⟨qb, A, some v⟩) hb (by decide) hv.closed
        hv.closed_era (.inr _root_.rfl) hv.dead (fun _ => ⟨πv, hv⟩)
        (fun _ m e r ps hred hemp => hd uv ub (by subst hu; rfl) hv e r ps
          (by rwa [Term.shiftN_closed hA0] at hred) hemp)
  rw [Term.subst_shift] at hres
  subst hu
  exact ⟨_, uv, ub, hres.cnv hle, _root_.rfl⟩

theorem Check.dref_step (hβ : Book.Closed β) (hE : Book.Era β 0 β βe)
    (hk : Book.defn β k = some d)
    (h : Check β (Pol.std β) (LHS.void β) [] .Lone [] (Term.apps (.Ref k) as) T π u) :
    ∃ π' ub us, Check β (Pol.std β) (LHS.void β) [] .Lone [] (Term.apps d.body as) T π' (Term.apps ub us) ∧
      u = Term.apps (.Ref k) us ∧ us.length = as.length ∧
      Book.defn βe k = some { d with body := ub } := by
  have hΦ := Pol.std_pre hβ
  obtain ⟨T0, π0, u0, T1, πs, us, hhead, hargs, hle, hπ, hu⟩ :=
    h.apps_inv hΦ as (.Ref k) (fun _ e => Term.noConfusion e)
  rcases hhead.ref_inv hΦ with ⟨d', hk', _, _, hle0, hπ0, hu0⟩ | ⟨A, hA, _⟩
  · rw [hk] at hk'; cases hk'
    obtain ⟨ub, πb, hkE, hc⟩ := hE.defn hk
    have hres := Check.apps ((hc.void_sp (as ++ [])).cnv hle0) hargs
    subst hu hu0
    exact ⟨_, ub, us, hres.cnv hle, _root_.rfl, hargs.length, hkE⟩
  · exact (Book.defn_adt_clash hk hA).elim

theorem Check.aref_step (hβ : Book.Closed β) (hA : Book.adt β k = some A)
    (h : Check β (Pol.std β) (LHS.void β) [] .Lone [] (.Ref k) T π u) :
    Check β (Pol.std β) (LHS.void β) [] .Lone [] (.Adt k []) T Uses.zero (.Adt k []) ∧
      u = .Ref k := by
  rcases h.ref_inv (Pol.std_pre hβ) with ⟨d, hd, _⟩ | ⟨A', hA', _, hle, _, hu⟩
  · exact (Book.defn_adt_clash hd hA).elim
  · rw [hA] at hA'; cases hA'; subst hu; exact ⟨(Check.adt hA).cnv hle, _root_.rfl⟩

theorem Check.rwt_step (hβ : Book.Closed β)
    (h : Check β (Pol.std β) (LHS.void β) [] .Lone [] (.Rwt .Rfl P f) T π u) :
    ∃ π' uf, Check β (Pol.std β) (LHS.void β) [] .Lone [] f T π' uf ∧ u = .Rwt .Rfl .Qnt uf := by
  have hΦ := Pol.std_pre hβ
  obtain ⟨a, b, T0, πe, ue, πP, πf, uf, he, _, hf, hle, _, hu⟩ := h.rwt_inv hΦ
  obtain ⟨a1, b1, T1, hab, hleE, _, hue⟩ := he.rfl_inv hΦ
  obtain ⟨hca, hcb, _⟩ := Le.eql_inv hβ hleE .refl .refl
  have hab' : Conv β a b := (hca.symm.trans hβ hab).trans hβ hcb
  subst hu hue
  exact ⟨πf, uf, hf.cnv (Le.trans hβ (.conv (Conv.app (Conv.app (Conv.refl P) hab') (Conv.refl _))) hle),
    _root_.rfl⟩

-- the constructor walk rebuilt along the shaped telescope with any re-tipping:
-- the same arguments, the same measures and erasures, tipped at the family
-- with that residual (matm re-checks a mismatched scrutinee at the peeled tail)
theorem Args.rebuild (hβ : Book.Closed β) :
    ∀ {as : List Term} {pn fn : Nat} {ps : List Term} {Tw T0 T1 : Term} {πs : Uses} {us : List Term},
    WTele a r ps pn fn Tw → Args β (Pol.std β) L q Γ T0 as T1 πs us →
    Le β (Ctx.δ Γ 0 (Term.retip r1 pn (pn + fn) Tw)) (Ctx.δ Γ 0 T0) → as.length = pn + fn →
    ∀ r2, Args β (Pol.std β) L q Γ (Term.retip r2 pn (pn + fn) Tw) as
      (Term.apps (.Adt a r2) (ps ++ as.take pn)) πs us := by
  intro as
  induction as with
  | nil =>
    intro pn fn ps Tw T0 T1 πs us hw h hle hlen r2
    cases h
    cases pn with
    | zero =>
      cases fn with
      | zero =>
        simp only [WTele, FTele] at hw; subst hw
        rw [Term.retip_adt_apps]; simpa using Args.nil
      | succ fk => rw [List.length_nil] at hlen; omega
    | succ pk => rw [List.length_nil] at hlen; omega
  | cons x as ih =>
    intro pn fn ps Tw T0 T1 πs us hw h hle hlen r2
    cases pn with
    | succ pk =>
      obtain ⟨qw, K, Bw, hT, hwB, hw'⟩ := WTele.param (x := x) hw
      subst hT
      rw [show pk + 1 + fn = pk + fn + 1 by omega] at hle ⊢
      obtain ⟨πx, ux, πs', us', B1, rfl, rfl, hx, hB, hr⟩ :=
        Args.step hβ (qw := .None) (K := K) (Bw := Term.retip r1 pk (pk + fn) Bw) hle h
      rw [WTele.retip_subst hwB r1 0 x] at hB
      have := ih hw' hr hB (by simp at hlen; omega) r2
      show Args β (Pol.std β) L q Γ (.All .None K (Term.retip r2 pk (pk + fn) Bw)) (x :: as) _ _ _
      refine .cons (Le.refl _) hx ?_
      rw [WTele.retip_subst hwB r2 0 x]
      simpa [List.take, List.append_assoc] using this
    | zero =>
      cases fn with
      | zero => rw [List.length_cons] at hlen; omega
      | succ fk =>
        obtain ⟨qf, F, Bw, hT, hFB, hw'⟩ := FTele.field (x := x) hw
        subst hT
        rw [Nat.zero_add] at hle ⊢
        obtain ⟨πx, ux, πs', us', B1, rfl, rfl, hx, hB, hr⟩ :=
          Args.step hβ (qw := qf) (K := F) (Bw := Term.retip r1 0 fk Bw) hle h
        rw [FTele.retip_subst hFB r1 0 x] at hB
        have := ih (pn := 0) hw' hr (by simpa using hB) (by simp at hlen; omega) r2
        rw [Nat.zero_add] at this
        show Args β (Pol.std β) L q Γ (.All qf F (Term.retip r2 0 fk Bw)) (x :: as) _ _ _
        refine .cons (Le.refl _) hx ?_
        rw [FTele.retip_subst hFB r2 0 x]
        simpa using this

theorem Book.Ok.shape (hok : Book.Ok β) (hA : Book.adt β a = some A) (hC : AdtD.ctr A c = some C) :
    CtrD.Shape a A.pn C := by
  obtain ⟨_, _, _, hctrs⟩ := hok a _ (Book.adt_tld hA)
  exact (hctrs c C hC).1

theorem Check.matc_step (hok : Book.Ok β)
    (hA : Book.adt β a = some A) (hC : AdtD.ctr A c = some C)
    (hps : ps.length = A.pn) (hxs : xs.length = C.fn)
    (h : Check β (Pol.std β) (LHS.void β) [] .Lone []
      (.App (.Mat a c hh mm) (Term.apps (.Ctr a c) (ps ++ xs))) T π u) :
    ∃ π' uh um up ux, Check β (Pol.std β) (LHS.void β) [] .Lone [] (Term.apps hh xs) T π'
        (Term.apps uh ux) ∧
      u = .App (.Mat a c uh um) (Term.apps (.Ctr a c) (up ++ ux)) ∧
      up.length = A.pn ∧ ux.length = C.fn := by
  have hβ := hok.closed
  have hΦ := Pol.std_pre hβ
  rcases h.app_inv hΦ with ⟨q1, A1, B1, πf, uf, πx, ux, hf, hx, hle, hπ, hu⟩ | ⟨g, _, hg, _⟩
  · obtain ⟨A', C', r, ps', q', telF, B, G, πh, uh, πm, um, hA', hC', hr, hlen, hlive, hI, hg,
      hh0, hm0, hleM, hπf, huf⟩ := hf.mat_inv hΦ
    rw [hA] at hA'; cases hA'; rw [hC] at hC'; cases hC'
    obtain ⟨rfl, hA1, hB1⟩ := Le.all_inv hβ hleM .refl .refl
    obtain ⟨T0, π0, u0, T1, πs, us, hhead, hargs, hleT1, hπx, hux⟩ :=
      hx.apps_inv hΦ (ps ++ xs) (.Ctr a c) (fun _ e => Term.noConfusion e)
    obtain ⟨A'', C'', r0, hA'', hC'', hr0, hleR, hπ0, hu0⟩ := hhead.ctr_inv hΦ
    rw [hA] at hA''; cases hA''; rw [hC] at hC''; cases hC''
    obtain ⟨Tm, πp, up, πq, uq, hargsP, hargsF, hπs, hus⟩ := hargs.split
    obtain ⟨TS0, hI0, hF0, hleTS⟩ := Args.params hβ (r' := r0) (hok.shape hA hC) hargsP hleR hps
    obtain ⟨hargsF', htip⟩ := Args.ftele hβ hF0 hargsF hleTS hxs
    obtain ⟨_, _, hconvs⟩ := Le.adt_inv hβ (Le.trans hβ htip (Le.trans hβ hleT1 hA1)) .refl .refl
    simp only [List.nil_append] at hconvs hargsF'
    have hconvT : Conv β telF TS0 := (Insts.conv hβ hI0 hI (Conv.refl _) hconvs).symm
    have hG := MatGoal.apply hβ C.fn hg hlive hargsF' (Le.conv hconvT) hxs
    have hres := Check.apps (hh0.void_sp (xs ++ [])) hG
    refine ⟨_, uh, um, up, uq, hres.cnv (Le.trans hβ ?_ hle), ?_, ?_, ?_⟩
    · rw [← Term.apps_append]
      exact Le.substR hβ hB1 (Conv.apps (Conv.refl _) (Convs.append hconvs.symm (Convs.refl xs))) 0
    · rw [Quant.dem_live (hlive (by decide))] at hux hu0
      subst hu huf hux hu0 hus; rfl
    · rw [hargsP.length, hps]
    · rw [hargsF.length, hxs]
  · exact Term.noConfusion hg

theorem Check.matm_step (hok : Book.Ok β) (hne : (a', c') ≠ (a, c))
    (h : Check β (Pol.std β) (LHS.void β) [] .Lone []
      (.App (.Mat a c hh mm) (Term.apps (.Ctr a' c') as)) T π u) :
    ∃ π' uh um us, Check β (Pol.std β) (LHS.void β) [] .Lone []
        (.App mm (Term.apps (.Ctr a' c') as)) T π' (.App um (Term.apps (.Ctr a' c') us)) ∧
      u = .App (.Mat a c uh um) (Term.apps (.Ctr a' c') us) := by
  have hβ := hok.closed
  have hΦ := Pol.std_pre hβ
  rcases h.app_inv hΦ with ⟨q1, A1, B1, πf, uf, πx, ux, hf, hx, hle, hπ, hu⟩ | ⟨g, _, hg, _⟩
  · obtain ⟨A0, C0, r, ps, q', telF, B, G, πh, uh, πm, um, hA0, hC0, hr, hlen, hlive, hI, hg,
      hh0, hm0, hleM, hπf, huf⟩ := hf.mat_inv hΦ
    obtain ⟨rfl, hA1, hB1⟩ := Le.all_inv hβ hleM .refl .refl
    have hq' := Quant.dem_live (q := .Lone) (hlive (by decide))
    rw [hq'] at hx
    obtain ⟨T0, π0, u0, T1, πs, us, hhead, hargs, hleT1, hπx, hux⟩ :=
      hx.apps_inv hΦ as (.Ctr a' c') (fun _ e => Term.noConfusion e)
    obtain ⟨A2, C2, r0, hA2, hC2, hr0, hleR, hπ0, hu0⟩ := hhead.ctr_inv hΦ
    have hshape := hok.shape hA2 hC2
    rcases Args.wtele hβ (WTele.retip r0 hshape) hargs hleR with ⟨_, qA, X, Y, hall⟩ | ⟨hlenAs, hadt⟩
    · exact absurd (Le.trans hβ hall (Le.trans hβ hleT1 hA1)) Le.all_adt
    · obtain ⟨rfl, hsub, hconvs⟩ :=
        Le.adt_inv hβ (Le.trans hβ hadt (Le.trans hβ hleT1 hA1)) .refl .refl
      simp only [List.nil_append] at hconvs
      have hcc : c' ≠ c := fun e => hne (by rw [e])
      have hargs' := Args.rebuild hβ hshape hargs hleR hlenAs (c :: r0)
      simp only [List.nil_append] at hargs'
      have hhead' := Check.ctr (β := β) (Φ := Pol.std β) (L := LHS.void β) (sp := as ++ [])
        (q := .Lone) (Γ := []) (r := c :: r0) hA2 hC2 (fun hm => by
          rcases List.mem_cons.mp hm with e | e
          · exact hcc e
          · exact hr0 e)
      have hscr := (Check.apps hhead' hargs').cnv
        (Le.adt (r := c :: r0) (r' := c :: r) (ps := as.take A2.pn) (ps' := ps)
          (fun x hx => by
            rcases List.mem_cons.mp hx with e | e
            · exact e ▸ List.mem_cons_self
            · exact List.mem_cons_of_mem _ (hsub x e))
          hconvs.length hconvs.get)
      rw [← hq'] at hscr
      have hres := Check.app (hm0.void_sp [_]) hscr
      rw [hq'] at hres
      refine ⟨_, uh, um, us, hres.cnv (Le.trans hβ (Le.subst hβ hB1 0 _) hle), ?_⟩
      subst hu huf hux hu0; rfl
  · exact Term.noConfusion hg

-- ----------------------------------------------------------------------------
-- typing transports along the reduction of a let-bound value in the context:
-- every δ-expanded term strong-reduces to its expansion with the reduct, so
-- the Le tests move by Le.red_l/red_r and the ex-falso test by Conv.red_l
-- ----------------------------------------------------------------------------

-- contexts that differ only by strong reduction of their let values
inductive Ctx.Red (β : Book) : Ctx → Ctx → Prop
  | nil   : Ctx.Red β [] []
  | rigid : Ctx.Red β Γ Γ' → Ctx.Red β (⟨q, T, none⟩ :: Γ) (⟨q, T, none⟩ :: Γ')
  | val   : BendCore.Red β .strong v v' → Ctx.Red β Γ Γ' →
            Ctx.Red β (⟨q, T, some v⟩ :: Γ) (⟨q, T, some v'⟩ :: Γ')

theorem Ctx.Red.length (h : Ctx.Red β Γ Γ') : Γ'.length = Γ.length := by
  induction h <;> simp [*]

theorem Ctx.Red.get (h : Ctx.Red β Γ Γ') : ∀ i b, Ctx.get Γ i = some b →
    ∃ b', Ctx.get Γ' i = some b' ∧ b'.q = b.q ∧ b'.T = b.T := by
  induction h with
  | nil => intro i b hg; cases i <;> cases hg
  | @rigid Γ0 _ _ _ _ ih =>
    intro i b hg
    cases i with
    | zero => cases hg; exact ⟨_, rfl, rfl, rfl⟩
    | succ i =>
      simp only [Ctx.get] at hg ⊢
      cases hg0 : Ctx.get Γ0 i with
      | none => rw [hg0] at hg; cases hg
      | some b0 =>
        rw [hg0] at hg; cases hg
        obtain ⟨b0', hg', hq, hT⟩ := ih i b0 hg0
        exact ⟨b0'.shift, by rw [hg']; rfl, hq, by simp [Bind.shift, hT]⟩
  | @val _ _ Γ0 _ _ _ _ _ ih =>
    intro i b hg
    cases i with
    | zero => cases hg; exact ⟨_, rfl, rfl, rfl⟩
    | succ i =>
      simp only [Ctx.get] at hg ⊢
      cases hg0 : Ctx.get Γ0 i with
      | none => rw [hg0] at hg; cases hg
      | some b0 =>
        rw [hg0] at hg; cases hg
        obtain ⟨b0', hg', hq, hT⟩ := ih i b0 hg0
        exact ⟨b0'.shift, by rw [hg']; rfl, hq, by simp [Bind.shift, hT]⟩

theorem Red.shiftN (hβ : Book.Closed β) (r : Red β p a b) :
    ∀ n, Red β p (Term.shiftN n a) (Term.shiftN n b)
  | 0 => r
  | n + 1 => (Red.shiftN hβ r n).shift hβ 0

theorem Ctx.Red.δ (hβ : Book.Closed β) (h : Ctx.Red β Γ Γ') :
    ∀ d t, BendCore.Red β .strong (Ctx.δ Γ d t) (Ctx.δ Γ' d t) := by
  induction h with
  | nil => intro d t; exact .refl
  | rigid _ ih => intro d t; exact ih (d + 1) t
  | val r _ ih =>
    intro d t
    exact (Ctx.δ_red hβ _ d (Red.substR hβ (r.shiftN hβ d) d t)).trans (ih d _)

theorem CtxDead.red (hβ : Book.Closed β) (h : Ctx.Red β Γ Γ') (hd : CtxDead β Γ) :
    CtxDead β Γ' := by
  obtain ⟨i, b, a, r, ps, hg, hq, hc, hemp⟩ := hd
  obtain ⟨b', hg', hq', hT⟩ := h.get i b hg
  refine ⟨i, b', a, r, ps, hg', fun e => hq (hq'.symm.trans e), ?_, hemp⟩
  rw [hT]; exact Conv.red_l hβ (h.δ hβ 0 b.T) hc

theorem Check.red_bind (hβ : Book.Closed β) {sp : List Term}
    (h : Check β (Pol.std β) L sp q Γ t T π u) :
    ∀ Γ', Ctx.Red β Γ Γ' → Check β (Pol.std β) (LHS.void β) sp q Γ' t T π u := by
  induction h with
  | var hg =>
    intro Γ' hΓ
    obtain ⟨b', hg', _, hT⟩ := hΓ.get _ _ hg
    rw [← hT]; exact .var hg'
  | ref hk _ _ =>
    intro Γ' _
    have hj := Book.defn_lt hk
    exact .ref hk (fun _ => Nat.le_of_lt hj) (fun _ he => absurd he (Nat.ne_of_lt hj))
  | refA hk h0 => intro Γ' _; exact .refA hk h0
  | adt hk => intro Γ' _; exact .adt hk
  | ctr hk hc hr => intro Γ' _; exact .ctr hk hc hr
  | typ _ ihg => intro Γ' hΓ; exact .typ (ihg _ hΓ)
  | qnt => intro Γ' _; exact .qnt
  | qua => intro Γ' _; exact .qua
  | min _ _ iha ihb => intro Γ' hΓ; exact .min (iha _ hΓ) (ihb _ hΓ)
  | all _ _ ihA ihB => intro Γ' hΓ; exact .all (ihA _ hΓ) (ihB _ (.rigid hΓ))
  | lam _ _ hle ihA ihf => intro Γ' hΓ; exact .lam (ihA _ hΓ) (ihf _ (.rigid hΓ)) hle
  | app _ _ ihf ihx => intro Γ' hΓ; exact .app (ihf _ hΓ) (ihx _ hΓ)
  | appLam ha _ ih => intro Γ' hΓ; exact .appLam (by rw [hΓ.length]; exact ha) (ih _ hΓ)
  | let_ _ _ _ hle ihv ihA ihb =>
    intro Γ' hΓ; exact .let_ (ihv _ hΓ) (ihA _ hΓ) (ihb _ (.val .refl hΓ)) hle
  | eql _ _ _ ihT iha ihb => intro Γ' hΓ; exact .eql (ihT _ hΓ) (iha _ hΓ) (ihb _ hΓ)
  | rfl hc =>
    intro Γ' hΓ
    exact .rfl (Conv.red_r hβ (hΓ.δ hβ 0 _) (Conv.red_l hβ (hΓ.δ hβ 0 _) hc))
  | rwt _ _ _ ihe ihP ihf => intro Γ' hΓ; exact .rwt (ihe _ hΓ) (ihP _ hΓ) (ihf _ hΓ)
  | mat hk hc hr hlen hlive hins hgoal _ _ ihh ihm =>
    intro Γ' hΓ; exact .mat hk hc hr hlen hlive hins hgoal (ihh _ hΓ) (ihm _ hΓ)
  | efq hk hlive hd => intro Γ' hΓ; exact .efq hk hlive (hd.imp_right (CtxDead.red hβ hΓ))
  | cnv _ hc iht =>
    intro Γ' hΓ
    exact .cnv (iht _ hΓ) (Le.red_r hβ (hΓ.δ hβ 0 _) (Le.red_l hβ (hΓ.δ hβ 0 _) hc))

theorem Step.dref_apps (hk : Book.defn β k = some d) (hn : as.length = d.n) :
    Step β p (Term.apps (.Ref k) as) (Term.apps d.body as) := by
  have := Step.dref (β := β) (p := p) (s := Term.apps (.Ref k) as) hk
    (by rw [Term.spine_apps (by trivial)]) (by rw [Term.spine_apps (by trivial)]; simpa using hn)
  rwa [Term.spine_apps (by trivial)] at this

-- ----------------------------------------------------------------------------
-- subject reduction with the erasure simulation: a live-position weak step
-- of a closed live term keeps its type, and the erasure takes the erased
-- image of the step in the book of erasures, or stays when the fired beta
-- was typed by appLam
-- ----------------------------------------------------------------------------

theorem Check.step (hok : Book.Ok β) (hE : Book.Era β 0 β βe)
    (hV : ∀ {a ua A πa}, V a ua → Check β (Pol.std β) (LHS.void β) [] .Lone [] a A πa ua →
      ∀ e r ps, Conv β A (Term.apps (.Adt e r) ps) → Book.empty β e r → False)
    (hs : LStep β V t u t') :
    ∀ {T π}, Check β (Pol.std β) (LHS.void β) [] .Lone [] t T π u →
    ∃ π' u', Check β (Pol.std β) (LHS.void β) [] .Lone [] t' T π' u' ∧
      (Step βe .weak u u' ∨ u' = u) := by
  have hβ := hok.closed
  have hΦ := Pol.std_pre hβ
  induction hs with
  | beta hv =>
    intro T π h
    obtain ⟨π', u', h', hu⟩ := Check.beta hβ h (fun uf ua e => hV (hv uf ua e))
    rcases hu with rfl | ⟨uf, ua, rfl, rfl⟩
    · exact ⟨π', _, h', .inr _root_.rfl⟩
    · exact ⟨π', _, h', .inl .beta⟩
  | let_ hv =>
    intro T π h
    obtain ⟨π', uv, ub, h', rfl⟩ := Check.let_step hβ h (fun uv ub e => hV (hv uv ub e))
    exact ⟨_, _, h', .inl .let_⟩
  | @dref k d s _ hk hsp hn =>
    intro T π h
    have hs : s = Term.apps (.Ref k) (Term.spine s).2 := by
      have := Term.apps_spine s; rw [hsp] at this; exact this.symm
    rw [hs] at h
    obtain ⟨π', ub, us, h', rfl, hlen, hkE⟩ := Check.dref_step hβ hE hk h
    exact ⟨_, _, h', .inl (Step.dref_apps hkE (hlen.trans hn))⟩
  | aref hk h0 =>
    intro T π h
    obtain ⟨h', rfl⟩ := Check.aref_step hβ hk h
    exact ⟨_, _, h', .inl (.aref (hE.adt hk) h0)⟩
  | matc hA hC hps hxs =>
    intro T π h
    obtain ⟨π', uh, um, up, ux, h', rfl, hup, hux⟩ := Check.matc_step hok hA hC hps hxs h
    exact ⟨_, _, h', .inl (.matc (hE.adt hA) hC hup hux)⟩
  | matm hne =>
    intro T π h
    obtain ⟨π', uh, um, us, h', rfl⟩ := Check.matm_step hok hne h
    exact ⟨_, _, h', .inl (.matm hne)⟩
  | rwt =>
    intro T π h
    obtain ⟨π', uf, h', rfl⟩ := Check.rwt_step hβ h
    exact ⟨_, _, h', .inl .rwt⟩
  | minLM =>
    intro T π h
    obtain ⟨πa, ua, πb, ub, ha, hb, hle, -, hu⟩ := h.min_inv hΦ
    obtain ⟨-, -, hua⟩ := ha.qua_inv hΦ
    subst hu hua
    exact ⟨_, _, hb.cnv hle, .inl .minLM⟩
  | minLN =>
    intro T π h
    obtain ⟨πa, ua, πb, ub, ha, hb, hle, -, hu⟩ := h.min_inv hΦ
    obtain ⟨-, -, hua⟩ := ha.qua_inv hΦ
    subst hu hua
    exact ⟨_, _, Check.qua.cnv hle, .inl .minLN⟩
  | minRM =>
    intro T π h
    obtain ⟨πa, ua, πb, ub, ha, hb, hle, -, hu⟩ := h.min_inv hΦ
    obtain ⟨-, -, hub⟩ := hb.qua_inv hΦ
    subst hu hub
    exact ⟨_, _, ha.cnv hle, .inl .minRM⟩
  | minRN =>
    intro T π h
    obtain ⟨πa, ua, πb, ub, ha, hb, hle, -, hu⟩ := h.min_inv hΦ
    obtain ⟨-, -, hub⟩ := hb.qua_inv hΦ
    subst hu hub
    exact ⟨_, _, Check.qua.cnv hle, .inl .minRN⟩
  | minLL =>
    intro T π h
    obtain ⟨πa, ua, πb, ub, ha, hb, hle, -, hu⟩ := h.min_inv hΦ
    obtain ⟨-, -, hua⟩ := ha.qua_inv hΦ
    obtain ⟨-, -, hub⟩ := hb.qua_inv hΦ
    subst hu hua hub
    exact ⟨_, _, Check.qua.cnv hle, .inl .minLL⟩
  | min_a _ ih =>
    intro T π h
    obtain ⟨πa, ua, πb, ub, ha, hb, hle, -, hu⟩ := h.min_inv hΦ
    simp only [Term.era_lone] at hu; cases hu
    obtain ⟨πa', ua', ha', hs⟩ := ih ha
    refine ⟨_, _, (Check.min ha' hb).cnv hle, ?_⟩
    rcases hs with hs | rfl
    · exact .inl (.min_a hs)
    · exact .inr _root_.rfl
  | min_b _ ih =>
    intro T π h
    obtain ⟨πa, ua, πb, ub, ha, hb, hle, -, hu⟩ := h.min_inv hΦ
    simp only [Term.era_lone] at hu; cases hu
    obtain ⟨πb', ub', hb', hs⟩ := ih hb
    refine ⟨_, _, (Check.min ha hb').cnv hle, ?_⟩
    rcases hs with hs | rfl
    · exact .inl (.min_b hs)
    · exact .inr _root_.rfl
  | app_f hstep ih =>
    intro T π h
    rcases h.app_inv hΦ with ⟨q', A, B, πf, uf, πx, ux, hf, hx, hle, -, hu⟩ | ⟨g, _, rfl, -⟩
    · simp only [Term.era_lone] at hu; cases hu
      obtain ⟨πf', uf', hf', hs⟩ := ih (hf.sp [])
      refine ⟨_, _, (Check.app (hf'.sp [_]) hx).cnv hle, ?_⟩
      rcases hs with hs | rfl
      · exact .inl (.app_f hs)
      · exact .inr _root_.rfl
    · exact hstep.lam.elim
  | app_a hnl hne hstep ih =>
    intro T π h
    rcases h.app_inv hΦ with ⟨q', A, B, πf, uf, πx, ux, hf, hx, hle, -, hu⟩ | ⟨g, _, hg, -⟩
    · simp only [Term.era_lone] at hu; cases hu
      have hq' : q' ≠ .None := fun e => hne (by subst e; exact hx.none_era _root_.rfl)
      rw [Quant.dem_live hq'] at hx
      obtain ⟨πx', ux', hx', hs⟩ := ih hx
      rw [← Quant.dem_live (q := .Lone) hq'] at hx'
      have hconv : Conv β (Term.subst 0 _ B) (Term.subst 0 _ B) :=
        Conv.substR hβ (Conv.of_red_rev (Red.one hstep.step.strong)) 0 B
      refine ⟨_, _, (Check.app (hf.sp [_]) hx').cnv (Le.trans hβ (.conv hconv) hle), ?_⟩
      rcases hs with hs | rfl
      · exact .inl (.app_a hs)
      · exact .inr _root_.rfl
    · exact absurd hg (hnl g)
  | mat_h _ ih =>
    intro T π h
    obtain ⟨A, C, r, ps, q', telF, B, G, πh, uh, πm, um, hA, hC, hr, hlen, hlive, hI, hg, hh, hm,
      hle, -, hu⟩ := h.mat_inv hΦ
    simp only [Term.era_lone] at hu; cases hu
    obtain ⟨πh', uh', hh', hs⟩ := ih hh
    refine ⟨_, _, (Check.mat hA hC hr hlen hlive hI hg hh' hm).cnv hle, ?_⟩
    rcases hs with hs | rfl
    · exact .inl (.mat_h hs)
    · exact .inr _root_.rfl
  | mat_m _ ih =>
    intro T π h
    obtain ⟨A, C, r, ps, q', telF, B, G, πh, uh, πm, um, hA, hC, hr, hlen, hlive, hI, hg, hh, hm,
      hle, -, hu⟩ := h.mat_inv hΦ
    simp only [Term.era_lone] at hu; cases hu
    obtain ⟨πm', um', hm', hs⟩ := ih hm
    refine ⟨_, _, (Check.mat hA hC hr hlen hlive hI hg hh hm').cnv hle, ?_⟩
    rcases hs with hs | rfl
    · exact .inl (.mat_m hs)
    · exact .inr _root_.rfl
  | @rwt_e e ue e' P f uP uf hstep ih =>
    intro T π h
    obtain ⟨a, b, T0, πe, ue, πP, πf, uf, he, hP, hf, hle, -, hu⟩ := h.rwt_inv hΦ
    simp only [Term.era_lone] at hu; cases hu
    obtain ⟨πe', ue', he', hs⟩ := ih he
    have hconv : Conv β (.App (.App P b) _) (.App (.App P b) _) :=
      Conv.app (Conv.refl _) (Conv.of_red_rev (Red.one hstep.step.strong))
    refine ⟨_, _, (Check.rwt he' hP hf).cnv (Le.trans hβ (.conv hconv) hle), ?_⟩
    rcases hs with hs | rfl
    · exact .inl (.rwt_e hs)
    · exact .inr _root_.rfl
  | rwt_f _ ih =>
    intro T π h
    obtain ⟨a, b, T0, πe, ue, πP, πf, uf, he, hP, hf, hle, -, hu⟩ := h.rwt_inv hΦ
    simp only [Term.era_lone] at hu; cases hu
    obtain ⟨πf', uf', hf', hs⟩ := ih hf
    refine ⟨_, _, (Check.rwt he hP hf').cnv hle, ?_⟩
    rcases hs with hs | rfl
    · exact .inl (.rwt_f hs)
    · exact .inr _root_.rfl
  | @let_v v uv v' qb b ub hstep hne ih =>
    intro T π h
    obtain ⟨A, T0, πv, uv0, πA, π1, ub0, hv, hA, hb, hle1, hle, -, hu⟩ := h.let_inv hΦ
    simp only [Term.era_lone] at hu; cases hu
    have hq : qb ≠ .None := fun e => hne (by subst e; exact hv.none_era _root_.rfl)
    rw [Quant.dem_live hq] at hv
    obtain ⟨πv', uv', hv', hs⟩ := ih hv
    rw [← Quant.dem_live (q := .Lone) hq] at hv'
    have hb' := hb.red_bind hβ [⟨qb, A, some v'⟩] (.val (Red.one hstep.step.strong) .nil)
    refine ⟨_, _, (Check.let_ hv' hA hb' hle1).cnv hle, ?_⟩
    rcases hs with hs | rfl
    · exact .inl (.let_v hs)
    · exact .inr _root_.rfl



-- ============================================================================
-- METATHEORY §N0 — the erasure world: what the machine's strategy sees.
-- The engine runs on the elaborated terms (Check's output u) of a filled
-- book: closed terms whose dead parts are the token Quant. It never reads
-- a type again; the typing derivation of the subject rides alongside only
-- to supply three facts at the right moments (progress, the affine
-- occurrence bound, and the shape of Data values).
-- ============================================================================

-- Deep β u: a deep value, the strategy's normal form — a weak-head value
-- whose spine arguments are deep, recursively
mutual
inductive Deep (β : Book) : Term → Prop
  | qnt   : Deep β .Qnt
  | typ   : Deep β (.Typ g)
  | qua   : Deep β (.Qua q)
  | all   : Deep β (.All q A B)
  | eql   : Deep β (.Eql a b T)
  | rfl   : Deep β .Rfl
  | lam   : Deep β (.Lam f)
  | mat   : Deep β (.Mat a c h m)
  | efq   : Deeps β us → Deep β (Term.apps .Efq us)
  | ctr   : Deeps β us → Deep β (Term.apps (.Ctr a c) us)
  | adt   : Deeps β us → Deep β (Term.apps (.Adt a r) us)
  | fam   : Book.adt β k = some A → 0 < A.pn → Deeps β us →
            Deep β (Term.apps (.Ref k) us)
  | ref   : Book.defn β k = some d → us.length < d.n → Deeps β us →
            Deep β (Term.apps (.Ref k) us)
  | rwt   : Deep β e → e ≠ .Rfl → Deeps β us → Deep β (Term.apps (.Rwt e P f) us)
  | matS  : Deep β x → (∀ a' c' xs, x ≠ Term.apps (.Ctr a' c') xs) → Deeps β us →
            Deep β (Term.apps (.Mat a c h m) (x :: us))
  | min   : Deep β a → a ≠ .Qua .Many → a ≠ .Qua .None →
            Deep β b → b ≠ .Qua .Many → b ≠ .Qua .None →
            ¬ (a = .Qua .Lone ∧ b = .Qua .Lone) →
            Deep β (.Min a b)
inductive Deeps (β : Book) : List Term → Prop
  | nil  : Deeps β []
  | cons : Deep β u → Deeps β us → Deeps β (u :: us)
end

-- csize β u: the constructor size of a value along its declared fields
-- (the last C.fn spine arguments of a constructor spine; parameters and
-- everything else count nothing, so a column pattern rebuilt from its
-- fields alone measures as the full spine did). A field is strictly
-- smaller than its constructor, and two values with the same field
-- skeleton measure the same: that is all the descent needs
noncomputable def Term.csize (β : Book) (u : Term) : Nat :=
  match _h : Term.spine u with
  | (.Ctr a c, us) =>
    match Book.adt β a with
    | some A =>
      match AdtD.ctr A c with
      | some C =>
        1 + ((us.drop (us.length - C.fn)).attach.map (fun ⟨x, _⟩ => Term.csize β x)).sum
      | none => 0
    | none => 0
  | _ => 0
termination_by Term.size u
decreasing_by
  all_goals simp_wf
  rename_i hx
  exact Term.size_spine_arg u _ (by rw [_h]; exact List.mem_of_mem_drop hx)

-- a charge prices one pending reference: the definition's index, then
-- one slot per column — the size of a deep argument, or nothing (⊤).
-- Charges compare lexicographically, index first
abbrev Pins := List (Option Nat)
abbrev Charge := Nat × Pins

def Pin.lt : Option Nat → Option Nat → Prop
  | some a, some b => a < b
  | some _, none   => True
  | none,   _      => False

inductive Pins.lt : Pins → Pins → Prop
  | here  : Pin.lt p q → ps.length = qs.length → Pins.lt (p :: ps) (q :: qs)
  | there : Pins.lt ps qs → Pins.lt (p :: ps) (p :: qs)

def Charge.lt (c c' : Charge) : Prop :=
  c.1 < c'.1 ∨ (c.1 = c'.1 ∧ Pins.lt c.2 c'.2)

-- Pins β n us pins: a pinning of the first n arguments — any closed deep
-- argument may be pinned at its size; a missing or unpinned one is ⊤
inductive Pins.of (β : Book) : Nat → List Term → Pins → Prop
  | zero : Pins.of β 0 us []
  | none : Pins.of β n us pins → Pins.of β (n + 1) (u :: us) (none :: pins)
  | some : u.Closed 0 → Deep β u → Pins.of β n us pins →
           Pins.of β (n + 1) (u :: us) (some (Term.csize β u) :: pins)
  | miss : Pins.of β n [] pins → Pins.of β (n + 1) [] (none :: pins)

-- Sub M M': M is a sub-multiset of M' (each charge occurs at most as
-- often)
def Sub (M M' : List Charge) : Prop := ∀ x, M.count x ≤ M'.count x

-- CG β u M: M prices the pending references of the closed erasure u. A
-- spine headed by a definition charges (k, pins) plus its arguments'
-- charges; a match charges any multiset covering both arms (only one
-- ever runs, and an affine binder may occur once in each); every other
-- node charges the sum of its parts. A lambda or let redex on a closed
-- argument, and a match on a constructor, may be priced by its contractum
-- instead (the argument closed and deep: the strategy's redexes, whose
-- arguments it never enters) — the pricing the unfold uses to see through
-- the case tree to its leaves, column after column
mutual
inductive CG (β : Book) : Term → List Charge → Prop
  | ref   : Book.defn β k = some d → Pins.of β d.n us pins → CGs β us Ms →
            CG β (Term.apps (.Ref k) us) ((k, pins) :: Ms)
  | var   : CG β (.Var i) []
  | refF  : Book.defn β k = none → CG β (.Ref k) []
  | typ   : CG β (.Typ g) []
  | qnt   : CG β .Qnt []
  | qua   : CG β (.Qua q) []
  | min   : CG β a Ma → CG β b Mb → CG β (.Min a b) (Ma ++ Mb)
  | all   : CG β (.All q A B) []
  | lam   : CG β f M → CG β (.Lam f) M
  | app   : CG β f Mf → CG β a Ma → CG β (.App f a) (Mf ++ Ma)
  | adt   : CG β (.Adt a r) []
  | ctr   : CG β (.Ctr a c) []
  | mat   : CG β h Mh → CG β m Mm → Sub Mh M → Sub Mm M → CG β (.Mat a c h m) M
  | efq   : CG β .Efq []
  | eql   : CG β (.Eql a b T) []
  | rfl   : CG β .Rfl []
  | rwt   : CG β e Me → CG β f Mf → CG β (.Rwt e P f) (Me ++ Mf)
  | let_  : CG β v Mv → CG β b Mb → CG β (.Let q v b) (Mv ++ Mb)
  -- contractum pricing
  | beta  : a.Closed 0 → Deep β a → CG β (Term.apps (Term.subst 0 a f) us) M →
            CG β (Term.apps (.Lam f) (a :: us)) M
  | letC  : v.Closed 0 → Deep β v → CG β (Term.subst 0 v b) M → CG β (.Let q v b) M
  | matc  : Book.adt β a = some A → AdtD.ctr A c = some C →
            us.length = A.pn + C.fn → (∀ u ∈ us, u.Closed 0) → Deeps β us →
            CG β (Term.apps h (us.drop A.pn ++ more)) M →
            CG β (Term.apps (.Mat a c h m) (Term.apps (.Ctr a c) us :: more)) M
  | matm  : (a', c') ≠ (a, c) → (∀ u ∈ us, u.Closed 0) → Deeps β us →
            CG β (Term.apps m (Term.apps (.Ctr a' c') us :: more)) M →
            CG β (Term.apps (.Mat a c h m) (Term.apps (.Ctr a' c') us :: more)) M
inductive CGs (β : Book) : List Term → List Charge → Prop
  | nil  : CGs β [] []
  | cons : CG β u M → CGs β us Ms → CGs β (u :: us) (M ++ Ms)
end

-- weight β u: the interaction nodes of a live term — a Lam, Mat, Let,
-- Rwt, Min or nullary family head; a match weighs its heavier arm (only
-- one ever runs). Every interaction (beta, let, match, rewrite, meet,
-- aref) removes one, and an affine substitution lands at most one live
-- copy of its argument
def Term.weight (β : Book) : Term → Nat
  | .Lam f       => 1 + Term.weight β f
  | .Mat _ _ h m => 1 + Nat.max (Term.weight β h) (Term.weight β m)
  | .Let _ v b   => 1 + Term.weight β v + Term.weight β b
  | .Rwt e _ f   => 1 + Term.weight β e + Term.weight β f
  | .Min a b     => 1 + Term.weight β a + Term.weight β b
  | .App f a     => Term.weight β f + Term.weight β a
  | .Ref k       => match Book.adt β k with
                    | some A => if A.pn = 0 then 1 else 0
                    | none => 0
  | _            => 0

-- the measure of a state: its charges, then its weight, lexicographically
-- (the multiset order on charges is §N1's)
abbrev Meas := List Charge × Nat


-- ============================================================================
-- METATHEORY §N1 — the order kernel: charges, the multiset order, the
-- measure. Charge.lt is well-founded (index first, then the pins
-- lexicographically); MLt is the Dershowitz–Manna multiset order on
-- charge lists, well-founded by the classic nested induction; MeasLt is
-- the measure order: charges first, then the weight
-- ============================================================================

-- charges

theorem Pin.acc_some (n : Nat) : Acc Pin.lt (some n) := by
  induction n using Nat.strongRecOn with
  | _ n ih => exact Acc.intro _ fun | some m, h => ih m h | none, h => nomatch h

theorem Pin.wf : WellFounded Pin.lt :=
  ⟨fun | some n => Pin.acc_some n
       | none => Acc.intro _ fun | some m, _ => Pin.acc_some m | none, h => nomatch h⟩

theorem Pin.lt.trans : Pin.lt a b → Pin.lt b c → Pin.lt a c := by
  cases a <;> cases b <;> cases c <;> simp [Pin.lt] <;> omega

theorem Pins.lt.length (h : Pins.lt ps qs) : ps.length = qs.length := by
  induction h <;> simp_all

theorem Pins.lt.trans (h1 : Pins.lt ps qs) : ∀ {rs}, Pins.lt qs rs → Pins.lt ps rs := by
  induction h1 with
  | here h hl =>
    intro rs h2
    cases h2 with
    | here h' hl' => exact .here (h.trans h') (hl.trans hl')
    | there h' => exact .here h (hl.trans h'.length)
  | there h ih =>
    intro rs h2
    cases h2 with
    | here h' hl' => exact .here h' (h.length.trans hl')
    | there h' => exact .there (ih h')

theorem Pins.acc_cons (hq : Acc Pin.lt q)
    (hn : ∀ ps : Pins, ps.length = n → Acc Pins.lt ps) :
    ∀ qs : Pins, Acc Pins.lt qs → qs.length = n → Acc Pins.lt (q :: qs) := by
  induction hq with
  | intro q _ ihq =>
    intro qs hqs
    induction hqs with
    | intro qs _ ihqs =>
      intro hl
      refine Acc.intro _ fun ps hps => ?_
      cases hps with
      | here hpq hlen => exact ihq _ hpq _ (hn _ (hlen.trans hl)) (hlen.trans hl)
      | there h => exact ihqs _ h (h.length.trans hl)

theorem Pins.acc : ∀ n (ps : Pins), ps.length = n → Acc Pins.lt ps
  | 0, ps, hl => Acc.intro _ fun _ h => by cases h <;> simp at hl
  | n+1, [], hl => by simp at hl
  | n+1, q :: qs, hl =>
    Pins.acc_cons (Pin.wf.apply q) (Pins.acc n) qs
      (Pins.acc n qs (by simpa using hl)) (by simpa using hl)

theorem Pins.wf : WellFounded Pins.lt := ⟨fun ps => Pins.acc _ ps rfl⟩

-- a pinning of n arguments has n pins (what Pins.lt.here asks for)
theorem Pins.of.length (h : Pins.of β n us pins) : pins.length = n := by
  induction h <;> simp_all

theorem Charge.wf : WellFounded Charge.lt :=
  Subrelation.wf (r := Prod.Lex (· < ·) Pins.lt)
    (fun {c c'} h => by
      obtain ⟨a, ps⟩ := c
      obtain ⟨b, qs⟩ := c'
      simp only [Charge.lt] at h
      rcases h with h | ⟨rfl, h⟩
      · exact .left _ _ h
      · exact .right _ h)
    (Prod.lex Nat.lt_wfRel ⟨_, Pins.wf⟩).wf

theorem Charge.lt.trans (h1 : Charge.lt a b) (h2 : Charge.lt b c) : Charge.lt a c := by
  rcases h1 with h1 | ⟨e1, h1⟩ <;> rcases h2 with h2 | ⟨e2, h2⟩ <;>
    first | exact .inl (by omega) | exact .inr ⟨by omega, h1.trans h2⟩

-- the multiset order: M' < M when M = X ++ R and M' = Y ++ R up to
-- permutation, X nonempty, and every y ∈ Y is below some x ∈ X

def MLt (M' M : List Charge) : Prop :=
  ∃ X Y R : List Charge, X ≠ [] ∧ M.Perm (X ++ R) ∧ M'.Perm (Y ++ R) ∧
    ∀ y ∈ Y, ∃ x ∈ X, Charge.lt y x

theorem MLt.perm_l (h : MLt M' M) (hp : M'.Perm K') : MLt K' M :=
  let ⟨X, Y, R, hX, hM, hM', hY⟩ := h; ⟨X, Y, R, hX, hM, hp.symm.trans hM', hY⟩

theorem MLt.perm_r (h : MLt M' M) (hp : M.Perm K) : MLt M' K :=
  let ⟨X, Y, R, hX, hM, hM', hY⟩ := h; ⟨X, Y, R, hX, hp.symm.trans hM, hM', hY⟩

theorem MLt.append_r (h : MLt M' M) (D : List Charge) : MLt (M' ++ D) (M ++ D) :=
  let ⟨X, Y, R, hX, hM, hM', hY⟩ := h
  ⟨X, Y, R ++ D, hX, by simpa [List.append_assoc] using hM.append_right D,
    by simpa [List.append_assoc] using hM'.append_right D, hY⟩

theorem MLt.append_l (h : MLt M' M) (D : List Charge) : MLt (D ++ M') (D ++ M) :=
  ((h.append_r D).perm_l List.perm_append_comm).perm_r List.perm_append_comm

theorem MLt.replace (hY : ∀ y ∈ Y, Charge.lt y x) : MLt (Y ++ R) (x :: R) :=
  ⟨[x], Y, R, by simp, .refl _, .refl _, by simpa using hY⟩

theorem MLt.drop (hX : X ≠ []) : MLt R (X ++ R) :=
  ⟨X, [], R, hX, .refl _, .refl _, by simp⟩

-- a permutation between two appends splits into four corners
theorem perm_split : ∀ (A B C D : List Charge), (A ++ B).Perm (C ++ D) →
    ∃ CA CB DA DB : List Charge, A.Perm (CA ++ DA) ∧ B.Perm (CB ++ DB) ∧
      C.Perm (CA ++ CB) ∧ D.Perm (DA ++ DB)
  | [], B, C, D, h => ⟨[], C, [], D, .refl _, h, .refl _, .refl _⟩
  | a :: A, B, C, D, h => by
    rcases List.mem_append.mp (h.subset (show a ∈ a :: A ++ B by simp)) with ha | ha
    · obtain ⟨CA, CB, DA, DB, hA, hB, hC, hD⟩ := perm_split A B (C.erase a) D
        (h.trans ((List.perm_cons_erase ha).append_right D)).cons_inv
      exact ⟨a :: CA, CB, DA, DB, hA.cons a, hB, (List.perm_cons_erase ha).trans (hC.cons a), hD⟩
    · obtain ⟨CA, CB, DA, DB, hA, hB, hC, hD⟩ := perm_split A B C (D.erase a)
        ((h.trans ((List.perm_cons_erase ha).append_left C)).trans List.perm_middle).cons_inv
      exact ⟨CA, CB, a :: DA, DB, (hA.cons a).trans List.perm_middle.symm, hB, hC,
        (List.perm_cons_erase ha).trans (hD.cons a)⟩

theorem MLt.trans (h1 : MLt M3 M2) (h2 : MLt M2 M1) : MLt M3 M1 := by
  obtain ⟨X', Y', R', hX', h2', h3, hY'⟩ := h1
  obtain ⟨X, Y, R, hX, h1', h2'', hY⟩ := h2
  obtain ⟨XY, RY, XR, RR, hX'p, hR'p, hYp, hRp⟩ := perm_split _ _ _ _ (h2'.symm.trans h2'')
  refine ⟨X ++ XR, Y' ++ RY, RR, by simp [hX], ?_, ?_, ?_⟩
  · exact (h1'.trans (hRp.append_left X)).trans (by simp)
  · exact (h3.trans (hR'p.append_left Y')).trans (by simp)
  · intro z hz
    rcases List.mem_append.mp hz with hz | hz
    · obtain ⟨x', hx', hlt⟩ := hY' z hz
      rcases List.mem_append.mp (hX'p.subset hx') with hx' | hx'
      · obtain ⟨x, hx, hlt'⟩ := hY x' (hYp.symm.subset (List.mem_append.mpr (.inl hx')))
        exact ⟨x, List.mem_append.mpr (.inl hx), hlt.trans hlt'⟩
      · exact ⟨x', List.mem_append.mpr (.inr hx'), hlt⟩
    · obtain ⟨x, hx, hlt⟩ := hY z (hYp.symm.subset (List.mem_append.mpr (.inr hz)))
      exact ⟨x, List.mem_append.mpr (.inl hx), hlt⟩

-- MLe: the reflexive (up to permutation) closure

def MLe (M' M : List Charge) : Prop := MLt M' M ∨ M'.Perm M

theorem MLe.refl : MLe M M := .inr (.refl _)

theorem MLt_of_MLe_MLt (h1 : MLe M3 M2) (h2 : MLt M2 M1) : MLt M3 M1 :=
  h1.elim (fun h => h.trans h2) (fun h => h2.perm_l h.symm)

theorem MLe.trans (h1 : MLe M3 M2) (h2 : MLe M2 M1) : MLe M3 M1 :=
  h2.elim (fun h => .inl (MLt_of_MLe_MLt h1 h))
    (fun h => h1.elim (fun h' => .inl (h'.perm_r h)) (fun h' => .inr (h'.trans h)))

theorem MLe.append_r (h : MLe M' M) (D : List Charge) : MLe (M' ++ D) (M ++ D) :=
  h.elim (fun h => .inl (h.append_r D)) (fun h => .inr (h.append_right D))

theorem MLe.append_l (h : MLe M' M) (D : List Charge) : MLe (D ++ M') (D ++ M) :=
  h.elim (fun h => .inl (h.append_l D)) (fun h => .inr (h.append_left D))

-- a sub-multiset (M = M' ++ D up to permutation) is MLe
theorem MLe.sub (h : M.Perm (M' ++ D)) : MLe M' M := by
  cases D with
  | nil => exact .inr (by simpa using h.symm)
  | cons d D => exact .inl ((MLt.drop (X := d :: D) (by simp)).perm_r
      (List.perm_append_comm.trans h.symm))

-- well-foundedness (Nipkow's nested induction, on the relation directly)

theorem MLt.acc_perm (h : Acc MLt M) (hp : M.Perm K) : Acc MLt K :=
  Acc.intro _ fun _ hy => h.inv (hy.perm_r hp.symm)

-- what lies below c :: X splits into what lies below c and what lies below X
theorem MLt.split (X : List Charge) : ∀ Y : List Charge,
    (∀ y ∈ Y, ∃ x ∈ c :: X, Charge.lt y x) →
    ∃ Y1 Y2 : List Charge, Y.Perm (Y1 ++ Y2) ∧ (∀ y ∈ Y1, Charge.lt y c) ∧
      ∀ y ∈ Y2, ∃ x ∈ X, Charge.lt y x
  | [], _ => ⟨[], [], .refl _, by simp, by simp⟩
  | y :: Y, h => by
    obtain ⟨Y1, Y2, hp, h1, h2⟩ := MLt.split X Y (fun z hz => h z (by simp [hz]))
    obtain ⟨x, hx, hlt⟩ := h y (by simp)
    rcases List.mem_cons.mp hx with rfl | hx
    · refine ⟨y :: Y1, Y2, hp.cons y, fun z hz => ?_, h2⟩
      rcases List.mem_cons.mp hz with rfl | hz
      · exact hlt
      · exact h1 z hz
    · refine ⟨Y1, y :: Y2, (hp.cons y).trans List.perm_middle.symm, h1, fun z hz => ?_⟩
      rcases List.mem_cons.mp hz with rfl | hz
      · exact ⟨x, hx, hlt⟩
      · exact h2 z hz

theorem MLt.acc_cons (hc : Acc Charge.lt c) : ∀ M, Acc MLt M → Acc MLt (c :: M) := by
  induction hc with
  | intro c _ ihc =>
    intro M hM
    induction hM with
    | intro M hMp ihM =>
      have batch : ∀ Y : List Charge, (∀ y ∈ Y, Charge.lt y c) →
          ∀ N, Acc MLt N → Acc MLt (Y ++ N) := by
        intro Y
        induction Y with
        | nil => exact fun _ N hN => hN
        | cons y Y ih =>
          exact fun hY N hN => ihc y (hY y (by simp)) _ (ih (fun z hz => hY z (by simp [hz])) N hN)
      refine Acc.intro _ fun L' h => ?_
      obtain ⟨X, Y, R, hX, hM, hL', hY⟩ := h
      by_cases hcX : c ∈ X
      · -- c is among the replaced: Y splits into the part below c and the rest
        have hMR : M.Perm (X.erase c ++ R) :=
          (hM.trans ((List.perm_cons_erase hcX).append_right R)).cons_inv
        obtain ⟨Y1, Y2, hYp, hY1, hY2⟩ := MLt.split (X.erase c) Y
          (fun y hy => let ⟨x, hx, h⟩ := hY y hy; ⟨x, (List.perm_cons_erase hcX).subset hx, h⟩)
        have hN : Acc MLt (Y2 ++ R) := by
          generalize hXe : X.erase c = Xe at hMR hY2
          cases Xe with
          | nil =>
            cases Y2 with
            | nil => exact MLt.acc_perm (Acc.intro M hMp) hMR
            | cons y Y2 => obtain ⟨x, hx, _⟩ := hY2 y (by simp); simp at hx
          | cons x X'' => exact hMp _ ⟨x :: X'', Y2, R, by simp, hMR, .refl _, hY2⟩
        exact MLt.acc_perm (batch Y1 hY1 _ hN)
          (by simpa [List.append_assoc] using (hL'.trans (hYp.append_right R)).symm)
      · -- c survives in R
        have hcR : c ∈ R := (List.mem_append.mp (hM.subset (by simp))).resolve_left hcX
        have hMR : M.Perm (X ++ R.erase c) :=
          ((hM.trans ((List.perm_cons_erase hcR).append_left X)).trans List.perm_middle).cons_inv
        exact MLt.acc_perm (ihM _ ⟨X, Y, R.erase c, hX, hMR, .refl _, hY⟩)
          (((hL'.trans ((List.perm_cons_erase hcR).append_left Y)).trans List.perm_middle).symm)

theorem MLt.wf : WellFounded MLt := ⟨fun M => by
  induction M with
  | nil => exact Acc.intro _ fun _ ⟨X, _, R, hX, hM, _, _⟩ => by cases X <;> simp_all
  | cons c M ih => exact MLt.acc_cons (Charge.wf.apply c) M ih⟩

-- the measure order: charges first, then the weight

def MeasLt (m' m : Meas) : Prop := MLt m'.1 m.1 ∨ (m'.1.Perm m.1 ∧ m'.2 < m.2)

theorem MeasLt.acc (L : List Charge) : ∀ n K, K.Perm L → Acc MeasLt (K, n) := by
  induction MLt.wf.apply L with
  | intro L _ ihL =>
    intro n
    induction n using Nat.strongRecOn with
    | _ n ihn =>
      intro K hKL
      refine Acc.intro _ fun m' hm' => ?_
      rcases hm' with hp | ⟨hp, hn⟩
      · exact ihL m'.1 (hp.perm_r hKL) m'.2 m'.1 (.refl _)
      · exact ihn m'.2 hn m'.1 (hp.trans hKL)

theorem MeasLt.wf : WellFounded MeasLt := ⟨fun m => MeasLt.acc m.1 m.2 m.1 (.refl _)⟩


-- ============================================================================
-- METATHEORY §N2 — the pricing algebra: csize, Deep, Pins, CG, weight.
-- csize unfolds on constructor spines and vanishes elsewhere; the §6
-- verdicts PEq/PLt become csize equalities and strict drops under any
-- iterated substitution of the pattern variables; a pinning exists for
-- every closed deep prefix; CG exists for every term, and a closed
-- substitution keeps a sub-multiset of the charges (one copy of the
-- value's charges per occurrence); weight is stable under shift and
-- grows under substitution by one copy of the value per occurrence.
-- ============================================================================

theorem le_sum_of_mem : ∀ (l : List Nat) (a : Nat), a ∈ l → a ≤ l.sum := by
  intro l
  induction l with
  | nil => intro a h; simp at h
  | cons x xs ih =>
    intro a h
    rw [List.sum_cons]
    rcases List.mem_cons.mp h with rfl | h
    · omega
    · have := ih a h; omega

theorem sum_map_drop_le (f : α → Nat) : ∀ (l : List α) (n : Nat),
    ((l.drop n).map f).sum ≤ (l.map f).sum := by
  intro l
  induction l with
  | nil => intro n; simp
  | cons x xs ih =>
    intro n
    cases n with
    | zero => exact Nat.le_refl _
    | succ n =>
      simp only [List.drop_succ_cons, List.map_cons, List.sum_cons]
      have := ih n; omega

-- Nat.max is max (omega reads the latter)
theorem nat_max (a b : Nat) : Nat.max a b = max a b := rfl

-- ---------------------------------------------------------------------------
-- csize
-- ---------------------------------------------------------------------------

theorem Term.csize_ctr (hk : Book.adt β a = some A) (hc : AdtD.ctr A c = some C)
    (us : List Term) :
    Term.csize β (Term.apps (.Ctr a c) us)
      = 1 + ((us.drop (us.length - C.fn)).map (Term.csize β)).sum := by
  rw [Term.csize]
  split
  · rename_i heq
    rw [Term.spine_apps (h := .Ctr a c) (by trivial)] at heq
    obtain ⟨h1, h2⟩ := Prod.mk.inj heq
    cases h1; cases h2
    simp [hk, hc]
  · rename_i hne
    exact absurd (Term.spine_apps (h := .Ctr a c) (by trivial) us) (hne a c us)

theorem Term.csize_fields (hk : Book.adt β a = some A) (hc : AdtD.ctr A c = some C)
    {ys : List Term} (hl : ys.length = C.fn) :
    Term.csize β (Term.apps (.Ctr a c) ys) = 1 + (ys.map (Term.csize β)).sum := by
  rw [Term.csize_ctr hk hc, hl, Nat.sub_self, List.drop_zero]

theorem Term.csize_full (hk : Book.adt β a = some A) (hc : AdtD.ctr A c = some C)
    {ps xs : List Term} (hlp : ps.length = A.pn) (hlx : xs.length = C.fn) :
    Term.csize β (Term.apps (.Ctr a c) (ps ++ xs)) = 1 + (xs.map (Term.csize β)).sum := by
  rw [Term.csize_ctr hk hc, List.length_append, hlp, hlx, Nat.add_sub_cancel, ← hlp,
    List.drop_left]

theorem Term.csize_apps_ne {h : Term} (hh : h.IsHead) (hne : ∀ a c, h ≠ .Ctr a c)
    (us : List Term) : Term.csize β (Term.apps h us) = 0 := by
  rw [Term.csize]
  split
  · rename_i heq
    rw [Term.spine_apps hh] at heq
    exact absurd (Prod.mk.inj heq).1 (hne _ _)
  · rfl

theorem Term.csize_tok : Term.csize β .Qnt = 0 :=
  Term.csize_apps_ne (h := .Qnt) (by trivial) (by simp) []

theorem Term.csize_field_lt (hk : Book.adt β a = some A) (hc : AdtD.ctr A c = some C)
    {us : List Term} {x : Term} (hx : x ∈ us.drop (us.length - C.fn)) :
    Term.csize β x < Term.csize β (Term.apps (.Ctr a c) us) := by
  rw [Term.csize_ctr hk hc]
  have := le_sum_of_mem _ _ (List.mem_map_of_mem (f := Term.csize β) hx)
  omega

-- the iterated substitution (§A's Term.msubstAt) commutes with spines
theorem Term.msubstAt_app (d : Nat) : ∀ (vs : List Term) (f a : Term),
    Term.msubstAt d vs (.App f a)
      = .App (Term.msubstAt d vs f) (Term.msubstAt d vs a) := by
  intro vs
  induction vs with
  | nil => intro f a; rfl
  | cons v vs ih => intro f a; exact ih _ _

theorem Term.msubstAt_ctr (d a c : Nat) : ∀ (vs : List Term),
    Term.msubstAt d vs (.Ctr a c) = .Ctr a c := by
  intro vs
  induction vs with
  | nil => rfl
  | cons v vs ih => exact ih

theorem Term.msubstAt_apps (d : Nat) (vs : List Term) : ∀ (xs : List Term) (f : Term),
    Term.msubstAt d vs (Term.apps f xs)
      = Term.apps (Term.msubstAt d vs f) (xs.map (Term.msubstAt d vs)) := by
  intro xs
  induction xs with
  | nil => intro f; rfl
  | cons x xs ih =>
    intro f
    show Term.msubstAt d vs (Term.apps (.App f x) xs) = _
    rw [ih (.App f x), Term.msubstAt_app]
    rfl

-- the descent verdicts measure: EQ columns measure alike, LT columns drop
mutual
theorem PEq.csize (h : PEq β t p) : ∀ (d : Nat) (env : List Term),
    Term.csize β (Term.msubstAt d env t) = Term.csize β (Term.msubstAt d env p) :=
  match h with
  | .var => fun _ _ => rfl
  | .ctr hk hc hlp hlx hxy => fun d env => by
    obtain ⟨hs, hl⟩ := PEqs.csize hxy d env
    rw [Term.msubstAt_apps, Term.msubstAt_apps, Term.msubstAt_ctr, List.map_append,
      Term.csize_full hk hc, Term.csize_fields hk hc, hs]
    all_goals simp [hlp, hlx, ← hl]
theorem PEqs.csize (h : PEqs β xs ys) : ∀ (d : Nat) (env : List Term),
    ((xs.map (Term.msubstAt d env)).map (Term.csize β)).sum
      = ((ys.map (Term.msubstAt d env)).map (Term.csize β)).sum ∧ xs.length = ys.length :=
  match h with
  | .nil => fun _ _ => ⟨rfl, rfl⟩
  | .cons hxy hrest => fun d env => by
    obtain ⟨h1, h2⟩ := PEqs.csize hrest d env
    have := PEq.csize hxy d env
    simp only [List.map_cons, List.sum_cons, List.length_cons]
    omega
end

mutual
theorem PLt.csize (h : PLt β t p) : ∀ (d : Nat) (env : List Term),
    Term.csize β (Term.msubstAt d env t) < Term.csize β (Term.msubstAt d env p) :=
  match h with
  | .subEq hk hc hly hy hpe => fun d env => by
    rw [Term.msubstAt_apps, Term.msubstAt_ctr, Term.csize_fields hk hc, PEq.csize hpe d env]
    · have := le_sum_of_mem _ _ (List.mem_map_of_mem (f := Term.csize β)
        (List.mem_map_of_mem (f := Term.msubstAt d env) hy))
      omega
    · simp [hly]
  | .subLt hk hc hly hy hpl => fun d env => by
    rw [Term.msubstAt_apps, Term.msubstAt_ctr, Term.csize_fields hk hc]
    · have h1 := PLt.csize hpl d env
      have := le_sum_of_mem _ _ (List.mem_map_of_mem (f := Term.csize β)
        (List.mem_map_of_mem (f := Term.msubstAt d env) hy))
      omega
    · simp [hly]
  | .ctr hk hc hlp hlx hxy => fun d env => by
    obtain ⟨hs, hl⟩ := PLts.csize hxy d env
    rw [Term.msubstAt_apps, Term.msubstAt_apps, Term.msubstAt_ctr, List.map_append,
      Term.csize_full hk hc, Term.csize_fields hk hc]
    · omega
    all_goals simp [hlp, hlx, ← hl]
theorem PLts.csize (h : PLts β xs ys) : ∀ (d : Nat) (env : List Term),
    ((xs.map (Term.msubstAt d env)).map (Term.csize β)).sum
      < ((ys.map (Term.msubstAt d env)).map (Term.csize β)).sum ∧ xs.length = ys.length :=
  match h with
  | .here hxy hrest => fun d env => by
    obtain ⟨h1, h2⟩ := PLes.csize hrest d env
    have := PLt.csize hxy d env
    simp only [List.map_cons, List.sum_cons, List.length_cons]
    omega
  | .there hxy hrest => fun d env => by
    obtain ⟨h1, h2⟩ := PLts.csize hrest d env
    have := PEq.csize hxy d env
    simp only [List.map_cons, List.sum_cons, List.length_cons]
    omega
theorem PLes.csize (h : PLes β xs ys) : ∀ (d : Nat) (env : List Term),
    ((xs.map (Term.msubstAt d env)).map (Term.csize β)).sum
      ≤ ((ys.map (Term.msubstAt d env)).map (Term.csize β)).sum ∧ xs.length = ys.length :=
  match h with
  | .nil => fun _ _ => ⟨Nat.le_refl _, rfl⟩
  | .consEq hxy hrest => fun d env => by
    obtain ⟨h1, h2⟩ := PLes.csize hrest d env
    have := PEq.csize hxy d env
    simp only [List.map_cons, List.sum_cons, List.length_cons]
    omega
  | .consLt hxy hrest => fun d env => by
    obtain ⟨h1, h2⟩ := PLes.csize hrest d env
    have := PLt.csize hxy d env
    simp only [List.map_cons, List.sum_cons, List.length_cons]
    omega
end

-- ---------------------------------------------------------------------------
-- Deep
-- ---------------------------------------------------------------------------

theorem Deep.value (hd : Deep β u) : Term.Value β u :=
  match hd with
  | .qnt => .qnt (as := [])
  | .typ => .typ (as := [])
  | .qua => .qua (as := [])
  | .all => .all (as := [])
  | .eql => .eql (as := [])
  | .rfl => .rfl (as := [])
  | .lam => .lam
  | .mat => .mat
  | .efq _ => .efq
  | .ctr _ => .ctr
  | .adt _ => .adt
  | .fam hk hpn _ => .fam hk hpn
  | .ref hk hlt _ => .ref hk hlt
  | .rwt he hne _ => .rwt (Deep.value he) hne
  | .matS hx hne _ => .matS (Deep.value hx) hne
  | .min ha h1 h2 hb h3 h4 h5 =>
    .min (as := []) (Deep.value ha) h1 h2 (Deep.value hb) h3 h4 h5

theorem Deeps.init : ∀ {us : List Term} {a : Term}, Deeps β (us ++ [a]) → Deeps β us := by
  intro us
  induction us with
  | nil => intro a _; exact .nil
  | cons u us ih =>
    intro a h
    cases h with
    | cons hu hus => exact .cons hu (ih hus)

theorem Deep.app_inv (hd : Deep β (.App f a)) : Deep β f := by
  generalize hu : Term.App f a = u at hd
  cases hd with
  | efq hus =>
    obtain ⟨ys, rfl, rfl⟩ := Term.app_eq_apps (by trivial) hu
    exact .efq hus.init
  | ctr hus =>
    obtain ⟨ys, rfl, rfl⟩ := Term.app_eq_apps (by trivial) hu
    exact .ctr hus.init
  | adt hus =>
    obtain ⟨ys, rfl, rfl⟩ := Term.app_eq_apps (by trivial) hu
    exact .adt hus.init
  | fam hk hpn hus =>
    obtain ⟨ys, rfl, rfl⟩ := Term.app_eq_apps (by trivial) hu
    exact .fam hk hpn hus.init
  | ref hk hlt hus =>
    obtain ⟨ys, rfl, rfl⟩ := Term.app_eq_apps (by trivial) hu
    exact .ref hk (by simp at hlt; omega) hus.init
  | rwt he hne hus =>
    obtain ⟨ys, rfl, rfl⟩ := Term.app_eq_apps (by trivial) hu
    exact .rwt he hne hus.init
  | matS hx hne hus =>
    obtain ⟨ys, hys, rfl⟩ := Term.app_eq_apps (by trivial) hu
    cases ys with
    | nil =>
      exact .mat
    | cons y ys =>
      simp only [List.cons_append, List.cons.injEq] at hys
      obtain ⟨rfl, rfl⟩ := hys
      exact .matS hx hne hus.init
  | _ => cases hu

-- ---------------------------------------------------------------------------
-- Pins
-- ---------------------------------------------------------------------------

theorem Pins.of.miss_all : ∀ (n : Nat), Pins.of β n [] (List.replicate n Option.none) := by
  intro n
  induction n with
  | zero => exact .zero
  | succ n ih => exact .miss ih

theorem Pins.of.full : ∀ (n : Nat) {us : List Term}, Deeps β us → (∀ u ∈ us, u.Closed 0) →
    n ≤ us.length → Pins.of β n us ((us.take n).map (Option.some ∘ Term.csize β)) := by
  intro n
  induction n with
  | zero => intro us _ _ _; exact .zero
  | succ n ih =>
    intro us hd hc hl
    cases hd with
    | nil => simp at hl
    | cons hu hus =>
      simp only [List.take_succ_cons, List.map_cons, Function.comp]
      exact .some (hc _ List.mem_cons_self) hu
        (ih hus (fun u hu => hc u (List.mem_cons_of_mem _ hu)) (by simp at hl; omega))

theorem Pins.of.subst (h : Pins.of β n us pins) (d : Nat) (w : Term) :
    Pins.of β n (us.map (Term.subst d w)) pins := by
  induction h with
  | zero => exact .zero
  | none _ ih => exact .none ih
  | some hc hu _ ih =>
    simp only [List.map_cons]
    rw [Term.subst_closed _ 0 d w hc (Nat.zero_le d)]
    exact .some hc hu ih
  | miss _ ih => exact .miss ih

-- ---------------------------------------------------------------------------
-- Sub and CG
-- ---------------------------------------------------------------------------

theorem Sub.refl (M : List Charge) : Sub M M := fun _ => Nat.le_refl _

theorem Sub.trans (h1 : Sub M1 M2) (h2 : Sub M2 M3) : Sub M1 M3 :=
  fun x => Nat.le_trans (h1 x) (h2 x)

theorem Sub.nil (M : List Charge) : Sub [] M := fun x => by simp

theorem Sub.append_left (A B : List Charge) : Sub A (B ++ A) :=
  fun x => by simp only [List.count_append]; omega

theorem Sub.append_right (A B : List Charge) : Sub A (A ++ B) :=
  fun x => by simp only [List.count_append]; omega

theorem Sub.append (h1 : Sub A A') (h2 : Sub B B') : Sub (A ++ B) (A' ++ B') :=
  fun x => by have := h1 x; have := h2 x; simp only [List.count_append]; omega

-- a sub-multiset is a permutation away from a sublist: the witness §N1 reads
theorem Sub.perm_append : ∀ (M' M : List Charge), Sub M' M → ∃ D, M.Perm (M' ++ D) := by
  intro M'
  induction M' with
  | nil => intro M _; exact ⟨M, List.Perm.refl _⟩
  | cons a M' ih =>
    intro M h
    have ha : a ∈ M := List.count_pos_iff.mp (by
      have := h a; simp only [List.count_cons, beq_self_eq_true, if_true] at this; omega)
    obtain ⟨D, hD⟩ := ih (M.erase a) (fun x => by
      have := h x
      rw [List.count_erase]
      simp only [List.count_cons] at this
      omega)
    exact ⟨D, (List.perm_cons_erase ha).trans (hD.cons a)⟩

theorem Sub.mle (h : Sub M' M) : MLe M' M :=
  let ⟨_, hD⟩ := Sub.perm_append M' M h
  MLe.sub hD

-- n copies of a charge list
def rep : Nat → List Charge → List Charge
  | 0,     _ => []
  | n + 1, l => l ++ rep n l

theorem count_rep (x : Charge) : ∀ (n : Nat) (l : List Charge),
    (rep n l).count x = n * l.count x := by
  intro n
  induction n with
  | zero => intro l; simp [rep]
  | succ n ih => intro l; simp only [rep, List.count_append, ih, Nat.add_mul, Nat.one_mul]; omega

theorem CG.apps (hf : CG β h Mh) : ∀ {us : List Term} {Ms : List Charge},
    CGs β us Ms → CG β (Term.apps h us) (Mh ++ Ms) := by
  intro us
  induction us generalizing h Mh with
  | nil => intro Ms hus; cases hus; rw [List.append_nil]; exact hf
  | cons u us ih =>
    intro Ms hus
    cases hus with
    | cons hu hus =>
      rw [← List.append_assoc]
      exact ih (.app hf hu) hus

theorem CG.exists : ∀ (u : Term), ∃ M, CG β u M := by
  intro u
  induction u with
  | Var i => exact ⟨_, .var⟩
  | Ref k =>
    cases hk : Book.defn β k with
    | none => exact ⟨_, .refF hk⟩
    | some d => exact ⟨_, .ref (us := []) hk (Pins.of.miss_all _) .nil⟩
  | Typ g _ => exact ⟨_, .typ⟩
  | Qnt => exact ⟨_, .qnt⟩
  | Qua q => exact ⟨_, .qua⟩
  | Min a b iha ihb =>
    obtain ⟨Ma, ha⟩ := iha
    obtain ⟨Mb, hb⟩ := ihb
    exact ⟨_, .min ha hb⟩
  | All q A B _ _ => exact ⟨_, .all⟩
  | Lam f ih =>
    obtain ⟨M, h⟩ := ih
    exact ⟨_, .lam h⟩
  | App f a ihf iha =>
    obtain ⟨Mf, hf⟩ := ihf
    obtain ⟨Ma, ha⟩ := iha
    exact ⟨_, .app hf ha⟩
  | Adt a r => exact ⟨_, .adt⟩
  | Ctr a c => exact ⟨_, .ctr⟩
  | Mat a c h m ihh ihm =>
    obtain ⟨Mh, hh⟩ := ihh
    obtain ⟨Mm, hm⟩ := ihm
    exact ⟨Mh ++ Mm, .mat hh hm (Sub.append_right _ _) (Sub.append_left _ _)⟩
  | Efq => exact ⟨_, .efq⟩
  | Eql a b T _ _ _ => exact ⟨_, .eql⟩
  | Rfl => exact ⟨_, .rfl⟩
  | Rwt e P f ihe _ ihf =>
    obtain ⟨Me, he⟩ := ihe
    obtain ⟨Mf, hf⟩ := ihf
    exact ⟨_, .rwt he hf⟩
  | Let q v b ihv ihb =>
    obtain ⟨Mv, hv⟩ := ihv
    obtain ⟨Mb, hb⟩ := ihb
    exact ⟨_, .let_ hv hb⟩

-- occurrences above a closed substitution shift down by one
theorem Term.occ_subst_ge (hw : w.Closed 0) : ∀ (t : Term) (e i : Nat), e ≤ i →
    Term.occ i (Term.subst e w t) = Term.occ (i + 1) t := by
  intro t
  induction t <;> intro e i hei <;> simp only [Term.subst, Term.occ]
  case Var j =>
    by_cases h1 : j = e
    · subst h1
      rw [if_pos rfl, Term.occ_closed w 0 i hw (Nat.zero_le i)]
      split <;> omega
    · rw [if_neg h1]
      by_cases h2 : e < j
      · rw [if_pos h2]; simp only [Term.occ]; split <;> split <;> omega
      · rw [if_neg h2]; simp only [Term.occ]; split <;> split <;> omega
  case All q A B ihA ihB =>
    rw [ihA e i hei, Term.shift_closed w 0 0 hw (Nat.le_refl 0), ihB (e + 1) (i + 1) (by omega)]
  case Lam f ih =>
    rw [Term.shift_closed w 0 0 hw (Nat.le_refl 0), ih (e + 1) (i + 1) (by omega)]
  case Let q v b ihv ihb =>
    rw [ihv e i hei, Term.shift_closed w 0 0 hw (Nat.le_refl 0), ihb (e + 1) (i + 1) (by omega)]
  all_goals simp [*]

-- the contractum of a closed redex has no more occurrences than the redex
theorem Term.occ_beta_le (hac : a.Closed 0) :
    Term.occ d (Term.apps (Term.subst 0 a f) us) ≤ Term.occ d (Term.apps (.Lam f) (a :: us)) := by
  rw [Term.occ_apps, Term.occ_apps, Term.occ_subst_ge hac f 0 d (Nat.zero_le d)]
  simp only [Term.occ, List.map_cons, List.sum_cons]
  omega

theorem Term.occ_letC_le (hvc : v.Closed 0) :
    Term.occ d (Term.subst 0 v b) ≤ Term.occ d (.Let q v b) := by
  rw [Term.occ_subst_ge hvc b 0 d (Nat.zero_le d)]
  simp only [Term.occ]; omega

theorem List.map_subst_closed {us : List Term} (hcl : ∀ u ∈ us, Term.Closed 0 u) (d : Nat)
    (v : Term) : us.map (Term.subst d v) = us := by
  rw [List.map_congr_left (g := id)
    (fun u hu => Term.subst_closed u 0 d v (hcl u hu) (Nat.zero_le d))]
  exact List.map_id us

theorem Term.occ_matc_le :
    Term.occ d (Term.apps h (us.drop n ++ more))
      ≤ Term.occ d (Term.apps (.Mat a c h m) (Term.apps (.Ctr a c) us :: more)) := by
  simp only [Term.occ_apps, Term.occ, nat_max, List.map_append, List.sum_append,
    List.map_cons, List.sum_cons]
  have := sum_map_drop_le (Term.occ d) us n
  have : Term.occ d h ≤ max (Term.occ d h) (Term.occ d m) := Nat.le_max_left _ _
  omega

theorem Term.occ_matm_le :
    Term.occ d (Term.apps m (x :: more)) ≤ Term.occ d (Term.apps (.Mat a c h m) (x :: more)) := by
  simp only [Term.occ_apps, Term.occ, nat_max, List.map_cons, List.sum_cons]
  have : Term.occ d m ≤ max (Term.occ d h) (Term.occ d m) := Nat.le_max_right _ _
  omega

-- a match's substituted arms are covered by the cover plus the copies
theorem CG.subst_mat {Mv : List Charge} (hh : CG β h' Mh') (hm : CG β m' Mm')
    (hsh : Sub Mh M) (hsm : Sub Mm M)
    (h1 : ∀ x, Mh'.count x ≤ Mh.count x + oh * Mv.count x)
    (h2 : ∀ x, Mm'.count x ≤ Mm.count x + om * Mv.count x) :
    ∃ M', CG β (.Mat a c h' m') M' ∧
      ∀ x, M'.count x ≤ M.count x + Nat.max oh om * Mv.count x := by
  refine ⟨M ++ rep (Nat.max oh om) Mv, .mat hh hm ?_ ?_, ?_⟩
  · intro x
    have := h1 x; have := hsh x
    have := Nat.mul_le_mul_right (Mv.count x) (Nat.le_max_left oh om)
    simp only [List.count_append, count_rep, nat_max] at *; omega
  · intro x
    have := h2 x; have := hsm x
    have := Nat.mul_le_mul_right (Mv.count x) (Nat.le_max_right oh om)
    simp only [List.count_append, count_rep, nat_max] at *; omega
  · intro x
    simp only [List.count_append, count_rep]; omega

-- a closed substitution keeps a sub-multiset of the charges: the body's,
-- plus one copy of the value's per occurrence
mutual
theorem CG.subst (hb : CG β b Mb) (hv : CG β v Mv) (hvc : v.Closed 0) (d : Nat) :
    ∃ M', CG β (Term.subst d v b) M' ∧
      ∀ x, M'.count x ≤ Mb.count x + Term.occ d b * Mv.count x :=
  match hb with
  | .ref hk hp hM => by
    rename_i k dd us pins Ms
    obtain ⟨Ms', hMs', hle⟩ := CGs.subst hM hv hvc d
    refine ⟨(k, pins) :: Ms', ?_, ?_⟩
    · rw [Term.subst_apps]
      exact .ref hk (hp.subst d v) hMs'
    · intro x
      have := hle x
      rw [Term.occ_apps]
      simp only [Term.occ, List.count_cons, Nat.zero_add]
      omega
  | .var => by
    rename_i i
    by_cases hi : i = d
    · subst hi
      simp only [Term.subst, Term.occ, if_true]
      exact ⟨Mv, hv, fun x => by simp⟩
    · simp only [Term.subst, Term.occ, if_neg hi]
      split <;> exact ⟨[], .var, fun x => by simp⟩
  | .refF hk => ⟨[], .refF hk, fun x => by simp⟩
  | .typ => ⟨[], .typ, fun x => by simp⟩
  | .qnt => ⟨[], .qnt, fun x => by simp⟩
  | .qua => ⟨[], .qua, fun x => by simp⟩
  | .all => ⟨[], .all, fun x => by simp⟩
  | .adt => ⟨[], .adt, fun x => by simp⟩
  | .ctr => ⟨[], .ctr, fun x => by simp⟩
  | .efq => ⟨[], .efq, fun x => by simp⟩
  | .eql => ⟨[], .eql, fun x => by simp⟩
  | .rfl => ⟨[], .rfl, fun x => by simp⟩
  | .min ha hb' => by
    obtain ⟨Ma', hMa', h1⟩ := CG.subst ha hv hvc d
    obtain ⟨Mb', hMb', h2⟩ := CG.subst hb' hv hvc d
    exact ⟨Ma' ++ Mb', .min hMa' hMb', fun x => by
      have := h1 x; have := h2 x
      simp only [Term.occ, List.count_append, Nat.add_mul]; omega⟩
  | .lam hf => by
    obtain ⟨M', hM', h⟩ := CG.subst hf hv hvc (d + 1)
    refine ⟨M', ?_, fun x => h x⟩
    simp only [Term.subst, Term.shift_closed v 0 0 hvc (Nat.le_refl 0)]
    exact .lam hM'
  | .app hf ha => by
    obtain ⟨Mf', hMf', h1⟩ := CG.subst hf hv hvc d
    obtain ⟨Ma', hMa', h2⟩ := CG.subst ha hv hvc d
    exact ⟨Mf' ++ Ma', .app hMf' hMa', fun x => by
      have := h1 x; have := h2 x
      simp only [Term.occ, List.count_append, Nat.add_mul]; omega⟩
  | .mat hh hm hsh hsm => by
    obtain ⟨Mh', hMh', h1⟩ := CG.subst hh hv hvc d
    obtain ⟨Mm', hMm', h2⟩ := CG.subst hm hv hvc d
    simp only [Term.subst, Term.occ]
    exact CG.subst_mat hMh' hMm' hsh hsm h1 h2
  | .rwt he hf => by
    obtain ⟨Me', hMe', h1⟩ := CG.subst he hv hvc d
    obtain ⟨Mf', hMf', h2⟩ := CG.subst hf hv hvc d
    exact ⟨Me' ++ Mf', .rwt hMe' hMf', fun x => by
      have := h1 x; have := h2 x
      simp only [Term.occ, List.count_append, Nat.add_mul]; omega⟩
  | .let_ hv' hb' => by
    obtain ⟨Mv', hMv', h1⟩ := CG.subst hv' hv hvc d
    obtain ⟨Mb', hMb', h2⟩ := CG.subst hb' hv hvc (d + 1)
    refine ⟨Mv' ++ Mb', ?_, ?_⟩
    · simp only [Term.subst, Term.shift_closed v 0 0 hvc (Nat.le_refl 0)]
      exact .let_ hMv' hMb'
    · intro x
      have := h1 x; have := h2 x
      simp only [Term.occ, List.count_append, Nat.add_mul]; omega
  | .beta hac hd hc => by
    obtain ⟨M', hM', hle⟩ := CG.subst hc hv hvc d
    have hsh := Term.shift_closed v 0 0 hvc (Nat.le_refl 0)
    have hsa := Term.subst_closed _ 0 d v hac (Nat.zero_le d)
    refine ⟨M', ?_, fun x => Nat.le_trans (hle x)
      (Nat.add_le_add_left (Nat.mul_le_mul_right _ (Term.occ_beta_le hac)) _)⟩
    rw [Term.subst_apps, Term.subst_subst0, hsa, hsh] at hM'
    rw [Term.subst_apps]
    simp only [Term.subst, List.map, hsh, hsa]
    exact .beta hac hd hM'
  | .letC hvc' hd hc => by
    obtain ⟨M', hM', hle⟩ := CG.subst hc hv hvc d
    have hsh := Term.shift_closed v 0 0 hvc (Nat.le_refl 0)
    have hsv := Term.subst_closed _ 0 d v hvc' (Nat.zero_le d)
    refine ⟨M', ?_, fun x => Nat.le_trans (hle x)
      (Nat.add_le_add_left (Nat.mul_le_mul_right _ (Term.occ_letC_le hvc')) _)⟩
    rw [Term.subst_subst0, hsv, hsh] at hM'
    simp only [Term.subst, hsh, hsv]
    exact .letC hvc' hd hM'
  | .matc hk hc hlen hcl hd hM => by
    obtain ⟨M', hM', hle⟩ := CG.subst hM hv hvc d
    refine ⟨M', ?_, fun x => Nat.le_trans (hle x)
      (Nat.add_le_add_left (Nat.mul_le_mul_right _ Term.occ_matc_le) _)⟩
    have hmap := List.map_subst_closed hcl d v
    rw [Term.subst_apps, List.map_append, List.map_drop, hmap] at hM'
    rw [Term.subst_apps]
    simp only [List.map_cons, Term.subst, Term.subst_apps, hmap]
    exact .matc hk hc hlen hcl hd hM'
  | .matm hne hcl hd hM => by
    obtain ⟨M', hM', hle⟩ := CG.subst hM hv hvc d
    refine ⟨M', ?_, fun x => Nat.le_trans (hle x)
      (Nat.add_le_add_left (Nat.mul_le_mul_right _ Term.occ_matm_le) _)⟩
    have hmap := List.map_subst_closed hcl d v
    rw [Term.subst_apps] at hM'
    rw [Term.subst_apps]
    simp only [List.map_cons, Term.subst, Term.subst_apps, hmap] at hM' ⊢
    exact .matm hne hcl hd hM'
theorem CGs.subst (hus : CGs β us Ms) (hv : CG β v Mv) (hvc : v.Closed 0) (d : Nat) :
    ∃ Ms', CGs β (us.map (Term.subst d v)) Ms' ∧
      ∀ x, Ms'.count x ≤ Ms.count x + (us.map (Term.occ d)).sum * Mv.count x :=
  match hus with
  | .nil => ⟨[], .nil, fun x => by simp⟩
  | .cons hu hus => by
    obtain ⟨M', hM', h1⟩ := CG.subst hu hv hvc d
    obtain ⟨Ms', hMs', h2⟩ := CGs.subst hus hv hvc d
    exact ⟨M' ++ Ms', .cons hM' hMs', fun x => by
      have := h1 x; have := h2 x
      simp only [List.count_append, List.map_cons, List.sum_cons, Nat.add_mul]; omega⟩
end

theorem CG.subst_lone (hb : CG β b Mb) (hv : CG β v Mv) (hvc : v.Closed 0)
    (ho : Term.occ 0 b ≤ 1) :
    ∃ M', CG β (Term.subst 0 v b) M' ∧ Sub M' (Mb ++ Mv) := by
  obtain ⟨M', h, hle⟩ := CG.subst hb hv hvc 0
  refine ⟨M', h, fun x => ?_⟩
  have := hle x
  have := Nat.mul_le_mul_right (Mv.count x) ho
  simp only [List.count_append]; omega

theorem CG.subst_free (hb : CG β b Mb) (hv : CG β v []) (hvc : v.Closed 0) :
    ∃ M', CG β (Term.subst 0 v b) M' ∧ Sub M' Mb := by
  obtain ⟨M', h, hle⟩ := CG.subst hb hv hvc 0
  refine ⟨M', h, fun x => ?_⟩
  have := hle x
  simp at this
  exact this

-- ---------------------------------------------------------------------------
-- weight
-- ---------------------------------------------------------------------------

theorem Term.weight_shift : ∀ (t : Term) (d : Nat),
    Term.weight β (Term.shift d t) = Term.weight β t := by
  intro t
  induction t <;> intro d
  case Var i => simp only [Term.shift]; split <;> rfl
  all_goals simp [Term.shift, Term.weight, *]

theorem Term.weight_apps : ∀ (us : List Term) (h : Term),
    Term.weight β (Term.apps h us) = Term.weight β h + (us.map (Term.weight β)).sum := by
  intro us
  induction us with
  | nil => intro h; show Term.weight β h = _; simp
  | cons u us ih =>
    intro h
    show Term.weight β (Term.apps (.App h u) us) = _
    rw [ih]
    simp only [Term.weight, List.map_cons, List.sum_cons]
    omega

theorem Term.weight_subst : ∀ (b : Term) (d : Nat) (v : Term),
    Term.weight β (Term.subst d v b) ≤ Term.weight β b + Term.occ d b * Term.weight β v := by
  intro b
  induction b <;> intro d v <;> simp only [Term.subst, Term.occ, Term.weight]
  case Var i => split <;> (try split) <;> simp [Term.weight]
  case Lam f ih =>
    have := ih (d + 1) (Term.shift 0 v)
    rw [Term.weight_shift] at this
    omega
  case Mat a c h m ihh ihm =>
    have h1 := ihh d v
    have h2 := ihm d v
    have m1 : Term.occ d h * Term.weight β v ≤ Nat.max (Term.occ d h) (Term.occ d m) * Term.weight β v :=
      Nat.mul_le_mul_right _ (Nat.le_max_left _ _)
    have m2 : Term.occ d m * Term.weight β v ≤ Nat.max (Term.occ d h) (Term.occ d m) * Term.weight β v :=
      Nat.mul_le_mul_right _ (Nat.le_max_right _ _)
    simp only [nat_max] at *
    omega
  case Min a b iha ihb =>
    have := iha d v; have := ihb d v
    rw [Nat.add_mul]; omega
  case App f a ihf iha =>
    have := ihf d v; have := iha d v
    rw [Nat.add_mul]; omega
  case Rwt e P f ihe _ ihf =>
    have := ihe d v; have := ihf d v
    rw [Nat.add_mul, Nat.add_mul]; omega
  case Let q v' b' ihv ihb =>
    have h1 := ihv d v
    have h2 := ihb (d + 1) (Term.shift 0 v)
    rw [Term.weight_shift] at h2
    rw [Nat.add_mul]; omega
  all_goals omega

theorem Term.weight_subst_lone (ho : Term.occ 0 b ≤ 1) (v : Term) :
    Term.weight β (Term.subst 0 v b) ≤ Term.weight β b + Term.weight β v := by
  have := Term.weight_subst (β := β) b 0 v
  have := Nat.mul_le_mul_right (Term.weight β v) ho
  omega

theorem Term.weight_subst_free : ∀ (b : Term) (d : Nat) (v : Term), Term.weight β v = 0 →
    Term.weight β (Term.subst d v b) = Term.weight β b := by
  intro b
  induction b <;> intro d v hv <;> simp only [Term.subst, Term.weight]
  case Var i => split <;> (try split) <;> simp [Term.weight, hv]
  all_goals simp [*, Term.weight_shift]

-- ============================================================================
-- METATHEORY §N3 — the typed facts the engine needs: the affine occurrence
-- bound (N3a), the strategy and its steps (N3c), and the inertness of Data
-- values for the measure (N3b)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- N3a — a binder measured None does not occur in the erasure, one measured
-- Lone occurs at most once: the var rule charges the ambient demand at its
-- index and erases to the token when dead; add and tail track occ, join
-- tracks max, and a rule that checks a premise dead erases it to the token
-- ----------------------------------------------------------------------------

theorem Quant.occ_add {a b : Quant} {x y : Nat}
    (h1 : (a = .None → x = 0) ∧ (a = .Lone → x ≤ 1))
    (h2 : (b = .None → y = 0) ∧ (b = .Lone → y ≤ 1)) :
    (Quant.add a b = .None → x + y = 0) ∧ (Quant.add a b = .Lone → x + y ≤ 1) := by
  cases a <;> cases b <;> simp_all [Quant.add] <;> omega

theorem Quant.occ_join {a b : Quant} {x y : Nat}
    (h1 : (a = .None → x = 0) ∧ (a = .Lone → x ≤ 1))
    (h2 : (b = .None → y = 0) ∧ (b = .Lone → y ≤ 1)) :
    (Quant.join a b = .None → Nat.max x y = 0) ∧ (Quant.join a b = .Lone → Nat.max x y ≤ 1) := by
  cases a <;> cases b <;> simp_all [Quant.join, nat_max] <;> omega

theorem Quant.occ_mono {a : Quant} {x z : Nat}
    (h : (a = .None → x = 0) ∧ (a = .Lone → x ≤ 1)) (hz : z ≤ x) :
    (a = .None → z = 0) ∧ (a = .Lone → z ≤ 1) :=
  ⟨fun ha => by have := h.1 ha; omega, fun ha => by have := h.2 ha; omega⟩

theorem Term.occ_era_le (q : Quant) (u : Term) (i : Nat) :
    Term.occ i (Term.era q u) ≤ Term.occ i u := by
  cases q <;> simp [Term.era, Term.occ]

theorem Quant.dem_ne (hq' : q' ≠ .None) (hq : q ≠ .None) : Quant.dem q' q ≠ .None := by
  rw [Quant.dem_live hq']; exact hq

theorem Check.occ {sp : List Term} (h : Check β Φ L sp q Γ t T π u) (i : Nat) :
    (π i = .None → Term.occ i u = 0) ∧ (π i = .Lone → Term.occ i u ≤ 1) := by
  induction h generalizing i with
  | var _ =>
    refine ⟨fun hh => ?_, fun hh => ?_⟩ <;> simp only [Uses.one] at hh <;> split at hh
    · subst hh; simp [Term.era, Term.occ]
    · exact Nat.le_zero.mp (Nat.le_trans (Term.occ_era_le _ _ _)
        (by simp only [Term.occ]; split <;> omega))
    · subst hh
      exact Nat.le_trans (Term.occ_era_le _ _ _) (by simp only [Term.occ]; split <;> omega)
    · exact absurd hh (by simp)
  | min _ _ iha ihb => exact Quant.occ_mono (Quant.occ_add (iha i) (ihb i)) (Term.occ_era_le _ _ _)
  | lam _ _ _ _ ihf => exact Quant.occ_mono (ihf (i + 1)) (Term.occ_era_le _ _ _)
  | app _ _ ihf ihx => exact Quant.occ_mono (Quant.occ_add (ihf i) (ihx i)) (Term.occ_era_le _ _ _)
  | appLam _ _ ih => exact ih i
  | let_ _ _ _ _ ihv _ ihb =>
    exact Quant.occ_mono (Quant.occ_add (ihv i) (ihb (i + 1))) (Term.occ_era_le _ _ _)
  | rwt _ _ _ ihe _ ihf =>
    exact Quant.occ_mono (Quant.occ_add (ihe i) (ihf i)) (Term.occ_era_le _ _ _)
  | mat _ _ _ _ _ _ _ _ _ ihh ihm =>
    exact Quant.occ_mono (Quant.occ_join (ihh i) (ihm i)) (Term.occ_era_le _ _ _)
  | cnv _ _ ih => exact ih i
  | qnt => exact ⟨fun _ => _root_.rfl, fun h => by simp [Uses.zero] at h⟩
  | _ =>
    exact ⟨fun _ => Nat.le_zero.mp (Nat.le_trans (Term.occ_era_le _ _ _) (by simp [Term.occ])),
      fun h => by simp [Uses.zero] at h⟩

theorem Check.occ_none {sp : List Term} (h : Check β Φ L sp q Γ t T π u) (hi : π i = .None) :
    Term.occ i u = 0 := (h.occ i).1 hi

theorem Check.occ_lone {sp : List Term} (h : Check β Φ L sp q Γ t T π u) (hi : π i = .Lone) :
    Term.occ i u ≤ 1 := (h.occ i).2 hi

-- at a binder: the lam and let rules give π 0 ≤ q'; a Lone binder occurs at
-- most once in the body's erasure
theorem Check.occ_le {sp : List Term} (h : Check β Φ L sp q Γ t T π u) (hi : Quant.le (π i) .Lone) :
    Term.occ i u ≤ 1 := by
  cases hq : π i
  · simp [h.occ_none hq]
  · exact h.occ_lone hq
  · rw [hq] at hi; exact hi.elim

-- ----------------------------------------------------------------------------
-- N3c (i) — the strategy: the deterministic weak reduction the engine runs
-- on erasures. The head of a spine reduces first; a spine argument is
-- deepened only once its head is deep, left to right; a beta fires on a
-- deep argument, a match on a deep constructor spine, a rewrite once its
-- evidence is Rfl, a meet once its left operand is deep, a saturated
-- definition once every argument is deep, a nullary family at once, a let
-- once its value is deep
-- ----------------------------------------------------------------------------

inductive SStep (β : Book) : Term → Term → Prop
  | beta  : Deep β a → SStep β (.App (.Lam f) a) (Term.subst 0 a f)
  | let_  : Deep β v → SStep β (.Let q v b) (Term.subst 0 v b)
  | dref  : Book.defn β k = some d →
            (Term.spine s).1 = .Ref k → (Term.spine s).2.length = d.n →
            Deeps β (Term.spine s).2 →
            SStep β s (Term.apps d.body (Term.spine s).2)
  | aref  : Book.adt β k = some A → A.pn = 0 → SStep β (.Ref k) (.Adt k [])
  | matc  : Book.adt β a = some A → AdtD.ctr A c = some C →
            ps.length = A.pn → xs.length = C.fn → Deeps β (ps ++ xs) →
            SStep β (.App (.Mat a c h m) (Term.apps (.Ctr a c) (ps ++ xs))) (Term.apps h xs)
  | matm  : (a', c') ≠ (a, c) → Deeps β as →
            SStep β (.App (.Mat a c h m) (Term.apps (.Ctr a' c') as))
                    (.App m (Term.apps (.Ctr a' c') as))
  | rwt   : SStep β (.Rwt .Rfl P f) f
  | minLM : SStep β (.Min (.Qua .Many) b) b
  | minLN : SStep β (.Min (.Qua .None) b) (.Qua .None)
  | minRM : SStep β (.Min a (.Qua .Many)) a
  | minRN : SStep β (.Min a (.Qua .None)) (.Qua .None)
  | minLL : SStep β (.Min (.Qua .Lone) (.Qua .Lone)) (.Qua .Lone)
  | app_f : SStep β f f' → SStep β (.App f a) (.App f' a)
  | app_a : Deep β f → SStep β a a' → SStep β (.App f a) (.App f a')
  | let_v : SStep β v v' → SStep β (.Let q v b) (.Let q v' b)
  | rwt_e : SStep β e e' → SStep β (.Rwt e P f) (.Rwt e' P f)
  | min_a : SStep β a a' → SStep β (.Min a b) (.Min a' b)
  | min_b : Deep β a → SStep β b b' → SStep β (.Min a b) (.Min a b')

-- ----------------------------------------------------------------------------
-- Deep inversions: what a deep term's shape says of its parts
-- ----------------------------------------------------------------------------

theorem Deeps.mem : ∀ {us : List Term}, Deeps β us → ∀ u ∈ us, Deep β u
  | _, .nil, _, hu => by simp at hu
  | _, .cons h hs, u, hu => by
    simp only [List.mem_cons] at hu
    rcases hu with rfl | hu
    · exact h
    · exact Deeps.mem hs u hu

theorem Deeps.of_mem : ∀ {us : List Term}, (∀ u ∈ us, Deep β u) → Deeps β us
  | [], _ => .nil
  | _ :: _, h => .cons (h _ (by simp)) (Deeps.of_mem fun u hu => h u (by simp [hu]))

theorem Deeps.append (h1 : Deeps β us) (h2 : Deeps β vs) : Deeps β (us ++ vs) :=
  Deeps.of_mem fun u hu => by
    rw [List.mem_append] at hu
    exact hu.elim (h1.mem u) (h2.mem u)

-- the arguments of a deep spine are deep
theorem Deep.args (hd : Deep β (Term.apps h us)) (hh : h.IsHead) : Deeps β us := by
  generalize he : Term.apps h us = t at hd
  cases hd
  case efq hus => obtain ⟨rfl, rfl⟩ := Term.apps_head_inv hh (by trivial) he; exact hus
  case ctr hus => obtain ⟨rfl, rfl⟩ := Term.apps_head_inv hh (by trivial) he; exact hus
  case adt hus => obtain ⟨rfl, rfl⟩ := Term.apps_head_inv hh (by trivial) he; exact hus
  case fam _ _ hus => obtain ⟨rfl, rfl⟩ := Term.apps_head_inv hh (by trivial) he; exact hus
  case ref _ _ hus => obtain ⟨rfl, rfl⟩ := Term.apps_head_inv hh (by trivial) he; exact hus
  case rwt _ _ hus => obtain ⟨rfl, rfl⟩ := Term.apps_head_inv hh (by trivial) he; exact hus
  case matS hx _ hus =>
    obtain ⟨rfl, rfl⟩ := Term.apps_head_inv hh (by trivial) he
    exact .cons hx hus
  all_goals
    rcases apps_shape _ _ _ he with ⟨rfl, _⟩ | ⟨_, _, _, h'⟩
    · exact .nil
    · exact Term.noConfusion h'

theorem Deep.app_arg (hd : Deep β (.App f a)) : Deep β a := by
  generalize hu : Term.App f a = u at hd
  cases hd <;> try exact Term.noConfusion hu
  case matS hx _ hus =>
    obtain ⟨ys, hys, rfl⟩ := Term.app_eq_apps (by trivial) hu
    exact (Deeps.cons hx hus).mem a (by rw [hys]; simp)
  all_goals
    obtain ⟨ys, hys, rfl⟩ := Term.app_eq_apps (by trivial) hu
    rename_i hus
    exact hus.mem a (by rw [hys]; simp)

-- no deep term is a beta redex
theorem Deep.app_lam (hd : Deep β (.App (.Lam g) a)) : False := by
  generalize hu : Term.App (.Lam g) a = u at hd
  cases hd <;> try exact Term.noConfusion hu
  all_goals
    obtain ⟨ys, _, hf⟩ := Term.app_eq_apps (by trivial) hu
    exact Term.apps_ne (by trivial) (by trivial) (fun h => Term.noConfusion h) hf.symm

-- a deep match spine is stuck on a non-constructor scrutinee
theorem Deep.app_mat (hd : Deep β (.App (.Mat a c h m) x)) :
    ∀ a' c' xs, x ≠ Term.apps (.Ctr a' c') xs := by
  generalize hu : Term.App (.Mat a c h m) x = u at hd
  cases hd <;> try exact Term.noConfusion hu
  case matS hx hne _ =>
    obtain ⟨ys, hys, hf⟩ := Term.app_eq_apps (by trivial) hu
    rcases apps_shape _ _ _ hf.symm with ⟨rfl, hm⟩ | ⟨_, _, _, h'⟩
    · cases hm; cases hys; exact hne
    · exact Term.noConfusion h'
  all_goals
    obtain ⟨ys, _, hf⟩ := Term.app_eq_apps (by trivial) hu
    exact absurd hf.symm (Term.apps_ne (by trivial) (by trivial) (fun h => Term.noConfusion h))

-- a deep reference spine is a parameterized family or an underapplied
-- definition
theorem Deep.ref_inv (hd : Deep β (Term.apps (.Ref k) us)) :
    (∃ A, Book.adt β k = some A ∧ 0 < A.pn) ∨
    (∃ d, Book.defn β k = some d ∧ us.length < d.n) := by
  generalize he : Term.apps (.Ref k) us = t at hd
  cases hd
  case fam hk h0 _ =>
    obtain ⟨h1, rfl⟩ := Term.apps_head_inv (by trivial) (by trivial) he
    cases h1; exact .inl ⟨_, hk, h0⟩
  case ref hk hn _ =>
    obtain ⟨h1, rfl⟩ := Term.apps_head_inv (by trivial) (by trivial) he
    cases h1; exact .inr ⟨_, hk, hn⟩
  all_goals
    first
      | (obtain ⟨h1, _⟩ := Term.apps_head_inv (by trivial) (by trivial) he; exact Term.noConfusion
           h1)
      | (rcases apps_shape _ _ _ he with ⟨_, h'⟩ | ⟨_, _, _, h'⟩ <;> exact Term.noConfusion h')

theorem Deep.min_inv (hd : Deep β (.Min a b)) :
    Deep β a ∧ a ≠ .Qua .Many ∧ a ≠ .Qua .None ∧
    Deep β b ∧ b ≠ .Qua .Many ∧ b ≠ .Qua .None ∧ ¬ (a = .Qua .Lone ∧ b = .Qua .Lone) := by
  generalize he : Term.Min a b = t at hd
  cases hd <;> try exact Term.noConfusion he
  case min ha ha1 ha2 hb hb1 hb2 hab => cases he; exact ⟨ha, ha1, ha2, hb, hb1, hb2, hab⟩
  all_goals
    rcases apps_shape _ _ _ he.symm with ⟨_, h'⟩ | ⟨_, _, _, h'⟩ <;> exact Term.noConfusion h'

theorem Deep.rwt_inv (hd : Deep β (Term.apps (.Rwt e P f) us)) : Deep β e ∧ e ≠ .Rfl := by
  generalize he : Term.apps (.Rwt e P f) us = t at hd
  cases hd
  case rwt hd hne _ =>
    obtain ⟨h1, rfl⟩ := Term.apps_head_inv (by trivial) (by trivial) he
    cases h1; exact ⟨hd, hne⟩
  all_goals
    first
      | (obtain ⟨h1, _⟩ := Term.apps_head_inv (by trivial) (by trivial) he; exact Term.noConfusion
           h1)
      | (rcases apps_shape _ _ _ he with ⟨_, h'⟩ | ⟨_, _, _, h'⟩ <;> exact Term.noConfusion h')

theorem Deep.let_inv (hd : Deep β (.Let q v b)) : False := by
  generalize he : Term.Let q v b = t at hd
  cases hd <;> try exact Term.noConfusion he
  all_goals
    rcases apps_shape _ _ _ he.symm with ⟨_, h'⟩ | ⟨_, _, _, h'⟩ <;> exact Term.noConfusion h'

-- the erasure of a live constructor spine is the constructor spine of the
-- erased arguments (the head's rule fixes the head)
theorem Check.ctr_spine_era (hβ : Book.Closed β) {sp : List Term}
    (h : Check β (Pol.std β) L sp q Γ (Term.apps (.Ctr a c) xs) T π u) (hq : q ≠ .None) :
    ∃ us, u = Term.apps (.Ctr a c) us ∧ us.length = xs.length := by
  obtain ⟨T0, π0, u0, T1, πs, us, hh, hargs, _, _, rfl⟩ :=
    Check.apps_inv (Pol.std_pre hβ) xs (.Ctr a c) (fun _ e => Term.noConfusion e) h
  obtain ⟨_, _, _, _, _, _, _, _, rfl⟩ := hh.ctr_inv (Pol.std_pre hβ)
  refine ⟨us, ?_, hargs.length⟩
  rw [Term.era_live hq, Term.era_live hq]

-- ----------------------------------------------------------------------------
-- a live term whose erasure is deep reduces, by appLam betas and steps on
-- its live parts, to a value with the same erasure and type (the engine's
-- Z section normalizes the subject with it)
-- ----------------------------------------------------------------------------

theorem Check.deep_value (hβ : Book.Closed β) {sp : List Term}
    (h : Check β (Pol.std β) L sp q Γ t T π u) (hq : q ≠ .None) (hd : Deep β u) :
    ∃ v π', Red β .weak t v ∧ Term.Value β v ∧
      Check β (Pol.std β) (LHS.void β) sp q Γ v T π' u := by
  have hΦ := Pol.std_pre hβ
  have h0 := h
  induction h with
  | var => exact ⟨_, _, .refl, .var (as := []), h0.void_sp _⟩
  | ref hk hw hdesc =>
    rw [Term.era_live hq] at hd
    rcases Deep.ref_inv (us := []) hd with ⟨A, hA, _⟩ | ⟨d', hd', hn⟩
    · exact absurd hA (fun hA => Book.defn_adt_clash hk hA)
    · rw [hk] at hd'; cases hd'
      exact ⟨_, _, .refl, .ref (as := []) hk hn, h0.void_sp _⟩
  | refA hk h0 =>
    rw [Term.era_live hq] at hd
    rcases Deep.ref_inv (us := []) hd with ⟨A, hA, hpn⟩ | ⟨d', hd', _⟩
    · rw [hk] at hA; cases hA; omega
    · exact absurd hk (fun hk => Book.defn_adt_clash hd' hk)
  | adt => exact ⟨_, _, .refl, .adt (as := []), h0.void_sp _⟩
  | ctr => exact ⟨_, _, .refl, .ctr (as := []), h0.void_sp _⟩
  | typ => exact ⟨_, _, .refl, .typ (as := []), h0.void_sp _⟩
  | qnt => exact ⟨_, _, .refl, .qnt (as := []), h0.void_sp _⟩
  | qua => exact ⟨_, _, .refl, .qua (as := []), h0.void_sp _⟩
  | min ha hb iha ihb =>
    rw [Term.era_live hq] at hd
    obtain ⟨hda, ha1, ha2, hdb, hb1, hb2, hab⟩ := Deep.min_inv hd
    obtain ⟨va, πa', ra, hva, ha'⟩ := iha hq hda ha
    obtain ⟨vb, πb', rb, hvb, hb'⟩ := ihb hq hdb hb
    refine ⟨.Min va vb, _, (Red.min_a ra).trans (Red.min_b rb), ?_, .min ha' hb'⟩
    refine Term.Value.min (as := []) hva ?_ ?_ hvb ?_ ?_ ?_
    · rintro rfl; exact ha1 ((ha'.qua_inv hΦ).2.2.trans (Term.era_live hq _))
    · rintro rfl; exact ha2 ((ha'.qua_inv hΦ).2.2.trans (Term.era_live hq _))
    · rintro rfl; exact hb1 ((hb'.qua_inv hΦ).2.2.trans (Term.era_live hq _))
    · rintro rfl; exact hb2 ((hb'.qua_inv hΦ).2.2.trans (Term.era_live hq _))
    · rintro ⟨rfl, rfl⟩
      exact hab ⟨(ha'.qua_inv hΦ).2.2.trans (Term.era_live hq _),
        (hb'.qua_inv hΦ).2.2.trans (Term.era_live hq _)⟩
  | all => exact ⟨_, _, .refl, .all (as := []), h0.void_sp _⟩
  | lam => exact ⟨_, _, .refl, .lam, h0.void_sp _⟩
  | app hf hx ihf ihx =>
    rw [Term.era_live hq] at hd
    have hdf := Deep.app_inv hd
    have hdx := Deep.app_arg hd
    obtain ⟨vf, πf', rf, hvf, hf'⟩ := ihf hq hdf hf
    have hx0 := hx.void_sp []
    cases hvf with
    | lam =>
      obtain ⟨_, _, _, _, _, _, _, _, _, _, _, rfl⟩ := hf'.lam_inv hΦ
      rw [Term.era_live hq] at hd
      exact (Deep.app_lam hd).elim
    | mat =>
      rename_i a c hh mm
      obtain ⟨_, _, r, ps, q'', _, B'', _, _, _, _, _, _, _, _, _, hlive, _, _, _, _, hcv, _, rfl⟩
          :=
        hf'.mat_inv hΦ
      rw [Term.era_live hq] at hd
      rw [Ctx.δ_all, Ctx.δ_all] at hcv
      obtain ⟨rfl, _, _⟩ := Le.all_inv hβ hcv .refl .refl
      have hq' := hlive hq
      obtain ⟨vx, πx', rx, hvx, hx'⟩ := ihx (Quant.dem_ne hq' hq) hdx hx
      refine ⟨.App (.Mat a c hh mm) vx, _, (Red.app_f rf).trans (Red.app_a rx),
        Term.Value.matS (as := []) hvx ?_,
        Check.cnv (.app (hf'.sp _) hx') (Le.conv (Ctx.δ_conv hβ _ 0
          (Conv.substR hβ (Conv.of_red_rev rx.strong) 0 _)))⟩
      intro a' c' xs hxs
      subst hxs
      obtain ⟨us, rfl, _⟩ := hx'.ctr_spine_era hβ (Quant.dem_ne hq' hq)
      exact Deep.app_mat hd a' c' us _root_.rfl
    | ref hk hgate =>
      rename_i k d as
      obtain ⟨T0, π0, u0, T1, πs, us, hh, hargs, _, _, rfl⟩ :=
        Check.apps_inv hΦ as (.Ref k) (fun _ e => Term.noConfusion e) hf'
      rcases hh.ref_inv hΦ with ⟨d', hk', _, _, _, _, _, rfl⟩ | ⟨A, hA, _, _, _, _⟩
      · rw [hk] at hk'; cases hk'
        simp only [Term.era_live hq] at hd
        rw [← Term.apps_snoc] at hd
        rcases Deep.ref_inv hd with ⟨A, hA, _⟩ | ⟨d', hd', hn⟩
        · exact absurd hA (fun hA => Book.defn_adt_clash hk hA)
        · rw [hk] at hd'; cases hd'
          refine ⟨_, _, Red.app_f rf, ?_, .app hf' hx0⟩
          rw [← Term.apps_snoc]
          refine Term.Value.ref hk ?_
          simp at hn ⊢; rw [hargs.length] at hn; omega
      · exact absurd hA (fun hA => Book.defn_adt_clash hk hA)
    | _ =>
      exact ⟨_, _, Red.app_f rf, by rw [← Term.apps_snoc]; constructor <;> assumption, .app hf' hx0⟩
  | appLam hc hb ih =>
    obtain ⟨v, π', r, hv, h'⟩ := ih hq hd hb
    exact ⟨v, π', .step .beta r, hv, h'⟩
  | let_ =>
    rw [Term.era_live hq] at hd
    exact (Deep.let_inv hd).elim
  | eql => exact ⟨_, _, .refl, .eql (as := []), h0.void_sp _⟩
  | rfl => exact ⟨_, _, .refl, .rfl (as := []), h0.void_sp _⟩
  | rwt he hP hf ihe _ _ =>
    rw [Term.era_live hq] at hd
    obtain ⟨hde, hne⟩ := Deep.rwt_inv (us := []) hd
    obtain ⟨ve, πe', re, hve, he'⟩ := ihe hq hde he
    refine ⟨_, _, Red.rwt_e re, Term.Value.rwt (as := []) hve ?_,
      Check.cnv (.rwt he' (hP.void_sp _) (hf.void_sp _)) (Le.conv (Ctx.δ_conv hβ _ 0
        (Conv.app (Conv.refl _) (Conv.of_red_rev re.strong))))⟩
    rintro rfl
    obtain ⟨_, _, _, _, _, _, hu⟩ := he'.rfl_inv hΦ
    exact hne (hu.trans (Term.era_live hq _))
  | mat => exact ⟨_, _, .refl, .mat, h0.void_sp _⟩
  | efq => exact ⟨_, _, .refl, .efq (as := []), h0.void_sp _⟩
  | cnv hb hc ih =>
    obtain ⟨v, π', r, hv, h'⟩ := ih hq hd hb
    exact ⟨v, π', r, hv, .cnv h' hc⟩

-- ----------------------------------------------------------------------------
-- the Bad route (G): a deep erasure has no room for a stuck emptied
-- position, so no closed live term with a deep erasure inhabits an emptied
-- family, and G's exact canonical forms apply to deep erasures
-- ----------------------------------------------------------------------------

-- Bad's witness sits at a deep position of a deep erasure
theorem Term.Bad.deep (hb : Term.Bad β q v u) (hd : Deep β u) :
    ∃ x a r ps πx ux, Book.empty β a r ∧
      Check β (Pol.std β) (LHS.void β) [] q [] x (Term.apps (.Adt a r) ps) πx ux ∧
      Term.size ux < Term.size u ∧ Deep β ux := by
  induction hb with
  | efq hemp hx =>
    exact ⟨_, _, _, _, _, _, hemp, hx,
      Term.size_spine_arg _ _ (by rw [Term.spine_apps (h := .Efq) (by trivial)]; simp),
      (Deep.args hd (by trivial)).mem _ (by simp)⟩
  | rwt _ ih =>
    obtain ⟨x, a, r, ps, πx, ux, hemp, hx, hlt, hdx⟩ := ih (Deep.rwt_inv hd).1
    exact ⟨x, a, r, ps, πx, ux, hemp, hx, Nat.lt_trans hlt (Term.size_rwt _ _ _ _), hdx⟩
  | matS _ ih =>
    obtain ⟨x, a, r, ps, πx, ux, hemp, hx, hlt, hdx⟩ := ih ((Deep.args hd (by trivial)).mem _
        (by simp))
    exact ⟨x, a, r, ps, πx, ux, hemp, hx, Nat.lt_trans hlt (Term.size_matS _ _ _ _ _ _), hdx⟩
  | minL _ ih =>
    obtain ⟨x, a, r, ps, πx, ux, hemp, hx, hlt, hdx⟩ := ih (Deep.min_inv hd).1
    exact ⟨x, a, r, ps, πx, ux, hemp, hx, by simp only [Term.size]; omega, hdx⟩
  | minR _ ih =>
    obtain ⟨x, a, r, ps, πx, ux, hemp, hx, hlt, hdx⟩ := ih (Deep.min_inv hd).2.2.2.1
    exact ⟨x, a, r, ps, πx, ux, hemp, hx, by simp only [Term.size]; omega, hdx⟩

theorem Check.deep_empty_aux (hok : Book.Ok β) :
    ∀ (n : Nat) {t T : Term} {π : Uses} {u : Term} {a : Nat} {r : List Nat} {ps : List Term},
    Term.size u ≤ n → Check β (Pol.std β) (LHS.void β) [] .Lone [] t T π u → Deep β u →
    Le β T (Term.apps (.Adt a r) ps) → Book.empty β a r → False := by
  intro n
  induction n with
  | zero => intro t T π u a r ps hn _ _ _ _; have := Term.size_pos u; omega
  | succ n ih =>
    intro t T π u a r ps hn h hd hT hemp
    obtain ⟨v, π', _, hv, h'⟩ := h.deep_value hok.closed (by decide) hd
    obtain ⟨x, a', r', ps', πx, ux, hemp', hx, hlt, hdx⟩ :=
      (Check.canon_empty hok (by decide) hv h' hT hemp).deep hd
    exact ih (by omega) hx hdx (Le.refl _) hemp'

-- no closed live term with a deep erasure inhabits an emptied family
theorem Check.deep_empty (hok : Book.Ok β)
    (h : Check β (Pol.std β) (LHS.void β) [] .Lone [] t T π u) (hd : Deep β u)
    (hT : Le β T (Term.apps (.Adt a r) ps)) (hemp : Book.empty β a r) : False :=
  Check.deep_empty_aux hok _ (Nat.le_refl _) h hd hT hemp

-- so a value with a deep erasure is never Bad: G's exact forms apply
theorem Check.deep_not_bad (hok : Book.Ok β) (hd : Deep β u) :
    ¬ Term.Bad β .Lone v u := fun hb =>
  let ⟨_, _, _, _, _, _, hemp, hx, _, hdx⟩ := hb.deep hd
  Check.deep_empty hok hx hdx (Le.refl _) hemp

-- ----------------------------------------------------------------------------
-- N3b (i) — tools: policy monotonicity, the head a fitted type reduces to,
-- and the constructor walk instantiated at closed values
-- ----------------------------------------------------------------------------

-- the judgment only grows with its policy
theorem Check.mono (hc : ∀ x y, Φ.conv x y → Φ'.conv x y) (he : ∀ Γ, Φ.efq Γ → Φ'.efq Γ)
    {sp : List Term} (h : Check β Φ L sp q Γ t T π u) :
    Check β Φ' L sp q Γ t T π u := by
  induction h with
  | var hg => exact .var hg
  | ref hk hw hd => exact .ref hk hw hd
  | refA hk h0 => exact .refA hk h0
  | adt hk => exact .adt hk
  | ctr hk hC hr => exact .ctr hk hC hr
  | typ _ ihg => exact .typ ihg
  | qnt => exact .qnt
  | qua => exact .qua
  | min _ _ iha ihb => exact .min iha ihb
  | all _ _ ihA ihB => exact .all ihA ihB
  | lam _ _ hle ihA ihf => exact .lam ihA ihf hle
  | app _ _ ihf ihx => exact .app ihf ihx
  | appLam ha _ ih => exact .appLam ha ih
  | let_ _ _ _ hle ihv ihA ihb => exact .let_ ihv ihA ihb hle
  | eql _ _ _ ihT iha ihb => exact .eql ihT iha ihb
  | rfl hcv => exact .rfl hcv
  | rwt _ _ _ ihe ihP ihf => exact .rwt ihe ihP ihf
  | mat hk hC hr hlen hlive hins hgoal _ _ ihh ihm => exact .mat hk hC hr hlen hlive hins hgoal ihh ihm
  | efq hk hlive hd => exact .efq hk hlive (hd.imp id (he _))
  | cnv _ hcv iht => exact .cnv iht (hc _ _ hcv)

-- a type fitted above a stable head form reduces to the same head form
theorem Le.typ_r (h : Le β (.Typ g) b) : ∃ g', Red β .strong b (.Typ g') := by
  rcases h.inv with ⟨c, r1, r2⟩ | ⟨_, g', _, r2, _⟩ | ⟨_, _, _, _, _, r1, _⟩ | ⟨_, _, _, _, _, r1,
      _⟩
  · obtain ⟨g', rfl, _⟩ := r1.typ_inv; exact ⟨g', r2⟩
  · exact ⟨g', r2⟩
  · obtain ⟨_, h', _⟩ := r1.typ_inv; exact Term.noConfusion h'
  · obtain ⟨_, h', _⟩ := r1.typ_inv
    exact absurd h' (Term.apps_adt_ne (by trivial) (fun e => Term.noConfusion e))

theorem Le.all_r (h : Le β (.All q A B) b) : ∃ A' B', Red β .strong b (.All q A' B') := by
  rcases h.inv with ⟨c, r1, r2⟩ | ⟨_, _, r1, _⟩ | ⟨_, _, _, A', B', r1, r2, _⟩ | ⟨_, _, _, _, _,
      r1, _⟩
  · obtain ⟨A', B', rfl, _⟩ := r1.all_inv; exact ⟨A', B', r2⟩
  · obtain ⟨_, _, h', _⟩ := r1.all_inv; exact Term.noConfusion h'
  · obtain ⟨_, _, h', _⟩ := r1.all_inv; cases h'; exact ⟨A', B', r2⟩
  · obtain ⟨_, _, h', _⟩ := r1.all_inv
    exact absurd h' (Term.apps_adt_ne (by trivial) (fun e => Term.noConfusion e))

theorem Le.qnt_r (h : Le β .Qnt b) : Red β .strong b .Qnt := by
  rcases h.inv with ⟨c, r1, r2⟩ | ⟨_, _, r1, _⟩ | ⟨_, _, _, _, _, r1, _⟩ | ⟨_, _, _, _, _, r1, _⟩
  · rw [r1.qnt_inv] at r2; exact r2
  · exact Term.noConfusion r1.qnt_inv
  · exact Term.noConfusion r1.qnt_inv
  · exact absurd r1.qnt_inv (Term.apps_adt_ne (by trivial) (fun e => Term.noConfusion e))

theorem Le.adt_r (h : Le β (Term.apps (.Adt a r) ps) b) :
    ∃ r' ps', Red β .strong b (Term.apps (.Adt a r') ps') ∧ (∀ c, c ∈ r' → c ∈ r) ∧ Convs β ps ps'
        := by
  rcases h.inv with ⟨c, r1, r2⟩ | ⟨_, _, r1, _⟩ | ⟨_, _, _, _, _, r1, _⟩ | ⟨x, r0, ps0, r', ps',
      r1, r2, hsub, hl, hc⟩
  · obtain ⟨ps1, rfl, hr⟩ := r1.adt_inv; exact ⟨r, ps1, r2, fun _ h => h, hr.convs (Reds.refl _)⟩
  · obtain ⟨_, h', _⟩ := r1.adt_inv
    exact absurd h'.symm (Term.apps_adt_ne (by trivial) (fun e => Term.noConfusion e))
  · obtain ⟨_, h', _⟩ := r1.adt_inv
    exact absurd h'.symm (Term.apps_adt_ne (by trivial) (fun e => Term.noConfusion e))
  · obtain ⟨ps1, h', hr⟩ := r1.adt_inv
    obtain ⟨h1, rfl⟩ := Term.apps_head_inv (by trivial) (by trivial) h'
    cases h1
    exact ⟨r', ps', r2, hsub, Convs.of_reds hr (Reds.refl _) (Convs.of_index hl hc)⟩

-- a telescope: All binders tipped at a family instance
def Term.IsTele : Term → Prop
  | .All _ _ B => Term.IsTele B
  | t => ∃ a r ps, t = Term.apps (.Adt a r) ps

theorem Term.IsTele.adt (a : Nat) (r : List Nat) (ps : List Term) :
    Term.IsTele (Term.apps (.Adt a r) ps) := by
  rcases apps_shape ps (.Adt a r) _ rfl with ⟨h1, _⟩ | ⟨as0, al, _, h2⟩
  · rw [h1]; exact ⟨a, r, [], rfl⟩
  · rw [h2]; exact ⟨a, r, ps, h2.symm⟩

theorem FTele.isTele : ∀ {k : Nat} {ps : List Term} {T : Term}, FTele a r ps k T → Term.IsTele T :=
    by
  intro k
  induction k with
  | zero => intro ps T h; simp only [FTele] at h; subst h; exact Term.IsTele.adt a r ps
  | succ k ih => intro ps T h; obtain ⟨_, _, _, rfl, h⟩ := h; simp only [Term.IsTele]; exact ih h

theorem WTele.isTele : ∀ {pn : Nat} {ps : List Term} {T : Term}, WTele a r ps pn fn T → Term.IsTele
    T := by
  intro pn
  induction pn with
  | zero => intro ps T h; exact FTele.isTele h
  | succ pn ih => intro ps T h; obtain ⟨_, _, _, rfl, h⟩ := h; simp only [Term.IsTele]; exact ih h

-- the constructor walk at a policy and the void equation: CtrOk's shape,
-- with a Lone field kinded at Kind(G) as bend.ts's adt_valid does (the
-- spec's CtrOk writes the bare quantity there)
def CtrOkD (β : Book) (Φ : Pol) (pn : Nat) (G : Term) : Ctx → Nat → Term → Prop
  | Γ, i, .All q A B =>
      (∃ π, Check β Φ (LHS.void β) [] .None Γ A
        (if pn ≤ i ∧ q = .Lone then .Typ (Term.shiftN (i - pn) G) else .Typ (.Qua q)) π .Qnt) ∧
      CtrOkD β Φ pn G (⟨q, A, none⟩ :: Γ) (i + 1) B
  | _, _, _ => True

-- instantiating the walk's outermost binder at a closed value
theorem CtrOkD.substLast (hβ : Book.Closed β) (hΦ : Φ.Weak)
    (hefq : ∀ Γ, Φ.efq (Γ ++ [b0]) → Φ.efq (Ctx.substLast w Γ))
    (hw : Term.Closed 0 w) (hv : b0.v = none)
    (h0 : Check β Φ (LHS.void β) [] .None [] w b0.T Uses.zero .Qnt)
    (hcase : (pn = 0 ∧ pn' = 0 ∧ G' = G) ∨ (∃ pk, pn = pk + 1 ∧ pn' = pk ∧ G' = Term.subst pk w G))
        :
    ∀ {T : Term} {Γ : Ctx}, Term.IsTele T → CtrOkD β Φ pn G (Γ ++ [b0]) (Γ.length + 1) T →
    CtrOkD β Φ pn' G' (Ctx.substLast w Γ) Γ.length (Term.subst Γ.length w T) := by
  intro T
  induction T with
  | All q A B _ ih =>
    intro Γ hT h
    obtain ⟨⟨π, hA⟩, hB⟩ := h
    have hA' := Check.subst hβ hΦ hA hw (by trivial) (.inl hv) h0 hefq Γ rfl (by simp)
      (fun h => absurd (hA.none_at _) h)
    have hK : Term.subst Γ.length w
        (if pn ≤ Γ.length + 1 ∧ q = .Lone then .Typ (Term.shiftN (Γ.length + 1 - pn) G) else .Typ
            (.Qua q))
        = (if pn' ≤ Γ.length ∧ q = .Lone then .Typ (Term.shiftN (Γ.length - pn') G') else .Typ
            (.Qua q)) := by
      rcases hcase with ⟨rfl, rfl, rfl⟩ | ⟨pk, hpn, hpn', hG'⟩
      · split <;> rename_i h1 <;> split <;> rename_i h2
        · show Term.Typ _ = Term.Typ _
          rw [Nat.sub_zero, Nat.sub_zero, Term.subst_shiftN]
        · exact absurd ⟨Nat.zero_le _, h1.2⟩ h2
        · exact absurd ⟨Nat.zero_le _, h2.2⟩ h1
        · rfl
      · subst hpn hG'
        rw [hpn']
        split <;> rename_i h1 <;> split <;> rename_i h2
        · show Term.Typ _ = Term.Typ _
          rw [show Γ.length + 1 - (pk + 1) = Γ.length - pk by omega]
          have := Term.subst_shiftN_add hw (Γ.length - pk) pk G
          rw [show Γ.length - pk + pk = Γ.length by omega] at this
          rw [this]
        · exact absurd ⟨by omega, h1.2⟩ h2
        · exact absurd ⟨by omega, h2.2⟩ h1
        · rfl
    refine ⟨⟨_, hK ▸ hA'⟩, ?_⟩
    rw [Term.shift_closed w 0 0 hw (Nat.le_refl 0)]
    exact ih (Γ := ⟨q, A, none⟩ :: Γ) hT hB
  | Var j =>
    intro Γ hT _
    obtain ⟨_, _, _, h⟩ := hT
    exact absurd h.symm (Term.apps_adt_ne (by trivial) (fun e => Term.noConfusion e))
  | _ => intros; simp only [Term.subst]; trivial

-- the kind of a family after instantiating its parameters, outermost first
def Term.instG : List Term → Term → Term
  | [],      G => G
  | p :: ps, G => Term.instG ps (Term.subst ps.length p G)

-- the parameter prefix of a constructor spine instantiates the walk (E's
-- Args.params with the walk carried along; the parameters check dead)
theorem CtrOkD.params (hβ : Book.Closed β) (hΦ : Φ.Weak)
    (hc : ∀ x y, Le β x y → Φ.conv x y) (he : ∀ Γ, CtxDead β Γ → Φ.efq Γ)
    (hefq : ∀ Γ b0 w, Φ.efq (Γ ++ [b0]) → Φ.efq (Ctx.substLast w Γ)) :
    ∀ {qs : List Term} {pn : Nat} {ps0 : List Term} {Tw T0 Tm G : Term} {πp : Uses} {up : List
        Term},
    WTele a r ps0 pn fn Tw → CtrOkD β Φ pn G [] 0 Tw →
    Args β (Pol.std β) L q [] T0 qs Tm πp up →
    Le β (Term.retip r' pn (pn + fn) Tw) T0 → qs.length = pn →
    ∃ TS, Insts Tw qs TS ∧ FTele a r (ps0 ++ qs) fn TS ∧
      Le β (Term.retip r' 0 fn TS) Tm ∧ CtrOkD β Φ 0 (Term.instG qs G) [] 0 TS ∧
      (∀ u ∈ up, u = .Qnt) := by
  intro qs
  induction qs with
  | nil =>
    intro pn ps0 Tw T0 Tm G πp up hw hD h hle hlen
    cases h
    cases pn with
    | zero =>
      rw [Nat.zero_add] at hle
      exact ⟨Tw, .nil, by rw [List.append_nil]; exact hw, hle, hD, fun _ h => by simp at h⟩
    | succ pk => simp at hlen
  | cons x qs ih =>
    intro pn ps0 Tw T0 Tm G πp up hw hD h hle hlen
    cases pn with
    | zero => simp at hlen
    | succ pk =>
      obtain ⟨qw, K, Bw, hT, hwB, hw'⟩ := WTele.param (x := x) hw
      subst hT
      rw [show pk + 1 + fn = pk + fn + 1 by omega] at hle
      obtain ⟨πx, ux, πs', us', B1, _, rfl, hx, hB, hr⟩ :=
        Args.step hβ (Γ := []) (qw := .None) (K := K) (Bw := Term.retip r' pk (pk + fn) Bw) hle h
      rw [WTele.retip_subst hwB r' 0 x] at hB
      obtain ⟨⟨πK, hK⟩, hrest⟩ := hD
      have hx0 : Check β Φ (LHS.void β) [] .None [] x K Uses.zero .Qnt :=
        (hx.dead.void).mono hc he
      have hD' := CtrOkD.substLast hβ hΦ (fun Γ => hefq Γ ⟨qw, K, none⟩ x) (hx.closed) rfl hx0
        (.inr ⟨pk, rfl, rfl, rfl⟩) (Γ := []) hwB.isTele hrest
      obtain ⟨TS, hI, hF, hle', hD'', hup⟩ := ih hw' hD' hr hB (by simp at hlen; omega)
      refine ⟨TS, .cons hI, by simpa [List.append_assoc] using hF, hle', ?_, ?_⟩
      · simp only [Term.instG]
        rw [show qs.length = pk by simp at hlen; omega]
        exact hD''
      · intro u hu
        simp only [List.mem_cons] at hu
        rcases hu with rfl | hu
        · exact hx.none_era _root_.rfl
        · exact hup u hu

-- the quantities of the first n binders of a telescope
def Term.allQs : Nat → Term → List Quant
  | 0, _ => []
  | n + 1, .All q _ B => q :: Term.allQs n B
  | _ + 1, _ => []

theorem FTele.allQs_subst : ∀ (k : Nat) {ps : List Term} {T : Term}, FTele a r ps k T →
    ∀ (d : Nat) (w : Term), Term.allQs k (Term.subst d w T) = Term.allQs k T := by
  intro k
  induction k with
  | zero => intro ps T _ d w; rfl
  | succ k ih =>
    intro ps T h d w
    obtain ⟨qf, F, B, rfl, hB⟩ := h
    simp only [Term.subst, Term.allQs]
    rw [ih hB]

-- the field walk: every field checks at a domain the instantiated walk
-- kinds — at the family's kind for a Lone field, at Kind(q) otherwise —
-- with the field's binder quantity read off the telescope
theorem CtrOkD.fields_qs (hβ : Book.Closed β) (hΦ : Φ.Weak)
    (hc : ∀ x y, Le β x y → Φ.conv x y) (he : ∀ Γ, CtxDead β Γ → Φ.efq Γ)
    (hefq : ∀ Γ b0 w, Φ.efq (Γ ++ [b0]) → Φ.efq (Ctx.substLast w Γ)) :
    ∀ {xs : List Term} {fn : Nat} {ps : List Term} {TS T0 T1 : Term} {πs : Uses} {us : List Term},
    FTele a r ps fn TS → CtrOkD β Φ 0 G' [] 0 TS →
    Args β (Pol.std β) L q [] T0 xs T1 πs us →
    Le β (Term.retip r' 0 fn TS) T0 → xs.length = fn →
    ∀ (j : Nat) x u, xs[j]? = some x → us[j]? = some u →
      ∃ qf F πx, (Term.allQs fn TS)[j]? = some qf ∧ Check β (Pol.std β) L [] (Quant.dem qf q) [] x
          F πx u ∧
        ∃ π, Check β Φ (LHS.void β) [] .None [] F (if qf = .Lone then .Typ G' else .Typ (.Qua qf))
            π .Qnt := by
  intro xs
  induction xs with
  | nil => intro fn ps TS T0 T1 πs us _ _ _ _ _ j x u hx; simp at hx
  | cons x xs ih =>
    intro fn ps TS T0 T1 πs us hF hD h hle hlen j x' u hx' hu
    cases fn with
    | zero => simp at hlen
    | succ fk =>
      obtain ⟨qf, F, Bs, hT, hFB, hF'⟩ := FTele.field (x := x) hF
      subst hT
      obtain ⟨πx, ux, πs', us', B1, rfl, rfl, hx, hB, hr⟩ :=
        Args.step hβ (Γ := []) (qw := qf) (K := F) (Bw := Term.retip r' 0 fk Bs) hle h
      rw [FTele.retip_subst hFB r' 0 x] at hB
      obtain ⟨⟨πF, hKF⟩, hrest⟩ := hD
      have hx0 : Check β Φ (LHS.void β) [] .None [] x F Uses.zero .Qnt :=
        (hx.dead.void).mono hc he
      have hD' := CtrOkD.substLast hβ hΦ (fun Γ => hefq Γ ⟨qf, F, none⟩ x) (hx.closed) rfl hx0
        (.inl ⟨rfl, rfl, rfl⟩) (Γ := []) hFB.isTele hrest
      cases j with
      | zero =>
        simp at hx' hu
        subst hx' hu
        refine ⟨qf, F, πx, by simp [Term.allQs], hx, πF, ?_⟩
        simpa [Term.shiftN] using hKF
      | succ j =>
        simp at hx' hu
        obtain ⟨T', hr', hle'⟩ := hr.le_start (Pol.std_pre hβ) hB
        obtain ⟨qf', F', πx', hq, hx'', hK⟩ := ih hF' hD' hr' (Le.refl _) (by simp at hlen; omega)
            j x' u hx' hu
        refine ⟨qf', F', πx', ?_, hx'', hK⟩
        simp only [Term.allQs, List.getElem?_cons_succ]
        rw [← FTele.allQs_subst fk hFB 0 x]; exact hq

-- ----------------------------------------------------------------------------
-- N3c (ii) — the erased book: Deep reads only arities and families, which
-- an erasure keeps (F's Book.Era)
-- ----------------------------------------------------------------------------

theorem Book.Era.tld_iff (h : Book.Era β k bs bs') : ∀ j,
    (∀ A, Book.tld bs j = some (.adt A) ↔ Book.tld bs' j = some (.adt A)) ∧
    (∀ n, (∃ d, Book.tld bs j = some (.defn d) ∧ d.n = n) ↔
          (∃ d', Book.tld bs' j = some (.defn d') ∧ d'.n = n)) := by
  induction h with
  | nil => intro j; exact ⟨fun _ => Iff.rfl, fun _ => Iff.rfl⟩
  | keepA _ ih => intro j; cases j with
    | zero => exact ⟨fun _ => Iff.rfl, fun _ => Iff.rfl⟩
    | succ j => exact ih j
  | era _ _ ih => intro j; cases j with
    | zero =>
      refine ⟨fun _ => ⟨fun h => (by cases h), fun h => (by cases h)⟩, fun n => ⟨?_, ?_⟩⟩
      · rintro ⟨d, hd, rfl⟩; cases hd; exact ⟨_, rfl, rfl⟩
      · rintro ⟨d, hd, rfl⟩; cases hd; exact ⟨_, rfl, rfl⟩
    | succ j => exact ih j

theorem Book.Era.adt_iff (h : Book.Era β 0 β βe) (k : Nat) (A : AdtD) :
    Book.adt β k = some A ↔ Book.adt βe k = some A := by
  have := (h.tld_iff k).1 A
  unfold Book.adt
  constructor
  · intro h'; split at h' <;> cases h'; rw [this.1 (by assumption)]
  · intro h'; split at h' <;> cases h'; rw [this.2 (by assumption)]

theorem Book.Era.defn_n (h : Book.Era β 0 β βe) (k n : Nat) :
    (∃ d, Book.defn β k = some d ∧ d.n = n) ↔ (∃ d', Book.defn βe k = some d' ∧ d'.n = n) := by
  have := (h.tld_iff k).2 n
  unfold Book.defn
  constructor
  · rintro ⟨d, hd, rfl⟩
    split at hd <;> cases hd
    obtain ⟨d', hd', hn⟩ := this.1 ⟨_, by assumption, rfl⟩
    exact ⟨d', by rw [hd'], hn⟩
  · rintro ⟨d, hd, rfl⟩
    split at hd <;> cases hd
    obtain ⟨d', hd', hn⟩ := this.2 ⟨_, by assumption, rfl⟩
    exact ⟨d', by rw [hd'], hn⟩

-- Deep transports along any two books agreeing on families and arities
mutual
theorem Deep.book (hA : ∀ k A, Book.adt β k = some A ↔ Book.adt β' k = some A)
    (hD : ∀ k n, (∃ d, Book.defn β k = some d ∧ d.n = n) ↔ (∃ d', Book.defn β' k = some d' ∧ d'.n =
        n))
    (hd : Deep β u) : Deep β' u :=
  match hd with
  | .qnt => .qnt
  | .typ => .typ
  | .qua => .qua
  | .all => .all
  | .eql => .eql
  | .rfl => .rfl
  | .lam => .lam
  | .mat => .mat
  | .efq hus => .efq (Deeps.book hA hD hus)
  | .ctr hus => .ctr (Deeps.book hA hD hus)
  | .adt hus => .adt (Deeps.book hA hD hus)
  | .fam hk hpn hus => .fam ((hA _ _).1 hk) hpn (Deeps.book hA hD hus)
  | .ref hk hn hus =>
    let ⟨_, hk', hn'⟩ := (hD _ _).1 ⟨_, hk, rfl⟩
    .ref hk' (hn' ▸ hn) (Deeps.book hA hD hus)
  | .rwt he hne hus => .rwt (Deep.book hA hD he) hne (Deeps.book hA hD hus)
  | .matS hx hne hus => .matS (Deep.book hA hD hx) hne (Deeps.book hA hD hus)
  | .min ha h1 h2 hb h3 h4 h5 => .min (Deep.book hA hD ha) h1 h2 (Deep.book hA hD hb) h3 h4 h5
theorem Deeps.book (hA : ∀ k A, Book.adt β k = some A ↔ Book.adt β' k = some A)
    (hD : ∀ k n, (∃ d, Book.defn β k = some d ∧ d.n = n) ↔ (∃ d', Book.defn β' k = some d' ∧ d'.n =
        n))
    (hd : Deeps β us) : Deeps β' us :=
  match hd with
  | .nil => .nil
  | .cons h hs => .cons (Deep.book hA hD h) (Deeps.book hA hD hs)
end

theorem Deep.era (hE : Book.Era β 0 β βe) (hd : Deep β u) : Deep βe u :=
  Deep.book hE.adt_iff hE.defn_n hd

theorem Deep.era' (hE : Book.Era β 0 β βe) (hd : Deep βe u) : Deep β u :=
  Deep.book (fun k A => (hE.adt_iff k A).symm) (fun k n => (hE.defn_n k n).symm) hd

-- ----------------------------------------------------------------------------
-- N3c (iii) — the typed steps at the strategy's positions
-- ----------------------------------------------------------------------------

-- a live term whose erasure is a quantity literal reduces to it
theorem Check.qua_red (hok : Book.Ok β) {sp : List Term}
    (h : Check β (Pol.std β) (LHS.void β) sp .Lone [] a .Qnt π (.Qua q0)) :
    Red β .weak a (.Qua q0) := by
  obtain ⟨v, π', r, hv, h'⟩ := h.deep_value hok.closed (by decide) .qua
  obtain ⟨q1, rfl⟩ := (Check.value_head hok (by decide) hv h'
    (Check.deep_not_bad hok .qua)).at_qnt hok.closed (Le.refl _)
  obtain ⟨_, _, hu⟩ := h'.qua_inv (Pol.std_pre hok.closed)
  cases hu
  exact r

-- the erasure of a live spine with a non-lambda head
theorem Check.spine_era (hβ : Book.Closed β) {sp : List Term} (hl : ∀ g, h ≠ .Lam g)
    (hc : Check β (Pol.std β) L sp .Lone Γ (Term.apps h as) T π u) :
    ∃ T0 π0 u0 T1 πs us, Check β (Pol.std β) L (as ++ sp) .Lone Γ h T0 π0 u0 ∧
      Args β (Pol.std β) L .Lone Γ T0 as T1 πs us ∧ Le β (Ctx.δ Γ 0 T1) (Ctx.δ Γ 0 T) ∧
      u = Term.apps u0 us ∧ us.length = as.length := by
  obtain ⟨T0, π0, u0, T1, πs, us, hh0, hargs, hle, _, rfl⟩ :=
    Check.apps_inv (Pol.std_pre hβ) as h hl hc
  exact ⟨T0, π0, u0, T1, πs, us, hh0, hargs, hle, _root_.rfl, hargs.length⟩

-- the app-typed beta: the contractum at the substituted erasure (F's
-- Check.beta cannot tell an app-typed redex from an appLam-typed one)
theorem Check.beta_app (hβ : Book.Closed β) {sp : List Term}
    (hf : Check β (Pol.std β) (LHS.void β) (x :: sp) .Lone [] (.Lam g) (.All q' A B) πf (.Lam ug))
    (hx : Check β (Pol.std β) (LHS.void β) [] (Quant.dem q' .Lone) [] x A πx ux)
    (hd : Check.Dead β x ux) :
    ∃ π', Check β (Pol.std β) (LHS.void β) sp .Lone [] (Term.subst 0 x g) (Term.subst 0 x B) π'
      (Term.subst 0 ux ug) := by
  have hΦ := Pol.std_pre hβ
  obtain ⟨q1, A1, B1, πA, π1, uf1, hA, hb, hle1, hleF, hπf, huf⟩ := hf.lam_inv hΦ
  cases huf
  obtain ⟨rfl, hAA, hBB⟩ := Le.all_inv hβ hleF .refl .refl
  have hA1 : Term.Closed 0 A1 := hA.closed
  have hres : Check β (Pol.std β) (LHS.void β) [] .Lone [] (Term.subst 0 x g)
      (Term.subst 0 x B1) (Uses.del 0 π1) (Term.subst 0 ux ug) := by
    by_cases hq : q1 = .None
    · subst hq
      exact Check.subst_std hβ (Γ := []) (b0 := ⟨.None, A1, none⟩) hb (by decide) hx.closed
        hx.closed_era (.inl _root_.rfl) (hx.dead.cnv hAA)
        (fun hne => absurd (Quant.le_none_eq hle1) hne) (fun h => absurd _root_.rfl h)
    · rw [Quant.dem_live hq] at hx
      exact Check.subst_std hβ (Γ := []) (b0 := ⟨q1, A1, none⟩) hb (by decide) hx.closed
        hx.closed_era (.inl _root_.rfl) (hx.dead.cnv hAA) (fun _ => ⟨πx, hx.cnv hAA⟩)
        (fun _ m e r ps hconv hemp => hd (hx.cnv hAA) e r ps
          (by rwa [Term.shiftN_closed hA1] at hconv) hemp)
  exact ⟨_, (hres.cnv (Le.subst hβ hBB 0 x)).sp sp⟩

-- ----------------------------------------------------------------------------
-- N3c (iv) — strategy progress: a live closed term whose erasure is not
-- deep steps, on the subject by appLam betas and one live step, on the
-- erasure by the strategy, and the result is typed at the same type
-- ----------------------------------------------------------------------------

theorem Check.sstep_gen (hok : Book.Ok β) (hE : Book.Era β 0 β βe)
    {sp : List Term} (h : Check β (Pol.std β) L sp q Γ t T π u)
    (hL : L = LHS.void β) (hΓ : Γ = []) (hq : q = .Lone) (hnd : ¬ Deep β u) :
    ∃ t' u' π', Red β .weak t t' ∧ SStep βe u u' ∧
      Check β (Pol.std β) (LHS.void β) sp .Lone [] t' T π' u' := by
  have hβ := hok.closed
  have hΦ := Pol.std_pre hβ
  induction h with
  | var hg => subst hΓ; simp [Ctx.get] at hg
  | ref hk hw hd =>
    subst hL hΓ hq
    rename_i j d sp0
    simp only [Term.era_lone] at hnd ⊢
    by_cases hn : d.n = 0
    · obtain ⟨π', ub', us, hres, hu, hlen, hkE'⟩ :=
        Check.dref_step hβ hE hk (as := []) ((Check.ref hk hw hd).void_sp [])
      obtain rfl : us = [] := by cases us with | nil => rfl | cons _ _ => simp at hlen
      have hs := SStep.dref (β := βe) hkE' (s := .Ref _) _root_.rfl
          (by simp [Term.spine, hn]) .nil
      exact ⟨_, _, π', Red.one (Step.dref hk (s := .Ref _) _root_.rfl hn.symm), hs, hres.sp _⟩
    · exact absurd (Deep.ref (us := []) hk (by simp; omega) .nil) hnd
  | refA hk h0 =>
    subst hL hΓ hq
    simp only [Term.era_lone] at hnd ⊢
    obtain ⟨hres, _⟩ := Check.aref_step hβ hk (Check.refA (sp := []) hk h0)
    exact ⟨_, _, _, Red.one (Step.aref hk h0), SStep.aref ((hE.adt_iff _ _).1 hk) h0, hres.sp _⟩
  | adt => subst hq; exact absurd (Deep.adt (us := []) .nil) hnd
  | ctr => subst hq; exact absurd (Deep.ctr (us := []) .nil) hnd
  | typ => subst hq; exact absurd .typ hnd
  | qnt => exact absurd .qnt hnd
  | qua => subst hq; exact absurd .qua hnd
  | all => subst hq; exact absurd .all hnd
  | lam => subst hq; exact absurd .lam hnd
  | mat => subst hq; exact absurd .mat hnd
  | efq => subst hq; exact absurd (Deep.efq (us := []) .nil) hnd
  | eql => subst hq; exact absurd .eql hnd
  | rfl => subst hq; exact absurd .rfl hnd
  | min ha hb iha ihb =>
    subst hL hΓ hq
    rename_i a πa ua b πb ub sp0
    simp only [Term.era_lone] at hnd ⊢
    by_cases hda : Deep β ua
    · by_cases h1 : ua = Term.Qua .Many
      · subst h1
        exact ⟨_, _, _, (Red.min_a (Check.qua_red hok ha)).trans (Red.one .minLM), .minLM, hb.sp
            _⟩
      by_cases h2 : ua = Term.Qua .None
      · subst h2
        exact ⟨_, _, _, (Red.min_a (Check.qua_red hok ha)).trans (Red.one .minLN), .minLN,
            Check.qua⟩
      by_cases hdb : Deep β ub
      · by_cases h3 : ub = Term.Qua .Many
        · subst h3
          exact ⟨_, _, _, (Red.min_b (Check.qua_red hok hb)).trans (Red.one .minRM), .minRM,
              ha.sp _⟩
        by_cases h4 : ub = Term.Qua .None
        · subst h4
          exact ⟨_, _, _, (Red.min_b (Check.qua_red hok hb)).trans (Red.one .minRN), .minRN,
              Check.qua⟩
        by_cases h5 : ua = Term.Qua .Lone ∧ ub = Term.Qua .Lone
        · obtain ⟨rfl, rfl⟩ := h5
          exact ⟨_, _, _, (Red.min_a (Check.qua_red hok ha)).trans
            ((Red.min_b (Check.qua_red hok hb)).trans (Red.one .minLL)), .minLL, Check.qua⟩
        · exact absurd (Deep.min hda h1 h2 hdb h3 h4 h5) hnd
      · obtain ⟨b', ub', πb', rb, sb, hb'⟩ := ihb _root_.rfl _root_.rfl _root_.rfl hdb
        exact ⟨_, _, _, Red.min_b rb, .min_b (hda.era hE) sb, Check.min ha hb'⟩
    · obtain ⟨a', ua', πa', ra, sa, ha'⟩ := iha _root_.rfl _root_.rfl _root_.rfl hda
      exact ⟨_, _, _, Red.min_a ra, .min_a sa, Check.min ha' hb⟩
  | appLam hc hb ih =>
    obtain ⟨t', u', π', r, s, h'⟩ := ih hL hΓ hq hnd
    exact ⟨t', u', π', .step .beta r, s, h'⟩
  | cnv hb hc ih =>
    subst hL hΓ hq
    obtain ⟨t', u', π', r, s, h'⟩ := ih _root_.rfl _root_.rfl _root_.rfl hnd
    exact ⟨t', u', π', r, s, h'.cnv hc⟩
  | rwt he hP hf ihe ihP ihf =>
    subst hL hΓ hq
    rename_i e a b T0 πe ue P πP f πf uf sp0
    simp only [Term.era_lone] at hnd ⊢
    by_cases hde : Deep β ue
    · obtain ⟨ve, πe', re, hve, he'⟩ := he.deep_value hβ (by decide) hde
      have hrfl := (Check.value_head hok (by decide) hve he'
        (Check.deep_not_bad hok hde)).at_eql hβ (Le.refl _)
      subst hrfl
      obtain ⟨a0, b0, T0, hab, hle0, _, hue⟩ := he'.rfl_inv hΦ
      simp only [Term.era_lone] at hue
      subst hue
      obtain ⟨hca, hcb, _⟩ := Le.eql_inv hβ hle0 .refl .refl
      have hconv : Conv β (.App (.App P a) .Rfl) (.App (.App P b) e) :=
        Conv.app (Conv.app (Conv.refl _) (Conv.trans hβ (Conv.trans hβ hca.symm hab) hcb))
          (Conv.of_red_rev re.strong)
      exact ⟨_, _, _, (Red.rwt_e re).trans (Red.one .rwt), .rwt, (hf.cnv (Le.conv hconv)).sp _⟩
    · obtain ⟨e', ue', πe', re, se, he'⟩ := ihe _root_.rfl _root_.rfl _root_.rfl hde
      exact ⟨_, _, _, Red.rwt_e re, .rwt_e se,
        (Check.rwt he' hP hf).cnv (Le.conv (Conv.app (Conv.refl _) (Conv.of_red_rev re.strong)))⟩
  | let_ hv hA hb hle ihv ihA ihb =>
    subst hL hΓ hq
    rename_i qb v A πv uv πA b T0 π1 ub sp0
    simp only [Term.era_lone] at hnd ⊢
    by_cases hdv : Deep β uv
    · obtain ⟨π', uv', ub', hres, hu⟩ := Check.let_step hβ (Check.let_ (sp := []) hv hA hb hle)
        (fun uv' ub' he => by
          simp only [Term.era_lone] at he
          cases he
          intro A' πa hv' e r ps hc hemp
          exact Check.deep_empty hok hv' hdv (Le.conv hc) hemp)
      simp only [Term.era_lone] at hu
      cases hu
      exact ⟨_, _, π', Red.one .let_, .let_ (hdv.era hE), hres.sp _⟩
    · have hqb : qb ≠ .None := by
        rintro rfl
        rw [hv.none_era _root_.rfl] at hdv
        exact hdv .qnt
      obtain ⟨v', uv', πv', rv, sv, hv'⟩ := ihv _root_.rfl _root_.rfl (Quant.dem_live hqb) hdv
      have hv0 : Check β (Pol.std β) (LHS.void β) [] (Quant.dem qb .Lone) [] v' A πv' uv' := by
        rw [Quant.dem_live hqb]; exact hv'
      have hb' := hb.red_bind hβ [⟨qb, A, some v'⟩] (.val rv.strong .nil)
      exact ⟨_, _, _, Red.let_v rv, .let_v sv, Check.let_ hv0 hA hb' hle⟩
  | app hf hx ihf ihx =>
    subst hL hΓ hq
    simp only [Term.era_lone] at hnd ⊢
    rename_i x sp' f q' A B πf uf πx ux
    by_cases hdf : Deep β uf
    · by_cases hdx : Deep β ux
      · obtain ⟨vf, πf', rf, hvf, hf'⟩ := hf.deep_value hβ (by decide) hdf
        have hvt := Check.value_head hok (by decide) hvf hf' (Check.deep_not_bad hok hdf)
        cases hvt.at_all hβ (Le.refl _) with
        | lam =>
          rename_i g
          obtain ⟨_, _, _, _, _, ug, _, _, _, _, _, huf⟩ := hf'.lam_inv hΦ
          simp only [Term.era_lone] at huf
          subst huf
          obtain ⟨π', hres⟩ := Check.beta_app hβ hf' hx
            (fun hx' e r ps hc hemp => Check.deep_empty hok hx' hdx (Le.conv hc) hemp)
          exact ⟨_, _, π', (Red.app_f rf).trans (Red.one .beta), .beta (hdx.era hE), hres⟩
        | mat =>
          rename_i a c hh mm
          obtain ⟨A0, C0, r, ps, q'', _, B'', _, _, uh, _, um, hk, hc0, hr, hlen, hlive, _, _, _, _,
            hcv, _, huf⟩ := hf'.mat_inv hΦ
          simp only [Term.era_lone] at huf
          subst huf
          obtain ⟨hqq, hAA, _⟩ := Le.all_inv hβ hcv .refl .refl
          subst hqq
          have hq' := hlive (by decide)
          rw [Quant.dem_live hq'] at hx
          obtain ⟨vx, πx', rx, hvx, hx'⟩ := hx.deep_value hβ (by decide) hdx
          obtain ⟨c', A', C', as, rfl, hk', hc', hr', hlen', hcs⟩ :=
            (Check.value_head hok (by decide) hvx hx' (Check.deep_not_bad hok hdx)).at_adt
                hβ hAA
          rw [hk] at hk'; cases hk'
          obtain ⟨us, rfl, hlus⟩ := hx'.ctr_spine_era hβ (by decide)
          have hx'' : Check β (Pol.std β) (LHS.void β) [] (Quant.dem q'' .Lone) [] (Term.apps (.Ctr
              a c') as) A πx'
              (Term.apps (.Ctr a c') us) := by rw [Quant.dem_live hq']; exact hx'
          have hApp := Check.app (hf'.sp [_]) hx''
          have hdus : Deeps βe us := Deep.args (hdx.era hE) (by trivial)
          have hcvB : Le β (Term.subst 0 (Term.apps (.Ctr a c') as) B) (Term.subst 0 x B) :=
            Le.conv (Conv.substR hβ (Conv.of_red_rev rx.strong) 0 B)
          by_cases hcc : c' = c
          · subst hcc
            rw [hc0] at hc'; cases hc'
            obtain ⟨π', uh', um', up, ux', hres, hu, hlup, hlux⟩ :=
              Check.matc_step hok hk hc0 (ps := as.take A0.pn) (xs := as.drop A0.pn)
                (by simp; omega) (by simp; omega) (by rw [List.take_append_drop]; exact hApp)
            simp only [Term.era_lone] at hu
            injection hu with h1 h2
            injection h1 with _ _ h3 h4
            obtain ⟨_, h5⟩ := Term.apps_head_inv (by trivial) (by trivial) h2
            subst h3 h4 h5
            have hstep : Step β .weak (.App (.Mat a c' hh mm) (Term.apps (.Ctr a c') as))
                (Term.apps hh (as.drop A0.pn)) := by
              have := Step.matc (β := β) (p := .weak) hk hc0 (ps := as.take A0.pn) (xs := as.drop
                  A0.pn)
                (by simp; omega) (by simp; omega) (h := hh) (m := mm)
              rwa [List.take_append_drop] at this
            exact ⟨_, _, π', (Red.app_f rf).trans ((Red.app_a rx).trans (Red.one hstep)),
              .matc ((hE.adt_iff _ _).1 hk) hc0 hlup hlux hdus, (hres.cnv hcvB).sp _⟩
          · have hne : (a, c') ≠ (a, c) := fun h => hcc (Prod.mk.inj h).2
            obtain ⟨π', uh', um', us', hres, hu⟩ := Check.matm_step hok hne hApp
            simp only [Term.era_lone] at hu
            injection hu with h1 h2
            injection h1 with _ _ h3 h4
            obtain ⟨_, h5⟩ := Term.apps_head_inv (by trivial) (by trivial) h2
            subst h3 h4 h5
            exact ⟨_, _, π', (Red.app_f rf).trans ((Red.app_a rx).trans (Red.one (Step.matm hne))),
              .matm hne hdus, (hres.cnv hcvB).sp _⟩
        | efq =>
          obtain ⟨a, A0, r, q'', ps, B'', hk, hlive, hd, hcv, _, _⟩ := hf'.efq_inv hΦ
          obtain ⟨hqq, hAA, _⟩ := Le.all_inv hβ hcv .refl .refl
          subst hqq
          rcases hd with hemp | hdead
          · have hq' := hlive (by decide)
            rw [Quant.dem_live hq'] at hx
            exact (Check.deep_empty hok hx hdx hAA hemp).elim
          · exact (CtxDead.nil hdead).elim
        | adt hk hlt =>
          obtain ⟨T0, π0, u0, T1, πs, us, hh0, _, _, rfl, hlus⟩ :=
            hf'.spine_era hβ (fun _ e => Term.noConfusion e)
          obtain ⟨_, _, _, _, rfl⟩ := hh0.adt_inv hΦ
          simp only [Term.era_lone] at hnd hdf
          rw [← Term.apps_snoc] at hnd
          exact (hnd (Deep.adt (Deeps.append (Deep.args hdf (by trivial)) (.cons hdx .nil)))).elim
        | ctr hk hc hlt =>
          obtain ⟨T0, π0, u0, T1, πs, us, hh0, _, _, rfl, hlus⟩ :=
            hf'.spine_era hβ (fun _ e => Term.noConfusion e)
          obtain ⟨_, _, _, _, _, _, _, _, rfl⟩ := hh0.ctr_inv hΦ
          simp only [Term.era_lone] at hnd hdf
          rw [← Term.apps_snoc] at hnd
          exact (hnd (Deep.ctr (Deeps.append (Deep.args hdf (by trivial)) (.cons hdx .nil)))).elim
        | ref hk hlt =>
          rename_i k d as
          obtain ⟨T0, π0, u0, T1, πs, us, hh0, _, _, rfl, hlus⟩ :=
            hf'.spine_era hβ (fun _ e => Term.noConfusion e)
          rcases hh0.ref_inv hΦ with ⟨d', hk', _, _, _, _, rfl⟩ | ⟨A', hA', _⟩
          · rw [hk] at hk'; cases hk'
            simp only [Term.era_lone] at hnd hdf hf' ⊢
            have hdus : Deeps β (us ++ [ux]) :=
              Deeps.append (Deep.args hdf (by trivial)) (.cons hdx .nil)
            by_cases hn : us.length + 1 = d.n
            · have hApp : Check β (Pol.std β) (LHS.void β) [] .Lone [] (Term.apps (.Ref k) (as ++
                [x]))
                  (Term.subst 0 x B) (Uses.add πf' πx) (Term.apps (.Ref k) (us ++ [ux])) := by
                rw [Term.apps_snoc, Term.apps_snoc]; exact Check.app (hf'.sp _) hx
              obtain ⟨π', ub', us', hres, hu, _, hkE'⟩ := Check.dref_step hβ hE hk hApp
              obtain ⟨_, h5⟩ := Term.apps_head_inv (by trivial) (by trivial) hu
              subst h5
              have hs := SStep.dref (β := βe) hkE' (s := Term.apps (.Ref k) (us ++ [ux]))
                (by rw [Term.spine_apps (by trivial)])
                    (by rw [Term.spine_apps (by trivial)]; simp; omega)
                (by rw [Term.spine_apps (by trivial)]; exact hdus.book hE.adt_iff hE.defn_n)
              rw [Term.spine_apps (by trivial)] at hs
              dsimp only at hs
              rw [← Term.apps_snoc]
              refine ⟨_, _, π', (Red.app_f rf).trans (Red.one ?_), hs, hres.sp _⟩
              rw [← Term.apps_snoc]
              exact Step.dref_apps hk (by simp; omega)
            · rw [← Term.apps_snoc] at hnd
              exact (hnd (Deep.ref hk (by simp; omega) hdus)).elim
          · exact (Book.defn_adt_clash hk hA').elim
      · have hq' : q' ≠ .None := by
          rintro rfl
          rw [hx.none_era _root_.rfl] at hdx
          exact hdx .qnt
        obtain ⟨x', ux', πx', rx, sx, hx'⟩ := ihx _root_.rfl _root_.rfl (Quant.dem_live hq') hdx
        refine ⟨.App f x', .App uf ux', Uses.add πf πx', Red.app_a rx, .app_a (hdf.era hE) sx, ?_⟩
        have hx'' : Check β (Pol.std β) (LHS.void β) [] (Quant.dem q' .Lone) [] x' A πx' ux' := by
          rw [Quant.dem_live hq']; exact hx'
        exact (Check.app (hf.sp _) hx'').cnv (Le.conv (Conv.substR hβ (Conv.of_red_rev rx.strong) 0
            B))
    · obtain ⟨f', uf', πf', rf, sf, hf'⟩ := ihf _root_.rfl _root_.rfl _root_.rfl hdf
      exact ⟨.App f' x, .App uf' ux, _, Red.app_f rf, .app_f sf, Check.app hf' hx⟩

theorem Check.sstep (hok : Book.Ok β) (hE : Book.Era β 0 β βe)
    {sp : List Term} (h : Check β (Pol.std β) (LHS.void β) sp .Lone [] t T π u) (hnd : ¬ Deep β u) :
    ∃ t' u' π', Red β .weak t t' ∧ SStep βe u u' ∧
      Check β (Pol.std β) (LHS.void β) sp .Lone [] t' T π' u' :=
  Check.sstep_gen hok hE h _root_.rfl _root_.rfl _root_.rfl hnd

-- ----------------------------------------------------------------------------
-- N3b (ii) — Data values are inert for the measure. The kind facts come
-- from K under its dead policy; they enter through DataPol
-- ----------------------------------------------------------------------------

-- what the dead policy must offer: it extends the standard one, survives
-- closed substitution, orders kinds by KLe, and refutes a function type,
-- a kind or Quant under Data; a family instance under Data has its
-- instantiated kind under Data
structure DataPol (β : Book) (Φ : Pol) : Prop where
  weak   : Φ.Weak
  std    : ∀ x y, Le β x y → Φ.conv x y
  efq    : ∀ Γ, CtxDead β Γ → Φ.efq Γ
  efqS   : ∀ Γ b0 w, Φ.efq (Γ ++ [b0]) → Φ.efq (Ctx.substLast w Γ)
  kind   : ∀ G, KLe β G (.Qua .Many) → Φ.conv (.Typ G) (.Typ (.Qua .Many))
  no_all : ∀ {A πA q X Y}, Check β Φ (LHS.void β) [] .None [] A (.Typ (.Qua .Many)) πA .Qnt →
             Red β .strong A (.All q X Y) → False
  no_typ : ∀ {A πA g}, Check β Φ (LHS.void β) [] .None [] A (.Typ (.Qua .Many)) πA .Qnt →
             Red β .strong A (.Typ g) → False
  no_qnt : ∀ {A πA}, Check β Φ (LHS.void β) [] .None [] A (.Typ (.Qua .Many)) πA .Qnt →
             Red β .strong A .Qnt → False
  adt    : ∀ {A πA a r ps A' G}, Check β Φ (LHS.void β) [] .None [] A (.Typ (.Qua .Many)) πA .Qnt →
             Red β .strong A (Term.apps (.Adt a r) ps) → Book.adt β a = some A' →
             STele β A'.pn A'.sig G → ps.length = A'.pn → KLe β (Term.instG ps G) (.Qua .Many)

-- every constructor's walk, with a Lone field kinded at Kind(G), the
-- family's kind
def Book.OkK (β : Book) (Φ : Pol) : Prop :=
  ∀ a A c C, Book.adt β a = some A → AdtD.ctr A c = some C →
    ∃ G, STele β A.pn A.sig G ∧ CtrOkD β Φ A.pn G [] 0 C.ty

theorem Term.instG.conv (hβ : Book.Closed β) : ∀ {xs ys : List Term} {G1 G2 : Term},
    Convs β xs ys → Conv β G1 G2 → Conv β (Term.instG xs G1) (Term.instG ys G2) := by
  intro xs
  induction xs with
  | nil => intro ys G1 G2 h hG; cases h; exact hG
  | cons x xs ih =>
    intro ys G1 G2 h hG
    cases h with
    | cons hxy hrest =>
      simp only [Term.instG]
      rw [← hrest.length]
      exact ih hrest (Conv.subst hβ hG hxy xs.length)

theorem CGs.of_forall : ∀ {us : List Term}, (∀ u ∈ us, CG β' u []) → CGs β' us []
  | [], _ => .nil
  | _ :: us, h =>
    .cons (h _ (List.mem_cons_self ..)) (CGs.of_forall fun u (hu : u ∈ us) => h u
        (List.mem_cons_of_mem _ hu))

theorem List.sum_map_zero (f : Term → Nat) : ∀ {us : List Term}, (∀ u ∈ us, f u = 0) → (us.map
    f).sum = 0
  | [], _ => rfl
  | u :: us, h => by
    simp only [List.map, List.sum_cons, h u (List.mem_cons_self ..), Nat.zero_add]
    exact List.sum_map_zero f fun u (hu : u ∈ us) => h u (List.mem_cons_of_mem _ hu)

theorem Check.data_deep_aux (hok : Book.Ok β) (hP : DataPol β Φ)
    (hK : Book.OkK β Φ) :
    ∀ (n : Nat) {a A : Term} {πa : Uses} {ua : Term} {πA : Uses},
    Term.size ua ≤ n →
    Check β (Pol.std β) (LHS.void β) [] .Lone [] a A πa ua →
    Check β Φ (LHS.void β) [] .None [] A (.Typ (.Qua .Many)) πA .Qnt →
    Deep β ua → (∀ β', CG β' ua []) ∧ (∀ β', Term.weight β' ua = 0) := by
  have hβ := hok.closed
  have hΦ := Pol.std_pre hβ
  intro n
  induction n with
  | zero => intro a A πa ua πA hn _ _ _; have := Term.size_pos ua; omega
  | succ n ih =>
    intro a A πa ua πA hn h hKA hd
    obtain ⟨v, π', _, hv, h'⟩ := h.deep_value hβ (by decide) hd
    have hvt := Check.value_head hok (by decide) hv h' (Check.deep_not_bad hok hd)
    cases hvt with
    | typ hl =>
      obtain ⟨_, _, _, _, rfl⟩ := h'.typ_inv hΦ
      exact ⟨fun _ => .typ, fun _ => _root_.rfl⟩
    | qnt hl =>
      obtain ⟨_, _, rfl⟩ := h'.qnt_inv hΦ
      exact ⟨fun _ => .qnt, fun _ => _root_.rfl⟩
    | all hl =>
      obtain ⟨_, _, _, _, _, _, rfl⟩ := h'.all_inv hΦ
      exact ⟨fun _ => .all, fun _ => _root_.rfl⟩
    | eql hl =>
      obtain ⟨_, _, _, _, _, _, _, _, rfl⟩ := h'.eql_inv hΦ
      exact ⟨fun _ => .eql, fun _ => _root_.rfl⟩
    | qua hl =>
      obtain ⟨_, _, rfl⟩ := h'.qua_inv hΦ
      exact ⟨fun _ => .qua, fun _ => _root_.rfl⟩
    | rfl hl =>
      obtain ⟨_, _, _, _, _, _, rfl⟩ := h'.rfl_inv hΦ
      exact ⟨fun _ => .rfl, fun _ => _root_.rfl⟩
    | adtT _ _ hl => obtain ⟨_, hr⟩ := hl.typ_r; exact (hP.no_typ hKA hr).elim
    | lam hl => obtain ⟨_, _, hr⟩ := hl.all_r; exact (hP.no_all hKA hr).elim
    | mat _ hl => obtain ⟨_, _, hr⟩ := hl.all_r; exact (hP.no_all hKA hr).elim
    | efq hl => obtain ⟨_, _, hr⟩ := hl.all_r; exact (hP.no_all hKA hr).elim
    | adtF _ _ hl => obtain ⟨_, _, hr⟩ := hl.all_r; exact (hP.no_all hKA hr).elim
    | ctrF _ _ _ hl => obtain ⟨_, _, hr⟩ := hl.all_r; exact (hP.no_all hKA hr).elim
    | ref _ _ hl => obtain ⟨_, _, hr⟩ := hl.all_r; exact (hP.no_all hKA hr).elim
    | @ctr a0 A0 c C r' _ as hA hC hr hlen hl =>
      -- the spine's erasure and its walk
      obtain ⟨T0, π0, u0, T1, πs, us, hh0, hargs, _, rfl, hlus⟩ :=
        h'.spine_era hβ (fun _ e => Term.noConfusion e)
      obtain ⟨A', C', r0, hA', hC', hr0, hle0, _, rfl⟩ := hh0.ctr_inv hΦ
      rw [hA] at hA'; cases hA'
      rw [hC] at hC'; cases hC'
      simp only [Term.era_lone] at hd hn ⊢
      obtain ⟨G, hS, hD⟩ := hK _ _ _ _ hA hC
      have hshape : WTele a0 [] [] A0.pn C.fn C.ty := hok.shape hA hC
      rw [← List.take_append_drop A0.pn as] at hargs
      obtain ⟨Tm, πp, up, πx, ux, hargsP, hargsF, _, rfl⟩ := hargs.split
      obtain ⟨TS, _, hFT, hle', hD', hup⟩ :=
        CtrOkD.params hβ hP.weak hP.std hP.efq hP.efqS hshape hD hargsP hle0 (by simp; omega)
      have hfields := CtrOkD.fields_qs hβ hP.weak hP.std hP.efq hP.efqS
        (by simpa using hFT) hD' hargsF hle' (by simp; omega)
      -- the family's instantiated kind fits Data
      obtain ⟨r', ps', hred, _, hcs⟩ := hl.adt_r
      have hKle : KLe β (Term.instG (as.take A0.pn) G) (.Qua .Many) :=
        KLe.trans hβ (KLe.conv (Term.instG.conv hβ hcs (Conv.refl G)))
          _ (hP.adt hKA hred hA hS (by rw [← hcs.length]; simp; omega))
      -- every argument's erasure is inert
      have hdus : Deeps β (up ++ ux) := Deep.args hd (by trivial)
      have hall : ∀ u ∈ up ++ ux, (∀ β', CG β' u []) ∧ (∀ β', Term.weight β' u = 0) := by
        intro u hu
        rw [List.mem_append] at hu
        rcases hu with hu | hu
        · rw [hup u hu]; exact ⟨fun _ => .qnt, fun _ => _root_.rfl⟩
        · obtain ⟨j, hj⟩ := List.mem_iff_getElem?.mp hu
          have hjl : j < (as.drop A0.pn).length := by
            rw [← hargsF.length]; exact (List.getElem?_eq_some_iff.mp hj).1
          obtain ⟨qf, F, πx', _, hx, πF, hKF⟩ :=
            hfields j _ u (List.getElem?_eq_getElem hjl) hj
          have hsz : Term.size u < Term.size (Term.apps (.Ctr a0 c) (up ++ ux)) :=
            Term.size_spine_arg _ _ (by rw [Term.spine_apps (by trivial)]; simp [hu])
          have hdu : Deep β u := hdus.mem u (by simp [hu])
          cases qf with
          | None => rw [hx.none_era _root_.rfl]; exact ⟨fun _ => .qnt, fun _ => _root_.rfl⟩
          | Lone =>
            simp only [if_true] at hKF
            exact ih (by omega) hx (hKF.cnv (hP.kind _ hKle)) hdu
          | Many =>
            simp only [reduceCtorEq, if_false] at hKF
            exact ih (by omega) hx hKF hdu
      refine ⟨fun β' => ?_, fun β' => ?_⟩
      · exact CG.apps (.ctr) (CGs.of_forall fun u hu => (hall u hu).1 β')
      · rw [Term.weight_apps]
        simp only [Term.weight, Nat.zero_add]
        exact List.sum_map_zero _ fun u hu => (hall u hu).2 β'

-- ============================================================================
-- METATHEORY §K — the dead fragment: a coarser reading of the judgment that
-- ignores binder quantities, its preservation along strong reduction, and the
-- kinds of what a Data-kinded type reduces to
-- ============================================================================

-- ----------------------------------------------------------------------------
-- §K1 binder-quantity erasure and the dead policy. Strong reduction includes
-- eta, which can change a binder's quantity, and Le compares All only at equal
-- quantities; so dead code is read under a conversion that erases binder
-- quantities, on the book as well (a dref step unfolds a body)
-- ----------------------------------------------------------------------------

-- erase binder quantities: every All becomes a Lone arrow
def Term.qer : Term → Term
  | .All _ A B   => .All .Lone (Term.qer A) (Term.qer B)
  | .Typ g       => .Typ (Term.qer g)
  | .Min a b     => .Min (Term.qer a) (Term.qer b)
  | .Lam f       => .Lam (Term.qer f)
  | .App f a     => .App (Term.qer f) (Term.qer a)
  | .Mat a c h m => .Mat a c (Term.qer h) (Term.qer m)
  | .Eql x y T   => .Eql (Term.qer x) (Term.qer y) (Term.qer T)
  | .Rwt e P f   => .Rwt (Term.qer e) (Term.qer P) (Term.qer f)
  | .Let q v b   => .Let q (Term.qer v) (Term.qer b)
  | t            => t

def CtrD.qer (C : CtrD) : CtrD := { C with ty := Term.qer C.ty }

def AdtD.qer (A : AdtD) : AdtD := { A with sig := Term.qer A.sig, ctrs := A.ctrs.map CtrD.qer }

def DefD.qer (d : DefD) : DefD := { d with ty := Term.qer d.ty, body := Term.qer d.body }

def TLD.qer : TLD → TLD
  | .adt A  => .adt A.qer
  | .defn d => .defn d.qer

def Book.qer (β : Book) : Book := β.map TLD.qer

-- the dead policy: conversion up to binder quantities, ex-falso free
def Pol.dead (β : Book) : Pol :=
  ⟨fun a b => Le (Book.qer β) (Term.qer a) (Term.qer b), fun _ => True⟩

-- qer commutes with the term algebra
theorem Term.qer_shift (t : Term) :
    ∀ d, Term.qer (Term.shift d t) = Term.shift d (Term.qer t) := by
  induction t <;> intro d <;> simp [Term.qer, Term.shift, *]
  split <;> rfl

theorem Term.qer_subst (t : Term) : ∀ d w,
    Term.qer (Term.subst d w t) = Term.subst d (Term.qer w) (Term.qer t) := by
  induction t <;> intro d w <;> simp [Term.qer, Term.subst, Term.qer_shift, *]
  split <;> (try split) <;> rfl

theorem Term.qer_apps (h : Term) (as : List Term) :
    Term.qer (Term.apps h as) = Term.apps (Term.qer h) (as.map Term.qer) := by
  induction as generalizing h <;> simp [Term.apps, Term.qer, *]

theorem Term.qer_spine (t : Term) :
    Term.spine (Term.qer t) = (Term.qer (Term.spine t).1, (Term.spine t).2.map Term.qer) := by
  induction t <;> simp [Term.qer, Term.spine, *]

theorem Term.qer_occ (t : Term) : ∀ i, Term.occ i (Term.qer t) = Term.occ i t := by
  induction t <;> intro i <;> simp [Term.qer, Term.occ, *]

theorem Term.qer_closed (t : Term) : ∀ n, Term.Closed n t → Term.Closed n (Term.qer t) := by
  induction t <;> intro n h <;> simp_all [Term.qer, Term.Closed]

theorem Book.qer_tld (β : Book) :
    ∀ k, Book.tld (Book.qer β) k = (Book.tld β k).map TLD.qer := by
  unfold Book.qer
  induction β <;> intro k <;> cases k <;> simp [Book.tld, *]

theorem Book.qer_defn (β : Book) (k : Nat) :
    Book.defn (Book.qer β) k = (Book.defn β k).map DefD.qer := by
  unfold Book.defn; rw [Book.qer_tld]
  cases Book.tld β k with
  | none => rfl
  | some t => cases t <;> rfl

theorem Book.qer_adt (β : Book) (a : Nat) :
    Book.adt (Book.qer β) a = (Book.adt β a).map AdtD.qer := by
  unfold Book.adt; rw [Book.qer_tld]
  cases Book.tld β a with
  | none => rfl
  | some t => cases t <;> rfl

theorem AdtD.qer_ctr (A : AdtD) (c : Nat) :
    AdtD.ctr A.qer c = (AdtD.ctr A c).map CtrD.qer := by
  show AdtD.ctr.go (A.ctrs.map CtrD.qer) c = (AdtD.ctr.go A.ctrs c).map CtrD.qer
  generalize A.ctrs = l
  induction l generalizing c with
  | nil => rfl
  | cons C cs ih => cases c <;> simp [AdtD.ctr.go, ih]

theorem Book.Closed.qer (hβ : Book.Closed β) : Book.Closed (Book.qer β) := by
  intro k t ht
  rw [Book.qer_tld] at ht
  cases h0 : Book.tld β k with
  | none => simp [h0] at ht
  | some t0 =>
    rw [h0] at ht; simp at ht; subst ht
    have hc := hβ k t0 h0
    cases t0 with
    | adt A =>
      refine ⟨Term.qer_closed _ _ hc.1, fun c C hC => ?_⟩
      rw [AdtD.qer_ctr] at hC
      cases h1 : AdtD.ctr A c with
      | none => simp [h1] at hC
      | some C0 => rw [h1] at hC; simp at hC; subst hC; exact Term.qer_closed _ _ (hc.2 c C0 h1)
    | defn d => exact ⟨Term.qer_closed _ _ hc.1, Term.qer_closed _ _ hc.2⟩

-- reduction, conversion and fitting survive the erasure (on the book too)
theorem Step.qer (h : Step β p a b) : Step (Book.qer β) p (Term.qer a) (Term.qer b) := by
  induction h with
  | beta => simp only [Term.qer, Term.qer_subst]; exact .beta
  | let_ => simp only [Term.qer, Term.qer_subst]; exact .let_
  | @dref k d s hk hs hn =>
    have e : (Term.spine (Term.qer s)).2 = (Term.spine s).2.map Term.qer := by rw [Term.qer_spine]
    rw [Term.qer_apps, ← e]
    exact .dref (k := k) (d := d.qer) (by rw [Book.qer_defn, hk]; rfl)
      (by rw [Term.qer_spine, hs]; rfl) (by rw [e]; simp [DefD.qer, hn])
  | @drefS k d s hp hk hs =>
    have e : (Term.spine (Term.qer s)).2 = (Term.spine s).2.map Term.qer := by rw [Term.qer_spine]
    rw [Term.qer_apps, ← e]
    exact .drefS (k := k) (d := d.qer) hp (by rw [Book.qer_defn, hk]; rfl)
      (by rw [Term.qer_spine, hs]; rfl)
  | @aref k A hk hpn =>
    exact .aref (A := A.qer) (by rw [Book.qer_adt, hk]; rfl) (by simpa [AdtD.qer] using hpn)
  | @matc a A c C ps xs h m hA hC hps hxs =>
    simp only [Term.qer, Term.qer_apps, List.map_append]
    exact .matc (A := A.qer) (C := C.qer) (by rw [Book.qer_adt, hA]; rfl)
      (by rw [AdtD.qer_ctr, hC]; rfl) (by simpa [AdtD.qer] using hps)
      (by simpa [CtrD.qer] using hxs)
  | matm hne => simp only [Term.qer, Term.qer_apps]; exact .matm hne
  | rwt => exact .rwt
  | minLM => exact .minLM
  | minLN => exact .minLN
  | minRM => exact .minRM
  | minRN => exact .minRN
  | minLL => exact .minLL
  | eta hp ho =>
    simp only [Term.qer, Term.qer_subst]
    exact .eta hp (by rw [Term.qer_occ]; exact ho)
  | typ_g hp _ ih => exact .typ_g hp ih
  | min_a _ ih => exact .min_a ih
  | min_b _ ih => exact .min_b ih
  | all_a hp _ ih => exact .all_a hp ih
  | all_b hp _ ih => exact .all_b hp ih
  | lam_f hp _ ih => exact .lam_f hp ih
  | app_f _ ih => exact .app_f ih
  | app_a _ ih => exact .app_a ih
  | mat_h _ ih => exact .mat_h ih
  | mat_m _ ih => exact .mat_m ih
  | eql_a _ ih => exact .eql_a ih
  | eql_b _ ih => exact .eql_b ih
  | eql_t _ ih => exact .eql_t ih
  | rwt_e _ ih => exact .rwt_e ih
  | rwt_p _ ih => exact .rwt_p ih
  | rwt_f _ ih => exact .rwt_f ih
  | let_v _ ih => exact .let_v ih
  | let_b hp _ ih => exact .let_b hp ih

theorem Red.qer (h : Red β p a b) : Red (Book.qer β) p (Term.qer a) (Term.qer b) := by
  induction h with
  | refl => exact .refl
  | step s _ ih => exact .step s.qer ih

theorem Conv.qer (h : Conv β a b) : Conv (Book.qer β) (Term.qer a) (Term.qer b) :=
  let ⟨c, r1, r2⟩ := h; ⟨Term.qer c, r1.qer, r2.qer⟩

theorem KLe.qer (h : KLe β g k) : KLe (Book.qer β) (Term.qer g) (Term.qer k) := by
  induction h with
  | many r => exact .many r.qer
  | lone r hq => exact .lone r.qer hq
  | minL r _ _ ih1 ih2 => exact .minL r.qer ih1 ih2
  | minR1 r _ ih => exact .minR1 r.qer ih
  | minR2 r _ ih => exact .minR2 r.qer ih
  | conv c => exact .conv c.qer

theorem Le.qer (h : Le β a b) : Le (Book.qer β) (Term.qer a) (Term.qer b) := by
  induction h with
  | conv c => exact .conv c.qer
  | red r1 r2 _ ih => exact .red r1.qer r2.qer ih
  | typ k => exact .typ k.qer
  | all _ _ ih1 ih2 => exact .all ih1 ih2
  | adt hsub hlen hc =>
    rw [Term.qer_apps, Term.qer_apps]
    refine .adt hsub (by simp [hlen]) (fun i p p' hp hp' => ?_)
    simp at hp hp'
    obtain ⟨p0, h1, rfl⟩ := hp
    obtain ⟨p0', h2, rfl⟩ := hp'
    exact (hc i p0 p0' h1 h2).qer

-- the dead policy is a preorder, weak, coarser than the standard one, and
-- still reads kinds; a stuck Lone never fits under Many
theorem Pol.dead_refl (β : Book) (a : Term) : (Pol.dead β).conv a a := Le.refl _

theorem Pol.dead_trans (hβ : Book.Closed β) (h1 : (Pol.dead β).conv a b)
    (h2 : (Pol.dead β).conv b c) : (Pol.dead β).conv a c :=
  Le.trans hβ.qer h1 h2

theorem Pol.dead_weak (hβ : Book.Closed β) : (Pol.dead β).Weak where
  subst d w x y h := by
    show Le _ _ _; rw [Term.qer_subst, Term.qer_subst]; exact Le.subst hβ.qer h d _
  shift d x y h := by
    show Le _ _ _; rw [Term.qer_shift, Term.qer_shift]; exact Le.shift hβ.qer h d
  append _ _ _ := trivial
  ins _ _ _ _ _ _ := trivial

theorem Pol.dead_std (_hβ : Book.Closed β) : ∀ x y, Le β x y → (Pol.dead β).conv x y :=
  fun _ _ h => h.qer

theorem Pol.dead_kind (_hβ : Book.Closed β) :
    ∀ G, KLe β G (.Qua .Many) → (Pol.dead β).conv (.Typ G) (.Typ (.Qua .Many)) :=
  fun _ h => Le.typ h.qer

theorem Pol.dead_typ_inv (hβ : Book.Closed β) (h : (Pol.dead β).conv (.Typ g) (.Typ k)) :
    KLe (Book.qer β) (Term.qer g) (Term.qer k) :=
  Le.typ_inv hβ.qer h .refl .refl

theorem KLe.lone_many (_hβ : Book.Closed β) : ¬ KLe β (.Qua .Lone) (.Qua .Many) := by
  intro h
  cases h with
  | many r => cases r.qua_inv
  | lone r hq => cases r.qua_inv; exact hq rfl
  | minL r _ _ => cases r.qua_inv
  | minR1 r _ => cases r.qua_inv
  | minR2 r _ => cases r.qua_inv
  | conv c => cases c.qua_inv

theorem Term.qer_inv_var (h : Term.qer t = .Var i) : t = .Var i := by
  cases t <;> simp [Term.qer] at h; simp [h]

theorem Term.qer_inv_ref (h : Term.qer t = .Ref k) : t = .Ref k := by
  cases t <;> simp [Term.qer] at h; simp [h]

theorem Term.qer_inv_qua (h : Term.qer t = .Qua q) : t = .Qua q := by
  cases t <;> simp [Term.qer] at h; simp [h]

theorem Term.qer_inv_rfl (h : Term.qer t = .Rfl) : t = .Rfl := by
  cases t <;> simp_all [Term.qer]

theorem Term.qer_inv_ctr (h : Term.qer t = .Ctr a c) : t = .Ctr a c := by
  cases t <;> simp [Term.qer] at h; simp [h]

theorem Term.qer_inv_typ (h : Term.qer t = .Typ g) : ∃ g0, t = .Typ g0 ∧ Term.qer g0 = g := by
  cases t <;> simp [Term.qer] at h; exact ⟨_, rfl, h⟩

theorem Term.qer_inv_min (h : Term.qer t = .Min a b) :
    ∃ a0 b0, t = .Min a0 b0 ∧ Term.qer a0 = a ∧ Term.qer b0 = b := by
  cases t <;> simp [Term.qer] at h; exact ⟨_, _, rfl, h.1, h.2⟩

theorem Term.qer_inv_all (h : Term.qer t = .All q A B) :
    ∃ q0 A0 B0, t = .All q0 A0 B0 ∧ q = .Lone ∧ Term.qer A0 = A ∧ Term.qer B0 = B := by
  cases t <;> simp [Term.qer] at h; exact ⟨_, _, _, rfl, h.1.symm, h.2.1, h.2.2⟩

theorem Term.qer_inv_lam (h : Term.qer t = .Lam f) : ∃ g, t = .Lam g ∧ Term.qer g = f := by
  cases t <;> simp [Term.qer] at h; exact ⟨_, rfl, h⟩

theorem Term.qer_inv_app (h : Term.qer t = .App f a) :
    ∃ f0 a0, t = .App f0 a0 ∧ Term.qer f0 = f ∧ Term.qer a0 = a := by
  cases t <;> simp [Term.qer] at h; exact ⟨_, _, rfl, h.1, h.2⟩

theorem Term.qer_inv_mat (h : Term.qer t = .Mat a c hh m) :
    ∃ h0 m0, t = .Mat a c h0 m0 ∧ Term.qer h0 = hh ∧ Term.qer m0 = m := by
  cases t <;> simp [Term.qer] at h
  obtain ⟨rfl, rfl, h1, h2⟩ := h; exact ⟨_, _, rfl, h1, h2⟩

theorem Term.qer_inv_eql (h : Term.qer t = .Eql x y T) :
    ∃ x0 y0 T0, t = .Eql x0 y0 T0 ∧ Term.qer x0 = x ∧ Term.qer y0 = y ∧
      Term.qer T0 = T := by
  cases t <;> simp [Term.qer] at h; exact ⟨_, _, _, rfl, h.1, h.2.1, h.2.2⟩

theorem Term.qer_inv_rwt (h : Term.qer t = .Rwt e P f) :
    ∃ e0 P0 f0, t = .Rwt e0 P0 f0 ∧ Term.qer e0 = e ∧ Term.qer P0 = P ∧
      Term.qer f0 = f := by
  cases t <;> simp [Term.qer] at h; exact ⟨_, _, _, rfl, h.1, h.2.1, h.2.2⟩

theorem Term.qer_inv_let (h : Term.qer t = .Let q v b) :
    ∃ v0 b0, t = .Let q v0 b0 ∧ Term.qer v0 = v ∧ Term.qer b0 = b := by
  cases t <;> simp [Term.qer] at h; obtain ⟨rfl, h1, h2⟩ := h; exact ⟨_, _, rfl, h1, h2⟩

-- a constructor spine of the erasure is the erasure of a constructor spine
theorem Term.qer_inv_ctr_apps (e : Term.qer t = Term.apps (.Ctr a c) xs) :
    ∃ xs0, t = Term.apps (.Ctr a c) xs0 ∧ xs0.map Term.qer = xs := by
  have hs := congrArg Term.spine e
  rw [Term.qer_spine, Term.spine_apps (h := .Ctr a c) trivial] at hs
  simp only [Prod.mk.injEq] at hs
  refine ⟨(Term.spine t).2, ?_, hs.2⟩
  rw [← Term.qer_inv_ctr hs.1]; exact (Term.apps_spine t).symm

theorem Step.qer_inv (h : Step (Book.qer β) p a' b') :
    ∀ a, Term.qer a = a' → ∃ b, Term.qer b = b' ∧ Step β p a b := by
  induction h with
  | beta =>
    intro a ha
    obtain ⟨f0, a0, rfl, hf, hx⟩ := Term.qer_inv_app ha
    obtain ⟨g, rfl, hg⟩ := Term.qer_inv_lam hf
    exact ⟨_, by rw [Term.qer_subst, hg, hx], .beta⟩
  | let_ =>
    intro a ha
    obtain ⟨v0, b0, rfl, hv, hb⟩ := Term.qer_inv_let ha
    exact ⟨_, by rw [Term.qer_subst, hv, hb], .let_⟩
  | @dref k d s hk hs hn =>
    intro a ha
    subst ha
    rw [Book.qer_defn] at hk
    cases hd0 : Book.defn β k with
    | none => rw [hd0] at hk; cases hk
    | some d0 =>
      rw [hd0] at hk; simp at hk; subst hk
      rw [Term.qer_spine] at hs hn
      refine ⟨Term.apps d0.body (Term.spine a).2, by rw [Term.qer_apps, Term.qer_spine]; rfl,
        .dref hd0 (Term.qer_inv_ref hs) ?_⟩
      simpa [DefD.qer] using hn
  | @drefS k d s hp hk hs =>
    intro a ha
    subst ha
    rw [Book.qer_defn] at hk
    cases hd0 : Book.defn β k with
    | none => rw [hd0] at hk; cases hk
    | some d0 =>
      rw [hd0] at hk; simp at hk; subst hk
      rw [Term.qer_spine] at hs
      exact ⟨Term.apps d0.body (Term.spine a).2, by rw [Term.qer_apps, Term.qer_spine]; rfl,
        .drefS hp hd0 (Term.qer_inv_ref hs)⟩
  | @aref k A hk hpn =>
    intro a ha
    obtain rfl := Term.qer_inv_ref ha
    rw [Book.qer_adt] at hk
    cases hA0 : Book.adt β k with
    | none => rw [hA0] at hk; cases hk
    | some A0 =>
      rw [hA0] at hk; simp at hk; subst hk
      exact ⟨.Adt k [], rfl, .aref hA0 (by simpa [AdtD.qer] using hpn)⟩
  | @matc a A c C ps xs h m hA hC hps hxs =>
    intro t ht
    obtain ⟨f0, s0, rfl, hf, hs⟩ := Term.qer_inv_app ht
    obtain ⟨h0, m0, rfl, hh, hm⟩ := Term.qer_inv_mat hf
    obtain ⟨ys, rfl, hys⟩ := Term.qer_inv_ctr_apps hs
    obtain ⟨ps0, xs0, rfl, hps0, hxs0⟩ := List.map_eq_append_iff.mp hys
    rw [Book.qer_adt] at hA
    cases hA0 : Book.adt β a with
    | none => rw [hA0] at hA; cases hA
    | some A0 =>
      rw [hA0] at hA; simp at hA; subst hA
      rw [AdtD.qer_ctr] at hC
      cases hC0 : AdtD.ctr A0 c with
      | none => rw [hC0] at hC; cases hC
      | some C0 =>
        rw [hC0] at hC; simp at hC; subst hC
        refine ⟨Term.apps h0 xs0, by rw [Term.qer_apps, hh, hxs0], .matc hA0 hC0 ?_ ?_⟩
        · simpa [AdtD.qer] using (List.length_map .. ▸ hps0 ▸ hps : ps0.length = _)
        · simpa [CtrD.qer] using (List.length_map .. ▸ hxs0 ▸ hxs : xs0.length = _)
  | @matm a' c' a c as h m hne =>
    intro t ht
    obtain ⟨f0, s0, rfl, hf, hs⟩ := Term.qer_inv_app ht
    obtain ⟨h0, m0, rfl, hh, hm⟩ := Term.qer_inv_mat hf
    obtain ⟨ys, rfl, hys⟩ := Term.qer_inv_ctr_apps hs
    exact ⟨.App m0 (Term.apps (.Ctr a' c') ys), by simp [Term.qer, Term.qer_apps, hm, hys],
      .matm hne⟩
  | rwt =>
    intro t ht
    obtain ⟨e0, P0, f0, rfl, he, hP, hf⟩ := Term.qer_inv_rwt ht
    obtain rfl := Term.qer_inv_rfl he
    exact ⟨f0, hf, .rwt⟩
  | minLM =>
    intro t ht
    obtain ⟨a0, b0, rfl, ha, hb⟩ := Term.qer_inv_min ht
    obtain rfl := Term.qer_inv_qua ha
    exact ⟨b0, hb, .minLM⟩
  | minLN =>
    intro t ht
    obtain ⟨a0, b0, rfl, ha, hb⟩ := Term.qer_inv_min ht
    obtain rfl := Term.qer_inv_qua ha
    exact ⟨.Qua .None, rfl, .minLN⟩
  | minRM =>
    intro t ht
    obtain ⟨a0, b0, rfl, ha, hb⟩ := Term.qer_inv_min ht
    obtain rfl := Term.qer_inv_qua hb
    exact ⟨a0, ha, .minRM⟩
  | minRN =>
    intro t ht
    obtain ⟨a0, b0, rfl, ha, hb⟩ := Term.qer_inv_min ht
    obtain rfl := Term.qer_inv_qua hb
    exact ⟨.Qua .None, rfl, .minRN⟩
  | minLL =>
    intro t ht
    obtain ⟨a0, b0, rfl, ha, hb⟩ := Term.qer_inv_min ht
    obtain rfl := Term.qer_inv_qua ha
    obtain rfl := Term.qer_inv_qua hb
    exact ⟨.Qua .Lone, rfl, .minLL⟩
  | eta hp hocc =>
    intro t ht
    obtain ⟨g0, rfl, hg⟩ := Term.qer_inv_lam ht
    obtain ⟨F0, x0, rfl, hF, hx⟩ := Term.qer_inv_app hg
    obtain rfl := Term.qer_inv_var hx
    refine ⟨Term.subst 0 .Qnt F0, by rw [Term.qer_subst, hF]; rfl, .eta hp ?_⟩
    rw [← Term.qer_occ, hF]; exact hocc
  | typ_g hp _ ih =>
    intro t ht
    obtain ⟨g0, rfl, hg⟩ := Term.qer_inv_typ ht
    obtain ⟨g1, hg1, hs⟩ := ih g0 hg
    exact ⟨.Typ g1, by simp [Term.qer, hg1], .typ_g hp hs⟩
  | min_a _ ih =>
    intro t ht
    obtain ⟨a0, b0, rfl, ha, hb⟩ := Term.qer_inv_min ht
    obtain ⟨a1, ha1, hs⟩ := ih a0 ha
    exact ⟨.Min a1 b0, by simp [Term.qer, ha1, hb], .min_a hs⟩
  | min_b _ ih =>
    intro t ht
    obtain ⟨a0, b0, rfl, ha, hb⟩ := Term.qer_inv_min ht
    obtain ⟨b1, hb1, hs⟩ := ih b0 hb
    exact ⟨.Min a0 b1, by simp [Term.qer, ha, hb1], .min_b hs⟩
  | all_a hp _ ih =>
    intro t ht
    obtain ⟨q0, A0, B0, rfl, hq', hA, hB⟩ := Term.qer_inv_all ht
    obtain ⟨A1, hA1, hs⟩ := ih A0 hA
    exact ⟨.All q0 A1 B0, by simp [Term.qer, hA1, hB, hq'], .all_a hp hs⟩
  | all_b hp _ ih =>
    intro t ht
    obtain ⟨q0, A0, B0, rfl, hq', hA, hB⟩ := Term.qer_inv_all ht
    obtain ⟨B1, hB1, hs⟩ := ih B0 hB
    exact ⟨.All q0 A0 B1, by simp [Term.qer, hA, hB1, hq'], .all_b hp hs⟩
  | lam_f hp _ ih =>
    intro t ht
    obtain ⟨g0, rfl, hg⟩ := Term.qer_inv_lam ht
    obtain ⟨g1, hg1, hs⟩ := ih g0 hg
    exact ⟨.Lam g1, by simp [Term.qer, hg1], .lam_f hp hs⟩
  | app_f _ ih =>
    intro t ht
    obtain ⟨f0, a0, rfl, hf, ha⟩ := Term.qer_inv_app ht
    obtain ⟨f1, hf1, hs⟩ := ih f0 hf
    exact ⟨.App f1 a0, by simp [Term.qer, hf1, ha], .app_f hs⟩
  | app_a _ ih =>
    intro t ht
    obtain ⟨f0, a0, rfl, hf, ha⟩ := Term.qer_inv_app ht
    obtain ⟨a1, ha1, hs⟩ := ih a0 ha
    exact ⟨.App f0 a1, by simp [Term.qer, hf, ha1], .app_a hs⟩
  | mat_h _ ih =>
    intro t ht
    obtain ⟨h0, m0, rfl, hh, hm⟩ := Term.qer_inv_mat ht
    obtain ⟨h1, hh1, hs⟩ := ih h0 hh
    exact ⟨.Mat _ _ h1 m0, by simp [Term.qer, hh1, hm], .mat_h hs⟩
  | mat_m _ ih =>
    intro t ht
    obtain ⟨h0, m0, rfl, hh, hm⟩ := Term.qer_inv_mat ht
    obtain ⟨m1, hm1, hs⟩ := ih m0 hm
    exact ⟨.Mat _ _ h0 m1, by simp [Term.qer, hh, hm1], .mat_m hs⟩
  | eql_a _ ih =>
    intro t ht
    obtain ⟨x0, y0, T0, rfl, hx, hy, hT⟩ := Term.qer_inv_eql ht
    obtain ⟨x1, hx1, hs⟩ := ih x0 hx
    exact ⟨.Eql x1 y0 T0, by simp [Term.qer, hx1, hy, hT], .eql_a hs⟩
  | eql_b _ ih =>
    intro t ht
    obtain ⟨x0, y0, T0, rfl, hx, hy, hT⟩ := Term.qer_inv_eql ht
    obtain ⟨y1, hy1, hs⟩ := ih y0 hy
    exact ⟨.Eql x0 y1 T0, by simp [Term.qer, hx, hy1, hT], .eql_b hs⟩
  | eql_t _ ih =>
    intro t ht
    obtain ⟨x0, y0, T0, rfl, hx, hy, hT⟩ := Term.qer_inv_eql ht
    obtain ⟨T1, hT1, hs⟩ := ih T0 hT
    exact ⟨.Eql x0 y0 T1, by simp [Term.qer, hx, hy, hT1], .eql_t hs⟩
  | rwt_e _ ih =>
    intro t ht
    obtain ⟨e0, P0, f0, rfl, he, hP, hf⟩ := Term.qer_inv_rwt ht
    obtain ⟨e1, he1, hs⟩ := ih e0 he
    exact ⟨.Rwt e1 P0 f0, by simp [Term.qer, he1, hP, hf], .rwt_e hs⟩
  | rwt_p _ ih =>
    intro t ht
    obtain ⟨e0, P0, f0, rfl, he, hP, hf⟩ := Term.qer_inv_rwt ht
    obtain ⟨P1, hP1, hs⟩ := ih P0 hP
    exact ⟨.Rwt e0 P1 f0, by simp [Term.qer, he, hP1, hf], .rwt_p hs⟩
  | rwt_f _ ih =>
    intro t ht
    obtain ⟨e0, P0, f0, rfl, he, hP, hf⟩ := Term.qer_inv_rwt ht
    obtain ⟨f1, hf1, hs⟩ := ih f0 hf
    exact ⟨.Rwt e0 P0 f1, by simp [Term.qer, he, hP, hf1], .rwt_f hs⟩
  | let_v _ ih =>
    intro t ht
    obtain ⟨v0, b0, rfl, hv, hb⟩ := Term.qer_inv_let ht
    obtain ⟨v1, hv1, hs⟩ := ih v0 hv
    exact ⟨.Let _ v1 b0, by simp [Term.qer, hv1, hb], .let_v hs⟩
  | let_b hp _ ih =>
    intro t ht
    obtain ⟨v0, b0, rfl, hv, hb⟩ := Term.qer_inv_let ht
    obtain ⟨b1, hb1, hs⟩ := ih b0 hb
    exact ⟨.Let _ v0 b1, by simp [Term.qer, hv, hb1], .let_b hp hs⟩

theorem Red.qer_inv (h : Red (Book.qer β) p a' b') :
    ∀ a, Term.qer a = a' → ∃ b, Term.qer b = b' ∧ Red β p a b := by
  induction h with
  | refl => intro a ha; exact ⟨a, ha, .refl⟩
  | step s _ ih =>
    intro a ha
    obtain ⟨b, hb, hs⟩ := Step.qer_inv s a ha
    obtain ⟨c, hc, hr⟩ := ih b hb
    exact ⟨c, hc, .step hs hr⟩

-- a kind under Data in the erased book is under Data in the book
theorem KLe.qer_many (h : KLe (Book.qer β) g' (.Qua .Many)) :
    ∀ g, Term.qer g = g' → KLe β g (.Qua .Many) := by
  generalize hm : (Term.Qua .Many : Term) = m at h
  induction h with
  | many r =>
    intro g hg
    obtain ⟨b, hb, hr⟩ := Red.qer_inv r g hg
    obtain rfl := Term.qer_inv_qua hb
    exact .many hr
  | lone r hq => subst hm; cases r.qua_inv; exact absurd _root_.rfl hq
  | minL r _ _ ih1 ih2 =>
    intro g hg
    obtain ⟨b, hb, hr⟩ := Red.qer_inv r g hg
    obtain ⟨g1, g2, rfl, h1, h2⟩ := Term.qer_inv_min hb
    exact .minL hr (ih1 hm g1 h1) (ih2 hm g2 h2)
  | minR1 r _ _ => subst hm; cases r.qua_inv
  | minR2 r _ _ => subst hm; cases r.qua_inv
  | conv c =>
    intro g hg
    subst hm
    obtain ⟨d, r1, r2⟩ := c
    cases r2.qua_inv
    obtain ⟨b, hb, hr⟩ := Red.qer_inv r1 g hg
    obtain rfl := Term.qer_inv_qua hb
    exact .many hr

-- two kinds read off one signature convert
theorem STele.conv (hβ : Book.Closed β) : ∀ {n : Nat} {T G G' : Term},
    STele β n T G → STele β n T G' → Conv β G G' := by
  intro n
  induction n with
  | zero =>
    intro T G G' h1 h2
    obtain ⟨d, hd1, hd2⟩ := church_rosser_closed hβ h1.strong h2.strong
    obtain ⟨g1, rfl, r1⟩ := hd1.typ_inv
    obtain ⟨g2, e, r2⟩ := hd2.typ_inv
    cases e
    exact ⟨g1, r1, r2⟩
  | succ n ih =>
    intro T G G' h1 h2
    obtain ⟨q, K, B, rfl, hr1⟩ := h1
    obtain ⟨_, _, _, e, hr2⟩ := h2
    cases e
    exact ih hr1 hr2

-- ----------------------------------------------------------------------------
-- §K2 open substitution at the dead policy: a binder anywhere in the context
-- is replaced by a term of its type drawn from the context below it (D's
-- Check.subst at depth d, the substituted term shifted past the d binders
-- above it)
-- ----------------------------------------------------------------------------

theorem Term.shiftN_succ (n : Nat) (t : Term) :
    Term.shift 0 (Term.shiftN n t) = Term.shiftN (n + 1) t := rfl

-- an open w passes through the binders it is shifted past
theorem Term.subst_shiftN_open (w v : Term) (n : Nat) : ∀ (e : Nat),
    Term.subst (e + n) (Term.shiftN (e + n) w) (Term.shiftN e v)
      = Term.shiftN e (Term.subst n (Term.shiftN n w) v) := by
  intro e
  induction e with
  | zero => rw [Nat.zero_add]; rfl
  | succ e ih =>
    show Term.subst (e + 1 + n) (Term.shiftN (e + 1 + n) w) (Term.shift 0 (Term.shiftN e v))
      = Term.shift 0 (Term.shiftN e (Term.subst n (Term.shiftN n w) v))
    rw [show e + 1 + n = (e + n) + 1 by omega, ← ih,
      Term.shift_subst_lt _ 0 (e + n) _ (Nat.zero_le _), Term.shiftN_succ (e + n) w]

theorem Term.subst_shift0_open (d : Nat) (w T : Term) :
    Term.subst (d + 1) (Term.shiftN (d + 1) w) (Term.shift 0 T)
      = Term.shift 0 (Term.subst d (Term.shiftN d w) T) := by
  rw [Term.shift_subst_lt T 0 d _ (Nat.zero_le d), Term.shiftN_succ]

theorem Term.shiftN_closed_at (h : Term.Closed n w) :
    ∀ k, Term.Closed (n + k) (Term.shiftN k w) := by
  intro k
  induction k with
  | zero => exact h
  | succ k ih => exact Term.Closed.shift _ _ 0 ih

-- a substitution of an open term keeps closedness
theorem Term.Closed.substO : ∀ (t : Term) (n d : Nat) (W : Term), W.Closed n → d ≤ n →
    t.Closed (n + 1) → (Term.subst d W t).Closed n := by
  intro t
  induction t <;> intro n d W hW hd hc <;> simp only [Term.Closed, Term.subst] at *
  case Var =>
    split
    · exact hW
    · split <;> simp only [Term.Closed] <;> omega
  case Typ ih => exact ih n d W hW hd hc
  case Min iha ihb => exact ⟨iha n d W hW hd hc.1, ihb n d W hW hd hc.2⟩
  case All ihA ihB =>
    exact ⟨ihA n d W hW hd hc.1,
      ihB (n + 1) (d + 1) _ (Term.Closed.shift W n 0 hW) (by omega) hc.2⟩
  case Lam ihf => exact ihf (n + 1) (d + 1) _ (Term.Closed.shift W n 0 hW) (by omega) hc
  case App ihf iha => exact ⟨ihf n d W hW hd hc.1, iha n d W hW hd hc.2⟩
  case Mat ihh ihm => exact ⟨ihh n d W hW hd hc.1, ihm n d W hW hd hc.2⟩
  case Eql iha ihb ihT =>
    exact ⟨iha n d W hW hd hc.1, ihb n d W hW hd hc.2.1, ihT n d W hW hd hc.2.2⟩
  case Rwt ihe ihP ihf =>
    exact ⟨ihe n d W hW hd hc.1, ihP n d W hW hd hc.2.1, ihf n d W hW hd hc.2.2⟩
  case Let ihv ihb =>
    exact ⟨ihv n d W hW hd hc.1,
      ihb (n + 1) (d + 1) _ (Term.Closed.shift W n 0 hW) (by omega) hc.2⟩

theorem Bind.shiftN_shift : ∀ (n : Nat) (b : Bind),
    Bind.shiftN n b.shift = Bind.shiftN (n + 1) b := by
  intro n
  induction n with
  | zero => intro b; rfl
  | succ n ih => intro b; show (Bind.shiftN n b.shift).shift = _; rw [ih]; rfl

-- the binders above the substituted one: entry j sees it as index Γ.length - 1 - j,
-- and w shifted past the entries below j
def Ctx.substAt (w : Term) : Ctx → Ctx
  | [] => []
  | b :: Γ => Bind.substAt Γ.length (Term.shiftN Γ.length w) b :: Ctx.substAt w Γ

theorem Ctx.substAt_length (w : Term) : ∀ (Γ : Ctx), (Ctx.substAt w Γ).length = Γ.length := by
  intro Γ; induction Γ with
  | nil => rfl
  | cons b Γ ih => simp only [Ctx.substAt, List.length_cons, ih]

theorem Ctx.substAt_rigid (w : Term) : ∀ (Γ : Ctx), (Ctx.substAt w Γ).rigid = Γ.rigid := by
  intro Γ; induction Γ with
  | nil => rfl
  | cons b Γ ih =>
    obtain ⟨q, T, v⟩ := b
    cases v <;>
      simp only [Ctx.substAt, Bind.substAt, Ctx.rigid, Option.map_none, Option.map_some, ih]

theorem Bind.shift_substAtO (b : Bind) (k : Nat) (w : Term) :
    (b.substAt k (Term.shiftN k w)).shift = b.shift.substAt (k + 1) (Term.shiftN (k + 1) w) := by
  obtain ⟨q, T, v⟩ := b
  cases v <;> simp [Bind.substAt, Bind.shift, ← Term.subst_shift0_open]

theorem Ctx.get_substAt (w : Term) : ∀ (Γ : Ctx) (i : Nat) (b : Bind),
    Ctx.get Γ i = some b →
    Ctx.get (Ctx.substAt w Γ) i = some (b.substAt Γ.length (Term.shiftN Γ.length w)) := by
  intro Γ
  induction Γ with
  | nil => intro i b h; cases h
  | cons b0 Γ ih =>
    intro i b hg
    cases i with
    | zero =>
      simp only [Ctx.get, Ctx.substAt, List.length_cons] at hg ⊢
      cases hg
      rw [Bind.shift_substAtO]
    | succ j =>
      simp only [Ctx.get, Ctx.substAt, List.length_cons, Option.map_eq_some_iff] at hg ⊢
      obtain ⟨b', hb', rfl⟩ := hg
      exact ⟨_, ih j b' hb', Bind.shift_substAtO b' Γ.length w⟩

-- δ of the substituted binders on the substituted term is the substitution
-- into δ of the originals, at the rigid depth
theorem Ctx.δ_substAt (w : Term) : ∀ (Γ : Ctx) (d : Nat) (t : Term),
    Ctx.δ (Ctx.substAt w Γ) d (Term.subst (d + Γ.length) (Term.shiftN (d + Γ.length) w) t)
      = Term.subst (d + Γ.rigid) (Term.shiftN (d + Γ.rigid) w) (Ctx.δ Γ d t) := by
  intro Γ
  induction Γ with
  | nil => intro d t; rfl
  | cons b Γ ih =>
    intro d t
    obtain ⟨q, T, v⟩ := b
    cases v <;> simp only [Ctx.substAt, Bind.substAt, Option.map_none, Option.map_some, Ctx.δ,
      Ctx.rigid, List.length_cons]
    · rw [show d + (Γ.length + 1) = (d + 1) + Γ.length by omega, ih (d + 1) t,
        show d + 1 + Ctx.rigid Γ = d + (Ctx.rigid Γ + 1) by omega]
    · rw [← ih d, show d + (Γ.length + 1) = (d + Γ.length) + 1 by omega,
        Term.subst_subst t (d + Γ.length) d _ _ (by omega),
        Term.shift_shiftN _ _ _ (by omega), Term.subst_shiftN_open]

theorem Ctx.δ_substAt0 (w : Term) (Γ : Ctx) (t : Term) :
    Ctx.δ (Ctx.substAt w Γ) 0 (Term.subst Γ.length (Term.shiftN Γ.length w) t)
      = Term.subst Γ.rigid (Term.shiftN Γ.rigid w) (Ctx.δ Γ 0 t) := by
  have := Ctx.δ_substAt w Γ 0 t
  rwa [Nat.zero_add, Nat.zero_add] at this

-- a comparison of let-expanded terms survives the substitution: a rigid b
-- is skipped by the outer δ, a let b with value w is the substitution itself
theorem Ctx.δ_mid {b : Bind} {Γ₁ : Ctx} {w : Term} (hv : b.v = none ∨ b.v = some w)
    (R : Term → Term → Prop)
    (hR : ∀ d w x y, R x y → R (Term.subst d w x) (Term.subst d w y))
    (Γ₂ : Ctx) (x y : Term)
    (h : R (Ctx.δ (Γ₂ ++ b :: Γ₁) 0 x) (Ctx.δ (Γ₂ ++ b :: Γ₁) 0 y)) :
    R (Ctx.δ (Ctx.substAt w Γ₂ ++ Γ₁) 0
        (Term.subst Γ₂.length (Term.shiftN Γ₂.length w) x))
      (Ctx.δ (Ctx.substAt w Γ₂ ++ Γ₁) 0
        (Term.subst Γ₂.length (Term.shiftN Γ₂.length w) y)) := by
  rw [Ctx.δ_append, Ctx.δ_append, Ctx.substAt_rigid, Nat.zero_add, Ctx.δ_substAt0,
    Ctx.δ_substAt0]
  rw [Ctx.δ_append, Ctx.δ_append, Nat.zero_add] at h
  rcases hv with hv | hv
  · simp only [Ctx.δ, hv] at h
    rw [Ctx.δ_subst _ _ _ _ _ (Nat.le_refl _), Ctx.δ_subst _ _ _ _ _ (Nat.le_refl _)]
    exact hR _ _ _ _ h
  · simp only [Ctx.δ, hv] at h
    exact h

-- a dead judgment replays under any binders, shifted past them
theorem Check.consN (hβ : Book.Closed β) (hΦ : Φ.Weak) {sp : List Term}
    (h : Check β Φ L sp .None Γ t T π u) : ∀ (Δ : Ctx) (sp' : List Term),
    Check β Φ (LHS.void β) sp' .None (Δ ++ Γ) (Term.shiftN Δ.length t)
      (Term.shiftN Δ.length T) Uses.zero .Qnt := by
  intro Δ
  induction Δ with
  | nil => intro sp'; exact (h.void_sp sp').dead
  | cons g Δ ih => intro sp'; exact ((ih []).ins hβ hΦ (Ins.zero (U := g)) sp').dead

theorem Check.zero_of_none {sp : List Term} (h : Check β Φ L sp q Γ t T π u) (hq : q = .None) :
    Check β Φ L sp q Γ t T Uses.zero .Qnt := by
  subst hq; exact h.dead

-- the open substitution at depth Γ₂.length, at the dead policy and demand
-- None: the var at that depth becomes w replayed under Γ₂, the binders of Γ₂
-- see w through their own depth, every other index is renumbered
theorem Check.substD (hβ : Book.Closed β) {sp : List Term} {b : Bind} {Γ₁ : Ctx}
    (h : Check β (Pol.dead β) L sp q Γb t T π u)
    (hw : Check β (Pol.dead β) (LHS.void β) [] .None Γ₁ w b.T π' u')
    (hv : b.v = none ∨ b.v = some w) :
    ∀ (Γ₂ : Ctx), Γb = Γ₂ ++ b :: Γ₁ → q = .None →
    Check β (Pol.dead β) (LHS.void β) sp q (Ctx.substAt w Γ₂ ++ Γ₁)
      (Term.subst Γ₂.length (Term.shiftN Γ₂.length w) t)
      (Term.subst Γ₂.length (Term.shiftN Γ₂.length w) T) Uses.zero .Qnt := by
  have hΦ := Pol.dead_weak hβ
  induction h with
  | @var Γb i bi L sp q hg =>
    intro Γ₂ hΓ hq
    subst hΓ hq
    rcases Nat.lt_trichotomy i Γ₂.length with hlt | heq | hgt
    · rw [Ctx.get_append _ _ _ hlt] at hg
      have hg' : Ctx.get (Ctx.substAt w Γ₂ ++ Γ₁) i
          = some (bi.substAt Γ₂.length (Term.shiftN Γ₂.length w)) := by
        rw [Ctx.get_append _ _ _ (by rw [Ctx.substAt_length]; exact hlt)]
        exact Ctx.get_substAt w Γ₂ i bi hg
      rw [show Term.subst Γ₂.length (Term.shiftN Γ₂.length w) (.Var i) = .Var i by
        simp [Term.subst, show ¬ i = Γ₂.length by omega, show ¬ Γ₂.length < i by omega]]
      exact (Check.var (q := .None) hg').dead
    · subst heq
      have e := Ctx.get_append_ge Γ₂ (b :: Γ₁) 0
      rw [Nat.add_zero] at e
      rw [e] at hg
      simp only [Ctx.get, Option.map_some, Bind.shiftN_shift] at hg
      cases hg
      rw [show Term.subst Γ₂.length (Term.shiftN Γ₂.length w) (.Var Γ₂.length)
          = Term.shiftN Γ₂.length w by simp [Term.subst], Bind.shiftN_T, Term.subst_shiftN]
      have := hw.consN hβ hΦ (Ctx.substAt w Γ₂) sp
      rwa [Ctx.substAt_length] at this
    · obtain ⟨j, rfl⟩ : ∃ j, i = Γ₂.length + (j + 1) :=
        ⟨i - Γ₂.length - 1, by omega⟩
      rw [Ctx.get_append_ge] at hg
      simp only [Ctx.get, Option.map_map, Option.map_eq_some_iff, Function.comp_apply,
        Bind.shiftN_shift] at hg
      obtain ⟨b₁, hb₁, rfl⟩ := hg
      have e := Ctx.get_append_ge (Ctx.substAt w Γ₂) Γ₁ j
      rw [Ctx.substAt_length, hb₁, Option.map_some] at e
      rw [show Term.subst Γ₂.length (Term.shiftN Γ₂.length w) (.Var (Γ₂.length + (j + 1)))
          = .Var (Γ₂.length + j) by
          simp [Term.subst, show Γ₂.length < Γ₂.length + (j + 1) by omega,
            show Γ₂.length + (j + 1) - 1 = Γ₂.length + j by omega],
        Bind.shiftN_T, Term.subst_shiftN]
      have : Check β (Pol.dead β) (LHS.void β) sp .None (Ctx.substAt w Γ₂ ++ Γ₁)
          (.Var (Γ₂.length + j)) (Bind.shiftN Γ₂.length b₁).T Uses.zero .Qnt :=
        (Check.var (q := .None) e).dead
      rw [Bind.shiftN_T] at this
      exact this
  | ref hk _ _ =>
    intro Γ₂ hΓ hq
    rw [Term.subst_closed _ 0 _ _ (hβ.defn hk).1 (Nat.zero_le _)]
    have hj := Book.defn_lt hk
    exact Check.zero_of_none (Check.ref hk (fun _ => Nat.le_of_lt hj)
      (fun _ he => absurd he (Nat.ne_of_lt hj))) hq
  | refA hk h0 =>
    intro Γ₂ hΓ hq
    rw [Term.subst_closed _ 0 _ _ (hβ.adtd hk).1 (Nat.zero_le _)]
    exact Check.zero_of_none (Check.refA hk h0) hq
  | adt hk =>
    intro Γ₂ hΓ hq
    rw [Term.subst_closed _ 0 _ _ (hβ.adtd hk).1 (Nat.zero_le _)]
    exact Check.zero_of_none (Check.adt hk) hq
  | ctr hk hc hr =>
    intro Γ₂ hΓ hq
    rw [Term.subst_closed _ 0 _ _ (Term.retip_closed _ _ _ _ 0 ((hβ.adtd hk).2 _ _ hc))
      (Nat.zero_le _)]
    exact Check.zero_of_none (Check.ctr hk hc hr) hq
  | typ _ ihg =>
    intro Γ₂ hΓ hq
    exact Check.zero_of_none (Check.typ (ihg Γ₂ hΓ _root_.rfl)) hq
  | qnt => intro Γ₂ hΓ hq; exact Check.qnt
  | qua => intro Γ₂ hΓ hq; exact Check.zero_of_none Check.qua hq
  | min _ _ iha ihb =>
    intro Γ₂ hΓ hq
    exact Check.zero_of_none (Check.min (iha Γ₂ hΓ hq) (ihb Γ₂ hΓ hq)) hq
  | all _ _ ihA ihB =>
    intro Γ₂ hΓ hq
    subst hΓ
    simp only [Term.subst, Term.shiftN_succ]
    exact Check.zero_of_none (Check.all (ihA Γ₂ _root_.rfl _root_.rfl)
      (ihB (⟨_, _, none⟩ :: Γ₂) _root_.rfl _root_.rfl)) hq
  | lam _ _ _ ihA ihf =>
    intro Γ₂ hΓ hq
    subst hΓ
    simp only [Term.subst, Term.shiftN_succ]
    exact Check.zero_of_none (Check.lam (ihA Γ₂ _root_.rfl _root_.rfl)
      (ihf (⟨_, _, none⟩ :: Γ₂) _root_.rfl hq) trivial) hq
  | app _ _ ihf ihx =>
    intro Γ₂ hΓ hq
    subst hΓ
    simp only [Term.subst, Term.subst_subst0, Term.shiftN_succ]
    have hf' := ihf Γ₂ _root_.rfl hq
    simp only [Term.subst, Term.shiftN_succ] at hf'
    exact Check.zero_of_none (Check.app (hf'.sp _)
      (ihx Γ₂ _root_.rfl (by rw [hq]; exact Quant.dem_none _))) hq
  | appLam ha _ ih =>
    intro Γ₂ hΓ hq
    subst hΓ
    have := ih Γ₂ _root_.rfl hq
    rw [Term.subst_subst0, Term.shiftN_succ] at this
    simp only [Term.subst, Term.shiftN_succ]
    refine Check.appLam ?_ this
    simp only [List.length_append, List.length_cons, Ctx.substAt_length] at ha ⊢
    have hW := Term.shiftN_closed_at hw.closed Γ₂.length
    exact Term.Closed.substO _ _ _ _ (Term.Closed.mono _ _ _ hW (by omega)) (by omega)
      (Term.Closed.mono _ _ _ ha (by omega))
  | let_ _ _ _ _ ihv ihA ihb =>
    intro Γ₂ hΓ hq
    subst hΓ
    simp only [Term.subst, Term.shiftN_succ]
    have hb' := ihb (⟨_, _, some _⟩ :: Γ₂) _root_.rfl hq
    simp only [List.length_cons, Ctx.substAt, Bind.substAt, Option.map_some,
      Term.subst_shift0_open] at hb'
    exact Check.zero_of_none (Check.let_ (ihv Γ₂ _root_.rfl (by rw [hq]; exact Quant.dem_none _))
      (ihA Γ₂ _root_.rfl _root_.rfl) hb' trivial) hq
  | eql _ _ _ ihT iha ihb =>
    intro Γ₂ hΓ hq
    simp only [Term.subst]
    exact Check.zero_of_none (Check.eql (ihT Γ₂ hΓ _root_.rfl) (iha Γ₂ hΓ _root_.rfl)
      (ihb Γ₂ hΓ _root_.rfl)) hq
  | rfl hc =>
    intro Γ₂ hΓ hq
    subst hΓ
    simp only [Term.subst]
    exact Check.zero_of_none (Check.rfl (Ctx.δ_mid hv (Conv β)
      (fun d w x y h => Conv.subst hβ h (Conv.refl w) d) Γ₂ _ _ hc)) hq
  | rwt _ _ _ ihe ihP ihf =>
    intro Γ₂ hΓ hq
    simp only [Term.subst]
    have hP' := ihP Γ₂ hΓ _root_.rfl
    rw [Term.subst_jmotive] at hP'
    exact Check.zero_of_none (Check.rwt (ihe Γ₂ hΓ hq) hP' (ihf Γ₂ hΓ hq)) hq
  | mat hk hc hr hlen hlive hins hgoal _ _ ihh ihm =>
    intro Γ₂ hΓ hq
    simp only [Term.subst, Term.subst_apps, Term.shiftN_succ]
    have hi' := hins.subst Γ₂.length (Term.shiftN Γ₂.length w)
    rw [Term.subst_closed _ 0 _ _ ((hβ.adtd hk).2 _ _ hc) (Nat.zero_le _)] at hi'
    have hg' := hgoal.subst Γ₂.length (Term.shiftN Γ₂.length w)
    simp only [Term.subst_apps, Term.subst, Term.shiftN_succ] at hg'
    have hm' := ihm Γ₂ hΓ hq
    simp only [Term.subst, Term.subst_apps, Term.shiftN_succ] at hm'
    exact Check.zero_of_none (Check.mat hk hc hr (by simp [hlen]) hlive hi' hg'
      (ihh Γ₂ hΓ hq) hm') hq
  | efq hk hlive _ =>
    intro Γ₂ hΓ hq
    simp only [Term.subst, Term.subst_apps, Term.shiftN_succ]
    exact Check.zero_of_none (Check.efq hk hlive (.inr trivial)) hq
  | cnv _ hc iht =>
    intro Γ₂ hΓ hq
    subst hΓ
    exact Check.cnv (iht Γ₂ _root_.rfl hq) (Ctx.δ_mid hv _ hΦ.subst Γ₂ _ _ hc)

-- ----------------------------------------------------------------------------
-- §K3 dead-code preservation along eta-free parallel steps: the coarsening,
-- context transport, the spine walks and the root rules at the dead policy;
-- the eta-free step and its closure and parallel form; the theorem
-- ----------------------------------------------------------------------------

-- the dead policy is coarser than the standard one, so every standard
-- derivation replays under it
theorem Check.dead_pol (hβ : Book.Closed β) {sp : List Term}
    (h : Check β (Pol.std β) L sp q Γ t T π u) : Check β (Pol.dead β) L sp q Γ t T π u :=
  Check.mono (Pol.dead_std hβ) (fun _ _ => trivial) h

-- adt_valid's constructor walk replays at the dead policy under the void
-- equation (CtrOkD kinds the Lone field at Kind(G), as the spec's CtrOk does)
theorem CtrOk.dead (hβ : Book.Closed β) : ∀ {T : Term} {Γ : Ctx} {i : Nat},
    CtrOk β k pn G Γ i T → CtrOkD β (Pol.dead β) pn G Γ i T := by
  intro T
  induction T with
  | All q A B _ ih =>
    intro Γ i h
    obtain ⟨⟨π, hA⟩, hB⟩ := h
    refine ⟨⟨π, ?_⟩, ih hB⟩
    have h' := hA.void.dead_pol hβ
    by_cases hc : pn ≤ i ∧ q = .Lone <;> simp only [hc, if_false] at h' ⊢ <;> exact h'
  | _ => intros; trivial

theorem Book.OkK.dead (hok : Book.Ok β) : Book.OkK β (Pol.dead β) := by
  intro a A c C hA hC
  obtain ⟨_, G, hS, hcs⟩ := hok a (.adt A) (Book.adt_tld hA)
  exact ⟨G, hS, CtrOk.dead hok.closed (hcs c C hC).2⟩

-- ----------------------------------------------------------------------------
-- small facts about the dead policy and the term algebra
-- ----------------------------------------------------------------------------

theorem Pol.dead_pre (hβ : Book.Closed β) : Pol.Pre (Pol.dead β) :=
  ⟨Pol.dead_refl β, fun h1 h2 => Pol.dead_trans hβ h1 h2⟩

theorem Pol.dead_conv (hβ : Book.Closed β) (h : Conv β a b) : (Pol.dead β).conv a b :=
  Pol.dead_std hβ _ _ (Le.conv h)

theorem Pol.dead_substR (hβ : Book.Closed β) (h : (Pol.dead β).conv X Y)
    (hw : Conv (Book.qer β) (Term.qer w) (Term.qer w')) (d : Nat) :
    (Pol.dead β).conv (Term.subst d w X) (Term.subst d w' Y) := by
  show Le _ _ _; rw [Term.qer_subst, Term.qer_subst]; exact Le.substR hβ.qer h hw d

-- a fitted pair of arrows: domains fit backwards, codomains along (the
-- quantities are erased, so they need not agree)
theorem Pol.dead_all_inv (hβ : Book.Closed β)
    (h : (Pol.dead β).conv (Ctx.δ Γ 0 (.All q A B)) (Ctx.δ Γ 0 (.All q' A' B'))) :
    (Pol.dead β).conv (Ctx.δ Γ 0 A') (Ctx.δ Γ 0 A) ∧
      (Pol.dead β).conv (Ctx.δ Γ 1 B) (Ctx.δ Γ 1 B') := by
  have h' : Le (Book.qer β) _ _ := h
  rw [Ctx.δ_all, Ctx.δ_all] at h'
  simp only [Term.qer] at h'
  exact (Le.all_inv hβ.qer h' .refl .refl).2

theorem Ctx.δ_eql : ∀ (Γ : Ctx) (d : Nat) (x y T : Term),
    Ctx.δ Γ d (.Eql x y T) = .Eql (Ctx.δ Γ d x) (Ctx.δ Γ d y) (Ctx.δ Γ d T) := by
  intro Γ
  induction Γ with
  | nil => intros; rfl
  | cons b Γ ih =>
    intro d x y T
    obtain ⟨_, _, v⟩ := b
    cases v <;> simp only [Ctx.δ, Term.subst, ih]

theorem Term.closed_of_occ : ∀ (t : Term) (n : Nat),
    (∀ i, n ≤ i → Term.occ i t = 0) → Term.Closed n t := by
  intro t
  induction t with
  | Var i => intro n h; exact Nat.lt_of_not_le fun hi => by simpa [Term.occ] using h i hi
  | Typ g ih => exact ih
  | Min a b iha ihb | App a b iha ihb | Mat _ _ a b iha ihb =>
    intro n h
    exact ⟨iha n fun i hi => by
        have := h i hi; simp only [Term.occ, Nat.max] at this; (try split at this) <;> omega,
      ihb n fun i hi => by
        have := h i hi; simp only [Term.occ, Nat.max] at this; (try split at this) <;> omega⟩
  | Eql a b c iha ihb ihc | Rwt a b c iha ihb ihc =>
    intro n h
    exact ⟨iha n fun i hi => by have := h i hi; simp only [Term.occ] at this; omega,
      ihb n fun i hi => by have := h i hi; simp only [Term.occ] at this; omega,
      ihc n fun i hi => by have := h i hi; simp only [Term.occ] at this; omega⟩
  | All _ a b iha ihb | Let _ a b iha ihb =>
    intro n h
    refine ⟨iha n fun i hi => by have := h i hi; simp only [Term.occ] at this; omega,
      ihb (n + 1) fun i hi => ?_⟩
    have := h (i - 1) (by omega)
    simp only [Term.occ, show i - 1 + 1 = i by omega] at this; omega
  | Lam f ih =>
    intro n h
    refine ih (n + 1) fun i hi => ?_
    have := h (i - 1) (by omega)
    simp only [Term.occ, show i - 1 + 1 = i by omega] at this; omega
  | _ => intros; trivial

theorem Par.closed (hβ : Book.Closed β) (hp : Par β t t') (hc : Term.Closed n t) :
    Term.Closed n t' :=
  Term.closed_of_occ t' n (fun i hi => hp.occ_zero hβ i (Term.occ_closed t n i hc hi))

theorem Insts.qer (h : Insts T ps X) : Insts (Term.qer T) (ps.map Term.qer) (Term.qer X) := by
  induction h with
  | nil => exact .nil
  | cons _ ih => simp only [List.map, Term.qer]; exact .cons (by rw [← Term.qer_subst]; exact ih)

theorem Insts.δ (h : Insts T ps X) : ∀ (Γ : Ctx) (d : Nat),
    Insts (Ctx.δ Γ d T) (ps.map (Ctx.δ Γ d)) (Ctx.δ Γ d X) := by
  intro Γ
  induction Γ generalizing T ps X with
  | nil => intro d; simpa [Ctx.δ] using h
  | cons b Γ ih =>
    intro d
    obtain ⟨_, _, v⟩ := b
    cases v with
    | none => simp only [Ctx.δ]; exact ih h (d + 1)
    | some v =>
      simp only [Ctx.δ]
      have := ih (h.subst d (Term.shiftN d v)) d
      rw [List.map_map] at this
      exact this

inductive Ctx.Cv (β : Book) : Ctx → Ctx → Prop
  | nil   : Ctx.Cv β [] []
  | rigid : Conv β T T' → Ctx.Cv β Γ Γ' →
            Ctx.Cv β (⟨q, T, none⟩ :: Γ) (⟨q, T', none⟩ :: Γ')
  | val   : Conv β T T' → Conv β v v' → Ctx.Cv β Γ Γ' →
            Ctx.Cv β (⟨q, T, some v⟩ :: Γ) (⟨q, T', some v'⟩ :: Γ')

theorem Ctx.Cv.refl : ∀ (Γ : Ctx), Ctx.Cv β Γ Γ
  | [] => .nil
  | ⟨_, _, v⟩ :: Γ => by cases v <;> constructor <;> first | exact Conv.refl _ | exact Ctx.Cv.refl Γ

theorem Ctx.Cv.length (h : Ctx.Cv β Γ Γ') : Γ'.length = Γ.length := by
  induction h <;> simp [*]

theorem Conv.shiftN (hβ : Book.Closed β) (h : Conv β a b) :
    ∀ n, Conv β (Term.shiftN n a) (Term.shiftN n b)
  | 0 => h
  | n + 1 => (Conv.shiftN hβ h n).shift hβ 0

theorem Ctx.Cv.δ (hβ : Book.Closed β) (h : Ctx.Cv β Γ Γ') :
    ∀ d t, Conv β (Ctx.δ Γ d t) (Ctx.δ Γ' d t) := by
  induction h with
  | nil => intro d t; exact Conv.refl _
  | rigid _ _ ih => intro d t; exact ih (d + 1) t
  | val _ hv _ ih =>
    intro d t
    exact (Ctx.δ_conv hβ _ d (Conv.substR hβ (hv.shiftN hβ d) d t)).trans hβ (ih d _)

theorem Ctx.Cv.get (hβ : Book.Closed β) (h : Ctx.Cv β Γ Γ') :
    ∀ i b, Ctx.get Γ i = some b → ∃ b', Ctx.get Γ' i = some b' ∧ Conv β b'.T b.T := by
  induction h with
  | nil => intro i b hg; cases i <;> cases hg
  | rigid hc _ ih | val hc _ _ ih =>
    intro i b hg
    cases i with
    | zero => cases hg; exact ⟨_, rfl, (hc.shift hβ 0).symm⟩
    | succ i =>
      simp only [Ctx.get, Option.map_eq_some_iff] at hg ⊢
      obtain ⟨b0, hg0, rfl⟩ := hg
      obtain ⟨b0', hg', hT⟩ := ih i b0 hg0
      exact ⟨b0'.shift, ⟨b0', hg', rfl⟩, hT.shift hβ 0⟩

theorem Check.cv (hβ : Book.Closed β) {sp : List Term}
    (h : Check β (Pol.dead β) L sp q Γ t T π u) :
    ∀ Γ', Ctx.Cv β Γ Γ' → Check β (Pol.dead β) (LHS.void β) sp q Γ' t T π u := by
  induction h with
  | var hg =>
    intro Γ' hΓ
    obtain ⟨b', hg', hT⟩ := hΓ.get hβ _ _ hg
    exact .cnv (.var hg') (Pol.dead_std hβ _ _ (.conv (Ctx.δ_conv hβ _ 0 hT)))
  | ref hk _ _ =>
    intro Γ' _
    have hj := Book.defn_lt hk
    exact .ref hk (fun _ => Nat.le_of_lt hj) (fun _ he => absurd he (Nat.ne_of_lt hj))
  | refA hk h0 => intro Γ' _; exact .refA hk h0
  | adt hk => intro Γ' _; exact .adt hk
  | ctr hk hc hr => intro Γ' _; exact .ctr hk hc hr
  | typ _ ihg => intro Γ' hΓ; exact .typ (ihg _ hΓ)
  | qnt => intro Γ' _; exact .qnt
  | qua => intro Γ' _; exact .qua
  | min _ _ iha ihb => intro Γ' hΓ; exact .min (iha _ hΓ) (ihb _ hΓ)
  | all _ _ ihA ihB => intro Γ' hΓ; exact .all (ihA _ hΓ) (ihB _ (.rigid (Conv.refl _) hΓ))
  | lam _ _ hle ihA ihf =>
    intro Γ' hΓ; exact .lam (ihA _ hΓ) (ihf _ (.rigid (Conv.refl _) hΓ)) hle
  | app _ _ ihf ihx => intro Γ' hΓ; exact .app (ihf _ hΓ) (ihx _ hΓ)
  | appLam ha _ ih => intro Γ' hΓ; exact .appLam (by rw [hΓ.length]; exact ha) (ih _ hΓ)
  | let_ _ _ _ hle ihv ihA ihb =>
    intro Γ' hΓ
    exact .let_ (ihv _ hΓ) (ihA _ hΓ) (ihb _ (.val (Conv.refl _) (Conv.refl _) hΓ)) hle
  | eql _ _ _ ihT iha ihb => intro Γ' hΓ; exact .eql (ihT _ hΓ) (iha _ hΓ) (ihb _ hΓ)
  | rfl hc =>
    intro Γ' hΓ
    exact .rfl ((hΓ.δ hβ 0 _).symm.trans hβ (hc.trans hβ (hΓ.δ hβ 0 _)))
  | rwt _ _ _ ihe ihP ihf => intro Γ' hΓ; exact .rwt (ihe _ hΓ) (ihP _ hΓ) (ihf _ hΓ)
  | mat hk hc hr hlen hlive hins hgoal _ _ ihh ihm =>
    intro Γ' hΓ; exact .mat hk hc hr hlen hlive hins hgoal (ihh _ hΓ) (ihm _ hΓ)
  | efq hk hlive _ => intro Γ' _; exact .efq hk hlive (.inr trivial)
  | cnv _ hc iht =>
    intro Γ' hΓ
    exact .cnv (iht _ hΓ) (Pol.dead_trans hβ (Pol.dead_conv hβ (hΓ.δ hβ 0 _).symm)
      (Pol.dead_trans hβ hc (Pol.dead_conv hβ (hΓ.δ hβ 0 _))))

-- ----------------------------------------------------------------------------
-- the spine walks at the dead policy (E's, with Le.all_inv read in the erased book)
-- ----------------------------------------------------------------------------

theorem Args.stepD (hβ : Book.Closed β)
    (hle : (Pol.dead β).conv (Ctx.δ Γ 0 (.All qw K Bw)) (Ctx.δ Γ 0 T0))
    (h : Args β (Pol.dead β) L .None Γ T0 (x :: as) T1 πs us) :
    ∃ πx ux πs' us' B1, πs = Uses.add πx πs' ∧ us = ux :: us' ∧
      Check β (Pol.dead β) L [] .None Γ x K πx ux ∧
      (Pol.dead β).conv (Ctx.δ Γ 0 (Term.subst 0 x Bw)) (Ctx.δ Γ 0 (Term.subst 0 x B1)) ∧
      Args β (Pol.dead β) L .None Γ (Term.subst 0 x B1) as T1 πs' us' := by
  cases h with
  | cons hc hx hr =>
    rename_i q1 A1 B1 πx ux πs' us'
    obtain ⟨hA, hB⟩ := Pol.dead_all_inv hβ (Pol.dead_trans hβ hle hc)
    rw [Quant.dem_none] at hx
    refine ⟨_, _, _, _, _, _root_.rfl, _root_.rfl, Check.cnv hx hA, ?_, hr⟩
    rw [Ctx.δ_subst Γ 0 0 _ _ (Nat.le_refl 0), Ctx.δ_subst Γ 0 0 _ _ (Nat.le_refl 0)]
    exact (Pol.dead_weak hβ).subst 0 _ _ _ hB

theorem Args.paramsD (hβ : Book.Closed β) :
    ∀ {qs : List Term} {pn : Nat} {ps0 : List Term} {Tw T0 Tm : Term} {πp : Uses}
      {up : List Term},
    WTele a r ps0 pn fn Tw → Args β (Pol.dead β) L .None Γ T0 qs Tm πp up →
    (Pol.dead β).conv (Ctx.δ Γ 0 (Term.retip r' pn (pn + fn) Tw)) (Ctx.δ Γ 0 T0) →
    qs.length = pn →
    ∃ TS, Insts Tw qs TS ∧ FTele a r (ps0 ++ qs) fn TS ∧
      (Pol.dead β).conv (Ctx.δ Γ 0 (Term.retip r' 0 fn TS)) (Ctx.δ Γ 0 Tm) := by
  intro qs
  induction qs with
  | nil =>
    intro pn ps0 Tw T0 Tm πp up hw h hle hlen
    cases h
    cases pn with
    | zero => rw [Nat.zero_add] at hle; exact ⟨Tw, .nil, by rw [List.append_nil]; exact hw, hle⟩
    | succ pk => simp at hlen
  | cons x qs ih =>
    intro pn ps0 Tw T0 Tm πp up hw h hle hlen
    cases pn with
    | zero => simp at hlen
    | succ pk =>
      obtain ⟨qw, K, Bw, hT, hwB, hw'⟩ := WTele.param (x := x) hw
      subst hT
      rw [show pk + 1 + fn = pk + fn + 1 by omega] at hle
      obtain ⟨πx, ux, πs', us', B1, _, _, _, hB, hr⟩ :=
        Args.stepD hβ (qw := .None) (K := K) (Bw := Term.retip r' pk (pk + fn) Bw) hle h
      rw [WTele.retip_subst hwB r' 0 x] at hB
      obtain ⟨TS, hI, hF, hle'⟩ := ih hw' hr hB (by simp at hlen; omega)
      exact ⟨TS, .cons hI, by simpa [List.append_assoc] using hF, hle'⟩

theorem Args.fteleD (hβ : Book.Closed β) :
    ∀ {xs : List Term} {fn : Nat} {ps : List Term} {TS T0 T1 : Term} {πs : Uses}
      {us : List Term},
    FTele a r ps fn TS → Args β (Pol.dead β) L .None Γ T0 xs T1 πs us →
    (Pol.dead β).conv (Ctx.δ Γ 0 (Term.retip r' 0 fn TS)) (Ctx.δ Γ 0 T0) → xs.length = fn →
    Args β (Pol.dead β) L .None Γ TS xs (Term.apps (.Adt a r) ps) πs us ∧
      (Pol.dead β).conv (Ctx.δ Γ 0 (Term.apps (.Adt a r') ps)) (Ctx.δ Γ 0 T1) := by
  intro xs
  induction xs with
  | nil =>
    intro fn ps TS T0 T1 πs us hF h hle hlen
    cases h
    cases fn with
    | zero =>
      simp only [FTele] at hF; subst hF
      rw [Term.retip_adt_apps] at hle
      exact ⟨.nil, hle⟩
    | succ fk => simp at hlen
  | cons x xs ih =>
    intro fn ps TS T0 T1 πs us hF h hle hlen
    cases fn with
    | zero => simp at hlen
    | succ fk =>
      obtain ⟨qf, F, Bs, hT, hFB, hF'⟩ := FTele.field (x := x) hF
      subst hT
      obtain ⟨πx, ux, πs', us', B1, rfl, rfl, hx, hB, hr⟩ :=
        Args.stepD hβ (qw := qf) (K := F) (Bw := Term.retip r' 0 fk Bs) hle h
      rw [FTele.retip_subst hFB r' 0 x] at hB
      obtain ⟨hw, hle'⟩ := ih hF' hr hB (by simp at hlen; omega)
      exact ⟨.cons (Pol.dead_refl _ _) (by rw [Quant.dem_none]; exact hx) hw, hle'⟩

theorem MatGoal.applyD (hβ : Book.Closed β) :
    ∀ (n : Nat) {B s tel G : Term}, MatGoal q' n B s tel G →
    ∀ {TS xs T1 πs us}, Args β (Pol.dead β) L .None Γ TS xs T1 πs us →
    (Pol.dead β).conv (Ctx.δ Γ 0 tel) (Ctx.δ Γ 0 TS) → xs.length = n →
    Args β (Pol.dead β) L .None Γ G xs (Term.subst 0 (Term.apps s xs) B) πs us := by
  intro n
  induction n with
  | zero =>
    intro B s tel G hg TS xs T1 πs us h hle hlen
    cases hg
    cases xs with
    | nil => cases h; exact .nil
    | cons => simp at hlen
  | succ n ih =>
    intro B s tel G hg TS xs T1 πs us h hle hlen
    cases hg with
    | succ hrest =>
      rename_i Bf G0 qf F
      cases xs with
      | nil => simp at hlen
      | cons x xs =>
        obtain ⟨πx, ux, πs', us', B1, rfl, rfl, hx, hB, hr⟩ := Args.stepD hβ hle h
        have hsub := hrest.subst 0 x
        rw [Term.subst_shift B 1 _] at hsub
        have es : Term.subst 0 x (.App (Term.shift 0 s) (.Var 0)) = .App s x := by
          show Term.App _ _ = _
          rw [Term.subst_shift s 0 x]; simp [Term.subst]
        rw [es] at hsub
        have hx' : Check β (Pol.dead β) L [] (Quant.dem (Quant.mul qf q') .None) Γ x F πx ux :=
          by rw [Quant.dem_none]; exact hx
        exact .cons (Pol.dead_refl _ _) hx' (ih hsub hr hB (by simp at hlen; omega))

theorem Args.steleD (hβ : Book.Closed β) :
    ∀ {as : List Term} {n : Nat} {Tw G T0 T1 : Term} {πs : Uses} {us : List Term},
    STele β n Tw G → Args β (Pol.dead β) L .None Γ T0 as T1 πs us →
    (Pol.dead β).conv (Ctx.δ Γ 0 Tw) (Ctx.δ Γ 0 T0) →
    (as.length < n ∧
      ∃ qA A B, (Pol.dead β).conv (Ctx.δ Γ 0 (.All qA A B)) (Ctx.δ Γ 0 T1)) ∨
    (as.length = n ∧ ∃ G', (Pol.dead β).conv (Ctx.δ Γ 0 (.Typ G')) (Ctx.δ Γ 0 T1)) := by
  intro as
  induction as with
  | nil =>
    intro n Tw G T0 T1 πs us hs h hle
    cases h
    cases n with
    | zero =>
      right
      exact ⟨_root_.rfl, G, Le.red_l hβ.qer ((Ctx.δ_red hβ Γ 0 hs).strong.qer) hle⟩
    | succ n =>
      obtain ⟨q0, K, B, hT, _⟩ := hs; subst hT; left; exact ⟨by simp, _, _, _, hle⟩
  | cons x as ih =>
    intro n Tw G T0 T1 πs us hs h hle
    cases n with
    | zero =>
      exfalso
      cases h with
      | cons hc _ _ =>
        have := Le.red_l hβ.qer ((Ctx.δ_red hβ Γ 0 hs).strong.qer) (Pol.dead_trans hβ hle hc)
        rw [Ctx.δ_typ, Ctx.δ_all] at this
        simp only [Term.qer] at this
        exact this.typ_all
    | succ n =>
      obtain ⟨q0, K, Bw, hT, hs'⟩ := hs
      subst hT
      obtain ⟨πx, ux, πs', us', B1, _, _, _, hB, hr⟩ := Args.stepD hβ hle h
      rcases ih (hs'.subst hβ 0 x) hr hB with ⟨hlt, hex⟩ | ⟨hlen, hcv⟩
      · left; exact ⟨by simp at hlt ⊢; omega, hex⟩
      · right; exact ⟨by simp at hlen ⊢; omega, hcv⟩

-- ----------------------------------------------------------------------------
-- the root rules at the dead policy, demand None, any context
-- ----------------------------------------------------------------------------

theorem Check.betaD (hβ : Book.Closed β) {sp : List Term}
    (h : Check β (Pol.dead β) L sp .None Γ (.App (.Lam f) a) T π u) :
    Check β (Pol.dead β) (LHS.void β) [] .None Γ (Term.subst 0 a f) T Uses.zero .Qnt := by
  have hΦ := Pol.dead_pre hβ
  rcases h.app_inv hΦ with
    ⟨q', A, B, πf, uf, πa, ua, hf, ha, hle, _, _⟩ | ⟨g, T0, hg, _, hb, hle⟩
  · obtain ⟨q1, A1, B1, πA, π1, uf1, _, hb, _, hleF, _, _⟩ := hf.lam_inv hΦ
    obtain ⟨hAA, hBB⟩ := Pol.dead_all_inv hβ hleF
    rw [Quant.dem_none] at ha
    have hres :=
      Check.substD hβ hb.void (ha.cnv hAA).void (.inl _root_.rfl) [] _root_.rfl _root_.rfl
    simp only [List.length_nil, Term.shiftN, Ctx.substAt, List.nil_append] at hres
    refine hres.cnv (Pol.dead_trans hβ ?_ hle)
    rw [Ctx.δ_subst Γ 0 0 _ _ (Nat.le_refl 0), Ctx.δ_subst Γ 0 0 _ _ (Nat.le_refl 0)]
    exact (Pol.dead_weak hβ).subst 0 _ _ _ hBB
  · cases hg; exact ((hb.void_sp []).cnv hle).dead

-- a definition's body, dead, at the dead policy, in any context
theorem Check.bodyD (hok : Book.Ok β) (hk : Book.defn β k = some d)
    (Γ : Ctx) : Check β (Pol.dead β) (LHS.void β) [] .None Γ d.body d.ty Uses.zero .Qnt := by
  obtain ⟨_, _, _, _, πb, ub, hc⟩ := hok k (.defn d) (Book.defn_tld hk)
  exact (hc.dead.dead_pol hok.closed).weaken hok.closed (Pol.dead_weak hok.closed) Γ

theorem Check.drefD (hok : Book.Ok β) {sp : List Term} (hk : Book.defn β k = some d)
    (h : Check β (Pol.dead β) L sp .None Γ (Term.apps (.Ref k) as) T π u) :
    Check β (Pol.dead β) (LHS.void β) [] .None Γ (Term.apps d.body as) T Uses.zero .Qnt := by
  have hβ := hok.closed
  have hΦ := Pol.dead_pre hβ
  obtain ⟨T0, π0, u0, T1, πs, us, hhead, hargs, hle, _, _⟩ :=
    h.void.apps_inv hΦ as (.Ref k) (fun _ e => Term.noConfusion e)
  rcases hhead.ref_inv hΦ with ⟨d', hk', _, _, hle0, _, _⟩ | ⟨A, hA, _⟩
  · rw [hk] at hk'; cases hk'
    have hc' := (Check.bodyD hok hk Γ).void_sp (as ++ sp)
    exact (((Check.apps (hc'.cnv hle0) hargs).cnv hle).void_sp []).dead
  · exact (Book.defn_adt_clash hk hA).elim

theorem Check.rwtD (hβ : Book.Closed β) {sp : List Term}
    (h : Check β (Pol.dead β) L sp .None Γ (.Rwt .Rfl P f) T π u) :
    Check β (Pol.dead β) (LHS.void β) [] .None Γ f T Uses.zero .Qnt := by
  have hΦ := Pol.dead_pre hβ
  obtain ⟨a, b, T0, πe, ue, πP, πf, uf, he, _, hf, hle, _, _⟩ := h.rwt_inv hΦ
  obtain ⟨a1, b1, T1, hab, hleE, _, _⟩ := he.rfl_inv hΦ
  have hleE' : Le (Book.qer β) _ _ := hleE
  rw [Ctx.δ_eql, Ctx.δ_eql] at hleE'
  simp only [Term.qer] at hleE'
  obtain ⟨hca, hcb, _⟩ := Le.eql_inv hβ.qer hleE' .refl .refl
  have hab' : Conv (Book.qer β) (Term.qer (Ctx.δ Γ 0 a)) (Term.qer (Ctx.δ Γ 0 b)) :=
    (hca.symm.trans hβ.qer hab.qer).trans hβ.qer hcb
  have key : (Pol.dead β).conv (Ctx.δ Γ 0 (Term.apps P [a, .Rfl]))
      (Ctx.δ Γ 0 (Term.apps P [b, .Rfl])) := by
    show Le _ _ _
    rw [Ctx.δ_apps, Ctx.δ_apps, Term.qer_apps, Term.qer_apps]
    simp only [List.map_cons, List.map_nil]
    exact Le.conv (Conv.apps (Conv.refl _) (.cons hab' (.cons (Conv.refl _) .nil)))
  exact ((hf.void_sp []).cnv (Pol.dead_trans hβ key hle)).dead

-- the constructor walk and its rebuilding at the dead policy (E's Args.wtele, F's Args.rebuild)
theorem Args.wteleD (hβ : Book.Closed β) :
    ∀ {as : List Term} {pn fn : Nat} {ps : List Term} {Tw T0 T1 : Term} {πs : Uses}
      {us : List Term},
    WTele a r ps pn fn Tw → Args β (Pol.dead β) L .None Γ T0 as T1 πs us →
    (Pol.dead β).conv (Ctx.δ Γ 0 Tw) (Ctx.δ Γ 0 T0) →
    (as.length < pn + fn ∧
      ∃ qA A B, (Pol.dead β).conv (Ctx.δ Γ 0 (.All qA A B)) (Ctx.δ Γ 0 T1)) ∨
    (as.length = pn + fn ∧
      (Pol.dead β).conv (Ctx.δ Γ 0 (Term.apps (.Adt a r) (ps ++ as.take pn)))
        (Ctx.δ Γ 0 T1)) := by
  intro as
  induction as with
  | nil =>
    intro pn fn ps Tw T0 T1 πs us hw h hle
    cases h
    cases pn with
    | zero =>
      cases fn with
      | zero => simp only [WTele, FTele] at hw; subst hw; right; simpa using hle
      | succ fk =>
        obtain ⟨qf, F, B, hT, _⟩ := hw; subst hT; left; exact ⟨by simp, _, _, _, hle⟩
    | succ pk =>
      obtain ⟨q0, K, B, hT, _⟩ := hw; subst hT; left
      exact ⟨by show 0 < pk + 1 + fn; omega, _, _, _, hle⟩
  | cons x as ih =>
    intro pn fn ps Tw T0 T1 πs us hw h hle
    cases pn with
    | succ pk =>
      obtain ⟨qw, K, Bw, hT, _, hw'⟩ := WTele.param (x := x) hw
      subst hT
      obtain ⟨πx, ux, πs', us', B1, _, _, _, hB, hr⟩ := Args.stepD hβ hle h
      rcases ih hw' hr hB with ⟨hlt, hex⟩ | ⟨hlen, hcv⟩
      · left; exact ⟨by simp; omega, hex⟩
      · right; refine ⟨by simp at hlen ⊢; omega, ?_⟩
        simpa [List.take, List.append_assoc] using hcv
    | zero =>
      cases fn with
      | zero =>
        exfalso
        simp only [WTele, FTele] at hw
        subst hw
        cases h with
        | cons hc _ _ =>
          have this' : Le (Book.qer β) _ _ := Pol.dead_trans hβ hle hc
          rw [Ctx.δ_apps, Ctx.δ_closed Γ 0 (.Adt a r) (by trivial), Ctx.δ_all,
            Term.qer_apps] at this'
          simp only [Term.qer] at this'
          exact this'.adt_all
      | succ fk =>
        obtain ⟨qf, F, Bw, hT, _, hw'⟩ := FTele.field (x := x) hw
        subst hT
        obtain ⟨πx, ux, πs', us', B1, _, _, _, hB, hr⟩ := Args.stepD hβ hle h
        rcases ih (pn := 0) hw' hr hB with ⟨hlt, hex⟩ | ⟨hlen, hcv⟩
        · left; exact ⟨by simp at hlt ⊢; omega, hex⟩
        · right; exact ⟨by simp at hlen ⊢; omega, by simpa using hcv⟩

theorem Args.rebuildD (hβ : Book.Closed β) :
    ∀ {as : List Term} {pn fn : Nat} {ps : List Term} {Tw T0 T1 : Term} {πs : Uses}
      {us : List Term},
    WTele a r ps pn fn Tw → Args β (Pol.dead β) L .None Γ T0 as T1 πs us →
    (Pol.dead β).conv (Ctx.δ Γ 0 (Term.retip r1 pn (pn + fn) Tw)) (Ctx.δ Γ 0 T0) →
    as.length = pn + fn →
    ∀ r2, Args β (Pol.dead β) L .None Γ (Term.retip r2 pn (pn + fn) Tw) as
      (Term.apps (.Adt a r2) (ps ++ as.take pn)) πs us := by
  intro as
  induction as with
  | nil =>
    intro pn fn ps Tw T0 T1 πs us hw h hle hlen r2
    cases h
    cases pn with
    | zero =>
      cases fn with
      | zero =>
        simp only [WTele, FTele] at hw; subst hw
        rw [Term.retip_adt_apps]; simpa using Args.nil
      | succ fk => rw [List.length_nil] at hlen; omega
    | succ pk => rw [List.length_nil] at hlen; omega
  | cons x as ih =>
    intro pn fn ps Tw T0 T1 πs us hw h hle hlen r2
    cases pn with
    | succ pk =>
      obtain ⟨qw, K, Bw, hT, hwB, hw'⟩ := WTele.param (x := x) hw
      subst hT
      rw [show pk + 1 + fn = pk + fn + 1 by omega] at hle ⊢
      obtain ⟨πx, ux, πs', us', B1, rfl, rfl, hx, hB, hr⟩ :=
        Args.stepD hβ (qw := .None) (K := K) (Bw := Term.retip r1 pk (pk + fn) Bw) hle h
      rw [WTele.retip_subst hwB r1 0 x] at hB
      have := ih hw' hr hB (by simp at hlen; omega) r2
      show Args β (Pol.dead β) L .None Γ (.All .None K (Term.retip r2 pk (pk + fn) Bw))
        (x :: as) _ _ _
      refine .cons (Pol.dead_refl _ _) (by rw [Quant.dem_none]; exact hx) ?_
      rw [WTele.retip_subst hwB r2 0 x]
      simpa [List.take, List.append_assoc] using this
    | zero =>
      cases fn with
      | zero => rw [List.length_cons] at hlen; omega
      | succ fk =>
        obtain ⟨qf, F, Bw, hT, hFB, hw'⟩ := FTele.field (x := x) hw
        subst hT
        rw [Nat.zero_add] at hle ⊢
        obtain ⟨πx, ux, πs', us', B1, rfl, rfl, hx, hB, hr⟩ :=
          Args.stepD hβ (qw := qf) (K := F) (Bw := Term.retip r1 0 fk Bw) hle h
        rw [FTele.retip_subst hFB r1 0 x] at hB
        have := ih (pn := 0) hw' hr (by simpa using hB) (by simp at hlen; omega) r2
        rw [Nat.zero_add] at this
        show Args β (Pol.dead β) L .None Γ (.All qf F (Term.retip r2 0 fk Bw)) (x :: as) _ _ _
        refine .cons (Pol.dead_refl _ _) (by rw [Quant.dem_none]; exact hx) ?_
        rw [FTele.retip_subst hFB r2 0 x]
        simpa using this

theorem Check.matcD (hok : Book.Ok β) {sp : List Term}
    (hA : Book.adt β a = some A) (hC : AdtD.ctr A c = some C)
    (hps : ps.length = A.pn) (hxs : xs.length = C.fn)
    (h : Check β (Pol.dead β) L sp .None Γ
      (.App (.Mat a c hh mm) (Term.apps (.Ctr a c) (ps ++ xs))) T π u) :
    Check β (Pol.dead β) (LHS.void β) [] .None Γ (Term.apps hh xs) T Uses.zero .Qnt := by
  have hβ := hok.closed
  have hΦ := Pol.dead_pre hβ
  rcases h.void.app_inv hΦ with
    ⟨q1, A1, B1, πf, uf, πx, ux, hf, hx, hle, _, _⟩ | ⟨g, _, hg, _⟩
  · obtain ⟨A', C', r, ps', q', telF, B, G, πh, uh, πm, um, hA', hC', hr, hlen, hlive, hI, hg,
      hh0, hm0, hleM, _, _⟩ := hf.mat_inv hΦ
    rw [hA] at hA'; cases hA'; rw [hC] at hC'; cases hC'
    obtain ⟨hA1, hB1⟩ := Pol.dead_all_inv hβ hleM
    rw [Quant.dem_none] at hx
    obtain ⟨T0, π0, u0, T1, πs, us, hhead, hargs, hleT1, _, _⟩ :=
      hx.apps_inv hΦ (ps ++ xs) (.Ctr a c) (fun _ e => Term.noConfusion e)
    obtain ⟨A'', C'', r0, hA'', hC'', hr0, hleR, _, _⟩ := hhead.ctr_inv hΦ
    rw [hA] at hA''; cases hA''; rw [hC] at hC''; cases hC''
    obtain ⟨Tm, πp, up, πq, uq, hargsP, hargsF, _, _⟩ := hargs.split
    obtain ⟨TS0, hI0, hF0, hleTS⟩ :=
      Args.paramsD hβ (r' := r0) (hok.shape hA hC) hargsP hleR hps
    obtain ⟨hargsF', htip⟩ := Args.fteleD hβ hF0 hargsF hleTS hxs
    have hadt : Le (Book.qer β) _ _ := Pol.dead_trans hβ htip (Pol.dead_trans hβ hleT1 hA1)
    rw [Ctx.δ_apps, Ctx.δ_apps, Ctx.δ_closed Γ 0 (.Adt a r0) trivial,
      Ctx.δ_closed Γ 0 (.Adt a r) trivial, Term.qer_apps, Term.qer_apps] at hadt
    simp only [List.nil_append, Term.qer] at hadt
    obtain ⟨_, _, hconvs⟩ := Le.adt_inv hβ.qer hadt .refl .refl
    simp only [List.nil_append] at hargsF'
    have hI0' := (hI0.δ Γ 0).qer
    have hI' := (hI.δ Γ 0).qer
    have hconvT : (Pol.dead β).conv (Ctx.δ Γ 0 telF) (Ctx.δ Γ 0 TS0) :=
      Le.conv (Insts.conv hβ.qer hI0' hI' (Conv.refl _) hconvs).symm
    have hG := MatGoal.applyD hβ C.fn hg hargsF' hconvT hxs
    have hres := Check.apps (hh0.void_sp (xs ++ [])) hG
    have hw : Conv (Book.qer β) (Term.qer (Ctx.δ Γ 0 (Term.apps (.Ctr a c) (ps' ++ xs))))
        (Term.qer (Ctx.δ Γ 0 (Term.apps (.Ctr a c) (ps ++ xs)))) := by
      rw [Ctx.δ_apps, Ctx.δ_apps, Term.qer_apps, Term.qer_apps, List.map_append, List.map_append,
        List.map_append, List.map_append]
      exact Conv.apps (Conv.refl _) (Convs.append hconvs.symm (Convs.refl _))
    refine (hres.cnv (Pol.dead_trans hβ ?_ hle)).dead
    rw [← Term.apps_append, Ctx.δ_subst Γ 0 0 _ _ (Nat.le_refl 0),
      Ctx.δ_subst Γ 0 0 _ _ (Nat.le_refl 0)]
    exact Pol.dead_substR hβ hB1 hw 0
  · exact Term.noConfusion hg

theorem Check.matmD (hok : Book.Ok β) {sp : List Term} (hne : (a', c') ≠ (a, c))
    (h : Check β (Pol.dead β) L sp .None Γ
      (.App (.Mat a c hh mm) (Term.apps (.Ctr a' c') as)) T π u) :
    Check β (Pol.dead β) (LHS.void β) [] .None Γ (.App mm (Term.apps (.Ctr a' c') as)) T
      Uses.zero .Qnt := by
  have hβ := hok.closed
  have hΦ := Pol.dead_pre hβ
  rcases h.void.app_inv hΦ with
    ⟨q1, A1, B1, πf, uf, πx, ux, hf, hx, hle, _, _⟩ | ⟨g, _, hg, _⟩
  · obtain ⟨A0, C0, r, ps, q', telF, B, G, πh, uh, πm, um, hA0, hC0, hr, hlen, hlive, hI, hg,
      hh0, hm0, hleM, _, _⟩ := hf.mat_inv hΦ
    obtain ⟨hA1, hB1⟩ := Pol.dead_all_inv hβ hleM
    rw [Quant.dem_none] at hx
    obtain ⟨T0, π0, u0, T1, πs, us, hhead, hargs, hleT1, _, _⟩ :=
      hx.apps_inv hΦ as (.Ctr a' c') (fun _ e => Term.noConfusion e)
    obtain ⟨A2, C2, r0, hA2, hC2, hr0, hleR, _, _⟩ := hhead.ctr_inv hΦ
    have hshape := hok.shape hA2 hC2
    rcases Args.wteleD hβ (WTele.retip r0 hshape) hargs hleR with
      ⟨_, qA, X, Y, hall⟩ | ⟨hlenAs, hadt⟩
    · have this' : Le (Book.qer β) _ _ := Pol.dead_trans hβ hall (Pol.dead_trans hβ hleT1 hA1)
      rw [Ctx.δ_all, Ctx.δ_apps, Ctx.δ_closed Γ 0 (.Adt a r) trivial, Term.qer_apps] at this'
      simp only [Term.qer] at this'
      exact absurd this' Le.all_adt
    · have hadt' : Le (Book.qer β) _ _ := Pol.dead_trans hβ hadt (Pol.dead_trans hβ hleT1 hA1)
      rw [Ctx.δ_apps, Ctx.δ_apps, Ctx.δ_closed Γ 0 (.Adt a' r0) trivial,
        Ctx.δ_closed Γ 0 (.Adt a r) trivial, Term.qer_apps, Term.qer_apps] at hadt'
      simp only [List.nil_append, Term.qer] at hadt'
      obtain ⟨rfl, hsub, hconvs⟩ := Le.adt_inv hβ.qer hadt' .refl .refl
      have hcc : c' ≠ c := fun e => hne (by rw [e])
      have hargs' := Args.rebuildD hβ hshape hargs hleR hlenAs (c :: r0)
      simp only [List.nil_append] at hargs'
      have hhead' := Check.ctr (β := β) (Φ := Pol.dead β) (L := LHS.void β) (sp := as ++ [])
        (q := .None) (Γ := Γ) (r := c :: r0) hA2 hC2 (fun hm => by
          rcases List.mem_cons.mp hm with e | e
          · exact hcc e
          · exact hr0 e)
      have hcv : (Pol.dead β).conv (Ctx.δ Γ 0 (Term.apps (.Adt a' (c :: r0)) (as.take A2.pn)))
          (Ctx.δ Γ 0 (Term.apps (.Adt a' (c :: r)) ps)) := by
        show Le _ _ _
        rw [Ctx.δ_apps, Ctx.δ_apps, Ctx.δ_closed Γ 0 (.Adt a' (c :: r0)) trivial,
          Ctx.δ_closed Γ 0 (.Adt a' (c :: r)) trivial, Term.qer_apps, Term.qer_apps]
        simp only [Term.qer]
        exact Le.adt (fun x hx => by
            rcases List.mem_cons.mp hx with e | e
            · exact e ▸ List.mem_cons_self
            · exact List.mem_cons_of_mem _ (hsub x e))
          hconvs.length hconvs.get
      have hscr := (Check.apps hhead' hargs').cnv hcv
      have hres := Check.app (hm0.void_sp [Term.apps (.Ctr a' c') as])
        (by rw [Quant.dem_none]; exact hscr)
      refine (hres.cnv (Pol.dead_trans hβ ?_ hle)).dead
      rw [Ctx.δ_subst Γ 0 0 _ _ (Nat.le_refl 0), Ctx.δ_subst Γ 0 0 _ _ (Nat.le_refl 0)]
      exact (Pol.dead_weak hβ).subst 0 _ _ _ hB1
  · exact Term.noConfusion hg

-- the type of an application moves with its argument; a binary application
-- moves with its three parts
theorem Pol.dead_arg (hβ : Book.Closed β) (hx : Conv β x x') (B : Term) :
    (Pol.dead β).conv (Ctx.δ Γ 0 (Term.subst 0 x' B)) (Ctx.δ Γ 0 (Term.subst 0 x B)) :=
  Pol.dead_conv hβ (Ctx.δ_conv hβ Γ 0 (Conv.substR hβ hx.symm 0 B))

theorem Pol.dead_app2 (hβ : Book.Closed β) (hP : Conv β P P') (hx : Conv β x x')
    (hy : Conv β y y') :
    (Pol.dead β).conv (Ctx.δ Γ 0 (.App (.App P x) y)) (Ctx.δ Γ 0 (.App (.App P' x') y')) :=
  Pol.dead_conv hβ (Ctx.δ_conv hβ Γ 0 (Conv.app (Conv.app hP hx) hy))

-- the eta body instantiated: the argument lands where the bound variable was
theorem Term.subst_eta (hocc : Term.occ 0 G = 0) (a : Term) :
    Term.subst 0 a (.App G (.Var 0)) = .App (Term.subst 0 .Qnt G) a := by
  simp only [Term.subst, if_true]
  rw [Term.occ_zero_subst_irrel G 0 a .Qnt hocc]

-- a derivation pinned at the void equation, no spine, demand None, normalized
theorem Check.at0 (h : Check β Φ (LHS.void β) [] .None Γ t T π u) :
    Check β Φ (LHS.void β) [] .None Γ t T Uses.zero .Qnt := h.dead

inductive StepB (β : Book) : Term → Term → Prop
  | beta  : StepB β (.App (.Lam f) a) (Term.subst 0 a f)
  | let_  : StepB β (.Let q v b) (Term.subst 0 v b)
  | dref  : Book.defn β k = some d →
            (Term.spine s).1 = .Ref k →
            StepB β s (Term.apps d.body (Term.spine s).2)
  | aref  : Book.adt β k = some A → A.pn = 0 → StepB β (.Ref k) (.Adt k [])
  | matc  : Book.adt β a = some A → AdtD.ctr A c = some C →
            ps.length = A.pn → xs.length = C.fn →
            StepB β (.App (.Mat a c h m) (Term.apps (.Ctr a c) (ps ++ xs)))
                    (Term.apps h xs)
  | matm  : (a', c') ≠ (a, c) →
            StepB β (.App (.Mat a c h m) (Term.apps (.Ctr a' c') as))
                    (.App m (Term.apps (.Ctr a' c') as))
  | rwt   : StepB β (.Rwt .Rfl P f) f
  | minLM : StepB β (.Min (.Qua .Many) b) b
  | minLN : StepB β (.Min (.Qua .None) b) (.Qua .None)
  | minRM : StepB β (.Min a (.Qua .Many)) a
  | minRN : StepB β (.Min a (.Qua .None)) (.Qua .None)
  | minLL : StepB β (.Min (.Qua .Lone) (.Qua .Lone)) (.Qua .Lone)
  | typ_g : StepB β g g' → StepB β (.Typ g) (.Typ g')
  | min_a : StepB β a a' → StepB β (.Min a b) (.Min a' b)
  | min_b : StepB β b b' → StepB β (.Min a b) (.Min a b')
  | all_a : StepB β A A' → StepB β (.All q A B) (.All q A' B)
  | all_b : StepB β B B' → StepB β (.All q A B) (.All q A B')
  | lam_f : StepB β f f' → StepB β (.Lam f) (.Lam f')
  | app_f : StepB β f f' → StepB β (.App f a) (.App f' a)
  | app_a : StepB β a a' → StepB β (.App f a) (.App f a')
  | mat_h : StepB β h h' → StepB β (.Mat a c h m) (.Mat a c h' m)
  | mat_m : StepB β m m' → StepB β (.Mat a c h m) (.Mat a c h m')
  | eql_a : StepB β x x' → StepB β (.Eql x y T) (.Eql x' y T)
  | eql_b : StepB β y y' → StepB β (.Eql x y T) (.Eql x y' T)
  | eql_t : StepB β T T' → StepB β (.Eql x y T) (.Eql x y T')
  | rwt_e : StepB β e e' → StepB β (.Rwt e P f) (.Rwt e' P f)
  | rwt_p : StepB β P P' → StepB β (.Rwt e P f) (.Rwt e P' f)
  | rwt_f : StepB β f f' → StepB β (.Rwt e P f) (.Rwt e P f')
  | let_v : StepB β v v' → StepB β (.Let q v b) (.Let q v' b)
  | let_b : StepB β b b' → StepB β (.Let q v b) (.Let q v b')

-- the dref rule on an explicit spine
theorem StepB.dref_apps (hk : Book.defn β k = some d) (as : List Term) :
    StepB β (Term.apps (.Ref k) as) (Term.apps d.body as) := by
  have h := StepB.dref (s := Term.apps (.Ref k) as) hk (by rw [Term.spine_apps (by trivial)])
  rwa [Term.spine_apps (by trivial)] at h

-- a relation on terms, pointwise on lists
inductive Pw (R : Term → Term → Prop) : List Term → List Term → Prop
  | nil  : Pw R [] []
  | cons : R x y → Pw R xs ys → Pw R (x :: xs) (y :: ys)

theorem Pw.length (h : Pw R xs ys) : xs.length = ys.length := by
  induction h with
  | nil => rfl
  | cons _ _ ih => simp [ih]

theorem Pw.mono (hRS : ∀ {a b}, R a b → S a b) (h : Pw R xs ys) : Pw S xs ys := by
  induction h with
  | nil => exact .nil
  | cons hx _ ih => exact .cons (hRS hx) ih

theorem Pw.trans (hR : ∀ {a b c}, R a b → R b c → R a c) (h1 : Pw R xs ys) (h2 : Pw R ys zs) :
    Pw R xs zs := by
  induction h1 generalizing zs with
  | nil => exact h2
  | cons hx _ ih => cases h2 with | cons hy hrest => exact .cons (hR hx hy) (ih hrest)

theorem Pw.append (h1 : Pw R xs ys) (h2 : Pw R as bs) : Pw R (xs ++ as) (ys ++ bs) := by
  induction h1 with
  | nil => exact h2
  | cons hx _ ih => exact .cons hx ih

theorem Pw.append_inv : ∀ {xs ys zs : List Term}, Pw R (xs ++ ys) zs →
    ∃ xs' ys', zs = xs' ++ ys' ∧ Pw R xs xs' ∧ Pw R ys ys' := by
  intro xs
  induction xs with
  | nil => intro ys zs h; exact ⟨[], zs, _root_.rfl, .nil, h⟩
  | cons x xs ih =>
    intro ys zs h
    cases h with
    | cons hx hrest =>
      obtain ⟨xs', ys', rfl, h1, h2⟩ := ih hrest
      exact ⟨_ :: xs', ys', _root_.rfl, .cons hx h1, h2⟩

theorem Pw.drop (h : Pw R xs ys) : ∀ n, Pw R (xs.drop n) (ys.drop n) := by
  induction h with
  | nil => intro n; simp; exact .nil
  | cons hx hrest ih =>
    intro n; cases n with | zero => exact .cons hx hrest | succ n => exact ih n

theorem Pw.map (f : Term → Term) (hf : ∀ {a b}, R a b → R (f a) (f b)) (h : Pw R xs ys) :
    Pw R (xs.map f) (ys.map f) := by
  induction h with
  | nil => exact .nil
  | cons hx _ ih => exact .cons (hf hx) ih

theorem Pw.of_getD : ∀ {xs ys : List Term}, xs.length = ys.length →
    (∀ i, i < xs.length → R (xs.getD i .Qnt) (ys.getD i .Qnt)) → Pw R xs ys := by
  intro xs
  induction xs with
  | nil => intro ys hl _; cases ys with | nil => exact .nil | cons => simp at hl
  | cons x xs ih =>
    intro ys hl hr
    cases ys with
    | nil => simp at hl
    | cons y ys =>
      exact .cons (hr 0 (by simp))
        (ih (by simp at hl; omega) fun i hi => hr (i + 1) (by simp; omega))

theorem Pw.getD (h : Pw R xs ys) :
    ∀ i, i < xs.length → R (xs.getD i .Qnt) (ys.getD i .Qnt) := by
  induction h with
  | nil => intro i hi; simp at hi
  | cons hx _ ih =>
    intro i hi
    cases i with
    | zero => simpa using hx
    | succ i => simpa using ih i (by simp at hi; omega)

theorem Pw.snoc_inv (h : Pw R (as ++ [x]) cs) :
    ∃ bs y, cs = bs ++ [y] ∧ Pw R as bs ∧ R x y := by
  obtain ⟨bs, ys, rfl, h1, h2⟩ := Pw.append_inv h
  cases h2 with | cons hy hn => cases hn; exact ⟨bs, _, _root_.rfl, h1, hy⟩

-- the reflexive-transitive closure of a relation on terms: RedB is the
-- eta-free strong run, Etas (§K4) the eta chain; RedsB and Etass are their
-- pointwise forms
inductive Star (R : Term → Term → Prop) : Term → Term → Prop
  | refl : Star R t t
  | step : R a b → Star R b c → Star R a c

abbrev RedB (β : Book) := Star (StepB β)
abbrev RedsB (β : Book) := Pw (RedB β)

theorem Pw.star_refl : ∀ (xs : List Term), Pw (Star R) xs xs
  | [] => .nil
  | _ :: xs => .cons .refl (Pw.star_refl xs)

theorem Star.one (h : R a b) : Star R a b := .step h .refl

theorem Star.trans (h1 : Star R a b) (h2 : Star R b c) : Star R a c := by
  induction h1 with
  | refl => exact h2
  | step s _ ih => exact .step s (ih h2)

theorem Star.congr {F : Term → Term} (hF : ∀ {a b}, R a b → R (F a) (F b)) (h : Star R a b) :
    Star R (F a) (F b) := by
  induction h with
  | refl => exact .refl
  | step s _ ih => exact .step (hF s) ih

theorem Star.red (h : Star R a b) (hR : ∀ {a b}, R a b → Step β .strong a b) :
    Red β .strong a b := by
  induction h with
  | refl => exact .refl
  | step s _ ih => exact .step (hR s) ih

theorem Star.lams (hl : ∀ {a b}, Star R a b → Star R (.Lam a) (.Lam b)) (n : Nat)
    (h : Star R f f') : Star R (Term.lams n f) (Term.lams n f') := by
  induction n with
  | zero => exact h
  | succ n ih => exact hl ih

theorem Star.substR
    (hR : ∀ (t : Term) (d : Nat) {w w'}, R w w' → Star R (Term.subst d w t) (Term.subst d w' t))
    (h : Star R w w') (d : Nat) (t : Term) : Star R (Term.subst d w t) (Term.subst d w' t) := by
  induction h with
  | refl => exact .refl
  | step s _ ih => exact (hR t d s).trans ih

theorem StepB.step (h : StepB β a b) : Step β .strong a b := by
  induction h with
  | beta => exact .beta
  | let_ => exact .let_
  | dref hk hs => exact .drefS _root_.rfl hk hs
  | aref hk h0 => exact .aref hk h0
  | matc h1 h2 h3 h4 => exact .matc h1 h2 h3 h4
  | matm hne => exact .matm hne
  | rwt => exact .rwt
  | minLM => exact .minLM
  | minLN => exact .minLN
  | minRM => exact .minRM
  | minRN => exact .minRN
  | minLL => exact .minLL
  | typ_g _ ih => exact .typ_g _root_.rfl ih
  | min_a _ ih => exact .min_a ih
  | min_b _ ih => exact .min_b ih
  | all_a _ ih => exact .all_a _root_.rfl ih
  | all_b _ ih => exact .all_b _root_.rfl ih
  | lam_f _ ih => exact .lam_f _root_.rfl ih
  | app_f _ ih => exact .app_f ih
  | app_a _ ih => exact .app_a ih
  | mat_h _ ih => exact .mat_h ih
  | mat_m _ ih => exact .mat_m ih
  | eql_a _ ih => exact .eql_a ih
  | eql_b _ ih => exact .eql_b ih
  | eql_t _ ih => exact .eql_t ih
  | rwt_e _ ih => exact .rwt_e ih
  | rwt_p _ ih => exact .rwt_p ih
  | rwt_f _ ih => exact .rwt_f ih
  | let_v _ ih => exact .let_v ih
  | let_b _ ih => exact .let_b _root_.rfl ih

inductive ParB (β : Book) : Term → Term → Prop
  | var  : ParB β (.Var i) (.Var i)
  | ref  : ParB β (.Ref k) (.Ref k)
  | typ  : ParB β g g' → ParB β (.Typ g) (.Typ g')
  | qnt  : ParB β .Qnt .Qnt
  | qua  : ParB β (.Qua q) (.Qua q)
  | min  : ParB β a a' → ParB β b b' → ParB β (.Min a b) (.Min a' b')
  | adt  : ParB β (.Adt a r) (.Adt a r)
  | ctr  : ParB β (.Ctr a c) (.Ctr a c)
  | efq  : ParB β .Efq .Efq
  | rfl  : ParB β .Rfl .Rfl
  | all  : ParB β A A' → ParB β B B' → ParB β (.All q A B) (.All q A' B')
  | lam  : ParB β f f' → ParB β (.Lam f) (.Lam f')
  | app  : ParB β f f' → ParB β a a' → ParB β (.App f a) (.App f' a')
  | mat  : ParB β h h' → ParB β m m' → ParB β (.Mat a c h m) (.Mat a c h' m')
  | eql  : ParB β x x' → ParB β y y' → ParB β T T' →
           ParB β (.Eql x y T) (.Eql x' y' T')
  | rwt  : ParB β e e' → ParB β P P' → ParB β f f' →
           ParB β (.Rwt e P f) (.Rwt e' P' f')
  | let_ : ParB β v v' → ParB β b b' → ParB β (.Let q v b) (.Let q v' b')
  | beta : ParB β f f' → ParB β a a' →
           ParB β (.App (.Lam f) a) (Term.subst 0 a' f')
  | letr : ParB β v v' → ParB β b b' →
           ParB β (.Let q v b) (Term.subst 0 v' b')
  | dref : Book.defn β k = some d →
           (Term.spine s).1 = .Ref k →
           (Term.spine s).2.length = args'.length →
           (∀ i, i < (Term.spine s).2.length →
             ParB β ((Term.spine s).2.getD i .Qnt) (args'.getD i .Qnt)) →
           ParB β s (Term.apps d.body args')
  | aref : Book.adt β k = some A → A.pn = 0 → ParB β (.Ref k) (.Adt k [])
  | matc : Book.adt β a = some A → AdtD.ctr A c = some C →
           (Term.spine s).1 = .Ctr a c →
           (Term.spine s).2.length = A.pn + C.fn →
           ParB β s s' → ParB β h h' →
           ParB β (.App (.Mat a c h m) s)
                 (Term.apps h' ((Term.spine s').2.drop A.pn))
  | matm : (Term.spine s).1 = .Ctr a' c' → (a', c') ≠ (a, c) →
           ParB β s s' → ParB β m m' →
           ParB β (.App (.Mat a c h m) s) (.App m' s')
  | rwtr : ParB β f f' → ParB β (.Rwt .Rfl P f) f'
  | minLM : ParB β b b' → ParB β (.Min (.Qua .Many) b) b'
  | minLN : ParB β (.Min (.Qua .None) b) (.Qua .None)
  | minRM : ParB β a a' → ParB β (.Min a (.Qua .Many)) a'
  | minRN : ParB β (.Min a (.Qua .None)) (.Qua .None)
  | minLL : ParB β (.Min (.Qua .Lone) (.Qua .Lone)) (.Qua .Lone)

abbrev ParsB (β : Book) := Pw (ParB β)

theorem ParB.refl : ∀ (t : Term), ParB β t t := by
  intro t; induction t <;> constructor <;> assumption

theorem ParB.apps (hh : ParB β h h') (has : ParsB β as as') :
    ParB β (Term.apps h as) (Term.apps h' as') := by
  induction has generalizing h h' with
  | nil => exact hh
  | cons hp _ ih => exact ih (.app hh hp)

theorem ParB.par (h : ParB β a b) : Par β a b := by
  induction h <;> first
    | exact .matc ‹_› ‹_› ‹_› ‹_› ‹_› ‹_›
    | exact .matm ‹_› ‹_› ‹_› ‹_›
    | (constructor <;> assumption)

theorem StepB.par (s : StepB β a b) : ParB β a b := by
  induction s with
  | beta => exact .beta (ParB.refl _) (ParB.refl _)
  | let_ => exact .letr (ParB.refl _) (ParB.refl _)
  | dref hk hsp => exact .dref hk hsp _root_.rfl (fun i _ => ParB.refl _)
  | aref hk h0 => exact .aref hk h0
  | matc h1 h2 h3 h4 =>
    rename_i a A c C h m ps xs
    have hd : ((Term.spine (Term.apps (.Ctr a c) (ps ++ xs))).2.drop A.pn) = xs := by
      rw [Term.spine_apps (by trivial)]
      show (ps ++ xs).drop A.pn = xs
      rw [← h3]
      exact List.drop_left
    have hp := ParB.matc (m := m) h1 h2
      (by rw [Term.spine_apps (by trivial)])
      (by rw [Term.spine_apps (by trivial)]; simp [h3, h4])
      (ParB.refl (Term.apps (.Ctr a c) (ps ++ xs))) (ParB.refl h)
    rwa [hd] at hp
  | matm hne =>
    rename_i a' c' a c h m as
    exact ParB.matm (s := Term.apps (.Ctr a' c') as)
      (by rw [Term.spine_apps (by trivial)]) hne (ParB.refl _) (ParB.refl _)
  | rwt => exact .rwtr (ParB.refl _)
  | minLM => exact .minLM (ParB.refl _)
  | minLN => exact .minLN
  | minRM => exact .minRM (ParB.refl _)
  | minRN => exact .minRN
  | minLL => exact .minLL
  | typ_g _ ih => exact .typ ih
  | min_a _ ih => exact .min ih (ParB.refl _)
  | min_b _ ih => exact .min (ParB.refl _) ih
  | all_a _ ih => exact .all ih (ParB.refl _)
  | all_b _ ih => exact .all (ParB.refl _) ih
  | lam_f _ ih => exact .lam ih
  | app_f _ ih => exact .app ih (ParB.refl _)
  | app_a _ ih => exact .app (ParB.refl _) ih
  | mat_h _ ih => exact .mat ih (ParB.refl _)
  | mat_m _ ih => exact .mat (ParB.refl _) ih
  | eql_a _ ih => exact .eql ih (ParB.refl _) (ParB.refl _)
  | eql_b _ ih => exact .eql (ParB.refl _) ih (ParB.refl _)
  | eql_t _ ih => exact .eql (ParB.refl _) (ParB.refl _) ih
  | rwt_e _ ih => exact .rwt ih (ParB.refl _) (ParB.refl _)
  | rwt_p _ ih => exact .rwt (ParB.refl _) ih (ParB.refl _)
  | rwt_f _ ih => exact .rwt (ParB.refl _) (ParB.refl _) ih
  | let_v _ ih => exact .let_ ih (ParB.refl _)
  | let_b _ ih => exact .let_ (ParB.refl _) ih

-- stability: an eta-free parallel reduct of a Ctr-headed spine is a
-- Ctr-headed spine with pointwise-parallel arguments
theorem ParB.ctr_spine_inv (hp : ParB β s t) :
    ∀ {a c : Nat} {as : List Term}, s = Term.apps (.Ctr a c) as →
    ∃ as', t = Term.apps (.Ctr a c) as' ∧ ParsB β as as' := by
  induction hp <;> intro a c as heq
  all_goals
    try exact absurd heq.symm (Term.apps_ne (by trivial) (by trivial) (fun h => Term.noConfusion h))
  all_goals try (obtain ⟨ys, _, hfy⟩ := Term.app_eq_apps (by trivial) heq
                 exact absurd hfy.symm
                   (Term.apps_ne (by trivial) (by trivial) (fun h => Term.noConfusion h)))
  case ctr =>
    obtain ⟨h1, h2⟩ := Term.apps_head_inv (h := Term.Ctr _ _) (by trivial)
      (by trivial) (xs := []) heq
    cases h1
    cases h2
    exact ⟨[], _root_.rfl, .nil⟩
  case app _ _ _ _ hf ha ihf _ =>
    obtain ⟨ys, hys, hfy⟩ := Term.app_eq_apps (by trivial) heq
    obtain ⟨ys', hy1, hy2⟩ := ihf hfy
    subst hys hy1
    exact ⟨ys' ++ [_], (Term.apps_snoc _ _ _).symm,
      Pw.append hy2 (.cons ha .nil)⟩
  case dref _ _ _ _ _ hsp _ _ _ =>
    rw [heq, Term.spine_apps (by trivial)] at hsp
    exact Term.noConfusion hsp

-- a spine keeps its head when its arguments move pointwise
theorem Term.spine_stable {R : Term → Term → Prop} {P : List Term → List Term → Prop}
    (hinv : ∀ {s t : Term} {as : List Term}, R s t → s = Term.apps h as →
      ∃ as', t = Term.apps h as' ∧ P as as')
    (hh : h.IsHead) (hp : R s t) (hs : (Term.spine s).1 = h) :
    (Term.spine t).1 = h ∧ P (Term.spine s).2 (Term.spine t).2 := by
  obtain ⟨as', ht, hps⟩ := hinv hp (by rw [← hs]; exact (Term.apps_spine s).symm)
  rw [ht, Term.spine_apps hh]
  exact ⟨_root_.rfl, hps⟩

theorem ParB.spine_stable (hp : ParB β s t) (hh : (Term.spine s).1 = .Ctr a c) :
    (Term.spine t).1 = .Ctr a c ∧ ParsB β (Term.spine s).2 (Term.spine t).2 :=
  Term.spine_stable (fun hp e => hp.ctr_spine_inv e) trivial hp hh

-- ----------------------------------------------------------------------------
-- the RedB kit: chains, congruences, spines
-- ----------------------------------------------------------------------------

theorem RedB.typ (r : RedB β g g') : RedB β (.Typ g) (.Typ g') :=
  Star.congr (F := fun g => .Typ g) (fun s => .typ_g s) r

theorem RedB.min (ra : RedB β a a') (rb : RedB β b b') :
    RedB β (.Min a b) (.Min a' b') :=
  (Star.congr (F := fun a => .Min a b) (fun s => .min_a s) ra).trans
    (Star.congr (F := fun b => .Min a' b) (fun s => .min_b s) rb)

theorem RedB.all (rA : RedB β A A') (rB : RedB β B B') :
    RedB β (.All q A B) (.All q A' B') :=
  (Star.congr (F := fun A => .All q A B) (fun s => .all_a s) rA).trans
    (Star.congr (F := fun B => .All q A' B) (fun s => .all_b s) rB)

theorem RedB.lam (r : RedB β f f') : RedB β (.Lam f) (.Lam f') :=
  Star.congr (F := fun f => .Lam f) (fun s => .lam_f s) r

theorem RedB.app (rf : RedB β f f') (ra : RedB β a a') :
    RedB β (.App f a) (.App f' a') :=
  (Star.congr (F := fun f => .App f a) (fun s => .app_f s) rf).trans
    (Star.congr (F := fun a => .App f' a) (fun s => .app_a s) ra)

theorem RedB.mat (rh : RedB β h h') (rm : RedB β m m') :
    RedB β (.Mat a c h m) (.Mat a c h' m') :=
  (Star.congr (F := fun h => .Mat a c h m) (fun s => .mat_h s) rh).trans
    (Star.congr (F := fun m => .Mat a c h' m) (fun s => .mat_m s) rm)

theorem RedB.eql (rx : RedB β x x') (ry : RedB β y y') (rT : RedB β T T') :
    RedB β (.Eql x y T) (.Eql x' y' T') :=
  ((Star.congr (F := fun x => .Eql x y T) (fun s => .eql_a s) rx).trans
    (Star.congr (F := fun y => .Eql x' y T) (fun s => .eql_b s) ry)).trans
    (Star.congr (F := fun T => .Eql x' y' T) (fun s => .eql_t s) rT)

theorem RedB.rwt (re : RedB β e e') (rP : RedB β P P') (rf : RedB β f f') :
    RedB β (.Rwt e P f) (.Rwt e' P' f') :=
  ((Star.congr (F := fun e => .Rwt e P f) (fun s => .rwt_e s) re).trans
    (Star.congr (F := fun P => .Rwt e' P f) (fun s => .rwt_p s) rP)).trans
    (Star.congr (F := fun f => .Rwt e' P' f) (fun s => .rwt_f s) rf)

theorem RedB.let_ (rv : RedB β v v') (rb : RedB β b b') :
    RedB β (.Let q v b) (.Let q v' b') :=
  (Star.congr (F := fun v => .Let q v b) (fun s => .let_v s) rv).trans
    (Star.congr (F := fun b => .Let q v' b) (fun s => .let_b s) rb)

theorem RedB.apps (rh : RedB β h h') (has : RedsB β as as') :
    RedB β (Term.apps h as) (Term.apps h' as') := by
  induction has generalizing h h' with
  | nil => exact rh
  | cons hr _ ih => exact ih (RedB.app rh hr)

theorem ParB.red (hp : ParB β a b) : RedB β a b := by
  induction hp with
  | var => exact .refl
  | ref => exact .refl
  | typ _ ih => exact RedB.typ ih
  | qnt => exact .refl
  | qua => exact .refl
  | min _ _ iha ihb => exact RedB.min iha ihb
  | adt => exact .refl
  | ctr => exact .refl
  | efq => exact .refl
  | rfl => exact .refl
  | all _ _ ihA ihB => exact RedB.all ihA ihB
  | lam _ ihf => exact RedB.lam ihf
  | app _ _ ihf iha => exact RedB.app ihf iha
  | mat _ _ ihh ihm => exact RedB.mat ihh ihm
  | eql _ _ _ ihx ihy ihT => exact RedB.eql ihx ihy ihT
  | rwt _ _ _ ihe ihP ihf => exact RedB.rwt ihe ihP ihf
  | let_ _ _ ihv ihb => exact RedB.let_ ihv ihb
  | beta _ _ ihf iha => exact (RedB.app (RedB.lam ihf) iha).trans (Star.one .beta)
  | letr _ _ ihv ihb => exact (RedB.let_ ihv ihb).trans (Star.one .let_)
  | @dref k d s args' hk hsp hlen' hpar ih =>
    have hs : s = Term.apps (.Ref k) (Term.spine s).2 := by
      rw [← hsp]; exact (Term.apps_spine s).symm
    rw [hs]
    exact (RedB.apps .refl (Pw.of_getD hlen' ih)).trans (Star.one (StepB.dref_apps hk _))
  | aref hk h0 => exact Star.one (.aref hk h0)
  | matc h1 h2 h3 h4 hps hph ihs ihh =>
    rename_i a A c C s s' h h' m
    obtain ⟨hh', hargs⟩ := hps.spine_stable h3
    have hlen : (Term.spine s').2.length = A.pn + C.fn := by
      rw [← hargs.length]; exact h4
    obtain ⟨ts, hts⟩ : ∃ ts, (Term.spine s').2 = ts := ⟨_, _root_.rfl⟩
    rw [hts] at hlen
    rw [hts]
    have hs' : s' = Term.apps (.Ctr a c) (ts.take A.pn ++ ts.drop A.pn) := by
      rw [List.take_append_drop, ← hts, ← hh']
      exact (Term.apps_spine s').symm
    have hstep : StepB β (.App (.Mat a c h m) s') (Term.apps h (ts.drop A.pn)) := by
      rw [hs']
      exact StepB.matc h1 h2 (by simp [List.length_take]; omega)
        (by simp [List.length_drop]; omega)
    exact ((RedB.app .refl ihs).trans (Star.one hstep)).trans (RedB.apps ihh (Pw.star_refl _))
  | matm h1 hne hps hphm ihs ihm =>
    rename_i s a' c' a c s' m m' h
    obtain ⟨hh', _⟩ := hps.spine_stable h1
    have hs' : s' = Term.apps (.Ctr a' c') (Term.spine s').2 := by
      rw [← hh']; exact (Term.apps_spine s').symm
    have hstep : StepB β (.App (.Mat a c h m) s') (.App m s') := by
      rw [hs']
      exact StepB.matm hne
    exact ((RedB.app .refl ihs).trans (Star.one hstep)).trans (RedB.app ihm .refl)
  | rwtr _ ihf => exact (Star.one .rwt).trans ihf
  | minLM _ ih => exact (Star.one .minLM).trans ih
  | minLN => exact Star.one .minLN
  | minRM _ ih => exact (Star.one .minRM).trans ih
  | minRN => exact Star.one .minRN
  | minLL => exact Star.one .minLL

-- ----------------------------------------------------------------------------
-- StepB / RedB / ParB under shift and substitution
-- ----------------------------------------------------------------------------

theorem StepB.shift (hβ : Book.Closed β) (s : StepB β a b) :
    ∀ d, StepB β (Term.shift d a) (Term.shift d b) := by
  induction s with
  | beta => intro d; rw [Term.shift_subst0]; exact .beta
  | let_ => intro d; rw [Term.shift_subst0]; exact .let_
  | @dref k dd s hk hsp =>
    intro d
    have hc := (hβ.defn hk).2
    have hs := Term.spine_shift hsp (by trivial) (d := d) rfl
    rw [Term.shift_apps, Term.shift_closed dd.body 0 d hc (Nat.zero_le d)]
    have h := StepB.dref (s := Term.shift d s) hk (by rw [hs])
    simpa [hs] using h
  | aref hk h0 => intro d; exact .aref hk h0
  | matc h1 h2 h3 h4 =>
    intro d
    simp only [Term.shift, Term.shift_apps, List.map_append]
    exact .matc h1 h2 (by simp [h3]) (by simp [h4])
  | matm hne =>
    intro d
    simp only [Term.shift, Term.shift_apps]
    exact .matm hne
  | rwt => intro d; exact .rwt
  | minLM => intro d; exact .minLM
  | minLN => intro d; exact .minLN
  | minRM => intro d; exact .minRM
  | minRN => intro d; exact .minRN
  | minLL => intro d; exact .minLL
  | typ_g _ ih => intro d; exact .typ_g (ih d)
  | min_a _ ih => intro d; exact .min_a (ih d)
  | min_b _ ih => intro d; exact .min_b (ih d)
  | all_a _ ih => intro d; exact .all_a (ih d)
  | all_b _ ih => intro d; exact .all_b (ih (d + 1))
  | lam_f _ ih => intro d; exact .lam_f (ih (d + 1))
  | app_f _ ih => intro d; exact .app_f (ih d)
  | app_a _ ih => intro d; exact .app_a (ih d)
  | mat_h _ ih => intro d; exact .mat_h (ih d)
  | mat_m _ ih => intro d; exact .mat_m (ih d)
  | eql_a _ ih => intro d; exact .eql_a (ih d)
  | eql_b _ ih => intro d; exact .eql_b (ih d)
  | eql_t _ ih => intro d; exact .eql_t (ih d)
  | rwt_e _ ih => intro d; exact .rwt_e (ih d)
  | rwt_p _ ih => intro d; exact .rwt_p (ih d)
  | rwt_f _ ih => intro d; exact .rwt_f (ih d)
  | let_v _ ih => intro d; exact .let_v (ih d)
  | let_b _ ih => intro d; exact .let_b (ih (d + 1))

theorem StepB.subst (hβ : Book.Closed β) (s : StepB β a b) :
    ∀ d w, StepB β (Term.subst d w a) (Term.subst d w b) := by
  induction s with
  | beta => intro d w; rw [Term.subst_subst0]; exact .beta
  | let_ => intro d w; rw [Term.subst_subst0]; exact .let_
  | @dref k dd s hk hsp =>
    intro d w
    have hc := (hβ.defn hk).2
    have hs := Term.spine_subst hsp (by trivial) (d := d) (w := w) rfl
    rw [Term.subst_apps, Term.subst_closed dd.body 0 d w hc (Nat.zero_le d)]
    have h := StepB.dref (s := Term.subst d w s) hk (by rw [hs])
    simpa [hs] using h
  | aref hk h0 => intro d w; exact .aref hk h0
  | matc h1 h2 h3 h4 =>
    intro d w
    simp only [Term.subst, Term.subst_apps, List.map_append]
    exact .matc h1 h2 (by simp [h3]) (by simp [h4])
  | matm hne =>
    intro d w
    simp only [Term.subst, Term.subst_apps]
    exact .matm hne
  | rwt => intro d w; exact .rwt
  | minLM => intro d w; exact .minLM
  | minLN => intro d w; exact .minLN
  | minRM => intro d w; exact .minRM
  | minRN => intro d w; exact .minRN
  | minLL => intro d w; exact .minLL
  | typ_g _ ih => intro d w; exact .typ_g (ih d w)
  | min_a _ ih => intro d w; exact .min_a (ih d w)
  | min_b _ ih => intro d w; exact .min_b (ih d w)
  | all_a _ ih => intro d w; exact .all_a (ih d w)
  | all_b _ ih => intro d w; exact .all_b (ih (d + 1) _)
  | lam_f _ ih => intro d w; exact .lam_f (ih (d + 1) _)
  | app_f _ ih => intro d w; exact .app_f (ih d w)
  | app_a _ ih => intro d w; exact .app_a (ih d w)
  | mat_h _ ih => intro d w; exact .mat_h (ih d w)
  | mat_m _ ih => intro d w; exact .mat_m (ih d w)
  | eql_a _ ih => intro d w; exact .eql_a (ih d w)
  | eql_b _ ih => intro d w; exact .eql_b (ih d w)
  | eql_t _ ih => intro d w; exact .eql_t (ih d w)
  | rwt_e _ ih => intro d w; exact .rwt_e (ih d w)
  | rwt_p _ ih => intro d w; exact .rwt_p (ih d w)
  | rwt_f _ ih => intro d w; exact .rwt_f (ih d w)
  | let_v _ ih => intro d w; exact .let_v (ih d w)
  | let_b _ ih => intro d w; exact .let_b (ih (d + 1) _)

theorem StepB.substR (hβ : Book.Closed β) : ∀ (t : Term) (d : Nat) {w w' : Term},
    StepB β w w' → RedB β (Term.subst d w t) (Term.subst d w' t) := by
  intro t
  induction t with
  | Var i =>
    intro d w w' s
    simp only [Term.subst]
    split
    · exact Star.one s
    · split <;> exact .refl
  | Ref k => intro d w w' _; exact .refl
  | Typ g ih => intro d w w' s; exact RedB.typ (ih d s)
  | Qnt => intro d w w' _; exact .refl
  | Qua q => intro d w w' _; exact .refl
  | Min a b iha ihb => intro d w w' s; exact RedB.min (iha d s) (ihb d s)
  | All q A B ihA ihB =>
    intro d w w' s; exact RedB.all (ihA d s) (ihB (d + 1) (s.shift hβ 0))
  | Lam f ih => intro d w w' s; exact RedB.lam (ih (d + 1) (s.shift hβ 0))
  | App f a ihf iha => intro d w w' s; exact RedB.app (ihf d s) (iha d s)
  | Adt a r => intro d w w' _; exact .refl
  | Ctr a c => intro d w w' _; exact .refl
  | Mat a c h m ihh ihm => intro d w w' s; exact RedB.mat (ihh d s) (ihm d s)
  | Efq => intro d w w' _; exact .refl
  | Eql x y T ihx ihy ihT =>
    intro d w w' s; exact RedB.eql (ihx d s) (ihy d s) (ihT d s)
  | Rfl => intro d w w' _; exact .refl
  | Rwt e P f ihe ihP ihf =>
    intro d w w' s; exact RedB.rwt (ihe d s) (ihP d s) (ihf d s)
  | Let q v b ihv ihb =>
    intro d w w' s; exact RedB.let_ (ihv d s) (ihb (d + 1) (s.shift hβ 0))

theorem RedB.subst (hβ : Book.Closed β) (r : RedB β a b) (d : Nat) (w : Term) :
    RedB β (Term.subst d w a) (Term.subst d w b) := Star.congr (fun s => s.subst hβ d w) r

theorem RedB.substR (hβ : Book.Closed β) (r : RedB β w w') (d : Nat) (t : Term) :
    RedB β (Term.subst d w t) (Term.subst d w' t) := Star.substR (StepB.substR hβ) r d t

theorem ParB.shift (hβ : Book.Closed β) (hp : ParB β t t') :
    ∀ d, ParB β (t.shift d) (t'.shift d) := by
  induction hp with
  | var => intro d; simp only [Term.shift]; split <;> exact .var
  | ref => intro d; exact .ref
  | typ _ ih => intro d; exact .typ (ih d)
  | qnt => intro d; exact .qnt
  | qua => intro d; exact .qua
  | min _ _ iha ihb => intro d; exact .min (iha d) (ihb d)
  | adt => intro d; exact .adt
  | ctr => intro d; exact .ctr
  | efq => intro d; exact .efq
  | rfl => intro d; exact .rfl
  | all _ _ ihA ihB => intro d; exact .all (ihA d) (ihB (d + 1))
  | lam _ ihf => intro d; exact .lam (ihf (d + 1))
  | app _ _ ihf iha => intro d; exact .app (ihf d) (iha d)
  | mat _ _ ihh ihm => intro d; exact .mat (ihh d) (ihm d)
  | eql _ _ _ ihx ihy ihT => intro d; exact .eql (ihx d) (ihy d) (ihT d)
  | rwt _ _ _ ihe ihP ihf => intro d; exact .rwt (ihe d) (ihP d) (ihf d)
  | let_ _ _ ihv ihb => intro d; exact .let_ (ihv d) (ihb (d + 1))
  | beta _ _ ihf iha =>
    intro d
    rw [Term.shift_subst0]
    exact .beta (ihf (d + 1)) (iha d)
  | letr _ _ ihv ihb =>
    intro d
    rw [Term.shift_subst0]
    exact .letr (ihv d) (ihb (d + 1))
  | @dref k dd s args' hk hsp hlen' hpar ih =>
    intro d
    have hc := (hβ.defn hk).2
    have hs : s = Term.apps (.Ref k) (Term.spine s).2 := by
      rw [← hsp]
      exact (Term.apps_spine s).symm
    rw [hs, Term.shift_apps, Term.shift_apps]
    simp only [Term.shift]
    rw [Term.shift_closed dd.body 0 d hc (Nat.zero_le d)]
    refine ParB.dref hk
      (by rw [Term.spine_apps (by trivial)])
      (by
        rw [Term.spine_apps (by trivial)]
        simp only [List.length_map]
        exact hlen') ?_
    rw [Term.spine_apps (by trivial)]
    intro i hi
    simp only [List.length_map] at hi
    rw [map_getD (Term.shift d) .Qnt .Qnt _ i (by omega),
      map_getD (Term.shift d) .Qnt .Qnt args' i (by omega)]
    exact ih i (by omega) d
  | aref hk h0 => intro d; exact .aref hk h0
  | matc h1 h2 h3 h4 hps hph ihs ihh =>
    rename_i a A c C s s' h h' m
    intro d
    obtain ⟨hh', hargs⟩ := hps.spine_stable h3
    have e1 : (Term.spine (Term.shift d s)).1 = Term.Ctr a c := by
      rw [Term.spine_shift h3 (by trivial) _root_.rfl]
    have e2 : (Term.spine (Term.shift d s)).2.length = A.pn + C.fn := by
      rw [Term.spine_shift h3 (by trivial) _root_.rfl]; simpa using h4
    have e3 : Term.shift d (Term.apps h' ((Term.spine s').2.drop A.pn))
        = Term.apps (Term.shift d h')
            ((Term.spine (Term.shift d s')).2.drop A.pn) := by
      rw [Term.shift_apps, Term.spine_shift hh' (by trivial) _root_.rfl]
      show _ = Term.apps _ (((Term.spine s').2.map (Term.shift d)).drop A.pn)
      rw [List.map_drop]
    rw [show Term.shift d (.App (.Mat a c h m) s)
        = .App (.Mat a c (Term.shift d h) (Term.shift d m)) (Term.shift d s)
      from _root_.rfl, e3]
    exact ParB.matc h1 h2 e1 e2 (ihs d) (ihh d)
  | matm h1 hne hps hphm ihs ihm =>
    rename_i s a' c' a c s' m m' h
    intro d
    exact ParB.matm (by rw [Term.spine_shift h1 (by trivial) _root_.rfl]) hne
      (ihs d) (ihm d)
  | rwtr _ ihf => intro d; exact .rwtr (ihf d)
  | minLM _ ih => intro d; exact .minLM (ih d)
  | minLN => intro d; exact .minLN
  | minRM _ ih => intro d; exact .minRM (ih d)
  | minRN => intro d; exact .minRN
  | minLL => intro d; exact .minLL

theorem ParB.subst (hβ : Book.Closed β) (hp : ParB β t t') :
    ∀ d {w w'}, ParB β w w' → ParB β (Term.subst d w t) (Term.subst d w' t') := by
  induction hp with
  | var =>
    intro d w w' hw
    simp only [Term.subst]
    split
    · exact hw
    · split <;> exact .var
  | ref => intro d w w' _; exact .ref
  | typ _ ih => intro d w w' hw; exact .typ (ih d hw)
  | qnt => intro d w w' _; exact .qnt
  | qua => intro d w w' _; exact .qua
  | min _ _ iha ihb => intro d w w' hw; exact .min (iha d hw) (ihb d hw)
  | adt => intro d w w' _; exact .adt
  | ctr => intro d w w' _; exact .ctr
  | efq => intro d w w' _; exact .efq
  | rfl => intro d w w' _; exact .rfl
  | all _ _ ihA ihB =>
    intro d w w' hw
    exact .all (ihA d hw) (ihB (d + 1) (hw.shift hβ 0))
  | lam _ ihf =>
    intro d w w' hw
    exact .lam (ihf (d + 1) (hw.shift hβ 0))
  | app _ _ ihf iha =>
    intro d w w' hw
    exact .app (ihf d hw) (iha d hw)
  | mat _ _ ihh ihm =>
    intro d w w' hw
    exact .mat (ihh d hw) (ihm d hw)
  | eql _ _ _ ihx ihy ihT =>
    intro d w w' hw
    exact .eql (ihx d hw) (ihy d hw) (ihT d hw)
  | rwt _ _ _ ihe ihP ihf =>
    intro d w w' hw
    exact .rwt (ihe d hw) (ihP d hw) (ihf d hw)
  | let_ _ _ ihv ihb =>
    intro d w w' hw
    exact .let_ (ihv d hw) (ihb (d + 1) (hw.shift hβ 0))
  | beta _ _ ihf iha =>
    intro d w w' hw
    rw [Term.subst_subst0]
    exact .beta (ihf (d + 1) (hw.shift hβ 0)) (iha d hw)
  | letr _ _ ihv ihb =>
    intro d w w' hw
    rw [Term.subst_subst0]
    exact .letr (ihv d hw) (ihb (d + 1) (hw.shift hβ 0))
  | @dref k dd s args' hk hsp hlen' hpar ih =>
    intro d w w' hw
    have hc := (hβ.defn hk).2
    have hs : s = Term.apps (.Ref k) (Term.spine s).2 := by
      rw [← hsp]
      exact (Term.apps_spine s).symm
    rw [hs, Term.subst_apps, Term.subst_apps]
    simp only [Term.subst]
    rw [Term.subst_closed dd.body 0 d w' hc (Nat.zero_le d)]
    refine ParB.dref hk
      (by rw [Term.spine_apps (by trivial)])
      (by
        rw [Term.spine_apps (by trivial)]
        simp only [List.length_map]
        exact hlen') ?_
    rw [Term.spine_apps (by trivial)]
    intro i hi
    simp only [List.length_map] at hi
    rw [map_getD (Term.subst d w) .Qnt .Qnt _ i (by omega),
      map_getD (Term.subst d w') .Qnt .Qnt args' i (by omega)]
    exact ih i (by omega) d hw
  | aref hk h0 => intro d w w' _; exact .aref hk h0
  | matc h1 h2 h3 h4 hps hph ihs ihh =>
    rename_i a A c C s s' h h' m
    intro d w w' hw
    obtain ⟨hh', hargs⟩ := hps.spine_stable h3
    have e1 : (Term.spine (Term.subst d w s)).1 = Term.Ctr a c := by
      rw [Term.spine_subst h3 (by trivial) _root_.rfl]
    have e2 : (Term.spine (Term.subst d w s)).2.length = A.pn + C.fn := by
      rw [Term.spine_subst h3 (by trivial) _root_.rfl]; simpa using h4
    have e3 : Term.subst d w' (Term.apps h' ((Term.spine s').2.drop A.pn))
        = Term.apps (Term.subst d w' h')
            ((Term.spine (Term.subst d w' s')).2.drop A.pn) := by
      rw [Term.subst_apps, Term.spine_subst hh' (by trivial) _root_.rfl]
      show _ = Term.apps _ (((Term.spine s').2.map (Term.subst d w')).drop A.pn)
      rw [List.map_drop]
    rw [show Term.subst d w (.App (.Mat a c h m) s)
        = .App (.Mat a c (Term.subst d w h) (Term.subst d w m))
            (Term.subst d w s)
      from _root_.rfl, e3]
    exact ParB.matc h1 h2 e1 e2 (ihs d hw) (ihh d hw)
  | matm h1 hne hps hphm ihs ihm =>
    rename_i s a' c' a c s' m m' h
    intro d w w' hw
    exact ParB.matm (by rw [Term.spine_subst h1 (by trivial) _root_.rfl]) hne
      (ihs d hw) (ihm d hw)
  | rwtr _ ihf =>
    intro d w w' hw
    exact .rwtr (ihf d hw)
  | minLM _ ih => intro d w w' hw; exact .minLM (ih d hw)
  | minLN => intro d w w' _; exact .minLN
  | minRM _ ih => intro d w w' hw; exact .minRM (ih d hw)
  | minRN => intro d w w' _; exact .minRN
  | minLL => intro d w w' _; exact .minLL

-- ----------------------------------------------------------------------------
-- Eta and Etas: shift, substitution, chains, congruences
-- ----------------------------------------------------------------------------

-- subject reduction of the dead fragment along one eta-free parallel step, in
-- any context; induction on the derivation, since an appLam-typed redex with a
-- step in its argument needs a parallel step of the sub-derivation
theorem Check.dead_parB (hok : Book.Ok β) {sp : List Term}
    (h : Check β (Pol.dead β) L sp q Γ t T π u) (hq : q = .None) :
    ∀ t', ParB β t t' →
      Check β (Pol.dead β) (LHS.void β) [] .None Γ t' T Uses.zero .Qnt := by
  have hβ := hok.closed
  induction h with
  | var hg =>
    intro t' hp
    cases hp with
    | var => exact Check.at0 (Check.var hg)
    | dref _ hs _ _ => simp [Term.spine] at hs
  | ref hk hw hd =>
    intro t' hp
    cases hp with
    | ref => exact ((Check.ref hk hw hd).void_sp []).dead
    | dref hk' hs hlen _ =>
      simp [Term.spine] at hs; subst hs
      rw [hk] at hk'; cases hk'
      have e := List.eq_nil_of_length_eq_zero (by simpa [Term.spine] using hlen.symm)
      rw [e]; exact Check.bodyD hok hk _
    | aref hA _ => exact (Book.defn_adt_clash hk hA).elim
  | refA hk h0 =>
    intro t' hp
    cases hp with
    | ref => exact Check.at0 (Check.refA hk h0)
    | dref hk' hs _ _ =>
      simp [Term.spine] at hs; subst hs; exact (Book.defn_adt_clash hk' hk).elim
    | aref hA _ => rw [hk] at hA; cases hA; exact Check.at0 (Check.adt hk)
  | adt hk =>
    intro t' hp
    cases hp with
    | adt => exact Check.at0 (Check.adt hk)
    | dref _ hs _ _ => simp [Term.spine] at hs
  | ctr hk hc hr =>
    intro t' hp
    cases hp with
    | ctr => exact Check.at0 (Check.ctr hk hc hr)
    | dref _ hs _ _ => simp [Term.spine] at hs
  | typ hg ihg =>
    subst hq; intro t' hp
    cases hp with
    | typ hg' => exact Check.at0 (Check.typ (ihg _root_.rfl _ hg'))
    | dref _ hs _ _ => simp [Term.spine] at hs
  | qnt =>
    intro t' hp
    cases hp with
    | qnt => exact Check.at0 Check.qnt
    | dref _ hs _ _ => simp [Term.spine] at hs
  | qua =>
    intro t' hp
    cases hp with
    | qua => exact Check.at0 Check.qua
    | dref _ hs _ _ => simp [Term.spine] at hs
  | min ha hb iha ihb =>
    subst hq; intro t' hp
    cases hp with
    | min ha' hb' => exact Check.at0 (Check.min (iha _root_.rfl _ ha') (ihb _root_.rfl _ hb'))
    | minLM hb' => exact ihb _root_.rfl _ hb'
    | minLN => exact Check.at0 Check.qua
    | minRM ha' => exact iha _root_.rfl _ ha'
    | minRN => exact Check.at0 Check.qua
    | minLL => exact Check.at0 Check.qua
    | dref _ hs _ _ => simp [Term.spine] at hs
  | all hA hB ihA ihB =>
    subst hq; intro t' hp
    cases hp with
    | all hA' hB' =>
      have hA'' := ihA _root_.rfl _ hA'
      have hB'' := (ihB _root_.rfl _ hB').cv hβ _
        (.rigid (Conv.of_red (hA'.par.red hβ)) (Ctx.Cv.refl _))
      exact Check.at0 (Check.all hA'' hB'')
    | dref _ hs _ _ => simp [Term.spine] at hs
  | lam hA hf hle ihA ihf =>
    subst hq; intro t' hp
    cases hp with
    | lam hf' => exact Check.at0 (Check.lam hA.void (ihf _root_.rfl _ hf') trivial)
    | dref _ hs _ _ => simp [Term.spine] at hs
  | @app L x sp q Γ f q' A B πf uf πx ux hf hx ihf ihx =>
    subst hq; intro t' hp
    cases hp with
    | app hf' hx' =>
      have hres := Check.app ((ihf _root_.rfl _ hf').sp [_])
        (by rw [Quant.dem_none]; exact ihx (Quant.dem_none _) _ hx')
      exact hres.cnv (Pol.dead_arg hβ (Conv.of_red (hx'.par.red hβ)) _)
    | beta hg' hx' =>
      have hres := Check.app ((ihf _root_.rfl _ (ParB.lam hg')).sp [_])
        (by rw [Quant.dem_none]; exact ihx (Quant.dem_none _) _ hx')
      exact (Check.betaD hβ hres).cnv (Pol.dead_arg hβ (Conv.of_red (hx'.par.red hβ)) _)
    | @dref k d _ args' hk hs hlen hargs =>
      obtain ⟨args₀, x', rfl, hpars, hxx'⟩ := Pw.snoc_inv (Pw.of_getD hlen hargs)
      have e : Term.apps (.Ref k) (Term.spine f).2 = f := by
        have := Term.apps_spine f
        rwa [show (Term.spine f).1 = .Ref k from hs] at this
      have hf0 : ParB β f (Term.apps (.Ref k) args₀) := by rw [← e]; exact ParB.apps .ref hpars
      have happ := Check.at0 (Check.app ((ihf _root_.rfl _ hf0).sp [x'])
        (by rw [Quant.dem_none]; exact ihx (Quant.dem_none _) _ hxx'))
      have happ' : Check β (Pol.dead β) (LHS.void β) [] .None Γ
          (Term.apps (.Ref k) (args₀ ++ [x'])) (Term.subst 0 x' B) Uses.zero .Qnt := by
        rw [Term.apps_append]; exact happ
      exact (Check.drefD hok hk happ').cnv (Pol.dead_arg hβ (Conv.of_red (hxx'.par.red hβ)) _)
    | @matc a A c C s s' hh h' mm hA hC hs hlen hs' hh' =>
      have happ := Check.at0 (Check.app ((ihf _root_.rfl _ (ParB.mat hh' (ParB.refl mm))).sp [s'])
        (by rw [Quant.dem_none]; exact ihx (Quant.dem_none _) _ hs'))
      obtain ⟨hs'1, hpars⟩ := hs'.spine_stable hs
      have hlen' : (Term.spine s').2.length = A.pn + C.fn := hpars.length.symm.trans hlen
      have es' : Term.apps (.Ctr a c) ((Term.spine s').2.take A.pn ++ (Term.spine s').2.drop A.pn)
          = s' := by
        rw [List.take_append_drop]
        have := Term.apps_spine s'
        rwa [show (Term.spine s').1 = .Ctr a c from hs'1] at this
      have happ' : Check β (Pol.dead β) (LHS.void β) [] .None Γ
          (.App (.Mat a c h' mm)
            (Term.apps (.Ctr a c) ((Term.spine s').2.take A.pn ++ (Term.spine s').2.drop A.pn)))
          (Term.subst 0 s' B) Uses.zero .Qnt := by
        rw [es']; exact happ
      have hred := Check.matcD hok hA hC
        (by rw [List.length_take]; exact Nat.min_eq_left (by omega))
        (by rw [List.length_drop]; omega) happ'
      exact hred.cnv (Pol.dead_arg hβ (Conv.of_red (hs'.par.red hβ)) _)
    | @matm s a' c' a c s' mm m' hh hs hne hs' hm' =>
      have happ := Check.at0 (Check.app ((ihf _root_.rfl _ (ParB.mat (ParB.refl hh) hm')).sp [s'])
        (by rw [Quant.dem_none]; exact ihx (Quant.dem_none _) _ hs'))
      obtain ⟨hs'1, _⟩ := hs'.spine_stable hs
      have es' : Term.apps (.Ctr a' c') (Term.spine s').2 = s' := by
        have := Term.apps_spine s'
        rwa [show (Term.spine s').1 = .Ctr a' c' from hs'1] at this
      have happ' : Check β (Pol.dead β) (LHS.void β) [] .None Γ
          (.App (.Mat a c hh m') (Term.apps (.Ctr a' c') (Term.spine s').2)) (Term.subst 0 s' B)
          Uses.zero .Qnt := by
        rw [es']; exact happ
      have hred := Check.matmD hok hne happ'
      rw [es'] at hred
      exact hred.cnv (Pol.dead_arg hβ (Conv.of_red (hs'.par.red hβ)) _)
  | appLam hcl hg ih =>
    subst hq; intro t' hp
    cases hp with
    | app hL hx' =>
      cases hL with
      | lam hg' =>
        exact Check.at0
          (Check.appLam (hx'.par.closed hβ hcl) (ih _root_.rfl _ (hg'.subst hβ 0 hx')))
      | dref _ hs _ _ => simp [Term.spine] at hs
    | beta hg' hx' => exact ih _root_.rfl _ (hg'.subst hβ 0 hx')
    | dref _ hs _ _ => simp [Term.spine] at hs
  | let_ hv hA hb hle ihv ihA ihb =>
    subst hq; intro t' hp
    cases hp with
    | let_ hv' hb' =>
      have hv'' := ihv (Quant.dem_none _) _ hv'
      have hb'' := (ihb _root_.rfl _ hb').cv hβ _
        (.val (Conv.refl _) (Conv.of_red (hv'.par.red hβ)) (Ctx.Cv.refl _))
      exact Check.at0 (Check.let_ (by rw [Quant.dem_none]; exact hv'') hA.void hb'' trivial)
    | letr hv' hb' =>
      have hv'' := ihv (Quant.dem_none _) _ hv'
      have hb'' := (ihb _root_.rfl _ hb').cv hβ _
        (.val (Conv.refl _) (Conv.of_red (hv'.par.red hβ)) (Ctx.Cv.refl _))
      have hres := Check.substD hβ hb'' hv'' (.inr _root_.rfl) [] _root_.rfl _root_.rfl
      simp only [List.length_nil, Term.shiftN, Ctx.substAt, List.nil_append,
        Term.subst_shift] at hres
      exact hres
    | dref _ hs _ _ => simp [Term.spine] at hs
  | eql hT ha hb ihT iha ihb =>
    subst hq; intro t' hp
    cases hp with
    | eql hx' hy' hT' =>
      exact Check.at0 (Check.eql (ihT _root_.rfl _ hT')
        ((iha _root_.rfl _ hx').cnv
          (Pol.dead_conv hβ (Ctx.δ_conv hβ _ 0 (Conv.of_red (hT'.par.red hβ)))))
        ((ihb _root_.rfl _ hy').cnv
          (Pol.dead_conv hβ (Ctx.δ_conv hβ _ 0 (Conv.of_red (hT'.par.red hβ))))))
    | dref _ hs _ _ => simp [Term.spine] at hs
  | rfl hc =>
    intro t' hp
    cases hp with
    | rfl => exact Check.at0 (Check.rfl hc)
    | dref _ hs _ _ => simp [Term.spine] at hs
  | rwt he hP hf ihe ihP ihf =>
    subst hq; intro t' hp
    cases hp with
    | rwt he' hP' hf' =>
      have hf'' := (ihf _root_.rfl _ hf').cnv
        (Pol.dead_app2 hβ (Conv.of_red (hP'.par.red hβ)) (Conv.refl _) (Conv.refl _))
      have hres := Check.rwt (sp := []) (ihe _root_.rfl _ he') (ihP _root_.rfl _ hP') hf''
      exact ((hres.cnv (Pol.dead_app2 hβ (Conv.of_red_rev (hP'.par.red hβ)) (Conv.refl _)
        (Conv.of_red_rev (he'.par.red hβ)))).void_sp []).dead
    | rwtr hf' => exact Check.rwtD hβ (Check.rwt (sp := []) he.void hP.void (ihf _root_.rfl _ hf'))
    | dref _ hs _ _ => simp [Term.spine] at hs
  | mat hk hc hr hlen hlive hins hgoal hh hm ihh ihm =>
    subst hq; intro t' hp
    cases hp with
    | mat hh' hm' =>
      exact Check.at0 (Check.mat hk hc hr hlen hlive hins hgoal (ihh _root_.rfl _ hh')
        (ihm _root_.rfl _ hm'))
    | dref _ hs _ _ => simp [Term.spine] at hs
  | efq hk hlive _ =>
    subst hq; intro t' hp
    cases hp with
    | efq => exact Check.at0 (Check.efq hk hlive (.inr trivial))
    | dref _ hs _ _ => simp [Term.spine] at hs
  | cnv _ hc iht =>
    intro t' hp
    exact (iht hq _ hp).cnv hc

-- one eta-free step, an eta-free run
theorem Check.dead_stepB (hok : Book.Ok β) {sp : List Term}
    (h : Check β (Pol.dead β) L sp q Γ t T π u) (hq : q = .None) (hs : StepB β t t') :
    Check β (Pol.dead β) (LHS.void β) [] .None Γ t' T Uses.zero .Qnt :=
  Check.dead_parB hok h hq t' hs.par

theorem Check.dead_redB (hok : Book.Ok β) {sp : List Term}
    (h : Check β (Pol.dead β) L sp q Γ t T π u) (hq : q = .None) (hr : RedB β t t') :
    Check β (Pol.dead β) (LHS.void β) [] .None Γ t' T Uses.zero .Qnt := by
  induction hr generalizing L sp q π u with
  | refl => exact Check.dead_parB hok h hq _ (ParB.refl _)
  | step s _ ih => exact ih (Check.dead_stepB hok h hq s) _root_.rfl

-- ----------------------------------------------------------------------------
-- §K4 the eta algebra: one eta step and its closure, parallel eta, the commute
-- of eta chains with eta-free runs, and towers (what an eta source of a spine
-- B-reduces to once its inner eta-expansions are peeled by betas)
-- ----------------------------------------------------------------------------

inductive Eta (β : Book) : Term → Term → Prop
  | eta   : Term.occ 0 F = 0 → Eta β (.Lam (.App F (.Var 0))) (Term.subst 0 .Qnt F)
  | typ_g : Eta β g g' → Eta β (.Typ g) (.Typ g')
  | min_a : Eta β a a' → Eta β (.Min a b) (.Min a' b)
  | min_b : Eta β b b' → Eta β (.Min a b) (.Min a b')
  | all_a : Eta β A A' → Eta β (.All q A B) (.All q A' B)
  | all_b : Eta β B B' → Eta β (.All q A B) (.All q A B')
  | lam_f : Eta β f f' → Eta β (.Lam f) (.Lam f')
  | app_f : Eta β f f' → Eta β (.App f a) (.App f' a)
  | app_a : Eta β a a' → Eta β (.App f a) (.App f a')
  | mat_h : Eta β h h' → Eta β (.Mat a c h m) (.Mat a c h' m)
  | mat_m : Eta β m m' → Eta β (.Mat a c h m) (.Mat a c h m')
  | eql_a : Eta β x x' → Eta β (.Eql x y T) (.Eql x' y T)
  | eql_b : Eta β y y' → Eta β (.Eql x y T) (.Eql x y' T)
  | eql_t : Eta β T T' → Eta β (.Eql x y T) (.Eql x y T')
  | rwt_e : Eta β e e' → Eta β (.Rwt e P f) (.Rwt e' P f)
  | rwt_p : Eta β P P' → Eta β (.Rwt e P f) (.Rwt e P' f)
  | rwt_f : Eta β f f' → Eta β (.Rwt e P f) (.Rwt e P f')
  | let_v : Eta β v v' → Eta β (.Let q v b) (.Let q v' b)
  | let_b : Eta β b b' → Eta β (.Let q v b) (.Let q v b')

theorem Eta.step (h : Eta β a b) : Step β .strong a b := by
  induction h with
  | eta hocc => exact .eta _root_.rfl hocc
  | typ_g _ ih => exact .typ_g _root_.rfl ih
  | min_a _ ih => exact .min_a ih
  | min_b _ ih => exact .min_b ih
  | all_a _ ih => exact .all_a _root_.rfl ih
  | all_b _ ih => exact .all_b _root_.rfl ih
  | lam_f _ ih => exact .lam_f _root_.rfl ih
  | app_f _ ih => exact .app_f ih
  | app_a _ ih => exact .app_a ih
  | mat_h _ ih => exact .mat_h ih
  | mat_m _ ih => exact .mat_m ih
  | eql_a _ ih => exact .eql_a ih
  | eql_b _ ih => exact .eql_b ih
  | eql_t _ ih => exact .eql_t ih
  | rwt_e _ ih => exact .rwt_e ih
  | rwt_p _ ih => exact .rwt_p ih
  | rwt_f _ ih => exact .rwt_f ih
  | let_v _ ih => exact .let_v ih
  | let_b _ ih => exact .let_b _root_.rfl ih

abbrev Etas (β : Book) := Star (Eta β)
abbrev Etass (β : Book) := Pw (Etas β)

theorem Eta.shift (h : Eta β a b) : ∀ d, Eta β (Term.shift d a) (Term.shift d b) := by
  induction h with
  | eta hocc =>
    intro d
    rw [Term.shift_subst_ge _ d 0 .Qnt (Nat.zero_le d)]
    simp only [Term.shift, Nat.zero_lt_succ, ↓reduceIte]
    exact .eta (by rw [Term.occ_shift_lt _ 0 (d + 1) (by omega)]; exact hocc)
  | typ_g _ ih => intro d; exact .typ_g (ih d)
  | min_a _ ih => intro d; exact .min_a (ih d)
  | min_b _ ih => intro d; exact .min_b (ih d)
  | all_a _ ih => intro d; exact .all_a (ih d)
  | all_b _ ih => intro d; exact .all_b (ih (d + 1))
  | lam_f _ ih => intro d; exact .lam_f (ih (d + 1))
  | app_f _ ih => intro d; exact .app_f (ih d)
  | app_a _ ih => intro d; exact .app_a (ih d)
  | mat_h _ ih => intro d; exact .mat_h (ih d)
  | mat_m _ ih => intro d; exact .mat_m (ih d)
  | eql_a _ ih => intro d; exact .eql_a (ih d)
  | eql_b _ ih => intro d; exact .eql_b (ih d)
  | eql_t _ ih => intro d; exact .eql_t (ih d)
  | rwt_e _ ih => intro d; exact .rwt_e (ih d)
  | rwt_p _ ih => intro d; exact .rwt_p (ih d)
  | rwt_f _ ih => intro d; exact .rwt_f (ih d)
  | let_v _ ih => intro d; exact .let_v (ih d)
  | let_b _ ih => intro d; exact .let_b (ih (d + 1))

theorem Eta.subst (h : Eta β a b) : ∀ d w, Eta β (Term.subst d w a) (Term.subst d w b) := by
  induction h with
  | @eta F hocc =>
    intro d w
    rw [Term.subst_subst0]
    have h0 : Term.subst (d + 1) (Term.shift 0 w) (Term.Var 0) = .Var 0 := by
      simp only [Term.subst]
      rw [if_neg (by omega), if_neg (by omega)]
    show Eta β (.Lam (.App (Term.subst (d + 1) (Term.shift 0 w) F)
      (Term.subst (d + 1) (Term.shift 0 w) (.Var 0)))) _
    rw [h0]
    exact .eta (Term.occ_subst_lt_zero F (d + 1) 0 (Term.shift 0 w)
      (by omega) hocc (Term.occ_shift_self w 0))
  | typ_g _ ih => intro d w; exact .typ_g (ih d w)
  | min_a _ ih => intro d w; exact .min_a (ih d w)
  | min_b _ ih => intro d w; exact .min_b (ih d w)
  | all_a _ ih => intro d w; exact .all_a (ih d w)
  | all_b _ ih => intro d w; exact .all_b (ih (d + 1) _)
  | lam_f _ ih => intro d w; exact .lam_f (ih (d + 1) _)
  | app_f _ ih => intro d w; exact .app_f (ih d w)
  | app_a _ ih => intro d w; exact .app_a (ih d w)
  | mat_h _ ih => intro d w; exact .mat_h (ih d w)
  | mat_m _ ih => intro d w; exact .mat_m (ih d w)
  | eql_a _ ih => intro d w; exact .eql_a (ih d w)
  | eql_b _ ih => intro d w; exact .eql_b (ih d w)
  | eql_t _ ih => intro d w; exact .eql_t (ih d w)
  | rwt_e _ ih => intro d w; exact .rwt_e (ih d w)
  | rwt_p _ ih => intro d w; exact .rwt_p (ih d w)
  | rwt_f _ ih => intro d w; exact .rwt_f (ih d w)
  | let_v _ ih => intro d w; exact .let_v (ih d w)
  | let_b _ ih => intro d w; exact .let_b (ih (d + 1) _)

theorem Etas.typ (r : Etas β g g') : Etas β (.Typ g) (.Typ g') :=
  Star.congr (F := fun g => .Typ g) (fun s => .typ_g s) r

theorem Etas.min (ra : Etas β a a') (rb : Etas β b b') :
    Etas β (.Min a b) (.Min a' b') :=
  (Star.congr (F := fun a => .Min a b) (fun s => .min_a s) ra).trans
    (Star.congr (F := fun b => .Min a' b) (fun s => .min_b s) rb)

theorem Etas.all (rA : Etas β A A') (rB : Etas β B B') :
    Etas β (.All q A B) (.All q A' B') :=
  (Star.congr (F := fun A => .All q A B) (fun s => .all_a s) rA).trans
    (Star.congr (F := fun B => .All q A' B) (fun s => .all_b s) rB)

theorem Etas.lam (r : Etas β f f') : Etas β (.Lam f) (.Lam f') :=
  Star.congr (F := fun f => .Lam f) (fun s => .lam_f s) r

theorem Etas.app (rf : Etas β f f') (ra : Etas β a a') :
    Etas β (.App f a) (.App f' a') :=
  (Star.congr (F := fun f => .App f a) (fun s => .app_f s) rf).trans
    (Star.congr (F := fun a => .App f' a) (fun s => .app_a s) ra)

theorem Etas.mat (rh : Etas β h h') (rm : Etas β m m') :
    Etas β (.Mat a c h m) (.Mat a c h' m') :=
  (Star.congr (F := fun h => .Mat a c h m) (fun s => .mat_h s) rh).trans
    (Star.congr (F := fun m => .Mat a c h' m) (fun s => .mat_m s) rm)

theorem Etas.eql (rx : Etas β x x') (ry : Etas β y y') (rT : Etas β T T') :
    Etas β (.Eql x y T) (.Eql x' y' T') :=
  ((Star.congr (F := fun x => .Eql x y T) (fun s => .eql_a s) rx).trans
    (Star.congr (F := fun y => .Eql x' y T) (fun s => .eql_b s) ry)).trans
    (Star.congr (F := fun T => .Eql x' y' T) (fun s => .eql_t s) rT)

theorem Etas.rwt (re : Etas β e e') (rP : Etas β P P') (rf : Etas β f f') :
    Etas β (.Rwt e P f) (.Rwt e' P' f') :=
  ((Star.congr (F := fun e => .Rwt e P f) (fun s => .rwt_e s) re).trans
    (Star.congr (F := fun P => .Rwt e' P f) (fun s => .rwt_p s) rP)).trans
    (Star.congr (F := fun f => .Rwt e' P' f) (fun s => .rwt_f s) rf)

theorem Etas.let_ (rv : Etas β v v') (rb : Etas β b b') :
    Etas β (.Let q v b) (.Let q v' b') :=
  (Star.congr (F := fun v => .Let q v b) (fun s => .let_v s) rv).trans
    (Star.congr (F := fun b => .Let q v' b) (fun s => .let_b s) rb)

theorem Etas.shift (h : Etas β a b) (d : Nat) : Etas β (Term.shift d a) (Term.shift d b) :=
  Star.congr (fun s => s.shift d) h

theorem Etas.shiftN (n : Nat) (h : Etas β a b) : Etas β (Term.shiftN n a) (Term.shiftN n b) := by
  induction n with
  | zero => exact h
  | succ n ih => exact ih.shift 0

theorem Etas.subst1 (h : Etas β a b) (d : Nat) (w : Term) :
    Etas β (Term.subst d w a) (Term.subst d w b) := Star.congr (fun s => s.subst d w) h

-- the argument of a substitution eta-contracts: one eta per copy
theorem Eta.substR : ∀ (t : Term) (d : Nat) {w w' : Term},
    Eta β w w' → Etas β (Term.subst d w t) (Term.subst d w' t) := by
  intro t
  induction t with
  | Var i =>
    intro d w w' s
    simp only [Term.subst]
    split
    · exact Star.one s
    · split <;> exact .refl
  | Ref k => intro d w w' _; exact .refl
  | Typ g ih => intro d w w' s; exact Etas.typ (ih d s)
  | Qnt => intro d w w' _; exact .refl
  | Qua q => intro d w w' _; exact .refl
  | Min a b iha ihb => intro d w w' s; exact Etas.min (iha d s) (ihb d s)
  | All q A B ihA ihB =>
    intro d w w' s; exact Etas.all (ihA d s) (ihB (d + 1) (s.shift 0))
  | Lam f ih => intro d w w' s; exact Etas.lam (ih (d + 1) (s.shift 0))
  | App f a ihf iha => intro d w w' s; exact Etas.app (ihf d s) (iha d s)
  | Adt a r => intro d w w' _; exact .refl
  | Ctr a c => intro d w w' _; exact .refl
  | Mat a c h m ihh ihm => intro d w w' s; exact Etas.mat (ihh d s) (ihm d s)
  | Efq => intro d w w' _; exact .refl
  | Eql x y T ihx ihy ihT =>
    intro d w w' s; exact Etas.eql (ihx d s) (ihy d s) (ihT d s)
  | Rfl => intro d w w' _; exact .refl
  | Rwt e P f ihe ihP ihf =>
    intro d w w' s; exact Etas.rwt (ihe d s) (ihP d s) (ihf d s)
  | Let q v b ihv ihb =>
    intro d w w' s; exact Etas.let_ (ihv d s) (ihb (d + 1) (s.shift 0))

theorem Etas.substR (h : Etas β w w') (d : Nat) (t : Term) :
    Etas β (Term.subst d w t) (Term.subst d w' t) := Star.substR Eta.substR h d t

theorem Etas.subst {d : Nat} (ha : Etas β a a') (hw : Etas β w w') :
    Etas β (Term.subst d w a) (Term.subst d w' a') :=
  (ha.subst1 d w).trans (hw.substR d a')

-- the eta-expansion of any term contracts to it
theorem Eta.expand (t : Term) : Eta β (.Lam (.App (Term.shift 0 t) (.Var 0))) t := by
  have h := Eta.eta (β := β) (F := Term.shift 0 t) (Term.occ_shift_self t 0)
  rwa [Term.subst_shift] at h

theorem Etas.apps (hh : Etas β h h') (has : Etass β as as') :
    Etas β (Term.apps h as) (Term.apps h' as') := by
  induction has generalizing h h' with
  | nil => exact hh
  | cons hp _ ih => exact ih (Etas.app hh hp)

-- ----------------------------------------------------------------------------
-- inversion: an eta chain keeps the root constructor (children chain), or
-- a root eta fires after inner steps
-- ----------------------------------------------------------------------------

-- one layer of congruence: same root, Etas on every child
inductive EtasC (β : Book) : Term → Term → Prop
  | var  : EtasC β (.Var i) (.Var i)
  | ref  : EtasC β (.Ref k) (.Ref k)
  | typ  : Etas β g g' → EtasC β (.Typ g) (.Typ g')
  | qnt  : EtasC β .Qnt .Qnt
  | qua  : EtasC β (.Qua q) (.Qua q)
  | min  : Etas β a a' → Etas β b b' → EtasC β (.Min a b) (.Min a' b')
  | adt  : EtasC β (.Adt a r) (.Adt a r)
  | ctr  : EtasC β (.Ctr a c) (.Ctr a c)
  | efq  : EtasC β .Efq .Efq
  | rfl  : EtasC β .Rfl .Rfl
  | all  : Etas β A A' → Etas β B B' → EtasC β (.All q A B) (.All q A' B')
  | lam  : Etas β f f' → EtasC β (.Lam f) (.Lam f')
  | app  : Etas β f f' → Etas β a a' → EtasC β (.App f a) (.App f' a')
  | mat  : Etas β h h' → Etas β m m' → EtasC β (.Mat a c h m) (.Mat a c h' m')
  | eql  : Etas β x x' → Etas β y y' → Etas β T T' →
           EtasC β (.Eql x y T) (.Eql x' y' T')
  | rwt  : Etas β e e' → Etas β P P' → Etas β f f' →
           EtasC β (.Rwt e P f) (.Rwt e' P' f')
  | let_ : Etas β v v' → Etas β b b' → EtasC β (.Let q v b) (.Let q v' b')

theorem EtasC.refl : ∀ (t : Term), EtasC β t t := by
  intro t; cases t <;> constructor <;> exact .refl

theorem EtasC.subst1 (h : EtasC β s u) (d : Nat) (w : Term) :
    EtasC β (Term.subst d w s) (Term.subst d w u) := by
  cases h with
  | var => exact EtasC.refl _
  | ref => exact .ref
  | typ h => exact .typ (h.subst1 d w)
  | qnt => exact .qnt
  | qua => exact .qua
  | min ha hb => exact .min (ha.subst1 d w) (hb.subst1 d w)
  | adt => exact .adt
  | ctr => exact .ctr
  | efq => exact .efq
  | rfl => exact .rfl
  | all hA hB => exact .all (hA.subst1 d w) (hB.subst1 (d + 1) _)
  | lam hf => exact .lam (hf.subst1 (d + 1) _)
  | app hf ha => exact .app (hf.subst1 d w) (ha.subst1 d w)
  | mat hh hm => exact .mat (hh.subst1 d w) (hm.subst1 d w)
  | eql hx hy hT => exact .eql (hx.subst1 d w) (hy.subst1 d w) (hT.subst1 d w)
  | rwt he hP hf => exact .rwt (he.subst1 d w) (hP.subst1 d w) (hf.subst1 d w)
  | let_ hv hb => exact .let_ (hv.subst1 d w) (hb.subst1 (d + 1) _)

theorem Etas.inv (h : Etas β s u) : EtasC β s u ∨
    ∃ X F, s = .Lam X ∧ Etas β X (.App F (.Var 0)) ∧ Term.occ 0 F = 0 ∧
      Etas β (Term.subst 0 .Qnt F) u := by
  induction h with
  | refl => exact .inl (EtasC.refl _)
  | step e rest ih =>
    cases e
    case eta hocc => exact .inr ⟨_, _, _root_.rfl, .refl, hocc, rest⟩
    all_goals
      rcases ih with hc | ⟨X, F, hX, h1, h2, h3⟩
      · cases hc; left; constructor <;> first | assumption | exact .step ‹_› ‹_›
      · cases hX <;> exact .inr ⟨_, _, _root_.rfl, .step ‹_› h1, h2, h3⟩

-- forward stability: an eta chain from a leaf-headed spine stays on that
-- head, arguments pointwise
def Term.IsLeaf : Term → Prop
  | .Var _ | .Ref _ | .Qnt | .Qua _ | .Adt _ _ | .Ctr _ _ | .Efq | .Rfl => True
  | _ => False

theorem Term.IsLeaf.isHead {t : Term} (h : Term.IsLeaf t) : Term.IsHead t := by
  cases t <;> simp_all [Term.IsLeaf, Term.IsHead]

theorem Eta.leaf_spine_inv (hp : Eta β s t) :
    ∀ {h : Term} {as : List Term}, h.IsLeaf → s = Term.apps h as →
    ∃ as', t = Term.apps h as' ∧ Etass β as as' := by
  induction hp <;> intro h as hl heq
  all_goals try
    exact absurd heq.symm (Term.apps_ne hl.isHead (by trivial) (fun e => by subst e; exact hl.elim))
  case app_f _ _ _ hf ihf =>
    obtain ⟨ys, hys, hfy⟩ := Term.app_eq_apps hl.isHead heq
    obtain ⟨ys', hy1, hy2⟩ := ihf hl hfy
    subst hys hy1
    exact ⟨ys' ++ [_], (Term.apps_snoc _ _ _).symm, Pw.append hy2 (.cons .refl .nil)⟩
  case app_a _ _ _ ha _ =>
    obtain ⟨ys, hys, hfy⟩ := Term.app_eq_apps hl.isHead heq
    subst hys hfy
    exact ⟨ys ++ [_], (Term.apps_snoc _ _ _).symm,
      Pw.append (Pw.star_refl _) (.cons (Star.one ha) .nil)⟩

theorem Etas.leaf_spine_inv (hp : Etas β s t) :
    ∀ {h : Term} {as : List Term}, h.IsLeaf → s = Term.apps h as →
    ∃ as', t = Term.apps h as' ∧ Etass β as as' := by
  induction hp with
  | refl => intro h as _ heq; exact ⟨as, heq, Pw.star_refl _⟩
  | step e _ ih =>
    intro h as hl heq
    obtain ⟨as₁, h1, h2⟩ := e.leaf_spine_inv hl heq
    obtain ⟨as', h3, h4⟩ := ih hl h1
    exact ⟨as', h3, Pw.trans Star.trans h2 h4⟩

theorem Etas.spine_stable (hp : Etas β s t) (hh : (Term.spine s).1 = h) (hl : h.IsLeaf) :
    (Term.spine t).1 = h ∧ Etass β (Term.spine s).2 (Term.spine t).2 :=
  Term.spine_stable (fun hp e => hp.leaf_spine_inv hl e) hl.isHead hp hh

-- ----------------------------------------------------------------------------
-- Par.split: a parallel step is an eta-free parallel step then etas
-- ----------------------------------------------------------------------------

theorem List.choose_getD : ∀ (n : Nat) (P : Nat → Term → Prop),
    (∀ i, i < n → ∃ y, P i y) →
    ∃ ys : List Term, ys.length = n ∧ ∀ i, i < n → P i (ys.getD i .Qnt) := by
  intro n
  induction n with
  | zero => intro P _; exact ⟨[], _root_.rfl, fun i hi => absurd hi (Nat.not_lt_zero i)⟩
  | succ n ih =>
    intro P h
    obtain ⟨y, hy⟩ := h 0 (Nat.zero_lt_succ n)
    obtain ⟨ys, hlen, hys⟩ := ih (fun i => P (i + 1)) (fun i hi => h (i + 1) (by omega))
    refine ⟨y :: ys, by simp [hlen], fun i hi => ?_⟩
    cases i with
    | zero => exact hy
    | succ i => exact hys i (by omega)

theorem Par.split (hβ : Book.Closed β) (hp : Par β u v) :
    ∃ u₁, ParB β u u₁ ∧ Etas β u₁ v := by
  induction hp with
  | @eta F F' hocc hF ih =>
    obtain ⟨F₁, h1, h2⟩ := ih
    refine ⟨.Lam (.App F₁ (.Var 0)), .lam (.app h1 .var), ?_⟩
    exact (Etas.lam (Etas.app h2 .refl)).trans (Star.one (.eta (Par.occ_zero hβ hF 0 hocc)))
  | var => exact ⟨_, .var, .refl⟩
  | ref => exact ⟨_, .ref, .refl⟩
  | typ _ ih => obtain ⟨_, h1, h2⟩ := ih; exact ⟨_, .typ h1, Etas.typ h2⟩
  | qnt => exact ⟨_, .qnt, .refl⟩
  | qua => exact ⟨_, .qua, .refl⟩
  | min _ _ iha ihb =>
    obtain ⟨_, ha1, ha2⟩ := iha; obtain ⟨_, hb1, hb2⟩ := ihb
    exact ⟨_, .min ha1 hb1, Etas.min ha2 hb2⟩
  | adt => exact ⟨_, .adt, .refl⟩
  | ctr => exact ⟨_, .ctr, .refl⟩
  | efq => exact ⟨_, .efq, .refl⟩
  | rfl => exact ⟨_, .rfl, .refl⟩
  | all _ _ ihA ihB =>
    obtain ⟨_, hA1, hA2⟩ := ihA; obtain ⟨_, hB1, hB2⟩ := ihB
    exact ⟨_, .all hA1 hB1, Etas.all hA2 hB2⟩
  | lam _ ih => obtain ⟨_, h1, h2⟩ := ih; exact ⟨_, .lam h1, Etas.lam h2⟩
  | app _ _ ihf iha =>
    obtain ⟨_, hf1, hf2⟩ := ihf; obtain ⟨_, ha1, ha2⟩ := iha
    exact ⟨_, .app hf1 ha1, Etas.app hf2 ha2⟩
  | mat _ _ ihh ihm =>
    obtain ⟨_, hh1, hh2⟩ := ihh; obtain ⟨_, hm1, hm2⟩ := ihm
    exact ⟨_, .mat hh1 hm1, Etas.mat hh2 hm2⟩
  | eql _ _ _ ihx ihy ihT =>
    obtain ⟨_, hx1, hx2⟩ := ihx; obtain ⟨_, hy1, hy2⟩ := ihy
    obtain ⟨_, hT1, hT2⟩ := ihT
    exact ⟨_, .eql hx1 hy1 hT1, Etas.eql hx2 hy2 hT2⟩
  | rwt _ _ _ ihe ihP ihf =>
    obtain ⟨_, he1, he2⟩ := ihe; obtain ⟨_, hP1, hP2⟩ := ihP
    obtain ⟨_, hf1, hf2⟩ := ihf
    exact ⟨_, .rwt he1 hP1 hf1, Etas.rwt he2 hP2 hf2⟩
  | let_ _ _ ihv ihb =>
    obtain ⟨_, hv1, hv2⟩ := ihv; obtain ⟨_, hb1, hb2⟩ := ihb
    exact ⟨_, .let_ hv1 hb1, Etas.let_ hv2 hb2⟩
  | beta _ _ ihf iha =>
    obtain ⟨_, hf1, hf2⟩ := ihf; obtain ⟨_, ha1, ha2⟩ := iha
    exact ⟨_, .beta hf1 ha1, Etas.subst hf2 ha2⟩
  | letr _ _ ihv ihb =>
    obtain ⟨_, hv1, hv2⟩ := ihv; obtain ⟨_, hb1, hb2⟩ := ihb
    exact ⟨_, .letr hv1 hb1, Etas.subst hb2 hv2⟩
  | @dref k d s args' hk hsp hlen hpar ih =>
    obtain ⟨args₁, hlen1, h1⟩ := List.choose_getD _
      (fun i x => ParB β ((Term.spine s).2.getD i .Qnt) x ∧ Etas β x (args'.getD i .Qnt)) ih
    refine ⟨Term.apps d.body args₁, .dref hk hsp hlen1.symm (fun i hi => (h1 i hi).1), ?_⟩
    exact Etas.apps .refl (Pw.of_getD (by rw [hlen1, hlen])
      (fun i hi => (h1 i (by rwa [hlen1] at hi)).2))
  | aref hk h0 => exact ⟨_, .aref hk h0, .refl⟩
  | matc h1 h2 h3 h4 hps hph ihs ihh =>
    obtain ⟨_, hs1, hs2⟩ := ihs; obtain ⟨_, hh1, hh2⟩ := ihh
    obtain ⟨hh', _⟩ := hs1.spine_stable h3
    obtain ⟨_, hargs'⟩ := hs2.spine_stable hh' (by trivial)
    exact ⟨_, .matc h1 h2 h3 h4 hs1 hh1, Etas.apps hh2 (hargs'.drop _)⟩
  | matm h1 hne hps hphm ihs ihm =>
    obtain ⟨_, hs1, hs2⟩ := ihs; obtain ⟨_, hm1, hm2⟩ := ihm
    exact ⟨_, .matm h1 hne hs1 hm1, Etas.app hm2 hs2⟩
  | rwtr _ ih => obtain ⟨_, h1, h2⟩ := ih; exact ⟨_, .rwtr h1, h2⟩
  | minLM _ ih => obtain ⟨_, h1, h2⟩ := ih; exact ⟨_, .minLM h1, h2⟩
  | minLN => exact ⟨_, .minLN, .refl⟩
  | minRM _ ih => obtain ⟨_, h1, h2⟩ := ih; exact ⟨_, .minRM h1, h2⟩
  | minRN => exact ⟨_, .minRN, .refl⟩
  | minLL => exact ⟨_, .minLL, .refl⟩

-- ----------------------------------------------------------------------------
-- Par.strip: a parallel step against a strong run (B's diamond, iterated)
-- ----------------------------------------------------------------------------

theorem Par.strip (hβ : Book.Closed β) (hp : Par β t t₁) (hr : Red β .strong t u) :
    ∃ w, Red β .strong t₁ w ∧ Par β u w := by
  obtain ⟨w, h1, h2⟩ := ParRed.strip hβ hp (ParRed.of_red hr)
  exact ⟨w, h1.red hβ, h2⟩

-- ----------------------------------------------------------------------------
-- ParE: parallel eta (B's Par restricted to congruences and eta). It is
-- the tile for commuting eta chains with eta-free steps: a sequential Etas
-- does not tile (a beta copies its argument's etas), a parallel one does.
-- ----------------------------------------------------------------------------

inductive ParE (β : Book) : Term → Term → Prop
  | var  : ParE β (.Var i) (.Var i)
  | ref  : ParE β (.Ref k) (.Ref k)
  | typ  : ParE β g g' → ParE β (.Typ g) (.Typ g')
  | qnt  : ParE β .Qnt .Qnt
  | qua  : ParE β (.Qua q) (.Qua q)
  | min  : ParE β a a' → ParE β b b' → ParE β (.Min a b) (.Min a' b')
  | adt  : ParE β (.Adt a r) (.Adt a r)
  | ctr  : ParE β (.Ctr a c) (.Ctr a c)
  | efq  : ParE β .Efq .Efq
  | rfl  : ParE β .Rfl .Rfl
  | all  : ParE β A A' → ParE β B B' → ParE β (.All q A B) (.All q A' B')
  | eta  : Term.occ 0 F = 0 → ParE β F F' →
           ParE β (.Lam (.App F (.Var 0))) (Term.subst 0 .Qnt F')
  | lam  : ParE β f f' → ParE β (.Lam f) (.Lam f')
  | app  : ParE β f f' → ParE β a a' → ParE β (.App f a) (.App f' a')
  | mat  : ParE β h h' → ParE β m m' → ParE β (.Mat a c h m) (.Mat a c h' m')
  | eql  : ParE β x x' → ParE β y y' → ParE β T T' →
           ParE β (.Eql x y T) (.Eql x' y' T')
  | rwt  : ParE β e e' → ParE β P P' → ParE β f f' →
           ParE β (.Rwt e P f) (.Rwt e' P' f')
  | let_ : ParE β v v' → ParE β b b' → ParE β (.Let q v b) (.Let q v' b')

abbrev ParsE (β : Book) := Pw (ParE β)

theorem ParE.refl : ∀ (t : Term), ParE β t t := by
  intro t; induction t <;> constructor <;> assumption

theorem ParE.apps (hh : ParE β h h') (has : ParsE β as as') :
    ParE β (Term.apps h as) (Term.apps h' as') := by
  induction has generalizing h h' with
  | nil => exact hh
  | cons hp _ ih => exact ih (.app hh hp)

theorem ParE.par (h : ParE β a b) : Par β a b := by
  induction h <;> constructor <;> assumption

theorem Eta.parE (h : Eta β a b) : ParE β a b := by
  induction h <;> constructor <;> first | assumption | exact ParE.refl _

theorem ParE.etas (hβ : Book.Closed β) (h : ParE β a b) : Etas β a b := by
  induction h with
  | var => exact .refl
  | ref => exact .refl
  | typ _ ih => exact Etas.typ ih
  | qnt => exact .refl
  | qua => exact .refl
  | min _ _ iha ihb => exact Etas.min iha ihb
  | adt => exact .refl
  | ctr => exact .refl
  | efq => exact .refl
  | rfl => exact .refl
  | all _ _ ihA ihB => exact Etas.all ihA ihB
  | eta hocc hF ih =>
    exact (Etas.lam (Etas.app ih .refl)).trans
      (Star.one (.eta (Par.occ_zero hβ hF.par 0 hocc)))
  | lam _ ih => exact Etas.lam ih
  | app _ _ ihf iha => exact Etas.app ihf iha
  | mat _ _ ihh ihm => exact Etas.mat ihh ihm
  | eql _ _ _ ihx ihy ihT => exact Etas.eql ihx ihy ihT
  | rwt _ _ _ ihe ihP ihf => exact Etas.rwt ihe ihP ihf
  | let_ _ _ ihv ihb => exact Etas.let_ ihv ihb

theorem ParE.shift (hp : ParE β t t') : ∀ d, ParE β (t.shift d) (t'.shift d) := by
  induction hp with
  | @eta F F' hocc hF ih =>
    intro d
    show ParE β (.Lam (.App (Term.shift (d + 1) F) (Term.shift (d + 1) (.Var 0))))
      (Term.shift d (Term.subst 0 .Qnt F'))
    have h0 : Term.shift (d + 1) (Term.Var 0) = .Var 0 := by
      simp only [Term.shift]
      rw [if_pos (by omega)]
    have h1 : Term.shift d (Term.subst 0 .Qnt F')
        = Term.subst 0 .Qnt (Term.shift (d + 1) F') := by
      rw [Term.shift_subst_ge F' d 0 .Qnt (Nat.zero_le d)]
      rfl
    rw [h0, h1]
    exact .eta (by rw [Term.occ_shift_lt F 0 (d + 1) (by omega)]; exact hocc) (ih (d + 1))
  | var => intro d; simp only [Term.shift]; split <;> exact .var
  | ref => intro d; exact .ref
  | typ _ ih => intro d; exact .typ (ih d)
  | qnt => intro d; exact .qnt
  | qua => intro d; exact .qua
  | min _ _ iha ihb => intro d; exact .min (iha d) (ihb d)
  | adt => intro d; exact .adt
  | ctr => intro d; exact .ctr
  | efq => intro d; exact .efq
  | rfl => intro d; exact .rfl
  | all _ _ ihA ihB => intro d; exact .all (ihA d) (ihB (d + 1))
  | lam _ ihf => intro d; exact .lam (ihf (d + 1))
  | app _ _ ihf iha => intro d; exact .app (ihf d) (iha d)
  | mat _ _ ihh ihm => intro d; exact .mat (ihh d) (ihm d)
  | eql _ _ _ ihx ihy ihT => intro d; exact .eql (ihx d) (ihy d) (ihT d)
  | rwt _ _ _ ihe ihP ihf => intro d; exact .rwt (ihe d) (ihP d) (ihf d)
  | let_ _ _ ihv ihb => intro d; exact .let_ (ihv d) (ihb (d + 1))

theorem ParE.subst (hp : ParE β t t') :
    ∀ d {w w'}, ParE β w w' → ParE β (Term.subst d w t) (Term.subst d w' t') := by
  induction hp with
  | @eta F F' hocc hF ih =>
    intro d w w' hw
    show ParE β (.Lam (.App (Term.subst (d + 1) (Term.shift 0 w) F)
      (Term.subst (d + 1) (Term.shift 0 w) (.Var 0))))
      (Term.subst d w' (Term.subst 0 .Qnt F'))
    have h0 : Term.subst (d + 1) (Term.shift 0 w) (Term.Var 0) = .Var 0 := by
      simp only [Term.subst]
      rw [if_neg (by omega), if_neg (by omega)]
    have h1 : Term.subst d w' (Term.subst 0 .Qnt F')
        = Term.subst 0 .Qnt (Term.subst (d + 1) (Term.shift 0 w') F') := by
      rw [Term.subst_subst0 F' w' .Qnt d]
      rfl
    rw [h0, h1]
    refine .eta ?_ (ih (d + 1) (hw.shift 0))
    exact Term.occ_subst_lt_zero F (d + 1) 0 (Term.shift 0 w) (by omega)
      hocc (Term.occ_shift_self w 0)
  | var =>
    intro d w w' hw
    simp only [Term.subst]
    split
    · exact hw
    · split <;> exact .var
  | ref => intro d w w' _; exact .ref
  | typ _ ih => intro d w w' hw; exact .typ (ih d hw)
  | qnt => intro d w w' _; exact .qnt
  | qua => intro d w w' _; exact .qua
  | min _ _ iha ihb => intro d w w' hw; exact .min (iha d hw) (ihb d hw)
  | adt => intro d w w' _; exact .adt
  | ctr => intro d w w' _; exact .ctr
  | efq => intro d w w' _; exact .efq
  | rfl => intro d w w' _; exact .rfl
  | all _ _ ihA ihB => intro d w w' hw; exact .all (ihA d hw) (ihB (d + 1) (hw.shift 0))
  | lam _ ihf => intro d w w' hw; exact .lam (ihf (d + 1) (hw.shift 0))
  | app _ _ ihf iha => intro d w w' hw; exact .app (ihf d hw) (iha d hw)
  | mat _ _ ihh ihm => intro d w w' hw; exact .mat (ihh d hw) (ihm d hw)
  | eql _ _ _ ihx ihy ihT => intro d w w' hw; exact .eql (ihx d hw) (ihy d hw) (ihT d hw)
  | rwt _ _ _ ihe ihP ihf => intro d w w' hw; exact .rwt (ihe d hw) (ihP d hw) (ihf d hw)
  | let_ _ _ ihv ihb => intro d w w' hw; exact .let_ (ihv d hw) (ihb (d + 1) (hw.shift 0))

theorem ParE.leaf_spine_inv (hp : ParE β s t) :
    ∀ {h : Term} {as : List Term}, h.IsLeaf → s = Term.apps h as →
    ∃ as', t = Term.apps h as' ∧ ParsE β as as' := by
  induction hp <;> intro h as hl heq
  all_goals try
    exact absurd heq.symm (Term.apps_ne hl.isHead (by trivial) (fun e => by subst e; exact hl.elim))
  all_goals try (obtain ⟨h1, h2⟩ := Term.apps_head_inv (by trivial) hl.isHead (xs := []) heq
                 cases h1; cases h2; exact ⟨[], _root_.rfl, .nil⟩)
  case app _ _ _ _ hf ha ihf _ =>
    obtain ⟨ys, hys, hfy⟩ := Term.app_eq_apps hl.isHead heq
    obtain ⟨ys', hy1, hy2⟩ := ihf hl hfy
    subst hys hy1
    exact ⟨ys' ++ [_], (Term.apps_snoc _ _ _).symm, Pw.append hy2 (.cons ha .nil)⟩

theorem ParE.spine_stable (hp : ParE β s t) (hh : (Term.spine s).1 = h) (hl : h.IsLeaf) :
    (Term.spine t).1 = h ∧ ParsE β (Term.spine s).2 (Term.spine t).2 :=
  Term.spine_stable (fun hp e => hp.leaf_spine_inv hl e) hl.isHead hp hh

-- ----------------------------------------------------------------------------
-- the tile: a parallel eta against one eta-free step. Induction on the size
-- of the source (the lam/eta/app_f case needs the step two levels down).
-- ----------------------------------------------------------------------------

theorem ParE.commute_aux (hβ : Book.Closed β) : ∀ (n : Nat) (u u' v : Term),
    Term.size u ≤ n → StepB β u u' → ParE β u v →
    ∃ v', RedB β v v' ∧ ParE β u' v' := by
  intro n
  induction n with
  | zero => intro u u' v hn _ _; exact absurd hn (by have := Term.size_pos u; omega)
  | succ n ih =>
    intro u u' v hn s hv
    cases s with
    | @beta f a =>
      cases hv with
      | app hL ha =>
        cases hL with
        | lam hf => exact ⟨_, Star.one .beta, hf.subst 0 ha⟩
        | @eta F F' hocc hF =>
          refine ⟨_, .refl, ?_⟩
          have h0 : Term.subst 0 a (.Var 0) = a := by simp [Term.subst]
          show ParE β (.App (Term.subst 0 a F) (Term.subst 0 a (.Var 0))) _
          rw [h0, Term.occ_zero_subst_irrel F 0 a .Qnt hocc]
          exact .app (hF.subst 0 .qnt) ha
    | let_ =>
      cases hv with
      | let_ hv' hb => exact ⟨_, Star.one .let_, hb.subst 0 hv'⟩
    | @dref k d s hk hsp =>
      obtain ⟨hh, hargs⟩ := hv.spine_stable hsp (by trivial)
      exact ⟨_, Star.one (.dref hk hh), ParE.apps (ParE.refl d.body) hargs⟩
    | aref hk h0 =>
      cases hv
      exact ⟨_, Star.one (.aref hk h0), ParE.refl _⟩
    | @matc a A c C h m ps xs h1 h2 h3 h4 =>
      cases hv with
      | app hM hS =>
        cases hM with
        | mat hh hm =>
          obtain ⟨ys, rfl, hys⟩ := hS.leaf_spine_inv (by trivial) _root_.rfl
          obtain ⟨ps', xs', rfl, hps, hxs⟩ := hys.append_inv
          exact ⟨_, Star.one (.matc h1 h2 (by rw [← hps.length]; exact h3)
            (by rw [← hxs.length]; exact h4)), ParE.apps hh hxs⟩
    | @matm a' c' a c h m as hne =>
      cases hv with
      | app hM hS =>
        cases hM with
        | mat hh hm =>
          obtain ⟨ys, rfl, hys⟩ := hS.leaf_spine_inv (by trivial) _root_.rfl
          exact ⟨_, Star.one (.matm hne), .app hm (ParE.apps .ctr hys)⟩
    | rwt =>
      cases hv with
      | rwt he hP hf => cases he; exact ⟨_, Star.one .rwt, hf⟩
    | minLM =>
      cases hv with
      | min ha hb => cases ha; exact ⟨_, Star.one .minLM, hb⟩
    | minLN =>
      cases hv with
      | min ha hb => cases ha; exact ⟨_, Star.one .minLN, .qua⟩
    | minRM =>
      cases hv with
      | min ha hb => cases hb; exact ⟨_, Star.one .minRM, ha⟩
    | minRN =>
      cases hv with
      | min ha hb => cases hb; exact ⟨_, Star.one .minRN, .qua⟩
    | minLL =>
      cases hv with
      | min ha hb => cases ha; cases hb; exact ⟨_, Star.one .minLL, .qua⟩
    | typ_g s' =>
      cases hv with
      | typ hg =>
        obtain ⟨_, h1, h2⟩ := ih _ _ _ (by simp [Term.size] at hn; omega) s' hg
        exact ⟨_, RedB.typ h1, .typ h2⟩
    | min_a s' =>
      cases hv with
      | min ha hb =>
        obtain ⟨_, h1, h2⟩ := ih _ _ _ (by simp [Term.size] at hn; omega) s' ha
        exact ⟨_, RedB.min h1 .refl, .min h2 hb⟩
    | min_b s' =>
      cases hv with
      | min ha hb =>
        obtain ⟨_, h1, h2⟩ := ih _ _ _ (by simp [Term.size] at hn; omega) s' hb
        exact ⟨_, RedB.min .refl h1, .min ha h2⟩
    | all_a s' =>
      cases hv with
      | all hA hB =>
        obtain ⟨_, h1, h2⟩ := ih _ _ _ (by simp [Term.size] at hn; omega) s' hA
        exact ⟨_, RedB.all h1 .refl, .all h2 hB⟩
    | all_b s' =>
      cases hv with
      | all hA hB =>
        obtain ⟨_, h1, h2⟩ := ih _ _ _ (by simp [Term.size] at hn; omega) s' hB
        exact ⟨_, RedB.all .refl h1, .all hA h2⟩
    | lam_f s' =>
      cases hv with
      | lam hf =>
        obtain ⟨_, h1, h2⟩ := ih _ _ _ (by simp [Term.size] at hn; omega) s' hf
        exact ⟨_, RedB.lam h1, .lam h2⟩
      | @eta F F' hocc hF =>
        generalize hx : Term.Var 0 = x at s'
        cases s' with
        | app_f hF2 =>
          subst hx
          obtain ⟨F₃, h1, h2⟩ := ih _ _ _ (by simp [Term.size] at hn; omega) hF2 hF
          exact ⟨_, RedB.subst hβ h1 0 .Qnt, .eta (Par.occ_zero hβ hF2.par.par 0 hocc) h2⟩
        | app_a hx' =>
          subst hx
          cases hx' with
          | dref _ hsp => simp [Term.spine] at hsp
        | @beta F₀ _ =>
          subst hx
          cases hF with
          | lam hF₀ =>
            refine ⟨_, .refl, ?_⟩
            show ParE β (.Lam (Term.subst 0 (.Var 0) F₀)) (.Lam (Term.subst 1 .Qnt _))
            rw [Term.subst_var_eq_subst_above F₀ 0 .Qnt hocc]
            exact .lam (hF₀.subst 1 .qnt)
          | @eta F₀₀ F₀₀' hocc₀ hF₀₀ =>
            refine ⟨_, .refl, ?_⟩
            have h0 : Term.subst 0 (.Var 0) (.Var 0) = .Var 0 := by simp [Term.subst]
            show ParE β
              (.Lam (.App (Term.subst 0 (.Var 0) F₀₀) (Term.subst 0 (.Var 0) (.Var 0)))) _
            rw [h0, Term.occ_zero_subst_irrel F₀₀ 0 (.Var 0) .Qnt hocc₀]
            have hocc1 : Term.occ 1 F₀₀ = 0 := by simp [Term.occ] at hocc; exact hocc
            exact .eta (Term.occ_subst_zero F₀₀ 0 0 .Qnt (Nat.le_refl 0) hocc1 _root_.rfl)
              (hF₀₀.subst 0 .qnt)
        | @dref k d _ hk hsp =>
          subst hx
          simp only [Term.spine] at hsp
          have hcl := (hβ.defn hk).2
          obtain ⟨hh', hargs⟩ := hF.spine_stable hsp (by trivial)
          have hFeq : F = Term.apps (.Ref k) (Term.spine F).2 := by
            rw [← hsp]; exact (Term.apps_spine F).symm
          have hocc' : Term.occ 0 (Term.apps d.body (Term.spine F).2) = 0 := by
            rw [Term.occ_apps, Term.occ_closed d.body 0 0 hcl (Nat.le_refl 0)]
            rw [hFeq, Term.occ_apps] at hocc; simp only [Term.occ] at hocc; omega
          obtain ⟨as', has'⟩ : ∃ as', (Term.spine F').2 = as' := ⟨_, _root_.rfl⟩
          have hF'eq : F' = Term.apps (.Ref k) as' := by
            rw [← has', ← hh']; exact (Term.apps_spine F').symm
          rw [has'] at hargs
          subst hF'eq
          have hstep : StepB β (Term.subst 0 .Qnt (Term.apps (.Ref k) as'))
              (Term.subst 0 .Qnt (Term.apps d.body as')) := by
            rw [Term.subst_apps_closed 0 .Qnt hcl, Term.subst_apps]
            simp only [Term.subst]
            exact StepB.dref_apps hk _
          refine ⟨_, Star.one hstep, ?_⟩
          simp only [Term.spine]
          rw [Term.apps_snoc]
          exact .eta hocc' (ParE.apps (ParE.refl d.body) hargs)
        | matc h1 h2 h3 h4 =>
          exact absurd hx
            (Term.apps_ne (by trivial) (by trivial) (fun h => Term.noConfusion h)).symm
        | matm hne =>
          exact absurd hx
            (Term.apps_ne (by trivial) (by trivial) (fun h => Term.noConfusion h)).symm
    | app_f s' =>
      cases hv with
      | app hf ha =>
        obtain ⟨_, h1, h2⟩ := ih _ _ _ (by simp [Term.size] at hn; omega) s' hf
        exact ⟨_, RedB.app h1 .refl, .app h2 ha⟩
    | app_a s' =>
      cases hv with
      | app hf ha =>
        obtain ⟨_, h1, h2⟩ := ih _ _ _ (by simp [Term.size] at hn; omega) s' ha
        exact ⟨_, RedB.app .refl h1, .app hf h2⟩
    | mat_h s' =>
      cases hv with
      | mat hh hm =>
        obtain ⟨_, h1, h2⟩ := ih _ _ _ (by simp [Term.size] at hn; omega) s' hh
        exact ⟨_, RedB.mat h1 .refl, .mat h2 hm⟩
    | mat_m s' =>
      cases hv with
      | mat hh hm =>
        obtain ⟨_, h1, h2⟩ := ih _ _ _ (by simp [Term.size] at hn; omega) s' hm
        exact ⟨_, RedB.mat .refl h1, .mat hh h2⟩
    | eql_a s' =>
      cases hv with
      | eql hx hy hT =>
        obtain ⟨_, h1, h2⟩ := ih _ _ _ (by simp [Term.size] at hn; omega) s' hx
        exact ⟨_, RedB.eql h1 .refl .refl, .eql h2 hy hT⟩
    | eql_b s' =>
      cases hv with
      | eql hx hy hT =>
        obtain ⟨_, h1, h2⟩ := ih _ _ _ (by simp [Term.size] at hn; omega) s' hy
        exact ⟨_, RedB.eql .refl h1 .refl, .eql hx h2 hT⟩
    | eql_t s' =>
      cases hv with
      | eql hx hy hT =>
        obtain ⟨_, h1, h2⟩ := ih _ _ _ (by simp [Term.size] at hn; omega) s' hT
        exact ⟨_, RedB.eql .refl .refl h1, .eql hx hy h2⟩
    | rwt_e s' =>
      cases hv with
      | rwt he hP hf =>
        obtain ⟨_, h1, h2⟩ := ih _ _ _ (by simp [Term.size] at hn; omega) s' he
        exact ⟨_, RedB.rwt h1 .refl .refl, .rwt h2 hP hf⟩
    | rwt_p s' =>
      cases hv with
      | rwt he hP hf =>
        obtain ⟨_, h1, h2⟩ := ih _ _ _ (by simp [Term.size] at hn; omega) s' hP
        exact ⟨_, RedB.rwt .refl h1 .refl, .rwt he h2 hf⟩
    | rwt_f s' =>
      cases hv with
      | rwt he hP hf =>
        obtain ⟨_, h1, h2⟩ := ih _ _ _ (by simp [Term.size] at hn; omega) s' hf
        exact ⟨_, RedB.rwt .refl .refl h1, .rwt he hP h2⟩
    | let_v s' =>
      cases hv with
      | let_ hv' hb =>
        obtain ⟨_, h1, h2⟩ := ih _ _ _ (by simp [Term.size] at hn; omega) s' hv'
        exact ⟨_, RedB.let_ h1 .refl, .let_ h2 hb⟩
    | let_b s' =>
      cases hv with
      | let_ hv' hb =>
        obtain ⟨_, h1, h2⟩ := ih _ _ _ (by simp [Term.size] at hn; omega) s' hb
        exact ⟨_, RedB.let_ .refl h1, .let_ hv' h2⟩

theorem ParE.commute (hβ : Book.Closed β) (hv : ParE β u v) (s : StepB β u u') :
    ∃ v', RedB β v v' ∧ ParE β u' v' :=
  ParE.commute_aux hβ _ u u' v (Nat.le_refl _) s hv

theorem ParE.commute_red (hβ : Book.Closed β) (hv : ParE β u v) (r : RedB β u u') :
    ∃ v', RedB β v v' ∧ ParE β u' v' := by
  induction r generalizing v with
  | refl => exact ⟨v, .refl, hv⟩
  | step s _ ih =>
    obtain ⟨w, h1, h2⟩ := ParE.commute hβ hv s
    obtain ⟨v', h3, h4⟩ := ih h2
    exact ⟨v', h1.trans h3, h4⟩

-- eta contractions never block an eta-free run: the reduct of the source
-- is matched, modulo etas, by a reduct of the eta-contracted term
theorem EtaB.commute_red (hβ : Book.Closed β) (he : Etas β u v) (r : RedB β u u') :
    ∃ v', RedB β v v' ∧ Etas β u' v' := by
  induction he generalizing u' with
  | refl => exact ⟨u', r, .refl⟩
  | step e _ ih =>
    obtain ⟨w, h1, h2⟩ := ParE.commute_red hβ e.parE r
    obtain ⟨v', h3, h4⟩ := ih h1
    exact ⟨v', h3, (h2.etas hβ).trans h4⟩

-- term-algebra helpers for the towers
theorem List.eq_nil_or_snoc (l : List Term) : l = [] ∨ ∃ L b, l = L ++ [b] := by
  rcases List.eq_nil_or_concat l with h | ⟨L, b, h⟩
  · exact .inl h
  · exact .inr ⟨L, b, by rw [h, List.concat_eq_append]⟩

theorem Term.map_shiftN_zero (ps : List Term) : ps.map (Term.shiftN 0) = ps := by
  induction ps <;> simp [Term.shiftN, *]

theorem Term.shiftN_var0 : ∀ n, Term.shiftN n (.Var 0) = .Var n
  | 0 => rfl
  | n + 1 => by
    show Term.shift 0 (Term.shiftN n (.Var 0)) = _
    rw [Term.shiftN_var0 n]; simp [Term.shift]

theorem Term.shiftN_succ' : ∀ (n : Nat) (t : Term),
    Term.shiftN (n + 1) t = Term.shift n (Term.shiftN n t)
  | 0, _ => rfl
  | n + 1, t => by
    have h := Term.shift_shift (Term.shiftN n t) 0 n (Nat.zero_le n)
    rwa [← Term.shiftN_succ' n t] at h

theorem Term.subst_shiftN_succ (n : Nat) (w p : Term) :
    Term.subst n w (Term.shiftN (n + 1) p) = Term.shiftN n p := by
  rw [Term.shiftN_succ', Term.subst_shift]

theorem Term.map_subst_rvars : ∀ (n m : Nat) (w : Term), n ≤ m →
    (Term.rvars n).map (Term.subst m w) = Term.rvars n
  | 0, _, _, _ => rfl
  | n + 1, m, w, h => by
    show Term.subst m w (.Var n) :: (Term.rvars n).map (Term.subst m w) = .Var n :: Term.rvars n
    rw [Term.map_subst_rvars n m w (by omega)]
    simp only [Term.subst]; rw [if_neg (by omega), if_neg (by omega)]

theorem Term.subst_lams : ∀ (n d : Nat) (w t : Term),
    Term.subst d w (Term.lams n t) = Term.lams n (Term.subst (d + n) (Term.shiftN n w) t)
  | 0, _, _, _ => rfl
  | n + 1, d, w, t => by
    show Term.Lam (Term.subst (d + 1) (Term.shift 0 w) (Term.lams n t))
      = Term.Lam (Term.lams n (Term.subst (d + (n + 1)) (Term.shiftN (n + 1) w) t))
    rw [Term.subst_lams n, Term.shiftN_shift0, show d + 1 + n = d + (n + 1) by omega]

theorem Term.lams_succ' : ∀ (n : Nat) (t : Term), Term.lams (n + 1) t = Term.lams n (.Lam t)
  | 0, _ => rfl
  | n + 1, t => by
    show Term.Lam (Term.lams (n + 1) t) = Term.Lam (Term.lams n (.Lam t)); rw [Term.lams_succ' n t]

theorem Term.map_shift_rvars :
    ∀ n, (Term.rvars n).map (Term.shift 0) ++ [.Var 0] = Term.rvars (n + 1)
  | 0 => rfl
  | n + 1 => by
    show Term.shift 0 (.Var n) :: ((Term.rvars n).map (Term.shift 0) ++ [.Var 0])
      = .Var (n + 1) :: Term.rvars (n + 1)
    rw [Term.map_shift_rvars n]; simp [Term.shift]

theorem Term.shiftN_apps : ∀ (n : Nat) (h : Term) (ps : List Term),
    Term.shiftN n (Term.apps h ps) = Term.apps (Term.shiftN n h) (ps.map (Term.shiftN n))
  | 0, h, ps => by rw [Term.map_shiftN_zero]; rfl
  | n + 1, h, ps => by
    show Term.shift 0 (Term.shiftN n (Term.apps h ps)) = _
    rw [Term.shiftN_apps n, Term.shift_apps, List.map_map]; rfl

theorem Term.IsHead.shift {t : Term} (h : t.IsHead) (d : Nat) : (Term.shift d t).IsHead := by
  cases t with
  | Var i => simp only [Term.shift]; split <;> trivial
  | App f a => exact h.elim
  | _ => trivial

-- n nested eta-expansions of a term contract to it (innermost first)
theorem Etas.lams_rvars : ∀ (n : Nat) (t : Term),
    Etas β (Term.lams n (Term.apps (Term.shiftN n t) (Term.rvars n))) t := by
  intro n
  induction n with
  | zero => intro t; exact .refl
  | succ n ih =>
    intro t
    rw [Term.lams_succ', ← Term.map_shift_rvars, Term.apps_snoc, ← Term.shiftN_succ,
      ← Term.shift_apps]
    exact (Star.lams Etas.lam n (Star.one (Eta.expand _))).trans (ih t)

-- a tower: an eta source of a spine, once its inner eta-expansions are peeled
-- by betas, is lams n (apps h' qs) with the last n arguments eta-chains to
-- Var (n-1) .. Var 0 and the head one congruence layer from the shifted target
def Tow (β : Book) (h : Term) (ps : List Term) (w : Term) : Prop :=
  ∃ n qs h', w = Term.lams n (Term.apps h' qs) ∧ EtasC β h' (Term.shiftN n h) ∧
    Etass β qs (ps.map (Term.shiftN n) ++ Term.rvars n)

theorem Tow.cases (ht : Tow β h ps w) :
    (∃ Z, w = .Lam Z) ∨
      ∃ h' qs, w = Term.apps h' qs ∧ EtasC β h' h ∧ Etass β qs ps := by
  obtain ⟨n, qs, h', rfl, hh, hqs⟩ := ht
  cases n with
  | zero =>
    simp only [Term.map_shiftN_zero, Term.rvars, List.append_nil] at hqs
    exact .inr ⟨h', qs, _root_.rfl, hh, hqs⟩
  | succ n => exact .inl ⟨_, _root_.rfl⟩

theorem Tow.mono (ht : Tow β h ps w) (hp : Etass β ps ps') : Tow β h ps' w := by
  obtain ⟨n, qs, h', rfl, hh, hqs⟩ := ht
  exact ⟨n, qs, h', _root_.rfl, hh,
    Pw.trans Star.trans hqs
      (Pw.append (Pw.map (Term.shiftN n) (fun e => e.shiftN n) hp) (Pw.star_refl _))⟩

-- applying a tower to an argument peels one layer by a beta
theorem Tow.peel (ht : Tow β h ps w) (a : Term) :
    ∃ w', RedB β (.App w a) w' ∧ Tow β h (ps ++ [a]) w' := by
  obtain ⟨n, qs, h', rfl, hh, hqs⟩ := ht
  cases n with
  | zero =>
    refine ⟨_, .refl, 0, qs ++ [a], h', (Term.apps_snoc _ _ _).symm, hh, ?_⟩
    simp only [Term.map_shiftN_zero, Term.rvars, List.append_nil] at hqs ⊢
    exact Pw.append hqs (.cons .refl .nil)
  | succ n =>
    refine ⟨_, Star.one .beta, n, qs.map (Term.subst n (Term.shiftN n a)),
      Term.subst n (Term.shiftN n a) h', ?_, ?_, ?_⟩
    · show Term.subst 0 a (Term.lams n (Term.apps h' qs)) = _
      rw [Term.subst_lams, Term.subst_apps]
      simp only [Nat.zero_add]
    · have := hh.subst1 n (Term.shiftN n a)
      rwa [Term.subst_shiftN_succ] at this
    · have := Pw.map (Term.subst n (Term.shiftN n a)) (fun e => e.subst1 _ _) hqs
      simp only [List.map_append, List.map_map, Term.rvars, List.map_cons] at this
      rw [Term.map_subst_rvars n n _ (Nat.le_refl n)] at this
      have e1 : (Term.subst n (Term.shiftN n a) ∘ Term.shiftN (n + 1)) = Term.shiftN n :=
        funext fun p => Term.subst_shiftN_succ n _ p
      have e2 : Term.subst n (Term.shiftN n a) (.Var n) = Term.shiftN n a := by simp [Term.subst]
      rw [e1, e2] at this
      simpa [List.map_append] using this

-- the peeling theorem: an eta source of a spine B-reduces to a tower over it
theorem Etas.peel : ∀ (u h : Term) (ps : List Term), h.IsHead → Etas β u (Term.apps h ps) →
    ∃ w, RedB β u w ∧ Tow β h ps w := by
  intro u
  induction u with
  | Lam X ih =>
    intro h ps hh he
    rcases he.inv with hc | ⟨Z, F, hZ, h1, h2, h3⟩
    · rcases List.eq_nil_or_snoc ps with rfl | ⟨ps₀, p, rfl⟩
      · exact ⟨_, .refl, 0, [], _, _root_.rfl, hc, .nil⟩
      · rw [Term.apps_snoc] at hc; cases hc
    · cases hZ
      have hF : Etas β F (Term.apps (Term.shift 0 h) (ps.map (Term.shift 0))) := by
        have := h3.shift 0
        rwa [Term.shift_subst_occ F 0 .Qnt h2, Term.shift_apps] at this
      have hX : Etas β X (Term.apps (Term.shift 0 h) (ps.map (Term.shift 0) ++ [.Var 0])) := by
        rw [Term.apps_snoc]; exact h1.trans (Etas.app hF .refl)
      obtain ⟨w₀, h4, h5⟩ := ih _ _ (hh.shift 0) hX
      obtain ⟨n, qs, h', rfl, hh', hqs⟩ := h5
      refine ⟨_, RedB.lam h4, n + 1, qs, h', _root_.rfl, ?_, ?_⟩
      · rwa [Term.shiftN_shift0] at hh'
      · simp only [List.map_append, List.map_map, List.map_cons, List.map_nil,
          Term.shiftN_var0] at hqs
        have e1 : (Term.shiftN n ∘ Term.shift 0) = Term.shiftN (n + 1) :=
          funext fun p => Term.shiftN_shift0 n p
        rw [e1] at hqs
        simpa [Term.rvars] using hqs
  | App u₁ u₂ ih₁ _ =>
    intro h ps hh he
    rcases he.inv with hc | ⟨Z, F, hZ, -⟩
    · rcases List.eq_nil_or_snoc ps with rfl | ⟨ps₀, p, rfl⟩
      · exact ⟨_, .refl, 0, [], _, _root_.rfl, hc, .nil⟩
      · rw [Term.apps_snoc] at hc
        cases hc with
        | app hf hx =>
          obtain ⟨w₁, h4, h5⟩ := ih₁ h ps₀ hh hf
          obtain ⟨w', h6, h7⟩ := h5.peel u₂
          exact ⟨w', (RedB.app h4 .refl).trans h6,
            h7.mono (Pw.append (Pw.star_refl _) (.cons hx .nil))⟩
    · cases hZ
  | _ =>
    intro h ps hh he
    rcases he.inv with hc | ⟨Z, F, hZ, -⟩
    · rcases List.eq_nil_or_snoc ps with rfl | ⟨ps₀, p, rfl⟩
      · exact ⟨_, .refl, 0, [], _, _root_.rfl, hc, .nil⟩
      · rw [Term.apps_snoc] at hc; cases hc
    · cases hZ

theorem Etas.beta_commute_aux (hβ : Book.Closed β) : ∀ (u : Term),
    (∀ g a us, Etas β u (Term.apps (.App (.Lam g) a) us) →
      ∃ u', RedB β u u' ∧ Etas β u' (Term.apps (Term.subst 0 a g) us)) ∧
    (∀ g, Etas β u (.Lam g) → ∀ a,
      ∃ g₀, RedB β (.App u a) (Term.subst 0 a g₀) ∧ Etas β g₀ g) := by
  intro u
  induction u with
  | Lam X ih =>
    refine ⟨fun g a us h => ?_, fun g h a => ?_⟩
    · rcases h.inv with hc | ⟨Z, F, hZ, h1, h2, h3⟩
      · exfalso
        rcases List.eq_nil_or_snoc us with rfl | ⟨us₀, x, rfl⟩
        · simp only [Term.apps] at hc; cases hc
        · rw [Term.apps_snoc] at hc; cases hc
      · cases hZ
        have hF : Etas β F (Term.apps (.App (.Lam (Term.shift 1 g)) (Term.shift 0 a))
            (us.map (Term.shift 0))) := by
          have := h3.shift 0
          rwa [Term.shift_subst_occ F 0 .Qnt h2, Term.shift_apps] at this
        have hX : Etas β X (Term.apps (.App (.Lam (Term.shift 1 g)) (Term.shift 0 a))
            (us.map (Term.shift 0) ++ [.Var 0])) := by
          rw [Term.apps_snoc]; exact h1.trans (Etas.app hF .refl)
        obtain ⟨X', h4, h5⟩ := ih.1 _ _ _ hX
        refine ⟨.Lam X', RedB.lam h4, ?_⟩
        have h6 : Etas β (.Lam X')
            (.Lam (.App (Term.shift 0 (Term.apps (Term.subst 0 a g) us)) (.Var 0))) := by
          apply Etas.lam
          rw [Term.shift_apps, Term.shift_subst0, ← Term.apps_snoc]
          exact h5
        exact h6.trans (Star.one (Eta.expand _))
    · rcases h.inv with hc | ⟨Z, F, hZ, h1, h2, h3⟩
      · cases hc with
        | lam hX => exact ⟨X, Star.one .beta, hX⟩
      · cases hZ
        have hF : Etas β F (.Lam (Term.shift 1 g)) := by
          have := h3.shift 0; rwa [Term.shift_subst_occ F 0 .Qnt h2] at this
        have hX : Etas β X (Term.apps (.App (.Lam (Term.shift 1 g)) (.Var 0)) []) :=
          h1.trans (Etas.app hF .refl)
        obtain ⟨X', h4, h5⟩ := ih.1 _ _ _ hX
        refine ⟨X', (Star.one .beta).trans (RedB.subst hβ h4 0 a), ?_⟩
        rw [Term.subst_var_eq_subst_above _ 0 .Qnt (Term.occ_shift_self g 1),
          Term.subst_shift] at h5
        exact h5
  | App u₁ u₂ ih₁ _ =>
    refine ⟨fun g a us h => ?_, fun g h a => ?_⟩
    · rcases h.inv with hc | ⟨Z, F, hZ, -⟩
      · rcases List.eq_nil_or_snoc us with rfl | ⟨us₀, x, rfl⟩
        · simp only [Term.apps] at hc
          cases hc with
          | app hf ha =>
            obtain ⟨g₀, h4, h5⟩ := ih₁.2 g hf u₂
            exact ⟨_, h4, Etas.subst h5 ha⟩
        · rw [Term.apps_snoc] at hc
          cases hc with
          | app hf hx =>
            obtain ⟨u₁', h4, h5⟩ := ih₁.1 g a us₀ hf
            rw [Term.apps_snoc]
            exact ⟨_, RedB.app h4 .refl, Etas.app h5 hx⟩
      · cases hZ
    · rcases h.inv with hc | ⟨Z, F, hZ, -⟩
      · cases hc
      · cases hZ
  | _ =>
    refine ⟨fun g a us h => ?_, fun g h a => ?_⟩ <;> rcases h.inv with hc | ⟨Z, F, hZ, -⟩
    · rcases List.eq_nil_or_snoc us with rfl | ⟨us₀, x, rfl⟩
      · simp only [Term.apps] at hc; cases hc
      · rw [Term.apps_snoc] at hc; cases hc
    · cases hZ
    · cases hc
    · cases hZ

theorem Tower.peel (hβ : Book.Closed β) (h : Etas β F (.Lam g)) (a : Term) :
    ∃ g₀, RedB β (.App F a) (Term.subst 0 a g₀) ∧ Etas β g₀ g :=
  (Etas.beta_commute_aux hβ F).2 g h a

-- ----------------------------------------------------------------------------
-- a run from an applied variable: steps inside the function are steps of the
-- unshifted term; a root beta makes a Lam; a root dref stays an applied
-- variable
-- ----------------------------------------------------------------------------

theorem AppVar.reduct_aux (hβ : Book.Closed β) (r : RedB β u w) :
    ∀ F, u = .App F (.Var 0) → Term.occ 0 F = 0 →
    ∃ v', RedB β (Term.subst 0 .Qnt F) v' ∧ Etas β (.Lam w) v' := by
  induction r with
  | refl => intro F hu hocc; subst hu; exact ⟨_, .refl, Star.one (.eta hocc)⟩
  | step s r ih =>
    intro F hu hocc
    subst hu
    generalize hx : Term.Var 0 = x at s
    cases s with
    | app_f hF =>
      subst hx
      obtain ⟨v', h1, h2⟩ := ih _ _root_.rfl (Par.occ_zero hβ hF.par.par 0 hocc)
      exact ⟨v', (Star.one (hF.subst hβ 0 .Qnt)).trans h1, h2⟩
    | app_a hx' =>
      subst hx
      cases hx' with
      | dref _ hsp => simp [Term.spine] at hsp
    | @beta f _ =>
      subst hx
      refine ⟨.Lam _, ?_, .refl⟩
      show RedB β (.Lam (Term.subst (0 + 1) .Qnt f)) (.Lam _)
      rw [← Term.subst_var_eq_subst_above f 0 .Qnt hocc]
      exact RedB.lam r
    | @dref k d _ hk hsp =>
      subst hx
      simp only [Term.spine] at hsp
      have hcl := (hβ.defn hk).2
      have hFeq : F = Term.apps (.Ref k) (Term.spine F).2 := by
        rw [← hsp]; exact (Term.apps_spine F).symm
      have hocc' : Term.occ 0 (Term.apps d.body (Term.spine F).2) = 0 := by
        rw [Term.occ_apps, Term.occ_closed d.body 0 0 hcl (Nat.le_refl 0)]
        rw [hFeq, Term.occ_apps] at hocc; simp only [Term.occ] at hocc; omega
      obtain ⟨v', h1, h2⟩ := ih (Term.apps d.body (Term.spine F).2)
        (by simp only [Term.spine]; rw [Term.apps_snoc]) hocc'
      refine ⟨v', (Star.one ?_).trans h1, h2⟩
      obtain ⟨as', has'⟩ : ∃ as', (Term.spine F).2 = as' := ⟨_, _root_.rfl⟩
      rw [has'] at hFeq ⊢
      subst hFeq
      rw [Term.subst_apps_closed 0 .Qnt hcl, Term.subst_apps]
      simp only [Term.subst]
      exact StepB.dref_apps hk _
    | matc h1 h2 h3 h4 =>
      exact absurd hx (Term.apps_ne (by trivial) (by trivial) (fun h => Term.noConfusion h)).symm
    | matm hne =>
      exact absurd hx (Term.apps_ne (by trivial) (by trivial) (fun h => Term.noConfusion h)).symm

theorem AppVar.reduct (hβ : Book.Closed β) (r : RedB β (.App (Term.shift 0 v) (.Var 0)) w) :
    ∃ v', RedB β v v' ∧ Etas β (.Lam w) v' := by
  obtain ⟨v', h1, h2⟩ := AppVar.reduct_aux hβ r _ _root_.rfl (Term.occ_shift_self v 0)
  rw [Term.subst_shift] at h1
  exact ⟨v', h1, h2⟩

-- ----------------------------------------------------------------------------
-- §K5 preservation modulo eta (a typed source, an eta-reduct of it and one
-- eta-free parallel step of the reduct B-reduce to eta-related terms; hence
-- covering survives every strong step) and the kinds of what a Data-kinded
-- type reduces to, in any context
-- ----------------------------------------------------------------------------

theorem RedB.lam_inv (r : RedB β s w) :
    ∀ g, s = .Lam g → ∃ g', w = .Lam g' ∧ RedB β g g' := by
  induction r with
  | refl => intro g e; exact ⟨g, e, .refl⟩
  | step st _ ih =>
    intro g e
    subst e
    cases st with
    | lam_f s' =>
      obtain ⟨g', rfl, r'⟩ := ih _ _root_.rfl
      exact ⟨g', _root_.rfl, .step s' r'⟩
    | dref _ hs => simp [Term.spine] at hs

theorem RedB.mat_inv (r : RedB β s w) :
    ∀ {a c : Nat} (h m : Term), s = .Mat a c h m →
      ∃ h' m', w = .Mat a c h' m' ∧ RedB β h h' ∧ RedB β m m' := by
  induction r with
  | refl => intro a c h m e; exact ⟨h, m, e, .refl, .refl⟩
  | step st _ ih =>
    intro a c h m e
    subst e
    cases st with
    | mat_h s' =>
      obtain ⟨h', m', rfl, r1, r2⟩ := ih _ _ _root_.rfl
      exact ⟨h', m', _root_.rfl, .step s' r1, r2⟩
    | mat_m s' =>
      obtain ⟨h', m', rfl, r1, r2⟩ := ih _ _ _root_.rfl
      exact ⟨h', m', _root_.rfl, r1, .step s' r2⟩
    | dref _ hs => simp [Term.spine] at hs

theorem RedB.ctr_spine_inv (r : RedB β s t) :
    ∀ {a c : Nat} {as : List Term}, s = Term.apps (.Ctr a c) as →
      ∃ as', t = Term.apps (.Ctr a c) as' ∧ RedsB β as as' := by
  induction r with
  | refl => intro a c as e; exact ⟨as, e, Pw.star_refl _⟩
  | step st _ ih =>
    intro a c as e
    obtain ⟨as₁, e₁, h₁⟩ := ParB.ctr_spine_inv st.par e
    obtain ⟨as', e', h'⟩ := ih e₁
    exact ⟨as', e', Pw.trans Star.trans (h₁.mono ParB.red) h'⟩

theorem Term.rvars_length : ∀ n, (Term.rvars n).length = n
  | 0 => rfl
  | n + 1 => by simp [Term.rvars, Term.rvars_length n]

theorem Term.shiftN_mat : ∀ n,
    Term.shiftN n (.Mat a c h m) = .Mat a c (Term.shiftN n h) (Term.shiftN n m)
  | 0 => rfl
  | n + 1 => by simp only [Term.shiftN, Term.shiftN_mat n, Term.shift]

theorem Term.shiftN_app : ∀ n, Term.shiftN n (.App f a) = .App (Term.shiftN n f) (Term.shiftN n a)
  | 0 => rfl
  | n + 1 => by simp only [Term.shiftN, Term.shiftN_app n, Term.shift]

theorem Term.shiftN_all_ex : ∀ n, ∃ A' B', Term.shiftN n (.All q A B) = .All q A' B'
  | 0 => ⟨A, B, rfl⟩
  | n + 1 => by
    obtain ⟨A', B', e⟩ := Term.shiftN_all_ex (q := q) (A := A) (B := B) n
    exact ⟨Term.shift 0 A', Term.shift (0 + 1) B', by simp only [Term.shiftN, e, Term.shift]⟩

theorem Term.shiftN_typ_ex : ∀ n, ∃ g', Term.shiftN n (.Typ g) = .Typ g'
  | 0 => ⟨g, rfl⟩
  | n + 1 => by
    obtain ⟨g', e⟩ := Term.shiftN_typ_ex (g := g) n
    exact ⟨Term.shift 0 g', by simp only [Term.shiftN, e, Term.shift]⟩

theorem Term.apps_eq_lam : ∀ {ps : List Term} {h g : Term},
    Term.apps h ps = .Lam g → h = .Lam g ∧ ps = [] := by
  intro ps h g e
  rcases List.eq_nil_or_snoc ps with rfl | ⟨L, b, rfl⟩
  · exact ⟨e, _root_.rfl⟩
  · rw [Term.apps_snoc] at e; cases e

-- ----------------------------------------------------------------------------
-- typed refutations at the dead policy: a Lam is never typed at Qnt, at an
-- equation or at a family spine; a kind former is never applied
-- ----------------------------------------------------------------------------

theorem Pol.dead_all_adt
    (h : (Pol.dead β).conv (Ctx.δ Γ 0 (.All q A B)) (Ctx.δ Γ 0 (Term.apps (.Adt a r) ps))) :
    False := by
  have h' : Le (Book.qer β) _ _ := h
  simp only [Ctx.δ_all, Ctx.δ_apps, Ctx.δ_closed Γ 0 (.Adt a r) trivial, Term.qer,
    Term.qer_apps] at h'
  exact h'.all_adt

theorem Pol.dead_all_qnt
    (h : (Pol.dead β).conv (Ctx.δ Γ 0 (.All q A B)) (Ctx.δ Γ 0 .Qnt)) : False := by
  have h' : Le (Book.qer β) _ _ := h
  simp only [Ctx.δ_all, Ctx.δ_closed Γ 0 .Qnt trivial, Term.qer] at h'
  exact h'.all_qnt

theorem Pol.dead_all_eql
    (h : (Pol.dead β).conv (Ctx.δ Γ 0 (.All q A B)) (Ctx.δ Γ 0 (.Eql x y T))) : False := by
  have h' : Le (Book.qer β) _ _ := h
  simp only [Ctx.δ_all, Ctx.δ_eql, Term.qer] at h'
  exact h'.all_eql

theorem Pol.dead_typ_all
    (h : (Pol.dead β).conv (Ctx.δ Γ 0 (.Typ g)) (Ctx.δ Γ 0 (.All q A B))) : False := by
  have h' : Le (Book.qer β) _ _ := h
  simp only [Ctx.δ_all, Ctx.δ_typ, Term.qer] at h'
  exact h'.typ_all

theorem Check.no_lam_qnt (hβ : Book.Closed β) {sp : List Term}
    (h : Check β (Pol.dead β) L sp q Γ (.Lam X) .Qnt π u) : False := by
  obtain ⟨_, _, _, _, _, _, _, _, _, hle, _, _⟩ := h.lam_inv (Pol.dead_pre hβ)
  exact Pol.dead_all_qnt hle

theorem Check.no_lam_eql (hβ : Book.Closed β) {sp : List Term}
    (h : Check β (Pol.dead β) L sp q Γ (.Lam X) (.Eql x y T) π u) : False := by
  obtain ⟨_, _, _, _, _, _, _, _, _, hle, _, _⟩ := h.lam_inv (Pol.dead_pre hβ)
  exact Pol.dead_all_eql hle

-- the eta source of a quantity literal / of Rfl, when typed at Qnt / at an equation
theorem Check.etas_qua (hβ : Book.Closed β) {sp : List Term}
    (h : Check β (Pol.dead β) L sp q Γ a .Qnt π u) (he : Etas β a (.Qua m)) : a = .Qua m := by
  rcases he.inv with hc | ⟨X, F, hX, -⟩
  · cases hc; rfl
  · subst hX; exact (Check.no_lam_qnt hβ h).elim

theorem Check.etas_rfl (hβ : Book.Closed β) {sp : List Term}
    (h : Check β (Pol.dead β) L sp q Γ e (.Eql x y T) π u) (he : Etas β e .Rfl) :
    e = .Rfl := by
  rcases he.inv with hc | ⟨X, F, hX, -⟩
  · cases hc; rfl
  · subst hX; exact (Check.no_lam_eql hβ h).elim

-- n lambdas peel to n rigid binders
theorem Check.lams_inv (hΦ : Pol.Pre Φ) : ∀ (n : Nat) {L : LHS} {sp : List Term} {Γ : Ctx}
    {X T : Term} {π : Uses} {u : Term},
    Check β Φ L sp q Γ (Term.lams n X) T π u →
    ∃ L' sp' Γ' T' π' u', Γ'.length = n ∧ Check β Φ L' sp' q (Γ' ++ Γ) X T' π' u' := by
  intro n
  induction n with
  | zero => intro L sp Γ X T π u h; exact ⟨L, sp, [], T, π, u, _root_.rfl, h⟩
  | succ n ih =>
    intro L sp Γ X T π u h
    obtain ⟨q', A, B, πA, π', uf, _, hb, _, _, _, _⟩ :=
      Check.lam_inv hΦ (f := Term.lams n X) h
    obtain ⟨L', sp', Γ', T', π'', u', hlen, h'⟩ := ih hb
    exact ⟨L', sp', Γ' ++ [⟨q', A, none⟩], T', π'', u', by simp [hlen], by simpa using h'⟩

-- a head whose type is a kind is never applied
theorem Check.kind_app (hβ : Book.Closed β) {sp : List Term}
    (h : Check β (Pol.dead β) L sp q Γ (.App (Term.apps hd qs) p) T π u)
    (hk : ∀ {L' : LHS} {sp' : List Term} {T' : Term} {π' : Uses} {u' : Term},
      Check β (Pol.dead β) L' sp' q Γ hd T' π' u' →
      (Pol.dead β).conv (Ctx.δ Γ 0 (.Typ (.Qua .Lone))) (Ctx.δ Γ 0 T'))
    (hnl : ∀ g, hd ≠ .Lam g) : False := by
  have hΦ := Pol.dead_pre hβ
  rcases h.app_inv hΦ with
    ⟨q', A, B, πf, uf, πx, ux, hf, _, _, _, _⟩ | ⟨g, _, e, _, _, _⟩
  · obtain ⟨T0, π0, u0, T1, πs, us, hhead, hargs, hle, _, _⟩ := hf.apps_inv hΦ qs hd hnl
    cases hargs with
    | nil => exact Pol.dead_typ_all (Pol.dead_trans hβ (hk hhead) hle)
    | cons hc _ _ => exact Pol.dead_typ_all (Pol.dead_trans hβ (hk hhead) hc)
  · exact hnl _ (Term.apps_eq_lam e).1

-- a typed tower over a kind former is no tower: it is the kind former itself
theorem Check.kind_tower (hβ : Book.Closed β) {sp : List Term}
    (h : Check β (Pol.dead β) L sp q Γ (Term.lams n (Term.apps hd qs)) K π u)
    (hlen : qs.length = n)
    (hk : ∀ {Γ' : Ctx} {L' : LHS} {sp' : List Term} {T' : Term} {π' : Uses} {u' : Term},
      Check β (Pol.dead β) L' sp' q Γ' hd T' π' u' →
      (Pol.dead β).conv (Ctx.δ Γ' 0 (.Typ (.Qua .Lone))) (Ctx.δ Γ' 0 T'))
    (hnl : ∀ g, hd ≠ .Lam g) :
    (Pol.dead β).conv (Ctx.δ Γ 0 (.Typ (.Qua .Lone))) (Ctx.δ Γ 0 K) := by
  cases n with
  | zero =>
    obtain rfl := List.eq_nil_of_length_eq_zero hlen
    exact hk h
  | succ n =>
    exfalso
    rcases List.eq_nil_or_snoc qs with rfl | ⟨qs₀, p, rfl⟩
    · simp at hlen
    · rw [Term.apps_snoc] at h
      obtain ⟨_, _, _, _, _, _, _, h'⟩ := Check.lams_inv (Pol.dead_pre hβ) _ h
      exact Check.kind_app hβ h' hk hnl

-- the scrutinee of a match inside a typed tower is never a lambda
theorem Check.tower_scrut (hβ : Book.Closed β) {sp : List Term}
    (h : Check β (Pol.dead β) L sp .None Γ
      (Term.lams n (Term.apps (.App (.Mat a c hh mm) x) qs)) T π u) (Z : Term) : x ≠ .Lam Z := by
  intro hx
  subst hx
  have hΦ := Pol.dead_pre hβ
  obtain ⟨_, _, _, _, _, _, _, h'⟩ := Check.lams_inv hΦ n h
  obtain ⟨T0, π0, u0, T1, πs, us, hhead, _, _, _, _⟩ :=
    h'.apps_inv hΦ qs _ (fun _ e => Term.noConfusion e)
  rcases hhead.app_inv hΦ with
    ⟨q', A, B, πf, uf, πx, ux, hf, hx, _, _, _⟩ | ⟨g, _, e, _, _, _⟩
  · obtain ⟨_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, hle, _, _⟩ :=
      hf.mat_inv hΦ
    obtain ⟨_, _, _, _, _, _, _, _, _, hleL, _, _⟩ := hx.lam_inv hΦ
    exact Pol.dead_all_adt (Pol.dead_trans hβ hleL (Pol.dead_all_inv hβ hle).1)
  · cases e

-- ----------------------------------------------------------------------------
-- the lemma: a typed source, an eta-reduct of it and one eta-free parallel
-- step of the reduct: the source and the step's result B-reduce to
-- eta-related terms
-- ----------------------------------------------------------------------------

theorem Check.post (hok : Book.Ok β) {sp : List Term}
    (h : Check β (Pol.dead β) L sp q Γ s T π u) (hq : q = .None) :
    ∀ t v, Etas β s t → ParB β t v →
      ∃ s' v', RedB β s s' ∧ RedB β v v' ∧ Etas β s' v' := by
  have hβ := hok.closed
  induction h with
  | var _ | ref _ _ _ | refA _ _ | adt _ | ctr _ _ _ | qnt | qua | rfl _ | efq _ _ _ =>
    intro t v he hp
    rcases he.inv with hc | ⟨X, F, hX, -⟩
    · cases hc; exact ⟨v, v, hp.red, .refl, .refl⟩
    · cases hX
  | typ hg ihg =>
    subst hq; intro t v he hp
    rcases he.inv with hc | ⟨X, F, hX, -⟩
    · cases hc with
      | typ hg' =>
        cases hp with
        | typ hpg =>
          obtain ⟨_, _, r1, r2, e1⟩ := ihg _root_.rfl _ _ hg' hpg
          exact ⟨_, _, RedB.typ r1, RedB.typ r2, Etas.typ e1⟩
        | dref _ hs _ _ => simp [Term.spine] at hs
    · cases hX
  | min ha hb iha ihb =>
    subst hq; intro t v he hp
    rcases he.inv with hc | ⟨X, F, hX, -⟩
    · cases hc with
      | min ha' hb' =>
        cases hp with
        | min hpa hpb =>
          obtain ⟨_, _, r1, r2, e1⟩ := iha _root_.rfl _ _ ha' hpa
          obtain ⟨_, _, r3, r4, e2⟩ := ihb _root_.rfl _ _ hb' hpb
          exact ⟨_, _, RedB.min r1 r3, RedB.min r2 r4, Etas.min e1 e2⟩
        | minLM hpb =>
          obtain rfl := Check.etas_qua hβ ha ha'
          obtain ⟨_, _, r3, r4, e2⟩ := ihb _root_.rfl _ _ hb' hpb
          exact ⟨_, _, .step .minLM r3, r4, e2⟩
        | minLN =>
          obtain rfl := Check.etas_qua hβ ha ha'
          exact ⟨_, _, Star.one .minLN, .refl, .refl⟩
        | minRM hpa =>
          obtain rfl := Check.etas_qua hβ hb hb'
          obtain ⟨_, _, r1, r2, e1⟩ := iha _root_.rfl _ _ ha' hpa
          exact ⟨_, _, .step .minRM r1, r2, e1⟩
        | minRN =>
          obtain rfl := Check.etas_qua hβ hb hb'
          exact ⟨_, _, Star.one .minRN, .refl, .refl⟩
        | minLL =>
          obtain rfl := Check.etas_qua hβ ha ha'
          obtain rfl := Check.etas_qua hβ hb hb'
          exact ⟨_, _, Star.one .minLL, .refl, .refl⟩
        | dref _ hs _ _ => simp [Term.spine] at hs
    · cases hX
  | all hA hB ihA ihB =>
    subst hq; intro t v he hp
    rcases he.inv with hc | ⟨X, F, hX, -⟩
    · cases hc with
      | all hA' hB' =>
        cases hp with
        | all hpA hpB =>
          obtain ⟨_, _, r1, r2, e1⟩ := ihA _root_.rfl _ _ hA' hpA
          obtain ⟨_, _, r3, r4, e2⟩ := ihB _root_.rfl _ _ hB' hpB
          exact ⟨_, _, RedB.all r1 r3, RedB.all r2 r4, Etas.all e1 e2⟩
        | dref _ hs _ _ => simp [Term.spine] at hs
    · cases hX
  | lam hA hf hle ihA ihf =>
    subst hq; intro t v he hp
    rcases he.inv with hc | ⟨X, F, hX, h1, h2, h3⟩
    · cases hc with
      | lam hf' =>
        cases hp with
        | lam hpf =>
          obtain ⟨_, _, r1, r2, e1⟩ := ihf _root_.rfl _ _ hf' hpf
          exact ⟨_, _, RedB.lam r1, RedB.lam r2, Etas.lam e1⟩
        | dref _ hs _ _ => simp [Term.spine] at hs
    · cases hX
      have hF : Etas β F (Term.shift 0 t) := by
        have := h3.shift 0
        rwa [Term.shift_subst_occ F 0 .Qnt h2] at this
      have hX' : Etas β _ (.App (Term.shift 0 t) (.Var 0)) := h1.trans (Etas.app hF .refl)
      obtain ⟨f', w', r1, r2, e1⟩ := ihf _root_.rfl _ _ hX' (ParB.app (hp.shift hβ 0) ParB.var)
      obtain ⟨v', r3, e2⟩ := AppVar.reduct hβ r2
      exact ⟨_, _, RedB.lam r1, r3, (Etas.lam e1).trans e2⟩
  | @app L x sp q Γ f q' A B πf uf πx ux hf hx ihf ihx =>
    subst hq; intro t v he hp
    rcases he.inv with hc | ⟨X, F, hX, -⟩
    · cases hc with
      | @app _ ft _ xt hf' hx' =>
        cases hp with
        | app hpf hpx =>
          obtain ⟨_, _, r1, r2, e1⟩ := ihf _root_.rfl _ _ hf' hpf
          obtain ⟨_, _, r3, r4, e2⟩ := ihx (Quant.dem_none _) _ _ hx' hpx
          exact ⟨_, _, RedB.app r1 r3, RedB.app r2 r4, Etas.app e1 e2⟩
        | beta hpg hpx =>
          obtain ⟨f', w, r1, r2, e1⟩ := ihf _root_.rfl _ _ hf' (ParB.lam hpg)
          obtain ⟨g₁, rfl, r2'⟩ := r2.lam_inv _ _root_.rfl
          obtain ⟨x', x₁, r3, r4, e2⟩ := ihx (Quant.dem_none _) _ _ hx' hpx
          obtain ⟨g₀, r5, e3⟩ := Tower.peel hβ e1 x'
          exact ⟨_, _, (RedB.app r1 r3).trans r5,
            (RedB.subst hβ r2' 0 _).trans (RedB.substR hβ r4 0 _), Etas.subst e3 e2⟩
        | @dref k d _ args' hk hs hlen hargs =>
          obtain ⟨vs₀, x₁, rfl, hpars, hpx⟩ := Pw.snoc_inv (Pw.of_getD hlen hargs)
          have hs' : (Term.spine ft).1 = .Ref k := hs
          have hpf : ParB β ft (Term.apps d.body vs₀) := ParB.dref hk hs' hpars.length hpars.getD
          obtain ⟨f', w, r1, r2, e1⟩ := ihf _root_.rfl _ _ hf' hpf
          obtain ⟨x', x₁', r3, r4, e2⟩ := ihx (Quant.dem_none _) _ _ hx' hpx
          refine ⟨_, _, RedB.app r1 r3, ?_, Etas.app e1 e2⟩
          rw [Term.apps_snoc]; exact RedB.app r2 r4
        | @matc a A₀ c C s s' hh h' mm hA hC hs hlen hs' hh' =>
          obtain ⟨f', w, r1, r2, e1⟩ := ihf _root_.rfl _ _ hf' (ParB.mat hh' (ParB.refl mm))
          obtain ⟨h₁, m₁, rfl, rh, _⟩ := r2.mat_inv _ _ _root_.rfl
          obtain ⟨x', s'', r3, r4, e2⟩ := ihx (Quant.dem_none _) _ _ hx' hs'
          obtain ⟨hs'1, hpars⟩ := hs'.spine_stable hs
          have es' : s' = Term.apps (.Ctr a c) (Term.spine s').2 := by
            have := Term.apps_spine s'; rw [hs'1] at this; exact this.symm
          obtain ⟨xs'', rfl, hred⟩ := r4.ctr_spine_inv es'
          have hlen' : xs''.length = A₀.pn + C.fn := by
            rw [← hred.length, ← hpars.length]; exact hlen
          obtain ⟨w₁, r5, ht₁⟩ := Etas.peel f' (.Mat a c h₁ m₁) [] trivial e1
          obtain ⟨w₂, r6, ht₂⟩ := ht₁.peel x'
          obtain ⟨n, qs, hd, rfl, hhd, hqs⟩ := ht₂
          rw [Term.shiftN_mat] at hhd
          cases hhd with
          | @mat h₀ _ m₀ _ _ _ eh em =>
            simp only [List.nil_append, List.map_cons, List.map_nil, List.singleton_append] at hqs
            cases hqs with
            | @cons q₀ _ qs' _ eq₀ hqs' =>
              have eq₁ : Etas β q₀ (Term.apps (.Ctr a c) (xs''.map (Term.shiftN n))) := by
                have := Etas.shiftN n e2
                rw [Term.shiftN_apps, Term.shiftN_closed (w := .Ctr a c) trivial] at this
                exact eq₀.trans this
              obtain ⟨w₃, r7, ht₃⟩ := Etas.peel q₀ (.Ctr a c) _ trivial eq₁
              have r8 : RedB β (Term.lams n (Term.apps (.App (.Mat a c h₀ m₀) q₀) qs'))
                  (Term.lams n (Term.apps (.App (.Mat a c h₀ m₀) w₃) qs')) :=
                Star.lams RedB.lam n (RedB.apps (RedB.app .refl r7) (Pw.star_refl _))
              have rs : RedB β (.App f x)
                  (Term.lams n (Term.apps (.App (.Mat a c h₀ m₀) w₃) qs')) :=
                ((RedB.app r1 r3).trans ((RedB.app r5 .refl).trans r6)).trans r8
              rcases ht₃.cases with ⟨Z, rfl⟩ | ⟨h₃, qs₃, rfl, hh₃, hqs₃⟩
              · exact absurd _root_.rfl
                  (Check.tower_scrut hβ (Check.dead_redB hok (Check.app hf hx) _root_.rfl rs) Z)
              · cases hh₃
                have hl : qs₃.length = A₀.pn + C.fn := by
                  rw [hqs₃.length, List.length_map]; exact hlen'
                have hstep : StepB β (.App (.Mat a c h₀ m₀) (Term.apps (.Ctr a c) qs₃))
                    (Term.apps h₀ (qs₃.drop A₀.pn)) := by
                  have := StepB.matc (h := h₀) (m := m₀) hA hC (ps := qs₃.take A₀.pn)
                    (xs := qs₃.drop A₀.pn) (by rw [List.length_take]; omega)
                    (by rw [List.length_drop]; omega)
                  rwa [List.take_append_drop] at this
                refine ⟨_, _,
                  rs.trans (Star.lams RedB.lam n (RedB.apps (Star.one hstep) (Pw.star_refl _))),
                  RedB.apps rh (hred.drop A₀.pn), ?_⟩
                have e := Star.lams Etas.lam n (Etas.apps (Etas.apps eh (hqs₃.drop A₀.pn)) hqs')
                rw [← List.map_drop, ← Term.shiftN_apps] at e
                exact e.trans (Etas.lams_rvars n _)
        | @matm s a' c' a c s' mm m' hh hs hne hs' hm' =>
          obtain ⟨f', w, r1, r2, e1⟩ := ihf _root_.rfl _ _ hf' (ParB.mat (ParB.refl hh) hm')
          obtain ⟨h₁, m₁, rfl, _, rm⟩ := r2.mat_inv _ _ _root_.rfl
          obtain ⟨x', s'', r3, r4, e2⟩ := ihx (Quant.dem_none _) _ _ hx' hs'
          obtain ⟨hs'1, _⟩ := hs'.spine_stable hs
          have es' : s' = Term.apps (.Ctr a' c') (Term.spine s').2 := by
            have := Term.apps_spine s'; rw [hs'1] at this; exact this.symm
          obtain ⟨xs'', rfl, _⟩ := r4.ctr_spine_inv es'
          obtain ⟨w₁, r5, ht₁⟩ := Etas.peel f' (.Mat a c h₁ m₁) [] trivial e1
          obtain ⟨w₂, r6, ht₂⟩ := ht₁.peel x'
          obtain ⟨n, qs, hd, rfl, hhd, hqs⟩ := ht₂
          rw [Term.shiftN_mat] at hhd
          cases hhd with
          | @mat h₀ _ m₀ _ _ _ eh em =>
            simp only [List.nil_append, List.map_cons, List.map_nil, List.singleton_append] at hqs
            cases hqs with
            | @cons q₀ _ qs' _ eq₀ hqs' =>
              have eq₁ : Etas β q₀ (Term.apps (.Ctr a' c') (xs''.map (Term.shiftN n))) := by
                have := Etas.shiftN n e2
                rw [Term.shiftN_apps, Term.shiftN_closed (w := .Ctr a' c') trivial] at this
                exact eq₀.trans this
              obtain ⟨w₃, r7, ht₃⟩ := Etas.peel q₀ (.Ctr a' c') _ trivial eq₁
              have r8 : RedB β (Term.lams n (Term.apps (.App (.Mat a c h₀ m₀) q₀) qs'))
                  (Term.lams n (Term.apps (.App (.Mat a c h₀ m₀) w₃) qs')) :=
                Star.lams RedB.lam n (RedB.apps (RedB.app .refl r7) (Pw.star_refl _))
              have rs : RedB β (.App f x)
                  (Term.lams n (Term.apps (.App (.Mat a c h₀ m₀) w₃) qs')) :=
                ((RedB.app r1 r3).trans ((RedB.app r5 .refl).trans r6)).trans r8
              rcases ht₃.cases with ⟨Z, rfl⟩ | ⟨h₃, qs₃, rfl, hh₃, hqs₃⟩
              · exact absurd _root_.rfl
                  (Check.tower_scrut hβ (Check.dead_redB hok (Check.app hf hx) _root_.rfl rs) Z)
              · cases hh₃
                refine ⟨_, _, rs.trans (Star.lams RedB.lam n (RedB.apps
                    (Star.one (StepB.matm (h := h₀) (m := m₀) (as := qs₃) hne))
                    (Pw.star_refl _))),
                  RedB.app rm r4, ?_⟩
                have e := Star.lams Etas.lam n
                  (Etas.apps (Etas.app em (Etas.apps (Star.refl (t := .Ctr a' c')) hqs₃)) hqs')
                have e' : Term.apps (.Ctr a' c') (xs''.map (Term.shiftN n))
                    = Term.shiftN n (Term.apps (.Ctr a' c') xs'') := by
                  rw [Term.shiftN_apps, Term.shiftN_closed (w := .Ctr a' c') trivial]
                rw [e', ← Term.shiftN_app] at e
                exact e.trans (Etas.lams_rvars n _)
    · cases hX
  | @appLam a L sp q Γ g T π u hcl hg ih =>
    subst hq; intro t v he hp
    rcases he.inv with hc | ⟨X, F, hX, -⟩
    · cases hc with
      | @app _ ft _ xt hL hx' =>
        rcases hL.inv with hc' | ⟨X, F, hX, h1, h2, h3⟩
        · cases hc' with
          | lam hg' =>
            cases hp with
            | app hpL hpx =>
              cases hpL with
              | lam hpg =>
                obtain ⟨s', v', r1, r2, e⟩ :=
                  ih _root_.rfl _ _ (Etas.subst hg' hx') (hpg.subst hβ 0 hpx)
                exact ⟨s', v', .step .beta r1, .step .beta r2, e⟩
              | dref _ hs _ _ => simp [Term.spine] at hs
            | beta hpg hpx =>
              obtain ⟨s', v', r1, r2, e⟩ :=
                ih _root_.rfl _ _ (Etas.subst hg' hx') (hpg.subst hβ 0 hpx)
              exact ⟨s', v', .step .beta r1, r2, e⟩
            | dref _ hs _ _ => simp [Term.spine] at hs
        · cases hX
          have he' : Etas β (Term.subst 0 a g) (.App ft xt) := by
            have := h1.subst1 0 a
            rw [Term.subst_eta h2] at this
            exact this.trans (Etas.app h3 hx')
          obtain ⟨s', v', r1, r2, e⟩ := ih _root_.rfl _ _ he' hp
          exact ⟨s', v', .step .beta r1, r2, e⟩
    · cases hX
  | let_ hv hA hb hle ihv ihA ihb =>
    subst hq; intro t v he hp
    rcases he.inv with hc | ⟨X, F, hX, -⟩
    · cases hc with
      | let_ hv' hb' =>
        cases hp with
        | let_ hpv hpb =>
          obtain ⟨_, _, r1, r2, e1⟩ := ihv (Quant.dem_none _) _ _ hv' hpv
          obtain ⟨_, _, r3, r4, e2⟩ := ihb _root_.rfl _ _ hb' hpb
          exact ⟨_, _, RedB.let_ r1 r3, RedB.let_ r2 r4, Etas.let_ e1 e2⟩
        | letr hpv hpb =>
          obtain ⟨_, _, r1, r2, e1⟩ := ihv (Quant.dem_none _) _ _ hv' hpv
          obtain ⟨_, _, r3, r4, e2⟩ := ihb _root_.rfl _ _ hb' hpb
          exact ⟨_, _, (RedB.let_ r1 r3).trans (Star.one .let_),
            (RedB.subst hβ r4 0 _).trans (RedB.substR hβ r2 0 _), Etas.subst e2 e1⟩
        | dref _ hs _ _ => simp [Term.spine] at hs
    · cases hX
  | eql hT ha hb ihT iha ihb =>
    subst hq; intro t v he hp
    rcases he.inv with hc | ⟨X, F, hX, -⟩
    · cases hc with
      | eql ha' hb' hT' =>
        cases hp with
        | eql hpa hpb hpT =>
          obtain ⟨_, _, r1, r2, e1⟩ := iha _root_.rfl _ _ ha' hpa
          obtain ⟨_, _, r3, r4, e2⟩ := ihb _root_.rfl _ _ hb' hpb
          obtain ⟨_, _, r5, r6, e3⟩ := ihT _root_.rfl _ _ hT' hpT
          exact ⟨_, _, RedB.eql r1 r3 r5, RedB.eql r2 r4 r6, Etas.eql e1 e2 e3⟩
        | dref _ hs _ _ => simp [Term.spine] at hs
    · cases hX
  | rwt he hP hf ihe ihP ihf =>
    subst hq; intro t v het hp
    rcases het.inv with hc | ⟨X, F, hX, -⟩
    · cases hc with
      | rwt he' hP' hf' =>
        cases hp with
        | rwt hpe hpP hpf =>
          obtain ⟨_, _, r1, r2, e1⟩ := ihe _root_.rfl _ _ he' hpe
          obtain ⟨_, _, r3, r4, e2⟩ := ihP _root_.rfl _ _ hP' hpP
          obtain ⟨_, _, r5, r6, e3⟩ := ihf _root_.rfl _ _ hf' hpf
          exact ⟨_, _, RedB.rwt r1 r3 r5, RedB.rwt r2 r4 r6, Etas.rwt e1 e2 e3⟩
        | rwtr hpf =>
          obtain rfl := Check.etas_rfl hβ he he'
          obtain ⟨_, _, r5, r6, e3⟩ := ihf _root_.rfl _ _ hf' hpf
          exact ⟨_, _, .step .rwt r5, r6, e3⟩
        | dref _ hs _ _ => simp [Term.spine] at hs
    · cases hX
  | mat hk hc hr hlen hlive hins hgoal hh hm ihh ihm =>
    subst hq; intro t v he hp
    rcases he.inv with hc' | ⟨X, F, hX, -⟩
    · cases hc' with
      | mat hh' hm' =>
        cases hp with
        | mat hph hpm =>
          obtain ⟨_, _, r1, r2, e1⟩ := ihh _root_.rfl _ _ hh' hph
          obtain ⟨_, _, r3, r4, e2⟩ := ihm _root_.rfl _ _ hm' hpm
          exact ⟨_, _, RedB.mat r1 r3, RedB.mat r2 r4, Etas.mat e1 e2⟩
        | dref _ hs _ _ => simp [Term.spine] at hs
    · cases hX
  | cnv _ hc iht =>
    intro t v he hp
    exact iht hq _ _ he hp

-- ----------------------------------------------------------------------------
-- covering: a term is covered when it and a typed term share an
-- eta-target; covering survives every strong step
-- ----------------------------------------------------------------------------

def Cov (β : Book) (Γ : Ctx) (T t : Term) : Prop :=
  ∃ s w, Check β (Pol.dead β) (LHS.void β) [] .None Γ s T Uses.zero .Qnt ∧
    Red β .strong t w ∧ Etas β s w

theorem Check.cov (h : Check β (Pol.dead β) (LHS.void β) [] .None Γ t T π u) : Cov β Γ T t :=
  ⟨t, t, h.at0, .refl, .refl⟩

theorem Cov.par (hok : Book.Ok β) (hc : Cov β Γ T t) (hp : Par β t t₁) :
    Cov β Γ T t₁ := by
  have hβ := hok.closed
  obtain ⟨s, w, hs, hr, he⟩ := hc
  obtain ⟨w₁, hr₁, hp₁⟩ := Par.strip hβ hp hr
  obtain ⟨u₁, hpB, he₁⟩ := Par.split hβ hp₁
  obtain ⟨s', u₁', r1, r2, e⟩ := Check.post hok hs _root_.rfl _ _ he hpB
  obtain ⟨w₁', r3, e'⟩ := EtaB.commute_red hβ he₁ r2
  exact ⟨s', w₁', Check.dead_redB hok hs _root_.rfl r1, hr₁.trans (r3.red StepB.step),
    e.trans e'⟩

theorem Cov.red (hok : Book.Ok β) (hc : Cov β Γ T t) (hr : Red β .strong t t') :
    Cov β Γ T t' := by
  induction hr with
  | refl => exact hc
  | step st _ ih => exact ih (hc.par hok st.par)

-- ----------------------------------------------------------------------------
-- the kinds of what a type reduces to, in any context
-- ----------------------------------------------------------------------------

theorem Red.closed (hβ : Book.Closed β) (hr : Red β .strong t t') (hc : Term.Closed n t) :
    Term.Closed n t' := by
  induction hr with
  | refl => exact hc
  | step st _ ih => exact ih (Par.closed hβ st.par hc)

theorem Convs.of_red_etas : ∀ {xs ys zs : List Term},
    Reds β .strong xs zs → Etass β ys zs → Convs β xs ys := by
  intro xs ys zs h1 h2
  induction h1 generalizing ys with
  | nil => cases h2; exact .nil
  | cons hx _ ih =>
    cases h2 with | cons hy hrest => exact .cons ⟨_, hx, hy.red Eta.step⟩ (ih hrest)

-- the open instantiation of a family kind: each parameter is shifted under
-- the binders it crosses (= instG on closed parameters)
def Term.instGo : List Term → Term → Term
  | [],      G => G
  | p :: ps, G => Term.instGo ps (Term.subst ps.length (Term.shiftN ps.length p) G)

theorem Term.instGo_closed : ∀ (ps : List Term) (G : Term), (∀ p ∈ ps, Term.Closed 0 p) →
    Term.instGo ps G = Term.instG ps G := by
  intro ps
  induction ps with
  | nil => intro G _; rfl
  | cons p ps ih =>
    intro G hcl
    simp only [Term.instGo, Term.instG]
    rw [Term.shiftN_closed (hcl p (by simp)) ps.length]
    exact ih _ (fun x hx => hcl x (by simp [hx]))

theorem Term.instGo.conv (hβ : Book.Closed β) : ∀ {xs ys : List Term} {G1 G2 : Term},
    Convs β xs ys → Conv β G1 G2 → Conv β (Term.instGo xs G1) (Term.instGo ys G2) := by
  intro xs
  induction xs with
  | nil => intro ys G1 G2 h hG; cases h; exact hG
  | cons x xs ih =>
    intro ys G1 G2 h hG
    cases h with
    | cons hxy hrest =>
      simp only [Term.instGo]
      rw [← hrest.length]
      exact ih hrest (Conv.subst hβ hG (Conv.shiftN hβ hxy xs.length) xs.length)

-- the signature walk with open parameters lands on the open instantiation
theorem Args.steleDo (hβ : Book.Closed β) :
    ∀ {as : List Term} {n : Nat} {Tw G T0 T1 : Term} {πs : Uses} {us : List Term},
    STele β n Tw G → Args β (Pol.dead β) L .None Γ T0 as T1 πs us →
    (Pol.dead β).conv (Ctx.δ Γ 0 Tw) (Ctx.δ Γ 0 T0) → as.length = n →
    (Pol.dead β).conv (Ctx.δ Γ 0 (.Typ (Term.instGo as G))) (Ctx.δ Γ 0 T1) := by
  intro as
  induction as with
  | nil =>
    intro n Tw G T0 T1 πs us hs h hle hlen
    cases h
    cases n with
    | zero => exact Le.red_l hβ.qer ((Ctx.δ_red hβ Γ 0 hs).strong.qer) hle
    | succ n => simp at hlen
  | cons x as ih =>
    intro n Tw G T0 T1 πs us hs h hle hlen
    cases n with
    | zero => simp at hlen
    | succ n =>
      obtain ⟨q0, K, Bw, hT, hs'⟩ := hs
      subst hT
      obtain ⟨πx, ux, πs', us', B1, _, _, _, hB, hr⟩ := Args.stepD hβ hle h
      have hsub := hs'.subst hβ 0 x
      rw [Nat.zero_add] at hsub
      have hlen' : as.length = n := by simp at hlen; omega
      have := ih hsub hr hB hlen'
      simp only [Term.instGo]
      rw [hlen']
      exact this

theorem Check.kind_red' (hok : Book.Ok β)
    (h : Check β (Pol.dead β) (LHS.void β) [] .None Γ A K π u) (hr : Red β .strong A A') :
    (∀ q X Y, A' = .All q X Y →
      (Pol.dead β).conv (Ctx.δ Γ 0 (.Typ (.Qua .Lone))) (Ctx.δ Γ 0 K)) ∧
    (∀ g, A' = .Typ g →
      (Pol.dead β).conv (Ctx.δ Γ 0 (.Typ (.Qua .Lone))) (Ctx.δ Γ 0 K)) ∧
    (A' = .Qnt → (Pol.dead β).conv (Ctx.δ Γ 0 (.Typ (.Qua .Lone))) (Ctx.δ Γ 0 K)) ∧
    (∀ a r ps A0, A' = Term.apps (.Adt a r) ps → Book.adt β a = some A0 →
      ps.length = A0.pn →
      ∃ G, STele β A0.pn A0.sig G ∧
        (Pol.dead β).conv (Ctx.δ Γ 0 (.Typ (Term.instGo ps G))) (Ctx.δ Γ 0 K)) := by
  have hβ := hok.closed
  have hΦ := Pol.dead_pre hβ
  obtain ⟨s, w, hs, hw, he⟩ := Cov.red hok h.cov hr
  refine ⟨fun q X Y e => ?_, fun g e => ?_, fun e => ?_, fun a r ps A0 e hA0 hlen => ?_⟩
  · subst e
    obtain ⟨X', Y', rfl, _, _⟩ := hw.all_inv
    obtain ⟨w₁, r, ht⟩ := Etas.peel s (.All q X' Y') [] trivial he
    obtain ⟨n, qs, hd, rfl, hhd, hqs⟩ := ht
    obtain ⟨X₃, Y₃, e₃⟩ := Term.shiftN_all_ex (q := q) (A := X') (B := Y') n
    rw [e₃] at hhd
    cases hhd with
    | all _ _ =>
      refine Check.kind_tower hβ (Check.dead_redB hok hs _root_.rfl r) ?_ ?_
        (fun _ e => Term.noConfusion e)
      · rw [hqs.length]; simp [Term.rvars_length]
      · intro Γ' L' sp' T' π' u' h'
        obtain ⟨_, _, _, _, hle, _, _⟩ := h'.all_inv hΦ
        exact hle
  · subst e
    obtain ⟨g', rfl, _⟩ := hw.typ_inv
    obtain ⟨w₁, r, ht⟩ := Etas.peel s (.Typ g') [] trivial he
    obtain ⟨n, qs, hd, rfl, hhd, hqs⟩ := ht
    obtain ⟨g₃, e₃⟩ := Term.shiftN_typ_ex (g := g') n
    rw [e₃] at hhd
    cases hhd with
    | typ _ =>
      refine Check.kind_tower hβ (Check.dead_redB hok hs _root_.rfl r) ?_ ?_
        (fun _ e => Term.noConfusion e)
      · rw [hqs.length]; simp [Term.rvars_length]
      · intro Γ' L' sp' T' π' u' h'
        obtain ⟨_, _, hle, _, _⟩ := h'.typ_inv hΦ
        exact hle
  · subst e
    obtain rfl := hw.qnt_inv
    obtain ⟨w₁, r, ht⟩ := Etas.peel s .Qnt [] trivial he
    obtain ⟨n, qs, hd, rfl, hhd, hqs⟩ := ht
    rw [Term.shiftN_closed (w := .Qnt) trivial] at hhd
    cases hhd with
    | qnt =>
      refine Check.kind_tower hβ (Check.dead_redB hok hs _root_.rfl r) ?_ ?_
        (fun _ e => Term.noConfusion e)
      · rw [hqs.length]; simp [Term.rvars_length]
      · intro Γ' L' sp' T' π' u' h'
        exact (h'.qnt_inv hΦ).1
  · subst e
    obtain ⟨ps'', rfl, hps⟩ := hw.adt_inv
    obtain ⟨w₁, rb, ht⟩ := Etas.peel s (.Adt a r) ps'' trivial he
    obtain ⟨n, qs, hd, rfl, hhd, hqs⟩ := ht
    rw [Term.shiftN_closed (w := .Adt a r) trivial] at hhd
    cases hhd with
    | adt =>
      have hw₁ := Check.dead_redB hok hs _root_.rfl rb
      obtain ⟨_, G, hSt, _⟩ := hok a (.adt A0) (Book.adt_tld hA0)
      have hlen'' : ps''.length = A0.pn := by rw [← hps.length]; exact hlen
      have hql : qs.length = ps''.length + n := by
        rw [hqs.length, List.length_append, List.length_map, Term.rvars_length]
      cases n with
      | zero =>
        simp only [Term.map_shiftN_zero, Term.rvars, List.append_nil] at hqs
        obtain ⟨T0, π0, u0, T1, πs, us, hhead, hargs, hle, _, _⟩ :=
          Check.apps_inv hΦ qs (.Adt a r) (fun _ e => Term.noConfusion e) hw₁
        obtain ⟨A1, hA1, hle0, _, _⟩ := hhead.adt_inv hΦ
        rw [hA0] at hA1; cases hA1
        have hwalk := Args.steleDo hβ hSt hargs hle0 (by omega)
        refine ⟨G, hSt, Pol.dead_trans hβ ?_ (Pol.dead_trans hβ hwalk hle)⟩
        have hc : Conv β (Term.instGo ps G) (Term.instGo qs G) :=
          Term.instGo.conv hβ (Convs.of_red_etas hps hqs) (Conv.refl G)
        exact Pol.dead_conv hβ (Ctx.δ_conv hβ Γ 0 (Conv.typ hc))
      | succ n =>
        exfalso
        obtain ⟨_, _, _, _, _, _, _, h'⟩ := Check.lams_inv hΦ (n + 1) hw₁
        obtain ⟨T0, π0, u0, T1, πs, us, hhead, hargs, hle, _, _⟩ :=
          Check.apps_inv hΦ qs (.Adt a r) (fun _ e => Term.noConfusion e) h'
        obtain ⟨A1, hA1, hle0, _, _⟩ := hhead.adt_inv hΦ
        rw [hA0] at hA1; cases hA1
        rcases Args.steleD hβ hSt hargs hle0 with ⟨hlt, _⟩ | ⟨heq, _⟩ <;> omega

-- the closed instance (closed parameters: instG)
theorem Check.kind_red_closed (hok : Book.Ok β)
    (h : Check β (Pol.dead β) (LHS.void β) [] .None [] A K π u) (hr : Red β .strong A A') :
    (∀ q X Y, A' = .All q X Y → (Pol.dead β).conv (.Typ (.Qua .Lone)) K) ∧
    (∀ g, A' = .Typ g → (Pol.dead β).conv (.Typ (.Qua .Lone)) K) ∧
    (A' = .Qnt → (Pol.dead β).conv (.Typ (.Qua .Lone)) K) ∧
    (∀ a r ps A0, A' = Term.apps (.Adt a r) ps → Book.adt β a = some A0 →
      ps.length = A0.pn →
      ∃ G, STele β A0.pn A0.sig G ∧ (Pol.dead β).conv (.Typ (Term.instG ps G)) K) := by
  obtain ⟨h1, h2, h3, h4⟩ := Check.kind_red' hok h hr
  refine ⟨h1, h2, h3, fun a r ps A0 e hA0 hlen => ?_⟩
  obtain ⟨G, hSt, hc⟩ := h4 a r ps A0 e hA0 hlen
  have hcl := (Term.closed_apps_inv ps (.Adt a r) 0
    (e ▸ Red.closed hok.closed hr h.closed)).2
  rw [Term.instGo_closed ps G hcl] at hc
  exact ⟨G, hSt, hc⟩

-- ----------------------------------------------------------------------------
-- the DataPol instance at the dead policy
-- ----------------------------------------------------------------------------

theorem DataPol.dead' (hok : Book.Ok β) : DataPol β (Pol.dead β) where
  weak := Pol.dead_weak hok.closed
  std := Pol.dead_std hok.closed
  efq := fun _ _ => trivial
  efqS := fun _ _ _ _ => trivial
  kind := Pol.dead_kind hok.closed
  no_all := fun hA hr =>
    KLe.lone_many hok.closed.qer
      (Pol.dead_typ_inv hok.closed ((Check.kind_red_closed hok hA hr).1 _ _ _ _root_.rfl))
  no_typ := fun hA hr =>
    KLe.lone_many hok.closed.qer
      (Pol.dead_typ_inv hok.closed ((Check.kind_red_closed hok hA hr).2.1 _ _root_.rfl))
  no_qnt := fun hA hr =>
    KLe.lone_many hok.closed.qer
      (Pol.dead_typ_inv hok.closed ((Check.kind_red_closed hok hA hr).2.2.1 _root_.rfl))
  adt := fun hA hr hA' hS' hlen => by
    obtain ⟨G, hG, hc⟩ := (Check.kind_red_closed hok hA hr).2.2.2 _ _ _ _ _root_.rfl hA' hlen
    have hK := KLe.qer_many (Pol.dead_typ_inv hok.closed hc) _ _root_.rfl
    exact KLe.trans hok.closed
      (KLe.conv (Term.instG.conv hok.closed (Convs.refl _) (STele.conv hok.closed hS' hG))) _ hK



-- ============================================================================
-- METATHEORY §N4 — the measure decreases: each strategy step (N4a), and the
-- unfold of a saturated definition (N4b)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- N4a — the administrative steps
-- ----------------------------------------------------------------------------

-- Fired u r: r sits at the root of u or below SStep's congruences — the
-- positions the strategy may fire at; the typed side facts of a step are
-- stated for them
inductive Fired : Term → Term → Prop
  | root  : Fired u u
  | app_f : Fired f r → Fired (.App f a) r
  | app_a : Fired a r → Fired (.App f a) r
  | let_v : Fired v r → Fired (.Let q v b) r
  | rwt_e : Fired e r → Fired (.Rwt e P f) r
  | min_a : Fired a r → Fired (.Min a b) r
  | min_b : Fired b r → Fired (.Min a b) r

theorem Fired.apps_of : ∀ (us : List Term) {f r : Term}, Fired f r → Fired (Term.apps f us) r := by
  intro us
  induction us with
  | nil => intro f r h; exact h
  | cons u us ih => intro f r h; exact ih (h.app_f)

theorem Fired.apps (us : List Term) (f : Term) : Fired (Term.apps f us) f :=
  Fired.apps_of us .root

-- a saturated definition spine is not deep
theorem Deep.dref_absurd (hd : Deep β s) (hsp : (Term.spine s).1 = .Ref k)
    (hk : Book.defn β k = some d) (hl : (Term.spine s).2.length = d.n) : False := by
  rw [← Term.apps_spine s, hsp] at hd
  rcases Deep.ref_inv hd with ⟨A, hA, _⟩ | ⟨d', hd', hlt⟩
  · exact Book.defn_adt_clash hk hA
  · rw [hk] at hd'; cases hd'; omega

-- a deep term does not step
theorem Deep.no_sstep (hs : SStep β u u') (hd : Deep β u) : False := by
  induction hs with
  | beta _ => exact Deep.app_lam hd
  | let_ _ => exact Deep.let_inv hd
  | dref hk hsp hl _ => exact Deep.dref_absurd hd hsp hk hl
  | aref hk h0 =>
    rcases Deep.ref_inv (us := []) hd with ⟨A', hA', hpn⟩ | ⟨d', hd', _⟩
    · rw [hk] at hA'; cases hA'; omega
    · exact Book.defn_adt_clash hd' hk
  | matc _ _ _ _ _ => exact Deep.app_mat hd _ _ _ _root_.rfl
  | matm _ _ => exact Deep.app_mat hd _ _ _ _root_.rfl
  | rwt => exact (Deep.rwt_inv (us := []) hd).2 _root_.rfl
  | minLM => exact (Deep.min_inv hd).2.1 _root_.rfl
  | minLN => exact (Deep.min_inv hd).2.2.1 _root_.rfl
  | minRM => exact (Deep.min_inv hd).2.2.2.2.1 _root_.rfl
  | minRN => exact (Deep.min_inv hd).2.2.2.2.2.1 _root_.rfl
  | minLL => exact (Deep.min_inv hd).2.2.2.2.2.2 ⟨_root_.rfl, _root_.rfl⟩
  | app_f _ ih => exact ih (Deep.app_inv hd)
  | app_a _ _ ih => exact ih (Deep.app_arg hd)
  | let_v _ _ => exact Deep.let_inv hd
  | rwt_e _ ih => exact ih (Deep.rwt_inv (us := []) hd).1
  | min_a _ ih => exact ih (Deep.min_inv hd).1
  | min_b _ _ ih => exact ih (Deep.min_inv hd).2.2.2.1

theorem Deep.apps_inv : ∀ (us : List Term) {f : Term}, Deep β (Term.apps f us) → Deep β f := by
  intro us
  induction us with
  | nil => intro f hd; exact hd
  | cons u us ih => intro f hd; exact Deep.app_inv (ih hd)

-- an application equal to a spine with a first argument: the spine is that
-- application, or the function is the spine without the last argument
theorem Term.app_eq_apps_cons (hh : h.IsHead) (e : Term.App f a = Term.apps h (y :: ys)) :
    (ys = [] ∧ f = h ∧ a = y) ∨ ∃ ys', ys = ys' ++ [a] ∧ f = Term.apps h (y :: ys') := by
  obtain ⟨zs, hzs, rfl⟩ := Term.app_eq_apps hh e
  cases zs with
  | nil => simp at hzs; exact .inl ⟨hzs.2, rfl, hzs.1.symm⟩
  | cons z zs => simp at hzs; obtain ⟨rfl, rfl⟩ := hzs; exact .inr ⟨zs, rfl, rfl⟩

-- a lambda and a match do not step
theorem SStep.lam_absurd (hs : SStep β (.Lam f) u') : False := by
  cases hs with
  | dref _ hsp _ _ => simp [Term.spine] at hsp

theorem SStep.mat_absurd (hs : SStep β (.Mat a c h m) u') : False := by
  cases hs with
  | dref _ hsp _ _ => simp [Term.spine] at hsp

-- a step on a spine whose head is a redex (not a reference, lambda, match,
-- or deep term) fires the head's own step
theorem SStep.app_spine (hh : ∀ k, (Term.spine f).1 ≠ .Ref k) (hnl : ∀ g, f ≠ .Lam g)
    (hnm : ∀ a c h m, f ≠ .Mat a c h m) (hnd : ¬ Deep β f)
    (hf : ∀ u', SStep β f u' → u' = f') :
    ∀ (us : List Term) (u' : Term), SStep β (Term.apps f us) u' → u' = Term.apps f' us := by
  intro us
  induction us generalizing f f' with
  | nil => exact fun u' h => hf u' h
  | cons x us ih =>
    intro u' hs
    refine ih (f := .App f x) (f' := .App f' x) ?_ ?_ ?_ ?_ ?_ u' hs
    · intro k; simp only [Term.spine]; exact hh k
    · intro g h; exact Term.noConfusion h
    · intro a c h m e; exact Term.noConfusion e
    · intro hd; exact hnd (Deep.app_inv hd)
    · intro u' h
      cases h with
      | beta _ => exact absurd rfl (hnl _)
      | dref _ hsp _ _ => simp only [Term.spine] at hsp; exact absurd hsp (hh _)
      | matc _ _ _ _ _ => exact absurd rfl (hnm _ _ _ _)
      | matm _ _ => exact absurd rfl (hnm _ _ _ _)
      | app_f h => rw [hf _ h]
      | app_a hd _ => exact absurd hd hnd

theorem SStep.lam_spine (hd : Deep β x) : ∀ (us : List Term) (u' : Term),
    SStep β (Term.apps (.Lam g) (x :: us)) u' → u' = Term.apps (Term.subst 0 x g) us := by
  intro us u' hs
  refine SStep.app_spine (f := .App (.Lam g) x) (f' := Term.subst 0 x g) ?_ ?_ ?_ ?_ ?_ us u' hs
  · intro k; simp [Term.spine]
  · intro g' h; exact Term.noConfusion h
  · intro a c h m e; exact Term.noConfusion e
  · exact Deep.app_lam
  · intro u' h
    cases h with
    | beta _ => rfl
    | dref _ hsp _ _ => simp [Term.spine] at hsp
    | app_f h => exact absurd h SStep.lam_absurd
    | app_a _ h => exact (Deep.no_sstep h hd).elim

theorem SStep.matc_spine (hk : Book.adt β a = some A) (hd : Deeps β vs) : ∀ (more : List Term) (u'
    : Term),
    SStep β (Term.apps (.Mat a c h m) (Term.apps (.Ctr a c) vs :: more)) u' →
    u' = Term.apps h (vs.drop A.pn ++ more) := by
  intro more u' hs
  rw [Term.apps_append]
  refine SStep.app_spine (f := .App (.Mat a c h m) (Term.apps (.Ctr a c) vs))
    (f' := Term.apps h (vs.drop A.pn)) ?_ ?_ ?_ ?_ ?_ more u' hs
  · intro k; simp [Term.spine]
  · intro g e; exact Term.noConfusion e
  · intro a' c' h' m' e; exact Term.noConfusion e
  · intro hdm; exact Deep.app_mat hdm a c vs rfl
  · intro u' hs'
    generalize hx : Term.apps (.Ctr a c) vs = x at hs'
    cases hs' with
    | matc hk' hC' hp hx' _ =>
      obtain ⟨_, hvs⟩ := Term.apps_head_inv (by trivial) (by trivial) hx
      rw [hk] at hk'; cases hk'
      subst hvs
      rw [← hp, List.drop_left]
    | matm hne _ =>
      obtain ⟨he, _⟩ := Term.apps_head_inv (by trivial) (by trivial) hx
      cases he; exact absurd rfl hne
    | dref _ hsp _ _ => simp [Term.spine] at hsp
    | app_f h => exact absurd h SStep.mat_absurd
    | app_a _ h => subst hx; exact (Deep.no_sstep h (Deep.ctr hd)).elim

theorem SStep.matm_spine (hne : (a', c') ≠ (a, c)) (hd : Deeps β vs) :
    ∀ (more : List Term) (u' : Term),
    SStep β (Term.apps (.Mat a c h m) (Term.apps (.Ctr a' c') vs :: more)) u' →
    u' = Term.apps m (Term.apps (.Ctr a' c') vs :: more) := by
  intro more u' hs
  refine SStep.app_spine (f := .App (.Mat a c h m) (Term.apps (.Ctr a' c') vs))
    (f' := .App m (Term.apps (.Ctr a' c') vs)) ?_ ?_ ?_ ?_ ?_ more u' hs
  · intro k; simp [Term.spine]
  · intro g e; exact Term.noConfusion e
  · intro a2 c2 h2 m2 e; exact Term.noConfusion e
  · intro hdm; exact Deep.app_mat hdm a' c' vs rfl
  · intro u' hs'
    generalize hx : Term.apps (.Ctr a' c') vs = x at hs'
    cases hs' with
    | matc _ _ _ _ _ =>
      obtain ⟨he, _⟩ := Term.apps_head_inv (by trivial) (by trivial) hx
      cases he; exact absurd rfl hne
    | matm _ _ => rfl
    | dref _ hsp _ _ => simp [Term.spine] at hsp
    | app_f h => exact absurd h SStep.mat_absurd
    | app_a _ h => subst hx; exact (Deep.no_sstep h (Deep.ctr hd)).elim

-- the measure order: helpers and frames
theorem MeasLt.mlt (h : MLt M' M) : MeasLt (M', w') (M, w) := Or.inl h

theorem MeasLt.mle (h : MLe M' M) (hw : w' < w) : MeasLt (M', w') (M, w) :=
  h.elim (fun h => Or.inl h) (fun h => Or.inr ⟨h, hw⟩)

theorem MeasLt.sub (h : Sub M' M) (hw : w' < w) : MeasLt (M', w') (M, w) :=
  MeasLt.mle h.mle hw

theorem MeasLt.frame (h : MeasLt (M', w') (M, w)) (D E : List Charge) (c : Nat) :
    MeasLt (D ++ M' ++ E, w' + c) (D ++ M ++ E, w + c) := by
  rcases h with h | ⟨hp, hw⟩
  · exact Or.inl ((h.append_l D).append_r E)
  · exact Or.inr ⟨(hp.append_left D).append_right E, by omega⟩

theorem MeasLt.cast (h : MeasLt (M', w') (M, w)) (e1 : w' = w1) (e2 : w = w2) :
    MeasLt (M', w1) (M, w2) := e1 ▸ e2 ▸ h

theorem Sub.comm (A B : List Charge) : Sub (A ++ B) (B ++ A) := fun x => by
  simp only [List.count_append]; omega

-- CG inversions on spines
theorem CGs.append : ∀ {us : List Term} {Ms : List Charge}, CGs β us Ms →
    ∀ {vs : List Term} {Ns : List Charge}, CGs β vs Ns → CGs β (us ++ vs) (Ms ++ Ns)
  | _, _, .nil, _, _, h => by simpa using h
  | _, _, .cons hu hus, _, _, h => by
    rw [List.cons_append, List.append_assoc]
    exact .cons hu (CGs.append hus h)

theorem CGs.append_inv : ∀ (us : List Term) {vs : List Term} {M : List Charge},
    CGs β (us ++ vs) M → ∃ Ms Ns, CGs β us Ms ∧ CGs β vs Ns ∧ M = Ms ++ Ns := by
  intro us
  induction us with
  | nil => intro vs M h; exact ⟨[], M, .nil, h, rfl⟩
  | cons u us ih =>
    intro vs M h
    cases h with
    | cons hu hus =>
      obtain ⟨Ms, Ns, h1, h2, rfl⟩ := ih hus
      exact ⟨_ ++ Ms, Ns, .cons hu h1, h2, by simp⟩

theorem Pins.of.snoc (h : Pins.of β n us pins) (x : Term) : Pins.of β n (us ++ [x]) pins := by
  induction h with
  | zero => exact .zero
  | none _ ih => exact .none ih
  | some hc hu _ ih => exact .some hc hu ih
  | miss h' _ => exact .none h'

-- pricings of the heads (a spine form in a rule never equals a bare head)
theorem CG.ctr_head (h : CG β (.Ctr a c) M) : M = [] := by
  generalize hu : Term.Ctr a c = u0 at h
  cases h
  case ctr => rfl
  all_goals (have e := congrArg Term.spine hu; simp [Term.spine_apps_of, Term.spine] at e)

theorem CG.rfl_head (h : CG β .Rfl M) : M = [] := by
  generalize hu : Term.Rfl = u0 at h
  cases h
  case rfl => rfl
  all_goals (have e := congrArg Term.spine hu; simp [Term.spine_apps_of, Term.spine] at e)

theorem CG.qua_head (h : CG β (.Qua q) M) : M = [] := by
  generalize hu : Term.Qua q = u0 at h
  cases h
  case qua => rfl
  all_goals (have e := congrArg Term.spine hu; simp [Term.spine_apps_of, Term.spine] at e)

theorem CG.lam_head (h : CG β (.Lam f) M) : CG β f M := by
  generalize hu : Term.Lam f = u0 at h
  cases h
  case lam hf => cases hu; exact hf
  all_goals (have e := congrArg Term.spine hu; simp [Term.spine_apps_of, Term.spine] at e)

theorem CG.mat_head (h : CG β (.Mat a c hh mm) M) :
    ∃ Mh Mm, CG β hh Mh ∧ CG β mm Mm ∧ Sub Mh M ∧ Sub Mm M := by
  generalize hu : Term.Mat a c hh mm = u0 at h
  cases h
  case mat => cases hu; exact ⟨_, _, by assumption, by assumption, by assumption, by assumption⟩
  all_goals (have e := congrArg Term.spine hu; simp [Term.spine_apps_of, Term.spine] at e)

theorem CG.refA_head (hk : Book.defn β k = none) (h : CG β (.Ref k) M) : M = [] := by
  generalize hu : Term.Ref k = u0 at h
  cases h
  case refF => rfl
  case ref hk' _ _ =>
    have e := congrArg Term.spine hu; simp [Term.spine_apps_of, Term.spine] at e
    obtain ⟨rfl, rfl⟩ := e
    rw [hk] at hk'; cases hk'
  all_goals (have e := congrArg Term.spine hu; simp [Term.spine_apps_of, Term.spine] at e)

-- a constructor spine is priced by the structural rules: its arguments'
-- charges in order
theorem CG.ctr_inv_rev : ∀ (rs : List Term) (M : List Charge),
    CG β (Term.apps (.Ctr a c) rs.reverse) M → CGs β rs.reverse M := by
  intro rs
  induction rs with
  | nil => intro M hM; rw [CG.ctr_head hM]; exact .nil
  | cons x rs ih =>
    intro M hM
    simp only [List.reverse_cons] at hM ⊢
    rw [Term.apps_snoc] at hM
    generalize hu : Term.App (Term.apps (.Ctr a c) rs.reverse) x = u0 at hM
    cases hM
    case app hf hx =>
      cases hu
      simpa using (ih _ hf).append (.cons hx .nil)
    all_goals (have e := congrArg Term.spine hu; simp [Term.spine_apps_of, Term.spine] at e)

theorem CG.ctr_inv (h : CG β (Term.apps (.Ctr a c) us) M) : CGs β us M := by
  rw [← List.reverse_reverse us] at h
  simpa using CG.ctr_inv_rev us.reverse M h

-- a definition spine is priced by the reference rule over the whole spine
-- (a structural pricing pins the missing arguments at ⊤)
theorem CG.ref_inv (hk : Book.defn β k = some d) : ∀ (rs : List Term) (M : List Charge),
    CG β (Term.apps (.Ref k) rs.reverse) M →
    ∃ pins Ms, Pins.of β d.n rs.reverse pins ∧ CGs β rs.reverse Ms ∧ M.Perm ((k, pins) :: Ms) := by
  intro rs
  induction rs with
  | nil =>
    intro M hM
    generalize hu : Term.Ref k = u0 at hM
    cases hM
    case ref hk' hp hMs =>
      have e := congrArg Term.spine hu; simp [Term.spine_apps_of, Term.spine] at e
      obtain ⟨rfl, rfl⟩ := e
      rw [hk] at hk'; cases hk'; cases hMs
      exact ⟨_, [], hp, .nil, .refl _⟩
    case refF hk' => cases hu; rw [hk] at hk'; cases hk'
    all_goals (have e := congrArg Term.spine hu; simp [Term.spine_apps_of, Term.spine] at e)
  | cons x rs ih =>
    intro M hM
    simp only [List.reverse_cons] at hM ⊢
    rw [Term.apps_snoc] at hM
    generalize hu : Term.App (Term.apps (.Ref k) rs.reverse) x = u0 at hM
    cases hM
    case ref hk' hp hMs =>
      have e := congrArg Term.spine hu; simp [Term.spine_apps_of, Term.spine] at e
      obtain ⟨rfl, rfl⟩ := e
      rw [hk] at hk'; cases hk'
      exact ⟨_, _, hp, hMs, .refl _⟩
    case app hf hx =>
      cases hu
      obtain ⟨pins, Ms, hp, h2, hperm⟩ := ih _ hf
      refine ⟨pins, Ms ++ _, hp.snoc x, h2.append (.cons hx .nil), ?_⟩
      rw [List.append_nil, ← List.cons_append]
      exact hperm.append_right _
    all_goals (have e := congrArg Term.spine hu; simp [Term.spine_apps_of, Term.spine] at e)

theorem MeasLt.frame_r (h : MeasLt (M', w') (M, w)) (E : List Charge) (c : Nat) :
    MeasLt (M' ++ E, w' + c) (M ++ E, w + c) := by
  simpa using MeasLt.frame h [] E c

theorem MeasLt.frame_l (h : MeasLt (M', w') (M, w)) (D : List Charge) (c : Nat) :
    MeasLt (D ++ M', c + w') (D ++ M, c + w) := by
  simpa [Nat.add_comm] using MeasLt.frame h D [] c

-- the typed side facts of a step, stated at the positions the strategy
-- may fire at: an affine binder or a chargeless and weightless argument at
-- a beta or a let, and the unfold's decrease at a saturated definition
-- spine (N4b)
def Side (β : Book) (u : Term) : Prop :=
  (∀ f a, Fired u (.App (.Lam f) a) → Deep β a →
    Term.occ 0 f ≤ 1 ∨ (CG β a [] ∧ Term.weight β a = 0)) ∧
  (∀ q v b, Fired u (.Let q v b) → Deep β v →
    Term.occ 0 b ≤ 1 ∨ (CG β v [] ∧ Term.weight β v = 0)) ∧
  (∀ k d (us : List Term) M, Fired u (Term.apps (.Ref k) us) → Book.defn β k = some d →
    us.length = d.n → Deeps β us → CG β (Term.apps (.Ref k) us) M →
    ∃ M', CG β (Term.apps d.body us) M' ∧ MLt M' M)

theorem Side.of (h : Side β u) (hf : Fired u r) : Side β r :=
  ⟨fun f a h1 => h.1 f a (Fired_trans hf h1), fun q v b h1 => h.2.1 q v b (Fired_trans hf h1),
   fun k d us M h1 => h.2.2 k d us M (Fired_trans hf h1)⟩
where
  Fired_trans {u r r' : Term} (h1 : Fired u r) : Fired r r' → Fired u r' := by
    induction h1 with
    | root => exact fun h => h
    | app_f _ ih => exact fun h => (ih h).app_f
    | app_a _ ih => exact fun h => (ih h).app_a
    | let_v _ ih => exact fun h => (ih h).let_v
    | rwt_e _ ih => exact fun h => (ih h).rwt_e
    | min_a _ ih => exact fun h => (ih h).min_a
    | min_b _ ih => exact fun h => (ih h).min_b

-- the root rules
theorem SStep.meas_beta (hac : a.Closed 0) (hM : CG β (.App (.Lam f) a) M)
    (hside : Term.occ 0 f ≤ 1 ∨ (CG β a [] ∧ Term.weight β a = 0)) :
    ∃ M', CG β (Term.subst 0 a f) M' ∧
      MeasLt (M', Term.weight β (Term.subst 0 a f)) (M, Term.weight β (.App (.Lam f) a)) := by
  have hw : Term.weight β (Term.subst 0 a f) < Term.weight β (.App (.Lam f) a) := by
    rcases hside with ho | ⟨_, hwa⟩
    · have := Term.weight_subst_lone (β := β) ho a; simp only [Term.weight]; omega
    · rw [Term.weight_subst_free f 0 a hwa]; simp only [Term.weight]; omega
  generalize hu : Term.App (.Lam f) a = u0 at hM
  cases hM
  case app hf ha =>
    cases hu
    have hf' := CG.lam_head hf
    rcases hside with ho | ⟨hca, _⟩
    · obtain ⟨M', h, hsub⟩ := CG.subst_lone hf' ha hac ho
      exact ⟨M', h, MeasLt.sub hsub hw⟩
    · obtain ⟨M', h, hsub⟩ := CG.subst_free hf' hca hac
      exact ⟨M', h, MeasLt.sub (hsub.trans (Sub.append_right _ _)) hw⟩
  case beta _ _ hM' =>
    have e := congrArg Term.spine hu
    simp only [Term.spine_apps_of, Term.spine, Prod.mk.injEq, List.nil_append,
      List.cons.injEq, Term.Lam.injEq] at e
    obtain ⟨rfl, rfl, rfl⟩ := e
    exact ⟨_, hM', MeasLt.mle MLe.refl hw⟩
  all_goals (have e := congrArg Term.spine hu; simp [Term.spine_apps_of, Term.spine] at e)

theorem SStep.meas_let (hvc : v.Closed 0) (hM : CG β (.Let q v b) M)
    (hside : Term.occ 0 b ≤ 1 ∨ (CG β v [] ∧ Term.weight β v = 0)) :
    ∃ M', CG β (Term.subst 0 v b) M' ∧
      MeasLt (M', Term.weight β (Term.subst 0 v b)) (M, Term.weight β (.Let q v b)) := by
  have hw : Term.weight β (Term.subst 0 v b) < Term.weight β (.Let q v b) := by
    rcases hside with ho | ⟨_, hwv⟩
    · have := Term.weight_subst_lone (β := β) ho v; simp only [Term.weight]; omega
    · rw [Term.weight_subst_free b 0 v hwv]; simp only [Term.weight]; omega
  generalize hu : Term.Let q v b = u0 at hM
  cases hM
  case let_ hv hb =>
    cases hu
    rcases hside with ho | ⟨hcv, _⟩
    · obtain ⟨M', h, hsub⟩ := CG.subst_lone hb hv hvc ho
      exact ⟨M', h, MeasLt.sub (hsub.trans (Sub.comm _ _)) hw⟩
    · obtain ⟨M', h, hsub⟩ := CG.subst_free hb hcv hvc
      exact ⟨M', h, MeasLt.sub (hsub.trans (Sub.append_left _ _)) hw⟩
  case letC _ _ hM' => cases hu; exact ⟨_, hM', MeasLt.mle MLe.refl hw⟩
  all_goals (have e := congrArg Term.spine hu; simp [Term.spine_apps_of, Term.spine] at e)

theorem SStep.meas_matc (hk : Book.adt β a = some A) (hp : ps.length = A.pn) (hM : CG β (.App (.Mat
    a c h m) (Term.apps (.Ctr a c) (ps ++ xs))) M) :
    ∃ M', CG β (Term.apps h xs) M' ∧
      MeasLt (M', Term.weight β (Term.apps h xs))
        (M, Term.weight β (.App (.Mat a c h m) (Term.apps (.Ctr a c) (ps ++ xs)))) := by
  have hw : Term.weight β (Term.apps h xs)
      < Term.weight β (.App (.Mat a c h m) (Term.apps (.Ctr a c) (ps ++ xs))) := by
    simp only [Term.weight, Term.weight_apps, List.map_append, List.sum_append, nat_max]
    have : Term.weight β h ≤ max (Term.weight β h) (Term.weight β m) := Nat.le_max_left _ _
    omega
  generalize hu : Term.App (.Mat a c h m) (Term.apps (.Ctr a c) (ps ++ xs)) = u0 at hM
  cases hM
  case app hmat hctr =>
    cases hu
    obtain ⟨Mh, Mm, hh, _, hsh, _⟩ := CG.mat_head hmat
    obtain ⟨M1, M2, _, h2, rfl⟩ := CGs.append_inv ps (CG.ctr_inv hctr)
    exact ⟨Mh ++ M2, CG.apps hh h2, MeasLt.sub (Sub.append hsh (Sub.append_left _ _)) hw⟩
  case matc hk' _ _ _ _ hM' =>
    have e := congrArg Term.spine hu
    simp only [Term.spine_apps_of, Term.spine, Prod.mk.injEq, List.nil_append,
      List.cons.injEq, Term.Mat.injEq] at e
    obtain ⟨⟨rfl, rfl, rfl, rfl⟩, e5, rfl⟩ := e
    obtain ⟨_, rfl⟩ := Term.apps_head_inv (h := .Ctr a c) (h' := .Ctr a c) (by trivial)
        (by trivial) e5
    rw [hk] at hk'; cases hk'
    rw [List.append_nil, ← hp, List.drop_left] at hM'
    exact ⟨_, hM', MeasLt.mle MLe.refl hw⟩
  case matm hne _ _ _ =>
    have e := congrArg Term.spine hu
    simp only [Term.spine_apps_of, Term.spine, Prod.mk.injEq, List.nil_append,
      List.cons.injEq, Term.Mat.injEq] at e
    obtain ⟨⟨rfl, rfl, rfl, rfl⟩, e5, rfl⟩ := e
    obtain ⟨he, _⟩ := Term.apps_head_inv (h := .Ctr a c) (h' := .Ctr _ _) (by trivial) (by trivial)
        e5
    cases he; exact absurd rfl hne
  all_goals (have e := congrArg Term.spine hu; simp [Term.spine_apps_of, Term.spine] at e)

theorem SStep.meas_matm (hne : (a', c') ≠ (a, c))
    (hM : CG β (.App (.Mat a c h m) (Term.apps (.Ctr a' c') as)) M) :
    ∃ M', CG β (.App m (Term.apps (.Ctr a' c') as)) M' ∧
      MeasLt (M', Term.weight β (.App m (Term.apps (.Ctr a' c') as)))
        (M, Term.weight β (.App (.Mat a c h m) (Term.apps (.Ctr a' c') as))) := by
  have hw : Term.weight β (.App m (Term.apps (.Ctr a' c') as))
      < Term.weight β (.App (.Mat a c h m) (Term.apps (.Ctr a' c') as)) := by
    simp only [Term.weight, nat_max]
    have : Term.weight β m ≤ max (Term.weight β h) (Term.weight β m) := Nat.le_max_right _ _
    omega
  generalize hu : Term.App (.Mat a c h m) (Term.apps (.Ctr a' c') as) = u0 at hM
  cases hM
  case app hmat hctr =>
    cases hu
    obtain ⟨Mh, Mm, _, hm, _, hsm⟩ := CG.mat_head hmat
    exact ⟨Mm ++ _, CG.app hm hctr, MeasLt.sub (Sub.append hsm (Sub.refl _)) hw⟩
  case matc _ _ _ _ _ _ =>
    have e := congrArg Term.spine hu
    simp only [Term.spine_apps_of, Term.spine, Prod.mk.injEq, List.nil_append,
      List.cons.injEq, Term.Mat.injEq] at e
    obtain ⟨⟨rfl, rfl, rfl, rfl⟩, e5, rfl⟩ := e
    obtain ⟨he, _⟩ := Term.apps_head_inv (h := .Ctr a' c') (h' := .Ctr _ _) (by trivial)
        (by trivial) e5
    cases he; exact absurd rfl hne
  case matm _ _ _ hM' =>
    have e := congrArg Term.spine hu
    simp only [Term.spine_apps_of, Term.spine, Prod.mk.injEq, List.nil_append,
      List.cons.injEq, Term.Mat.injEq] at e
    obtain ⟨⟨rfl, rfl, rfl, rfl⟩, e5, rfl⟩ := e
    obtain ⟨he, rfl⟩ := Term.apps_head_inv (h := .Ctr a' c') (h' := .Ctr _ _) (by trivial)
        (by trivial) e5
    cases he
    exact ⟨_, hM', MeasLt.mle MLe.refl hw⟩
  all_goals (have e := congrArg Term.spine hu; simp [Term.spine_apps_of, Term.spine] at e)

theorem SStep.meas_rwt (hM : CG β (.Rwt .Rfl P f) M) :
    ∃ M', CG β f M' ∧ MeasLt (M', Term.weight β f) (M, Term.weight β (.Rwt .Rfl P f)) := by
  generalize hu : Term.Rwt .Rfl P f = u0 at hM
  cases hM
  case rwt he hf =>
    cases hu
    rw [CG.rfl_head he]
    exact ⟨_, hf, MeasLt.mle MLe.refl (by simp [Term.weight])⟩
  all_goals (have e := congrArg Term.spine hu; simp [Term.spine_apps_of, Term.spine] at e)

theorem SStep.meas_min (hM : CG β (.Min a b) M) :
    ∃ Ma Mb, CG β a Ma ∧ CG β b Mb ∧ M = Ma ++ Mb := by
  generalize hu : Term.Min a b = u0 at hM
  cases hM
  case min ha hb => cases hu; exact ⟨_, _, ha, hb, rfl⟩
  all_goals (have e := congrArg Term.spine hu; simp [Term.spine_apps_of, Term.spine] at e)

theorem SStep.meas_aref (hk : Book.adt β k = some A) (h0 : A.pn = 0) (hM : CG β (.Ref k) M) :
    ∃ M', CG β (.Adt k []) M' ∧ MeasLt (M', Term.weight β (.Adt k [])) (M, Term.weight β (.Ref k))
        := by
  have hkd : Book.defn β k = none := by
    cases h : Book.defn β k with
    | none => rfl
    | some d => exact (Book.defn_adt_clash h hk).elim
  rw [CG.refA_head hkd hM]
  exact ⟨[], .adt, MeasLt.mle MLe.refl (by simp [Term.weight, hk, h0])⟩

theorem SStep.meas_dref (hk : Book.defn β k = some d)
    (hsp : (Term.spine s).1 = .Ref k) (hl : (Term.spine s).2.length = d.n)
    (hds : Deeps β (Term.spine s).2) (hM : CG β s M) (hside : Side β s) :
    ∃ M', CG β (Term.apps d.body (Term.spine s).2) M' ∧
      MeasLt (M', Term.weight β (Term.apps d.body (Term.spine s).2)) (M, Term.weight β s) := by
  obtain ⟨us, hus⟩ : ∃ us, (Term.spine s).2 = us := ⟨_, rfl⟩
  have es : s = Term.apps (.Ref k) us := by rw [← hus, ← hsp]; exact (Term.apps_spine s).symm
  subst es
  rw [hus] at hl hds ⊢
  obtain ⟨M', h, hlt⟩ := hside.2.2 k d us M .root hk hl hds hM
  exact ⟨M', h, MeasLt.mlt hlt⟩

-- a step on a definition spine: the unfold of a saturated prefix, or a
-- step inside one argument
theorem SStep.ref_spine_inv (hk : Book.defn β k = some d) : ∀ (rs : List Term) (u' : Term),
    SStep β (Term.apps (.Ref k) rs.reverse) u' →
    (∃ us1 us2, rs.reverse = us1 ++ us2 ∧ us1.length = d.n ∧ Deeps β us1 ∧
      u' = Term.apps (Term.apps d.body us1) us2) ∨
    (∃ us1 x x' us2, rs.reverse = us1 ++ x :: us2 ∧ SStep β x x' ∧
      u' = Term.apps (.Ref k) (us1 ++ x' :: us2)) := by
  intro rs
  induction rs with
  | nil =>
    intro u' hs
    simp only [List.reverse_nil] at hs ⊢
    cases hs with
    | dref hk' hsp hl _ =>
      simp [Term.apps, Term.spine] at hsp hl
      subst hsp; rw [hk] at hk'; cases hk'
      exact .inl ⟨[], [], rfl, by simpa using hl, .nil, by simp [Term.apps, Term.spine]⟩
    | aref hA _ => exact (Book.defn_adt_clash hk hA).elim
  | cons a rs ih =>
    intro u' hs
    simp only [List.reverse_cons] at hs ⊢
    rw [Term.apps_snoc] at hs
    generalize hF : Term.apps (.Ref k) rs.reverse = F at hs
    cases hs with
    | beta _ => exact absurd (congrArg Term.spine hF) (by simp [Term.spine_apps_of, Term.spine])
    | dref hk' hsp hl hds =>
      simp only [Term.spine, ← hF, Term.spine_apps_of] at hsp hl hds ⊢
      simp at hsp; subst hsp; rw [hk] at hk'; cases hk'
      exact .inl ⟨rs.reverse ++ [a], [], by simp, by simpa using hl, by simpa using hds, rfl⟩
    | matc _ _ _ _ _ =>
      exact absurd (congrArg Term.spine hF) (by simp [Term.spine_apps_of, Term.spine])
    | matm _ _ =>
      exact absurd (congrArg Term.spine hF) (by simp [Term.spine_apps_of, Term.spine])
    | app_f hsf =>
      subst hF
      rcases ih _ hsf with ⟨us1, us2, e, hl, hd, rfl⟩ | ⟨us1, x, x', us2, e, hs, rfl⟩
      · exact .inl ⟨us1, us2 ++ [a], by rw [e, List.append_assoc], hl, hd,
          by rw [Term.apps_snoc]⟩
      · exact .inr ⟨us1, x, x', us2 ++ [a], by rw [e]; simp, hs,
          by rw [← Term.apps_snoc, List.append_assoc, List.cons_append]⟩
    | app_a _ hsa =>
      subst hF
      exact .inr ⟨rs.reverse, a, _, [], rfl, hsa, by rw [Term.apps_snoc]⟩

-- pins: a pinning of a longer spine pins its saturated prefix; replacing
-- a non-deep argument keeps the pins
theorem Pins.of.prefix (h : Pins.of β n us pins) : ∀ {us1 us2 : List Term},
    us = us1 ++ us2 → n ≤ us1.length → Pins.of β n us1 pins := by
  induction h with
  | zero => intro us1 us2 _ _; exact .zero
  | none _ ih =>
    intro us1 us2 e hn
    cases us1 with
    | nil => simp at hn
    | cons u0 us1 =>
      simp only [List.cons_append, List.cons.injEq] at e
      obtain ⟨rfl, e⟩ := e
      exact .none (ih e (by simpa using hn))
  | some hc hu _ ih =>
    intro us1 us2 e hn
    cases us1 with
    | nil => simp at hn
    | cons u0 us1 =>
      simp only [List.cons_append, List.cons.injEq] at e
      obtain ⟨rfl, e⟩ := e
      exact .some hc hu (ih e (by simpa using hn))
  | miss _ _ =>
    intro us1 us2 e hn
    cases us1 with
    | nil => simp at hn
    | cons u0 us1 => simp at e

theorem Pins.of.replace (h : Pins.of β n us pins) (hx : ¬ Deep β x) (x' : Term) :
    ∀ {us1 us2 : List Term}, us = us1 ++ x :: us2 → Pins.of β n (us1 ++ x' :: us2) pins := by
  induction h with
  | zero => intro us1 us2 _; exact .zero
  | none _ ih =>
    intro us1 us2 e
    cases us1 with
    | nil =>
      simp only [List.nil_append, List.cons.injEq] at e
      obtain ⟨rfl, rfl⟩ := e
      exact .none (by assumption)
    | cons u0 us1 =>
      simp only [List.cons_append, List.cons.injEq] at e
      obtain ⟨rfl, e⟩ := e
      exact .none (ih e)
  | some hc hu _ ih =>
    intro us1 us2 e
    cases us1 with
    | nil =>
      simp only [List.nil_append, List.cons.injEq] at e
      obtain ⟨rfl, rfl⟩ := e
      exact absurd hu hx
    | cons u0 us1 =>
      simp only [List.cons_append, List.cons.injEq] at e
      obtain ⟨rfl, e⟩ := e
      exact .some hc hu (ih e)
  | miss _ _ => intro us1 us2 e; cases us1 <;> simp at e

theorem CGs.split3 (h : CGs β (us1 ++ x :: us2) M) :
    ∃ M1 Mx M2, CGs β us1 M1 ∧ CG β x Mx ∧ CGs β us2 M2 ∧ M = M1 ++ (Mx ++ M2) := by
  obtain ⟨M1, N, h1, h2, rfl⟩ := CGs.append_inv us1 h
  cases h2 with
  | cons hx h3 => exact ⟨M1, _, _, h1, hx, h3, rfl⟩

theorem MeasLt.frame' (h : MeasLt (M', w') (M, w)) (D E : List Charge)
    (hK' : K'.Perm (D ++ M' ++ E)) (hK : K.Perm (D ++ M ++ E)) (c : Nat)
    (e1 : w1 = w' + c) (e2 : w2 = w + c) : MeasLt (K', w1) (K, w2) := by
  subst e1 e2
  rcases MeasLt.frame h D E c with h | ⟨hp, hw⟩
  · exact Or.inl ((h.perm_l hK'.symm).perm_r hK.symm)
  · exact Or.inr ⟨hK'.trans (hp.trans hK.symm), hw⟩

-- the step inside an argument of a definition spine (its pricing is the
-- reference rule over the whole spine, the stepping argument is unpinned)
theorem SStep.meas_ref_arg (hk : Book.defn β k = some d) (hsx : SStep β x x')
    (ih : ∀ M, CG β x M → x.Closed 0 → Side β x →
      ∃ M', CG β x' M' ∧ MeasLt (M', Term.weight β x') (M, Term.weight β x))
    (hp : Pins.of β d.n (us1 ++ x :: us2) pins) (hMs : CGs β (us1 ++ x :: us2) Ms)
    (hc : (Term.apps (.Ref k) (us1 ++ x :: us2)).Closed 0)
    (hside : Side β (Term.apps (.Ref k) (us1 ++ x :: us2))) :
    ∃ M', CG β (Term.apps (.Ref k) (us1 ++ x' :: us2)) M' ∧
      MeasLt (M', Term.weight β (Term.apps (.Ref k) (us1 ++ x' :: us2)))
        ((k, pins) :: Ms, Term.weight β (Term.apps (.Ref k) (us1 ++ x :: us2))) := by
  obtain ⟨M1, Mx, M2, h1, hx, h2, rfl⟩ := CGs.split3 hMs
  have hcx : x.Closed 0 := (Term.closed_apps_inv _ _ _ hc).2 x (by simp)
  have hfx : Fired (Term.apps (.Ref k) (us1 ++ x :: us2)) x := by
    rw [Term.apps_append]; exact Fired.apps_of us2 (.app_a .root)
  obtain ⟨Mx', hx', hlt⟩ := ih _ hx hcx (hside.of hfx)
  refine ⟨(k, pins) :: (M1 ++ (Mx' ++ M2)),
    .ref hk (hp.replace (fun hd => Deep.no_sstep hsx hd) x' rfl) (h1.append (.cons hx' h2)), ?_⟩
  refine MeasLt.frame' hlt ((k, pins) :: M1) M2 (by simp) (by simp)
    (Term.weight β (.Ref k) + (us1.map (Term.weight β)).sum + (us2.map (Term.weight β)).sum)
    ?_ ?_ <;>
  · simp only [Term.weight_apps, List.map_append, List.sum_append, List.map_cons, List.sum_cons]
    omega

-- the congruences: the enclosing pricing is structural, or the step is
-- the head redex of a contractum-priced spine, or a step inside a
-- definition spine
theorem SStep.meas_app_f (hsf : SStep β f f')
    (ih : ∀ {t t' : Term}, Term.size t < Term.size (.App f a) → SStep β t t' →
      ∀ M, CG β t M → t.Closed 0 → Side β t →
      ∃ M', CG β t' M' ∧ MeasLt (M', Term.weight β t') (M, Term.weight β t))
    (hM : CG β (.App f a) M) (hc : (Term.App f a).Closed 0) (hside : Side β (.App f a)) :
    ∃ M', CG β (.App f' a) M' ∧
      MeasLt (M', Term.weight β (.App f' a)) (M, Term.weight β (.App f a)) := by
  generalize hu : Term.App f a = u0 at hM
  cases hM
  case app hf ha =>
    cases hu
    obtain ⟨M', h, hlt⟩ := ih (by simp only [Term.size]; omega) hsf _ hf hc.1 (hside.of (.app_f
        .root))
    exact ⟨M' ++ _, CG.app h ha,
        by simpa [Term.weight] using MeasLt.frame_r hlt _ (Term.weight β a)⟩
  case ref hk hp hMs =>
    rename_i k d us pins Ms
    obtain ⟨ys, rfl, rfl⟩ := Term.app_eq_apps (h := .Ref _) (by trivial) hu
    rw [← List.reverse_reverse ys] at hsf
    rcases SStep.ref_spine_inv hk _ _ hsf with
      ⟨us1, us2, e, hl, hd, rfl⟩ | ⟨us1, x, x', us2, e, hsx, rfl⟩
    · rw [List.reverse_reverse] at e; subst e
      rw [List.append_assoc] at hp hMs
      obtain ⟨Ms1, Ms2, h1, h2, rfl⟩ := CGs.append_inv us1 hMs
      have hF : Fired (Term.App (Term.apps (.Ref k) (us1 ++ us2)) a) (Term.apps (.Ref k) us1) := by
        rw [Term.apps_append]; exact (Fired.apps us2 _).app_f
      obtain ⟨M', h, hlt⟩ := hside.2.2 k d us1 _ hF hk hl hd
        (.ref hk (hp.prefix rfl (by omega)) h1)
      refine ⟨M' ++ Ms2, ?_, MeasLt.mlt (by simpa using hlt.append_r Ms2)⟩
      rw [← Term.apps_snoc]; exact CG.apps h h2
    · rw [List.reverse_reverse] at e; subst e
      rw [← Term.apps_snoc]; simp only [List.append_assoc, List.cons_append]
      rw [List.append_assoc, List.cons_append] at hp hMs
      rw [← Term.apps_snoc, List.append_assoc, List.cons_append] at hc hside
      exact SStep.meas_ref_arg hk hsx (fun M hM hcx hsx' => ih (by
        have h1 := Term.size_spine_arg (Term.apps (.Ref k) (us1 ++ x :: us2)) x
          (by rw [Term.spine_apps (by trivial)]; simp)
        exact Nat.lt_of_lt_of_le h1 (by simp only [Term.size]; omega)) hsx M hM hcx hsx') hp hMs hc
            hside
  case beta _ hd hM' =>
    rename_i x' f0 us0 M0
    rcases Term.app_eq_apps_cons (by trivial) hu with ⟨rfl, rfl, rfl⟩ | ⟨ys, rfl, rfl⟩
    · exact (SStep.lam_absurd hsf).elim
    · obtain rfl := SStep.lam_spine hd ys f' hsf
      refine ⟨_, by rw [← Term.apps_snoc]; exact hM', MeasLt.mle MLe.refl ?_⟩
      simp only [Term.weight, Term.weight_apps, List.map_cons, List.sum_cons, List.map_append,
        List.sum_append, List.map_nil, List.sum_nil]
      rcases hside.1 _ _ (Fired.app_f (Fired.apps ys _)) hd with ho | ⟨_, hwa⟩
      · have := Term.weight_subst_lone (β := β) ho x'; omega
      · rw [Term.weight_subst_free _ 0 _ hwa]; omega
  case matc hk hC hlen hcl hd hM' =>
    rcases Term.app_eq_apps_cons (by trivial) hu with ⟨rfl, rfl, rfl⟩ | ⟨ys, rfl, rfl⟩
    · exact (SStep.mat_absurd hsf).elim
    · rename_i a0 A0 c0 C0 us0 h0 m0
      obtain rfl := SStep.matc_spine hk hd ys f' hsf
      refine ⟨_, by rw [← Term.apps_snoc, List.append_assoc]; exact hM', MeasLt.mle MLe.refl ?_⟩
      simp only [Term.weight, Term.weight_apps, List.map_cons, List.sum_cons, List.map_append,
        List.sum_append, List.map_nil, List.sum_nil, nat_max]
      have := sum_map_drop_le (Term.weight β) us0 A0.pn
      have : Term.weight β h0 ≤ max (Term.weight β h0) (Term.weight β m0) := Nat.le_max_left _ _
      omega
  case matm hne hcl hd hM' =>
    rcases Term.app_eq_apps_cons (by trivial) hu with ⟨rfl, rfl, rfl⟩ | ⟨ys, rfl, rfl⟩
    · exact (SStep.mat_absurd hsf).elim
    · rename_i a1 c1 a0 c0 us0 m0 h0
      obtain rfl := SStep.matm_spine hne hd ys f' hsf
      refine ⟨_, by rw [← Term.apps_snoc]; exact hM', MeasLt.mle MLe.refl ?_⟩
      simp only [Term.weight, Term.weight_apps, List.map_cons, List.sum_cons, List.map_append,
        List.sum_append, List.map_nil, List.sum_nil, nat_max]
      have : Term.weight β m0 ≤ max (Term.weight β h0) (Term.weight β m0) := Nat.le_max_right _ _
      omega
  all_goals (have e := congrArg Term.spine hu; simp [Term.spine] at e)

theorem SStep.meas_app_a (hdf : Deep β f) (hsa : SStep β a a')
    (ih : ∀ {t t' : Term}, Term.size t < Term.size (.App f a) → SStep β t t' →
      ∀ M, CG β t M → t.Closed 0 → Side β t →
      ∃ M', CG β t' M' ∧ MeasLt (M', Term.weight β t') (M, Term.weight β t))
    (hM : CG β (.App f a) M) (hc : (Term.App f a).Closed 0) (hside : Side β (.App f a)) :
    ∃ M', CG β (.App f a') M' ∧
      MeasLt (M', Term.weight β (.App f a')) (M, Term.weight β (.App f a)) := by
  have iha := fun M hM hca hsa' => ih (by simp only [Term.size]; omega) hsa M hM hca hsa'
  generalize hu : Term.App f a = u0 at hM
  cases hM
  case app hf ha =>
    cases hu
    obtain ⟨M', h, hlt⟩ := iha _ ha hc.2 (hside.of (.app_a .root))
    exact ⟨_ ++ M', CG.app hf h,
        by simpa [Term.weight] using MeasLt.frame_l hlt _ (Term.weight β f)⟩
  case ref hk hp hMs =>
    obtain ⟨ys, rfl, rfl⟩ := Term.app_eq_apps (h := .Ref _) (by trivial) hu
    rw [← Term.apps_snoc] at hc hside ⊢
    exact SStep.meas_ref_arg (us2 := []) hk hsa iha hp hMs hc hside
  case beta _ hd _ =>
    rcases Term.app_eq_apps_cons (by trivial) hu with ⟨rfl, rfl, rfl⟩ | ⟨ys, rfl, rfl⟩
    · exact (Deep.no_sstep hsa hd).elim
    · exact (Deep.app_lam (Deep.apps_inv ys hdf)).elim
  case matc _ _ _ _ hd _ =>
    rcases Term.app_eq_apps_cons (by trivial) hu with ⟨rfl, rfl, rfl⟩ | ⟨ys, rfl, rfl⟩
    · exact (Deep.no_sstep hsa (Deep.ctr hd)).elim
    · exact (Deep.app_mat (Deep.apps_inv ys hdf) _ _ _ rfl).elim
  case matm _ _ hd _ =>
    rcases Term.app_eq_apps_cons (by trivial) hu with ⟨rfl, rfl, rfl⟩ | ⟨ys, rfl, rfl⟩
    · exact (Deep.no_sstep hsa (Deep.ctr hd)).elim
    · exact (Deep.app_mat (Deep.apps_inv ys hdf) _ _ _ rfl).elim
  all_goals (have e := congrArg Term.spine hu; simp [Term.spine] at e)

theorem SStep.meas_let_v (hsv : SStep β v v')
    (ih : ∀ M, CG β v M → v.Closed 0 → Side β v →
      ∃ M', CG β v' M' ∧ MeasLt (M', Term.weight β v') (M, Term.weight β v))
    (hM : CG β (.Let q v b) M) (hc : (Term.Let q v b).Closed 0) (hside : Side β (.Let q v b)) :
    ∃ M', CG β (.Let q v' b) M' ∧
      MeasLt (M', Term.weight β (.Let q v' b)) (M, Term.weight β (.Let q v b)) := by
  generalize hu : Term.Let q v b = u0 at hM
  cases hM
  case let_ hv hb =>
    cases hu
    obtain ⟨M', h, hlt⟩ := ih _ hv hc.1 (hside.of (.let_v .root))
    refine ⟨M' ++ _, CG.let_ h hb, ?_⟩
    simp only [Term.weight]
    exact (MeasLt.frame_r hlt _ (1 + Term.weight β b)).cast (by omega) (by omega)
  case letC _ hd _ => cases hu; exact (Deep.no_sstep hsv hd).elim
  all_goals (have e := congrArg Term.spine hu; simp [Term.spine_apps_of, Term.spine] at e)

theorem SStep.meas_rwt_e
    (ih : ∀ M, CG β e M → e.Closed 0 → Side β e →
      ∃ M', CG β e' M' ∧ MeasLt (M', Term.weight β e') (M, Term.weight β e))
    (hM : CG β (.Rwt e P f) M) (hc : (Term.Rwt e P f).Closed 0) (hside : Side β (.Rwt e P f)) :
    ∃ M', CG β (.Rwt e' P f) M' ∧
      MeasLt (M', Term.weight β (.Rwt e' P f)) (M, Term.weight β (.Rwt e P f)) := by
  generalize hu : Term.Rwt e P f = u0 at hM
  cases hM
  case rwt he hf =>
    cases hu
    obtain ⟨M', h, hlt⟩ := ih _ he hc.1 (hside.of (.rwt_e .root))
    refine ⟨M' ++ _, CG.rwt h hf, ?_⟩
    simp only [Term.weight]
    exact (MeasLt.frame_r hlt _ (1 + Term.weight β f)).cast (by omega) (by omega)
  all_goals (have e := congrArg Term.spine hu; simp [Term.spine_apps_of, Term.spine] at e)

theorem SStep.meas_min_a
    (ih : ∀ M, CG β a M → a.Closed 0 → Side β a →
      ∃ M', CG β a' M' ∧ MeasLt (M', Term.weight β a') (M, Term.weight β a))
    (hM : CG β (.Min a b) M) (hc : (Term.Min a b).Closed 0) (hside : Side β (.Min a b)) :
    ∃ M', CG β (.Min a' b) M' ∧
      MeasLt (M', Term.weight β (.Min a' b)) (M, Term.weight β (.Min a b)) := by
  obtain ⟨Ma, Mb, ha, hb, rfl⟩ := SStep.meas_min hM
  obtain ⟨M', h, hlt⟩ := ih _ ha hc.1 (hside.of (.min_a .root))
  refine ⟨M' ++ _, CG.min h hb, ?_⟩
  simp only [Term.weight]
  exact (MeasLt.frame_r hlt _ (1 + Term.weight β b)).cast (by omega) (by omega)

theorem SStep.meas_min_b
    (ih : ∀ M, CG β b M → b.Closed 0 → Side β b →
      ∃ M', CG β b' M' ∧ MeasLt (M', Term.weight β b') (M, Term.weight β b))
    (hM : CG β (.Min a b) M) (hc : (Term.Min a b).Closed 0) (hside : Side β (.Min a b)) :
    ∃ M', CG β (.Min a b') M' ∧
      MeasLt (M', Term.weight β (.Min a b')) (M, Term.weight β (.Min a b)) := by
  obtain ⟨Ma, Mb, ha, hb, rfl⟩ := SStep.meas_min hM
  obtain ⟨M', h, hlt⟩ := ih _ hb hc.2 (hside.of (.min_b .root))
  refine ⟨_ ++ M', CG.min ha h, ?_⟩
  simp only [Term.weight]
  exact (MeasLt.frame_l hlt _ (1 + Term.weight β a)).cast (by omega) (by omega)

theorem SStep.meas_aux : ∀ (n : Nat) {u u' : Term}, Term.size u ≤ n → SStep β u u' →
    ∀ (M : List Charge), CG β u M → u.Closed 0 → Side β u →
    ∃ M', CG β u' M' ∧ MeasLt (M', Term.weight β u') (M, Term.weight β u) := by
  intro n
  induction n with
  | zero => intro u u' hn; have := Term.size_pos u; omega
  | succ n ih =>
    intro u u' hn hs
    have ih' : ∀ {t t' : Term}, Term.size t < Term.size u → SStep β t t' →
        ∀ M, CG β t M → t.Closed 0 → Side β t →
        ∃ M', CG β t' M' ∧ MeasLt (M', Term.weight β t') (M, Term.weight β t) :=
      fun hlt hs' => ih (by omega) hs'
    cases hs with
    | beta hd => exact fun M hM hc hside => SStep.meas_beta hc.2 hM (hside.1 _ _ .root hd)
    | let_ hd => exact fun M hM hc hside => SStep.meas_let hc.1 hM (hside.2.1 _ _ _ .root hd)
    | dref hk hsp hl hds => exact fun M hM _ hside => SStep.meas_dref hk hsp hl hds hM hside
    | aref hk h0 => exact fun M hM _ _ => SStep.meas_aref hk h0 hM
    | matc hk _ hp _ _ => exact fun M hM _ _ => SStep.meas_matc hk hp hM
    | matm hne _ => exact fun M hM _ _ => SStep.meas_matm hne hM
    | rwt => exact fun M hM _ _ => SStep.meas_rwt hM
    | minLM =>
      intro M hM _ _
      obtain ⟨Ma, Mb, ha, hb, rfl⟩ := SStep.meas_min hM
      rw [CG.qua_head ha]
      exact ⟨_, hb, MeasLt.mle MLe.refl (by simp only [Term.weight]; omega)⟩
    | minLN =>
      intro M hM _ _
      exact ⟨[], .qua, MeasLt.sub (Sub.nil _) (by simp only [Term.weight]; omega)⟩
    | minRM =>
      intro M hM _ _
      obtain ⟨Ma, Mb, ha, hb, rfl⟩ := SStep.meas_min hM
      rw [CG.qua_head hb]
      exact ⟨_, ha, MeasLt.mle (by simpa using MLe.refl) (by simp only [Term.weight]; omega)⟩
    | minRN =>
      intro M hM _ _
      exact ⟨[], .qua, MeasLt.sub (Sub.nil _) (by simp only [Term.weight]; omega)⟩
    | minLL =>
      intro M hM _ _
      exact ⟨[], .qua, MeasLt.sub (Sub.nil _) (by simp only [Term.weight]; omega)⟩
    | app_f hsf => exact fun M hM hc hside => SStep.meas_app_f hsf ih' hM hc hside
    | app_a hdf hsa => exact fun M hM hc hside => SStep.meas_app_a hdf hsa ih' hM hc hside
    | let_v hsv =>
      exact fun M hM hc hside => SStep.meas_let_v hsv
        (fun M hM hc' hs' => ih' (by simp only [Term.size]; omega) hsv M hM hc' hs') hM hc hside
    | rwt_e hse =>
      exact fun M hM hc hside => SStep.meas_rwt_e
        (fun M hM hc' hs' => ih' (by simp only [Term.size]; omega) hse M hM hc' hs') hM hc hside
    | min_a hsa =>
      exact fun M hM hc hside => SStep.meas_min_a
        (fun M hM hc' hs' => ih' (by simp only [Term.size]; omega) hsa M hM hc' hs') hM hc hside
    | min_b _ hsb =>
      exact fun M hM hc hside => SStep.meas_min_b
        (fun M hM hc' hs' => ih' (by simp only [Term.size]; omega) hsb M hM hc' hs') hM hc hside

-- N4a: every strategy step on a closed term decreases the measure, given
-- the typed side facts at the strategy's positions (Side; its third
-- component, the unfold, is N4b's Unfold.meas_full)
theorem SStep.meas (hs : SStep β u u') (hM : CG β u M) (hc : u.Closed 0) (hside : Side β u) :
    ∃ M', CG β u' M' ∧ MeasLt (M', Term.weight β u') (M, Term.weight β u) :=
  SStep.meas_aux _ (Nat.le_refl _) hs M hM hc hside

-- ----------------------------------------------------------------------------
-- N4b — the unfold. The order kernel on pins, the environment of a leaf
-- (closed values for the columns and fields; inner binders keep their
-- variables), the descent verdicts in the erased book
-- ----------------------------------------------------------------------------

-- the instantiation of a term by an environment: entry i (innermost first)
-- is a closed value for the variable, or none — a binder kept as a variable
def Term.inst (d : Nat) : List (Option Term) → Term → Term
  | [],           t => t
  | some v :: ρ,  t => Term.subst d v (Term.inst (d + 1) ρ t)
  | none :: ρ,    t => Term.inst (d + 1) ρ t

-- every value of an environment is closed
def Env.Closed (ρ : List (Option Term)) : Prop := ∀ v, some v ∈ ρ → v.Closed 0

theorem Env.Closed.tail (h : Env.Closed (e :: ρ)) : Env.Closed ρ :=
  fun v hv => h v (by simp [hv])

theorem Env.Closed.head (h : Env.Closed (some v :: ρ)) : v.Closed 0 := h v (by simp)

theorem Term.inst_apps (d : Nat) : ∀ (ρ : List (Option Term)) (f : Term) (xs : List Term),
    Term.inst d ρ (Term.apps f xs) = Term.apps (Term.inst d ρ f) (xs.map (Term.inst d ρ)) := by
  intro ρ
  induction ρ generalizing d with
  | nil => intro f xs; simp [Term.inst]
  | cons e ρ ih =>
    intro f xs
    cases e with
    | none => simp only [Term.inst]; exact ih (d + 1) f xs
    | some v =>
      simp only [Term.inst]
      rw [ih (d + 1) f xs, Term.subst_apps, List.map_map]
      rfl

theorem Term.inst_app (d : Nat) (ρ : List (Option Term)) (f x : Term) :
    Term.inst d ρ (.App f x) = .App (Term.inst d ρ f) (Term.inst d ρ x) :=
  Term.inst_apps d ρ f [x]

theorem Term.inst_closed (d : Nat) : ∀ (ρ : List (Option Term)) {t : Term}, t.Closed d →
    Term.inst d ρ t = t := by
  intro ρ
  induction ρ generalizing d with
  | nil => intro t _; rfl
  | cons e ρ ih =>
    intro t ht
    cases e with
    | none => simp only [Term.inst]; exact ih (d + 1) (Term.Closed.mono t d (d + 1) ht (by omega))
    | some v =>
      simp only [Term.inst]
      rw [ih (d + 1) (Term.Closed.mono t d (d + 1) ht (by omega)),
        Term.subst_closed t d d v ht (Nat.le_refl d)]

theorem Term.inst_lam (d : Nat) : ∀ (ρ : List (Option Term)), Env.Closed ρ → ∀ (f : Term),
    Term.inst d ρ (.Lam f) = .Lam (Term.inst (d + 1) ρ f) := by
  intro ρ
  induction ρ generalizing d with
  | nil => intro _ f; rfl
  | cons e ρ ih =>
    intro hc f
    cases e with
    | none => simp only [Term.inst]; exact ih (d + 1) hc.tail f
    | some v =>
      simp only [Term.inst]
      rw [ih (d + 1) hc.tail f]
      simp only [Term.subst, Term.shift_closed v 0 0 hc.head (Nat.le_refl 0)]

theorem Term.inst_mat (d : Nat) : ∀ (ρ : List (Option Term)) (a c : Nat) (h m : Term),
    Term.inst d ρ (.Mat a c h m) = .Mat a c (Term.inst d ρ h) (Term.inst d ρ m) := by
  intro ρ
  induction ρ generalizing d with
  | nil => intro a c h m; rfl
  | cons e ρ ih =>
    intro a c h m
    cases e with
    | none => simp only [Term.inst]; exact ih (d + 1) a c h m
    | some v => simp only [Term.inst]; rw [ih (d + 1)]; rfl

theorem Term.inst_min (d : Nat) : ∀ (ρ : List (Option Term)) (a b : Term),
    Term.inst d ρ (.Min a b) = .Min (Term.inst d ρ a) (Term.inst d ρ b) := by
  intro ρ
  induction ρ generalizing d with
  | nil => intro a b; rfl
  | cons e ρ ih =>
    intro a b
    cases e with
    | none => simp only [Term.inst]; exact ih (d + 1) a b
    | some v => simp only [Term.inst]; rw [ih (d + 1)]; rfl

theorem Term.inst_rwt (d : Nat) : ∀ (ρ : List (Option Term)) (e P f : Term),
    Term.inst d ρ (.Rwt e P f) = .Rwt (Term.inst d ρ e) (Term.inst d ρ P) (Term.inst d ρ f) := by
  intro ρ
  induction ρ generalizing d with
  | nil => intro e P f; rfl
  | cons e0 ρ ih =>
    intro e P f
    cases e0 with
    | none => simp only [Term.inst]; exact ih (d + 1) e P f
    | some v => simp only [Term.inst]; rw [ih (d + 1)]; rfl

-- the instantiation of a variable: below the depth it is kept; at an
-- entry it is the value, or a variable for a kept entry
theorem Term.inst_var_lt (d : Nat) : ∀ (ρ : List (Option Term)) (i : Nat), i < d →
    Term.inst d ρ (.Var i) = .Var i := by
  intro ρ
  induction ρ generalizing d with
  | nil => intro i _; rfl
  | cons e ρ ih =>
    intro i hi
    cases e with
    | none => simp only [Term.inst]; exact ih (d + 1) i (by omega)
    | some v =>
      simp only [Term.inst]
      rw [ih (d + 1) i (by omega)]
      simp only [Term.subst]
      rw [if_neg (by omega), if_neg (by omega)]

theorem Term.inst_var (d : Nat) : ∀ (ρ : List (Option Term)) (i : Nat), Env.Closed ρ →
    (∀ v, ρ[i]? = some (some v) → Term.inst d ρ (.Var (d + i)) = v) ∧
    (ρ[i]? = some none → ∃ j, d ≤ j ∧ Term.inst d ρ (.Var (d + i)) = .Var j) ∧
    (ρ[i]? = none → ∃ j, d ≤ j ∧ Term.inst d ρ (.Var (d + i)) = .Var j) := by
  intro ρ
  induction ρ generalizing d with
  | nil =>
    intro i _
    exact ⟨fun v h => by simp at h, fun h => by simp at h, fun _ => ⟨_, by omega, rfl⟩⟩
  | cons e ρ ih =>
    intro i hc
    cases i with
    | zero =>
      simp only [Nat.add_zero]
      cases e with
      | none =>
        refine ⟨fun v h => by simp at h, fun _ => ?_, fun h => by simp at h⟩
        simp only [Term.inst]
        exact ⟨d, Nat.le_refl d, Term.inst_var_lt (d + 1) ρ d (by omega)⟩
      | some w =>
        refine ⟨fun v h => ?_, fun h => by simp at h, fun h => by simp at h⟩
        simp at h; subst h
        simp only [Term.inst]
        rw [Term.inst_var_lt (d + 1) ρ d (by omega)]
        simp [Term.subst]
    | succ i =>
      have := ih (d + 1) i hc.tail
      rw [show d + (i + 1) = d + 1 + i by omega]
      cases e with
      | none =>
        simp only [Term.inst]
        refine ⟨fun v h => this.1 v (by rwa [List.getElem?_cons_succ] at h), fun h => ?_, fun h =>
            ?_⟩
        · obtain ⟨j, hj, e⟩ := this.2.1 (by rwa [List.getElem?_cons_succ] at h)
          exact ⟨j, by omega, e⟩
        · obtain ⟨j, hj, e⟩ := this.2.2 (by rwa [List.getElem?_cons_succ] at h)
          exact ⟨j, by omega, e⟩
      | some w =>
        refine ⟨fun v h => ?_, fun h => ?_, fun h => ?_⟩
        · simp only [Term.inst]; rw [this.1 v (by rwa [List.getElem?_cons_succ] at h)]
          exact Term.subst_closed v 0 d w (hc.tail v (List.mem_of_getElem?
              (by rwa [List.getElem?_cons_succ] at h))) (Nat.zero_le d)
        · obtain ⟨j, hj, e⟩ := this.2.1 (by rwa [List.getElem?_cons_succ] at h)
          simp only [Term.inst]; rw [e]
          simp only [Term.subst]
          rw [if_neg (by omega), if_pos (by omega)]
          exact ⟨j - 1, by omega, rfl⟩
        · obtain ⟨j, hj, e⟩ := this.2.2 (by rwa [List.getElem?_cons_succ] at h)
          simp only [Term.inst]; rw [e]
          simp only [Term.subst]
          rw [if_neg (by omega), if_pos (by omega)]
          exact ⟨j - 1, by omega, rfl⟩

-- the environment as a list of closed values (every entry substituted)
def Term.instL (d : Nat) (ρ : List Term) (t : Term) : Term := Term.inst d (ρ.map some) t

theorem Env.Closed.map {ρ : List Term} (hc : ∀ v ∈ ρ, Term.Closed 0 v) : Env.Closed (ρ.map some) :=
    by
  intro v hv
  simp only [List.mem_map] at hv
  obtain ⟨w, hw, e⟩ := hv
  cases e; exact hc _ hw

theorem Term.instL_apps (d : Nat) (ρ : List Term) (f : Term) (xs : List Term) :
    Term.instL d ρ (Term.apps f xs) = Term.apps (Term.instL d ρ f) (xs.map (Term.instL d ρ)) := by
  unfold Term.instL; rw [Term.inst_apps]

theorem Term.instL_closed (d : Nat) (ρ : List Term) {t : Term} (ht : t.Closed d) :
    Term.instL d ρ t = t := Term.inst_closed d _ ht

theorem Term.instL_lam (d : Nat) (ρ : List Term) (hc : ∀ v ∈ ρ, Term.Closed 0 v) (f : Term) :
    Term.instL d ρ (.Lam f) = .Lam (Term.instL (d + 1) ρ f) := Term.inst_lam d _ (Env.Closed.map
        hc) f

theorem Term.instL_mat (d : Nat) (ρ : List Term) (a c : Nat) (h m : Term) :
    Term.instL d ρ (.Mat a c h m) = .Mat a c (Term.instL d ρ h) (Term.instL d ρ m) :=
  Term.inst_mat d _ a c h m

theorem Term.instL_var_some (d : Nat) (ρ : List Term) (hc : ∀ v ∈ ρ, Term.Closed 0 v)
    (h : ρ[i]? = some v) : Term.instL d ρ (.Var (d + i)) = v :=
  (Term.inst_var d (ρ.map some) i (Env.Closed.map hc)).1 v (by simp [h])

theorem Term.instL_shift (d : Nat) : ∀ (ρ : List Term), (∀ v ∈ ρ, Term.Closed 0 v) → ∀ (t : Term),
    Term.instL (d + 1) ρ (Term.shift 0 t) = Term.shift 0 (Term.instL d ρ t) := by
  intro ρ
  induction ρ generalizing d with
  | nil => intro _ t; rfl
  | cons v ρ ih =>
    intro hc t
    have h1 := ih (d + 1) (fun v hv => hc v (by simp [hv])) t
    simp only [Term.instL, List.map_cons, Term.inst] at h1 ⊢
    rw [h1]
    exact Term.subst_shift0_closed (hc v (by simp)) d _

-- the variables of a pattern lie above the inner binders
def Term.VarsGe (D : Nat) (p : Term) : Prop := ∀ i, i < D → Term.occ i p = 0

theorem Term.VarsGe.field (h : Term.VarsGe D (Term.apps (.Ctr a c) ys)) (hy : y ∈ ys) :
    Term.VarsGe D y := by
  intro i hi
  have := h i hi
  rw [Term.occ_apps] at this
  have := le_sum_of_mem _ _ (List.mem_map_of_mem (f := Term.occ i) hy)
  omega

theorem Term.VarsGe.shift (h : Term.VarsGe D p) : Term.VarsGe (D + 1) (Term.shift 0 p) := by
  intro i hi
  cases i with
  | zero => exact Term.occ_shift_self p 0
  | succ i => rw [Term.occ_shift_ge p i 0 (Nat.zero_le i)]; exact h i (by omega)

theorem Term.VarsGe.var (h : Term.VarsGe D (.Var i)) : D ≤ i :=
  Nat.le_of_not_lt fun hlt => by have := h i hlt; simp [Term.occ] at this

theorem PEqs.length : ∀ {xs ys : List Term}, PEqs β xs ys → xs.length = ys.length
  | _, _, .nil => rfl
  | _, _, .cons _ hs => by simp [PEqs.length hs]

mutual
theorem PLts.length : ∀ {xs ys : List Term}, PLts β xs ys → xs.length = ys.length
  | _, _, .here _ hs => by simp [PLes.length hs]
  | _, _, .there _ hs => by simp [PLts.length hs]
theorem PLes.length : ∀ {xs ys : List Term}, PLes β xs ys → xs.length = ys.length
  | _, _, .nil => rfl
  | _, _, .consEq _ hs => by simp [PLes.length hs]
  | _, _, .consLt _ hs => by simp [PLes.length hs]
end

-- the shapes of a verdict's sides
theorem PEq.shape (h : PEq β t p) :
    (∃ i, t = .Var i ∧ p = .Var i) ∨
    (∃ a c A C ps xs ys, Book.adt β a = some A ∧ AdtD.ctr A c = some C ∧ ps.length = A.pn ∧
      xs.length = C.fn ∧ ys.length = C.fn ∧ t = Term.apps (.Ctr a c) (ps ++ xs) ∧
      p = Term.apps (.Ctr a c) ys ∧ PEqs β xs ys) := by
  cases h with
  | var => exact .inl ⟨_, rfl, rfl⟩
  | ctr hk hc hlp hlx hxy =>
    exact .inr ⟨_, _, _, _, _, _, _, hk, hc, hlp, hlx,
        by rw [← hxy.length]; exact hlx, rfl, rfl, hxy⟩

theorem PEq.var_inv (h : PEq β (.Var i) p) : p = .Var i := by
  rcases h.shape with ⟨j, e1, e2⟩ | ⟨_, _, _, _, _, _, _, _, _, _, _, _, e1, _, _⟩
  · cases e1; exact e2
  · exact Term.noConfusion (Term.apps_head_inv (xs := []) (by trivial) (by trivial) e1).1

theorem PLt.pat (h : PLt β t p) : ∃ a c A C ys, Book.adt β a = some A ∧ AdtD.ctr A c = some C ∧
    ys.length = C.fn ∧ p = Term.apps (.Ctr a c) ys := by
  cases h with
  | subEq hk hc hly _ _ => exact ⟨_, _, _, _, _, hk, hc, hly, rfl⟩
  | subLt hk hc hly _ _ => exact ⟨_, _, _, _, _, hk, hc, hly, rfl⟩
  | ctr hk hc _ hlx hxy => exact ⟨_, _, _, _, _, hk, hc, by rw [← hxy.length]; exact hlx, rfl⟩

theorem PLt.shape (h : PLt β t p) : (∃ i, t = .Var i) ∨ (∃ a c vs, t = Term.apps (.Ctr a c) vs) :=
  match h with
  | .subEq _ _ _ _ hpe => (PEq.shape hpe).elim (fun ⟨i, e, _⟩ => .inl ⟨i, e⟩)
      (fun ⟨a, c, _, _, ps, xs, _, _, _, _, _, _, e, _, _⟩ => .inr ⟨a, c, ps ++ xs, e⟩)
  | .subLt _ _ _ _ hpl => PLt.shape hpl
  | .ctr _ _ _ _ _ => .inr ⟨_, _, _, rfl⟩

-- a kept inner variable is no verdict's side against a pattern above it
theorem PLt.var_absurd (hi : i < D) : ∀ {t p : Term}, PLt β t p → t = .Var i →
    Term.VarsGe D p → False
  | _, _, .subEq _ _ _ hy hpe, e, hp => by
    subst e
    rw [hpe.var_inv] at hy
    exact absurd (hp.field hy).var (by omega)
  | _, _, .subLt _ _ _ hy hpl, e, hp => PLt.var_absurd hi hpl e (hp.field hy)
  | _, _, .ctr _ _ _ _ _, e, _ =>
    Term.noConfusion (Term.apps_head_inv (ys := []) (by trivial) (by trivial) e).1

-- a context of rigid binders expands nothing
theorem Ctx.δ_rigid : ∀ (Γ : Ctx), (∀ b ∈ Γ, b.v = none) → ∀ d t, Ctx.δ Γ d t = t := by
  intro Γ
  induction Γ with
  | nil => intro _ d t; rfl
  | cons b Γ ih =>
    intro h d t
    simp only [Ctx.δ, h b (by simp)]
    exact ih (fun b hb => h b (by simp [hb])) (d + 1) t

-- DomP β βe ρ D x e: the instantiated erasure e of the source x carries the
-- descent facts against every pattern p over the outer variables: an EQ
-- verdict makes e a closed deep term no larger than the pattern's value,
-- an LT verdict strictly smaller
def DomP (β βe : Book) (ρ : List Term) (D : Nat) (x e : Term) : Prop :=
  ∀ p, Term.VarsGe D p →
    (PEq β x p → e.Closed 0 ∧ Deep βe e ∧ Term.csize βe e ≤ Term.csize βe (Term.instL D ρ p)) ∧
    (PLt β x p → e.Closed 0 ∧ Deep βe e ∧ Term.csize βe e < Term.csize βe (Term.instL D ρ p))

-- a pattern's value has a positive size
theorem Term.csize_pat_pos (hE : Book.Era β 0 β βe) (hk : Book.adt β a = some A)
    (hc : AdtD.ctr A c = some C) (hly : ys.length = C.fn) (ρ : List Term) (D : Nat) :
    1 ≤ Term.csize βe (Term.instL D ρ (Term.apps (.Ctr a c) ys)) := by
  rw [Term.instL_apps, Term.instL_closed _ _ (t := .Ctr _ _) trivial, Term.csize_fields (hE.adt hk)
      hc (by simpa using hly)]
  omega

-- a source verdict's field is dominated by the whole
theorem Term.csize_pat_field (hE : Book.Era β 0 β βe) (hk : Book.adt β a = some A)
    (hc : AdtD.ctr A c = some C) (hly : ys.length = C.fn) (hy : y ∈ ys) (ρ : List Term) (D : Nat) :
    Term.csize βe (Term.instL D ρ y) < Term.csize βe (Term.instL D ρ (Term.apps (.Ctr a c) ys)) :=
        by
  rw [Term.instL_apps, Term.instL_closed _ _ (t := .Ctr _ _) trivial]
  exact Term.csize_field_lt (hE.adt hk) hc
    (by simpa [hly] using List.mem_map_of_mem (f := Term.instL D ρ) hy)

-- the token (a dead argument) is dominated by every verdict
theorem DomP.qnt (hE : Book.Era β 0 β βe) : DomP β βe ρ D x .Qnt := by
  intro p _
  refine ⟨fun _ => ⟨trivial, .qnt, by rw [Term.csize_tok]; exact Nat.zero_le _⟩, fun h => ?_⟩
  obtain ⟨a, c, A, C, ys, hk, hc, hly, rfl⟩ := h.pat
  exact ⟨trivial, .qnt, by rw [Term.csize_tok]; exact Term.csize_pat_pos hE hk hc hly ρ D⟩

-- an outer variable: its value against the patterns
theorem DomP.var_plt (hE : Book.Era β 0 β βe) (hv : Term.instL D ρ (.Var i) = v) :
    ∀ {t p : Term}, PLt β t p → t = .Var i → Term.csize βe v < Term.csize βe (Term.instL D ρ p)
  | _, _, .subEq hk hc hly hy hpe, e => by
    subst e
    rw [hpe.var_inv] at hy
    rw [← hv]; exact Term.csize_pat_field hE hk hc hly hy ρ D
  | _, _, .subLt hk hc hly hy hpl, e =>
    Nat.lt_trans (DomP.var_plt hE hv hpl e) (Term.csize_pat_field hE hk hc hly hy ρ D)
  | _, _, .ctr _ _ _ _ _, e =>
    Term.noConfusion (Term.apps_head_inv (ys := []) (by trivial) (by trivial) e).1

theorem DomP.var (hE : Book.Era β 0 β βe) (hv : Term.instL D ρ (.Var i) = v) (hc : v.Closed 0)
    (hd : Deep βe v) : DomP β βe ρ D (.Var i) v := by
  intro p _
  refine ⟨fun h => ⟨hc, hd, ?_⟩, fun h => ⟨hc, hd, DomP.var_plt hE hv h rfl⟩⟩
  rw [h.var_inv, hv]; exact Nat.le_refl _

-- a kept inner variable is never a verdict's side (the patterns lie above)
theorem DomP.kept (hi : i < D) (e : Term) : DomP β βe ρ D (.Var i) e := by
  intro p hp
  refine ⟨fun h => ?_, fun h => (PLt.var_absurd hi h rfl hp).elim⟩
  rw [h.var_inv] at hp
  exact absurd hp.var (by omega)

theorem Quant.add_ne_none (ha : a ≠ .None) : Quant.add a b ≠ .None := by
  cases a <;> cases b <;> simp_all [Quant.add]

theorem Quant.add_ne_none' (hb : b ≠ .None) : Quant.add a b ≠ .None := by
  cases a <;> cases b <;> simp_all [Quant.add]

theorem Quant.join_ne_none (ha : a ≠ .None) : Quant.join a b ≠ .None := by
  cases a <;> cases b <;> simp_all [Quant.join]

theorem Quant.join_ne_none' (hb : b ≠ .None) : Quant.join a b ≠ .None := by
  cases a <;> cases b <;> simp_all [Quant.join]

theorem Quant.add_many (ha : a ≠ .None) (hb : b ≠ .None) : Quant.add a b = .Many := by
  cases a <;> cases b <;> simp_all [Quant.add]

theorem Quant.add_many_l (ha : a = .Many) : Quant.add a b = .Many := by
  cases a <;> cases b <;> simp_all [Quant.add]

theorem Quant.add_many_r (hb : b = .Many) : Quant.add a b = .Many := by
  cases a <;> cases b <;> simp_all [Quant.add]

theorem Quant.join_many_l (ha : a = .Many) : Quant.join a b = .Many := by
  cases a <;> cases b <;> simp_all [Quant.join]

theorem Quant.join_many_r (hb : b = .Many) : Quant.join a b = .Many := by
  cases a <;> cases b <;> simp_all [Quant.join]

-- ----------------------------------------------------------------------------
-- the pending erased spine: each entry an argument's source, erasure and
-- uses, with its pricing and descent facts once instantiated
-- ----------------------------------------------------------------------------

def esUses : List (Term × Term × Uses) → Uses
  | [] => Uses.zero
  | e :: es => Uses.add e.2.2 (esUses es)

-- pointwise sums along verdict lists
theorem sum_le_pointwise (f g : Term → Nat) : ∀ (l1 l2 : List Term), l1.length = l2.length →
    (∀ (j : Nat) a b, l1[j]? = some a → l2[j]? = some b → f a ≤ g b) → (l1.map f).sum ≤ (l2.map
        g).sum := by
  intro l1
  induction l1 with
  | nil => intro l2 _ _; simp
  | cons a l1 ih =>
    intro l2 hl h
    cases l2 with
    | nil => simp at hl
    | cons b l2 =>
      simp only [List.map_cons, List.sum_cons]
      have := h 0 a b (by simp) (by simp)
      have := ih l2 (by simpa using hl) (fun j a b ha hb => h (j + 1) a b (by simpa using ha)
          (by simpa using hb))
      omega

theorem PEqs.get : ∀ {xs ys : List Term}, PEqs β xs ys → ∀ (j : Nat) {x y : Term},
    xs[j]? = some x → ys[j]? = some y → PEq β x y
  | _, _, .nil, j, _, _, hx, _ => by simp at hx
  | _, _, .cons h hs, 0, _, _, hx, hy => by simp at hx hy; subst hx hy; exact h
  | _, _, .cons h hs, j + 1, _, _, hx, hy => PEqs.get hs j (by simpa using hx) (by simpa using hy)

-- the lists of an LT verdict: a strict sum, given pointwise dominations
mutual
theorem PLts.sum_lt (f g : Term → Nat) : ∀ {xs ys : List Term}, PLts β xs ys → ∀ (es : List Term),
    es.length = xs.length →
    (∀ (j : Nat) x y e, xs[j]? = some x → ys[j]? = some y → es[j]? = some e →
      (PEq β x y → f e ≤ g y) ∧ (PLt β x y → f e < g y)) →
    (es.map f).sum < (ys.map g).sum
  | _, _, .here h hs, e :: es, hl, hd => by
    simp only [List.map_cons, List.sum_cons]
    have h1 := (hd 0 _ _ e (by simp) (by simp) (by simp)).2 h
    have h2 := PLes.sum_le f g hs es (by simpa using hl)
      (fun j x y e hx hy he => hd (j + 1) x y e (by simpa using hx) (by simpa using hy)
          (by simpa using he))
    omega
  | _, _, .there h hs, e :: es, hl, hd => by
    simp only [List.map_cons, List.sum_cons]
    have h1 := (hd 0 _ _ e (by simp) (by simp) (by simp)).1 h
    have h2 := PLts.sum_lt f g hs es (by simpa using hl)
      (fun j x y e hx hy he => hd (j + 1) x y e (by simpa using hx) (by simpa using hy)
          (by simpa using he))
    omega
  | _, _, .here _ _, [], hl, _ => by simp at hl
  | _, _, .there _ _, [], hl, _ => by simp at hl
theorem PLes.sum_le (f g : Term → Nat) : ∀ {xs ys : List Term}, PLes β xs ys → ∀ (es : List Term),
    es.length = xs.length →
    (∀ (j : Nat) x y e, xs[j]? = some x → ys[j]? = some y → es[j]? = some e →
      (PEq β x y → f e ≤ g y) ∧ (PLt β x y → f e < g y)) →
    (es.map f).sum ≤ (ys.map g).sum
  | _, _, .nil, [], _, _ => Nat.le_refl _
  | _, _, .nil, _ :: _, hl, _ => by simp at hl
  | _, _, .consEq h hs, e :: es, hl, hd => by
    simp only [List.map_cons, List.sum_cons]
    have h1 := (hd 0 _ _ e (by simp) (by simp) (by simp)).1 h
    have h2 := PLes.sum_le f g hs es (by simpa using hl)
      (fun j x y e hx hy he => hd (j + 1) x y e (by simpa using hx) (by simpa using hy)
          (by simpa using he))
    omega
  | _, _, .consLt h hs, e :: es, hl, hd => by
    simp only [List.map_cons, List.sum_cons]
    have h1 := (hd 0 _ _ e (by simp) (by simp) (by simp)).2 h
    have h2 := PLes.sum_le f g hs es (by simpa using hl)
      (fun j x y e hx hy he => hd (j + 1) x y e (by simpa using hx) (by simpa using hy)
          (by simpa using he))
    omega
  | _, _, .consEq _ _, [], hl, _ => by simp at hl
  | _, _, .consLt _ _, [], hl, _ => by simp at hl
end

mutual
theorem PLts.get : ∀ {xs ys : List Term}, PLts β xs ys → ∀ (j : Nat) {x y : Term},
    xs[j]? = some x → ys[j]? = some y → PEq β x y ∨ PLt β x y
  | _, _, .here h _, 0, _, _, hx, hy => by simp at hx hy; subst hx hy; exact .inr h
  | _, _, .there h _, 0, _, _, hx, hy => by simp at hx hy; subst hx hy; exact .inl h
  | _, _, .here _ hs, j + 1, _, _, hx, hy => PLes.get hs j (by simpa using hx) (by simpa using hy)
  | _, _, .there _ hs, j + 1, _, _, hx, hy => PLts.get hs j (by simpa using hx) (by simpa using hy)
theorem PLes.get : ∀ {xs ys : List Term}, PLes β xs ys → ∀ (j : Nat) {x y : Term},
    xs[j]? = some x → ys[j]? = some y → PEq β x y ∨ PLt β x y
  | _, _, .nil, _, _, _, hx, _ => by simp at hx
  | _, _, .consEq h _, 0, _, _, hx, hy => by simp at hx hy; subst hx hy; exact .inl h
  | _, _, .consLt h _, 0, _, _, hx, hy => by simp at hx hy; subst hx hy; exact .inr h
  | _, _, .consEq _ hs, j + 1, _, _, hx, hy => PLes.get hs j (by simpa using hx) (by simpa using hy)
  | _, _, .consLt _ hs, j + 1, _, _, hx, hy => PLes.get hs j (by simpa using hx) (by simpa using hy)
end

-- the fields of an instantiated constructor spine, against a pattern's
theorem DomP.ctr_fields {A : AdtD} {C : CtrD} {src era ps xs ys : List Term}
    (hlen : era.length = src.length)
    (hpar : ∀ (i : Nat) e, i < A.pn → era[i]? = some e → e = .Qnt)
    (hdom : ∀ (i : Nat) x e, src[i]? = some x → era[i]? = some e → DomP β βe ρ D x e)
    (hsrc : src = ps ++ xs) (hlp : ps.length = A.pn) (hlx : xs.length = C.fn) (hly : ys.length =
        C.fn)
    (hrel : ∀ (j : Nat) x y, xs[j]? = some x → ys[j]? = some y → PEq β x y ∨ PLt β x y)
    (hp : Term.VarsGe D (Term.apps (.Ctr a c) ys)) :
    (∀ e ∈ era, e.Closed 0 ∧ Deep βe e) ∧
    (∀ (j : Nat) x y e, xs[j]? = some x → ys[j]? = some y → (era.drop A.pn)[j]? = some e →
      (PEq β x y → Term.csize βe e ≤ Term.csize βe (Term.instL D ρ y)) ∧
      (PLt β x y → Term.csize βe e < Term.csize βe (Term.instL D ρ y))) := by
  subst hsrc
  have hfield : ∀ (j : Nat) x y e, xs[j]? = some x → ys[j]? = some y → era[A.pn + j]? = some e →
      (e.Closed 0 ∧ Deep βe e) ∧
      (PEq β x y → Term.csize βe e ≤ Term.csize βe (Term.instL D ρ y)) ∧
      (PLt β x y → Term.csize βe e < Term.csize βe (Term.instL D ρ y)) := by
    intro j x y e hx hy he
    have hsx : (ps ++ xs)[A.pn + j]? = some x := by
      rw [List.getElem?_append_right (by omega)]; simpa [hlp] using hx
    have hd := hdom _ x e hsx he y (hp.field (List.mem_of_getElem? hy))
    rcases hrel j x y hx hy with hr | hr
    · exact ⟨⟨(hd.1 hr).1, (hd.1 hr).2.1⟩, fun _ => (hd.1 hr).2.2, fun h => (hd.2 h).2.2⟩
    · exact ⟨⟨(hd.2 hr).1, (hd.2 hr).2.1⟩, fun h => (hd.1 h).2.2, fun _ => (hd.2 hr).2.2⟩
  refine ⟨fun e he => ?_, fun j x y e hx hy he => ?_⟩
  · obtain ⟨i, hi⟩ := List.mem_iff_getElem?.mp he
    by_cases hlt : i < A.pn
    · rw [hpar i e hlt hi]; exact ⟨trivial, .qnt⟩
    · have hi' : i = A.pn + (i - A.pn) := by omega
      rw [hi'] at hi
      have hjl : i - A.pn < xs.length := by
        have := (List.getElem?_eq_some_iff.mp hi).1
        simp [List.length_append] at hlen; omega
      exact (hfield (i - A.pn) _ _ e (List.getElem?_eq_getElem hjl)
        (List.getElem?_eq_getElem (by omega)) hi).1
  · rw [List.getElem?_drop] at he
    exact (hfield j x y e hx hy he).2

theorem DomP.ctr_peq (hE : Book.Era β 0 β βe) (hk : Book.adt β a = some A)
    (hC : AdtD.ctr A c = some C) {src era : List Term} (hlen : era.length = src.length)
    (hpar : ∀ (i : Nat) e, i < A.pn → era[i]? = some e → e = .Qnt)
    (hdom : ∀ (i : Nat) x e, src[i]? = some x → era[i]? = some e → DomP β βe ρ D x e)
    (h : PEq β (Term.apps (.Ctr a c) src) p) (hp : Term.VarsGe D p) :
    (Term.apps (.Ctr a c) era).Closed 0 ∧ Deep βe (Term.apps (.Ctr a c) era) ∧
      Term.csize βe (Term.apps (.Ctr a c) era) ≤ Term.csize βe (Term.instL D ρ p) := by
  rcases h.shape with ⟨_, e1, _⟩ | ⟨a', c', A', C', ps, xs, ys, hk', hc', hlp, hlx, hly, e1, rfl,
      hxy⟩
  · exact Term.noConfusion (Term.apps_head_inv (ys := []) (by trivial) (by trivial) e1).1
  obtain ⟨e2, rfl⟩ := Term.apps_head_inv (by trivial) (by trivial) e1
  cases e2
  rw [hk] at hk'; cases hk'; rw [hC] at hc'; cases hc'
  obtain ⟨hcd, hfld⟩ := DomP.ctr_fields hlen hpar hdom rfl hlp hlx hly
    (fun j x y hx hy => .inl (hxy.get j hx hy)) hp
  refine ⟨Term.closed_apps era _ 0 trivial (fun e he => (hcd e he).1),
    .ctr (Deeps.of_mem fun e he => (hcd e he).2), ?_⟩
  rw [Term.csize_ctr (hE.adt hk) hC, Term.instL_apps, Term.instL_closed _ _ (t := .Ctr _ _) trivial,
    Term.csize_fields (hE.adt hk) hC (by simpa using hly), List.map_map]
  have hdl : era.length - C.fn = A.pn := by simp [List.length_append, hlp, hlx] at hlen; omega
  rw [hdl]
  have := sum_le_pointwise (Term.csize βe) (Term.csize βe ∘ Term.instL D ρ) (era.drop A.pn) ys
    (by simp [List.length_append, hlp, hlx] at hlen; simp [hly]; omega) (fun j e y he hy => by
      have hjx : j < xs.length := by rw [hlx, ← hly]; exact (List.getElem?_eq_some_iff.mp hy).1
      exact (hfld j _ y e (List.getElem?_eq_getElem hjx) hy he).1 (hxy.get j
          (List.getElem?_eq_getElem hjx) hy))
  omega

theorem DomP.ctr_plt (hE : Book.Era β 0 β βe) (hk : Book.adt β a = some A)
    (hC : AdtD.ctr A c = some C) {src era : List Term} (hlen : era.length = src.length)
    (hpar : ∀ (i : Nat) e, i < A.pn → era[i]? = some e → e = .Qnt)
    (hdom : ∀ (i : Nat) x e, src[i]? = some x → era[i]? = some e → DomP β βe ρ D x e) :
    ∀ {t p : Term}, PLt β t p → t = Term.apps (.Ctr a c) src → Term.VarsGe D p →
    (Term.apps (.Ctr a c) era).Closed 0 ∧ Deep βe (Term.apps (.Ctr a c) era) ∧
      Term.csize βe (Term.apps (.Ctr a c) era) < Term.csize βe (Term.instL D ρ p)
  | _, _, .subEq hk' hc' hly hy hpe, e, hp => by
    subst e
    obtain ⟨h1, h2, h3⟩ := DomP.ctr_peq hE hk hC hlen hpar hdom hpe (hp.field hy)
    exact ⟨h1, h2, Nat.lt_of_le_of_lt h3 (Term.csize_pat_field hE hk' hc' hly hy ρ D)⟩
  | _, _, .subLt hk' hc' hly hy hpl, e, hp => by
    obtain ⟨h1, h2, h3⟩ := DomP.ctr_plt hE hk hC hlen hpar hdom hpl e (hp.field hy)
    exact ⟨h1, h2, Nat.lt_trans h3 (Term.csize_pat_field hE hk' hc' hly hy ρ D)⟩
  | _, _, .ctr hk' hc' hlp hlx hxy, e, hp => by
    obtain ⟨e2, rfl⟩ := Term.apps_head_inv (by trivial) (by trivial) e
    cases e2
    rw [hk] at hk'; cases hk'; rw [hC] at hc'; cases hc'
    have hly := hxy.length
    obtain ⟨hcd, hfld⟩ := DomP.ctr_fields hlen hpar hdom rfl hlp hlx (by omega)
      (fun j x y hx hy => hxy.get j hx hy) hp
    refine ⟨Term.closed_apps era _ 0 trivial (fun e he => (hcd e he).1),
      .ctr (Deeps.of_mem fun e he => (hcd e he).2), ?_⟩
    rw [Term.csize_ctr (hE.adt hk) hC, Term.instL_apps, Term.instL_closed _ _ (t := .Ctr _ _)
        trivial,
      Term.csize_fields (hE.adt hk) hC (by simp; omega), List.map_map]
    have hdl : era.length - C.fn = A.pn := by simp [List.length_append, hlp, hlx] at hlen; omega
    rw [hdl]
    have := PLts.sum_lt (Term.csize βe) (Term.csize βe ∘ Term.instL D ρ) hxy (era.drop A.pn)
      (by simp [List.length_append, hlp, hlx] at hlen; simp; omega) (fun j x y e hx hy he => hfld j
          x y e hx hy he)
    omega

theorem DomP.ctr (hE : Book.Era β 0 β βe) (hk : Book.adt β a = some A) (hC : AdtD.ctr A c = some
    C)
    {src era : List Term} (hlen : era.length = src.length)
    (hpar : ∀ (i : Nat) e, i < A.pn → era[i]? = some e → e = .Qnt)
    (hdom : ∀ (i : Nat) x e, src[i]? = some x → era[i]? = some e → DomP β βe ρ D x e) :
    DomP β βe ρ D (Term.apps (.Ctr a c) src) (Term.apps (.Ctr a c) era) :=
  fun _ hp => ⟨fun h => DomP.ctr_peq hE hk hC hlen hpar hdom h hp,
    fun h => DomP.ctr_plt hE hk hC hlen hpar hdom h rfl hp⟩

-- pins of ⊤ for the rest of a spine
theorem Pins.of.rest : ∀ (n : Nat) (us : List Term), Pins.of β n us (List.replicate n Option.none)
    := by
  intro n
  induction n with
  | zero => intro us; exact .zero
  | succ n ih =>
    intro us
    cases us with
    | nil => exact .miss (ih [])
    | cons u us => exact .none (ih us)

-- the descent verdicts of a self-call turn into a strictly smaller
-- pinning of its instantiated erased arguments
theorem SpineLt.pins (ρ : List Term) (D : Nat) :
    ∀ (j : Nat) {cols xs : List Term}, SpineLt β qs j cols xs → ∀ (pins : Pins) (era : List Term),
    era.length = xs.length → pins.length = cols.length →
    (∀ (i : Nat) x e, xs[i]? = some x → era[i]? = some e → DomP β βe ρ D x e) →
    (∀ (i : Nat) e, era[i]? = some e → qs.getD (j + i) .Lone = .None → e = .Qnt) →
    (∀ (i : Nat) c, cols[i]? = some c → Term.VarsGe D c) →
    (∀ (i : Nat) c n, cols[i]? = some c → pins[i]? = some (some n) →
      Term.csize βe (Term.instL D ρ c) = n) →
    ∃ pins', Pins.of βe cols.length era pins' ∧ Pins.lt pins' pins := by
  intro j cols xs h
  induction h with
  | @here j t c cs ts hq hlt =>
    intro pins era hle hlp hdom hqn hvg hpin
    cases era with
    | nil => simp at hle
    | cons e era =>
      cases pins with
      | nil => simp at hlp
      | cons p0 pins =>
        obtain ⟨hc, hd, hlt'⟩ := (hdom 0 t e (by simp) (by simp) c (hvg 0 c (by simp))).2 hlt
        refine ⟨some (Term.csize βe e) :: List.replicate cs.length Option.none,
          .some hc hd (Pins.of.rest cs.length era), .here ?_ (by simp at hlp ⊢; omega)⟩
        cases p0 with
        | none => trivial
        | some n => rw [hpin 0 c n (by simp) (by simp)] at hlt'; exact hlt'
  | @skip j cs ts c t hq _ ih =>
    intro pins era hle hlp hdom hqn hvg hpin
    cases era with
    | nil => simp at hle
    | cons e era =>
      cases pins with
      | nil => simp at hlp
      | cons p0 pins =>
        have he : e = .Qnt := hqn 0 e (by simp) (by simpa using hq)
        subst he
        have hz : Term.csize βe .Qnt = 0 := Term.csize_tok
        cases p0 with
        | none =>
          exact ⟨some (Term.csize βe .Qnt) :: List.replicate cs.length Option.none,
            .some (u := .Qnt) (by trivial) .qnt (Pins.of.rest cs.length era), .here trivial
                (by simp at hlp ⊢; omega)⟩
        | some n =>
          cases n with
          | zero =>
            obtain ⟨pins', h1, h2⟩ := ih pins era (by simpa using hle) (by simp at hlp ⊢; omega)
              (fun i x e hx he => hdom (i + 1) x e (by simpa using hx) (by simpa using he))
              (fun i e he hq' => hqn (i + 1) e (by simpa using he)
                  (by rw [show j + (i + 1) = j + 1 + i by omega]; exact hq'))
              (fun i c hc => hvg (i + 1) c (by simpa using hc))
              (fun i c n hc hp => hpin (i + 1) c n (by simpa using hc) (by simpa using hp))
            exact ⟨some (Term.csize βe .Qnt) :: pins', .some (u := .Qnt) (by trivial) .qnt h1,
                by rw [hz]; exact .there h2⟩
          | succ n =>
            exact ⟨some (Term.csize βe .Qnt) :: List.replicate cs.length Option.none,
              .some (u := .Qnt) (by trivial) .qnt (Pins.of.rest cs.length era),
              .here (by rw [hz]; show 0 < n + 1; omega) (by simp at hlp ⊢; omega)⟩
  | @there j t c cs ts hq hpe _ ih =>
    intro pins era hle hlp hdom hqn hvg hpin
    cases era with
    | nil => simp at hle
    | cons e era =>
      cases pins with
      | nil => simp at hlp
      | cons p0 pins =>
        obtain ⟨hc, hd, hle'⟩ := (hdom 0 t e (by simp) (by simp) c (hvg 0 c (by simp))).1 hpe
        cases p0 with
        | none =>
          exact ⟨some (Term.csize βe e) :: List.replicate cs.length Option.none,
            .some hc hd (Pins.of.rest cs.length era), .here trivial (by simp at hlp ⊢; omega)⟩
        | some n =>
          rw [hpin 0 c n (by simp) (by simp)] at hle'
          rcases Nat.lt_or_eq_of_le hle' with hlt | heq
          · exact ⟨some (Term.csize βe e) :: List.replicate cs.length Option.none,
              .some hc hd (Pins.of.rest cs.length era), .here hlt (by simp at hlp ⊢; omega)⟩
          · obtain ⟨pins', h1, h2⟩ := ih pins era (by simpa using hle) (by simp at hlp ⊢; omega)
              (fun i x e hx he => hdom (i + 1) x e (by simpa using hx) (by simpa using he))
              (fun i e he hq' => hqn (i + 1) e (by simpa using he)
                  (by rw [show j + (i + 1) = j + 1 + i by omega]; exact hq'))
              (fun i c hc => hvg (i + 1) c (by simpa using hc))
              (fun i c n hc hp => hpin (i + 1) c n (by simpa using hc) (by simpa using hp))
            exact ⟨some n :: pins', by rw [← heq]; exact .some hc hd h1, .there h2⟩

theorem LHS.lam_of_zero {L : LHS} (hn : L.n = 0) : L.lam = L.shift := by simp [LHS.lam, hn]

theorem LHS.mat_of_zero {L : LHS} (hn : L.n = 0) (a c fn : Nat) : L.mat a c fn = L :=
    by simp [LHS.mat, hn]

-- ----------------------------------------------------------------------------
-- the tree walk: the equation's algebra (lams, shifts, the column patterns),
-- the instantiation of patterns by the pending values
-- ----------------------------------------------------------------------------

theorem Term.lams_add : ∀ (a b : Nat) (X : Term), Term.lams (a + b) X = Term.lams a (Term.lams b X)
    := by
  intro a
  induction a with
  | zero => intro b X; simp [Term.lams]
  | succ a ih =>
    intro b X
    rw [show a + 1 + b = (a + b) + 1 by omega]
    simp only [Term.lams]
    rw [ih]

theorem Term.shift_lams : ∀ (j d : Nat) (X : Term),
    Term.shift d (Term.lams j X) = Term.lams j (Term.shift (d + j) X) := by
  intro j
  induction j with
  | zero => intro d X; rfl
  | succ j ih =>
    intro d X
    simp only [Term.lams, Term.shift]
    rw [ih, show d + 1 + j = d + (j + 1) by omega]

def Term.shiftNAt : Nat → Nat → Term → Term
  | 0,     _, t => t
  | n + 1, d, t => Term.shift d (Term.shiftNAt n d t)

theorem Term.subst_var_shift : ∀ (t : Term) (d : Nat),
    Term.subst d (.Var d) (Term.shift (d + 1) t) = t := by
  intro t
  induction t <;> intro d
  case Var i =>
    simp only [Term.shift]
    split
    · show (if i = d then Term.Var d else if d < i then Term.Var (i - 1) else Term.Var i) =
        Term.Var i
      by_cases h1 : i = d
      · rw [if_pos h1, h1]
      · rw [if_neg h1, if_neg (by omega)]
    · show (if i + 1 = d then Term.Var d else if d < i + 1 then Term.Var (i + 1 - 1) else Term.Var
        (i + 1))
        = Term.Var i
      rw [if_neg (by omega), if_pos (by omega), Nat.add_sub_cancel]
  all_goals simp [Term.shift, Term.subst, *]

theorem Term.applyB_shift_lam (t : Term) : Term.applyB (Term.shift 0 (.Lam t)) (.Var 0) = t := by
  simp only [Term.shift, Term.applyB]; exact Term.subst_var_shift t 0

theorem Term.applyB_ref_spine (k : Nat) (cs : List Term) (P : Term) :
    Term.applyB (Term.apps (.Ref k) cs) P = Term.apps (.Ref k) (cs ++ [P]) := by
  rw [Term.apps_snoc]
  rcases apps_shape cs (.Ref k) _ rfl with ⟨rfl, _⟩ | ⟨cs0, cl, rfl, e⟩
  · rfl
  · rw [e]; rfl

-- the equation's walks on a spine of columns
theorem LHS.lam_pos {L : LHS} (hn : L.n ≠ 0) :
    L.lam = { L with t := Term.applyB (Term.shift 0 L.t) (.Var 0), n := L.n - 1 } := by
  simp [LHS.lam, hn]

theorem LHS.mat_pos {L : LHS} (hn : L.n ≠ 0) (a c fn : Nat) :
    L.mat a c fn = { L with t := Term.lhsExt L.t a c fn, n := L.n - 1 + fn } := by
  simp [LHS.mat, hn]

theorem Term.applyB_lams_succ (j : Nat) (X : Term) :
    Term.applyB (Term.shift 0 (Term.lams (j + 1) X)) (.Var 0) = Term.lams j X :=
  Term.applyB_shift_lam _

theorem Term.applyB_lams_zero (k : Nat) (cols : List Term) :
    Term.applyB (Term.shift 0 (Term.lams 0 (Term.apps (.Ref k) cols))) (.Var 0)
      = Term.lams 0 (Term.apps (.Ref k) (cols.map (Term.shift 0) ++ [.Var 0])) := by
  simp only [Term.lams]
  rw [Term.shift_apps]
  exact Term.applyB_ref_spine k _ _

theorem Term.lhsExt_lams_zero (k : Nat) (cols : List Term) (a c fn : Nat) :
    Term.lhsExt (Term.lams 0 (Term.apps (.Ref k) cols)) a c fn
      = Term.lams fn (Term.apps (.Ref k) (cols.map (Term.shiftN fn) ++ [Term.apps (.Ctr a c)
          (Term.rvars fn)])) := by
  simp only [Term.lams, Term.lhsExt]
  rw [Term.shiftN_apps, Term.shiftN_closed (w := .Ref k) trivial, Term.applyB_ref_spine]

-- column patterns: variables and constructors of patterns (fields only)
inductive Pat (β : Book) : Term → Prop
  | var : Pat β (.Var i)
  | ctr : Book.adt β a = some A → AdtD.ctr A c = some C → cs.length = C.fn →
          (∀ x ∈ cs, Pat β x) → Pat β (Term.apps (.Ctr a c) cs)

theorem Term.rvars_mem : ∀ (n : Nat), ∀ x ∈ Term.rvars n, ∃ i, x = Term.Var i := by
  intro n; induction n with
  | zero => intro x hx; simp [Term.rvars] at hx
  | succ n ih =>
    intro x hx
    simp only [Term.rvars, List.mem_cons] at hx
    exact hx.elim (fun e => ⟨n, e⟩) (ih x)

theorem Pat.rvars (hk : Book.adt β a = some A) (hc : AdtD.ctr A c = some C) :
    Pat β (Term.apps (.Ctr a c) (Term.rvars C.fn)) :=
  .ctr hk hc (Term.rvars_length _) (fun x hx =>
      by obtain ⟨i, rfl⟩ := Term.rvars_mem _ x hx; exact .var)

theorem Pat.shift (h : Pat β p) : ∀ (d : Nat), Pat β (Term.shift d p) := by
  induction h with
  | var => intro d; simp only [Term.shift]; split <;> exact .var
  | ctr hk hc hl _ ih =>
    intro d
    rw [Term.shift_apps]
    exact .ctr hk hc (by simpa using hl) (fun x hx => by
      obtain ⟨y, hy, rfl⟩ := List.mem_map.mp hx; exact ih y hy d)

theorem Pat.shiftN (h : Pat β p) : ∀ (n : Nat), Pat β (Term.shiftN n p) := by
  intro n; induction n with
  | zero => exact h
  | succ n ih => exact ih.shift 0

-- the instantiation of a shifted term by one more value
theorem Term.instL_cons_shift (v : Term) (ρ : List Term) (hc : ∀ w ∈ ρ, Term.Closed 0 w) (t : Term)
    :
    Term.instL 0 (v :: ρ) (Term.shift 0 t) = Term.instL 0 ρ t := by
  simp only [Term.instL, List.map_cons, Term.inst]
  have := Term.instL_shift 0 ρ hc t
  simp only [Term.instL] at this
  rw [this, Term.subst_shift]

theorem Term.instL_shiftN_pend : ∀ (pend ρ : List Term), (∀ w ∈ pend ++ ρ, Term.Closed 0 w) → ∀ (t
    : Term),
    Term.instL 0 (pend ++ ρ) (Term.shiftN pend.length t) = Term.instL 0 ρ t := by
  intro pend
  induction pend with
  | nil => intro ρ _ t; rfl
  | cons v pend ih =>
    intro ρ hc t
    simp only [List.length_cons, Term.shiftN, List.cons_append]
    rw [Term.instL_cons_shift v (pend ++ ρ) (fun w hw => hc w (by simp [hw]))]
    exact ih ρ (fun w hw => hc w (by simp [hw])) t

theorem Term.instL_rvars : ∀ (xs ρ : List Term), (∀ w ∈ xs ++ ρ, Term.Closed 0 w) →
    (Term.rvars xs.length).map (Term.instL 0 (xs.reverse ++ ρ)) = xs := by
  intro xs
  induction xs with
  | nil => intro ρ _; rfl
  | cons x xs ih =>
    intro ρ hc
    have hxs : ∀ w ∈ xs, Term.Closed 0 w := fun w hw => hc w (by simp [hw])
    have hx : Term.Closed 0 x := hc x (by simp)
    have hρ : ∀ w ∈ ρ, Term.Closed 0 w := fun w hw => hc w (by simp [hw])
    have hall : ∀ w ∈ xs.reverse ++ ([x] ++ ρ), Term.Closed 0 w := by
      intro w hw
      rw [List.mem_append, List.mem_reverse, List.mem_append, List.mem_singleton] at hw
      rcases hw with hw | rfl | hw
      · exact hxs w hw
      · exact hx
      · exact hρ w hw
    simp only [List.length_cons, Term.rvars, List.map_cons, List.reverse_cons, List.append_assoc]
    have h1 : Term.instL 0 (xs.reverse ++ ([x] ++ ρ)) (.Var (0 + xs.length)) = x :=
      Term.instL_var_some 0 _ hall
        (by rw [List.getElem?_append_right (by simp), List.length_reverse, Nat.sub_self]; rfl)
    rw [Nat.zero_add] at h1
    rw [h1, ih ([x] ++ ρ) (fun w hw => by
      rw [List.mem_append, List.mem_append, List.mem_singleton] at hw
      rcases hw with hw | rfl | hw
      · exact hxs w hw
      · exact hx
      · exact hρ w hw)]

theorem Term.instL_closed_of : ∀ (ρ : List Term) (d : Nat) {t : Term}, (∀ w ∈ ρ, Term.Closed 0 w) →
    t.Closed (d + ρ.length) → (Term.instL d ρ t).Closed d := by
  intro ρ
  induction ρ with
  | nil => intro d t _ ht; exact ht
  | cons v ρ ih =>
    intro d t hc ht
    simp only [Term.instL, List.map_cons, Term.inst]
    have := ih (d + 1) (fun w hw => hc w (by simp [hw])) (t := t)
      (by simp at ht; rw [show d + 1 + ρ.length = d + (ρ.length + 1) by omega]; exact ht)
    simp only [Term.instL] at this
    exact Term.Closed.subst (hc v (by simp)) _ d d (Nat.le_refl d) this

theorem Term.instL_cons (d : Nat) (v : Term) (ρ : List Term) (t : Term) :
    Term.instL d (v :: ρ) t = Term.subst d v (Term.instL (d + 1) ρ t) := rfl

theorem Term.instL_all (d : Nat) : ∀ (ρ : List Term), (∀ v ∈ ρ, Term.Closed 0 v) → ∀ (q : Quant) (A
    B : Term),
    Term.instL d ρ (.All q A B) = .All q (Term.instL d ρ A) (Term.instL (d + 1) ρ B) := by
  intro ρ
  induction ρ generalizing d with
  | nil => intro _ q A B; rfl
  | cons v ρ ih =>
    intro hc q A B
    rw [Term.instL_cons, Term.instL_cons, Term.instL_cons, ih (d + 1) (fun v hv => hc v
        (by simp [hv]))]
    simp only [Term.subst, Term.shift_closed v 0 0 (hc v (by simp)) (Nat.le_refl 0)]

theorem Le.instL (hβ : Book.Closed β) (h : Le β a b) : ∀ (d : Nat) (ρ : List Term),
    Le β (Term.instL d ρ a) (Term.instL d ρ b) := by
  intro d ρ
  induction ρ generalizing d with
  | nil => exact h
  | cons v ρ ih => rw [Term.instL_cons, Term.instL_cons]; exact (ih (d + 1)).subst hβ d v

-- a pinning's pins are the sizes of the pinned arguments
theorem Pins.of.get (h : Pins.of β n us pins) : ∀ (i : Nat) (m : Nat),
    pins[i]? = Option.some (Option.some m) → ∃ u, us[i]? = Option.some u ∧ m = Term.csize β u := by
  induction h with
  | zero => intro i m h; simp at h
  | none _ ih =>
    intro i m h
    cases i with
    | zero => simp at h
    | succ i => obtain ⟨u, hu, e⟩ := ih i m (by simpa using h); exact ⟨u, by simpa using hu, e⟩
  | some _ _ _ ih =>
    intro i m h
    cases i with
    | zero => simp at h; exact ⟨_, rfl, h.symm⟩
    | succ i => obtain ⟨u, hu, e⟩ := ih i m (by simpa using h); exact ⟨u, by simpa using hu, e⟩
  | miss _ ih =>
    intro i m h
    cases i with
    | zero => simp at h
    | succ i => obtain ⟨u, hu, e⟩ := ih i m (by simpa using h); simp at hu

-- TelV β T qs xs: T is a telescope, up to Le, of binders with the quantities
-- qs, the codomains instantiated by the values xs
def TelV (β : Book) : Term → List Quant → List Term → Prop
  | _, [], [] => True
  | T, q :: qs, x :: xs => ∃ A B, Le β T (.All q A B) ∧ TelV β (Term.subst 0 x B) qs xs
  | _, _, _ => False

theorem TelV.le (hβ : Book.Closed β) (h : Le β T T') : ∀ {qs xs}, TelV β T' qs xs → TelV β T qs xs
    := by
  intro qs xs
  cases qs <;> cases xs <;> simp only [TelV] <;> try exact id
  intro ⟨A, B, hle, ht⟩
  exact ⟨A, B, h.trans hβ hle, ht⟩

theorem TeleQs.telv (hβ : Book.Closed β) : ∀ {n : Nat} {qs : List Quant} {T : Term}, TeleQs β T n
    qs →
    ∀ (xs : List Term), xs.length = n → TelV β T qs xs := by
  intro n
  induction n with
  | zero =>
    intro qs T h xs hl
    cases h; cases xs with
    | nil => trivial
    | cons _ _ => simp at hl
  | succ n ih =>
    intro qs T h xs hl
    cases h with
    | cons hred ht =>
      cases xs with
      | nil => simp at hl
      | cons x xs =>
        exact ⟨_, _, Le.conv (Conv.of_red hred.strong), ih (TeleQs.subst hβ ht 0 x) xs
            (by simpa using hl)⟩

theorem MatGoal.instL (h : MatGoal q' n B s tel G) : ∀ (ρ : List Term), (∀ v ∈ ρ, Term.Closed 0 v) →
    ∀ (d : Nat), MatGoal q' n (Term.instL (d + 1) ρ B) (Term.instL d ρ s) (Term.instL d ρ tel)
        (Term.instL d ρ G) := by
  intro ρ
  induction ρ with
  | nil => intro _ d; exact h
  | cons v ρ ih =>
    intro hc d
    have := (ih (fun v hv => hc v (by simp [hv])) (d + 1)).subst d v
    rw [Term.shift_closed v 0 0 (hc v (by simp)) (Nat.le_refl 0)] at this
    rw [Term.instL_cons, Term.instL_cons, Term.instL_cons, Term.instL_cons]
    exact this

theorem Insts.instL (h : Insts T ps T') (hT : T.Closed 0) : ∀ (ρ : List Term) (d : Nat),
    Insts T (ps.map (Term.instL d ρ)) (Term.instL d ρ T') := by
  intro ρ
  induction ρ with
  | nil =>
    intro d
    have e : Term.instL d [] = id := funext fun p => rfl
    rw [e, List.map_id]
    exact h
  | cons v ρ ih =>
    intro d
    have := (ih (d + 1)).subst d v
    rw [Term.subst_closed T 0 d v hT (Nat.zero_le d), List.map_map] at this
    have e : Term.instL d (v :: ρ) = Term.subst d v ∘ Term.instL (d + 1) ρ := funext fun p => rfl
    rw [Term.instL_cons, e]
    exact this

-- the arm's telescope: the fields' quantities scaled by the scrutinee's,
-- then the motive's telescope at the rebuilt constructor
theorem MatGoal.telv : ∀ (n : Nat) {B s tel G : Term} {ps : List Term},
    MatGoal q' n B s tel G → FTele a r ps n tel →
    ∀ (xs : List Term), xs.length = n → ∀ {qs rest}, TelV β (Term.subst 0 (Term.apps s xs) B) qs
        rest →
    TelV β G ((Term.allQs n tel).map (fun qf => Quant.mul qf q') ++ qs) (xs ++ rest) := by
  intro n
  induction n with
  | zero =>
    intro B s tel G ps h _ xs hl qs rest ht
    cases h; cases xs with
    | nil => simpa [Term.apps, Term.allQs] using ht
    | cons _ _ => simp at hl
  | succ n ih =>
    intro B s tel G ps h hF xs hl qs rest ht
    cases h with
    | succ h' =>
      cases xs with
      | nil => simp at hl
      | cons x xs =>
        obtain ⟨qf', F', Bf', e, hB⟩ := hF
        cases e
        simp only [Term.allQs, List.map_cons, List.cons_append, TelV]
        refine ⟨_, _, Le.refl _, ?_⟩
        have h2 := h'.subst 0 x
        rw [Nat.zero_add, Term.subst_shift] at h2
        simp only [Term.subst, Term.subst_shift, if_pos] at h2
        have := ih h2 (FTele.subst hB 0 x) xs (by simpa using hl) (by simpa [Term.apps] using ht)
        rwa [FTele.allQs_subst n hB] at this

-- Args: appending walks
theorem Args.append : ∀ {as : List Term} {T0 Tm : Term} {πa : Uses} {ua : List Term},
    Args β Φ L q Γ T0 as Tm πa ua → ∀ {bs T1 πb ub}, Args β Φ L q Γ Tm bs T1 πb ub →
    Args β Φ L q Γ T0 (as ++ bs) T1 (Uses.add πa πb) (ua ++ ub) := by
  intro as T0 Tm πa ua h
  induction h with
  | nil => intro bs T1 πb ub h; simpa [Uses.zero_add] using h
  | cons hc hx _ ih =>
    intro bs T1 πb ub h
    simp only [List.cons_append, Uses.add_assoc]
    exact .cons hc hx (ih h)

theorem Args.snoc : ∀ {as : List Term} {T0 T1 : Term} {πs : Uses} {us : List Term},
    Args β Φ L q Γ T0 as T1 πs us → Φ.conv (Ctx.δ Γ 0 T1) (Ctx.δ Γ 0 (.All q' A B)) →
    Check β Φ L [] (Quant.dem q' q) Γ x A πx ux →
    Args β Φ L q Γ T0 (as ++ [x]) (Term.subst 0 x B) (Uses.add πs πx) (us ++ [ux]) := by
  intro as T0 T1 πs us h hle hx
  induction h with
  | nil =>
    simpa [Uses.zero_add, Uses.add_zero] using Args.cons hle hx (.nil (T := Term.subst 0 x B))
  | cons hc hx' _ ih =>
    simp only [List.cons_append, Uses.add_assoc]
    exact .cons hc hx' (ih hle)

-- ----------------------------------------------------------------------------
-- the walk's typing tools: the spine's arguments from its erasure, the
-- constructor shape of a deep column value, the fields' typed facts
-- ----------------------------------------------------------------------------

-- a closed live derivation whose erasure is a definition spine walks the
-- definition's type over some source arguments
theorem Check.ref_spine_args (hβ : Book.Closed β) (hk : Book.defn β k = some d) :
    ∀ {sp : List Term} {q : Quant} {Γ : Ctx} {t T : Term} {π : Uses} {u : Term},
    Check β (Pol.std β) L sp q Γ t T π u → Γ = [] → q = .Lone →
    ∀ (us : List Term), u = Term.apps (.Ref k) us →
    ∃ as T1 πs, Args β (Pol.std β) L .Lone [] d.ty as T1 πs us ∧ Le β T1 T := by
  intro sp q Γ t T π u h
  induction h
  case ref hd' _ _ =>
    intro hΓ hq us hu
    subst hΓ hq
    have e := congrArg Term.spine hu
    simp [Term.spine_apps_of, Term.spine] at e
    obtain ⟨rfl, rfl⟩ := e
    rw [hk] at hd'; cases hd'
    exact ⟨[], _, _, .nil, Le.refl _⟩
  case refA hA _ =>
    intro hΓ hq us hu
    subst hΓ hq
    have e := congrArg Term.spine hu
    simp [Term.spine_apps_of, Term.spine] at e
    obtain ⟨rfl, _⟩ := e
    exact (Book.defn_adt_clash hk hA).elim
  case app hf hx ihf _ =>
    intro hΓ hq us hu
    subst hΓ hq
    simp only [Term.era_lone] at hu
    obtain ⟨ys, rfl, rfl⟩ := Term.app_eq_apps (h := .Ref k) (by trivial) hu
    obtain ⟨as, T1, πs, hargs, hle⟩ := ihf _root_.rfl _root_.rfl ys _root_.rfl
    exact ⟨as ++ [_], _, _, Args.snoc hargs hle hx, Le.refl _⟩
  case appLam _ _ ih => intro hΓ hq us hu; exact ih hΓ hq us hu
  case cnv _ hle ih =>
    intro hΓ hq us hu
    obtain ⟨as, T1, πs, hargs, hle'⟩ := ih hΓ hq us hu
    subst hΓ
    exact ⟨as, T1, πs, hargs, hle'.trans hβ hle⟩
  all_goals
    intro hΓ hq us hu
    subst hq
    have e := congrArg Term.spine hu
    simp [Term.era_lone, Term.spine_apps_of, Term.spine] at e

-- a deep column value at a family type is a full constructor spine of that
-- family, the erasure of a value with the same erasure
theorem Deep.ctr_shape (hok : Book.Ok β) {sp : List Term}
    (h : Check β (Pol.std β) (LHS.void β) sp .Lone [] a A πa ua) (hd : Deep β ua)
    (hT : Le β A (Term.apps (.Adt a0 r) ps)) :
    ∃ v π' c A' C as vs, Red β .weak a v ∧ Term.Value β v ∧
      Check β (Pol.std β) (LHS.void β) sp .Lone [] v A π' ua ∧
      v = Term.apps (.Ctr a0 c) as ∧ ua = Term.apps (.Ctr a0 c) vs ∧
      Book.adt β a0 = some A' ∧ AdtD.ctr A' c = some C ∧ c ∉ r ∧
      as.length = A'.pn + C.fn ∧ vs.length = as.length ∧ Convs β (as.take A'.pn) ps := by
  have hβ := hok.closed
  obtain ⟨v, π', hred, hv, h'⟩ := h.deep_value hβ (by decide) hd
  obtain ⟨c, A', C, as, rfl, hA, hC, hr, hlen, hcs⟩ :=
    Check.canon_adt' hok (by decide) hv h' (Check.deep_not_bad hok hd) hT
  obtain ⟨vs, rfl, hlv⟩ := Check.ctr_spine_era hβ h' (by decide)
  exact ⟨_, π', c, A', C, as, vs, hred, hv, h', _root_.rfl, _root_.rfl, hA, hC, hr, hlen, hlv, hcs⟩

-- ----------------------------------------------------------------------------
-- small helpers for the walk
-- ----------------------------------------------------------------------------

theorem Term.rvars_closed : ∀ (n : Nat), ∀ x ∈ Term.rvars n, x.Closed n := by
  intro n
  induction n with
  | zero => intro x hx; simp [Term.rvars] at hx
  | succ n ih =>
    intro x hx
    simp only [Term.rvars, List.mem_cons] at hx
    rcases hx with rfl | hx
    · show n < n + 1; omega
    · exact Term.Closed.mono x n (n + 1) (ih x hx) (by omega)

theorem Insts.ftele : ∀ {pn : Nat} {ps0 : List Term} {Tw : Term} {ps : List Term} {T' : Term},
    WTele a r ps0 pn fn Tw → Insts Tw ps T' → ps.length = pn → FTele a r (ps0 ++ ps) fn T' := by
  intro pn
  induction pn with
  | zero => intro ps0 Tw ps T' hw hI hl; cases hI with
    | nil => rw [List.append_nil]; exact hw
    | cons _ => simp at hl
  | succ pn ih =>
    intro ps0 Tw ps T' hw hI hl
    cases hI with
    | nil => simp at hl
    | @cons x _ _ _ _ _ hI' =>
      obtain ⟨q, K, B, e, _, hw'⟩ := WTele.param (x := x) hw
      cases e
      have := ih hw' hI' (by simpa using hl)
      simpa [List.append_assoc] using this

theorem Term.allQs_conv : ∀ (n : Nat) {T T' : Term} {ps ps' : List Term},
    Conv β T T' → FTele a r ps n T → FTele a' r' ps' n T' → Term.allQs n T = Term.allQs n T' := by
  intro n
  induction n with
  | zero => intro _ _ _ _ _ _ _; rfl
  | succ n ih =>
    intro T T' ps ps' hc h1 h2
    obtain ⟨q, F, B, rfl, hB⟩ := h1
    obtain ⟨q', F', B', rfl, hB'⟩ := h2
    obtain ⟨rfl, _, hcB⟩ := hc.all_inv
    simp only [Term.allQs]
    rw [ih hcB hB hB']

-- ----------------------------------------------------------------------------
-- N4b (nested Mats): the LHS algebra for a Mat on a pending field, and the
-- pattern columns under the field's substitution
-- ----------------------------------------------------------------------------

theorem Term.shiftNAt_lams : ∀ (n j d : Nat) (X : Term),
    Term.shiftNAt n d (Term.lams j X) = Term.lams j (Term.shiftNAt n (d + j) X) := by
  intro n
  induction n with
  | zero => intro j d X; rfl
  | succ n ih => intro j d X; simp only [Term.shiftNAt]; rw [ih, Term.shift_lams]

theorem Term.shiftN_lam : ∀ (n : Nat) (Y : Term), Term.shiftN n (.Lam Y) = .Lam (Term.shiftNAt n 1
    Y) := by
  intro n
  induction n with
  | zero => intro Y; rfl
  | succ n ih => intro Y; simp only [Term.shiftN, Term.shiftNAt]; rw [ih]; rfl

theorem Term.shiftNAt_apps : ∀ (n d : Nat) (f : Term) (xs : List Term),
    Term.shiftNAt n d (Term.apps f xs) = Term.apps (Term.shiftNAt n d f) (xs.map (Term.shiftNAt n
        d)) := by
  intro n
  induction n with
  | zero => intro d f xs; simp [Term.shiftNAt]
  | succ n ih =>
    intro d f xs
    simp only [Term.shiftNAt]
    rw [ih, Term.shift_apps, List.map_map]
    rfl

theorem Term.shiftNAt_closed : ∀ (n d : Nat) {t : Term}, t.Closed d → Term.shiftNAt n d t = t := by
  intro n
  induction n with
  | zero => intro d t _; rfl
  | succ n ih =>
    intro d t h
    simp only [Term.shiftNAt]
    rw [ih d h]
    exact Term.shift_closed t d d h (Nat.le_refl d)

theorem Term.shiftNAt_var (n : Nat) : ∀ (d i : Nat),
    Term.shiftNAt n d (.Var i) = if i < d then .Var i else .Var (i + n) := by
  induction n with
  | zero => intro d i; simp [Term.shiftNAt]
  | succ n ih =>
    intro d i; simp only [Term.shiftNAt]; rw [ih]
    split
    · simp only [Term.shift]; rw [if_pos ‹_›]
    · simp only [Term.shift]; rw [if_neg (by omega)]; rfl

-- lhsExt on a pending field: the outermost pending binder becomes the pattern
theorem Term.lhsExt_lams_succ (k : Nat) (cols : List Term) (a c fn j : Nat) :
    Term.lhsExt (Term.lams (j + 1) (Term.apps (.Ref k) cols)) a c fn
      = Term.lams (fn + j) (Term.apps (.Ref k) (cols.map (fun x =>
          Term.subst j (Term.shiftN j (Term.apps (.Ctr a c) (Term.rvars fn))) (Term.shiftNAt fn (1
              + j) x)))) := by
  simp only [Term.lhsExt, Term.lams]
  rw [Term.shiftN_lam, Term.shiftNAt_lams]
  simp only [Term.applyB]
  rw [Term.subst_lams, ← Term.lams_add, Nat.zero_add, Term.shiftNAt_apps, Term.subst_apps,
      List.map_map]
  rw [Term.shiftNAt_closed fn (1 + j) (t := .Ref k) trivial]
  rfl

theorem Pat.subst (h : Pat β p) (hP : Pat β P) : ∀ (d : Nat), Pat β (Term.subst d P p) := by
  induction h with
  | var =>
    intro d; simp only [Term.subst]
    split
    · exact hP
    · split <;> exact .var
  | ctr hk hc hl _ ih =>
    intro d
    rw [Term.subst_apps]
    simp only [Term.subst]
    refine .ctr hk hc (by simp [hl]) ?_
    intro x hx; rw [List.mem_map] at hx; obtain ⟨y, hy, rfl⟩ := hx; exact ih y hy d

theorem Pat.shiftNAt (h : Pat β p) : ∀ (n d : Nat), Pat β (Term.shiftNAt n d p) := by
  intro n; induction n with
  | zero => intro d; exact h
  | succ n ih => intro d; exact (ih d).shift d

theorem Term.instL0_var_some (ρ : List Term) (hc : ∀ v ∈ ρ, Term.Closed 0 v) (h : ρ[i]? = some v) :
    Term.instL 0 ρ (.Var i) = v := by
  have := Term.instL_var_some 0 ρ hc h; rwa [Nat.zero_add] at this

-- the instantiation of a pattern after the substitution of a pending field
-- by a constructor pattern over the new fields: the same as instantiating
-- the pending field by the instance of that pattern
theorem Pat.instL_subst (h : Pat β p) (A B E : List Term) (P : Term)
    (hc : ∀ w ∈ A ++ B ++ E, Term.Closed 0 w) (hQ : (Term.instL 0 (B ++ E) P).Closed 0) :
    p.Closed (A.length + 1 + E.length) →
    Term.instL 0 (A ++ B ++ E) (Term.subst A.length (Term.shiftN A.length P) (Term.shiftNAt
        B.length (A.length + 1) p))
      = Term.instL 0 (A ++ [Term.instL 0 (B ++ E) P] ++ E) p := by
  have hc' : ∀ w ∈ A ++ [Term.instL 0 (B ++ E) P] ++ E, Term.Closed 0 w := by
    intro w hw; simp only [List.mem_append, List.mem_singleton] at hw
    rcases hw with (hw | rfl) | hw
    · exact hc w (by simp [hw])
    · exact hQ
    · exact hc w (by simp [hw])
  induction h with
  | @var i =>
    intro hp
    simp only [Term.Closed] at hp
    rw [Term.shiftNAt_var]
    rcases Nat.lt_trichotomy i A.length with hi | rfl | hi
    · rw [if_pos (by omega)]
      simp only [Term.subst]; rw [if_neg (by omega), if_neg (by omega)]
      obtain ⟨v, hv⟩ : ∃ v, A[i]? = some v := ⟨_, List.getElem?_eq_getElem hi⟩
      rw [Term.instL0_var_some _ hc
          (by rw [List.getElem?_append_left (by simp; omega), List.getElem?_append_left hi]; exact
                hv),
        Term.instL0_var_some _ hc'
            (by rw [List.getElem?_append_left (by simp; omega), List.getElem?_append_left hi];
                  exact hv)]
    · rw [if_pos (by omega)]
      simp only [Term.subst]; rw [if_pos trivial]
      rw [List.append_assoc, Term.instL_shiftN_pend A (B ++ E)
          (by simpa [List.append_assoc] using hc)]
      rw [Term.instL0_var_some _ hc'
          (by rw [List.append_assoc, List.getElem?_append_right (Nat.le_refl _), Nat.sub_self];
                rfl)]
    · rw [if_neg (by omega)]
      simp only [Term.subst]; rw [if_neg (by omega), if_pos (by omega)]
      obtain ⟨m, rfl⟩ : ∃ m, i = A.length + 1 + m := ⟨i - A.length - 1, by omega⟩
      obtain ⟨v, hv⟩ : ∃ v, E[m]? = some v := ⟨_, List.getElem?_eq_getElem (by omega)⟩
      rw [Term.instL0_var_some _ hc (by
        rw [List.getElem?_append_right (by simp; omega), List.length_append]
        rw [show A.length + 1 + m + B.length - 1 - (A.length + B.length) = m by omega]; exact hv)]
      rw [Term.instL0_var_some _ hc' (by
        rw [List.getElem?_append_right (by simp), List.length_append, List.length_singleton]
        rw [show A.length + 1 + m - (A.length + 1) = m by omega]; exact hv)]
  | ctr hk hc hl _ ih =>
    intro hp
    rw [Term.shiftNAt_apps, Term.subst_apps, Term.instL_apps, Term.instL_apps, List.map_map,
        List.map_map]
    rw [Term.shiftNAt_closed _ _ (t := .Ctr _ _) trivial]
    simp only [Term.subst, Term.instL_closed _ _ (t := .Ctr _ _) trivial]
    congr 1
    apply List.map_congr_left
    intro x hx
    exact ih x hx ((Term.closed_apps_inv _ _ _ hp).2 x hx)

-- the size of a pattern instance depends only on the sizes of its
-- variables' values
theorem Pat.csize_congr (h : Pat βe p) : ∀ (ρ1 ρ2 : List Term), (∀ w ∈ ρ1, Term.Closed 0 w) →
    (∀ w ∈ ρ2, Term.Closed 0 w) → ρ1.length = ρ2.length →
    (∀ (i : Nat) v1 v2, ρ1[i]? = some v1 → ρ2[i]? = some v2 → Term.csize βe v1 = Term.csize βe v2) →
    p.Closed ρ1.length → Term.csize βe (Term.instL 0 ρ1 p) = Term.csize βe (Term.instL 0 ρ2 p) := by
  induction h with
  | @var i =>
    intro ρ1 ρ2 hc1 hc2 hl hcs hp
    simp only [Term.Closed] at hp
    obtain ⟨v1, hv1⟩ : ∃ v1, ρ1[i]? = some v1 := ⟨_, List.getElem?_eq_getElem hp⟩
    obtain ⟨v2, hv2⟩ : ∃ v2, ρ2[i]? = some v2 := ⟨_, List.getElem?_eq_getElem (hl ▸ hp)⟩
    rw [Term.instL0_var_some ρ1 hc1 hv1, Term.instL0_var_some ρ2 hc2 hv2]
    exact hcs i v1 v2 hv1 hv2
  | ctr hk hc hl _ ih =>
    intro ρ1 ρ2 hc1 hc2 hlen hcs hp
    rw [Term.instL_apps, Term.instL_closed _ _ (t := .Ctr _ _) trivial, Term.instL_apps,
        Term.instL_closed _ _ (t := .Ctr _ _) trivial,
      Term.csize_fields hk hc (by simp [hl]), Term.csize_fields hk hc (by simp [hl])]
    congr 1
    rw [List.map_map, List.map_map]
    apply congrArg List.sum
    apply List.map_congr_left
    intro x hx
    exact ih x hx ρ1 ρ2 hc1 hc2 hlen hcs ((Term.closed_apps_inv _ _ _ hp).2 x hx)

-- the fields of a live constructor spine, with each field's binder quantity
theorem Check.ctr_fields_qs (hok : Book.Ok β) (hP : DataPol β Φ)
    (hK : Book.OkK β Φ) {sp : List Term}
    (h : Check β (Pol.std β) (LHS.void β) sp .Lone [] (Term.apps (.Ctr a0 c) as) A π
      (Term.apps (.Ctr a0 c) vs))
    (hA : Book.adt β a0 = some A') (hC : AdtD.ctr A' c = some C) (hlen : as.length = A'.pn + C.fn)
    (hd : Deep β (Term.apps (.Ctr a0 c) vs)) :
    ∃ TS, Insts C.ty (as.take A'.pn) TS ∧ FTele a0 [] (as.take A'.pn) C.fn TS ∧
      (∃ πf, Args β (Pol.std β) (LHS.void β) .Lone [] TS (as.drop A'.pn)
        (Term.apps (.Adt a0 []) (as.take A'.pn)) πf (vs.drop A'.pn)) ∧
      (vs.take A'.pn).length = A'.pn ∧
      ∀ (j : Nat) x u, (as.drop A'.pn)[j]? = some x → (vs.drop A'.pn)[j]? = some u →
        ∃ qf, (Term.allQs C.fn TS)[j]? = some qf ∧
          (qf = .Many → (∀ β', CG β' u [])) ∧ (qf = .None → u = .Qnt) := by
  have hβ := hok.closed
  have hΦ := Pol.std_pre hβ
  obtain ⟨T0, π0, u0, T1, πs, us, hh0, hargs, _, hu, hlus⟩ :=
    h.spine_era hβ (fun _ e => Term.noConfusion e)
  obtain ⟨A2, C2, r0, hA2, hC2, hr0, hle0, _, rfl⟩ := hh0.ctr_inv hΦ
  rw [hA] at hA2; cases hA2; rw [hC] at hC2; cases hC2
  simp only [Term.era_lone] at hu
  obtain ⟨_, rfl⟩ := Term.apps_head_inv (by trivial) (by trivial) hu
  obtain ⟨G, hS, hD⟩ := hK _ _ _ _ hA hC
  have hshape : WTele a0 [] [] A'.pn C.fn C.ty := hok.shape hA hC
  rw [← List.take_append_drop A'.pn as] at hargs
  obtain ⟨Tm, πp, up, πx, ux, hargsP, hargsF, _, rfl⟩ := hargs.split
  have hlp : up.length = A'.pn := by rw [hargsP.length]; simp; omega
  obtain ⟨TS, hI, hFT, hle', hD', hup⟩ :=
    CtrOkD.params hβ hP.weak hP.std hP.efq hP.efqS hshape hD hargsP hle0 (by simp; omega)
  have hFT' : FTele a0 [] (as.take A'.pn) C.fn TS := by simpa using hFT
  obtain ⟨hargsTS, _⟩ := Args.ftele hβ (r' := r0) hFT' hargsF hle' (by simp; omega)
  have hfields := CtrOkD.fields_qs hβ hP.weak hP.std hP.efq hP.efqS hFT' hD' hargsF hle'
      (by simp; omega)
  have hdrop : (up ++ ux).drop A'.pn = ux := by rw [← hlp, List.drop_left]
  have htake : (up ++ ux).take A'.pn = up := by rw [← hlp, List.take_left]
  rw [hdrop]
  refine ⟨TS, hI, hFT', ⟨_, hargsTS⟩, by rw [htake, hlp], fun j x u hx hu => ?_⟩
  · obtain ⟨qf, F, πx', hq, hx', πF, hKF⟩ := hfields j x u hx hu
    refine ⟨qf, hq, fun hqf => ?_, fun hqf => ?_⟩
    · subst hqf
      simp only [reduceCtorEq, if_false] at hKF
      have hdu : Deep β u := (Deep.args hd (by trivial)).mem u (by
        rw [List.mem_append]; exact .inr (List.mem_of_getElem? hu))
      exact (Check.data_deep_aux hok hP hK _ (Nat.le_refl _) hx' hKF hdu).1
    · subst hqf; exact hx'.none_era _root_.rfl

theorem List.drop_succ_eq' (l : List Term) (a : Nat) : l.drop (a + 1) = (l.drop a).drop 1 :=
  List.drop_drop.symm

-- ----------------------------------------------------------------------------
-- the leaf environment (with lets): an entry per binder of the context —
-- the binder's source instance and erased instance (closed once every
-- binder outside it is substituted), the charges it lends, and whether the
-- erased instance is substituted for the binder (a kept binder — a leaf
-- lambda's, or a let priced structurally — stays a variable)
-- ----------------------------------------------------------------------------

structure Ent : Type where
  src : Term
  era : Term
  chg : List Charge
  sub : Bool

def Ent.ρ (e : Ent) : Option Term := if e.sub then some e.era else none

def EnvO.ρ (env : List Ent) : List (Option Term) := env.map Ent.ρ

def EnvO.budget : List Ent → Uses → List Charge
  | [], _ => []
  | e :: env, π => (if e.sub ∧ π 0 ≠ .None then e.chg else []) ++ EnvO.budget env (Uses.tail π)

def EnvO.Aff (env : List Ent) (π : Uses) : Prop :=
  ∀ (j : Nat) e, env[j]? = some e → e.sub = true → e.chg ≠ [] → π j ≠ .Many

theorem EnvO.ρ_cons (e : Ent) (env : List Ent) : EnvO.ρ (e :: env) = e.ρ :: EnvO.ρ env := rfl

theorem Uses.tail_add (πa πb : Uses) : Uses.tail (Uses.add πa πb) = Uses.add (Uses.tail πa)
    (Uses.tail πb) := rfl

theorem EnvO.budget_le : ∀ (env : List Ent) (π π' : Uses), (∀ i, π i ≠ .None → π' i ≠ .None) →
    Sub (EnvO.budget env π) (EnvO.budget env π') := by
  intro env
  induction env with
  | nil => intro _ _ _; exact Sub.refl _
  | cons e env ih =>
    intro π π' h
    simp only [EnvO.budget]
    refine Sub.append ?_ (ih _ _ (fun i hi => h (i + 1) hi))
    by_cases h1 : e.sub ∧ π 0 ≠ .None
    · rw [if_pos h1, if_pos ⟨h1.1, h 0 h1.2⟩]; exact Sub.refl _
    · rw [if_neg h1]; exact Sub.nil _

theorem EnvO.Aff.tail (h : EnvO.Aff (e :: env) π) : EnvO.Aff env (Uses.tail π) :=
  fun j e' he hs hne => h (j + 1) e' (by simpa using he) hs hne

theorem EnvO.Aff.cons (h0 : e.sub = true → e.chg ≠ [] → π 0 ≠ .Many) (h : EnvO.Aff env (Uses.tail
    π)) :
    EnvO.Aff (e :: env) π := by
  intro j e' he hs hne
  cases j with
  | zero => simp at he; subst he; exact h0 hs hne
  | succ j => exact h j e' (by simpa using he) hs hne

theorem EnvO.Aff.add_l (h : EnvO.Aff env (Uses.add πa πb)) : EnvO.Aff env πa :=
  fun j e he hs hne hm => h j e he hs hne (Quant.add_many_l hm)

theorem EnvO.Aff.add_r (h : EnvO.Aff env (Uses.add πa πb)) : EnvO.Aff env πb :=
  fun j e he hs hne hm => h j e he hs hne (Quant.add_many_r hm)

theorem EnvO.Aff.join_l (h : EnvO.Aff env (Uses.join πa πb)) : EnvO.Aff env πa :=
  fun j e he hs hne hm => h j e he hs hne (Quant.join_many_l hm)

theorem EnvO.Aff.join_r (h : EnvO.Aff env (Uses.join πa πb)) : EnvO.Aff env πb :=
  fun j e he hs hne hm => h j e he hs hne (Quant.join_many_r hm)

theorem EnvO.budget_add : ∀ (env : List Ent) (πa πb : Uses), EnvO.Aff env (Uses.add πa πb) →
    Sub (EnvO.budget env πa ++ EnvO.budget env πb) (EnvO.budget env (Uses.add πa πb)) := by
  intro env
  induction env with
  | nil => intro _ _ _; exact Sub.refl _
  | cons e env ih =>
    intro πa πb h
    have ih' := ih (Uses.tail πa) (Uses.tail πb) (by rw [← Uses.tail_add]; exact h.tail)
    intro x
    have := ih' x
    simp only [EnvO.budget, Uses.tail_add, List.count_append] at this ⊢
    have hadd : Uses.add πa πb 0 = Quant.add (πa 0) (πb 0) := rfl
    by_cases hs : e.sub = true
    · by_cases ha : πa 0 = .None <;> by_cases hb : πb 0 = .None
      · rw [if_neg (fun h => h.2 ha), if_neg (fun h => h.2 hb), if_neg (fun h => h.2
          (by rw [hadd, ha, hb]; rfl))]
        simp only [List.count_nil]; omega
      · rw [if_neg (fun h => h.2 ha), if_pos ⟨hs, hb⟩, if_pos ⟨hs,
          by rw [hadd]; exact Quant.add_ne_none' hb⟩]
        simp only [List.count_nil]; omega
      · rw [if_pos ⟨hs, ha⟩, if_neg (fun h => h.2 hb), if_pos ⟨hs,
          by rw [hadd]; exact Quant.add_ne_none ha⟩]
        simp only [List.count_nil]; omega
      · by_cases he : e.chg = []
        · rw [he]; simp only [ite_self, List.count_nil]; omega
        · exact absurd (by rw [hadd]; exact Quant.add_many ha hb) (h 0 e (by simp) hs he)
    · rw [if_neg (fun h => hs h.1), if_neg (fun h => hs h.1), if_neg (fun h => hs h.1)]
      simp only [List.count_nil]; omega

theorem EnvO.budget_one (hq : q ≠ .None) : ∀ (env : List Ent) (j : Nat) (e : Ent),
    env[j]? = some e → e.sub = true → Sub e.chg (EnvO.budget env (Uses.one j q)) := by
  intro env
  induction env with
  | nil => intro j e h; simp at h
  | cons e0 env ih =>
    intro j e h hs
    cases j with
    | zero =>
      simp at h; subst h
      simp only [EnvO.budget]
      rw [if_pos ⟨hs, by simp [Uses.one, hq]⟩]
      exact Sub.append_right _ _
    | succ j =>
      simp only [EnvO.budget]
      rw [if_neg (fun h => h.2 (by simp [Uses.one]))]
      have := ih j e (by simpa using h) hs
      have e1 : Uses.tail (Uses.one (j + 1) q) = Uses.one j q := by
        funext i; simp only [Uses.tail, Uses.one]; by_cases hi : i = j
        · subst hi; simp
        · rw [if_neg (by omega), if_neg hi]
      rw [e1]; simpa using this

-- PricedO k pins env π M: M is a pricing below the unfolded charge, up to
-- charges lent by the environment to the uses π
def PricedO (k : Nat) (pins : Pins) (env : List Ent) (π : Uses) (M : List Charge) : Prop :=
  ∃ Y R, M.Perm (Y ++ R) ∧ (∀ y ∈ Y, Charge.lt y (k, pins)) ∧ Sub R (EnvO.budget env π)

theorem PricedO.nil : PricedO k pins env π [] := ⟨[], [], .refl _, by simp, Sub.nil _⟩

theorem PricedO.append (h1 : PricedO k pins env π1 M1) (h2 : PricedO k pins env π2 M2)
    (haff : EnvO.Aff env (Uses.add π1 π2)) : PricedO k pins env (Uses.add π1 π2) (M1 ++ M2) := by
  obtain ⟨Y1, R1, hp1, hY1, hR1⟩ := h1
  obtain ⟨Y2, R2, hp2, hY2, hR2⟩ := h2
  refine ⟨Y1 ++ Y2, R1 ++ R2, ?_, ?_, (Sub.append hR1 hR2).trans (EnvO.budget_add env π1 π2 haff)⟩
  · rw [List.perm_iff_count]; intro x
    have := List.perm_iff_count.mp hp1 x; have := List.perm_iff_count.mp hp2 x
    simp only [List.count_append] at *; omega
  · intro y hy; rw [List.mem_append] at hy; exact hy.elim (hY1 y) (hY2 y)

theorem PricedO.cons (hc : Charge.lt c (k, pins)) (h : PricedO k pins env π M) :
    PricedO k pins env π (c :: M) :=
  let ⟨Y, R, hp, hY, hR⟩ := h
  ⟨c :: Y, R, by simpa using hp.cons c, fun y hy => by
    rw [List.mem_cons] at hy; exact hy.elim (fun e => e ▸ hc) (hY y), hR⟩

-- under a kept binder the budget is the tail's
theorem PricedO.under (hs : e.sub = false) (h : PricedO k pins (e :: env) π' M) :
    PricedO k pins env (Uses.tail π') M :=
  let ⟨Y, R, hp, hY, hR⟩ := h
  ⟨Y, R, hp, hY, by simp only [EnvO.budget, hs] at hR; simpa using hR⟩

-- under a substituted binder, the entry's charges are lent once
theorem PricedO.under_sub (hs : e.sub = true) (h : PricedO k pins (e :: env) π' M) :
    ∃ Y R, M.Perm (Y ++ R) ∧ (∀ y ∈ Y, Charge.lt y (k, pins)) ∧
      Sub R ((if π' 0 = .None then [] else e.chg) ++ EnvO.budget env (Uses.tail π')) :=
  let ⟨Y, R, hp, hY, hR⟩ := h
  ⟨Y, R, hp, hY, by
    simp only [EnvO.budget] at hR
    by_cases h0 : π' 0 = .None
    · rw [if_neg (fun h => h.2 h0)] at hR; rw [if_pos h0]; exact hR
    · rw [if_pos ⟨hs, h0⟩] at hR; rw [if_neg h0]; exact hR⟩

theorem PricedO.cover (h1 : PricedO k pins env π1 M1) (h2 : PricedO k pins env π2 M2)
    (hle1 : ∀ i, π1 i ≠ .None → π i ≠ .None) (hle2 : ∀ i, π2 i ≠ .None → π i ≠ .None) :
    ∃ M, Sub M1 M ∧ Sub M2 M ∧ PricedO k pins env π M := by
  obtain ⟨Y1, R1, hp1, hY1, hR1⟩ := h1
  obtain ⟨Y2, R2, hp2, hY2, hR2⟩ := h2
  refine ⟨Y1 ++ Y2 ++ EnvO.budget env π, ?_, ?_, Y1 ++ Y2, EnvO.budget env π, .refl _, ?_, Sub.refl
      _⟩
  · intro x
    have := List.perm_iff_count.mp hp1 x
    have := (hR1.trans (EnvO.budget_le env π1 π hle1)) x
    simp only [List.count_append] at *; omega
  · intro x
    have := List.perm_iff_count.mp hp2 x
    have := (hR2.trans (EnvO.budget_le env π2 π hle2)) x
    simp only [List.count_append] at *; omega
  · intro y hy; rw [List.mem_append] at hy; exact hy.elim (hY1 y) (hY2 y)

-- ----------------------------------------------------------------------------
-- lets in leaves: the instantiation under a let and under the type formers,
-- the agreement of two environments on a closed instance
-- ----------------------------------------------------------------------------

theorem Term.inst_let (d : Nat) : ∀ (ρ : List (Option Term)), Env.Closed ρ → ∀ (q : Quant) (v b :
    Term),
    Term.inst d ρ (.Let q v b) = .Let q (Term.inst d ρ v) (Term.inst (d + 1) ρ b) := by
  intro ρ
  induction ρ generalizing d with
  | nil => intro _ q v b; rfl
  | cons e0 ρ ih =>
    intro hc q v b
    cases e0 with
    | none => simp only [Term.inst]; exact ih (d + 1) hc.tail q v b
    | some w =>
      simp only [Term.inst]; rw [ih (d + 1) hc.tail]
      simp only [Term.subst]; rw [Term.shift_closed w 0 0 hc.head (Nat.le_refl 0)]

-- ----------------------------------------------------------------------------
-- δ on variables and shapes
-- ----------------------------------------------------------------------------

theorem Ctx.δ_var_lt : ∀ (Γ : Ctx) (d i : Nat), i < d → Ctx.δ Γ d (.Var i) = .Var i := by
  intro Γ
  induction Γ with
  | nil => intro d i _; rfl
  | cons b Γ ih =>
    intro d i hi
    obtain ⟨q, T, v⟩ := b
    cases v <;> simp only [Ctx.δ]
    · exact ih (d + 1) i (by omega)
    · simp only [Term.subst]; rw [if_neg (by omega), if_neg (by omega)]; exact ih d i hi

theorem Term.apps_cons_ne_var (x x0 : Term) : ∀ (xs : List Term) (i : Nat), Term.apps x (x0 :: xs)
    ≠ .Var i := by
  intro xs
  induction xs generalizing x x0 with
  | nil => intro i h; exact Term.noConfusion h
  | cons y ys ih => intro i; exact ih (.App x x0) y i

theorem Term.apps_ne_ctr_apps (hnc : ∀ a c xs, x ≠ Term.apps (.Ctr a c) xs) :
    ∀ (ys : List Term) (a c : Nat) (zs : List Term), Term.apps x ys ≠ Term.apps (.Ctr a c) zs := by
  intro ys a c zs h
  have e := congrArg Term.spine h
  rw [Term.spine_apps_of, Term.spine_apps (by trivial)] at e
  simp only [Prod.mk.injEq] at e
  exact hnc a c (Term.spine x).2 (by rw [← e.1]; exact (Term.apps_spine x).symm)

theorem Term.spine_shift_eq : ∀ (t : Term) (d : Nat),
    Term.spine (Term.shift d t) = (Term.shift d (Term.spine t).1, (Term.spine t).2.map (Term.shift
        d)) := by
  intro t
  induction t <;> intro d
  case App f a ihf _ =>
    simp only [Term.shift, Term.spine]; rw [ihf d]; simp
  case Var i => simp only [Term.shift]; split <;> simp [Term.spine, Term.shift, *]
  all_goals rfl

theorem Term.shift_eq_var (h : Term.shift d x = .Var j) : ∃ i, x = .Var i := by
  cases x <;> first | exact ⟨_, rfl⟩ | (simp [Term.shift] at h)

theorem Term.shift_eq_ctr (h : Term.shift d x = .Ctr a c) : x = .Ctr a c := by
  cases x <;> (try simp only [Term.shift] at h) <;>
    first | (split at h <;> cases h) | (cases h; rfl) | cases h

theorem Term.shift_eq_ctr_apps (h : Term.shift d x = Term.apps (.Ctr a c) zs) :
    ∃ ys, x = Term.apps (.Ctr a c) ys := by
  have e := congrArg Term.spine h
  rw [Term.spine_shift_eq, Term.spine_apps (by trivial)] at e
  simp only [Prod.mk.injEq] at e
  have hh : (Term.spine x).1 = .Ctr a c := Term.shift_eq_ctr e.1
  exact ⟨(Term.spine x).2, by rw [← hh]; exact (Term.apps_spine x).symm⟩

-- ----------------------------------------------------------------------------
-- DomS: the structural domination of an expanded source by its erased
-- instance — what an environment entry records, compositional under apps
-- ----------------------------------------------------------------------------

inductive DomS (β βe : Book) (ρ : List Term) (D : Nat) : Term → Term → Prop
  | nov  : (∀ i, x ≠ .Var i) → (∀ a c xs, x ≠ Term.apps (.Ctr a c) xs) → DomS β βe ρ D x e
  | var  : i < D → DomS β βe ρ D (.Var i) e
  | varO : D ≤ i → ρ[i - D]? = some v → v.Closed 0 → Deep βe v → DomS β βe ρ D (.Var i) v
  | qnt  : DomS β βe ρ D x .Qnt
  | ctr  : Book.adt β a = some A → AdtD.ctr A c = some C → era.length = src.length → A.pn ≤
      era.length →
           (∀ (i : Nat) e, i < A.pn → era[i]? = some e → e = .Qnt) →
           (∀ (i : Nat) x e, src[i]? = some x → era[i]? = some e → DomS β βe ρ D x e) →
           DomS β βe ρ D (Term.apps (.Ctr a c) src) (Term.apps (.Ctr a c) era)

theorem DomS.dom (hE : Book.Era β 0 β βe) (hρ : ∀ v ∈ ρ, Term.Closed 0 v) (h : DomS β βe ρ D x e)
    :
    DomP β βe ρ D x e := by
  induction h with
  | nov hnv hnc =>
    intro p _
    refine ⟨fun h1 => ?_, fun h1 => ?_⟩
    · rcases h1.shape with ⟨i, e1, _⟩ | ⟨a, c, _, _, ps, xs, _, _, _, _, _, _, e1, _, _⟩
      · exact absurd e1 (hnv i)
      · exact absurd e1 (hnc a c _)
    · rcases h1.shape with ⟨i, e1⟩ | ⟨a, c, vs, e1⟩
      · exact absurd e1 (hnv i)
      · exact absurd e1 (hnc a c vs)
  | var hi => exact DomP.kept hi _
  | @varO i v hi hj hc hd =>
    refine DomP.var hE ?_ hc hd
    have := Term.instL_var_some D ρ hρ hj; rwa [Nat.add_sub_cancel' hi] at this
  | qnt => exact DomP.qnt hE
  | ctr hk hC hlen _ hpar _ ih => exact DomP.ctr hE hk hC hlen hpar ih

theorem DomS.apps (h : DomS β βe ρ D x e) (hq : e = .Qnt → ∀ a c xs, x ≠ Term.apps (.Ctr a c) xs) :
    ∀ (xs es : List Term), es.length = xs.length →
    (∀ (i : Nat) x' e', xs[i]? = some x' → es[i]? = some e' → DomS β βe ρ D x' e') →
    DomS β βe ρ D (Term.apps x xs) (Term.apps e es) := by
  intro xs es hl hs
  cases xs with
  | nil => cases es with
    | nil => exact h
    | cons _ _ => simp at hl
  | cons x0 xs' =>
  cases h with
  | nov hnv hnc =>
    exact .nov (Term.apps_cons_ne_var x x0 xs') (fun a c zs => Term.apps_ne_ctr_apps hnc (x0 ::
        xs') a c zs)
  | var _ =>
    exact .nov (Term.apps_cons_ne_var _ x0 xs') (fun a c zs => Term.apps_ne_ctr_apps
      (fun a c ys h => Term.noConfusion (Term.apps_head_inv (xs := []) (by trivial) (by trivial)
          h).1) (x0 :: xs') a c zs)
  | varO _ _ _ _ =>
    exact .nov (Term.apps_cons_ne_var _ x0 xs') (fun a c zs => Term.apps_ne_ctr_apps
      (fun a c ys h => Term.noConfusion (Term.apps_head_inv (xs := []) (by trivial) (by trivial)
          h).1) (x0 :: xs') a c zs)
  | qnt =>
    exact .nov (Term.apps_cons_ne_var _ x0 xs') (fun a c zs => Term.apps_ne_ctr_apps (hq rfl) (x0
        :: xs') a c zs)
  | @ctr a A c C era src hk hC hlen hpn hpar hf =>
    rw [← Term.apps_append, ← Term.apps_append]
    refine .ctr hk hC (by simp [hlen, hl]) (by simp; omega) ?_ ?_
    · intro i e' hi he
      rw [List.getElem?_append_left (by omega)] at he
      exact hpar i e' hi he
    · intro i x' e' hx he
      rcases Nat.lt_or_ge i src.length with hi | hi
      · rw [List.getElem?_append_left hi] at hx
        rw [List.getElem?_append_left (by omega)] at he
        exact hf i x' e' hx he
      · rw [List.getElem?_append_right hi] at hx
        rw [List.getElem?_append_right (by omega), hlen] at he
        exact hs (i - src.length) x' e' hx he

-- a constructor spine is closed and deep iff its arguments are
theorem Term.ctr_closed_deep_iff (a c : Nat) (era : List Term) :
    ((Term.apps (.Ctr a c) era).Closed 0 ∧ Deep βe (Term.apps (.Ctr a c) era)) ↔
      ∀ e ∈ era, e.Closed 0 ∧ Deep βe e := by
  constructor
  · intro ⟨hc, hd⟩ e he
    exact ⟨(Term.closed_apps_inv _ _ _ hc).2 e he, (Deep.args hd (by trivial)).mem e he⟩
  · intro h
    exact ⟨Term.closed_apps _ _ _ trivial (fun e he => (h e he).1), .ctr (Deeps.of_mem fun e he =>
        (h e he).2)⟩


theorem Term.apps_ne_var (hnv : ∀ i, x ≠ .Var i) : ∀ (ys : List Term) (i : Nat), Term.apps x ys ≠
    .Var i
  | [], i => hnv i
  | y :: ys, i => Term.apps_cons_ne_var x y ys i

theorem Term.var_ne_ctr_apps (i : Nat) : ∀ a c xs, Term.Var i ≠ Term.apps (.Ctr a c) xs :=
  fun a c xs h => Term.noConfusion (Term.apps_head_inv (xs := []) (by trivial) (by trivial) h).1

-- a bad field (not closed and deep) refutes every verdict on the spine
theorem DomS.ctr_no_peq (hk : Book.adt β a = some A) (hC : AdtD.ctr A c = some C) {src : List Term}
    (hipn : A.pn ≤ i) (hil : i < src.length) (hx0 : src[i]? = some x0) (hd0 : DomP β βe ρ D x0 e0)
    (hne0 : ¬ (e0.Closed 0 ∧ Deep βe e0)) (ys : List Term) :
    PEq β (Term.apps (.Ctr a c) (src ++ ys)) p → Term.VarsGe D p → False := by
  intro h1 hp
  rcases h1.shape with ⟨_, e1, _⟩ | ⟨a', c', A', C', ps, xs, ys', hk', hc', hlp, hlx, hly, e1, rfl,
      hxy⟩
  · exact Term.noConfusion (Term.apps_head_inv (ys := []) (by trivial) (by trivial) e1).1
  obtain ⟨e2, e3⟩ := Term.apps_head_inv (by trivial) (by trivial) e1
  cases e2
  rw [hk] at hk'; cases hk'; rw [hC] at hc'; cases hc'
  have hxi : xs[i - A.pn]? = some x0 := by
    have : (ps ++ xs)[i]? = some x0 := by rw [← e3, List.getElem?_append_left hil]; exact hx0
    rw [List.getElem?_append_right (by omega), hlp] at this; exact this
  obtain ⟨y0, hy0⟩ : ∃ y0, ys'[i - A.pn]? = some y0 :=
    ⟨_, List.getElem?_eq_getElem (by rw [hly, ← hlx]; exact (List.getElem?_eq_some_iff.mp hxi).1)⟩
  have hpe := hxy.get (i - A.pn) hxi hy0
  have hd := (hd0 y0 (hp.field (List.mem_of_getElem? hy0))).1 hpe
  exact hne0 ⟨hd.1, hd.2.1⟩

theorem DomS.ctr_no_plt_ctr (hk : Book.adt β a = some A) (hC : AdtD.ctr A c = some C) {src : List
    Term}
    (hipn : A.pn ≤ i) (hil : i < src.length) (hx0 : src[i]? = some x0) (hd0 : DomP β βe ρ D x0 e0)
    (hne0 : ¬ (e0.Closed 0 ∧ Deep βe e0)) (ys : List Term) {a' c' : Nat} {A' : AdtD} {C' : CtrD}
    {ps xs ys' : List Term} (hk' : Book.adt β a' = some A') (hc' : AdtD.ctr A' c' = some C')
    (hlp : ps.length = A'.pn) (hxy : PLts β xs ys')
    (e : Term.apps (.Ctr a' c') (ps ++ xs) = Term.apps (.Ctr a c) (src ++ ys))
    (hp : Term.VarsGe D (Term.apps (.Ctr a' c') ys')) : False := by
  obtain ⟨e2, e3⟩ := Term.apps_head_inv (by trivial) (by trivial) e
  cases e2
  rw [hk] at hk'; cases hk'; rw [hC] at hc'; cases hc'
  have hxi : xs[i - A.pn]? = some x0 := by
    have : (ps ++ xs)[i]? = some x0 := by rw [e3, List.getElem?_append_left hil]; exact hx0
    rw [List.getElem?_append_right (by omega), hlp] at this; exact this
  have hly := hxy.length
  obtain ⟨y0, hy0⟩ : ∃ y0, ys'[i - A.pn]? = some y0 :=
    ⟨_, List.getElem?_eq_getElem (by rw [← hly]; exact (List.getElem?_eq_some_iff.mp hxi).1)⟩
  have hy0m : y0 ∈ ys' := List.mem_of_getElem? hy0
  rcases hxy.get (i - A.pn) hxi hy0 with hpe | hpl
  · have hd := (hd0 y0 (hp.field hy0m)).1 hpe; exact hne0 ⟨hd.1, hd.2.1⟩
  · have hd := (hd0 y0 (hp.field hy0m)).2 hpl; exact hne0 ⟨hd.1, hd.2.1⟩

theorem DomS.ctr_no_plt (hk : Book.adt β a = some A) (hC : AdtD.ctr A c = some C) {src : List Term}
    (hipn : A.pn ≤ i) (hil : i < src.length) (hx0 : src[i]? = some x0) (hd0 : DomP β βe ρ D x0 e0)
    (hne0 : ¬ (e0.Closed 0 ∧ Deep βe e0)) (ys : List Term) :
    ∀ {t p : Term}, PLt β t p → t = Term.apps (.Ctr a c) (src ++ ys) → Term.VarsGe D p → False
  | _, _, .subEq _ _ _ hy hpe, e, hp => by
    subst e; exact DomS.ctr_no_peq hk hC hipn hil hx0 hd0 hne0 ys hpe (hp.field hy)
  | _, _, .subLt _ _ _ hy hpl, e, hp =>
    DomS.ctr_no_plt hk hC hipn hil hx0 hd0 hne0 ys hpl e (hp.field hy)
  | _, _, .ctr hk' hc' hlp _ hxy, e, hp =>
    DomS.ctr_no_plt_ctr hk hC hipn hil hx0 hd0 hne0 ys hk' hc' hlp hxy e hp

-- an entry whose erased instance is not closed and deep is no verdict's
-- side, under any pending spine
theorem DomS.no_verdict (hE : Book.Era β 0 β βe) (hρ : ∀ v ∈ ρ, Term.Closed 0 v) (h : DomS β βe ρ
    D x e)
    (hne : ¬ (e.Closed 0 ∧ Deep βe e)) : ∀ (ys : List Term) (p : Term), Term.VarsGe D p →
    ¬ PEq β (Term.apps x ys) p ∧ ¬ PLt β (Term.apps x ys) p := by
  intro ys p hp
  have nov_case : (∀ i, Term.apps x ys ≠ .Var i) → (∀ a c xs, Term.apps x ys ≠ Term.apps (.Ctr a c)
      xs) →
      ¬ PEq β (Term.apps x ys) p ∧ ¬ PLt β (Term.apps x ys) p := by
    intro hnv hnc
    have hd := DomS.dom hE hρ (DomS.nov (e := .Var 0) hnv hnc) p hp
    exact ⟨fun h1 => Nat.lt_irrefl 0 (hd.1 h1).1, fun h1 => Nat.lt_irrefl 0 (hd.2 h1).1⟩
  cases h with
  | nov hnv hnc => exact nov_case (Term.apps_ne_var hnv ys) (Term.apps_ne_ctr_apps hnc ys)
  | @var i _ hi =>
    cases ys with
    | nil =>
      refine ⟨fun h1 => ?_, fun h1 => PLt.var_absurd hi h1 rfl hp⟩
      rw [h1.var_inv] at hp; have := hp.var; omega
    | cons y ys =>
      exact nov_case (Term.apps_cons_ne_var _ y ys) (Term.apps_ne_ctr_apps (Term.var_ne_ctr_apps i)
          (y :: ys))
  | varO _ _ hc hd => exact absurd ⟨hc, hd⟩ hne
  | qnt => exact absurd ⟨trivial, .qnt⟩ hne
  | @ctr a A c C era src hk hC hlen hpn hpar hf =>
    obtain ⟨e0, he0, hne0⟩ : ∃ e0 ∈ era, ¬ (e0.Closed 0 ∧ Deep βe e0) :=
      Classical.byContradiction fun hcon => hne ((Term.ctr_closed_deep_iff a c era).mpr
        fun e he => Classical.byContradiction fun hn => hcon ⟨e, he, hn⟩)
    obtain ⟨i, hi⟩ := List.mem_iff_getElem?.mp he0
    have hipn : A.pn ≤ i := Nat.le_of_not_lt fun hlt => hne0
        (by rw [hpar i e0 hlt hi]; exact ⟨trivial, .qnt⟩)
    have hil : i < src.length := by rw [← hlen]; exact (List.getElem?_eq_some_iff.mp hi).1
    obtain ⟨x0, hx0⟩ : ∃ x0, src[i]? = some x0 := ⟨_, List.getElem?_eq_getElem hil⟩
    have hd0 := DomS.dom hE hρ (hf i x0 e0 hx0 hi)
    rw [← Term.apps_append]
    exact ⟨fun h1 => DomS.ctr_no_peq hk hC hipn hil hx0 hd0 hne0 ys h1 hp,
      fun h1 => DomS.ctr_no_plt hk hC hipn hil hx0 hd0 hne0 ys h1 rfl hp⟩

-- under a new rigid binder the expanded source shifts
theorem DomS.shift (h : DomS β βe ρ D x e) : DomS β βe ρ (D + 1) (Term.shift 0 x) e := by
  induction h with
  | nov hnv hnc =>
    refine .nov (fun i h1 => ?_) (fun a c xs h1 => ?_)
    · obtain ⟨i', e'⟩ := Term.shift_eq_var h1; exact hnv i' e'
    · obtain ⟨ys, e'⟩ := Term.shift_eq_ctr_apps h1; exact hnc a c ys e'
  | @var i _ hi => simp only [Term.shift]; rw [if_neg (by omega)]; exact .var (by omega)
  | @varO i v hi hj hc hd =>
    simp only [Term.shift]; rw [if_neg (by omega)]
    exact .varO (by omega) (by rw [show i + 1 - (D + 1) = i - D by omega]; exact hj) hc hd
  | qnt => exact .qnt
  | @ctr a A c C era src hk hC hlen hpn hpar _ ih =>
    rw [Term.shift_apps]
    simp only [Term.shift]
    refine .ctr hk hC (by simp [hlen]) hpn hpar ?_
    intro i x' e' hx he
    rw [List.getElem?_map] at hx
    obtain ⟨x0, hx0, rfl⟩ := Option.map_eq_some_iff.mp hx
    exact ih i x0 e' hx0 he

-- ----------------------------------------------------------------------------
-- NoV D x: x is no verdict's side under any pending spine, at this depth
-- and every deeper one (closed under shifts, so an entry keeps it)
-- ----------------------------------------------------------------------------

def NoV (β : Book) (D : Nat) (x : Term) : Prop :=
  ∀ (m : Nat) (ys : List Term) (p : Term), Term.VarsGe (D + m) p →
    ¬ PEq β (Term.apps (Term.shiftN m x) ys) p ∧ ¬ PLt β (Term.apps (Term.shiftN m x) ys) p

theorem NoV.shift (h : NoV β D x) : NoV β (D + 1) (Term.shift 0 x) := fun m ys p hp => by
  rw [Term.shiftN_shift0]
  exact h (m + 1) ys p (by rw [← Nat.add_assoc, Nat.add_right_comm]; exact hp)

theorem NoV.shiftN (h : NoV β D x) : ∀ (m : Nat), NoV β (D + m) (Term.shiftN m x)
  | 0 => h
  | m + 1 => (NoV.shiftN h m).shift

theorem NoV.apps (h : NoV β D x) (ys : List Term) : NoV β D (Term.apps x ys) := fun m ys' p hp => by
  rw [Term.shiftN_apps, ← Term.apps_append]; exact h m _ p hp

theorem NoV.dom (h : NoV β D x) (e : Term) : DomP β βe ρ D x e := fun p hp =>
  ⟨fun h1 => absurd h1 (h 0 [] p hp).1, fun h1 => absurd h1 (h 0 [] p hp).2⟩

theorem DomS.shiftN (h : DomS β βe ρ D x e) : ∀ (m : Nat), DomS β βe ρ (D + m) (Term.shiftN m x) e
  | 0 => h
  | m + 1 => (DomS.shiftN h m).shift

theorem DomS.nov_of (hE : Book.Era β 0 β βe) (hρ : ∀ v ∈ ρ, Term.Closed 0 v) (h : DomS β βe ρ D x
    e)
    (hne : ¬ (e.Closed 0 ∧ Deep βe e)) : NoV β D x :=
  fun m ys p hp => DomS.no_verdict hE hρ (h.shiftN m) hne ys p hp

theorem Term.shiftN_ctr : ∀ (m a c : Nat), Term.shiftN m (.Ctr a c) = .Ctr a c
  | 0, _, _ => rfl
  | m + 1, a, c => by simp only [Term.shiftN]; rw [Term.shiftN_ctr m a c]; rfl

theorem Term.var0_not_closed_deep : ¬ ((Term.Var 0).Closed 0 ∧ Deep βe (.Var 0)) :=
  fun h => Nat.lt_irrefl 0 h.1

-- a constructor spine with a verdict-free field is verdict-free
theorem NoV.ctr_field (hk : Book.adt β a = some A) (hC : AdtD.ctr A c = some C) {src : List Term}
    (hipn : A.pn ≤ i) (hil : i < src.length) (hx0 : src[i]? = some x0) (hn : NoV β D x0) :
    NoV β D (Term.apps (.Ctr a c) src) := by
  intro m ys p hp
  rw [Term.shiftN_apps, Term.shiftN_ctr, ← Term.apps_append]
  have hd0 : DomP β β [] (D + m) (Term.shiftN m x0) (.Var 0) := NoV.dom (hn.shiftN m) _
  have hx0' : (src.map (Term.shiftN m))[i]? = some (Term.shiftN m x0) :=
      by rw [List.getElem?_map, hx0]; rfl
  exact ⟨fun h1 => DomS.ctr_no_peq hk hC hipn (by simpa using hil) hx0' hd0
      Term.var0_not_closed_deep ys h1 hp,
    fun h1 => DomS.ctr_no_plt hk hC hipn (by simpa using hil) hx0' hd0 Term.var0_not_closed_deep ys
        h1 rfl hp⟩

-- ----------------------------------------------------------------------------
-- δ under the two binders a leaf adds, and on rigid heads
-- ----------------------------------------------------------------------------

theorem Ctx.δ_cons_rig (q : Quant) (T : Term) (Γ : Ctx) (d : Nat) (t : Term) :
    Ctx.δ (⟨q, T, none⟩ :: Γ) d t = Ctx.δ Γ (d + 1) t := rfl

theorem Ctx.δ_cons_let (q : Quant) (T v : Term) (Γ : Ctx) (t : Term) :
    Ctx.δ (⟨q, T, some v⟩ :: Γ) 0 t = Ctx.δ Γ 0 (Term.subst 0 v t) := rfl

theorem Term.subst0_var_succ (v : Term) (j : Nat) : Term.subst 0 v (.Var (j + 1)) = .Var j := by
  simp [Term.subst]

theorem Term.subst0_var_zero (v : Term) : Term.subst 0 v (.Var 0) = v := by simp [Term.subst]

theorem Ctx.δ_var_succ_rig (Γ : Ctx) (j : Nat) :
    Ctx.δ Γ 1 (.Var (j + 1)) = Term.shift 0 (Ctx.δ Γ 0 (.Var j)) := by
  have := Ctx.δ_shift Γ 0 0 (.Var j) (Nat.le_refl 0)
  simpa [Term.shift] using this

-- a head that is neither a variable nor a constructor stays so under δ
theorem Term.subst_head (hh : t.IsHead) (hnv : ∀ i, t ≠ .Var i) (hnc : ∀ a c, t ≠ .Ctr a c) (d :
    Nat) (w : Term) :
    (Term.subst d w t).IsHead ∧ (∀ i, Term.subst d w t ≠ .Var i) ∧ (∀ a c, Term.subst d w t ≠ .Ctr
        a c) := by
  cases t <;> first
    | exact absurd rfl (hnv _)
    | exact absurd rfl (hnc _ _)
    | exact hh.elim
    | (simp only [Term.subst]; exact ⟨trivial, fun _ h => Term.noConfusion h, fun _ _ h =>
         Term.noConfusion h⟩)

theorem Ctx.δ_head : ∀ (Γ : Ctx) (d : Nat) {t : Term}, t.IsHead → (∀ i, t ≠ .Var i) → (∀ a c, t ≠
    .Ctr a c) →
    (Ctx.δ Γ d t).IsHead ∧ (∀ i, Ctx.δ Γ d t ≠ .Var i) ∧ (∀ a c, Ctx.δ Γ d t ≠ .Ctr a c) := by
  intro Γ
  induction Γ with
  | nil => intro d t hh hnv hnc; exact ⟨hh, hnv, hnc⟩
  | cons b Γ ih =>
    intro d t hh hnv hnc
    obtain ⟨q, T, v⟩ := b
    cases v <;> simp only [Ctx.δ]
    · exact ih (d + 1) hh hnv hnc
    · obtain ⟨h1, h2, h3⟩ := Term.subst_head hh hnv hnc d _
      exact ih d h1 h2 h3

theorem DomS.rigid_head (hh : t.IsHead) (hnv : ∀ i, t ≠ .Var i) (hnc : ∀ a c, t ≠ .Ctr a c) (Γ :
    Ctx)
    (xs : List Term) (e : Term) : DomS β βe ρ D (Term.apps (Ctx.δ Γ 0 t) xs) e := by
  obtain ⟨h1, h2, h3⟩ := Ctx.δ_head Γ 0 hh hnv hnc
  refine .nov (Term.apps_ne_var h2 xs) (Term.apps_ne_ctr_apps ?_ xs)
  intro a c ys h
  cases ys with
  | nil => exact h3 a c h
  | cons y ys =>
    exact absurd (Term.apps_head_inv (xs := []) (ys := y :: ys) h1 (by trivial) h).1 (h3 a c)

-- ----------------------------------------------------------------------------
-- the tok lemmas in a let-bearing context (the conversions are δ-expanded)
-- ----------------------------------------------------------------------------

theorem Args.ctr_tokδ (hβ : Book.Closed β) :
    ∀ {pn : Nat} {ps0 : List Term} {Tw T0 T1 : Term} {as : List Term} {πs : Uses} {us : List Term},
    WTele a r ps0 pn fn Tw → Args β (Pol.std β) L q Γ T0 as T1 πs us →
    Le β (Ctx.δ Γ 0 (Term.retip r' pn (pn + fn) Tw)) (Ctx.δ Γ 0 T0) →
    ∀ (i : Nat) u, i < pn → us[i]? = some u → u = .Qnt := by
  intro pn
  induction pn with
  | zero => intro _ _ _ _ _ _ _ _ _ _ i _ hi; omega
  | succ pk ih =>
    intro ps0 Tw T0 T1 as πs us hw h hle i u hi hu
    cases h with
    | nil => simp at hu
    | @cons _ q' A B x πx0 ux0 as' _ πs0 us0 hc hx hr =>
      obtain ⟨qw, K, Bw, hT, hwB, hw'⟩ := WTele.param (x := x) hw
      subst hT
      rw [show pk + 1 + fn = pk + fn + 1 by omega] at hle
      obtain ⟨πx, ux, πs', us', B1, _, hus, hx', hB, hr'⟩ :=
        Args.step hβ (hle : Le β (Ctx.δ Γ 0 (.All .None K (Term.retip r' pk (pk + fn) Bw))) (Ctx.δ
            Γ 0 T0))
          (.cons hc hx hr)
      obtain ⟨rfl, rfl⟩ := List.cons.inj hus
      cases i with
      | zero => simp at hu; subst hu; exact hx'.none_era rfl
      | succ i =>
        rw [WTele.retip_subst hwB r' 0 x] at hB
        exact ih hw' hr' hB i u (by omega) (by simpa using hu)

theorem Args.teleqs_tokδ (hβ : Book.Closed β) :
    ∀ (n : Nat) {qs : List Quant} {Tw : Term}, TeleQs β Tw n qs →
    ∀ {T0 T1 : Term} {as : List Term} {πs : Uses} {us : List Term},
    Args β (Pol.std β) L q Γ T0 as T1 πs us → Le β (Ctx.δ Γ 0 Tw) (Ctx.δ Γ 0 T0) →
    ∀ (i : Nat) u, us[i]? = some u → qs.getD i .Lone = .None → u = .Qnt := by
  intro n
  induction n with
  | zero => intro qs Tw ht; cases ht; intro _ _ _ _ _ _ _ i _ _ hq; simp at hq
  | succ n ih =>
    intro qs Tw ht
    cases ht with
    | cons hred ht' =>
      rename_i q0 A B qs'
      intro T0 T1 as πs us h hle i u hu hq
      cases h with
      | nil => simp at hu
      | @cons _ q' A' B' x πx0 ux0 as' _ πs0 us0 hc hx hr =>
        have hle' : Le β (Ctx.δ Γ 0 (.All q0 A B)) (Ctx.δ Γ 0 T0) :=
          Le.red_l hβ (Ctx.δ_red hβ Γ 0 hred.strong) hle
        obtain ⟨πx, ux, πs', us', B1, _, hus, hx', hB, hr'⟩ := Args.step hβ hle' (.cons hc hx hr)
        obtain ⟨rfl, rfl⟩ := List.cons.inj hus
        cases i with
        | zero =>
          simp at hu; subst hu
          simp at hq; subst hq
          exact hx'.none_era rfl
        | succ i =>
          exact ih (TeleQs.subst hβ ht' 0 x) hr' hB i u (by simpa using hu) (by simpa using hq)

-- ----------------------------------------------------------------------------
-- closing a derivation over an environment: every binder substituted by
-- its closed value, from the outermost in (D's Check.subst_std iterated)
-- ----------------------------------------------------------------------------

theorem Term.instL_nil (d : Nat) (t : Term) : Term.instL d [] t = t := rfl

theorem Term.instL_snoc (d : Nat) : ∀ (ρ : List Term) (w t : Term),
    Term.instL d (ρ ++ [w]) t = Term.instL d ρ (Term.subst (d + ρ.length) w t) := by
  intro ρ
  induction ρ generalizing d with
  | nil =>
    intro w t
    simp only [Term.instL, List.nil_append, List.map_cons, List.map_nil, Term.inst,
        List.length_nil, Nat.add_zero]
  | cons v ρ ih =>
    intro w t
    simp only [Term.instL, List.cons_append, List.map_cons, Term.inst, List.length_cons] at *
    rw [ih (d + 1), show d + 1 + ρ.length = d + (ρ.length + 1) by omega]

theorem Ctx.get_of_lt : ∀ (Γ : Ctx) (i : Nat), i < Γ.length → ∃ b, Ctx.get Γ i = some b := by
  intro Γ
  induction Γ with
  | nil => intro i h; simp at h
  | cons b Γ ih =>
    intro i h
    cases i with
    | zero => exact ⟨_, rfl⟩
    | succ i =>
      obtain ⟨b', hb'⟩ := ih i (by simpa using h)
      exact ⟨_, by rw [Ctx.get_succ, hb']; rfl⟩

inductive ClosOk (β : Book) : Ctx → List (Term × Term) → Prop
  | nil : ClosOk β [] []
  | snoc {Γ : Ctx} {env : List (Term × Term)} {b0 : Bind} {w uw : Term} :
      w.Closed 0 → uw.Closed 0 → (b0.v = none ∨ b0.v = some w) →
      Check β (Pol.std β) (LHS.void β) [] .None [] w b0.T Uses.zero .Qnt →
      (b0.q ≠ .None → ∃ πw, Check β (Pol.std β) (LHS.void β) [] .Lone [] w b0.T πw uw) →
      (b0.q ≠ .None → ∀ m a r ps, Conv β (Term.shiftN m b0.T) (Term.apps (.Adt a r) ps) → ¬
          Book.empty β a r) →
      ClosOk β (Ctx.substLast w Γ) env → ClosOk β (Γ ++ [b0]) (env ++ [(w, uw)])

theorem ClosOk.length : ClosOk β Γ env → Γ.length = env.length := by
  intro h
  induction h with
  | nil => rfl
  | snoc _ _ _ _ _ _ _ ih => simp only [Ctx.substLast_length] at ih; simp [ih]

theorem ClosOk.cons : ∀ {Γ : Ctx} {env : List (Term × Term)}, ClosOk β Γ env →
    ∀ (b : Bind) (w uw : Term), w.Closed 0 → uw.Closed 0 →
    (b.v = none ∨ ∃ v, b.v = some v ∧ Term.instL 0 (env.map Prod.fst) v = w) →
    Check β (Pol.std β) (LHS.void β) [] .None [] w (Term.instL 0 (env.map Prod.fst) b.T) Uses.zero
        .Qnt →
    (b.q ≠ .None → ∃ πw, Check β (Pol.std β) (LHS.void β) [] .Lone [] w (Term.instL 0 (env.map
        Prod.fst) b.T) πw uw) →
    (b.q ≠ .None → ∀ m a r ps, Conv β (Term.shiftN m (Term.instL 0 (env.map Prod.fst) b.T))
      (Term.apps (.Adt a r) ps) → ¬ Book.empty β a r) →
    ClosOk β (b :: Γ) ((w, uw) :: env) := by
  intro Γ env hc
  induction hc with
  | nil =>
    intro b w uw hw huw hv h0 h1 hd
    simp only [List.map_nil, Term.instL_nil] at hv h0 h1 hd
    have hv' : b.v = none ∨ b.v = some w :=
      hv.elim Or.inl (fun ⟨v, hbv, e⟩ => Or.inr (by rw [hbv, e]))
    exact (ClosOk.snoc (Γ := []) (env := []) hw huw hv' h0 h1 hd .nil : ClosOk β ([] ++ [b]) ([] ++
        [(w, uw)]))
  | @snoc Γ env b0 w0 uw0 hw0 huw0 hv0 h00 h10 hd0 hc' ih =>
    intro b w uw hw huw hv h0 h1 hd
    have hlen : Γ.length = env.length := by
      have := hc'.length; simpa only [Ctx.substLast_length] using this
    have e : ∀ x, Term.instL 0 ((env ++ [(w0, uw0)]).map Prod.fst) x
        = Term.instL 0 (env.map Prod.fst) (Term.subst Γ.length w0 x) := by
      intro x
      rw [List.map_append]
      simp only [List.map_cons, List.map_nil]
      rw [Term.instL_snoc]
      simp [hlen]
    show ClosOk β ((b :: Γ) ++ [b0]) (((w, uw) :: env) ++ [(w0, uw0)])
    refine ClosOk.snoc hw0 huw0 hv0 h00 h10 hd0 ?_
    show ClosOk β (Bind.substAt Γ.length w0 b :: Ctx.substLast w0 Γ) ((w, uw) :: env)
    refine ih (b.substAt Γ.length w0) w uw hw huw ?_ ?_ ?_ ?_
    · rcases hv with hv | ⟨v, hbv, hvw⟩
      · left; simp [Bind.substAt, hv]
      · right; refine ⟨Term.subst Γ.length w0 v, by simp [Bind.substAt, hbv], ?_⟩
        rw [← e]; exact hvw
    · simp only [Bind.substAt]; rw [← e]; exact h0
    · simp only [Bind.substAt]; rw [← e]; exact h1
    · simp only [Bind.substAt]; rw [← e]; exact hd

theorem Term.apps_ne_qnt (hne : x ≠ .Qnt) : ∀ (ys : List Term), Term.apps x ys ≠ .Qnt
  | [] => hne
  | y :: ys => fun h => by
    have := congrArg Term.spine h
    rw [Term.spine_apps_of] at this
    simp [Term.spine] at this

theorem Term.shiftN_eq_var : ∀ (m : Nat), Term.shiftN m x = .Var j → ∃ i, x = .Var i
  | 0, h => ⟨_, h⟩
  | m + 1, h => by
    obtain ⟨i, hi⟩ := Term.shift_eq_var h
    exact Term.shiftN_eq_var m hi

theorem Term.shiftN_eq_ctr_apps : ∀ (m : Nat), Term.shiftN m x = Term.apps (.Ctr a c) zs →
    ∃ ys, x = Term.apps (.Ctr a c) ys
  | 0, h => ⟨_, h⟩
  | m + 1, h => by
    obtain ⟨ys, hy⟩ := Term.shift_eq_ctr_apps h
    exact Term.shiftN_eq_ctr_apps m hy

-- a term that is neither a variable nor a constructor spine is verdict-free
theorem NoV.of_nov (hnv : ∀ i, x ≠ .Var i) (hnc : ∀ a c xs, x ≠ Term.apps (.Ctr a c) xs) : NoV β D
    x := by
  intro m ys p _
  have h1 : ∀ i, Term.apps (Term.shiftN m x) ys ≠ .Var i :=
    Term.apps_ne_var (fun i h => by obtain ⟨_, h2⟩ := Term.shiftN_eq_var m h; exact hnv _ h2) ys
  have h2 : ∀ a c zs, Term.apps (Term.shiftN m x) ys ≠ Term.apps (.Ctr a c) zs :=
    Term.apps_ne_ctr_apps (fun a c zs h =>
        by obtain ⟨_, h3⟩ := Term.shiftN_eq_ctr_apps m h; exact hnc a c _ h3) ys
  refine ⟨fun hp => ?_, fun hp => ?_⟩
  · rcases hp.shape with ⟨i, e1, _⟩ | ⟨a, c, _, _, ps, xs, _, _, _, _, _, _, e1, _, _⟩
    · exact h1 i e1
    · exact h2 a c _ e1
  · rcases hp.shape with ⟨i, e1⟩ | ⟨a, c, vs, e1⟩
    · exact h1 i e1
    · exact h2 a c vs e1

-- a rigid head applied to a pending spine is never a constructor spine
theorem DomS.rigid_side (hh : t.IsHead) (hnv : ∀ i, t ≠ .Var i) (hnc : ∀ a c, t ≠ .Ctr a c) (Γ :
    Ctx)
    (xs : List Term) : ∀ a c ys, Term.apps (Ctx.δ Γ 0 t) xs ≠ Term.apps (.Ctr a c) ys := by
  obtain ⟨h1, h2, h3⟩ := Ctx.δ_head Γ 0 hh hnv hnc
  exact Term.apps_ne_ctr_apps (fun a c ys h' => by
    cases ys with
    | nil => exact h3 a c h'
    | cons y ys =>
      exact absurd (Term.apps_head_inv (xs := []) (ys := y :: ys) h1 (by trivial) h').1 (h3 a c)) xs


-- ============================================================================
-- METATHEORY §N4c — lets in leaves: the semantic Data type (Dat), the closing
-- of dead derivations over the leaf's environment, the pure shapes (PureD)
-- and the position lemma, the leaf state and pricing with lets, the walk
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Dat β X: X is Data-kinded, semantically: it reduces to no function type,
-- kind or Quant, and a family reduct's instantiated kind fits Many. It is
-- what a Data kinding in any rigid context yields (Kd2b's kind_red'), and
-- it descends along Le, so "T is fitted below a Data-kinded type" is Dat T
-- ----------------------------------------------------------------------------

def Dat (β : Book) (X : Term) : Prop :=
  (∀ q A B, ¬ Red β .strong X (.All q A B)) ∧ (∀ g, ¬ Red β .strong X (.Typ g)) ∧
  ¬ Red β .strong X .Qnt ∧
  (∀ a r ps A0, Red β .strong X (Term.apps (.Adt a r) ps) → Book.adt β a = some A0 →
    ps.length = A0.pn → ∃ G, STele β A0.pn A0.sig G ∧ KLe β (Term.instGo ps G) (.Qua .Many))

theorem Dat.of_le (hβ : Book.Closed β) (h : Le β D X) (hX : Dat β X) : Dat β D := by
  refine ⟨fun q A B hr => ?_, fun g hr => ?_, fun hr => ?_, fun a r ps A0 hr hA hlen => ?_⟩
  · obtain ⟨_, _, hr'⟩ := Le.all_r (h.red_l hβ hr); exact hX.1 _ _ _ hr'
  · obtain ⟨_, hr'⟩ := Le.typ_r (h.red_l hβ hr); exact hX.2.1 _ hr'
  · exact hX.2.2.1 (Le.qnt_r (h.red_l hβ hr))
  · obtain ⟨r', ps', hr', _, hcs⟩ := Le.adt_r (h.red_l hβ hr)
    obtain ⟨G, hS, hK⟩ := hX.2.2.2 _ _ _ _ hr' hA (by rw [← hcs.length]; exact hlen)
    exact ⟨G, hS, KLe.trans hβ (KLe.conv (Term.instGo.conv hβ hcs (Conv.refl G))) _ hK⟩

theorem Dat.of_kind (hok : Book.Ok β) {sp : List Term}
    (h : Check β (Pol.dead β) (LHS.void β) sp .None Γ X (.Typ (.Qua .Many)) π u)
    (hΓ : ∀ b ∈ Γ, b.v = none) : Dat β X := by
  have hβ := hok.closed
  have hδ := Ctx.δ_rigid Γ hΓ
  have h0 := h.void_sp []
  refine ⟨fun q A B hr => ?_, fun g hr => ?_, fun hr => ?_, fun a r ps A0 hr hA hlen => ?_⟩
  · have hc := (Check.kind_red' hok h0 hr).1 q A B _root_.rfl
    rw [hδ, hδ] at hc
    exact KLe.lone_many hβ.qer (Pol.dead_typ_inv hβ hc)
  · have hc := (Check.kind_red' hok h0 hr).2.1 g _root_.rfl
    rw [hδ, hδ] at hc
    exact KLe.lone_many hβ.qer (Pol.dead_typ_inv hβ hc)
  · have hc := (Check.kind_red' hok h0 hr).2.2.1 _root_.rfl
    rw [hδ, hδ] at hc
    exact KLe.lone_many hβ.qer (Pol.dead_typ_inv hβ hc)
  · obtain ⟨G, hS, hc⟩ := (Check.kind_red' hok h0 hr).2.2.2 a r ps A0 _root_.rfl hA hlen
    rw [hδ, hδ] at hc
    exact ⟨G, hS, KLe.qer_many (Pol.dead_typ_inv hβ hc) _ _root_.rfl⟩

-- a closed deep value at a Dat type is inert (N3's data_deep_aux with the
-- kinding replaced by Dat: the top level only, the fields by N3's lemma)
theorem Check.dat_deep (hok : Book.Ok β)
    (h : Check β (Pol.std β) (LHS.void β) [] .Lone [] a A πa ua) (hD : Dat β A) (hd : Deep β ua) :
    (∀ β', CG β' ua []) ∧ (∀ β', Term.weight β' ua = 0) := by
  have hβ := hok.closed
  have hΦ := Pol.std_pre hβ
  have hP := DataPol.dead' hok
  have hK := Book.OkK.dead hok
  obtain ⟨v, π', _, hv, h'⟩ := h.deep_value hβ (by decide) hd
  have hvt := Check.value_head hok (by decide) hv h' (Check.deep_not_bad hok hd)
  cases hvt with
  | typ hl => obtain ⟨_, _, _, _, rfl⟩ := h'.typ_inv hΦ; exact ⟨fun _ => .typ, fun _ => _root_.rfl⟩
  | qnt hl => obtain ⟨_, _, rfl⟩ := h'.qnt_inv hΦ; exact ⟨fun _ => .qnt, fun _ => _root_.rfl⟩
  | all hl =>
    obtain ⟨_, _, _, _, _, _, rfl⟩ := h'.all_inv hΦ
    exact ⟨fun _ => .all, fun _ => _root_.rfl⟩
  | eql hl =>
    obtain ⟨_, _, _, _, _, _, _, _, rfl⟩ := h'.eql_inv hΦ
    exact ⟨fun _ => .eql, fun _ => _root_.rfl⟩
  | qua hl => obtain ⟨_, _, rfl⟩ := h'.qua_inv hΦ; exact ⟨fun _ => .qua, fun _ => _root_.rfl⟩
  | rfl hl =>
    obtain ⟨_, _, _, _, _, _, rfl⟩ := h'.rfl_inv hΦ
    exact ⟨fun _ => .rfl, fun _ => _root_.rfl⟩
  | adtT _ _ hl => obtain ⟨_, hr⟩ := hl.typ_r; exact (hD.2.1 _ hr).elim
  | lam hl => obtain ⟨_, _, hr⟩ := hl.all_r; exact (hD.1 _ _ _ hr).elim
  | mat _ hl => obtain ⟨_, _, hr⟩ := hl.all_r; exact (hD.1 _ _ _ hr).elim
  | efq hl => obtain ⟨_, _, hr⟩ := hl.all_r; exact (hD.1 _ _ _ hr).elim
  | adtF _ _ hl => obtain ⟨_, _, hr⟩ := hl.all_r; exact (hD.1 _ _ _ hr).elim
  | ctrF _ _ _ hl => obtain ⟨_, _, hr⟩ := hl.all_r; exact (hD.1 _ _ _ hr).elim
  | ref _ _ hl => obtain ⟨_, _, hr⟩ := hl.all_r; exact (hD.1 _ _ _ hr).elim
  | @ctr a0 A0 c C r' _ as hA hC hr hlen hl =>
    obtain ⟨T0, π0, u0, T1, πs, us, hh0, hargs, _, rfl, hlus⟩ :=
      h'.spine_era hβ (fun _ e => Term.noConfusion e)
    obtain ⟨A', C', r0, hA', hC', hr0, hle0, _, rfl⟩ := hh0.ctr_inv hΦ
    rw [hA] at hA'; cases hA'
    rw [hC] at hC'; cases hC'
    simp only [Term.era_lone] at hd ⊢
    obtain ⟨G, hS, hD'⟩ := hK _ _ _ _ hA hC
    have hshape : WTele a0 [] [] A0.pn C.fn C.ty := hok.shape hA hC
    rw [← List.take_append_drop A0.pn as] at hargs
    obtain ⟨Tm, πp, up, πx, ux, hargsP, hargsF, _, rfl⟩ := hargs.split
    obtain ⟨TS, _, hFT, hle', hD'', hup⟩ :=
      CtrOkD.params hβ hP.weak hP.std hP.efq hP.efqS hshape hD' hargsP hle0 (by simp; omega)
    have hfields := CtrOkD.fields_qs hβ hP.weak hP.std hP.efq hP.efqS
      (by simpa using hFT) hD'' hargsF hle' (by simp; omega)
    -- the family's instantiated kind fits Data
    obtain ⟨r'', ps', hred, _, hcs⟩ := hl.adt_r
    obtain ⟨G', hS', hKle'⟩ := hD.2.2.2 _ _ _ _ hred hA (by rw [← hcs.length]; simp; omega)
    have hcl : ∀ p ∈ as.take A0.pn, Term.Closed 0 p := fun p hp =>
      (Term.closed_apps_inv _ _ _ h'.closed).2 p (List.mem_of_mem_take hp)
    have hKle : KLe β (Term.instG (as.take A0.pn) G) (.Qua .Many) := by
      rw [← Term.instGo_closed _ _ hcl]
      exact KLe.trans hβ (KLe.conv (Term.instGo.conv hβ hcs (STele.conv hβ hS hS'))) _ hKle'
    -- every argument's erasure is inert
    have hdus : Deeps β (up ++ ux) := Deep.args hd (by trivial)
    have hall : ∀ u ∈ up ++ ux, (∀ β', CG β' u []) ∧ (∀ β', Term.weight β' u = 0) := by
      intro u hu
      rw [List.mem_append] at hu
      rcases hu with hu | hu
      · rw [hup u hu]; exact ⟨fun _ => .qnt, fun _ => _root_.rfl⟩
      · obtain ⟨j, hj⟩ := List.mem_iff_getElem?.mp hu
        have hjl : j < (as.drop A0.pn).length := by
          rw [← hargsF.length]; exact (List.getElem?_eq_some_iff.mp hj).1
        obtain ⟨qf, F, πx', _, hx, πF, hKF⟩ := hfields j _ u (List.getElem?_eq_getElem hjl) hj
        have hdu : Deep β u := hdus.mem u (by simp [hu])
        cases qf with
        | None => rw [hx.none_era _root_.rfl]; exact ⟨fun _ => .qnt, fun _ => _root_.rfl⟩
        | Lone =>
          simp only [if_true] at hKF
          exact Check.data_deep_aux hok hP hK _ (Nat.le_refl _) hx (hKF.cnv (hP.kind _ hKle)) hdu
        | Many =>
          simp only [reduceCtorEq, if_false] at hKF
          exact Check.data_deep_aux hok hP hK _ (Nat.le_refl _) hx hKF hdu
    refine ⟨fun β' => ?_, fun β' => ?_⟩
    · exact CG.apps (.ctr) (CGs.of_forall fun u hu => (hall u hu).1 β')
    · rw [Term.weight_apps]
      simp only [Term.weight, Nat.zero_add]
      exact List.sum_map_zero _ fun u hu => (hall u hu).2 β'

-- ----------------------------------------------------------------------------
-- closing a DEAD derivation over the leaf's environment: the lets are
-- expanded with Kc's open substitution (LetsOk: every let value is
-- dead-typed in its own context), the walk's columns are substituted by
-- their closed sources (the walk's ClosOk); the leaf's lambdas stay, in
-- some rigid context. The result is the instance instL r ρS (δ Γ 0 t)
-- ----------------------------------------------------------------------------

def LetsOk (β : Book) (Γw : Ctx) : Ctx → Prop
  | [] => True
  | b :: Γ => (∀ v, b.v = some v →
      ∃ π u, Check β (Pol.dead β) (LHS.void β) [] .None (Γ ++ Γw) v b.T π u) ∧ LetsOk β Γw Γ

theorem Ctx.substAt_rigid_mem (w : Term) : ∀ (Γ : Ctx), (∀ b ∈ Γ, b.v = none) →
    ∀ b ∈ Ctx.substAt w Γ, b.v = none := by
  intro Γ
  induction Γ with
  | nil => intro _ b hb; simp [Ctx.substAt] at hb
  | cons b0 Γ ih =>
    intro h b hb
    simp only [Ctx.substAt, List.mem_cons] at hb
    rcases hb with rfl | hb
    · simp [Bind.substAt, h b0 (by simp)]
    · exact ih (fun b hb => h b (by simp [hb])) b hb

theorem Ctx.substAt_append_ex (w : Term) : ∀ (Δ Γ : Ctx), ∃ Δ', Ctx.substAt w (Δ ++ Γ) = Δ' ++
    Ctx.substAt w Γ ∧
    Δ'.length = Δ.length ∧ ((∀ b ∈ Δ, b.v = none) → ∀ b ∈ Δ', b.v = none) := by
  intro Δ Γ
  induction Δ with
  | nil => exact ⟨[], rfl, rfl, fun _ b hb => by simp at hb⟩
  | cons b Δ ih =>
    obtain ⟨Δ', e, hl, hr⟩ := ih
    refine ⟨Bind.substAt (Δ ++ Γ).length (Term.shiftN (Δ ++ Γ).length w) b :: Δ', ?_,
        by simp [hl], ?_⟩
    · simp only [List.cons_append, Ctx.substAt, e]
    · intro h b' hb'
      simp only [List.mem_cons] at hb'
      rcases hb' with rfl | hb'
      · simp [Bind.substAt, h b (by simp)]
      · exact hr (fun b hb => h b (by simp [hb])) b' hb'

theorem Ctx.substAt_closed (hw : Term.Closed 0 w) : ∀ (Γ : Ctx), Ctx.substAt w Γ = Ctx.substLast w
    Γ := by
  intro Γ
  induction Γ with
  | nil => rfl
  | cons b Γ ih => simp only [Ctx.substAt, Ctx.substLast, Term.shiftN_closed hw, ih]

theorem Check.δ_dead (hβ : Book.Closed β) :
    ∀ (Γl : Ctx), LetsOk β Γw Γl → ∀ {Δ : Ctx} {sp : List Term} {t T : Term} {π : Uses} {u : Term},
    (∀ b ∈ Δ, b.v = none) →
    Check β (Pol.dead β) (LHS.void β) sp .None (Δ ++ Γl ++ Γw) t T π u →
    ∃ Λ, Λ.length = Δ.length + Γl.rigid ∧ (∀ b ∈ Λ, b.v = none) ∧
      Check β (Pol.dead β) (LHS.void β) [] .None (Λ ++ Γw) (Ctx.δ Γl Δ.length t) (Ctx.δ Γl Δ.length
          T)
        Uses.zero .Qnt := by
  intro Γl
  induction Γl with
  | nil =>
    intro _ Δ sp t T π u hΔ h
    exact ⟨Δ,
        by simp [Ctx.rigid], hΔ,
             by simpa [Ctx.δ] using Check.zero_of_none (h.void_sp []) _root_.rfl⟩
  | cons b Γl ih =>
    intro hL Δ sp t T π u hΔ h
    obtain ⟨q, A, v⟩ := b
    obtain ⟨hb, hL'⟩ := hL
    cases v with
    | none =>
      obtain ⟨Λ, hlen, hΛ, h'⟩ := ih hL' (Δ := Δ ++ [⟨q, A, none⟩])
        (fun b hb =>
            by simp only [List.mem_append, List.mem_singleton] at hb; rcases hb with hb | rfl;
                 exact hΔ b hb; rfl)
        (by simpa [List.append_assoc] using h)
      refine ⟨Λ, by simp [Ctx.rigid] at hlen ⊢; omega, hΛ, ?_⟩
      simpa [Ctx.δ] using h'
    | some v =>
      obtain ⟨π', u', hv⟩ := hb v _root_.rfl
      have h1 := Check.substD hβ h hv (.inr _root_.rfl) Δ (by simp [List.append_assoc]) _root_.rfl
      obtain ⟨Λ, hlen, hΛ, h'⟩ := ih hL' (Δ := Ctx.substAt v Δ) (Ctx.substAt_rigid_mem v Δ hΔ)
        (by simpa [List.append_assoc] using h1)
      refine ⟨Λ, by simp [Ctx.rigid, Ctx.substAt_length] at hlen ⊢; omega, hΛ, ?_⟩
      simpa [Ctx.δ, Ctx.substAt_length] using h'

theorem Check.closeW (hβ : Book.Closed β) : ∀ {Γw : Ctx} {env : List (Term × Term)}, ClosOk β Γw
    env →
    ∀ {Δ : Ctx} {sp : List Term} {t T : Term} {π : Uses} {u : Term}, (∀ b ∈ Δ, b.v = none) →
    Check β (Pol.dead β) (LHS.void β) sp .None (Δ ++ Γw) t T π u →
    ∃ Λ, (∀ b ∈ Λ, b.v = none) ∧
      Check β (Pol.dead β) (LHS.void β) [] .None Λ (Term.instL Δ.length (env.map Prod.fst) t)
        (Term.instL Δ.length (env.map Prod.fst) T) Uses.zero .Qnt := by
  intro Γw env hc
  induction hc with
  | nil =>
    intro Δ sp t T π u hΔ h
    exact ⟨Δ, hΔ, by simpa [Term.instL_nil] using Check.zero_of_none (h.void_sp []) _root_.rfl⟩
  | @snoc Γ env b0 w uw hw _ hv h0 _ _ hc' ih =>
    intro Δ sp t T π u hΔ h
    have hlen : Γ.length = env.length := by
      have := hc'.length; simpa only [Ctx.substLast_length] using this
    have h1 := Check.substD hβ h (Check.dead_pol hβ h0) hv (Δ ++ Γ) (by simp [List.append_assoc])
        _root_.rfl
    obtain ⟨Δ', e, hl, hr⟩ := Ctx.substAt_append_ex w Δ Γ
    rw [e, Ctx.substAt_closed hw, List.append_nil, Term.shiftN_closed hw] at h1
    obtain ⟨Λ, hΛ, h'⟩ := ih (hr hΔ) h1
    refine ⟨Λ, hΛ, ?_⟩
    simp only [List.map_append, List.map_cons, List.map_nil]
    rw [Term.instL_snoc, Term.instL_snoc]
    simp only [List.length_map, ← hlen]
    rw [hl] at h'
    simpa [List.length_append] using h'

-- the leaf's context: its own binders over the walk's rigid, closed columns
def Outer (β : Book) (Γ : Ctx) (r : Nat) (ρS ρO : List Term) : Prop :=
  ∃ (Γl Γw : Ctx) (env : List (Term × Term)), Γ = Γl ++ Γw ∧ Γl.rigid = r ∧ (∀ b ∈ Γw, b.v = none) ∧
    ClosOk β Γw env ∧ env.map Prod.fst = ρS ∧ env.map Prod.snd = ρO ∧ LetsOk β Γw Γl

theorem Check.closeD (hβ : Book.Closed β) (ho : Outer β Γ r ρS ρO) {sp : List Term}
    (h : Check β (Pol.dead β) (LHS.void β) sp .None Γ t T π u) :
    ∃ Λ, (∀ b ∈ Λ, b.v = none) ∧
      Check β (Pol.dead β) (LHS.void β) [] .None Λ (Term.instL r ρS (Ctx.δ Γ 0 t))
        (Term.instL r ρS (Ctx.δ Γ 0 T)) Uses.zero .Qnt := by
  obtain ⟨Γl, Γw, env, rfl, rfl, hw, hc, rfl, _, hL⟩ := ho
  obtain ⟨Λ1, hl1, hΛ1, h1⟩ := Check.δ_dead hβ Γl hL (Δ := []) (fun _ h => by simp at h)
      (by simpa using h)
  obtain ⟨Λ, hΛ, h2⟩ := Check.closeW hβ hc hΛ1 h1
  refine ⟨Λ, hΛ, ?_⟩
  rw [Ctx.δ_append, Ctx.δ_append, Ctx.δ_rigid Γw hw, Ctx.δ_rigid Γw hw]
  rw [hl1] at h2
  simpa using h2

theorem Outer.lam (ho : Outer β Γ r ρS ρO) (q : Quant) (A : Term) :
    Outer β (⟨q, A, none⟩ :: Γ) (r + 1) ρS ρO := by
  obtain ⟨Γl, Γw, env, rfl, rfl, hw, hc, hs, he, hL⟩ := ho
  exact ⟨⟨q, A, none⟩ :: Γl, Γw, env, rfl, by simp [Ctx.rigid], hw, hc, hs, he,
    ⟨fun _ h => by simp at h, hL⟩⟩

theorem Outer.let (ho : Outer β Γ r ρS ρO) (q : Quant) (A v : Term)
    (hv : Check β (Pol.dead β) (LHS.void β) [] .None Γ v A π u) :
    Outer β (⟨q, A, some v⟩ :: Γ) r ρS ρO := by
  obtain ⟨Γl, Γw, env, rfl, rfl, hw, hc, hs, he, hL⟩ := ho
  exact ⟨⟨q, A, some v⟩ :: Γl, Γw, env, rfl, by simp [Ctx.rigid], hw, hc, hs, he,
    ⟨fun v' hv' => by cases hv'; exact ⟨_, _, hv⟩, hL⟩⟩

-- a Data kinding in the leaf's context makes its instance Dat, under any shift
theorem Dat.of_outer (hok : Book.Ok β) (ho : Outer β Γ r ρS ρO) {sp : List Term}
    (h : Check β (Pol.std β) L sp .None Γ P (.Typ (.Qua .Many)) π u) :
    ∀ n, Dat β (Term.shiftN n (Term.instL r ρS (Ctx.δ Γ 0 P))) := by
  intro n
  have hβ := hok.closed
  obtain ⟨Λ, hΛ, h'⟩ := Check.closeD hβ ho (Check.dead_pol hβ h.void)
  rw [Ctx.δ_closed _ _ (.Typ (.Qua .Many)) trivial, Term.instL_closed _ _ (t := .Typ (.Qua .Many))
      trivial] at h'
  have h'' := Check.consN hβ (Pol.dead_weak hβ) h' (List.replicate n ⟨.None, .Qnt, none⟩) []
  rw [List.length_replicate, Term.shiftN_closed (w := Term.Typ (.Qua .Many)) trivial] at h''
  refine Dat.of_kind hok h'' ?_
  intro b hb
  rw [List.mem_append] at hb
  rcases hb with hb | hb
  · rw [List.mem_replicate] at hb; rw [hb.2]
  · exact hΛ b hb

-- ----------------------------------------------------------------------------
-- the constructor walk instantiated by OPEN arguments (Kc's substD) in any
-- base context: the fields' domains are kinded at the family's instantiated
-- kind (Kd2b's instGo, which the outermost-first substitution spells)
-- ----------------------------------------------------------------------------

theorem Insts.shiftN (h : Insts T ps T') : ∀ (n : Nat),
    Insts (Term.shiftN n T) (ps.map (Term.shiftN n)) (Term.shiftN n T') := by
  intro n
  induction n with
  | zero => rw [Term.map_shiftN_zero]; exact h
  | succ n ih =>
    have := ih.shift 0
    simp only [Term.shiftN]
    rw [List.map_map] at this
    exact this

theorem Insts.unique : Insts T ps X → Insts T ps X' → X = X' := by
  intro h
  induction h with
  | nil => intro h'; cases h'; rfl
  | cons _ ih => intro h'; cases h'; exact ih (by assumption)

theorem CtrOkD.weaken (hβ : Book.Closed β) : ∀ {T : Term} {Γ : Ctx} {i : Nat},
    CtrOkD β (Pol.dead β) pn G Γ i T → ∀ (Δ : Ctx), CtrOkD β (Pol.dead β) pn G (Γ ++ Δ) i T := by
  intro T
  induction T with
  | All q A B _ ih =>
    intro Γ i h Δ
    obtain ⟨⟨π, hA⟩, hB⟩ := h
    exact ⟨⟨π, Check.weaken hβ (Pol.dead_weak hβ) hA Δ⟩, ih hB Δ⟩
  | _ => intros; trivial

theorem CtrOkD.substD (hβ : Book.Closed β) {Γ₁ : Ctx} {b0 : Bind} {w : Term} {π0 : Uses} {u0 : Term}
    (hv : b0.v = none)
    (h0 : Check β (Pol.dead β) (LHS.void β) [] .None Γ₁ w b0.T π0 u0)
    (hcase : (pn = 0 ∧ pn' = 0 ∧ G' = G) ∨
      (∃ pk, pn = pk + 1 ∧ pn' = pk ∧ G' = Term.subst pk (Term.shiftN pk w) G)) :
    ∀ {T : Term} {Γ : Ctx}, Term.IsTele T → CtrOkD β (Pol.dead β) pn G (Γ ++ b0 :: Γ₁) (Γ.length +
        1) T →
    CtrOkD β (Pol.dead β) pn' G' (Ctx.substAt w Γ ++ Γ₁) Γ.length
      (Term.subst Γ.length (Term.shiftN Γ.length w) T) := by
  intro T
  induction T with
  | All q A B _ ih =>
    intro Γ hT h
    obtain ⟨⟨π, hA⟩, hB⟩ := h
    have hA' := Check.substD hβ hA h0 (.inl hv) Γ _root_.rfl _root_.rfl
    have hK : Term.subst Γ.length (Term.shiftN Γ.length w)
        (if pn ≤ Γ.length + 1 ∧ q = .Lone then .Typ (Term.shiftN (Γ.length + 1 - pn) G) else .Typ
            (.Qua q))
        = (if pn' ≤ Γ.length ∧ q = .Lone then .Typ (Term.shiftN (Γ.length - pn') G') else .Typ
            (.Qua q)) := by
      rcases hcase with ⟨rfl, rfl, rfl⟩ | ⟨pk, hpn, hpn', hG'⟩
      · split <;> rename_i h1 <;> split <;> rename_i h2
        · show Term.Typ _ = Term.Typ _
          rw [Nat.sub_zero, Nat.sub_zero, Term.subst_shiftN]
        · exact absurd ⟨Nat.zero_le _, h1.2⟩ h2
        · exact absurd ⟨Nat.zero_le _, h2.2⟩ h1
        · rfl
      · subst hpn hG'
        rw [hpn']
        split <;> rename_i h1 <;> split <;> rename_i h2
        · show Term.Typ _ = Term.Typ _
          rw [show Γ.length + 1 - (pk + 1) = Γ.length - pk by omega]
          have := Term.subst_shiftN_open w G pk (Γ.length - pk)
          rw [show Γ.length - pk + pk = Γ.length by omega] at this
          rw [this]
        · exact absurd ⟨by omega, h1.2⟩ h2
        · exact absurd ⟨by omega, h2.2⟩ h1
        · rfl
    refine ⟨⟨_, hK ▸ hA'⟩, ?_⟩
    exact ih (Γ := ⟨q, A, none⟩ :: Γ) hT hB
  | Var j =>
    intro Γ hT _
    obtain ⟨_, _, _, h⟩ := hT
    exact absurd h.symm (Term.apps_adt_ne (by trivial) (fun e => Term.noConfusion e))
  | _ => intros; simp only [Term.subst]; trivial

-- the parameters instantiate the walk (Kb's Args.paramsD with the walk carried along)
theorem CtrOkD.paramsO (hβ : Book.Closed β) :
    ∀ {qs : List Term} {pn : Nat} {ps0 : List Term} {Tw T0 Tm G : Term} {πp : Uses} {up : List
        Term},
    WTele a r ps0 pn fn Tw → CtrOkD β (Pol.dead β) pn G Λ 0 Tw →
    Args β (Pol.dead β) L .None Λ T0 qs Tm πp up →
    (Pol.dead β).conv (Ctx.δ Λ 0 (Term.retip r' pn (pn + fn) Tw)) (Ctx.δ Λ 0 T0) → qs.length = pn →
    ∃ TS, Insts Tw qs TS ∧ FTele a r (ps0 ++ qs) fn TS ∧
      (Pol.dead β).conv (Ctx.δ Λ 0 (Term.retip r' 0 fn TS)) (Ctx.δ Λ 0 Tm) ∧
      CtrOkD β (Pol.dead β) 0 (Term.instGo qs G) Λ 0 TS := by
  intro qs
  induction qs with
  | nil =>
    intro pn ps0 Tw T0 Tm G πp up hw hD h hle hlen
    cases h
    cases pn with
    | zero =>
      rw [Nat.zero_add] at hle
      exact ⟨Tw, .nil, by rw [List.append_nil]; exact hw, hle, hD⟩
    | succ pk => simp at hlen
  | cons x qs ih =>
    intro pn ps0 Tw T0 Tm G πp up hw hD h hle hlen
    cases pn with
    | zero => simp at hlen
    | succ pk =>
      obtain ⟨qw, K, Bw, hT, hwB, hw'⟩ := WTele.param (x := x) hw
      subst hT
      rw [show pk + 1 + fn = pk + fn + 1 by omega] at hle
      obtain ⟨πx, ux, πs', us', B1, _, rfl, hx, hB, hr⟩ :=
        Args.stepD hβ (Γ := Λ) (qw := .None) (K := K) (Bw := Term.retip r' pk (pk + fn) Bw) hle h
      rw [WTele.retip_subst hwB r' 0 x] at hB
      obtain ⟨⟨πK, hK⟩, hrest⟩ := hD
      have hD' := CtrOkD.substD hβ (b0 := ⟨qw, K, none⟩) _root_.rfl hx.void
        (.inr ⟨pk, _root_.rfl, _root_.rfl, _root_.rfl⟩) (Γ := []) hwB.isTele hrest
      obtain ⟨TS, hI, hF, hle', hD''⟩ := ih hw' hD' hr hB (by simp at hlen; omega)
      refine ⟨TS, .cons hI, by simpa [List.append_assoc] using hF, hle', ?_⟩
      simp only [Term.instGo]
      rw [show qs.length = pk by simp at hlen; omega]
      exact hD''

-- the field walk: every field checks at a domain the instantiated walk
-- kinds; the domain is the telescope's, opened by the previous fields
theorem CtrOkD.fieldsO (hβ : Book.Closed β) :
    ∀ {xs : List Term} {fn : Nat} {ps : List Term} {TS T0 T1 : Term} {πs : Uses} {us : List Term},
    FTele a r ps fn TS → CtrOkD β (Pol.dead β) 0 G' Λ 0 TS →
    Args β (Pol.dead β) L .None Λ T0 xs T1 πs us →
    (Pol.dead β).conv (Ctx.δ Λ 0 (Term.retip r' 0 fn TS)) (Ctx.δ Λ 0 T0) → xs.length = fn →
    ∀ (j : Nat) x u, xs[j]? = some x → us[j]? = some u →
      ∃ qf F B πx, Insts TS (xs.take j) (.All qf F B) ∧
        Check β (Pol.dead β) L [] .None Λ x F πx u ∧
        ∃ π, Check β (Pol.dead β) (LHS.void β) [] .None Λ F
          (if qf = .Lone then .Typ G' else .Typ (.Qua qf)) π .Qnt := by
  intro xs
  induction xs with
  | nil => intro fn ps TS T0 T1 πs us _ _ _ _ _ j x u hx; simp at hx
  | cons x xs ih =>
    intro fn ps TS T0 T1 πs us hF hD h hle hlen j x' u hx' hu
    cases fn with
    | zero => simp at hlen
    | succ fk =>
      obtain ⟨qf, F, Bs, hT, hFB, hF'⟩ := FTele.field (x := x) hF
      subst hT
      obtain ⟨πx, ux, πs', us', B1, rfl, rfl, hx, hB, hr⟩ :=
        Args.stepD hβ (Γ := Λ) (qw := qf) (K := F) (Bw := Term.retip r' 0 fk Bs) hle h
      rw [FTele.retip_subst hFB r' 0 x] at hB
      obtain ⟨⟨πF, hKF⟩, hrest⟩ := hD
      have hD' := CtrOkD.substD hβ (b0 := ⟨qf, F, none⟩) _root_.rfl hx.void
        (.inl ⟨_root_.rfl, _root_.rfl, _root_.rfl⟩) (Γ := []) hFB.isTele hrest
      cases j with
      | zero =>
        simp at hx' hu
        subst hx' hu
        refine ⟨qf, F, Bs, πx, .nil, hx, πF, ?_⟩
        simpa [Term.shiftN] using hKF
      | succ j =>
        simp at hx' hu
        obtain ⟨T', hr', _⟩ := hr.le_start (Pol.dead_pre hβ) hB
        obtain ⟨qf', F', B', πx', hI, hx'', hK'⟩ :=
          ih hF' hD' hr' ((Pol.dead_pre hβ).refl _) (by simp at hlen; omega) j x' u hx' hu
        exact ⟨qf', F', B', πx', .cons hI, hx'', hK'⟩

-- ----------------------------------------------------------------------------
-- CtrsFull: every constructor of a leaf carries all its arguments (the
-- residue of N4's syntactic condition). Closed under shift, substitution and
-- the context's let expansion when the let values are full
-- ----------------------------------------------------------------------------

theorem Term.CtrsFull.mono_n : ∀ {t : Term} {n m : Nat}, Term.CtrsFull β n t → n ≤ m →
    Term.CtrsFull β m t := by
  intro t
  induction t <;> intro n m h hnm <;> simp only [Term.CtrsFull] at h ⊢
  case App f a ihf _ => exact ⟨ihf h.1 (by omega), h.2⟩
  case Ctr a c => intro A C hA hC; exact Nat.le_trans (h A C hA hC) hnm
  all_goals exact h

theorem Term.CtrsFull.shift : ∀ {t : Term} {n : Nat}, Term.CtrsFull β n t → ∀ (d : Nat),
    Term.CtrsFull β n (Term.shift d t) := by
  intro t
  induction t <;> intro n h d <;> simp only [Term.CtrsFull, Term.shift] at h ⊢
  case Var i => split <;> simp [Term.CtrsFull]
  case App f a ihf iha => exact ⟨ihf h.1 d, iha h.2 d⟩
  case Lam f ih => exact ih h (d + 1)
  case Let q v b ihv ihb => exact ⟨ihv h.1 d, ihb h.2 (d + 1)⟩
  case Mat a c hh m ihh ihm => exact ⟨ihh h.1 d, ihm h.2 d⟩
  case Min a b iha ihb => exact ⟨iha h.1 d, ihb h.2 d⟩
  case Rwt e P f ihe _ ihf => exact ⟨ihe h.1 d, ihf h.2 d⟩
  all_goals first | trivial | exact h

theorem Term.CtrsFull.shiftN (h : Term.CtrsFull β n t) : ∀ (d : Nat), Term.CtrsFull β n
    (Term.shiftN d t)
  | 0 => h
  | d + 1 => (Term.CtrsFull.shiftN h d).shift 0

theorem Term.CtrsFull.subst : ∀ {t : Term} {n : Nat} {w : Term}, Term.CtrsFull β n t →
    Term.CtrsFull β 0 w → ∀ (d : Nat), Term.CtrsFull β n (Term.subst d w t) := by
  intro t
  induction t <;> intro n w h hw d <;> simp only [Term.CtrsFull, Term.subst] at h ⊢
  case Var i =>
    split
    · exact hw.mono_n (Nat.zero_le n)
    · split <;> simp [Term.CtrsFull]
  case App f a ihf iha => exact ⟨ihf h.1 hw d, iha h.2 hw d⟩
  case Lam f ih => exact ih h (hw.shift 0) (d + 1)
  case Let q v b ihv ihb => exact ⟨ihv h.1 hw d, ihb h.2 (hw.shift 0) (d + 1)⟩
  case Mat a c hh m ihh ihm => exact ⟨ihh h.1 hw d, ihm h.2 hw d⟩
  case Min a b iha ihb => exact ⟨iha h.1 hw d, ihb h.2 hw d⟩
  case Rwt e P f ihe _ ihf => exact ⟨ihe h.1 hw d, ihf h.2 hw d⟩
  all_goals first | trivial | exact h

theorem Term.CtrsFull.apps_head : ∀ (zs : List Term) (h : Term) {n : Nat}, Term.CtrsFull β n
    (Term.apps h zs) →
    Term.CtrsFull β (n + zs.length) h := by
  intro zs
  induction zs with
  | nil => intro h n hh; exact hh
  | cons z zs ih =>
    intro h n hh
    have := ih (.App h z) hh
    simp only [Term.CtrsFull] at this
    rw [List.length_cons, ← Nat.add_assoc]
    exact this.1

theorem Term.CtrsFull.apps_ctr (h : Term.CtrsFull β n (Term.apps (.Ctr a c) zs))
    (hA : Book.adt β a = some A) (hC : AdtD.ctr A c = some C) : A.pn + C.fn ≤ n + zs.length :=
  Term.CtrsFull.apps_head zs _ h A C hA hC

-- every let value of the context is full
def Ctx.LetsFull (β : Book) : Ctx → Prop
  | [] => True
  | b :: Γ => (∀ v, b.v = some v → Term.CtrsFull β 0 v) ∧ Ctx.LetsFull β Γ

theorem Term.CtrsFull.δ : ∀ (Γ : Ctx), Ctx.LetsFull β Γ → ∀ (d : Nat) {t : Term}, Term.CtrsFull β 0
    t →
    Term.CtrsFull β 0 (Ctx.δ Γ d t) := by
  intro Γ
  induction Γ with
  | nil => intro _ d t h; exact h
  | cons b Γ ih =>
    intro hL d t h
    obtain ⟨q, T, v⟩ := b
    obtain ⟨hb, hL'⟩ := hL
    cases v with
    | none => exact ih hL' (d + 1) h
    | some v => exact ih hL' d (h.subst ((hb v _root_.rfl).shiftN d) d)

-- ----------------------------------------------------------------------------
-- PureD: the shapes of DomS that can carry a verdict — a substituted
-- variable, a token, a full constructor spine of such. Every other DomS
-- shape is verdict-free (NoV) once its instance is closed and deep
-- ----------------------------------------------------------------------------

inductive PureD (β βe : Book) (ρ : List Term) (D : Nat) : Term → Term → Prop
  | varO : D ≤ i → ρ[i - D]? = some v → v.Closed 0 → Deep βe v → PureD β βe ρ D (.Var i) v
  | qnt  : PureD β βe ρ D x .Qnt
  | ctr  : Book.adt β a = some A → AdtD.ctr A c = some C → era.length = src.length →
           src.length = A.pn + C.fn →
           (∀ (i : Nat) e, i < A.pn → era[i]? = some e → e = .Qnt) →
           (∀ (i : Nat) x e, src[i]? = some x → era[i]? = some e → PureD β βe ρ D x e) →
           PureD β βe ρ D (Term.apps (.Ctr a c) src) (Term.apps (.Ctr a c) era)

theorem PureD.shape (h : PureD β βe ρ D x e) :
    (∃ i, x = .Var i) ∨ e = .Qnt ∨
    (∃ a c A C src era, Book.adt β a = some A ∧ AdtD.ctr A c = some C ∧ src.length = A.pn + C.fn ∧
      x = Term.apps (.Ctr a c) src ∧ e = Term.apps (.Ctr a c) era ∧
      (∀ (i : Nat) x e, src[i]? = some x → era[i]? = some e → PureD β βe ρ D x e)) := by
  cases h with
  | varO => exact .inl ⟨_, rfl⟩
  | qnt => exact .inr (.inl rfl)
  | ctr hA hC _ hlen _ hf => exact .inr (.inr ⟨_, _, _, _, _, _, hA, hC, hlen, rfl, rfl, hf⟩)

-- a constructor spine on a verdict's side has exactly its declared arguments
theorem PEq.ctr_len (h : PEq β t p) (ht : t = Term.apps (.Ctr a c) vs) (hA : Book.adt β a = some A)
    (hC : AdtD.ctr A c = some C) : vs.length = A.pn + C.fn := by
  rcases h.shape with ⟨i, e1, _⟩ | ⟨a', c', A', C', ps, xs, _, hA', hC', hps, hxs, _, e1, _, _⟩
  · rw [ht] at e1; exact absurd e1 (Term.apps_ne_var (fun _ h => Term.noConfusion h) vs i)
  · rw [ht] at e1
    obtain ⟨e2, e3⟩ := Term.apps_head_inv (by trivial) (by trivial) e1
    cases e2
    rw [hA] at hA'; cases hA'
    rw [hC] at hC'; cases hC'
    rw [e3]; simp [hps, hxs]

theorem PLt.ctr_len : ∀ {t p : Term}, PLt β t p → t = Term.apps (.Ctr a c) vs → Book.adt β a = some
    A →
    AdtD.ctr A c = some C → vs.length = A.pn + C.fn
  | _, _, .subEq _ _ _ _ hpe, ht, hA, hC => hpe.ctr_len ht hA hC
  | _, _, .subLt _ _ _ _ hpl, ht, hA, hC => PLt.ctr_len hpl ht hA hC
  | _, _, .ctr hA' hC' hps hxs _, ht, hA, hC => by
    obtain ⟨e2, e3⟩ := Term.apps_head_inv (by trivial) (by trivial) ht.symm
    cases e2
    rw [hA] at hA'; cases hA'
    rw [hC] at hC'; cases hC'
    rw [e3]; simp [hps, hxs]

theorem NoV.ctr_over (hA : Book.adt β a = some A) (hC : AdtD.ctr A c = some C) (src : List Term)
    (hl : A.pn + C.fn < src.length) : NoV β D (Term.apps (.Ctr a c) src) := by
  intro m ys p _
  rw [Term.shiftN_apps, Term.shiftN_ctr, ← Term.apps_append]
  refine ⟨fun h1 => ?_, fun h1 => ?_⟩
  · have := h1.ctr_len rfl hA hC; simp at this; omega
  · have := h1.ctr_len rfl hA hC; simp at this; omega

theorem Term.CtrsFull.apps_arg : ∀ (zs : List Term) (h : Term) {n : Nat}, Term.CtrsFull β n
    (Term.apps h zs) →
    ∀ x ∈ zs, Term.CtrsFull β 0 x := by
  intro zs
  induction zs with
  | nil => intro _ _ _ x hx; simp at hx
  | cons z zs ih =>
    intro h n hh x hx
    simp only [List.mem_cons] at hx
    rcases hx with rfl | hx
    · have := Term.CtrsFull.apps_head zs _ hh; exact this.2
    · exact ih (.App h z) hh x hx

theorem DomS.pure_or_nov (hE : Book.Era β 0 β βe) (hρ : ∀ v ∈ ρ, Term.Closed 0 v) :
    DomS β βe ρ D x e → e.Closed 0 → Deep βe e → Term.CtrsFull β 0 x → PureD β βe ρ D x e ∨ NoV β D
        x := by
  intro h
  induction h with
  | nov hnv hnc => intro _ _ _; exact .inr (NoV.of_nov hnv hnc)
  | var hi =>
    intro _ _ _
    exact .inr (DomS.nov_of hE hρ (DomS.var (e := .Var 0) hi) (fun h => Nat.lt_irrefl 0 h.1))
  | varO hi hj hc hd => intro _ _ _; exact .inl (.varO hi hj hc hd)
  | qnt => intro _ _ _; exact .inl .qnt
  | @ctr a A c C era src hk hC hlen hpn hpar hf ih =>
    intro hc hd hfull
    have hced := (Term.ctr_closed_deep_iff a c era).mp ⟨hc, hd⟩
    have hge : A.pn + C.fn ≤ src.length := by have := hfull.apps_ctr hk hC; simpa using this
    rcases Nat.lt_or_eq_of_le hge with hlt | heq
    · exact .inr (NoV.ctr_over hk hC src hlt)
    · by_cases hall : ∀ (i : Nat) x e, src[i]? = some x → era[i]? = some e → PureD β βe ρ D x e
      · exact .inl (.ctr hk hC hlen heq.symm hpar hall)
      · obtain ⟨i, x0, e0, hx0, he0, hnp⟩ : ∃ i x e, src[i]? = some x ∧ era[i]? = some e ∧ ¬ PureD
          β βe ρ D x e :=
          Classical.byContradiction fun hcon =>
            hall fun i x e hx he => Classical.byContradiction fun hn => hcon ⟨i, x, e, hx, he, hn⟩
        have hil : i < src.length := (List.getElem?_eq_some_iff.mp hx0).1
        have hce := hced e0 (List.mem_of_getElem? he0)
        have hxf : Term.CtrsFull β 0 x0 := Term.CtrsFull.apps_arg src _ hfull x0
            (List.mem_of_getElem? hx0)
        rcases ih i x0 e0 hx0 he0 hce.1 hce.2 hxf with hp | hn
        · exact absurd hp hnp
        · have hipn : A.pn ≤ i := Nat.le_of_not_lt fun hlt => by
            have := hpar i e0 hlt he0; subst this; exact hnp .qnt
          exact .inr (NoV.ctr_field hk hC hipn hil hx0 hn)

-- ----------------------------------------------------------------------------
-- the closed instance of a leaf term at depth m under the leaf's lambdas:
-- lets expanded, columns substituted, shifted under m more binders
-- ----------------------------------------------------------------------------

def Term.cl (Γ : Ctx) (r : Nat) (ρS : List Term) (m : Nat) (t : Term) : Term :=
  Term.shiftN m (Term.instL r ρS (Ctx.δ Γ 0 t))

theorem Le.shiftN (hβ : Book.Closed β) (h : Le β a b) : ∀ (n : Nat), Le β (Term.shiftN n a)
    (Term.shiftN n b)
  | 0 => h
  | n + 1 => (Le.shiftN hβ h n).shift hβ 0

theorem Le.cl (hβ : Book.Closed β) (h : Le β (Ctx.δ Γ 0 a) (Ctx.δ Γ 0 b)) (r : Nat) (ρS : List
    Term) (m : Nat) :
    Le β (Term.cl Γ r ρS m a) (Term.cl Γ r ρS m b) :=
  (h.instL hβ r ρS).shiftN hβ m

theorem Term.cl_apps (hh : h.Closed 0) (xs : List Term) :
    Term.cl Γ r ρS m (Term.apps h xs) = Term.apps h (xs.map (Term.cl Γ r ρS m)) := by
  simp only [Term.cl]
  rw [Ctx.δ_apps, Term.instL_apps, Term.shiftN_apps, List.map_map, List.map_map]
  rw [Ctx.δ_closed _ _ _ (Term.Closed.mono _ _ _ hh (Nat.zero_le _)),
    Term.instL_closed _ _ (Term.Closed.mono _ _ _ hh (Nat.zero_le _)), Term.shiftN_closed hh]
  rfl

theorem Term.shiftN_all : ∀ (n : Nat) (q : Quant) (A B : Term), ∃ B', Term.shiftN n (.All q A B) =
    .All q (Term.shiftN n A) B' := by
  intro n
  induction n with
  | zero => intro q A B; exact ⟨B, rfl⟩
  | succ n ih =>
    intro q A B
    obtain ⟨B', e⟩ := ih q A B
    exact ⟨_, by simp only [Term.shiftN]; rw [e]; rfl⟩

theorem Term.cl_all (hρ : ∀ v ∈ ρS, Term.Closed 0 v) (q : Quant) (A B : Term) :
    ∃ B', Term.cl Γ r ρS m (.All q A B) = .All q (Term.cl Γ r ρS m A) B' := by
  simp only [Term.cl]
  rw [Ctx.δ_all, Term.instL_all _ _ hρ]
  exact Term.shiftN_all m q _ _

theorem Insts.cl (h : Insts T ps X) (hT : T.Closed 0) :
    Insts T (ps.map (Term.cl Γ r ρS m)) (Term.cl Γ r ρS m X) := by
  have h1 := h.δ Γ 0
  rw [Ctx.δ_closed _ _ _ hT] at h1
  have h2 := h1.instL hT ρS r
  rw [List.map_map] at h2
  have h3 := h2.shiftN m
  rw [List.map_map, Term.shiftN_closed hT] at h3
  exact h3

theorem Check.closeDm (hβ : Book.Closed β) (ho : Outer β Γ r ρS ρO) {sp : List Term}
    (h : Check β (Pol.dead β) (LHS.void β) sp .None Γ t T π u) (m : Nat) :
    ∃ Λ, (∀ b ∈ Λ, b.v = none) ∧
      Check β (Pol.dead β) (LHS.void β) [] .None Λ (Term.cl Γ r ρS m t) (Term.cl Γ r ρS m T)
          Uses.zero .Qnt := by
  obtain ⟨Λ, hΛ, h'⟩ := Check.closeD hβ ho h
  have h'' := Check.consN hβ (Pol.dead_weak hβ) h' (List.replicate m ⟨.None, .Qnt, none⟩) []
  rw [List.length_replicate] at h''
  refine ⟨_, ?_, h''⟩
  intro b hb
  rw [List.mem_append] at hb
  rcases hb with hb | hb
  · rw [List.mem_replicate] at hb; rw [hb.2]
  · exact hΛ b hb

-- ----------------------------------------------------------------------------
-- the pending spine of the position lemma: every argument with its typing
-- and its own position fact P
-- ----------------------------------------------------------------------------

inductive ArgsP (β : Book) (L : LHS) (Γ : Ctx) (P : Term → Term → Uses → Term → Prop) :
    Term → List Term → Term → Uses → List Term → Prop
  | nil  : ArgsP β L Γ P T [] T Uses.zero []
  | cons : Le β (Ctx.δ Γ 0 T0) (Ctx.δ Γ 0 (.All q' A B)) →
           Check β (Pol.std β) L [] (Quant.dem q' .Lone) Γ x A πx ux → P x A πx ux →
           ArgsP β L Γ P (Term.subst 0 x B) as T πs us →
           ArgsP β L Γ P T0 (x :: as) T (Uses.add πx πs) (ux :: us)

theorem ArgsP.toArgs (h : ArgsP β L Γ P T0 as T πs us) : Args β (Pol.std β) L .Lone Γ T0 as T πs us
    := by
  induction h with
  | nil => exact .nil
  | cons hc hx _ _ ih => exact .cons hc hx ih

theorem ArgsP.split (h : ArgsP β L Γ P T0 (as ++ bs) T πs us) :
    ∃ Tm πa ua πb ub, ArgsP β L Γ P T0 as Tm πa ua ∧ ArgsP β L Γ P Tm bs T πb ub ∧
      πs = Uses.add πa πb ∧ us = ua ++ ub := by
  induction as generalizing T0 πs us with
  | nil => exact ⟨T0, Uses.zero, [], πs, us, .nil, h, (Uses.zero_add πs).symm, rfl⟩
  | cons a as ih =>
    cases h with
    | cons hc hx hP hr =>
      obtain ⟨Tm, πa, ua, πb, ub, h1, h2, rfl, rfl⟩ := ih hr
      exact ⟨Tm, _, _, πb, ub, .cons hc hx hP h1, h2, (Uses.add_assoc _ _ _).symm, rfl⟩

theorem ArgsP.le_start (hβ : Book.Closed β) (h : ArgsP β L Γ P T0 as T πs us)
    (hc : Le β (Ctx.δ Γ 0 X) (Ctx.δ Γ 0 T0)) :
    ∃ T', ArgsP β L Γ P X as T' πs us ∧ Le β (Ctx.δ Γ 0 T') (Ctx.δ Γ 0 T) := by
  cases h with
  | nil => exact ⟨X, .nil, hc⟩
  | cons hc0 ha hP hr => exact ⟨_, .cons (hc.trans hβ hc0) ha hP hr, Le.refl _⟩

theorem ArgsP.step (hβ : Book.Closed β)
    (hle : Le β (Ctx.δ Γ 0 (.All qw K Bw)) (Ctx.δ Γ 0 T0))
    (h : ArgsP β L Γ P T0 (x :: as) T πs us) :
    ∃ A πx ux πs' us' B, πs = Uses.add πx πs' ∧ us = ux :: us' ∧
      Check β (Pol.std β) L [] (Quant.dem qw .Lone) Γ x A πx ux ∧ P x A πx ux ∧
      Le β (Ctx.δ Γ 0 A) (Ctx.δ Γ 0 K) ∧
      Le β (Ctx.δ Γ 0 (Term.subst 0 x Bw)) (Ctx.δ Γ 0 (Term.subst 0 x B)) ∧
      ArgsP β L Γ P (Term.subst 0 x B) as T πs' us' := by
  cases h with
  | cons hc hx hP hr =>
    rename_i q1 A1 B1 πx ux πs' us'
    have ra : Red β .strong (Ctx.δ Γ 0 (.All qw K Bw)) (.All qw (Ctx.δ Γ 0 K) (Ctx.δ Γ 1 Bw)) := by
      rw [Ctx.δ_all]; exact .refl
    have rb : Red β .strong (Ctx.δ Γ 0 (.All q1 A1 B1)) (.All q1 (Ctx.δ Γ 0 A1) (Ctx.δ Γ 1 B1)) :=
        by
      rw [Ctx.δ_all]; exact .refl
    obtain ⟨rfl, hA, hB⟩ := Le.all_inv hβ (Le.trans hβ hle hc) ra rb
    refine ⟨_, _, _, _, _, _, _root_.rfl, _root_.rfl, hx, hP, hA, ?_, hr⟩
    rw [Ctx.δ_subst Γ 0 0 _ _ (Nat.le_refl 0), Ctx.δ_subst Γ 0 0 _ _ (Nat.le_refl 0)]
    exact Le.subst hβ hB 0 _

-- the parameters: dead, and the telescope facts of E's Args.params
theorem ArgsP.params (hβ : Book.Closed β) :
    ∀ {qs : List Term} {pn : Nat} {ps0 : List Term} {Tw T0 Tm : Term} {πp : Uses} {up : List Term},
    WTele a r ps0 pn fn Tw → ArgsP β L Γ P T0 qs Tm πp up →
    Le β (Ctx.δ Γ 0 (Term.retip r' pn (pn + fn) Tw)) (Ctx.δ Γ 0 T0) → qs.length = pn →
    ∃ TS, Insts Tw qs TS ∧ FTele a r (ps0 ++ qs) fn TS ∧
      Le β (Ctx.δ Γ 0 (Term.retip r' 0 fn TS)) (Ctx.δ Γ 0 Tm) ∧ πp = Uses.zero := by
  intro qs
  induction qs with
  | nil =>
    intro pn ps0 Tw T0 Tm πp up hw h hle hlen
    cases h
    cases pn with
    | zero =>
      rw [Nat.zero_add] at hle
      exact ⟨Tw, .nil, by rw [List.append_nil]; exact hw, hle, rfl⟩
    | succ pk => simp at hlen
  | cons x qs ih =>
    intro pn ps0 Tw T0 Tm πp up hw h hle hlen
    cases pn with
    | zero => simp at hlen
    | succ pk =>
      obtain ⟨qw, K, Bw, hT, hwB, hw'⟩ := WTele.param (x := x) hw
      subst hT
      rw [show pk + 1 + fn = pk + fn + 1 by omega] at hle
      obtain ⟨A, πx, ux, πs', us', B, rfl, rfl, hx, _, _, hB, hr⟩ :=
        ArgsP.step hβ (qw := .None) (K := K) (Bw := Term.retip r' pk (pk + fn) Bw) hle h
      rw [WTele.retip_subst hwB r' 0 x] at hB
      obtain ⟨TS, hI, hF, hle', rfl⟩ := ih hw' hr hB (by simp at hlen; omega)
      refine ⟨TS, .cons hI, by simpa [List.append_assoc] using hF, hle', ?_⟩
      rw [hx.none_uses _root_.rfl, Uses.add_zero]

-- the fields: a live use in the pending fields is a live use of one field,
-- typed below the telescope's domain opened by the previous fields
theorem ArgsP.fields (hβ : Book.Closed β) :
    ∀ {xs : List Term} {fn : Nat} {ps : List Term} {TS T0 T1 : Term} {πs : Uses} {us : List Term},
    FTele a r ps fn TS → ArgsP β L Γ P T0 xs T1 πs us →
    Le β (Ctx.δ Γ 0 (Term.retip r' 0 fn TS)) (Ctx.δ Γ 0 T0) → xs.length = fn →
    ∀ (j : Nat), πs j ≠ .None →
    ∃ (k : Nat) (x : Term) (qf : Quant) (A : Term) (πx : Uses) (ux F B : Term),
      xs[k]? = some x ∧ us[k]? = some ux ∧ Insts TS (xs.take k) (.All qf F B) ∧
      Check β (Pol.std β) L [] (Quant.dem qf .Lone) Γ x A πx ux ∧ P x A πx ux ∧
      Le β (Ctx.δ Γ 0 A) (Ctx.δ Γ 0 F) ∧ πx j ≠ .None := by
  intro xs
  induction xs with
  | nil => intro fn ps TS T0 T1 πs us _ h _ _ j hj; cases h; exact absurd rfl hj
  | cons x xs ih =>
    intro fn ps TS T0 T1 πs us hF h hle hlen j hj
    cases fn with
    | zero => simp at hlen
    | succ fk =>
      obtain ⟨qf, F, Bs, hT, hFB, hF'⟩ := FTele.field (x := x) hF
      subst hT
      obtain ⟨A, πx, ux, πs', us', B, rfl, rfl, hx, hP, hAF, hB, hr⟩ :=
        ArgsP.step hβ (qw := qf) (K := F) (Bw := Term.retip r' 0 fk Bs) hle h
      rw [FTele.retip_subst hFB r' 0 x] at hB
      by_cases hxj : πx j = .None
      · have hj' : πs' j ≠ .None := fun h0 => hj (by simp [Uses.add, hxj, h0, Quant.add])
        obtain ⟨k, x', qf', A', πx', ux', F', B', hk, hu, hI, hx', hP', hAF', hj''⟩ :=
          ih hF' hr hB (by simp at hlen; omega) j hj'
        exact ⟨k + 1, x', qf', A', πx', ux', F', B',
            by simpa using hk, by simpa using hu, .cons hI, hx', hP', hAF', hj''⟩
      · exact ⟨0, x, qf, A, πx, ux, F, Bs, rfl, rfl, .nil, hx, hP, hAF, hxj⟩

theorem Insts.append (h : Insts T ps X) : ∀ {ys : List Term} {Y : Term}, Insts X ys Y → Insts T (ps
    ++ ys) Y := by
  induction h with
  | nil => intro ys Y h'; exact h'
  | cons _ ih => intro ys Y h'; exact .cons (ih h')

-- ----------------------------------------------------------------------------
-- a full constructor spine at a Dat type: every live-used field is typed
-- below a Dat domain (the walk, instantiated in the closed context)
-- ----------------------------------------------------------------------------

theorem ArgsP.ctr_dat (hok : Book.Ok β) (ho : Outer β Γ r ρS ρO) (hρS : ∀ v ∈ ρS, Term.Closed 0 v)
    (hA : Book.adt β a = some A) (hC : AdtD.ctr A c = some C) (hr0 : c ∉ r0)
    (h : ArgsP β L Γ P (Term.retip r0 A.pn (A.pn + C.fn) C.ty) as T1 πs us)
    (hlen : as.length = A.pn + C.fn) (hD : Dat β (Term.cl Γ r ρS m T1)) :
    ∀ (j : Nat), πs j ≠ .None →
    ∃ (k : Nat) (x : Term) (qf : Quant) (A' : Term) (πx : Uses) (ux : Term), as[k]? = some x ∧
        us[k]? = some ux ∧
      Check β (Pol.std β) L [] (Quant.dem qf .Lone) Γ x A' πx ux ∧ P x A' πx ux ∧
      πx j ≠ .None ∧ Dat β (Term.cl Γ r ρS m A') := by
  intro j hj
  have hβ := hok.closed
  have hΦd := Pol.dead_pre hβ
  have hshape : WTele a [] [] A.pn C.fn C.ty := hok.shape hA hC
  have hCc : C.ty.Closed 0 := (Book.Closed.adtd hβ hA).2 c C hC
  -- the closed dead spine
  have hsp := Check.apps (sp := []) (Check.ctr (sp := as ++ []) (q := .Lone) hA hC hr0) h.toArgs
  obtain ⟨Λ, hΛ, hcl⟩ := Check.closeDm hβ ho (Check.dead_pol hβ hsp.dead.void) m
  rw [Term.cl_apps (h := .Ctr a c) trivial] at hcl
  obtain ⟨T0', _, _, T1', πs', us', hh, hargs', _, _, _⟩ :=
    hcl.apps_inv hΦd (as.map (Term.cl Γ r ρS m)) (.Ctr a c) (fun _ e => Term.noConfusion e)
  obtain ⟨A2, C2, r2, hA2, hC2, _, hle0, _, _⟩ := hh.ctr_inv hΦd
  rw [hA] at hA2; cases hA2
  rw [hC] at hC2; cases hC2
  -- split both spines
  have h0 := h
  rw [← List.take_append_drop A.pn as] at h0
  obtain ⟨Tm, πa, ua, πb, ub, hPa, hPb, hπ, hus⟩ := h0.split
  have hps : (as.take A.pn).length = A.pn := by simp; omega
  have hxs : (as.drop A.pn).length = C.fn := by simp; omega
  obtain ⟨TS, hI, hFT, hle', hπa⟩ := ArgsP.params hβ hshape hPa (Le.refl _) hps
  subst hπa
  rw [hπ, Uses.zero_add] at hj
  rw [← List.take_append_drop A.pn as, List.map_append] at hargs'
  obtain ⟨Tm', _, _, _, ub', hargsP', hargsF', _, _⟩ := hargs'.split
  -- the family instance is Dat
  obtain ⟨_, hleA⟩ := Args.ftele hβ (r' := r0) (by simpa using hFT) hPb.toArgs hle' hxs
  have hDA : Dat β (Term.cl Γ r ρS m (Term.apps (.Adt a r0) (as.take A.pn))) :=
    Dat.of_le hβ (hleA.cl hβ r ρS m) hD
  rw [Term.cl_apps (h := .Adt a r0) trivial] at hDA
  obtain ⟨G', hS', hKle'⟩ := hDA.2.2.2 _ _ _ _ Red.refl hA (by rw [List.length_map, hps])
  -- the walk, in the closed context
  obtain ⟨G, hS, hD0⟩ := Book.OkK.dead hok a A c C hA hC
  have hD1 : CtrOkD β (Pol.dead β) A.pn G Λ 0 C.ty := by simpa using hD0.weaken hβ Λ
  obtain ⟨TS', hI', hFT', hle'', hD2⟩ := CtrOkD.paramsO hβ hshape hD1 hargsP' hle0
      (by rw [List.length_map, hps])
  have hKle : KLe β (Term.instGo ((as.take A.pn).map (Term.cl Γ r ρS m)) G) (.Qua .Many) :=
    KLe.trans hβ (KLe.conv (Term.instGo.conv hβ (Convs.refl _) (STele.conv hβ hS hS'))) _ hKle'
  -- the used field
  obtain ⟨k, x, qf, A', πx, ux, F, B, hk, hu, hIk, hx, hPx, hAF, hxj⟩ := ArgsP.fields hβ hFT hPb
      hle' hxs j hj
  have hua : ua.length = A.pn := by rw [hPa.toArgs.length, hps]
  refine ⟨A.pn + k, x, qf, A', πx, ux, by rw [← List.getElem?_drop]; exact hk, ?_, hx, hPx, hxj,
    Dat.of_le hβ (hAF.cl hβ r ρS m) ?_⟩
  · rw [hus, List.getElem?_append_right (by omega), hua, Nat.add_sub_cancel_left]; exact hu
  have hqf : qf ≠ .None := fun h0 => hxj (by rw [hx.none_uses (by rw [h0]; rfl)]; rfl)
  have hkl : k < (as.drop A.pn).length := (List.getElem?_eq_some_iff.mp hk).1
  have hub : ∃ u', ub'[k]? = some u' :=
    ⟨_, List.getElem?_eq_getElem (by rw [hargsF'.length, List.length_map]; exact hkl)⟩
  obtain ⟨u', hu'⟩ := hub
  obtain ⟨qf', F', B', _, hIk', _, π', hKF'⟩ := CtrOkD.fieldsO hβ (r' := r2) hFT' hD2 hargsF' hle''
    (by rw [List.length_map, hxs]) k _ u' (by rw [List.getElem?_map, hk]; rfl) hu'
  -- the two instantiated telescopes agree
  have hI1 : Insts C.ty (((as.take A.pn) ++ (as.drop A.pn).take k).map (Term.cl Γ r ρS m))
      (Term.cl Γ r ρS m (.All qf F B)) := (hI.append hIk).cl hCc
  have hI2 : Insts C.ty (((as.take A.pn) ++ (as.drop A.pn).take k).map (Term.cl Γ r ρS m)) (.All
      qf' F' B') := by
    rw [List.map_append]
    exact hI'.append (by rw [List.map_take]; exact hIk')
  have heq := Insts.unique hI1 hI2
  obtain ⟨B'', hcl⟩ := Term.cl_all (Γ := Γ) (r := r) (m := m) hρS qf F B
  rw [hcl] at heq
  cases heq
  -- the field's domain is Data-kinded
  cases qf with
  | None => exact absurd rfl hqf
  | Lone =>
    simp only [if_true] at hKF'
    have hK2 : Check β (Pol.dead β) (LHS.void β) [] .None Λ (Term.cl Γ r ρS m F) (.Typ (.Qua
        .Many)) π' .Qnt :=
      hKF'.cnv (by rw [Ctx.δ_rigid Λ hΛ, Ctx.δ_rigid Λ hΛ]; exact Pol.dead_kind hβ _ hKle)
    exact Dat.of_kind hok hK2 hΛ
  | Many =>
    simp only [reduceCtorEq, if_false] at hKF'
    exact Dat.of_kind hok hKF' hΛ

-- a rigid non-variable, non-constructor head is never pure
theorem PureD.rigid_absurd (hh : t.IsHead) (hnv : ∀ i, t ≠ .Var i) (hnc : ∀ a c, t ≠ .Ctr a c) (Γ :
    Ctx)
    (xs : List Term) (hne : e ≠ .Qnt) (h : PureD β βe ρ D (Ctx.δ Γ 0 (Term.apps t xs)) e) : False
        := by
  rw [Ctx.δ_apps] at h
  obtain ⟨_, h2, _⟩ := Ctx.δ_head Γ 0 hh hnv hnc
  rcases h.shape with ⟨i, e1⟩ | e2 | ⟨a, c, _, _, src, _, _, _, _, e1, _, _⟩
  · exact Term.apps_ne_var h2 _ i e1
  · exact hne e2
  · exact DomS.rigid_side hh hnv hnc Γ _ a c src e1

-- ----------------------------------------------------------------------------
-- THE POSITION LEMMA: in a pure value at a Dat type, every live-used binder
-- has a Dat type (its closed instance, under any shift)
-- ----------------------------------------------------------------------------

theorem Check.pure_dat (hok : Book.Ok β) :
    ∀ {L : LHS} {sp : List Term} {q : Quant} {Γ : Ctx} {t T : Term} {π : Uses} {u : Term},
    Check β (Pol.std β) L sp q Γ t T π u → q = .Lone →
    ∀ {r : Nat} {ρS ρO ρ : List Term} {D m : Nat} {βe : Book} {ρi : List (Option Term)},
    Outer β Γ r ρS ρO → (∀ v ∈ ρS, Term.Closed 0 v) → Ctx.LetsFull β Γ → Env.Closed ρi →
    ∀ (as : List Term) {T1 : Term} {πs : Uses} {us : List Term},
    ArgsP β L Γ (fun x A πx ux => Dat β (Term.cl Γ r ρS m A) →
        PureD β βe ρ D (Ctx.δ Γ 0 x) (Term.inst 0 ρi ux) →
        ∀ (j : Nat) b, πx j ≠ .None → Ctx.get Γ j = some b → Dat β (Term.cl Γ r ρS m b.T)) T as T1
            πs us →
    PureD β βe ρ D (Ctx.δ Γ 0 (Term.apps t as)) (Term.apps (Term.inst 0 ρi u) (us.map (Term.inst 0
        ρi))) →
    Dat β (Term.cl Γ r ρS m T1) →
    ∀ (j : Nat) b, Uses.add π πs j ≠ .None → Ctx.get Γ j = some b → Dat β (Term.cl Γ r ρS m b.T) :=
        by
  have hβ := hok.closed
  have hΦ := Pol.std_pre hβ
  have hL : (Quant.Lone : Quant) ≠ .None := by decide
  intro L sp q Γ t T π u h
  induction h with
  | var hg =>
    intro hq r ρS ρO ρ D m βe ρi ho hρS hLF hρi as T1 πs us hargs hpure hD j b' hj hb
    rename_i Γ i b L sp q
    subst hq
    simp only [Term.era_live hL] at hpure
    cases as with
    | nil =>
      cases hargs
      have hji : j = i := by
        by_cases hji : j = i
        · exact hji
        · exact absurd (by simp [Uses.add, Uses.one, Uses.zero, hji, Quant.add]) hj
      subst hji
      rw [hg] at hb; cases hb
      exact hD
    | cons a as' =>
      cases hargs
      simp only [List.map_cons] at hpure
      rw [Ctx.δ_apps] at hpure
      rcases hpure.shape with ⟨i', e1⟩ | e2 | ⟨a', c', A', C', src, era, hA', hC', hlen, e1, _, _⟩
      · exact absurd e1 (Term.apps_cons_ne_var _ _ _ _)
      · exact absurd e2 (Term.apps_ne_qnt (x := .App _ _) (by simp) _)
      · have hX : Term.CtrsFull β 0 (Ctx.δ Γ 0 (.Var i)) := Term.CtrsFull.δ Γ hLF 0 trivial
        have e := congrArg Term.spine e1
        rw [Term.spine_apps_of, Term.spine_apps (by trivial)] at e
        obtain ⟨e2, e3⟩ := Prod.mk.inj e
        have hXe : Ctx.δ Γ 0 (.Var i) = Term.apps (.Ctr a' c') (Term.spine (Ctx.δ Γ 0 (.Var i))).2
            := by
          rw [← e2]; exact (Term.apps_spine _).symm
        rw [hXe] at hX
        have h1 := hX.apps_ctr hA' hC'
        have h2 := congrArg List.length e3
        simp at h2
        omega
  | @ctr a A c C r0 L sp q Γ hA hC hr =>
    intro hq r ρS ρO ρ D m βe ρi ho hρS hLF hρi as T1 πs us hargs hpure hD j b hj hb
    subst hq
    simp only [Term.era_live hL, Term.inst_closed 0 _ (t := .Ctr a c) trivial] at hpure
    rw [Ctx.δ_apps, Ctx.δ_closed Γ 0 (.Ctr a c) trivial] at hpure
    rcases hpure.shape with ⟨i, e1⟩ | e2 | ⟨a', c', A', C', src, era, hA', hC', hlen, e1, e2, hf⟩
    · exact absurd e1 (Term.apps_ne_var (fun _ h => Term.noConfusion h) _ i)
    · exact absurd e2 (Term.apps_ne_qnt (fun h => Term.noConfusion h) _)
    · obtain ⟨e3, e4⟩ := Term.apps_head_inv (by trivial) (by trivial) e1
      cases e3
      rw [hA] at hA'; cases hA'
      rw [hC] at hC'; cases hC'
      obtain ⟨_, e6⟩ := Term.apps_head_inv (by trivial) (by trivial) e2
      have hlen' : as.length = A.pn + C.fn := by rw [← hlen, ← e4, List.length_map]
      rw [Uses.zero_add] at hj
      obtain ⟨k, x, qf, A', πx, ux, hk, hu, hx, hPx, hxj, hDA⟩ :=
        ArgsP.ctr_dat hok ho hρS hA hC hr hargs hlen' hD j hj
      have hpx : PureD β βe ρ D (Ctx.δ Γ 0 x) (Term.inst 0 ρi ux) :=
        hf k _ _ (by rw [← e4, List.getElem?_map, hk]; rfl)
            (by rw [← e6, List.getElem?_map, hu]; rfl)
      exact hPx hDA hpx j b hxj hb
  | app hf hx ihf ihx =>
    intro hq r ρS ρO ρ D m βe ρi ho hρS hLF hρi as T1 πs us hargs hpure hD j b hj hb
    rename_i L x sp q Γ f q' A B πf uf πx ux
    subst hq
    simp only [Term.era_live hL, Term.inst_app] at hpure
    have hfact : Dat β (Term.cl Γ r ρS m A) → PureD β βe ρ D (Ctx.δ Γ 0 x) (Term.inst 0 ρi ux) →
        ∀ (j : Nat) b, πx j ≠ .None → Ctx.get Γ j = some b → Dat β (Term.cl Γ r ρS m b.T) := by
      intro hDA hpx j' b' hj' hb'
      by_cases hq' : q' = .None
      · exact absurd (by rw [hx.none_uses (by rw [hq']; rfl)]; exact _root_.rfl) hj'
      · rw [Quant.dem_live hq'] at hx ihx
        exact ihx _root_.rfl ho hρS hLF hρi [] .nil hpx hDA j' b'
            (by rw [Uses.add_zero]; exact hj') hb'
    have hargs' : ArgsP β L Γ _ (.All q' A B) (x :: as) T1 (Uses.add πx πs) (ux :: us) :=
      .cons (Le.refl _) hx hfact hargs
    refine ihf _root_.rfl ho hρS hLF hρi (x :: as) hargs' hpure hD j b ?_ hb
    rw [← Uses.add_assoc]; exact hj
  | appLam hc _ ih =>
    intro hq r ρS ρO ρ D m βe ρi ho hρS hLF hρi as T1 πs us hargs hpure hD j b hj hb
    rename_i a0 L0 sp0 q0 Γ0 f0 T0 π0 u0 hprem
    subst hq
    cases as with
    | nil =>
      cases hargs
      have hpure' : PureD β βe ρ D (Ctx.δ Γ0 0 (Term.apps (.Lam f0) [a0])) (Term.inst 0 ρi u0) :=
          hpure
      by_cases hne : Term.inst 0 ρi u0 = .Qnt
      · refine ih _root_.rfl (ρ := ρ) (D := D) (βe := βe) ho hρS hLF hρi [] .nil ?_ hD j b hj hb
        show PureD β βe ρ D _ (Term.inst 0 ρi u0)
        rw [hne]; exact .qnt
      · exact (PureD.rigid_absurd (t := .Lam f0) (by trivial) (by simp) (by simp) Γ0 [a0] hne
          hpure').elim
    | cons a as' =>
      cases hargs
      simp only [List.map_cons] at hpure
      exact (PureD.rigid_absurd (t := .Lam f0) (by trivial) (by simp) (by simp) Γ0 (a0 :: a :: as')
        (Term.apps_ne_qnt (x := .App _ _) (by simp) _) hpure).elim
  | cnv _ hle ih =>
    intro hq r ρS ρO ρ D m βe ρi ho hρS hLF hρi as T1 πs us hargs hpure hD j b hj hb
    obtain ⟨T', hargs', hle'⟩ := hargs.le_start hβ hle
    exact ih hq ho hρS hLF hρi as hargs' hpure (Dat.of_le hβ (hle'.cl hβ r ρS m) hD) j b hj hb
  | _ =>
    intro hq r ρS ρO ρ D m βe ρi ho hρS hLF hρi as T1 πs us hargs hpure hD j b hj hb
    subst hq
    try simp only [Term.era_live hL] at hpure
    cases as with
    | nil =>
      cases hargs
      first
        | exact absurd _root_.rfl hj
        | exact (PureD.rigid_absurd (by trivial) (by simp) (by simp) _ [] (by
            simp [Term.inst_min, Term.inst_lam 0 ρi hρi, Term.inst_let 0 ρi hρi, Term.inst_rwt,
              Term.inst_mat, Term.apps]) hpure).elim
    | cons a as' =>
      cases hargs
      simp only [List.map_cons] at hpure
      exact (PureD.rigid_absurd (by trivial) (by simp) (by simp) _ (a :: as')
        (Term.apps_ne_qnt (x := .App _ _) (by simp) _) hpure).elim

theorem Term.cl_lam (hρ : ∀ v ∈ ρS, Term.Closed 0 v) (q : Quant) (A t : Term) :
    Term.cl (⟨q, A, none⟩ :: Γ) (r + 1) ρS n (Term.shift 0 t) = Term.cl Γ r ρS (n + 1) t := by
  simp only [Term.cl]
  rw [Ctx.δ_cons_rig, Ctx.δ_shift Γ 0 0 t (Nat.le_refl 0), Term.instL_shift r _ hρ,
      Term.shiftN_shift0]

theorem Term.cl_let (q : Quant) (A v t : Term) :
    Term.cl (⟨q, A, some v⟩ :: Γ) r ρS n (Term.shift 0 t) = Term.cl Γ r ρS n t := by
  simp only [Term.cl]; rw [Ctx.δ_cons_let, Term.subst_shift]

theorem Ctx.LetsFull.of_rigid : ∀ (Γ : Ctx), (∀ b ∈ Γ, b.v = none) → Ctx.LetsFull β Γ := by
  intro Γ
  induction Γ with
  | nil => intro _; trivial
  | cons b Γ ih =>
    intro h
    exact ⟨fun v hv => (by rw [h b (by simp)] at hv; cases hv), ih (fun b hb => h b (by simp [hb]))⟩

-- a charge in the budget is a charge of a used substituted entry
theorem EnvO.budget_mem : ∀ (env : List Ent) (π : Uses) (y : Charge), y ∈ EnvO.budget env π →
    ∃ (j : Nat) (e : Ent), env[j]? = some e ∧ e.sub = true ∧ π j ≠ .None ∧ y ∈ e.chg := by
  intro env
  induction env with
  | nil => intro π y h; simp [EnvO.budget] at h
  | cons e env ih =>
    intro π y h
    simp only [EnvO.budget, List.mem_append] at h
    rcases h with h | h
    · split at h
      · rename_i hc; exact ⟨0, e, rfl, by simpa using hc.1, hc.2, h⟩
      · simp at h
    · obtain ⟨j, e', hj, hs, hπ, hy⟩ := ih (Uses.tail π) y h
      exact ⟨j + 1, e', by simpa using hj, hs, hπ, hy⟩

-- ----------------------------------------------------------------------------
-- the leaf state with lets: the equation with every column bound; a
-- context whose binders each have an entry (the outer ones the walk's,
-- substituted; the inner ones the leaf's lambdas and lets); the columns
-- expanded by δ and pinned; and, while no leaf lambda or live let is in
-- scope, the closing environment
-- ----------------------------------------------------------------------------

def EntOk (βe : Book) (k : Nat) (pins : Pins) (e : Ent) : Prop :=
  e.src.Closed 0 ∧ e.era.Closed 0 ∧
    (e.sub = true → Deep βe e.era ∧ ∃ M Y, CG βe e.era M ∧ M.Perm (Y ++ e.chg) ∧ ∀ y ∈ Y, Charge.lt
        y (k, pins))

structure LeafSt2 (β βe : Book) (k : Nat) (d : DefD) (L : LHS) (Γ : Ctx) (r : Nat) (env : List Ent)
    (ρO : List Term) (pins : Pins) (ρS : List Term) : Prop where
  hk   : L.k = k
  hn   : L.n = 0
  hqs  : L.qs = d.qs
  len  : Γ.length = env.length
  ρc   : ∀ v ∈ ρO, v.Closed 0
  ents : ∀ e ∈ env, EntOk βe k pins e
  dom  : ∀ (j : Nat) e b, env[j]? = some e → Ctx.get Γ j = some b → e.sub = true →
           (DomS β βe ρO r (Ctx.δ Γ 0 (.Var j)) e.era ∨ (e.era ≠ .Qnt ∧ NoV β r (Ctx.δ Γ 0 (.Var
               j)))) ∧
           (b.q ≠ .None → e.era = .Qnt → ∀ a c xs, Ctx.δ Γ 0 (.Var j) ≠ Term.apps (.Ctr a c) xs)
  kept : ∀ (j : Nat) e, env[j]? = some e → e.sub = false →
           (∃ i, Ctx.δ Γ 0 (.Var j) = .Var i ∧ i < r) ∨ NoV β r (Ctx.δ Γ 0 (.Var j))
  hd   : (Term.spine L.t).1 = .Ref k
  cols : (Term.spine L.t).2.length = d.n
  pl   : pins.length = d.n
  vg   : ∀ (i : Nat) c, (Term.spine L.t).2[i]? = some c →
           Term.VarsGe r (Ctx.δ Γ 0 c) ∧ (Term.instL r ρO (Ctx.δ Γ 0 c)).Closed 0
  pin  : ∀ (i : Nat) c n, (Term.spine L.t).2[i]? = some c → pins[i]? = some (some n) →
           Term.csize βe (Term.instL r ρO (Ctx.δ Γ 0 c)) = n
  ρSc  : ∀ v ∈ ρS, v.Closed 0
  outer : Outer β Γ r ρS ρO
  full : Ctx.LetsFull β Γ
  dat  : ∀ (j : Nat) e b, env[j]? = some e → Ctx.get Γ j = some b → e.sub = true → e.chg ≠ [] →
           b.q ≠ .None → ∀ n, ¬ Dat β (Term.cl Γ r ρS n b.T)

theorem LeafSt2.ρ_closed (st : LeafSt2 β βe k d L Γ r env ρO pins ρS) : Env.Closed (EnvO.ρ env) :=
    by
  intro v hv
  simp only [EnvO.ρ, List.mem_map] at hv
  obtain ⟨e, he, hev⟩ := hv
  simp only [Ent.ρ] at hev
  split at hev
  · cases hev; exact (st.ents e he).2.1
  · cases hev

-- under a leaf lambda: a kept rigid entry; every expanded source shifts
theorem LeafSt2.lam (st : LeafSt2 β βe k d L Γ r env ρO pins ρS) (q : Quant) (A : Term) :
    LeafSt2 β βe k d L.shift (⟨q, A, none⟩ :: Γ) (r + 1) (⟨.Qnt, .Qnt, [], false⟩ :: env) ρO pins
        ρS := by
  have hsp := Term.spine_shift (d := 0) st.hd (by trivial) rfl
  refine ⟨st.hk, st.hn, st.hqs,
      by simp [st.len], st.ρc, ?_, ?_, ?_, ?_, ?_, st.pl, ?_, ?_, st.ρSc,
    Outer.lam st.outer q A, ⟨fun _ h => by simp at h, st.full⟩, ?_⟩
  · intro e he; rw [List.mem_cons] at he
    rcases he with rfl | he
    · exact ⟨trivial, trivial, fun h => by cases h⟩
    · exact st.ents e he
  · intro j e b he hb hs
    cases j with
    | zero => simp at he; subst he; cases hs
    | succ j =>
      rw [Ctx.get_succ] at hb
      obtain ⟨b', hb', rfl⟩ := Option.map_eq_some_iff.mp hb
      obtain ⟨h1, h2⟩ := st.dom j e b' (by simpa using he) hb' hs
      rw [Ctx.δ_cons_rig, Ctx.δ_var_succ_rig]
      refine ⟨h1.elim (fun h => .inl h.shift) (fun h => .inr ⟨h.1, h.2.shift⟩), ?_⟩
      intro hq hqe a c xs h
      obtain ⟨ys, e'⟩ := Term.shift_eq_ctr_apps h
      exact h2 hq hqe a c ys e'
  · intro j e he hs
    cases j with
    | zero => left; exact ⟨0, by rw [Ctx.δ_cons_rig, Ctx.δ_var_lt Γ 1 0 (by omega)], by omega⟩
    | succ j =>
      rw [Ctx.δ_cons_rig, Ctx.δ_var_succ_rig]
      rcases st.kept j e (by simpa using he) hs with ⟨i, hi, hlt⟩ | hn
      · left; exact ⟨i + 1, by rw [hi]; simp [Term.shift], by omega⟩
      · right; exact hn.shift
  · show (Term.spine (Term.shift 0 L.t)).1 = _; rw [hsp]
  · show (Term.spine (Term.shift 0 L.t)).2.length = _; rw [hsp]; simpa using st.cols
  · intro i c' hc'
    rw [show (Term.spine L.shift.t).2 = (Term.spine L.t).2.map (Term.shift 0) from congrArg
        Prod.snd hsp,
      List.getElem?_map] at hc'
    obtain ⟨c, hc, rfl⟩ := Option.map_eq_some_iff.mp hc'
    obtain ⟨h1, h2⟩ := st.vg i c hc
    rw [Ctx.δ_cons_rig, Ctx.δ_shift Γ 0 0 c (Nat.le_refl 0), Term.instL_shift r _ st.ρc,
      Term.shift_closed _ 0 0 h2 (Nat.le_refl 0)]
    exact ⟨h1.shift, h2⟩
  · intro i c' n hc' hp
    rw [show (Term.spine L.shift.t).2 = (Term.spine L.t).2.map (Term.shift 0) from congrArg
        Prod.snd hsp,
      List.getElem?_map] at hc'
    obtain ⟨c, hc, rfl⟩ := Option.map_eq_some_iff.mp hc'
    obtain ⟨_, h2⟩ := st.vg i c hc
    rw [Ctx.δ_cons_rig, Ctx.δ_shift Γ 0 0 c (Nat.le_refl 0), Term.instL_shift r _ st.ρc,
      Term.shift_closed _ 0 0 h2 (Nat.le_refl 0)]
    exact st.pin i c n hc hp
  · intro j e b he hb hs hc hq n
    cases j with
    | zero => simp at he; subst he; cases hs
    | succ j =>
      rw [Ctx.get_succ] at hb
      obtain ⟨b', hb', rfl⟩ := Option.map_eq_some_iff.mp hb
      show ¬ Dat β (Term.cl _ _ _ n (Term.shift 0 b'.T))
      rw [Term.cl_lam st.ρSc]
      exact st.dat j e b' (by simpa using he) hb' hs hc (by simpa [Bind.shift] using hq) (n + 1)

-- ----------------------------------------------------------------------------
-- entries and environments: small facts
-- ----------------------------------------------------------------------------

theorem Ent.ρ_true {e : Ent} (hs : e.sub = true) : e.ρ = some e.era := by simp [Ent.ρ, hs]

theorem Ent.ρ_false {e : Ent} (hs : e.sub = false) : e.ρ = none := by simp [Ent.ρ, hs]

theorem EnvO.ρ_get (env : List Ent) (i : Nat) : (EnvO.ρ env)[i]? = (env[i]?).map Ent.ρ := by
  simp [EnvO.ρ]

theorem EnvO.ρ_allsub : ∀ (env : List Ent), (∀ e ∈ env, e.sub = true) →
    EnvO.ρ env = (env.map Ent.era).map some := by
  intro env
  induction env with
  | nil => intro _; rfl
  | cons e env ih =>
    intro h
    simp only [EnvO.ρ_cons, List.map_cons]
    rw [Ent.ρ_true (h e (by simp)), ← ih (fun e' he' => h e' (by simp [he']))]

theorem Quant.le_many_eq (h : Quant.le .Many q) : q = .Many := by cases q <;> simp_all [Quant.le]

-- the composition at an entry with pending arguments: structural when every
-- pending argument is, else verdict-free through the pending field
theorem DomS.apps' (h : DomS β βe ρ D x e) (hq : e = .Qnt → ∀ a c xs, x ≠ Term.apps (.Ctr a c) xs)
    (xs es : List Term) (hl : es.length = xs.length)
    (hs : ∀ (i : Nat) x' e', xs[i]? = some x' → es[i]? = some e' →
      DomS β βe ρ D x' e' ∨ (e' ≠ .Qnt ∧ NoV β D x')) :
    DomS β βe ρ D (Term.apps x xs) (Term.apps e es) ∨
      (Term.apps e es ≠ .Qnt ∧ NoV β D (Term.apps x xs)) := by
  by_cases hall : ∀ (i : Nat) x' e', xs[i]? = some x' → es[i]? = some e' → DomS β βe ρ D x' e'
  · exact .inl (h.apps hq xs es hl hall)
  · obtain ⟨i, x', e', hx, he, hnd⟩ : ∃ i x' e', xs[i]? = some x' ∧ es[i]? = some e' ∧ ¬ DomS β βe
      ρ D x' e' :=
      Classical.byContradiction fun hcon =>
        hall fun i x' e' hx he => Classical.byContradiction fun hn => hcon ⟨i, x', e', hx, he, hn⟩
    obtain ⟨_, hn⟩ := (hs i x' e' hx he).resolve_left hnd
    have hxs : xs ≠ [] := fun h0 => by subst h0; simp at hx
    have hes : es ≠ [] := fun h0 => by subst h0; simp at he
    right
    refine ⟨?_, ?_⟩
    · cases es with
      | nil => exact absurd rfl hes
      | cons e0 es =>
        intro h0
        exact absurd (congrArg Term.spine h0) (by rw [Term.spine_apps_of]; simp [Term.spine])
    · cases xs with
      | nil => exact absurd rfl hxs
      | cons x0 xs =>
      cases h with
      | nov hnv hnc =>
        exact NoV.of_nov (Term.apps_cons_ne_var _ _ _) (Term.apps_ne_ctr_apps hnc _)
      | var _ =>
        exact NoV.of_nov (Term.apps_cons_ne_var _ _ _) (Term.apps_ne_ctr_apps (Term.var_ne_ctr_apps
            _) _)
      | varO _ _ _ _ =>
        exact NoV.of_nov (Term.apps_cons_ne_var _ _ _) (Term.apps_ne_ctr_apps (Term.var_ne_ctr_apps
            _) _)
      | qnt => exact NoV.of_nov (Term.apps_cons_ne_var _ _ _) (Term.apps_ne_ctr_apps (hq rfl) _)
      | @ctr a A c C era src hk hC hlen hpn hpar hf =>
        rw [← Term.apps_append]
        exact NoV.ctr_field hk hC (i := src.length + i) (by omega)
          (by simp; exact (List.getElem?_eq_some_iff.mp hx).1)
          (by rw [List.getElem?_append_right (by omega), Nat.add_sub_cancel_left]; exact hx) hn

-- ----------------------------------------------------------------------------
-- the leaf state under a let
-- ----------------------------------------------------------------------------

theorem LeafSt2.let {πv' : Uses} {uv' : Term} (st : LeafSt2 β βe k d L Γ r env ρO pins ρS) (qb :
    Quant) (A v : Term) (e : Ent)
    (hsrc : e.src.Closed 0) (hera : e.era.Closed 0)
    (hsub : e.sub = true → Deep βe e.era ∧
      (∃ M Y, CG βe e.era M ∧ M.Perm (Y ++ e.chg) ∧ ∀ y ∈ Y, Charge.lt y (k, pins)) ∧
      (DomS β βe ρO r (Ctx.δ Γ 0 v) e.era ∨ (e.era ≠ .Qnt ∧ NoV β r (Ctx.δ Γ 0 v))) ∧
      (qb ≠ .None → e.era = .Qnt → ∀ a c xs, Ctx.δ Γ 0 v ≠ Term.apps (.Ctr a c) xs))
    (hkept : e.sub = false → NoV β r (Ctx.δ Γ 0 v))
    (hvd : Check β (Pol.dead β) (LHS.void β) [] .None Γ v A πv' uv') (hvf : Term.CtrsFull β 0 v)
    (hdat : e.sub = true → e.chg ≠ [] → qb ≠ .None → ∀ n, ¬ Dat β (Term.cl Γ r ρS n A)) :
    LeafSt2 β βe k d L.shift (⟨qb, A, some v⟩ :: Γ) r (e :: env) ρO pins ρS := by
  have hsp := Term.spine_shift (d := 0) st.hd (by trivial) rfl
  refine ⟨st.hk, st.hn, st.hqs,
      by simp [st.len], st.ρc, ?_, ?_, ?_, ?_, ?_, st.pl, ?_, ?_, st.ρSc,
    Outer.let st.outer qb A v hvd, ⟨fun v' hv' => by cases hv'; exact hvf, st.full⟩, ?_⟩
  · intro e' he; rw [List.mem_cons] at he
    rcases he with rfl | he
    · exact ⟨hsrc, hera, fun hs => ⟨(hsub hs).1, (hsub hs).2.1⟩⟩
    · exact st.ents e' he
  · intro j e' b he hb hs
    cases j with
    | zero =>
      simp only [List.getElem?_cons_zero, Option.some.injEq] at he; subst he
      simp only [Ctx.get, Option.some.injEq] at hb; subst hb
      rw [Ctx.δ_cons_let, Term.subst0_var_zero]
      refine ⟨(hsub hs).2.2.1, fun hq => (hsub hs).2.2.2 (by simpa [Bind.shift] using hq)⟩
    | succ j =>
      rw [Ctx.get_succ] at hb
      obtain ⟨b', hb', rfl⟩ := Option.map_eq_some_iff.mp hb
      rw [Ctx.δ_cons_let, Term.subst0_var_succ]
      have := st.dom j e' b' (by simpa using he) hb' hs
      exact ⟨this.1, fun hq => this.2 (by simpa [Bind.shift] using hq)⟩
  · intro j e' he hs
    cases j with
    | zero => simp at he; subst he; right; rw [Ctx.δ_cons_let, Term.subst0_var_zero]; exact hkept hs
    | succ j => rw [Ctx.δ_cons_let, Term.subst0_var_succ]; exact st.kept j e' (by simpa using he) hs
  · show (Term.spine (Term.shift 0 L.t)).1 = _; rw [hsp]
  · show (Term.spine (Term.shift 0 L.t)).2.length = _; rw [hsp]; simpa using st.cols
  · intro i c' hc'
    rw [show (Term.spine L.shift.t).2 = (Term.spine L.t).2.map (Term.shift 0) from congrArg
        Prod.snd hsp,
      List.getElem?_map] at hc'
    obtain ⟨c, hc, rfl⟩ := Option.map_eq_some_iff.mp hc'
    rw [Ctx.δ_cons_let, Term.subst_shift]
    exact st.vg i c hc
  · intro i c' n hc' hp
    rw [show (Term.spine L.shift.t).2 = (Term.spine L.t).2.map (Term.shift 0) from congrArg
        Prod.snd hsp,
      List.getElem?_map] at hc'
    obtain ⟨c, hc, rfl⟩ := Option.map_eq_some_iff.mp hc'
    rw [Ctx.δ_cons_let, Term.subst_shift]
    exact st.pin i c n hc hp
  · intro j e' b he hb hs hc hq n
    cases j with
    | zero =>
      simp only [List.getElem?_cons_zero, Option.some.injEq] at he; subst he
      simp only [Ctx.get, Option.some.injEq] at hb; subst hb
      show ¬ Dat β (Term.cl _ _ _ n (Term.shift 0 A))
      rw [Term.cl_let]
      exact hdat hs hc (by simpa [Bind.shift] using hq) n
    | succ j =>
      rw [Ctx.get_succ] at hb
      obtain ⟨b', hb', rfl⟩ := Option.map_eq_some_iff.mp hb
      show ¬ Dat β (Term.cl _ _ _ n (Term.shift 0 b'.T))
      rw [Term.cl_let]
      exact st.dat j e' b' (by simpa using he) hb' hs hc (by simpa [Bind.shift] using hq) n

-- ----------------------------------------------------------------------------
-- the pending erased spine and the goal, with lets
-- ----------------------------------------------------------------------------

def EsF2 (β βe : Book) (ρO : List Term) (r k : Nat) (pins : Pins) (env : List Ent) (Γ : Ctx) :
    List (Term × Term × Uses) → Prop
  | [] => True
  | e :: es => (∃ M, CG βe (Term.inst 0 (EnvO.ρ env) e.2.1) M ∧ PricedO k pins env e.2.2 M) ∧
      (DomS β βe ρO r (Ctx.δ Γ 0 e.1) (Term.inst 0 (EnvO.ρ env) e.2.1) ∨
        (Term.inst 0 (EnvO.ρ env) e.2.1 ≠ .Qnt ∧ NoV β r (Ctx.δ Γ 0 e.1))) ∧
      EsF2 β βe ρO r k pins env Γ es

theorem EsF2.priced : ∀ (es : List (Term × Term × Uses)), EsF2 β βe ρO r k pins env Γ es →
    EnvO.Aff env (esUses es) →
    ∃ Ms, CGs βe (es.map (fun e => Term.inst 0 (EnvO.ρ env) e.2.1)) Ms ∧ PricedO k pins env (esUses
        es) Ms := by
  intro es
  induction es with
  | nil => intro _ _; exact ⟨[], .nil, PricedO.nil⟩
  | cons e es ih =>
    intro h haff
    obtain ⟨⟨M, hM, hp⟩, _, hes⟩ := h
    obtain ⟨Ms, hMs, hps⟩ := ih hes haff.add_r
    exact ⟨M ++ Ms, .cons hM hMs, hp.append hps haff⟩

theorem EsF2.dom (hE : Book.Era β 0 β βe) (hρ : ∀ v ∈ ρO, Term.Closed 0 v) :
    ∀ (es : List (Term × Term × Uses)), EsF2 β βe ρO r k pins env Γ es →
    ∀ (i : Nat) x e, (es.map Prod.fst)[i]? = some x →
    (es.map (fun e => Term.inst 0 (EnvO.ρ env) e.2.1))[i]? = some e → DomP β βe ρO r (Ctx.δ Γ 0 x)
        e := by
  intro es
  induction es with
  | nil => intro _ i x e h; simp at h
  | cons e0 es ih =>
    intro h i x e hx he
    obtain ⟨_, hd, hes⟩ := h
    cases i with
    | zero =>
      simp at hx he; subst hx he
      exact hd.elim (fun h => h.dom hE hρ) (fun h => h.2.dom _)
    | succ i => exact ih hes i x e (by simpa using hx) (by simpa using he)

theorem EsF2.facts : ∀ (es : List (Term × Term × Uses)), EsF2 β βe ρO r k pins env Γ es →
    ∀ (i : Nat) x e, ((es.map Prod.fst).map (Ctx.δ Γ 0))[i]? = some x →
    (es.map (fun e => Term.inst 0 (EnvO.ρ env) e.2.1))[i]? = some e →
    DomS β βe ρO r x e ∨ (e ≠ .Qnt ∧ NoV β r x) := by
  intro es
  induction es with
  | nil => intro _ i x e h; simp at h
  | cons e0 es ih =>
    intro h i x e hx he
    obtain ⟨_, hd, hes⟩ := h
    cases i with
    | zero => simp at hx he; subst hx he; exact hd
    | succ i => exact ih hes i x e (by simpa using hx) (by simpa using he)

def LeafGoal2 (β βe : Book) (k : Nat) (pins : Pins) (ρO : List Term) (r : Nat) (env : List Ent) (Γ
    : Ctx)
    (t u : Term) (π : Uses) (es : List (Term × Term × Uses)) : Prop :=
  (∃ M, CG βe (Term.apps (Term.inst 0 (EnvO.ρ env) u) (es.map (fun e => Term.inst 0 (EnvO.ρ env)
      e.2.1))) M ∧
    PricedO k pins env (Uses.add π (esUses es)) M) ∧
  (DomS β βe ρO r (Ctx.δ Γ 0 (Term.apps t (es.map Prod.fst)))
      (Term.apps (Term.inst 0 (EnvO.ρ env) u) (es.map (fun e => Term.inst 0 (EnvO.ρ env) e.2.1))) ∨
    (Term.apps (Term.inst 0 (EnvO.ρ env) u) (es.map (fun e => Term.inst 0 (EnvO.ρ env) e.2.1)) ≠
        .Qnt ∧
      NoV β r (Ctx.δ Γ 0 (Term.apps t (es.map Prod.fst))))) ∧
  (Term.apps (Term.inst 0 (EnvO.ρ env) u) (es.map (fun e => Term.inst 0 (EnvO.ρ env) e.2.1)) = .Qnt
      →
    ∀ a c xs, Ctx.δ Γ 0 (Term.apps t (es.map Prod.fst)) ≠ Term.apps (.Ctr a c) xs)

theorem LeafGoal2.head (hM : CG βe (Term.inst 0 (EnvO.ρ env) u) M) (hp : PricedO k pins env π M)
    (hes : EsF2 β βe ρO r k pins env Γ es) (haff : EnvO.Aff env (Uses.add π (esUses es)))
    (hdom : DomS β βe ρO r (Ctx.δ Γ 0 (Term.apps t (es.map Prod.fst)))
        (Term.apps (Term.inst 0 (EnvO.ρ env) u) (es.map (fun e => Term.inst 0 (EnvO.ρ env) e.2.1)))
            ∨
      (Term.apps (Term.inst 0 (EnvO.ρ env) u) (es.map (fun e => Term.inst 0 (EnvO.ρ env) e.2.1)) ≠
          .Qnt ∧
        NoV β r (Ctx.δ Γ 0 (Term.apps t (es.map Prod.fst)))))
    (hq : Term.apps (Term.inst 0 (EnvO.ρ env) u) (es.map (fun e => Term.inst 0 (EnvO.ρ env) e.2.1))
        = .Qnt →
      ∀ a c xs, Ctx.δ Γ 0 (Term.apps t (es.map Prod.fst)) ≠ Term.apps (.Ctr a c) xs) :
    LeafGoal2 β βe k pins ρO r env Γ t u π es :=
  let ⟨Ms, hMs, hps⟩ := EsF2.priced es hes haff.add_r
  ⟨⟨M ++ Ms, CG.apps hM hMs, hp.append hps haff⟩, hdom, hq⟩

-- a rigid non-constructor head (the source's) is no verdict's side
theorem LeafGoal2.rigid (hM : CG βe (Term.inst 0 (EnvO.ρ env) u) M) (hp : PricedO k pins env π M)
    (hes : EsF2 β βe ρO r k pins env Γ es) (haff : EnvO.Aff env (Uses.add π (esUses es)))
    (hh : t.IsHead) (hnv : ∀ i, t ≠ .Var i) (hnc : ∀ a c, t ≠ .Ctr a c) :
    LeafGoal2 β βe k pins ρO r env Γ t u π es := by
  refine LeafGoal2.head hM hp hes haff ?_ ?_
  · rw [Ctx.δ_apps]; exact .inl (DomS.rigid_head hh hnv hnc Γ _ _)
  · intro _ a c xs h
    rw [Ctx.δ_apps] at h
    obtain ⟨h1, h2, h3⟩ := Ctx.δ_head Γ 0 hh hnv hnc
    exact Term.apps_ne_ctr_apps (fun a c ys h' => by
      cases ys with
      | nil => exact h3 a c h'
      | cons y ys =>
        exact absurd (Term.apps_head_inv (xs := []) (ys := y :: ys) h1 (by trivial) h').1 (h3 a c))
            _ a c xs h

theorem Term.inst_cons_some (d : Nat) (v : Term) (ρ : List (Option Term)) (t : Term) :
    Term.inst d (some v :: ρ) t = Term.subst d v (Term.inst (d + 1) ρ t) := rfl

theorem Term.inst_cons_none (d : Nat) (ρ : List (Option Term)) (t : Term) :
    Term.inst d (none :: ρ) t = Term.inst (d + 1) ρ t := rfl

theorem CG.inst_closed (ht : t.Closed 0) (h : CG β t M) : CG β (Term.inst d ρ t) M := by
  rw [Term.inst_closed d ρ (Term.Closed.mono t 0 d ht (Nat.zero_le d))]; exact h

-- ----------------------------------------------------------------------------
-- the leaf pricing with lets
-- ----------------------------------------------------------------------------

theorem Leaf.priced2 (hok : Book.Ok β) (hE : Book.Era β 0 β βe)
    (hk : Book.defn β k = some d) (hkE : Book.defn βe k = some dE) (hnE : dE.n = d.n) :
    ∀ {L : LHS} {sp : List Term} {q : Quant} {Γ : Ctx} {t T : Term} {π : Uses} {u : Term},
    Check β (Pol.std β) L sp q Γ t T π u → q = .Lone →
    ∀ {r : Nat} {env : List Ent} {ρO ρS : List Term} {pins : Pins},
      LeafSt2 β βe k d L Γ r env ρO pins ρS →
    ∀ (es : List (Term × Term × Uses)), Term.CtrsFull β es.length t →
      EsF2 β βe ρO r k pins env Γ es → sp = es.map Prod.fst →
      EnvO.Aff env (Uses.add π (esUses es)) →
      (∀ (j : Nat) b, Ctx.get Γ j = some b → b.q = .None → Uses.add π (esUses es) j = .None) →
      (∃ T1 πs, Args β (Pol.std β) L q Γ T (es.map Prod.fst) T1 πs (es.map (fun e => e.2.1))) →
      LeafGoal2 β βe k pins ρO r env Γ t u π es := by
  have hβ := hok.closed
  have hΦ := Pol.std_pre hβ
  have hL : (Quant.Lone : Quant) ≠ .None := by decide
  intro L sp q Γ t T π u h
  induction h with
  | var hg =>
    intro hq r env ρO ρS pins st es hok' hes hsp haff hdead hargs
    rename_i Γ i b L sp q
    subst hq
    have hi : i < Γ.length := Ctx.get_lt hg
    have hρ := st.ρ_closed
    simp only [Term.era_live hL]
    obtain ⟨e, he⟩ : ∃ e, env[i]? = some e := ⟨_, List.getElem?_eq_getElem
        (by rw [← st.len]; exact hi)⟩
    have hbq : b.q ≠ .None := fun hq0 => by
      have := hdead i b hg hq0
      have h1 := (Quant.add_eq_none this).1
      simp only [Uses.one] at h1
      cases h1
    have hρi : (EnvO.ρ env)[i]? = some e.ρ := by rw [EnvO.ρ_get, he]; rfl
    cases hs : e.sub with
    | false =>
      obtain ⟨j', _, hinst⟩ := (Term.inst_var 0 (EnvO.ρ env) i hρ).2.1 (by rw [hρi, Ent.ρ_false hs])
      rw [Nat.zero_add] at hinst
      refine LeafGoal2.head (M := []) (by rw [hinst]; exact .var) PricedO.nil hes haff ?_ ?_
      · rw [Ctx.δ_apps, hinst]
        rcases st.kept i e he hs with ⟨i0, hi0, hlt⟩ | hn
        · rw [hi0]
          cases es with
          | nil => left; exact .var hlt
          | cons e0 es =>
            left
            exact .nov (Term.apps_cons_ne_var _ _ _) (Term.apps_ne_ctr_apps (Term.var_ne_ctr_apps
                i0) _)
        · right; exact ⟨Term.apps_ne_qnt (by simp) _, hn.apps _⟩
      · intro h0; exact absurd h0 (by rw [hinst]; exact Term.apps_ne_qnt (by simp) _)
    | true =>
      have hinst : Term.inst 0 (EnvO.ρ env) (.Var i) = e.era := by
        have := (Term.inst_var 0 (EnvO.ρ env) i hρ).1 e.era (by rw [hρi, Ent.ρ_true hs])
        rwa [Nat.zero_add] at this
      obtain ⟨_, _, hsubOk⟩ := st.ents e (List.mem_of_getElem? he)
      obtain ⟨_, M, Y, hM, hperm, hY⟩ := hsubOk hs
      have hp : PricedO k pins env (Uses.one i .Lone) M :=
        ⟨Y, e.chg, hperm, hY, EnvO.budget_one hL env i e he hs⟩
      obtain ⟨hdom, hside⟩ := st.dom i e b he hg hs
      refine LeafGoal2.head (M := M) (by rw [hinst]; exact hM) hp hes haff ?_ ?_
      · rw [Ctx.δ_apps, hinst]
        rcases hdom with hd | ⟨hne, hn⟩
        · exact DomS.apps' hd (hside hbq) _ _ (by simp) (EsF2.facts es hes)
        · right; exact ⟨Term.apps_ne_qnt hne _, hn.apps _⟩
      · intro h0 a c xs hx
        rw [hinst] at h0
        rw [Ctx.δ_apps] at hx
        cases es with
        | nil => exact hside hbq h0 a c xs hx
        | cons e0 es => exact absurd h0 (Term.apps_ne_qnt (x := .App e.era _) (by simp) _)
  | @ref j dd q L sp Γ hd' hw' hsp' =>
    intro hq r env ρO ρS pins st es hok' hes hsp haff hdead hargs
    subst hq
    unfold LeafGoal2
    simp only [Term.era_live hL, Term.inst_closed 0 _ (t := .Ref j) trivial]
    have hjk := hw' hL
    rw [st.hk] at hjk
    obtain ⟨Ms, hMs, hps⟩ := EsF2.priced es hes haff.add_r
    have hnov : DomS β βe ρO r (Ctx.δ Γ 0 (Term.apps (.Ref j) (es.map Prod.fst)))
        (Term.apps (.Ref j) (es.map (fun e => Term.inst 0 (EnvO.ρ env) e.2.1))) ∨
        (Term.apps (.Ref j) (es.map (fun e => Term.inst 0 (EnvO.ρ env) e.2.1)) ≠ .Qnt ∧
          NoV β r (Ctx.δ Γ 0 (Term.apps (.Ref j) (es.map Prod.fst)))) := by
      rw [Ctx.δ_apps]
      exact Or.inl (DomS.rigid_head (t := .Ref j) (by trivial) (by simp) (by simp) Γ _ _)
    have hside : Term.apps (.Ref j) (es.map (fun e => Term.inst 0 (EnvO.ρ env) e.2.1)) = .Qnt → ∀ a
        c xs,
        Ctx.δ Γ 0 (Term.apps (.Ref j) (es.map Prod.fst)) ≠ Term.apps (.Ctr a c) xs := by
      intro h0; exact absurd h0 (Term.apps_ne_qnt (by simp) _)
    rcases Nat.lt_or_eq_of_le hjk with hlt | heq
    · obtain ⟨dj', hkE', _⟩ := (Book.Era.defn_n hE _ _).mp ⟨_, hd', rfl⟩
      refine ⟨⟨_, .ref hkE' (Pins.of.rest dj'.n _) hMs, ?_⟩, hnov, hside⟩
      rw [Uses.zero_add]
      exact hps.cons (Or.inl hlt)
    · subst heq
      rw [hk] at hd'; cases hd'
      have hsl := hsp' hL st.hk.symm
      simp only [LHS.cols, st.hqs] at hsl
      subst hsp
      obtain ⟨T1, πs, hargs⟩ := hargs
      obtain ⟨pins', hp', hlt⟩ := SpineLt.pins ρO r 0 hsl pins
        (es.map (fun e => Term.inst 0 (EnvO.ρ env) e.2.1)) (by simp)
            (by rw [List.length_map, st.pl, st.cols])
        (fun i x e hx he => by
          rw [List.getElem?_map] at hx
          obtain ⟨x0, hx0, rfl⟩ := Option.map_eq_some_iff.mp hx
          exact EsF2.dom hE st.ρc es hes i x0 e hx0 he)
        (fun i e he hqn => by
          rw [List.getElem?_map] at he
          obtain ⟨e0, he0, rfl⟩ := Option.map_eq_some_iff.mp he
          rw [Args.teleqs_tokδ hβ d.n (hok.defn hk).2.1 hargs (Le.refl _) i e0.2.1
            (by rw [List.getElem?_map, he0]; rfl) (by simpa using hqn), Term.inst_closed 0 _ (t :=
                .Qnt) trivial])
        (fun i c hc => by
          rw [List.getElem?_map] at hc
          obtain ⟨c0, hc0, rfl⟩ := Option.map_eq_some_iff.mp hc
          exact (st.vg i c0 hc0).1)
        (fun i c n hc hp => by
          rw [List.getElem?_map] at hc
          obtain ⟨c0, hc0, rfl⟩ := Option.map_eq_some_iff.mp hc
          exact st.pin i c0 n hc0 hp)
      rw [List.length_map, st.cols, ← hnE] at hp'
      refine ⟨⟨_, .ref hkE hp' hMs, ?_⟩, hnov, hside⟩
      rw [Uses.zero_add]
      exact hps.cons (Or.inr ⟨rfl, hlt⟩)
  | refA hA h0 =>
    intro hq r env ρO ρS pins st es hok' hes hsp haff hdead hargs
    simp only [Term.era_live (hq ▸ hL)]
    rename_i j A L sp q Γ
    have hdj : Book.defn β j = none := by
      cases hdj : Book.defn β j with
      | none => rfl
      | some dj => exact (Book.defn_adt_clash hdj hA).elim
    have hdjE : Book.defn βe j = none := by
      cases h' : Book.defn βe j with
      | none => rfl
      | some d' =>
        obtain ⟨dj, hdj', _⟩ := (Book.Era.defn_n hE j d'.n).mpr ⟨d', h', rfl⟩
        rw [hdj] at hdj'; cases hdj'
    exact LeafGoal2.rigid (M := []) (CG.inst_closed (by trivial) (.refF hdjE)) PricedO.nil hes haff
      (by trivial) (by simp) (by simp)
  | @ctr a A c C r0 L sp q Γ hA hC hr =>
    intro hq r env ρO ρS pins st es hok' hes hsp haff hdead hargs
    subst hq
    simp only [Term.era_live hL]
    obtain ⟨T1, πs, hargs⟩ := hargs
    have hpn : A.pn ≤ es.length := Nat.le_trans (Nat.le_add_right _ _) (hok' A C hA hC)
    have hpar : ∀ (i : Nat) e, i < A.pn → (es.map (fun e => Term.inst 0 (EnvO.ρ env) e.2.1))[i]? =
        some e →
        e = .Qnt := by
      intro i e hi he
      rw [List.getElem?_map] at he
      obtain ⟨e0, he0, rfl⟩ := Option.map_eq_some_iff.mp he
      rw [Args.ctr_tokδ hβ (hok.shape hA hC) hargs (Le.refl _) i e0.2.1 hi
        (by rw [List.getElem?_map, he0]; rfl), Term.inst_closed 0 _ (t := .Qnt) trivial]
    refine LeafGoal2.head (M := []) (CG.inst_closed (by trivial) .ctr) PricedO.nil hes haff ?_ ?_
    · rw [Term.inst_closed 0 _ (t := .Ctr _ _) trivial, Ctx.δ_apps, Ctx.δ_closed _ 0 (.Ctr _ _)
        trivial]
      by_cases hall : ∀ (i : Nat) x e, ((es.map Prod.fst).map (Ctx.δ Γ 0))[i]? = some x →
          (es.map (fun e => Term.inst 0 (EnvO.ρ env) e.2.1))[i]? = some e → DomS β βe ρO r x e
      · left; exact .ctr hA hC (by simp) (by simpa using hpn) hpar hall
      · obtain ⟨i, x, e, hx, he, hnd⟩ : ∃ i x e, ((es.map Prod.fst).map (Ctx.δ Γ 0))[i]? = some x ∧
            (es.map (fun e => Term.inst 0 (EnvO.ρ env) e.2.1))[i]? = some e ∧ ¬ DomS β βe ρO r x e
                :=
          Classical.byContradiction fun hcon =>
            hall fun i x e hx he => Classical.byContradiction fun hn => hcon ⟨i, x, e, hx, he, hn⟩
        obtain ⟨hne, hn⟩ := (EsF2.facts es hes i x e hx he).resolve_left hnd
        have hipn : A.pn ≤ i := Nat.le_of_not_lt fun hlt => hne (hpar i e hlt he)
        right
        exact ⟨Term.apps_ne_qnt (x := .Ctr a c) (by simp) _,
          NoV.ctr_field hA hC hipn (List.getElem?_eq_some_iff.mp hx).1 hx hn⟩
    · intro h0
      rw [Term.inst_closed 0 _ (t := .Ctr _ _) trivial] at h0
      exact absurd h0 (Term.apps_ne_qnt (x := .Ctr a c) (by simp) _)
  | min ha hb iha ihb =>
    intro hq r env ρO ρS pins st es hok' hes hsp haff hdead hargs
    subst hq
    simp only [Term.era_live hL]
    have hok2 := hok'
    simp only [Term.CtrsFull] at hok2
    have haff' := haff.add_l
    have hdead' : ∀ (j : Nat) b, Ctx.get _ j = some b → b.q = .None → Uses.add _ _ j = .None :=
      fun j b hg hq => (Quant.add_eq_none (hdead j b hg hq)).1
    obtain ⟨⟨Ma, hMa, hpa⟩, _⟩ := iha rfl st [] hok2.1 trivial rfl
      (by rw [esUses, Uses.add_zero]; exact haff'.add_l)
      (fun j b hg hq =>
          by rw [esUses, Uses.add_zero]; exact (Quant.add_eq_none (hdead' j b hg hq)).1) ⟨_, _,
              .nil⟩
    obtain ⟨⟨Mb, hMb, hpb⟩, _⟩ := ihb rfl st [] hok2.2 trivial rfl
      (by rw [esUses, Uses.add_zero]; exact haff'.add_r)
      (fun j b hg hq =>
          by rw [esUses, Uses.add_zero]; exact (Quant.add_eq_none (hdead' j b hg hq)).2) ⟨_, _,
              .nil⟩
    simp only [List.map_nil, Term.apps, esUses, Uses.add_zero] at hMa hpa hMb hpb
    exact LeafGoal2.rigid (by rw [Term.inst_min]; exact .min hMa hMb) (hpa.append hpb haff') hes
        haff
      (by trivial) (by simp) (by simp)
  | @lam L Γ A q' πA q f B π' uf sp _ hf hle _ ihf =>
    intro hq r env ρO ρS pins st es hok' hes hsp haff hdead hargs
    subst hq
    simp only [Term.era_live hL]
    have hok2 : Term.CtrsFull β 0 f := hok'
    have hρ := st.ρ_closed
    obtain ⟨⟨M, hM, hp⟩, _⟩ := ihf rfl (by rw [LHS.lam_of_zero st.hn]; exact st.lam q' A) [] hok2
        trivial rfl
      (by rw [esUses, Uses.add_zero]; exact EnvO.Aff.cons (fun hs => by cases hs) haff.add_l)
      (fun j b hg hq => by
        rw [esUses, Uses.add_zero]
        cases j with
        | zero =>
          simp only [Ctx.get, Option.some.injEq] at hg; subst hg
          simp only [Bind.shift] at hq
          exact Quant.le_none_eq (hq ▸ hle)
        | succ j =>
          rw [Ctx.get_succ] at hg
          obtain ⟨b', hb', rfl⟩ := Option.map_eq_some_iff.mp hg
          exact (Quant.add_eq_none (hdead j b' hb' (by simpa [Bind.shift] using hq))).1)
      ⟨_, _, .nil⟩
    simp only [List.map_nil, Term.apps, esUses, Uses.add_zero] at hM hp
    rw [EnvO.ρ_cons, Ent.ρ_false rfl, Term.inst_cons_none] at hM
    refine LeafGoal2.rigid (M := M) ?_ (PricedO.under rfl hp) hes haff (by trivial) (by simp)
        (by simp)
    rw [Term.inst_lam 0 _ hρ]
    exact .lam hM
  | app hf hx ihf ihx =>
    intro hq r env ρO ρS pins st es hok' hes hsp haff hdead hargs
    rename_i L x sp q Γ f q' A B πf uf πx ux
    subst hq
    simp only [Term.era_live hL]
    obtain ⟨T1, πs, hargs⟩ := hargs
    have hok3 : Term.CtrsFull β (es.length + 1) f ∧ Term.CtrsFull β 0 x := hok'
    have haffx : EnvO.Aff env πx := haff.add_l.add_r
    have hdeadx : ∀ (j : Nat) b, Ctx.get Γ j = some b → b.q = .None → πx j = .None :=
      fun j b hg hq => (Quant.add_eq_none (Quant.add_eq_none (hdead j b hg hq)).1).2
    have hxfacts : (∃ M, CG βe (Term.inst 0 (EnvO.ρ env) ux) M ∧ PricedO k pins env πx M) ∧
        (DomS β βe ρO r (Ctx.δ Γ 0 x) (Term.inst 0 (EnvO.ρ env) ux) ∨
          (Term.inst 0 (EnvO.ρ env) ux ≠ .Qnt ∧ NoV β r (Ctx.δ Γ 0 x))) := by
      by_cases hq' : q' = .None
      · rw [hx.none_era (by rw [hq']; rfl), Term.inst_closed 0 _ (t := .Qnt) trivial]
        exact ⟨⟨[], .qnt, PricedO.nil⟩, .inl .qnt⟩
      · rw [Quant.dem_live hq'] at hx ihx
        obtain ⟨⟨M, hM, hp⟩, hdom, _⟩ := ihx rfl st [] hok3.2 trivial rfl
          (by rw [esUses, Uses.add_zero]; exact haffx)
          (fun j b hg hq => by rw [esUses, Uses.add_zero]; exact hdeadx j b hg hq) ⟨_, _, .nil⟩
        simp only [List.map_nil, Term.apps, esUses, Uses.add_zero] at hM hp hdom
        exact ⟨⟨M, hM, hp⟩, hdom⟩
    have hes' : EsF2 β βe ρO r k pins env Γ ((x, ux, πx) :: es) := ⟨hxfacts.1, hxfacts.2, hes⟩
    have haff' : EnvO.Aff env (Uses.add πf (esUses ((x, ux, πx) :: es))) := by
      simp only [esUses, ← Uses.add_assoc]; exact haff
    have hdead' : ∀ (j : Nat) b, Ctx.get Γ j = some b → b.q = .None →
        Uses.add πf (esUses ((x, ux, πx) :: es)) j = .None := fun j b hg hq => by
      simp only [esUses, ← Uses.add_assoc]; exact hdead j b hg hq
    have hargs' : ∃ T1 πs, Args β (Pol.std β) L .Lone Γ (.All q' A B) (((x, ux, πx) :: es).map
        Prod.fst) T1 πs
        (((x, ux, πx) :: es).map (fun e => e.2.1)) :=
      ⟨T1, _, .cons (hΦ.refl _) hx hargs⟩
    obtain ⟨⟨M, hM, hp⟩, hdom, hside⟩ := ihf rfl st ((x, ux, πx) :: es) hok3.1 hes'
        (by rw [hsp]; rfl)
      haff' hdead' hargs'
    simp only [List.map_cons, esUses, ← Uses.add_assoc] at hM hp hdom hside
    unfold LeafGoal2
    rw [Term.inst_app]
    exact ⟨⟨M, hM, hp⟩, hdom, hside⟩
  | appLam hc _ ih =>
    intro hq r env ρO ρS pins st es hok' hes hsp haff hdead hargs
    rename_i a0 L0 sp0 q0 Γ0 f0 T0 π0 u0 hprem
    subst hq
    have hok3 : Term.CtrsFull β 0 f0 ∧ Term.CtrsFull β 0 a0 := hok'
    have hok'' : Term.CtrsFull β es.length (Term.subst 0 a0 f0) :=
      (hok3.1.mono_n (Nat.zero_le _)).subst hok3.2 0
    obtain ⟨⟨M, hM, hp⟩, _, _⟩ := ih rfl st es hok'' hes hsp haff hdead hargs
    refine ⟨⟨M, hM, hp⟩, ?_, ?_⟩
    · show DomS β βe ρO r (Ctx.δ Γ0 0 (Term.apps (.Lam f0) (a0 :: es.map Prod.fst))) _ ∨ _
      rw [Ctx.δ_apps]; exact .inl (DomS.rigid_head (by trivial) (by simp) (by simp) Γ0 _ _)
    · intro _
      show ∀ a c xs, Ctx.δ Γ0 0 (Term.apps (.Lam f0) (a0 :: es.map Prod.fst)) ≠ Term.apps (.Ctr a
          c) xs
      rw [Ctx.δ_apps]; exact DomS.rigid_side (by trivial) (by simp) (by simp) Γ0 _
  | @let_ L0 qb q0 Γ0 v A πv uv πA b0 T0 π0 ub sp0 hv hkind hb hle ihv _ ihb =>
    intro hq r env ρO ρS pins st es hok' hes hsp haff hdead hargs
    subst hq
    simp only [Term.era_live hL]
    have hρ := st.ρ_closed
    have hok3 : Term.CtrsFull β 0 v ∧ Term.CtrsFull β 0 b0 := hok'
    have hinst : Term.inst 0 (EnvO.ρ env) (.Let qb uv ub)
        = .Let qb (Term.inst 0 (EnvO.ρ env) uv) (Term.inst 1 (EnvO.ρ env) ub) := Term.inst_let 0 _
            hρ qb uv ub
    have hdeadv : ∀ (j : Nat) b, Ctx.get Γ0 j = some b → b.q = .None → πv j = .None := fun j b hg
        hq =>
      (Quant.add_eq_none (Quant.add_eq_none (hdead j b hg hq)).1).1
    have hdeadb : ∀ (j : Nat) b, Ctx.get Γ0 j = some b → b.q = .None → Uses.tail π0 j = .None :=
        fun j b hg hq =>
      (Quant.add_eq_none (Quant.add_eq_none (hdead j b hg hq)).1).2
    have haffL : EnvO.Aff env (Uses.add πv (Uses.tail π0)) := haff.add_l
    have hsrcc : ∀ w ∈ env.map Ent.src, Term.Closed 0 w := by
      intro w hw; simp only [List.mem_map] at hw; obtain ⟨e, he, rfl⟩ := hw; exact (st.ents e he).1
    have herac : ∀ w ∈ env.map Ent.era, Term.Closed 0 w := by
      intro w hw
      simp only [List.mem_map] at hw
      obtain ⟨e, he, rfl⟩ := hw
      exact (st.ents e he).2.1
    have hvc : (Term.instL 0 (env.map Ent.src) v).Closed 0 :=
      Term.instL_closed_of _ 0 hsrcc
          (by rw [Nat.zero_add, List.length_map, ← st.len]; exact hv.closed)
    have hvdead : Check β (Pol.dead β) (LHS.void β) [] .None Γ0 v A Uses.zero .Qnt :=
      Check.dead_pol hβ hv.dead.void
    have hfin : ∀ M, CG βe (.Let qb (Term.inst 0 (EnvO.ρ env) uv) (Term.inst 1 (EnvO.ρ env) ub)) M →
        PricedO k pins env (Uses.add πv (Uses.tail π0)) M →
        LeafGoal2 β βe k pins ρO r env Γ0 (.Let qb v b0) (.Let qb uv ub) (Uses.add πv (Uses.tail
            π0)) es := by
      intro M hM hp
      exact LeafGoal2.rigid (by rw [hinst]; exact hM) hp hes haff (by trivial) (by simp) (by simp)
    -- the body's dead-binder uses
    have hdeadB : (qb = .None → π0 0 = .None) → ∀ (j : Nat) b, Ctx.get (⟨qb, A, some v⟩ :: Γ0) j =
        some b →
        b.q = .None → Uses.add π0 (esUses []) j = .None := by
      intro h0 j b hg hq
      rw [esUses, Uses.add_zero]
      cases j with
      | zero =>
        simp only [Ctx.get, Option.some.injEq] at hg; subst hg
        exact h0 (by simpa [Bind.shift] using hq)
      | succ j =>
        rw [Ctx.get_succ] at hg
        obtain ⟨b', hb', rfl⟩ := Option.map_eq_some_iff.mp hg
        exact hdeadb j b' hb' (by simpa [Bind.shift] using hq)
    by_cases hqb : qb = .None
    · -- a dead let: the token is substituted
      subst hqb
      have huv : uv = .Qnt := hv.none_era rfl
      subst huv
      have hπ0 : π0 0 = .None := Quant.le_none_eq hle
      obtain ⟨⟨Mb, hMb, hpb⟩, _⟩ := ihb rfl (st.let .None A v ⟨_, .Qnt, [], true⟩ hvc trivial
          (fun _ => ⟨.qnt, ⟨[], [], .qnt, .refl _, by simp⟩, .inl .qnt, fun h => absurd rfl h⟩)
          (fun h => by cases h) hvdead hok3.1 (fun _ h _ => absurd rfl h))
        [] hok3.2 trivial rfl
        (by rw [esUses, Uses.add_zero]; exact EnvO.Aff.cons (fun _ h => absurd rfl h) haffL.add_r)
        (hdeadB (fun _ => hπ0)) ⟨_, _, .nil⟩
      simp only [List.map_nil, Term.apps, esUses, Uses.add_zero] at hMb hpb
      rw [EnvO.ρ_cons, Ent.ρ_true rfl, Term.inst_cons_some] at hMb
      obtain ⟨Y, R, hpm, hY, hR⟩ := PricedO.under_sub rfl hpb
      rw [if_pos hπ0, List.nil_append] at hR
      refine hfin Mb
          (by rw [Term.inst_closed 0 _ (t := .Qnt) trivial]; exact .letC trivial .qnt hMb)
        ⟨Y, R, hpm, hY, hR.trans (EnvO.budget_le env _ _ (fun i hi => Quant.add_ne_none' hi))⟩
    · -- a live let: its value is priced by the induction
      have hqv : Quant.dem qb .Lone = .Lone := Quant.dem_live hqb
      rw [hqv] at hv ihv
      obtain ⟨⟨Mv, hMv, hpv⟩, hdv, hqv'⟩ := ihv rfl st [] hok3.1 trivial rfl
        (by rw [esUses, Uses.add_zero]; exact haffL.add_l)
        (fun j b hg hq => by rw [esUses, Uses.add_zero]; exact hdeadv j b hg hq) ⟨_, _, .nil⟩
      simp only [List.map_nil, Term.apps, esUses, Uses.add_zero] at hMv hpv hdv hqv'
      have hdeadB' := hdeadB (fun h => absurd h hqb)
      -- the value's shape: pure (a substituted variable, a token, a full
      -- constructor spine of such) with a closed deep instance, or verdict-free
      have hshape : (PureD β βe ρO r (Ctx.δ Γ0 0 v) (Term.inst 0 (EnvO.ρ env) uv) ∧
          (Term.inst 0 (EnvO.ρ env) uv).Closed 0 ∧ Deep βe (Term.inst 0 (EnvO.ρ env) uv)) ∨
          NoV β r (Ctx.δ Γ0 0 v) := by
        rcases hdv with hd | ⟨_, hn⟩
        · by_cases hcd : (Term.inst 0 (EnvO.ρ env) uv).Closed 0 ∧ Deep βe (Term.inst 0 (EnvO.ρ env)
            uv)
          · rcases DomS.pure_or_nov hE st.ρc hd hcd.1 hcd.2 (Term.CtrsFull.δ Γ0 st.full 0 hok3.1)
              with hp | hn
            · exact .inl ⟨hp, hcd⟩
            · exact .inr hn
          · exact .inr (DomS.nov_of hE st.ρc hd hcd)
        · exact .inr hn
      rcases hshape with ⟨hpure, hcd⟩ | hnv
      · -- substituted: a charge the value lends is a charge of a used entry,
        -- whose type is Data when the annotation is (the position lemma); so
        -- a Many-used let lends nothing, and a Lone-used one records that
        -- its annotation is not Data
        obtain ⟨Yv, Rv0, hpm0, hY0, hR0⟩ := hpv
        have hcore : ∀ n, Dat β (Term.cl Γ0 r ρS n A) → Rv0 ≠ [] → False := by
          intro n hDA hne
          obtain ⟨y, hy⟩ := List.exists_mem_of_ne_nil Rv0 hne
          have hyb : y ∈ EnvO.budget env πv :=
            List.count_pos_iff.mp (Nat.lt_of_lt_of_le (List.count_pos_iff.mpr hy) (hR0 y))
          obtain ⟨j, e, hje, hes', hπj, hyc⟩ := EnvO.budget_mem env πv y hyb
          obtain ⟨b, hb⟩ := Ctx.get_of_lt Γ0 j
              (by rw [st.len]; exact (List.getElem?_eq_some_iff.mp hje).1)
          have hbq : b.q ≠ .None := fun h0 => hπj (hdeadv j b hb h0)
          exact st.dat j e b hje hb hes' (List.ne_nil_of_mem hyc) hbq n
            (Check.pure_dat hok hv rfl st.outer st.ρSc st.full hρ [] .nil hpure hDA j b
              (by rw [Uses.add_zero]; exact hπj) hb)
        obtain ⟨Rv, hpr, hRvM, hRvb, hRvdat⟩ : ∃ Rv, (∃ M Y, CG βe (Term.inst 0 (EnvO.ρ env) uv) M ∧
            M.Perm (Y ++ Rv) ∧ ∀ y ∈ Y, Charge.lt y (k, pins)) ∧ (Rv ≠ [] → π0 0 ≠ .Many) ∧
            Sub Rv (EnvO.budget env πv) ∧ (Rv ≠ [] → ∀ n, ¬ Dat β (Term.cl Γ0 r ρS n A)) := by
          by_cases hall : ∀ y ∈ Rv0, Charge.lt y (k, pins)
          · exact ⟨[], ⟨Mv, Yv ++ Rv0, hMv, by simpa using hpm0,
              fun y hy => (List.mem_append.mp hy).elim (hY0 y) (hall y)⟩, fun h => absurd rfl h,
                  Sub.nil _,
              fun h => absurd rfl h⟩
          · have hne : Rv0 ≠ [] := fun h => hall (by rw [h]; simp)
            by_cases hm : π0 0 = .Many
            · exfalso
              have hqbM : qb = .Many := Quant.le_many_eq (hm ▸ hle)
              have hk' := hkind
              rw [hqbM] at hk'
              exact hcore 0 (Dat.of_outer hok st.outer hk' 0) hne
            · exact ⟨Rv0, ⟨Mv, Yv, hMv, hpm0, hY0⟩, fun _ => hm, hR0, fun _ n hD => hcore n hD hne⟩
        obtain ⟨⟨M1, hM1, hpb⟩, _⟩ := ihb rfl (st.let qb A v ⟨Term.instL 0 (env.map Ent.src) v, _,
            Rv, true⟩ hvc hcd.1
            (fun _ => ⟨hcd.2, hpr, hdv, fun _ => hqv'⟩) (fun h => by cases h) hvdead hok3.1
            (fun _ hne _ => hRvdat hne))
          [] hok3.2 trivial rfl
          (by rw [esUses, Uses.add_zero]; exact EnvO.Aff.cons (fun _ => hRvM) haffL.add_r)
          hdeadB' ⟨_, _, .nil⟩
        simp only [List.map_nil, Term.apps, esUses, Uses.add_zero] at hM1 hpb
        rw [EnvO.ρ_cons, Ent.ρ_true rfl, Term.inst_cons_some] at hM1
        obtain ⟨Y, R, hpm, hY, hR⟩ := PricedO.under_sub rfl hpb
        refine hfin M1 (.letC hcd.1 hcd.2 hM1) ⟨Y, R, hpm, hY, ?_⟩
        refine hR.trans ((Sub.append ?_ (Sub.refl _)).trans (EnvO.budget_add env πv (Uses.tail π0)
            haffL))
        split
        · exact Sub.nil _
        · exact hRvb
      · -- kept: the let is priced structurally, its variable stays
        have huvc : (Term.instL 0 (env.map Ent.era) uv).Closed 0 :=
          Term.instL_closed_of _ 0 herac
              (by rw [Nat.zero_add, List.length_map, ← st.len]; exact hv.closed_era)
        obtain ⟨⟨M1, hM1, hpb⟩, _⟩ := ihb rfl (st.let qb A v ⟨Term.instL 0 (env.map Ent.src) v,
            Term.instL 0 (env.map Ent.era) uv, [], false⟩ hvc huvc (fun h => by cases h) (fun _ =>
                hnv)
            hvdead hok3.1 (fun h => by cases h))
          [] hok3.2 trivial rfl
          (by rw [esUses, Uses.add_zero]; exact EnvO.Aff.cons (fun h => by cases h) haffL.add_r)
          hdeadB' ⟨_, _, .nil⟩
        simp only [List.map_nil, Term.apps, esUses, Uses.add_zero] at hM1 hpb
        rw [EnvO.ρ_cons, Ent.ρ_false rfl, Term.inst_cons_none] at hM1
        exact hfin (Mv ++ M1) (.let_ hMv hM1) (hpv.append (PricedO.under rfl hpb) haffL)
  | rwt he _ hf ihe _ ihf =>
    intro hq r env ρO ρS pins st es hok' hes hsp haff hdead hargs
    subst hq
    simp only [Term.era_live hL]
    have hok2 := hok'
    simp only [Term.CtrsFull] at hok2
    have haff' := haff.add_l
    have hdead' : ∀ (j : Nat) b, Ctx.get _ j = some b → b.q = .None → Uses.add _ _ j = .None :=
      fun j b hg hq => (Quant.add_eq_none (hdead j b hg hq)).1
    obtain ⟨⟨Me, hMe, hpe⟩, _⟩ := ihe rfl st [] hok2.1 trivial rfl
      (by rw [esUses, Uses.add_zero]; exact haff'.add_l)
      (fun j b hg hq =>
          by rw [esUses, Uses.add_zero]; exact (Quant.add_eq_none (hdead' j b hg hq)).1) ⟨_, _,
              .nil⟩
    obtain ⟨⟨Mf, hMf, hpf⟩, _⟩ := ihf rfl st [] hok2.2 trivial rfl
      (by rw [esUses, Uses.add_zero]; exact haff'.add_r)
      (fun j b hg hq =>
          by rw [esUses, Uses.add_zero]; exact (Quant.add_eq_none (hdead' j b hg hq)).2) ⟨_, _,
              .nil⟩
    simp only [List.map_nil, Term.apps, esUses, Uses.add_zero] at hMe hpe hMf hpf
    exact LeafGoal2.rigid
        (by rw [Term.inst_rwt, Term.inst_closed 0 _ (t := .Qnt) trivial]; exact .rwt hMe hMf)
            (hpe.append hpf haff')
      hes haff (by trivial) (by simp) (by simp)
  | mat hA hC hr hps hq' hI hG hh hm ihh ihm =>
    intro hq r env ρO ρS pins st es hok' hes hsp haff hdead hargs
    subst hq
    simp only [Term.era_live hL]
    have hok2 := hok'
    simp only [Term.CtrsFull] at hok2
    have haff' := haff.add_l
    have hdead' : ∀ (j : Nat) b, Ctx.get _ j = some b → b.q = .None → Uses.join _ _ j = .None :=
      fun j b hg hq => (Quant.add_eq_none (hdead j b hg hq)).1
    obtain ⟨⟨Mh, hMh, hph⟩, _⟩ := ihh rfl (by rw [LHS.mat_of_zero st.hn]; exact st) [] hok2.1
        trivial rfl
      (by rw [esUses, Uses.add_zero]; exact haff'.join_l)
      (fun j b hg hq =>
          by rw [esUses, Uses.add_zero]; exact (Quant.join_eq_none (hdead' j b hg hq)).1) ⟨_, _,
              .nil⟩
    obtain ⟨⟨Mm, hMm, hpm⟩, _⟩ := ihm rfl st [] hok2.2 trivial rfl
      (by rw [esUses, Uses.add_zero]; exact haff'.join_r)
      (fun j b hg hq =>
          by rw [esUses, Uses.add_zero]; exact (Quant.join_eq_none (hdead' j b hg hq)).2) ⟨_, _,
              .nil⟩
    simp only [List.map_nil, Term.apps, esUses, Uses.add_zero] at hMh hph hMm hpm
    obtain ⟨M, hsh, hsm, hp⟩ := hph.cover hpm (fun i => Quant.join_ne_none) (fun i =>
        Quant.join_ne_none')
    exact LeafGoal2.rigid (by rw [Term.inst_mat]; exact .mat hMh hMm hsh hsm) hp hes haff
      (by trivial) (by simp) (by simp)
  | cnv _ hle ih =>
    intro hq r env ρO ρS pins st es hok' hes hsp haff hdead hargs
    obtain ⟨T1, πs, hargs⟩ := hargs
    obtain ⟨T', hargs', _⟩ := Args.le_start hΦ hargs hle
    exact ih hq st es hok' hes hsp haff hdead ⟨T', πs, hargs'⟩
  | _ =>
    intro hq r env ρO ρS pins st es hok' hes hsp haff hdead hargs
    try simp only [Term.era_live (hq ▸ hL)]
    exact LeafGoal2.rigid (M := []) (CG.inst_closed (by trivial) (by
        first | exact .adt | exact .typ | exact .qnt | exact .qua | exact .all | exact .eql
              | exact .rfl | exact .efq)) PricedO.nil hes haff (by trivial) (by simp) (by simp)

-- ----------------------------------------------------------------------------
-- the walk's environment as a leaf environment
-- ----------------------------------------------------------------------------

def Env.toEnt (env : List (Term × Term × List Charge)) : List Ent :=
  env.map (fun e => ⟨e.1, e.2.1, e.2.2, true⟩)

theorem Env.toEnt_sub (env : List (Term × Term × List Charge)) : ∀ e ∈ Env.toEnt env, e.sub = true
    := by
  intro e he; simp only [Env.toEnt, List.mem_map] at he; obtain ⟨_, _, rfl⟩ := he; rfl

theorem Env.toEnt_ρ (env : List (Term × Term × List Charge)) :
    EnvO.ρ (Env.toEnt env) = (env.map (fun e => e.2.1)).map some := by
  rw [EnvO.ρ_allsub _ (Env.toEnt_sub env)]; simp [Env.toEnt]

structure WalkSt (β βe : Book) (k : Nat) (d : DefD) (us : List Term) (L : LHS) (Γ : Ctx)
    (T : Term) (π : Uses) (n j : Nat) (env : List (Term × Term × List Charge))
    (cols rest restS : List Term) (Mrest : List Charge) (qs : List Quant) : Prop where
  hk   : L.k = k
  hn   : L.n = n
  hqs  : L.qs = d.qs
  ht   : L.t = Term.lams j (Term.apps (.Ref k) cols)
  rig  : ∀ b ∈ Γ, b.v = none
  len  : Γ.length = env.length
  vals : ∀ e ∈ env, e.1.Closed 0 ∧ e.2.1.Closed 0 ∧ Deep βe e.2.1 ∧ CG βe e.2.1 e.2.2
  aff  : EnvO.Aff (Env.toEnt env) π
  rlen : rest.length = n
  jle  : j ≤ n
  rdeep : Deeps βe rest
  rcl  : ∀ r ∈ rest, r.Closed 0
  rcg  : CGs βe rest Mrest
  slen : restS.length = n
  pat  : ∀ (i : Nat) c, cols[i]? = some c → Pat βe c ∧ c.Closed (j + env.length)
  clen : cols.length + (n - j) = d.n
  drop : us.drop cols.length = rest.drop j
  csz  : ∀ (i : Nat) c ui, cols[i]? = some c → us[i]? = some ui →
           Term.csize βe (Term.instL 0 ((rest.take j).reverse ++ env.map (fun e => e.2.1)) c)
             = Term.csize βe ui
  args : ∃ T1 πs, Args β (Pol.std β) (LHS.void β) .Lone [] (Term.instL 0 (env.map Prod.fst) T)
      restS T1 πs rest
  telv : TelV β (Term.instL 0 (env.map Prod.fst) T) qs restS
  dat  : ∀ (j : Nat) e b, env[j]? = some e → Ctx.get Γ j = some b → e.2.2 ≠ [] → b.q ≠ .None →
           ∀ n, ¬ Dat β (Term.shiftN n (Term.instL 0 (env.map Prod.fst) b.T))
  dead : ∀ (j : Nat) b, Ctx.get Γ j = some b → b.q = .None → π j = .None
  clos : ClosOk β Γ (env.map (fun e => (e.1, e.2.1)))

theorem WalkSt.outer (st : WalkSt β βe k d us L Γ T π n j env cols rest restS Mrest qs) :
    Outer β Γ 0 (env.map Prod.fst) (env.map (fun e => e.2.1)) :=
  ⟨[], Γ, env.map (fun e => (e.1, e.2.1)), rfl, rfl, st.rig, st.clos, by simp, by simp, trivial⟩

theorem List.take_append_len {α : Type} (l1 l2 : List α) (n : Nat) :
    (l1 ++ l2).take (l1.length + n) = l1 ++ l2.take n := by
  rw [List.take_append, List.take_of_length_le (by omega), Nat.add_sub_cancel_left]

theorem List.drop_append_len {α : Type} (l1 l2 : List α) (n : Nat) :
    (l1 ++ l2).drop (l1.length + n) = l2.drop n := by
  rw [List.drop_append, List.drop_of_length_le (by omega), Nat.add_sub_cancel_left, List.nil_append]

theorem Term.Closed.shiftNAt : ∀ (n d : Nat) {t : Term} {m : Nat}, t.Closed m → (Term.shiftNAt n d
    t).Closed (m + n) := by
  intro n
  induction n with
  | zero => intro d t m h; exact h
  | succ n ih => intro d t m h; exact Term.Closed.shift _ _ d (ih d h)

-- the size of a pattern instance is unchanged when one variable's value
-- is replaced by another of the same size
theorem Pat.csize_congr_mid (h : Pat βe p) (A E : List Term) (v1 v2 : Term)
    (hA : ∀ w ∈ A, Term.Closed 0 w) (hE : ∀ w ∈ E, Term.Closed 0 w) (h1 : v1.Closed 0) (h2 :
        v2.Closed 0)
    (hp : p.Closed (A.length + 1 + E.length)) (hv : Term.csize βe v1 = Term.csize βe v2) :
    Term.csize βe (Term.instL 0 (A ++ [v1] ++ E) p) = Term.csize βe (Term.instL 0 (A ++ [v2] ++ E)
        p) := by
  have hc : ∀ v, v.Closed 0 → ∀ w ∈ A ++ [v] ++ E, Term.Closed 0 w := by
    intro v hv w hw; simp only [List.mem_append, List.mem_singleton] at hw
    rcases hw with (hw | rfl) | hw
    · exact hA w hw
    · exact hv
    · exact hE w hw
  refine Pat.csize_congr h _ _ (hc v1 h1) (hc v2 h2) (by simp) ?_
    (by simp only [List.length_append, List.length_singleton]; exact hp)
  intro i w1 w2 hw1 hw2
  rcases Nat.lt_trichotomy i A.length with hi | rfl | hi
  · rw [List.getElem?_append_left (by simp; omega), List.getElem?_append_left hi] at hw1 hw2
    rw [hw1] at hw2; cases hw2; rfl
  · rw [List.append_assoc, List.getElem?_append_right (Nat.le_refl _), Nat.sub_self] at hw1 hw2
    simp at hw1 hw2; subst hw1; subst hw2; exact hv
  · rw [List.getElem?_append_right (by simp; omega)] at hw1 hw2
    simp only [List.length_append, List.length_singleton] at hw1 hw2
    rw [hw1] at hw2; cases hw2; rfl

-- the walk: a Lam binds the next pending value (a field or a column) into
-- the environment; a Mat on the next pending value peels it into its
-- fields (the tested value's constructor shape from the walk's typing);
-- a leaf is priced by Leaf.priced2
theorem Unfold.walk (hok : Book.Ok β) (hE : Book.Era β 0 β βe)
    (hk : Book.defn β k = some d)
    (hkE : Book.defn βe k = some dE) (hnE : dE.n = d.n) (us : List Term) (pins : Pins)
    (hpins : Pins.of βe d.n us pins) :
    ∀ (n : Nat) {t : Term}, Tree β n t → ∀ (j : Nat),
    ∀ {L : LHS} {Γ : Ctx} {T : Term} {π : Uses} {u : Term}
      (env : List (Term × Term × List Charge)) (cols rest restS : List Term)
      (Mrest : List Charge) (qs : List Quant),
    Check β (Pol.std β) L [] .Lone Γ t T π u → Term.CtrsFull β 0 t →
    WalkSt β βe k d us L Γ T π n j env cols rest restS Mrest qs →
    ∃ M', CG βe (Term.apps (Term.instL 0 (env.map (fun e => e.2.1)) u) rest) M' ∧
      ∃ Y R, M'.Perm (Y ++ R) ∧ (∀ y ∈ Y, Charge.lt y (k, pins)) ∧
        Sub R (EnvO.budget (Env.toEnt env) π ++ Mrest) := by
  have hβ := hok.closed
  have hΦ := Pol.std_pre hβ
  intro n t ht
  induction ht with
  | @leaf t =>
    intro j L Γ T π u env cols rest restS Mrest qs hder hbo st
    obtain rfl : j = 0 := by have := st.jle; omega
    have hρc : ∀ v ∈ env.map (fun e => e.2.1), Term.Closed 0 v := by
      intro v hv
      simp only [List.mem_map] at hv
      obtain ⟨e, he, rfl⟩ := hv
      exact (st.vals e he).2.1
    cases rest with
    | cons _ _ => have := st.rlen; simp at this
    | nil =>
    cases st.rcg
    have hLt : L.t = Term.apps (.Ref k) cols := st.ht
    have hcl : cols.length = d.n := by have := st.clen; omega
    have hδ := Ctx.δ_rigid _ st.rig
    have hρSc : ∀ v ∈ env.map Prod.fst, Term.Closed 0 v := by
      intro v hv; simp only [List.mem_map] at hv; obtain ⟨e, he, rfl⟩ := hv; exact (st.vals e he).1
    have lst : LeafSt2 β βe k d L Γ 0 (Env.toEnt env) (env.map (fun e => e.2.1)) pins (env.map
        Prod.fst) := by
      refine ⟨st.hk, st.hn, st.hqs,
          by simp [Env.toEnt, st.len], hρc, ?_, ?_, ?_, ?_, ?_, hpins.length,
        ?_, ?_, hρSc, st.outer, Ctx.LetsFull.of_rigid Γ st.rig, ?_⟩
      · intro e he; simp only [Env.toEnt, List.mem_map] at he; obtain ⟨e', he', rfl⟩ := he
        exact ⟨(st.vals e' he').1, (st.vals e' he').2.1,
          fun _ => ⟨(st.vals e' he').2.2.1, _, [], (st.vals e' he').2.2.2, .refl _, by simp⟩⟩
      · intro j e b he hb hs
        simp only [Env.toEnt, List.getElem?_map] at he
        obtain ⟨e', he', rfl⟩ := Option.map_eq_some_iff.mp he
        rw [hδ]
        have hv := st.vals e' (List.mem_of_getElem? he')
        exact ⟨.inl (.varO (Nat.zero_le j) (by rw [Nat.sub_zero, List.getElem?_map, he']; rfl)
            hv.2.1 hv.2.2.1),
          fun _ _ => Term.var_ne_ctr_apps j⟩
      · intro j e he hs
        simp only [Env.toEnt, List.getElem?_map] at he
        obtain ⟨e', _, rfl⟩ := Option.map_eq_some_iff.mp he
        cases hs
      · rw [hLt, Term.spine_apps (by trivial)]
      · rw [hLt, Term.spine_apps (by trivial)]; exact hcl
      · intro i c hc
        rw [hLt, Term.spine_apps (by trivial)] at hc
        rw [hδ]
        refine ⟨fun i hi => absurd hi (Nat.not_lt_zero i), ?_⟩
        exact Term.instL_closed_of _ 0 hρc (by simpa using (st.pat i c hc).2)
      · intro i c m hc hp
        rw [hLt, Term.spine_apps (by trivial)] at hc
        obtain ⟨ui, hui, rfl⟩ := hpins.get i m hp
        rw [hδ]
        have := st.csz i c ui hc hui
        simpa using this
      · intro j e b he hb hs hc hq n
        simp only [Env.toEnt, List.getElem?_map] at he
        obtain ⟨e', he', rfl⟩ := Option.map_eq_some_iff.mp he
        simp only [Term.cl, hδ]
        exact st.dat j e' b he' hb hc hq n
    obtain ⟨⟨M', hM', Y, R, hp, hY, hR⟩, _, _⟩ := Leaf.priced2 hok hE hk hkE hnE hder rfl lst []
        hbo trivial rfl
      (by rw [esUses, Uses.add_zero]; exact st.aff)
      (by rw [esUses, Uses.add_zero]; exact st.dead) ⟨_, _, .nil⟩
    simp only [List.map_nil, Term.apps, esUses, Uses.add_zero, Env.toEnt_ρ] at hM' hp hR
    exact ⟨M', hM', Y, R, hp, hY, hR.trans (Sub.append_right _ _)⟩
  | @efq n =>
    intro j L Γ T π u env cols rest restS Mrest qs hder _ st
    obtain ⟨_, _, _, _, _, _, _, _, _, _, _, rfl⟩ := hder.efq_inv hΦ
    simp only [Term.era_lone]
    rw [Term.instL_closed 0 _ (t := .Efq) trivial]
    exact ⟨_, CG.apps .efq st.rcg, [], Mrest, by simp, by simp, Sub.append_left _ _⟩
  | @lam n f _ ih =>
    intro j L Γ T π u env cols rest restS Mrest qs hder hbo st
    obtain ⟨q', A, B, πA, π', uf, hA, hf, hle, hcv, rfl, rfl⟩ := hder.lam_inv hΦ
    have hbo' : Term.CtrsFull β 0 f := hbo
    simp only [Term.era_lone]
    have hδ := Ctx.δ_rigid _ st.rig
    have hcv' : Le β (.All q' A B) T := by simpa [hδ, Pol.std_conv] using hcv
    have hρSc : ∀ v ∈ env.map Prod.fst, Term.Closed 0 v := by
      intro v hv; simp only [List.mem_map] at hv; obtain ⟨e, he, rfl⟩ := hv; exact (st.vals e he).1
    have hρec : ∀ v ∈ env.map (fun e => e.2.1), Term.Closed 0 v := by
      intro v hv
      simp only [List.mem_map] at hv
      obtain ⟨e, he, rfl⟩ := hv
      exact (st.vals e he).2.1
    cases rest with
    | nil => have := st.rlen; simp at this
    | cons r0 rest' =>
    cases restS with
    | nil => have := st.slen; simp at this
    | cons a0 restS' =>
    cases qs with
    | nil => exact (st.telv).elim
    | cons q0 qs' =>
    obtain ⟨A', B', hleT, htv'⟩ := st.telv
    cases st.rcg with
    | cons hM0 hMrest' =>
    rename_i M0 Mrest'
    cases st.rdeep with
    | cons hr0d hrest'd =>
    have hr0c : r0.Closed 0 := st.rcl r0 (by simp)
    -- the binder's quantity is the expected one
    have hleAll : Le β (.All q' (Term.instL 0 (env.map Prod.fst) A) (Term.instL 1 (env.map
        Prod.fst) B))
        (.All q0 A' B') := by
      rw [← Term.instL_all 0 _ hρSc]; exact (hcv'.instL hβ 0 _).trans hβ hleT
    obtain ⟨hq, _, hB'⟩ := Le.all_inv hβ hleAll (Red.refl) (Red.refl)
    -- the value's closed typing
    obtain ⟨T1, πs, hargs⟩ := st.args
    obtain ⟨πx, ux, πs', us', B1, _, hus, hx, hB, hr'⟩ := Args.step hβ (Γ := [])
      (show Le β (Ctx.δ [] 0 (.All q' (Term.instL 0 (env.map Prod.fst) A) (Term.instL 1 (env.map
          Prod.fst) B)))
        (Ctx.δ [] 0 (Term.instL 0 (env.map Prod.fst) T)) from by
        rw [← Term.instL_all 0 _ hρSc]; exact hcv'.instL hβ 0 _) hargs
    obtain ⟨rfl, rfl⟩ := List.cons.inj hus
    simp only [Ctx.δ_nil] at hB
    have ha0c : a0.Closed 0 := hx.closed
    -- the new entry's charges: none when its type is Data (the value is inert)
    have hDc : (Term.instL 0 (env.map Prod.fst) A).Closed 0 :=
      Term.instL_closed_of _ 0 hρSc
          (by rw [Nat.zero_add, List.length_map, ← st.len]; exact hA.closed)
    obtain ⟨M0', hM0', hM0aff, hM0sub, hM0dat⟩ : ∃ M0', CG βe r0 M0' ∧ (M0' ≠ [] → π' 0 ≠ .Many) ∧
        Sub M0' M0 ∧
        (M0' ≠ [] → q' ≠ .None → ¬ Dat β (Term.instL 0 (env.map Prod.fst) A)) := by
      by_cases hD : q' ≠ .None ∧ Dat β (Term.instL 0 (env.map Prod.fst) A)
      · have hx' := hx
        rw [Quant.dem_live hD.1] at hx'
        exact ⟨[], (Check.dat_deep hok hx' hD.2 (Deep.era' hE hr0d)).1 βe, fun h => absurd rfl
            h, Sub.nil _,
          fun h => absurd rfl h⟩
      · refine ⟨M0, hM0, fun _ hm => ?_, Sub.refl _, fun _ hq' hD' => hD ⟨hq', hD'⟩⟩
        have hqm : q' = .Many := Quant.le_many_eq (hm ▸ hle)
        refine hD ⟨by rw [hqm]; decide, ?_⟩
        have hk' := hA
        rw [hqm] at hk'
        have := Dat.of_outer hok st.outer hk' 0
        simpa [Term.cl, hδ, Term.shiftN] using this
    have hn0 : L.n ≠ 0 := by rw [st.hn]; omega
    -- the binder's dead use and the closing environment under it
    have hdead' : ∀ (j : Nat) b, Ctx.get (⟨q', A, none⟩ :: Γ) j = some b → b.q = .None → π' j =
        .None := by
      intro j b hg hq
      cases j with
      | zero =>
        simp only [Ctx.get, Option.some.injEq] at hg; subst hg
        simp only [Bind.shift] at hq
        exact Quant.le_none_eq (hq ▸ hle)
      | succ j =>
        rw [Ctx.get_succ] at hg
        obtain ⟨b', hb', rfl⟩ := Option.map_eq_some_iff.mp hg
        exact st.dead j b' hb' (by simpa [Bind.shift] using hq)
    have hclos' : ClosOk β (⟨q', A, none⟩ :: Γ) (((a0, r0, M0') :: env).map (fun e => (e.1,
        e.2.1))) := by
      have hpf : (env.map (fun e => (e.1, e.2.1))).map Prod.fst = env.map Prod.fst := by simp
      have hTc : (Term.instL 0 (env.map Prod.fst) A).Closed 0 :=
        Term.instL_closed_of _ 0 hρSc
            (by rw [Nat.zero_add, List.length_map, ← st.len]; exact hA.closed)
      simp only [List.map_cons]
      refine ClosOk.cons st.clos ⟨q', A, none⟩ a0 r0 ha0c hr0c (Or.inl rfl) ?_ ?_ ?_
      · show Check β (Pol.std β) (LHS.void β) [] .None [] a0 (Term.instL 0 _ A) Uses.zero .Qnt
        rw [hpf]; exact hx.dead
      · intro hq'
        show ∃ πw, Check β (Pol.std β) (LHS.void β) [] .Lone [] a0 (Term.instL 0 _ A) πw r0
        rw [hpf, Quant.dem_live hq'] at *; exact ⟨_, hx⟩
      · intro hq' m a r ps hconv hemp
        show False
        simp only [hpf] at hconv
        rw [Term.shiftN_closed hTc] at hconv
        rw [Quant.dem_live hq'] at hx
        exact Check.deep_empty hok hx (Deep.era' hE hr0d) (Le.conv hconv) hemp
    -- the state under the binder: a field's lambda keeps the columns, a
    -- column's lambda appends the new column variable
    obtain ⟨cols', j', st'⟩ : ∃ cols' j', WalkSt β βe k d us L.lam (⟨q', A, none⟩ :: Γ) B π' n j'
        ((a0, r0, M0') :: env) cols' rest' restS' Mrest' qs' := by
      cases j with
      | succ j =>
        refine ⟨cols, j, ?_⟩
        refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, hrest'd, ?_, hMrest', ?_, ?_, ?_, ?_,
            ?_, ?_, ?_, ?_,
          hdead', hclos'⟩
        · rw [LHS.lam_pos hn0]; exact st.hk
        · rw [LHS.lam_pos hn0, st.hn]; rfl
        · rw [LHS.lam_pos hn0]; exact st.hqs
        · rw [LHS.lam_pos hn0]; show Term.applyB (Term.shift 0 L.t) (.Var 0) = _
          rw [st.ht]; exact Term.applyB_lams_succ j _
        · intro b hb; rw [List.mem_cons] at hb; exact hb.elim (fun e => e ▸ rfl) (st.rig b)
        · simp [st.len]
        · intro e he; rw [List.mem_cons] at he
          rcases he with rfl | he
          · exact ⟨ha0c, hr0c, hr0d, hM0'⟩
          · exact st.vals e he
        · exact EnvO.Aff.cons (fun _ => hM0aff) st.aff
        · have := st.rlen; simpa using this
        · have := st.jle; omega
        · intro r hr; exact st.rcl r (by simp [hr])
        · have := st.slen; simpa using this
        · intro i c hc; obtain ⟨h1, h2⟩ := st.pat i c hc
          refine ⟨h1, ?_⟩
          simp at h2 ⊢
          rw [show j + (env.length + 1) = j + 1 + env.length by omega]
          exact h2
        · have := st.clen; omega
        · have := st.drop; simpa using this
        · intro i c ui hc hui
          have := st.csz i c ui hc hui
          simpa [List.take_succ_cons, List.reverse_cons, List.append_assoc] using this
        · obtain ⟨T', hr'', _⟩ := Args.le_start hΦ hr' (by simp only [Ctx.δ_nil]; exact hB)
          exact ⟨T', πs', hr''⟩
        · simp only [List.map_cons, Term.instL_cons]
          exact TelV.le hβ (hB'.subst hβ 0 a0) htv'
        · intro j' e b he hb hc hq'' n
          cases j' with
          | zero =>
            simp at he; subst he
            simp only [Ctx.get, Option.some.injEq] at hb; subst hb
            simp only [List.map_cons]
            show ¬ Dat β (Term.shiftN n (Term.instL 0 (a0 :: env.map Prod.fst) (Term.shift 0 A)))
            rw [Term.instL_cons_shift _ _ hρSc, Term.shiftN_closed hDc]
            exact hM0dat hc (by simpa [Bind.shift] using hq'')
          | succ j' =>
            rw [Ctx.get_succ] at hb
            obtain ⟨b', hb', rfl⟩ := Option.map_eq_some_iff.mp hb
            simp only [List.map_cons]
            show ¬ Dat β (Term.shiftN n (Term.instL 0 (a0 :: env.map Prod.fst) (Term.shift 0 b'.T)))
            rw [Term.instL_cons_shift _ _ hρSc]
            exact st.dat j' e b' (by simpa using he) hb' hc (by simpa [Bind.shift] using hq'') n
      | zero =>
        have hus0 : us[cols.length]? = some r0 := by
          have := st.drop
          simp only [List.drop_zero] at this
          have h := congrArg (fun l => l[0]?) this
          simp only [List.getElem?_drop, Nat.add_zero, List.getElem?_cons_zero] at h
          exact h
        refine ⟨cols.map (Term.shift 0) ++ [.Var 0], 0, ?_⟩
        refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, hrest'd, ?_, hMrest', ?_, ?_, ?_, ?_,
            ?_, ?_, ?_, ?_,
          hdead', hclos'⟩
        · rw [LHS.lam_pos hn0]; exact st.hk
        · rw [LHS.lam_pos hn0, st.hn]; rfl
        · rw [LHS.lam_pos hn0]; exact st.hqs
        · rw [LHS.lam_pos hn0]; show Term.applyB (Term.shift 0 L.t) (.Var 0) = _
          rw [st.ht]; exact Term.applyB_lams_zero k cols
        · intro b hb; rw [List.mem_cons] at hb; exact hb.elim (fun e => e ▸ rfl) (st.rig b)
        · simp [st.len]
        · intro e he; rw [List.mem_cons] at he
          rcases he with rfl | he
          · exact ⟨ha0c, hr0c, hr0d, hM0'⟩
          · exact st.vals e he
        · exact EnvO.Aff.cons (fun _ => hM0aff) st.aff
        · have := st.rlen; simpa using this
        · exact Nat.zero_le _
        · intro r hr; exact st.rcl r (by simp [hr])
        · have := st.slen; simpa using this
        · intro i c hc
          rcases Nat.lt_or_ge i cols.length with hi | hi
          · rw [List.getElem?_append_left (by simpa using hi), List.getElem?_map] at hc
            obtain ⟨c0, hc0, rfl⟩ := Option.map_eq_some_iff.mp hc
            obtain ⟨h1, h2⟩ := st.pat i c0 hc0
            refine ⟨h1.shift 0, ?_⟩
            simp only [Nat.zero_add] at h2
            have := Term.Closed.shift c0 _ 0 h2
            simp only [List.length_cons, Nat.zero_add]; exact this
          · have hi' : i = cols.length := by
              have := (List.getElem?_eq_some_iff.mp hc).1; simp at this; omega
            subst hi'
            rw [List.getElem?_append_right (by simp), List.length_map, Nat.sub_self] at hc
            simp at hc; subst hc
            exact ⟨.var, by show 0 < 0 + ((a0, r0, M0') :: env).length; simp⟩
        · have := st.clen; simp; omega
        · have := st.drop
          simp only [List.drop_zero] at this
          simp only [List.length_append, List.length_map, List.length_singleton, List.drop_zero]
          rw [List.drop_succ_eq', this]; rfl
        · intro i c ui hc hui
          simp only [List.take_zero, List.reverse_nil, List.nil_append, List.map_cons]
          rcases Nat.lt_or_ge i cols.length with hi | hi
          · rw [List.getElem?_append_left (by simpa using hi), List.getElem?_map] at hc
            obtain ⟨c0, hc0, rfl⟩ := Option.map_eq_some_iff.mp hc
            rw [Term.instL_cons_shift r0 _ hρec]
            have := st.csz i c0 ui hc0 hui
            simpa using this
          · have hi' : i = cols.length := by
              have := (List.getElem?_eq_some_iff.mp hc).1; simp at this; omega
            subst hi'
            rw [List.getElem?_append_right (by simp), List.length_map, Nat.sub_self] at hc
            simp at hc; subst hc
            rw [hus0] at hui; cases hui
            rw [Term.instL_var_some 0 (r0 :: env.map (fun e => e.2.1)) (fun v hv => by
              rw [List.mem_cons] at hv
              exact hv.elim (fun e => e ▸ hr0c) (hρec v)) (i := 0) (v := r0) (by simp)]
        · obtain ⟨T', hr'', _⟩ := Args.le_start hΦ hr' (by simp only [Ctx.δ_nil]; exact hB)
          exact ⟨T', πs', hr''⟩
        · simp only [List.map_cons, Term.instL_cons]
          exact TelV.le hβ (hB'.subst hβ 0 a0) htv'
        · intro j' e b he hb hc hq'' n
          cases j' with
          | zero =>
            simp at he; subst he
            simp only [Ctx.get, Option.some.injEq] at hb; subst hb
            simp only [List.map_cons]
            show ¬ Dat β (Term.shiftN n (Term.instL 0 (a0 :: env.map Prod.fst) (Term.shift 0 A)))
            rw [Term.instL_cons_shift _ _ hρSc, Term.shiftN_closed hDc]
            exact hM0dat hc (by simpa [Bind.shift] using hq'')
          | succ j' =>
            rw [Ctx.get_succ] at hb
            obtain ⟨b', hb', rfl⟩ := Option.map_eq_some_iff.mp hb
            simp only [List.map_cons]
            show ¬ Dat β (Term.shiftN n (Term.instL 0 (a0 :: env.map Prod.fst) (Term.shift 0 b'.T)))
            rw [Term.instL_cons_shift _ _ hρSc]
            exact st.dat j' e b' (by simpa using he) hb' hc (by simpa [Bind.shift] using hq'') n
    obtain ⟨M', hM', Y, R, hp, hY, hR⟩ := ih j' ((a0, r0, M0') :: env) cols' rest' restS' Mrest'
        qs' hf hbo' st'
    simp only [List.map_cons] at hM' hR
    refine ⟨M', ?_, Y, R, hp, hY, ?_⟩
    · rw [Term.instL_lam 0 _ hρec]
      exact .beta hr0c hr0d (by rw [← Term.instL_cons]; exact hM')
    · intro x
      have h1 := hR x; have h2 := hM0sub x
      simp only [Env.toEnt, List.map_cons, EnvO.budget, List.count_append] at h1 ⊢
      split at h1 <;> (try simp only [List.count_nil] at h1) <;> omega
  | @mat a A c C n h m hA hC _ _ ihh ihm =>
    intro j L Γ T π u env cols rest restS Mrest qs hder hbo st
    have hboh : Term.CtrsFull β 0 h := hbo.1
    have hbom : Term.CtrsFull β 0 m := hbo.2
    obtain ⟨A0, C0, r, ps, q', telF, B, G, πh, uh, πm, um, hA0, hC0, hr, hps, hq', hI, hG, hh, hm,
      hcv, rfl, rfl⟩ := hder.mat_inv hΦ
    rw [hA] at hA0; cases hA0; rw [hC] at hC0; cases hC0
    simp only [Term.era_lone]
    have hδ := Ctx.δ_rigid _ st.rig
    have hcv' : Le β (.All q' (Term.apps (.Adt a r) ps) B) T :=
        by simpa [hδ, Pol.std_conv] using hcv
    have hρSc : ∀ v ∈ env.map Prod.fst, Term.Closed 0 v := by
      intro v hv; simp only [List.mem_map] at hv; obtain ⟨e, he, rfl⟩ := hv; exact (st.vals e he).1
    have hρec : ∀ v ∈ env.map (fun e => e.2.1), Term.Closed 0 v := by
      intro v hv
      simp only [List.mem_map] at hv
      obtain ⟨e, he, rfl⟩ := hv
      exact (st.vals e he).2.1
    cases rest with
    | nil => have := st.rlen; simp at this
    | cons r0 rest' =>
    cases restS with
    | nil => have := st.slen; simp at this
    | cons a0 restS' =>
    cases qs with
    | nil => exact (st.telv).elim
    | cons q0 qs' =>
    obtain ⟨A', B', hleT, htv'⟩ := st.telv
    cases st.rcg with
    | cons hM0 hMrest' =>
    rename_i M0 Mrest'
    cases st.rdeep with
    | cons hr0d hrest'd =>
    have hr0c : r0.Closed 0 := st.rcl r0 (by simp)
    have hq'ne : q' ≠ .None := hq' (by decide)
    have hn0 : L.n ≠ 0 := by rw [st.hn]; omega
    -- the closed instance of the match's domain
    have hinstA : Term.instL 0 (env.map Prod.fst) (Term.apps (.Adt a r) ps)
        = Term.apps (.Adt a r) (ps.map (Term.instL 0 (env.map Prod.fst))) := by
      rw [Term.instL_apps, Term.instL_closed 0 _ (t := .Adt _ _) trivial]
    have hleAll : Le β (.All q' (Term.apps (.Adt a r) (ps.map (Term.instL 0 (env.map Prod.fst))))
        (Term.instL 1 (env.map Prod.fst) B)) (.All q0 A' B') := by
      rw [← hinstA, ← Term.instL_all 0 _ hρSc]; exact (hcv'.instL hβ 0 _).trans hβ hleT
    obtain ⟨hq, _, hB'⟩ := Le.all_inv hβ hleAll (Red.refl) (Red.refl)
    obtain ⟨T1, πs, hargs⟩ := st.args
    obtain ⟨πx, ux, πs', us', B1, _, hus, hx, hB, hr'⟩ := Args.step hβ (Γ := [])
      (show Le β (Ctx.δ [] 0 (.All q' (Term.apps (.Adt a r) (ps.map (Term.instL 0 (env.map
          Prod.fst))))
          (Term.instL 1 (env.map Prod.fst) B))) (Ctx.δ [] 0 (Term.instL 0 (env.map Prod.fst) T))
              from by
        rw [← hinstA, ← Term.instL_all 0 _ hρSc]; exact hcv'.instL hβ 0 _) hargs
    obtain ⟨rfl, rfl⟩ := List.cons.inj hus
    simp only [Ctx.δ_nil] at hB
    rw [Quant.dem_live hq'ne] at hx
    have ha0c : a0.Closed 0 := hx.closed
    -- the tested value's shape
    obtain ⟨v, π'', c', A2, C2, as, vs, hred, hv, hv', rfl, rfl, hA2, hC2, hnotin, hlen, hlv, hcs⟩
        :=
      Deep.ctr_shape hok hx (Deep.era' hE hr0d) (Le.refl _)
    rw [hA] at hA2; cases hA2
    have hvsc : ∀ u ∈ vs, u.Closed 0 := (Term.closed_apps_inv _ _ _ hr0c).2
    have hvsd : Deeps βe vs := Deep.args hr0d (by trivial)
    have hM0' := CG.ctr_inv hM0
    have hconvA0 : Conv β (Term.apps (.Ctr a c') as) a0 := (Conv.of_red hred.strong).symm
    -- the spine derivation of the value, for the re-typing at a peeled family
    obtain ⟨T0v, π0v, u0v, T1v, πsv, usv, hh0v, hargsv, _, huv, hlusv⟩ :=
      hv'.spine_era hβ (fun _ e => Term.noConfusion e)
    obtain ⟨A3, C3, r0', hA3, hC3, hr0', hle0v, _, rfl⟩ := hh0v.ctr_inv hΦ
    rw [hA] at hA3; cases hA3; rw [hC2] at hC3; cases hC3
    simp only [Term.era_lone] at huv
    obtain ⟨_, rfl⟩ := Term.apps_head_inv (by trivial) (by trivial) huv
    by_cases hcc : c' = c
    · -- the arm
      have hcc' := hcc.symm
      subst hcc'
      rw [hC] at hC2; cases hC2
      obtain ⟨TS, hI_TS, hFT, ⟨πf, hargsTS⟩, _, _⟩ :=
        Check.ctr_fields_qs hok (DataPol.dead' hok) (Book.OkK.dead hok) hv' hA hC hlen
            (Deep.era' hE hr0d)
      have hCty : C.ty.Closed 0 := (hβ.adtd hA).2 c C hC
      have hI_c := hI.instL hCty (env.map Prod.fst) 0
      have hG_c := hG.instL (env.map Prod.fst) hρSc 0
      rw [Term.instL_apps, Term.instL_closed _ _ (t := .Ctr _ _) trivial] at hG_c
      have hconvTel : Conv β (Term.instL 0 (env.map Prod.fst) telF) TS :=
        Insts.conv hβ hI_c hI_TS (Conv.refl _) hcs.symm
      have hFT_c : FTele a [] (ps.map (Term.instL 0 (env.map Prod.fst))) C.fn
          (Term.instL 0 (env.map Prod.fst) telF) := by
        simpa using Insts.ftele (hok.shape hA hC) hI_c (by simp [hps])
      have hlenx : (as.drop A.pn).length = C.fn := by simp [hlen]
      have hargsG := MatGoal.apply hβ (Γ := []) (L := LHS.void β) (q := .Lone) C.fn hG_c (fun _ =>
          hq'ne)
        (by rw [Quant.dem_live hq'ne]; exact hargsTS) (Le.conv hconvTel) hlenx
      have hconvTip : Conv β (Term.apps (Term.apps (.Ctr a c) (ps.map (Term.instL 0 (env.map
          Prod.fst))))
          (as.drop A.pn)) a0 := by
        rw [← Term.apps_append]
        refine Conv.trans hβ ?_ hconvA0
        have := Conv.apps (Conv.refl (Term.Ctr a c)) (Convs.append hcs.symm (Convs.refl (as.drop
            A.pn)))
        rwa [List.take_append_drop] at this
      have hleTip : Le β (Term.subst 0 (Term.apps (Term.apps (.Ctr a c) (ps.map (Term.instL 0
          (env.map Prod.fst))))
          (as.drop A.pn)) (Term.instL 1 (env.map Prod.fst) B)) (Term.subst 0 a0 B1) :=
        (Le.conv (Conv.substR hβ hconvTip 0 _)).trans hβ hB
      obtain ⟨T', hr'', _⟩ := Args.le_start hΦ hr' (by simp only [Ctx.δ_nil]; exact hleTip)
      have hargsArm := hargsG.append hr''
      have htvArm := MatGoal.telv C.fn hG_c hFT_c (as.drop A.pn) hlenx (qs := qs') (rest := restS')
        (TelV.le hβ ((Le.conv (Conv.substR hβ hconvTip 0 _)).trans hβ (hB'.subst hβ 0 a0)) htv')
      have hqsEq : Term.allQs C.fn (Term.instL 0 (env.map Prod.fst) telF) = Term.allQs C.fn TS :=
        Term.allQs_conv C.fn hconvTel hFT_c hFT
      -- the pending values' charges
      rw [← List.take_append_drop A.pn vs] at hM0'
      obtain ⟨Mp, Mf, _, hMf, rfl⟩ := CGs.append_inv _ hM0'
      have hxs : (vs.drop A.pn).length = C.fn := by simp; omega
      have hxsc : ∀ u ∈ vs.drop A.pn, u.Closed 0 := fun u hu => hvsc u (List.mem_of_mem_drop hu)
      have hxsd : Deeps βe (vs.drop A.pn) := Deeps.of_mem fun u hu => hvsd.mem u
          (List.mem_of_mem_drop hu)
      -- the value's size is that of its field-only rebuild
      have hcsz0 : Term.csize βe (Term.apps (.Ctr a c) (vs.drop A.pn)) = Term.csize βe (Term.apps
          (.Ctr a c) vs) := by
        rw [Term.csize_fields (hE.adt hA) hC hxs, Term.csize_ctr (hE.adt hA) hC]
        have : vs.length - C.fn = A.pn := by omega
        rw [this]
      have hrlen : (vs.drop A.pn ++ rest').length = n + C.fn := by
        simp only [List.length_append, hxs]; have := st.rlen; simp at this; omega
      have hslen : (as.drop A.pn ++ restS').length = n + C.fn := by
        simp only [List.length_append, List.length_drop, hlen]; have := st.slen; simp at this; omega
      -- the state in the arm: the tested value's pattern replaces its column
      -- (an original column: a new pattern column; a pending field: the
      -- field's binder is substituted by the pattern)
      obtain ⟨cols'', j', st'⟩ : ∃ cols'' j', WalkSt β βe k d us (L.mat a c C.fn) Γ G πh (n + C.fn)
          j' env cols''
          (vs.drop A.pn ++ rest') (as.drop A.pn ++ restS') (Mf ++ Mrest')
          ((Term.allQs C.fn (Term.instL 0 (env.map Prod.fst) telF)).map (fun qf => Quant.mul qf q')
              ++ qs') := by
        cases j with
        | zero =>
          have hus0 : us[cols.length]? = some (Term.apps (.Ctr a c) vs) := by
            have := st.drop
            simp only [List.drop_zero] at this
            have h := congrArg (fun l => l[0]?) this
            simp only [List.getElem?_drop, Nat.add_zero, List.getElem?_cons_zero] at h
            exact h
          refine ⟨cols.map (Term.shiftN C.fn) ++ [Term.apps (.Ctr a c) (Term.rvars C.fn)], C.fn, ?_⟩
          refine ⟨?_, ?_, ?_, ?_, st.rig, st.len, st.vals, st.aff.join_l, hrlen,
              Nat.le_add_left _ _,
            hxsd.append hrest'd, ?_, hMf.append hMrest', hslen, ?_, ?_, ?_, ?_, ⟨T', _, hargsArm⟩,
                htvArm, st.dat,
            fun j b hg hq => (Quant.join_eq_none (st.dead j b hg hq)).1, st.clos⟩
          · rw [LHS.mat_pos hn0]; exact st.hk
          · rw [LHS.mat_pos hn0, st.hn]; show n + 1 - 1 + C.fn = n + C.fn; omega
          · rw [LHS.mat_pos hn0]; exact st.hqs
          · rw [LHS.mat_pos hn0]; show Term.lhsExt L.t a c C.fn = _
            rw [st.ht]; exact Term.lhsExt_lams_zero k cols a c C.fn
          · intro r hr; rw [List.mem_append] at hr
            exact hr.elim (hxsc r) (fun hr => st.rcl r (by simp [hr]))
          · intro i c0 hc
            rcases Nat.lt_or_ge i cols.length with hi | hi
            · rw [List.getElem?_append_left (by simpa using hi), List.getElem?_map] at hc
              obtain ⟨c1, hc1, rfl⟩ := Option.map_eq_some_iff.mp hc
              obtain ⟨h1, h2⟩ := st.pat i c1 hc1
              simp only [Nat.zero_add] at h2
              refine ⟨h1.shiftN C.fn, ?_⟩
              have := Term.shiftN_closed_at h2 C.fn
              rw [Nat.add_comm]; exact this
            · have hi' : i = cols.length := by
                have := (List.getElem?_eq_some_iff.mp hc).1; simp at this; omega
              subst hi'
              rw [List.getElem?_append_right (by simp), List.length_map, Nat.sub_self] at hc
              simp at hc; subst hc
              refine ⟨Pat.rvars (hE.adt hA) hC, ?_⟩
              exact Term.closed_apps _ _ _ trivial (fun x hx =>
                Term.Closed.mono x _ _ (Term.rvars_closed C.fn x hx) (by omega))
          · have := st.clen; simp; omega
          · have := st.drop
            simp only [List.drop_zero] at this
            simp only [List.length_append, List.length_map, List.length_singleton]
            rw [List.drop_succ_eq', this, ← hxs, List.drop_left]; rfl
          · intro i c0 ui hc hui
            have hpend : (vs.drop A.pn ++ rest').take C.fn = vs.drop A.pn :=
                by rw [← hxs, List.take_left]
            rw [hpend]
            rcases Nat.lt_or_ge i cols.length with hi | hi
            · rw [List.getElem?_append_left (by simpa using hi), List.getElem?_map] at hc
              obtain ⟨c1, hc1, rfl⟩ := Option.map_eq_some_iff.mp hc
              have hpl : (vs.drop A.pn).reverse.length = C.fn := by simp [hxs]
              rw [← hpl, Term.instL_shiftN_pend _ _ (fun w hw => by
                rw [List.mem_append, List.mem_reverse] at hw; exact hw.elim (hxsc w) (hρec w))]
              have := st.csz i c1 ui hc1 hui
              simpa using this
            · have hi' : i = cols.length := by
                have := (List.getElem?_eq_some_iff.mp hc).1; simp at this; omega
              subst hi'
              rw [List.getElem?_append_right (by simp), List.length_map, Nat.sub_self] at hc
              simp at hc; subst hc
              rw [hus0] at hui; cases hui
              rw [Term.instL_apps, Term.instL_closed _ _ (t := .Ctr _ _) trivial, ← hxs,
                  Term.instL_rvars _ _ (fun w hw => by
                rw [List.mem_append] at hw; exact hw.elim (hxsc w) (hρec w))]
              exact hcsz0
        | succ j =>
          -- the pending field's binder (Var j inside the columns) becomes the pattern
          have hjn : j ≤ n := by have := st.jle; omega
          have hrl : rest'.length = n := by have := st.rlen; simpa using this
          obtain ⟨Ap, hApdef, hAp⟩ : ∃ Ap, (rest'.take j).reverse = Ap ∧ Ap.length = j :=
            ⟨_, rfl, by simp; omega⟩
          obtain ⟨Bp, hBpdef, hBp⟩ : ∃ Bp, (vs.drop A.pn).reverse = Bp ∧ Bp.length = C.fn :=
            ⟨_, rfl, by simp [hxs]⟩
          have hApc : ∀ w ∈ Ap, w.Closed 0 := by
            intro w hw; rw [← hApdef, List.mem_reverse] at hw
            exact st.rcl w (by simp [List.mem_of_mem_take hw])
          have hBpc : ∀ w ∈ Bp, w.Closed 0 := by
            intro w hw; rw [← hBpdef, List.mem_reverse] at hw; exact hxsc w hw
          have hQeq : Term.instL 0 (Bp ++ env.map (fun e => e.2.1)) (Term.apps (.Ctr a c)
              (Term.rvars Bp.length))
              = Term.apps (.Ctr a c) (vs.drop A.pn) := by
            rw [hBp, ← hBpdef, Term.instL_apps, Term.instL_closed _ _ (t := .Ctr _ _) trivial, ←
                hxs, Term.instL_rvars _ _ (fun w hw => by
              rw [List.mem_append] at hw; exact hw.elim (hxsc w) (hρec w))]
          have hQc : (Term.apps (.Ctr a c) (vs.drop A.pn)).Closed 0 :=
            Term.closed_apps _ _ _ trivial hxsc
          refine ⟨cols.map (fun x => Term.subst j (Term.shiftN j (Term.apps (.Ctr a c) (Term.rvars
              C.fn)))
            (Term.shiftNAt C.fn (1 + j) x)), C.fn + j, ?_⟩
          refine ⟨?_, ?_, ?_, ?_, st.rig, st.len, st.vals, st.aff.join_l, hrlen, by omega,
            hxsd.append hrest'd, ?_, hMf.append hMrest', hslen, ?_, ?_, ?_, ?_, ⟨T', _, hargsArm⟩,
                htvArm, st.dat,
            fun j b hg hq => (Quant.join_eq_none (st.dead j b hg hq)).1, st.clos⟩
          · rw [LHS.mat_pos hn0]; exact st.hk
          · rw [LHS.mat_pos hn0, st.hn]; show n + 1 - 1 + C.fn = n + C.fn; omega
          · rw [LHS.mat_pos hn0]; exact st.hqs
          · rw [LHS.mat_pos hn0]; show Term.lhsExt L.t a c C.fn = _
            rw [st.ht]; exact Term.lhsExt_lams_succ k cols a c C.fn j
          · intro r hr; rw [List.mem_append] at hr
            exact hr.elim (hxsc r) (fun hr => st.rcl r (by simp [hr]))
          · intro i c0 hc
            rw [List.getElem?_map] at hc
            obtain ⟨c1, hc1, rfl⟩ := Option.map_eq_some_iff.mp hc
            obtain ⟨h1, h2⟩ := st.pat i c1 hc1
            refine ⟨(h1.shiftNAt C.fn (1 + j)).subst ((Pat.rvars (hE.adt hA) hC).shiftN j) j, ?_⟩
            have hP : (Term.apps (.Ctr a c) (Term.rvars C.fn)).Closed C.fn :=
              Term.closed_apps _ _ _ trivial (fun x hx => Term.rvars_closed C.fn x hx)
            refine Term.Closed.substO _ _ _ _ (Term.Closed.mono _ _ _ (Term.shiftN_closed_at hP j)
                (by omega)) (by omega) ?_
            have := Term.Closed.shiftNAt C.fn (1 + j) h2
            exact Term.Closed.mono _ _ _ this (by omega)
          · simp only [List.length_map]; have := st.clen; omega
          · simp only [List.length_map]
            have := st.drop
            rw [this, List.drop_succ_cons, ← hxs, List.drop_append_len]
          · intro i c0 ui hc hui
            rw [List.getElem?_map] at hc
            obtain ⟨c1, hc1, rfl⟩ := Option.map_eq_some_iff.mp hc
            obtain ⟨h1, h2⟩ := st.pat i c1 hc1
            have hpend : (vs.drop A.pn ++ rest').take (C.fn + j) = vs.drop A.pn ++ rest'.take j :=
                by
              rw [← hxs]; exact List.take_append_len _ _ _
            rw [hpend, List.reverse_append, hApdef, hBpdef, Nat.add_comm 1 j, ← hAp, ← hBp]
            rw [Pat.instL_subst h1 Ap Bp _ _ (by
                intro w hw; simp only [List.mem_append] at hw
                rcases hw with (hw | hw) | hw
                · exact hApc w hw
                · exact hBpc w hw
                · exact hρec w hw) (by rw [hQeq]; exact hQc) (by
                rw [hAp, List.length_map]; exact h2)]
            rw [hQeq, Pat.csize_congr_mid h1 Ap _ _ (Term.apps (.Ctr a c) vs) hApc hρec hQc hr0c
              (by rw [hAp, List.length_map]; exact h2) hcsz0]
            have := st.csz i c1 ui hc1 hui
            rw [List.take_succ_cons, List.reverse_cons, hApdef] at this
            exact this
      obtain ⟨M', hM', Y, R, hp, hY, hR⟩ := ihh j' env _ _ _ _ _ hh hboh st'
      refine ⟨M', ?_, Y, R, hp, hY, ?_⟩
      · rw [Term.instL_mat]
        exact .matc (hE.adt hA) hC (by omega) hvsc hvsd hM'
      · intro x
        have h1 := hR x
        have h2 := EnvO.budget_le (Env.toEnt env) πh (Uses.join πh πm) (fun i hi =>
            Quant.join_ne_none hi) x
        simp only [List.count_append] at h1 h2 ⊢
        omega
    · -- the tail
      have hne : (a, c') ≠ (a, c) := fun e => hcc (Prod.mk.inj e).2
      have hnotin' : c' ∉ c :: r := by
        intro hmem; rw [List.mem_cons] at hmem; exact hmem.elim hcc hnotin
      have hrebuild := Args.rebuild hβ (Γ := []) (hok.shape hA hC2) hargsv hle0v hlen (c :: r)
      have hvA := Check.apps (sp := []) (Check.ctr (sp := as ++ []) (L := LHS.void β) (q := .Lone)
          (Γ := [])
        hA hC2 hnotin') hrebuild
      simp only [Term.era_lone, List.nil_append] at hvA
      have hleAdt : Le β (Term.apps (.Adt a (c :: r)) (as.take A.pn))
          (Term.apps (.Adt a (c :: r)) (ps.map (Term.instL 0 (env.map Prod.fst)))) :=
        Le.adt (fun c hc => hc) hcs.length (fun i p p' hp hp' => hcs.get i p p' hp hp')
      obtain ⟨πv, hvT⟩ : ∃ πv, Check β (Pol.std β) (LHS.void β) [] (Quant.dem q' .Lone) []
          (Term.apps (.Ctr a c') as)
          (Term.apps (.Adt a (c :: r)) (ps.map (Term.instL 0 (env.map Prod.fst)))) πv
          (Term.apps (.Ctr a c') vs) :=
        ⟨_, by rw [Quant.dem_live hq'ne]; exact Check.cnv hvA
                 (by simp only [Ctx.δ_nil]; exact hleAdt)⟩
      have hleV : Le β (Term.subst 0 (Term.apps (.Ctr a c') as) (Term.instL 1 (env.map Prod.fst) B))
          (Term.subst 0 a0 B1) := (Le.conv (Conv.substR hβ hconvA0 0 _)).trans hβ hB
      obtain ⟨T', hr'', _⟩ := Args.le_start hΦ hr' (by simp only [Ctx.δ_nil]; exact hleV)
      have hargsTail := Args.cons (β := β) (Φ := Pol.std β) (L := LHS.void β) (q := .Lone) (Γ := [])
        (T0 := .All q' (Term.apps (.Adt a (c :: r)) (ps.map (Term.instL 0 (env.map Prod.fst))))
          (Term.instL 1 (env.map Prod.fst) B))
        (show (Pol.std β).conv (Ctx.δ [] 0 (Term.All q' (Term.apps (.Adt a (c :: r))
            (ps.map (Term.instL 0 (env.map Prod.fst)))) (Term.instL 1 (env.map Prod.fst) B)))
          (Ctx.δ [] 0 (Term.All q' (Term.apps (.Adt a (c :: r)) (ps.map (Term.instL 0 (env.map
              Prod.fst))))
            (Term.instL 1 (env.map Prod.fst) B))) from Le.refl _) hvT hr''
      have hinstT : Term.instL 0 (env.map Prod.fst) (.All q' (Term.apps (.Adt a (c :: r)) ps) B)
          = .All q' (Term.apps (.Adt a (c :: r)) (ps.map (Term.instL 0 (env.map Prod.fst))))
              (Term.instL 1 (env.map Prod.fst) B) := by
        rw [Term.instL_all 0 _ hρSc, Term.instL_apps, Term.instL_closed 0 _ (t := .Adt _ _) trivial]
      have st' : WalkSt β βe k d us L Γ (.All q' (Term.apps (.Adt a (c :: r)) ps) B) πm (n + 1) j
          env cols
          (Term.apps (.Ctr a c') vs :: rest') (Term.apps (.Ctr a c') as :: restS') (M0 ++ Mrest')
              (q0 :: qs') := by
        refine ⟨st.hk, st.hn, st.hqs, st.ht, st.rig, st.len, st.vals, st.aff.join_r,
            st.rlen, st.jle,
          .cons hr0d hrest'd, st.rcl, .cons hM0 hMrest',
              by simpa using st.slen, st.pat, st.clen, st.drop, st.csz,
          ?_, ?_, st.dat, fun j b hg hq => (Quant.join_eq_none (st.dead j b hg hq)).2, st.clos⟩
        · rw [hinstT]; exact ⟨T', _, hargsTail⟩
        · rw [hinstT]
          refine ⟨_, _, by rw [← hq]; exact Le.refl _, ?_⟩
          exact TelV.le hβ ((Le.conv (Conv.substR hβ hconvA0 0 _)).trans hβ (hB'.subst hβ 0 a0))
              htv'
      obtain ⟨M', hM', Y, R, hp, hY, hR⟩ := ihm j env cols _ _ _ _ hm hbom st'
      refine ⟨M', ?_, Y, R, hp, hY, ?_⟩
      · rw [Term.instL_mat]
        exact .matm hne hvsc hvsd hM'
      · intro x
        have h1 := hR x
        have h2 := EnvO.budget_le (Env.toEnt env) πm (Uses.join πh πm) (fun i hi =>
            Quant.join_ne_none' hi) x
        simp only [List.count_append] at h1 h2 ⊢
        omega

-- N4b: the unfold of a saturated definition spine decreases the charges,
-- for a definition whose body is a case tree: the walk from the root, with
-- the spine's typing read off its erasure
theorem Unfold.meas_full (hok : Book.Ok β) (hE : Book.Era β 0 β βe)
    (hk : Book.defn β k = some d)
    (hT : Tree β d.n d.body) (hcf : Term.CtrsFull β 0 d.body) {sp : List Term}
    (hkE : Book.defn βe k = some dE) (hbE : dE.body = ub)
    (h : Check β (Pol.std β) (LHS.void β) sp .Lone [] t T π (Term.apps (.Ref k) us))
    (hlen : us.length = d.n) (hus : Deeps βe us)
    (hM : CG βe (Term.apps (.Ref k) us) M) :
    ∃ M', CG βe (Term.apps ub us) M' ∧ MLt M' M := by
  have hβ := hok.closed
  obtain ⟨ub', π0, hkE', hder⟩ := Book.Era.defn hE hk
  rw [hkE] at hkE'; cases hkE'
  simp at hbE; subst hbE
  rw [← List.reverse_reverse us] at hM
  obtain ⟨pins, Ms, hp, hMs, hperm⟩ := CG.ref_inv hkE _ _ hM
  rw [List.reverse_reverse] at hp hMs
  obtain ⟨as, T1, πs, hargs, _⟩ := Check.ref_spine_args hβ hk h rfl rfl us rfl
  have hasl : as.length = d.n := by rw [← hargs.length]; exact hlen
  have husc : ∀ u ∈ us, u.Closed 0 := (Term.closed_apps_inv _ _ _ h.closed_era).2
  have st : WalkSt β βe k d us ⟨k, .Ref k, d.n, d.qs⟩ [] d.ty π0 d.n 0 [] [] us as Ms d.qs := by
    refine ⟨rfl, rfl, rfl, rfl, fun b hb => by simp at hb, rfl, fun e he => by simp at he,
      fun j e he => by simp [Env.toEnt] at he, hlen, Nat.zero_le _, hus, husc, hMs, hasl,
      fun i c hc => by simp at hc, by simp, rfl, fun i c ui hc => by simp at hc,
      ⟨T1, πs, hargs⟩, TeleQs.telv hβ (hok.defn hk).2.1 as hasl, (fun j e _ he => by simp at he),
      (fun j b hg _ => by cases hg), .nil⟩
  obtain ⟨M', hM', Y, R, hp', hY, hR⟩ :=
    Unfold.walk hok hE hk hkE rfl us pins hp d.n hT 0 [] [] us as Ms d.qs hder hcf st
  simp only [List.map_nil] at hM' hR
  have hR' : Sub R Ms := by simpa [EnvO.budget, Env.toEnt] using hR
  obtain ⟨Dm, hDm⟩ := Sub.perm_append _ _ hR'
  refine ⟨M', hM', (k, pins) :: Dm, Y, R, by simp, ?_, hp', fun y hy => ⟨_, by simp, hY y hy⟩⟩
  exact hperm.trans ((hDm.trans List.perm_append_comm).cons _)

-- ============================================================================
-- METATHEORY §Z — the claims. Everything above is assembled here: the
-- engine (§N) runs a closed live term to a deep erasure, the Bad route
-- (§G, §N3) refutes a deep inhabitant of an emptied family, and the
-- step lemma (§F) retypes every live step
-- ============================================================================

-- the spec's live step is F's LStep with no condition on the fired
-- redex's argument
theorem LiveStep.lstep (h : LiveStep β t u t') : LStep β (fun _ _ => True) t u t' := by
  induction h with
  | beta => exact .beta fun _ _ _ => trivial
  | let_ => exact .let_ fun _ _ _ => trivial
  | dref hk hs hl => exact .dref hk hs hl
  | aref hk hp => exact .aref hk hp
  | matc hk hc hp hx => exact .matc hk hc hp hx
  | matm hne => exact .matm hne
  | rwt => exact .rwt
  | minLM => exact .minLM
  | minLN => exact .minLN
  | minRM => exact .minRM
  | minRN => exact .minRN
  | minLL => exact .minLL
  | min_a _ ih => exact .min_a ih
  | min_b _ ih => exact .min_b ih
  | app_f _ ih => exact .app_f ih
  | app_a hl hx _ ih => exact .app_a hl hx ih
  | mat_h _ ih => exact .mat_h ih
  | mat_m _ ih => exact .mat_m ih
  | rwt_e _ ih => exact .rwt_e ih
  | rwt_f _ ih => exact .rwt_f ih
  | let_v _ hv ih => exact .let_v ih hv

-- Norm β t T: the engine's output — t weak-reduces to a closed live term
-- of the same type whose erasure is deep
def Norm (β : Book) (t T : Term) : Prop :=
  ∃ t' π' u', Red β .weak t t' ∧
    Check β (Pol.std β) (LHS.void β) [] .Lone [] t' T π' u' ∧ Deep β u'

-- ----------------------------------------------------------------------------
-- Erasure-directed inversion: a derivation whose erasure has a given root
-- shape reaches, through appLam betas on the subject and cnv, the rule of
-- that shape (the erasure is fixed; the subject weak-reduces)
-- ----------------------------------------------------------------------------

theorem Quant.le_lone (h : Quant.le p q) (hne : q ≠ .Many) : Quant.le p .Lone := by
  cases q <;> cases p <;> simp_all [Quant.le]

theorem Check.era_app (hβ : Book.Closed β) {sp : List Term}
    (h : Check β (Pol.std β) L sp q Γ t T π u) (hL : L = LHS.void β) (hΓ : Γ = [])
    (hq : q = .Lone) (hu : u = .App uf ux) :
    ∃ f x q' A B πf πx, Red β .weak t (.App f x) ∧
      Check β (Pol.std β) (LHS.void β) (x :: sp) .Lone [] f (.All q' A B) πf uf ∧
      Check β (Pol.std β) (LHS.void β) [] (Quant.dem q' .Lone) [] x A πx ux ∧
      Le β (Term.subst 0 x B) T := by
  induction h with
  | app hf hx =>
    subst hL hΓ hq; rw [Term.era_lone] at hu; cases hu
    exact ⟨_, _, _, _, _, _, _, .refl, hf, hx, Le.refl _⟩
  | appLam _ _ ih =>
    obtain ⟨f, x, q', A, B, πf, πx, hr, hf, hx, hle⟩ := ih hL hΓ hq hu
    exact ⟨f, x, q', A, B, πf, πx, .step .beta hr, hf, hx, hle⟩
  | cnv _ hle ih =>
    subst hΓ
    obtain ⟨f, x, q', A, B, πf, πx, hr, hf, hx, hle'⟩ := ih hL _root_.rfl hq hu
    exact ⟨f, x, q', A, B, πf, πx, hr, hf, hx, hle'.trans hβ hle⟩
  | _ => subst hq; simp at hu

theorem Check.era_lam (hβ : Book.Closed β) {sp : List Term}
    (h : Check β (Pol.std β) L sp q Γ t T π u) (hL : L = LHS.void β) (hΓ : Γ = [])
    (hq : q = .Lone) (hu : u = .Lam ug) :
    ∃ q' A B, (q' ≠ .Many → Term.occ 0 ug ≤ 1) ∧
      (∃ πA, Check β (Pol.std β) (LHS.void β) [] .None [] A (.Typ (.Qua q')) πA .Qnt) ∧
      Le β (.All q' A B) T := by
  induction h with
  | lam hA hf hle =>
    subst hL hΓ hq; rw [Term.era_lone] at hu; cases hu
    exact ⟨_, _, _, fun hne => hf.occ_le (Quant.le_lone hle hne), ⟨_, hA⟩, Le.refl _⟩
  | appLam _ _ ih => exact ih hL hΓ hq hu
  | cnv _ hle ih =>
    subst hΓ
    obtain ⟨q', A, B, hocc, hA, hle'⟩ := ih hL _root_.rfl hq hu
    exact ⟨q', A, B, hocc, hA, hle'.trans hβ hle⟩
  | _ => subst hq; simp at hu

theorem Check.era_let {sp : List Term}
    (h : Check β (Pol.std β) L sp q Γ t T π u) (hL : L = LHS.void β) (hΓ : Γ = [])
    (hq : q = .Lone) (hu : u = .Let qb uv ub) :
    ∃ v A πv, Check β (Pol.std β) (LHS.void β) [] (Quant.dem qb .Lone) [] v A πv uv ∧
      (qb ≠ .Many → Term.occ 0 ub ≤ 1) ∧
      ∃ πA, Check β (Pol.std β) (LHS.void β) [] .None [] A (.Typ (.Qua qb)) πA .Qnt := by
  induction h with
  | let_ hv hA hb hle =>
    subst hL hΓ hq; rw [Term.era_lone] at hu; cases hu
    exact ⟨_, _, _, hv, fun hne => hb.occ_le (Quant.le_lone hle hne), _, hA⟩
  | appLam _ _ ih => exact ih hL hΓ hq hu
  | cnv _ _ ih => exact ih hL hΓ hq hu
  | _ => subst hq; simp at hu

theorem Check.era_rwt {sp : List Term}
    (h : Check β (Pol.std β) L sp q Γ t T π u) (hL : L = LHS.void β) (hΓ : Γ = [])
    (hq : q = .Lone) (hu : u = .Rwt ue uP uf) :
    ∃ e a b T0 πe, Check β (Pol.std β) (LHS.void β) [] .Lone [] e (.Eql a b T0) πe ue := by
  induction h with
  | rwt he _ _ =>
    subst hL hΓ hq; rw [Term.era_lone] at hu; cases hu
    exact ⟨_, _, _, _, _, he⟩
  | appLam _ _ ih => exact ih hL hΓ hq hu
  | cnv _ _ ih => exact ih hL hΓ hq hu
  | _ => subst hq; simp at hu

theorem Check.era_min {sp : List Term}
    (h : Check β (Pol.std β) L sp q Γ t T π u) (hL : L = LHS.void β) (hΓ : Γ = [])
    (hq : q = .Lone) (hu : u = .Min ua ub) :
    ∃ a b πa πb, Check β (Pol.std β) (LHS.void β) [] .Lone [] a .Qnt πa ua ∧
      Check β (Pol.std β) (LHS.void β) [] .Lone [] b .Qnt πb ub := by
  induction h with
  | min ha hb =>
    subst hL hΓ hq; rw [Term.era_lone] at hu; cases hu
    exact ⟨_, _, _, _, ha, hb⟩
  | appLam _ _ ih => exact ih hL hΓ hq hu
  | cnv _ _ ih => exact ih hL hΓ hq hu
  | _ => subst hq; simp at hu

-- the typed side facts of a fired beta / let (N4's hypotheses): a Lone or
-- None binder occurs at most once in the body's erasure; a Many binder
-- holds a Data value, whose deep erasure prices and weighs nothing (N3b)
theorem Check.beta_side (hok : Book.Ok β) (hP : DataPol β Φ)
    (hK : Book.OkK β Φ) {sp : List Term}
    (h : Check β (Pol.std β) (LHS.void β) sp .Lone [] t T π (.App (.Lam uf) ua))
    (hd : Deep β ua) :
    Term.occ 0 uf ≤ 1 ∨ ((∀ β', CG β' ua []) ∧ ∀ β', Term.weight β' ua = 0) := by
  have hβ := hok.closed
  obtain ⟨f, x, q', A, B, πf, πx, _, hf, hx, _⟩ := Check.era_app hβ h _root_.rfl _root_.rfl
      _root_.rfl _root_.rfl
  obtain ⟨q1, A1, B1, hocc, ⟨πA, hA⟩, hle⟩ := Check.era_lam hβ hf _root_.rfl _root_.rfl _root_.rfl
      _root_.rfl
  obtain ⟨rfl, hAA, _⟩ := Le.all_inv hβ hle .refl .refl
  by_cases hm : q1 = .Many
  · subst hm
    exact .inr (Check.data_deep_aux hok hP hK _ (Nat.le_refl _) (hx.cnv hAA)
      (hA.mono hP.std hP.efq) hd)
  · exact .inl (hocc hm)

theorem Check.let_side (hok : Book.Ok β) (hP : DataPol β Φ)
    (hK : Book.OkK β Φ) {sp : List Term}
    (h : Check β (Pol.std β) (LHS.void β) sp .Lone [] t T π (.Let qb uv ub))
    (hd : Deep β uv) :
    Term.occ 0 ub ≤ 1 ∨ ((∀ β', CG β' uv []) ∧ ∀ β', Term.weight β' uv = 0) := by
  have hβ := hok.closed
  obtain ⟨v, A, πv, hv, hocc, πA, hA⟩ := Check.era_let h _root_.rfl _root_.rfl _root_.rfl _root_.rfl
  by_cases hm : qb = .Many
  · subst hm
    exact .inr (Check.data_deep_aux hok hP hK _ (Nat.le_refl _) hv
      (hA.mono hP.std hP.efq) hd)
  · exact .inl (hocc hm)

-- ----------------------------------------------------------------------------
-- The fired position (N4's Fired): below the strategy's congruences sits a
-- closed live typed term whose erasure is the redex — or the token, at a
-- dead argument, which the strategy never fires
-- ----------------------------------------------------------------------------

theorem Check.fired (hβ : Book.Closed β) {sp : List Term}
    (h : Check β (Pol.std β) (LHS.void β) sp .Lone [] t T π u) (hf : Fired u r) :
    r = .Qnt ∨ ∃ t' T' π' sp', Check β (Pol.std β) (LHS.void β) sp' .Lone [] t' T' π' r := by
  induction hf generalizing t T π sp with
  | root => exact .inr ⟨_, _, _, _, h⟩
  | app_f _ ih =>
    obtain ⟨_, _, _, _, _, _, _, _, hf, _, _⟩ :=
      Check.era_app hβ h _root_.rfl _root_.rfl _root_.rfl _root_.rfl
    exact ih hf
  | app_a hfa ih =>
    obtain ⟨_, _, q', _, _, _, _, _, _, hx, _⟩ :=
      Check.era_app hβ h _root_.rfl _root_.rfl _root_.rfl _root_.rfl
    cases q' with
    | None => obtain rfl := hx.none_era _root_.rfl; cases hfa; exact .inl _root_.rfl
    | Lone => exact ih hx
    | Many => exact ih hx
  | let_v hfv ih =>
    rename_i v r' qb b
    obtain ⟨_, _, _, hv, _, _⟩ := Check.era_let h _root_.rfl _root_.rfl _root_.rfl _root_.rfl
    cases qb with
    | None => obtain rfl := hv.none_era _root_.rfl; cases hfv; exact .inl _root_.rfl
    | Lone => exact ih hv
    | Many => exact ih hv
  | rwt_e _ ih =>
    obtain ⟨_, _, _, _, _, he⟩ := Check.era_rwt h _root_.rfl _root_.rfl _root_.rfl _root_.rfl
    exact ih he
  | min_a _ ih =>
    obtain ⟨_, _, _, _, ha, _⟩ := Check.era_min h _root_.rfl _root_.rfl _root_.rfl _root_.rfl
    exact ih ha
  | min_b _ ih =>
    obtain ⟨_, _, _, _, _, hb⟩ := Check.era_min h _root_.rfl _root_.rfl _root_.rfl _root_.rfl
    exact ih hb

theorem Check.fired_beta (hok : Book.Ok β) (hP : DataPol β Φ)
    (hK : Book.OkK β Φ) {sp : List Term}
    (h : Check β (Pol.std β) (LHS.void β) sp .Lone [] t T π u)
    (hf : Fired u (.App (.Lam uf) ua)) (hd : Deep β ua) :
    Term.occ 0 uf ≤ 1 ∨ ((∀ β', CG β' ua []) ∧ ∀ β', Term.weight β' ua = 0) :=
  match Check.fired hok.closed h hf with
  | .inl e => Term.noConfusion e
  | .inr ⟨_, _, _, _, h'⟩ => Check.beta_side hok hP hK h' hd

theorem Check.fired_let (hok : Book.Ok β) (hP : DataPol β Φ)
    (hK : Book.OkK β Φ) {sp : List Term}
    (h : Check β (Pol.std β) (LHS.void β) sp .Lone [] t T π u)
    (hf : Fired u (.Let qb uv ub)) (hd : Deep β uv) :
    Term.occ 0 ub ≤ 1 ∨ ((∀ β', CG β' uv []) ∧ ∀ β', Term.weight β' uv = 0) :=
  match Check.fired hok.closed h hf with
  | .inl e => Term.noConfusion e
  | .inr ⟨_, _, _, _, h'⟩ => Check.let_side hok hP hK h' hd

-- the drive: while the erasure is not deep, N3's strategy step retypes
-- the subject and N4's measure step lowers the pricing of the erasure
-- (well-founded induction on N1's measure)
theorem Norm.drive (hok : Book.Ok β) (hE : Book.Era β 0 β βe)
    (meas : ∀ {t π u u' M}, Check β (Pol.std β) (LHS.void β) [] .Lone [] t T π u →
      SStep βe u u' → CG βe u M →
      ∃ M', CG βe u' M' ∧ MeasLt (M', Term.weight βe u') (M, Term.weight βe u))
    (h : Check β (Pol.std β) (LHS.void β) [] .Lone [] t T π u) : Norm β t T := by
  obtain ⟨M, hM⟩ := CG.exists (β := βe) u
  refine MeasLt.wf.induction (C := fun m => ∀ t π u M, m = (M, Term.weight βe u) →
    CG βe u M → Check β (Pol.std β) (LHS.void β) [] .Lone [] t T π u → Norm β t T)
    (M, Term.weight βe u) ?_ t π u M rfl hM h
  intro m ih t π u M hm hM h
  subst hm
  by_cases hd : Deep β u
  · exact ⟨t, π, u, .refl, h, hd⟩
  obtain ⟨t', u', π', hr, hs, h'⟩ := Check.sstep hok hE h hd
  obtain ⟨M', hM', hlt⟩ := meas h hs hM
  obtain ⟨t'', π'', u'', hr', h'', hd''⟩ := ih _ hlt t' π' u' M' rfl hM' h'
  exact ⟨t'', π'', u'', hr.trans hr', h'', hd''⟩

-- N4's side facts at every fired position of a closed live erasure: the
-- affine bound or the chargeless Data argument at a beta or let, and the
-- unfold's decrease at a saturated definition spine
theorem Check.side (hok : Book.Ok β) (hE : Book.Era β 0 β βe) {sp : List Term}
    (h : Check β (Pol.std β) (LHS.void β) sp .Lone [] t T π u) : Side βe u := by
  have hP := DataPol.dead' hok
  have hK := Book.OkK.dead hok
  refine ⟨fun f a hf hd => ?_, fun q v b hf hd => ?_,
    fun k dE us M hf hkE hlen hus hM => ?_⟩
  · exact (Check.fired_beta hok hP hK h hf (hd.era' hE)).imp_right
      fun ⟨h1, h2⟩ => ⟨h1 βe, h2 βe⟩
  · exact (Check.fired_let hok hP hK h hf (hd.era' hE)).imp_right
      fun ⟨h1, h2⟩ => ⟨h1 βe, h2 βe⟩
  · obtain ⟨d, hk, hn⟩ := (Book.Era.defn_n hE k dE.n).2 ⟨dE, hkE, _root_.rfl⟩
    rcases Check.fired hok.closed h hf with e | ⟨_, _, _, _, h'⟩
    · exact (Term.apps_ne (by trivial) (by trivial) (fun e => Term.noConfusion e) e).elim
    have hlen' : us.length = d.n := hlen.trans hn.symm
    exact Unfold.meas_full hok hE hk (Book.Ok.defn hok hk).2.2.1
      (Book.Ok.defn hok hk).2.2.2.1 hkE _root_.rfl h' hlen' hus hM

-- the engine: every closed live term of an Ok book normalizes
-- (well-founded induction on §N1's measure of the erasure)
theorem norm_all (hok : Book.Ok β)
    (h : Check β (Pol.std β) (LHS.void β) [] .Lone [] t T π u) : Norm β t T := by
  obtain ⟨βe, hE⟩ := hok.era
  exact Norm.drive hok hE (fun h hs hM =>
    SStep.meas hs hM h.closed_era (Check.side hok hE h)) h

-- ----------------------------------------------------------------------------
-- The claims (spec §11)
-- ----------------------------------------------------------------------------

-- (5) consistency: a normal form of an emptied family is refuted by
-- Check.deep_empty
theorem consistency_holds : consistency := by
  intro β a r ps t π u hok hemp h
  obtain ⟨_, _, _, _, h', hd⟩ := norm_all hok h
  exact Check.deep_empty hok h' hd (Le.refl _) hemp

-- (4) normalization: the normal form's subject reduces by appLam betas
-- to a value with the same erasure (Check.deep_value)
theorem normalization_holds : normalization := by
  intro β t T π u hok h
  obtain ⟨t', π', u', hr, h', hd⟩ := norm_all hok h
  obtain ⟨v, π'', hrv, hv, hcv⟩ := Check.deep_value hok.closed h' (by decide) hd
  exact ⟨v, π'', u', hr.trans hrv, hv, hcv⟩

-- (2) subject reduction: F's Check.step at the trivial argument
-- condition, whose ex-falso obligation is consistency
theorem subject_reduction_holds : subject_reduction := by
  intro β t t' T π u hok h hs
  obtain ⟨βe, hE⟩ := hok.era
  obtain ⟨π', u', h', _⟩ := Check.step hok hE (V := fun _ _ => True)
    (fun _ ha e r ps hc hemp =>
      consistency_holds β e r ps _ _ _ hok hemp (ha.cnv (Le.conv hc)))
    hs.lstep h
  exact ⟨π', u', h'⟩

-- (1) confluence and (3) progress are B's and G's: church_rosser_holds,
-- progress_holds

#print axioms church_rosser_holds
#print axioms subject_reduction_holds
#print axioms progress_holds
#print axioms normalization_holds
#print axioms consistency_holds

end BendCore
