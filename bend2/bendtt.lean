import Std.Data.HashMap

-- BendTT
-- ======
--
-- BendTT is Bend's kernel: a dependent affine calculus with Type : Type,
-- no universe levels and no native datatypes. This file holds the whole
-- kernel and the argument for its consistency, in three parts:
--
-- 1. THEORY: terms, evaluator, conversion, the bidirectional checker, the
--    live check, a parser for .bendtt text and a CLI.
-- 2. CLAIMS: the declarative theory, and the claims about Part 1's check.
-- 3. PROOF: the lemmas, in order.
--
-- A term has a dead part and a live part, read off its syntax. Types,
-- annotations, motives, and the argument, field or value of a q=0 App,
-- Tup or Let are dead: they are checked for types only, never run, and
-- may be inconsistent (Girard's paradox fits there). All else is live.
-- Every binder, App and Tup states its quantity, so the live part needs
-- no types. The typing checker (Checker) ignores usage; the live check
-- (Termination) ignores types. The live part of a def must be affine (a
-- q=1 variable is used at most once, a q=0 one never), may call only
-- earlier defs, and may call its own def only on parameters it rebuilt,
-- then a piece of one.
-- A q=2 binder needs a Data domain, and Data holds no λ and no call.
--
-- Then live evaluation terminates by a measure that ignores types: a call
-- is replaced by smaller calls, and all else shrinks. Subject reduction
-- and progress carry the type along, and no value has type <>. So no live
-- term inhabits Empty: termination follows from linearity, and types
-- only rule out stuck terms.
--
-- A datatype is a Σ over a label: Nat = Σt:<Z, S> -> (Nat.arms t). A
-- match is a λ-match: λ{(,): h} splits a pair, λ{.k: h; m} switches on
-- a label, λ{} eliminates the empty enum. A def's leading λs and λ-matches
-- (and λ-matches applied to variables it bound) are its case tree: a call
-- unfolds only when its arguments walk the whole tree, so a stuck call
-- stays a call, and compares by its spine.
--
--   Term ::=
--   | Var ::= k                            # a bound name
--   | Ref ::= k                            # a def's name
--   | Ann ::= "{" x ":" T "}"
--   | Let ::= "!" q k "=" v ";" f          # transparent
--   | Typ ::= "*1" | "*2"                  # Type, Data
--   | All ::= "∀" q k ":" A "->" B
--   | Lam ::= "λ" q k "=>" f
--   | App ::= "(" f (q x)+ ")"
--   | Sig ::= "Σ" q k ":" A "->" B
--   | Tup ::= "(" q a "," b ")"            # (a, b, c) is (a, (b, c))
--   | Prj ::= "λ{(,):" h "}"
--   | Enu ::= "<" k,* ">"                  # k may be ()
--   | Lab ::= "." k | "()"
--   | Mat ::= "λ{" Lab ":" h ";" m "}"
--   | Efq ::= "λ{}"
--   | Eql ::= "{" a "==" b ":" T "}"
--   | Rfl ::= "{==}"
--   | Rwt ::= "%" e ":" k "," k "=>" P ";" f  # J: P binds x, h : {a == x}
--   q    ::= "-" | "" | "+"                # 0, 1, 2
--   Def  ::= ["opaque"] k ":" T "=" v

-- Types
-- =====

inductive Quan where
  | Q0 | Q1 | Q2
  deriving DecidableEq, Repr, Inhabited

inductive Term where
  | Var (i : Nat)
  | Ref (k : String)
  | Ann (x T : Term)
  | Let (q : Quan) (v f : Term)
  | Typ (q : Quan)
  | All (q : Quan) (A B : Term)
  | Lam (q : Quan) (f : Term)
  | App (q : Quan) (f x : Term)
  | Sig (q : Quan) (A B : Term)
  | Tup (q : Quan) (a b : Term)
  | Prj (h : Term)
  | Enu (ks : List String)
  | Lab (k : String)
  | Mat (k : String) (h m : Term)
  | Efq
  | Eql (a b T : Term)
  | Rfl
  | Rwt (e P f : Term)
  deriving DecidableEq, Repr, Inhabited

open Quan Term

-- an opaque def (o) never unfolds; its body is a model, checked with
-- every def transparent, so no other def learns what it computes
structure Def where
  k : String
  T : Term
  v : Term
  o : Bool
  deriving Inhabited

-- a Book lists defs; a def's index orders its live calls
abbrev Book := List Def

-- a Lib maps a name to its def: the checker's fast Book.get
abbrev Lib := Std.HashMap String Def

-- a Ctx lists, innermost first, each variable's type and let value
abbrev Ctx := List (Term × Option Term)

-- an Env lists, innermost first, the values a case tree's λs bound
abbrev Env := List Term

-- an Arg is one spine argument and its quantity
abbrev Arg := Quan × Term

-- a Step is where a walk goes on: a term, its environment and spine
abbrev Step := Term × Env × List Arg

abbrev Ren := Nat → Nat

abbrev Subst := Nat → Term

abbrev Res := Except String

-- a Tag says a variable is the piece of column j at a path: each step,
-- innermost first, takes a pair's first (false) or second (true) field
abbrev Tag := Option (Nat × List Bool)

-- a Guard carries a def's book, its own index, column liveness, var
-- tags, and the labels its matches hit, with their columns and paths
structure Guard where
  book : Book
  self : Nat
  cols : List Bool
  tags : List Tag
  hits : List ((Nat × List Bool) × String)

abbrev Parse := StateT (List Char) (Except String)

-- Constants
-- =========

-- the step budget of each wnf, conv and check; a native build at -O3
-- runs it within a 4 GB stack (LEAN_STACK_SIZE_KB=4194304)
def FUEL : Nat := 400000000

-- Quan
-- ====

def Quan.live : Quan → Bool
  | Q0 => false
  | _  => true

-- the quantity of a pair's first field, when the pair is used at q
def Quan.fld : Quan → Quan → Quan
  | Q0, _ => Q0
  | Q1, q => q
  | Q2, _ => Q2

-- the kind a q binder's domain needs, inside a type of kind g
def Quan.kind : Quan → Quan → Quan
  | Q0, _ => Q1
  | Q1, g => g
  | Q2, _ => Q2

-- the quantity a λ+ steps to in Par: q=2 only says how a λ runs (it
-- copies), so a λ+ converts as a λ
def Quan.lin : Quan → Quan
  | Q2 => Q1
  | q  => q

-- a q binder allows n live uses
def Quan.allows : Quan → Nat → Bool
  | Q0, n => n == 0
  | Q1, n => n ≤ 1
  | Q2, _ => true

-- Ren
-- ===

def Ren.up (r : Ren) : Nat → Nat
  | 0     => 0
  | i + 1 => r i + 1

-- moves variable v to index 0, under a new binder
def Ren.pick (v i : Nat) : Nat :=
  if i == v then 0 else i + 1

-- Term
-- ====

def Term.ren (r : Ren) : Term → Term
  | Var i => Var (r i)
  | Ref k => Ref k
  | Ann x T =>
    let x := Term.ren r x
    let T := Term.ren r T
    Ann x T
  | Let q v f =>
    let v := Term.ren r v
    let f := Term.ren (Ren.up r) f
    Let q v f
  | Typ q => Typ q
  | All q A B =>
    let A := Term.ren r A
    let B := Term.ren (Ren.up r) B
    All q A B
  | Lam q f =>
    let f := Term.ren (Ren.up r) f
    Lam q f
  | App q f x =>
    let f := Term.ren r f
    let x := Term.ren r x
    App q f x
  | Sig q A B =>
    let A := Term.ren r A
    let B := Term.ren (Ren.up r) B
    Sig q A B
  | Tup q a b =>
    let a := Term.ren r a
    let b := Term.ren r b
    Tup q a b
  | Prj h =>
    let h := Term.ren r h
    Prj h
  | Enu ks => Enu ks
  | Lab k => Lab k
  | Mat k h m =>
    let h := Term.ren r h
    let m := Term.ren r m
    Mat k h m
  | Efq => Efq
  | Eql a b T =>
    let a := Term.ren r a
    let b := Term.ren r b
    let T := Term.ren r T
    Eql a b T
  | Rfl => Rfl
  | Rwt e P f =>
    let e := Term.ren r e
    let P := Term.ren (Ren.up (Ren.up r)) P
    let f := Term.ren r f
    Rwt e P f

def Term.spine (t : Term) : List Arg → Term
  | []           => t
  | (q, x) :: xs => Term.spine (App q t x) xs

def Term.unspine : Term → List Arg → Term × List Arg
  | App q f x, xs => Term.unspine f ((q, x) :: xs)
  | t,         xs => (t, xs)

-- a λ or a λ-match: a node of a case tree, which takes an argument
def Term.takes : Term → Bool
  | Lam _ _   => true
  | Prj _     => true
  | Mat _ _ _ => true
  | Efq       => true
  | _         => false

-- an argument as it enters a type: a λ goes annotated, so its calls infer
def Term.arg (x A : Term) : Term :=
  if Term.takes x then Ann x A else x

-- a former whose parts may bind a variable
def Term.binds : Term → Bool
  | All .. | Lam .. | Sig .. | Rwt .. => true
  | _ => false

-- a node of a case tree: a λ, a λ-match, or a spine of one on a variable
def Term.node : Term → Bool
  | App _ f (Var _) => Term.takes (Term.unspine f []).1
  | t               => Term.takes t

-- Subst
-- =====

def Subst.up (s : Subst) : Nat → Term
  | 0     => Var 0
  | i + 1 => Term.ren Nat.succ (s i)

def Term.sub (s : Subst) : Term → Term
  | Var i => s i
  | Ref k => Ref k
  | Ann x T =>
    let x := Term.sub s x
    let T := Term.sub s T
    Ann x T
  | Let q v f =>
    let v := Term.sub s v
    let f := Term.sub (Subst.up s) f
    Let q v f
  | Typ q => Typ q
  | All q A B =>
    let A := Term.sub s A
    let B := Term.sub (Subst.up s) B
    All q A B
  | Lam q f =>
    let f := Term.sub (Subst.up s) f
    Lam q f
  | App q f x =>
    let f := Term.sub s f
    let x := Term.sub s x
    App q f x
  | Sig q A B =>
    let A := Term.sub s A
    let B := Term.sub (Subst.up s) B
    Sig q A B
  | Tup q a b =>
    let a := Term.sub s a
    let b := Term.sub s b
    Tup q a b
  | Prj h =>
    let h := Term.sub s h
    Prj h
  | Enu ks => Enu ks
  | Lab k => Lab k
  | Mat k h m =>
    let h := Term.sub s h
    let m := Term.sub s m
    Mat k h m
  | Efq => Efq
  | Eql a b T =>
    let a := Term.sub s a
    let b := Term.sub s b
    let T := Term.sub s T
    Eql a b T
  | Rfl => Rfl
  | Rwt e P f =>
    let e := Term.sub s e
    let P := Term.sub (Subst.up (Subst.up s)) P
    let f := Term.sub s f
    Rwt e P f

-- The CLI runs Term.sub as Term.subz (sub_subz): the same map, but it
-- passes the binder depth d down, so a value shifts once, not once per
-- binder, and a variable costs one lookup, not one per binder.

-- s under d binders
def Subst.lift (s : Subst) (d : Nat) (i : Nat) : Term :=
  if i < d then Var i else if d = 0 then s i else Term.ren (· + d) (s (i - d))

def Term.subk (s : Subst) (d : Nat) : Term → Term
  | Var i => Subst.lift s d i
  | Ref k => Ref k
  | Ann x T =>
    let x := Term.subk s d x
    let T := Term.subk s d T
    Ann x T
  | Let q v f =>
    let v := Term.subk s d v
    let f := Term.subk s (d + 1) f
    Let q v f
  | Typ q => Typ q
  | All q A B =>
    let A := Term.subk s d A
    let B := Term.subk s (d + 1) B
    All q A B
  | Lam q f =>
    let f := Term.subk s (d + 1) f
    Lam q f
  | App q f x =>
    let f := Term.subk s d f
    let x := Term.subk s d x
    App q f x
  | Sig q A B =>
    let A := Term.subk s d A
    let B := Term.subk s (d + 1) B
    Sig q A B
  | Tup q a b =>
    let a := Term.subk s d a
    let b := Term.subk s d b
    Tup q a b
  | Prj h =>
    let h := Term.subk s d h
    Prj h
  | Enu ks => Enu ks
  | Lab k => Lab k
  | Mat k h m =>
    let h := Term.subk s d h
    let m := Term.subk s d m
    Mat k h m
  | Efq => Efq
  | Eql a b T =>
    let a := Term.subk s d a
    let b := Term.subk s d b
    let T := Term.subk s d T
    Eql a b T
  | Rfl => Rfl
  | Rwt e P f =>
    let e := Term.subk s d e
    let P := Term.subk s (d + 2) P
    let f := Term.subk s d f
    Rwt e P f

def Term.subz (s : Subst) (t : Term) : Term :=
  Term.subk s 0 t

theorem up_ren : Ren.up r ∘ Ren.up s = Ren.up (r ∘ s) := by
  funext i; cases i <;> rfl

theorem ren_ren (t : Term) : Term.ren r (Term.ren s t) = Term.ren (r ∘ s) t := by
  induction t generalizing r s <;> simp [Term.ren, up_ren, *]

theorem subk_sub (t : Term) : Term.subk s d t = Term.sub (Subst.lift s d) t := by
  have up d : Subst.up (Subst.lift s d) = Subst.lift s (d + 1) := by
    funext i; cases i; rfl
    simp [Subst.up, Subst.lift]; split <;> (try split) <;> simp_all [Term.ren, ren_ren]; rfl
  induction t generalizing d <;> simp [Term.subk, Term.sub, *]

@[csimp] theorem sub_subz : @Term.sub = @Term.subz := by
  funext s t; rw [Term.subz, subk_sub]; rfl

def Subst.one (v : Term) : Nat → Term
  | 0     => v
  | i + 1 => Var i

-- a pair match's motive, at the pair of its two new variables
def Subst.tup (q : Quan) : Nat → Term
  | 0     => Tup q (Var 1) (Var 0)
  | i + 1 => Var (i + 2)

def Term.inst (f v : Term) : Term :=
  Term.sub (Subst.one v) f

-- Env
-- ===

def Env.sub : Env → Nat → Term
  | [],     i     => Var i
  | x :: _, 0     => x
  | _ :: e, i + 1 => Env.sub e i

-- Book
-- ====

def Book.get (bk : Book) (k : String) : Option Def :=
  bk.find? (·.k == k)

def Book.index (bk : Book) (k : String) : Option Nat :=
  bk.findIdx? (·.k == k)

-- (a def's first copy wins, as in Book.get)
def Lib.of (bk : Book) : Lib :=
  bk.foldr (fun d l => l.insert d.k d) {}

-- Ctx
-- ===

-- replaces each let variable by its value; every index stays
def Ctx.sub : Ctx → Nat → Term
  | [],               i     => Var i
  | (_, some v) :: c, 0     => Term.ren Nat.succ (Term.sub (Ctx.sub c) v)
  | (_, none) :: _,   0     => Var 0
  | _ :: c,           i + 1 => Term.ren Nat.succ (Ctx.sub c i)

-- (a context without lets leaves t as is)
def Ctx.zeta (c : Ctx) (t : Term) : Term :=
  if c.any (·.2.isSome) then Term.sub (Ctx.sub c) t else t

-- Guard
-- =====

def Guard.bind (g : Guard) (o : Tag) : Guard :=
  { g with tags := o :: g.tags }

-- the tag of the next argument of a case tree: a pending piece, or
-- a new column of the given liveness
def Guard.next (g : Guard) : List Tag → Bool → Tag × Guard × List Tag
  | p :: ps, _ => (p, g, ps)
  | [],      l =>
    let p := some (g.cols.length, [])
    let g := { g with cols := g.cols ++ [l] }
    (p, g, [])

-- Show
-- ====

def Quan.mark : Quan → String
  | Q0 => "-"
  | Q1 => ""
  | Q2 => "+"

def Quan.show : Quan → String
  | Q0 => "0"
  | Q1 => "1"
  | Q2 => "2"

-- the name of the variable bound at depth d
def Nat.name (d : Nat) : String :=
  "x" ++ toString d

def Term.show : Term → Nat → String
  | Var i, d => Nat.name (d - i - 1)
  | Ref k, _ => k
  | Ann x T, d =>
    let x := Term.show x d
    let T := Term.show T d
    "{" ++ x ++ " : " ++ T ++ "}"
  | Let q v f, d =>
    let v := Term.show v d
    let f := Term.show f (d + 1)
    "!" ++ Quan.mark q ++ Nat.name d ++ " = " ++ v ++ "; " ++ f
  | Typ q, _ => "*" ++ Quan.show q
  | All q A B, d =>
    let A := Term.show A d
    let B := Term.show B (d + 1)
    "∀" ++ Quan.mark q ++ Nat.name d ++ " : " ++ A ++ " -> " ++ B
  | Lam q f, d =>
    let f := Term.show f (d + 1)
    "λ" ++ Quan.mark q ++ Nat.name d ++ " => " ++ f
  | App q f x, d =>
    let f := Term.show f d
    let x := Term.show x d
    "(" ++ f ++ " " ++ Quan.mark q ++ x ++ ")"
  | Sig q A B, d =>
    let A := Term.show A d
    let B := Term.show B (d + 1)
    "Σ" ++ Quan.mark q ++ Nat.name d ++ " : " ++ A ++ " -> " ++ B
  | Tup q a b, d =>
    let a := Term.show a d
    let b := Term.show b d
    "(" ++ Quan.mark q ++ a ++ ", " ++ b ++ ")"
  | Prj h, d =>
    let h := Term.show h d
    "λ{(,): " ++ h ++ "}"
  | Enu ks, _ => "<" ++ ", ".intercalate ks ++ ">"
  | Lab k, _ => if k == "()" then k else "." ++ k
  | Mat k h m, d =>
    let k := if k == "()" then k else "." ++ k
    let h := Term.show h d
    let m := Term.show m d
    "λ{" ++ k ++ ": " ++ h ++ "; " ++ m ++ "}"
  | Efq, _ => "λ{}"
  | Eql a b T, d =>
    let a := Term.show a d
    let b := Term.show b d
    let T := Term.show T d
    "{" ++ a ++ " == " ++ b ++ " : " ++ T ++ "}"
  | Rfl, _ => "{==}"
  | Rwt e P f, d =>
    let e := Term.show e d
    let P := Term.show P (d + 2)
    let f := Term.show f d
    "%" ++ e ++ " : " ++ Nat.name d ++ ", " ++ Nat.name (d + 1) ++ " => " ++ P ++ "; " ++ f

-- Parser
-- ======

def Parse.fail (e : String) : Parse α := do
  let s ← get
  let s := String.ofList (s.take 30)
  throw ("parse error: expected " ++ e ++ " at '" ++ s ++ "'")

partial def Parse.skip : Parse Unit := do
  match ← get with
  | '#' :: s =>
    set (s.dropWhile (· != '\n'))
    Parse.skip
  | c :: s =>
    if c.isWhitespace then
      set s
      Parse.skip
  | [] => pure ()

def Parse.peek : Parse Char := do
  Parse.skip
  match ← get with
  | c :: _ => pure c
  | []     => pure ' '

def Parse.take (w : String) : Parse Bool := do
  Parse.skip
  let s ← get
  if w.toList.isPrefixOf s then
    set (s.drop w.length)
    pure true
  else
    pure false

def Parse.eat (w : String) : Parse Unit := do
  let ok ← Parse.take w
  if !ok then
    Parse.fail ("'" ++ w ++ "'")

def Char.is_name (c : Char) : Bool :=
  c.isAlphanum || c == '_' || c == '.'

def Parse.name : Parse String := do
  Parse.skip
  let s ← get
  let k := s.takeWhile Char.is_name
  if k.isEmpty then
    Parse.fail "a name"
  set (s.drop k.length)
  pure (String.ofList k)

-- a label name: a name, or ()
def Parse.label : Parse String := do
  if ← Parse.take "()" then
    return "()"
  Parse.name

-- a label key: .k or ()
def Parse.key : Parse String := do
  if ← Parse.take "()" then
    return "()"
  Parse.eat "."
  Parse.name

def Quan.parse : Parse Quan := do
  if ← Parse.take "-" then
    return Q0
  if ← Parse.take "+" then
    return Q2
  return Q1

mutual

partial def Term.parse (vs : List String) : Parse Term := do
  match ← Parse.peek with
  | '{' => Term.parse_brace vs
  | '*' => Term.parse_typ
  | '!' => Term.parse_let vs
  | '∀' => Term.parse_bind vs "∀"
  | 'Σ' => Term.parse_bind vs "Σ"
  | 'λ' => Term.parse_lam vs
  | '(' => Term.parse_paren vs
  | '<' => Term.parse_enum []
  | '.' => Lab <$> Parse.key
  | '%' => Term.parse_rwt vs
  | _   => Term.parse_name vs

partial def Term.parse_name (vs : List String) : Parse Term := do
  let k ← Parse.name
  match vs.findIdx? (· == k) with
  | some i => return Var i
  | none   => return Ref k

partial def Term.parse_brace (vs : List String) : Parse Term := do
  Parse.eat "{"
  if ← Parse.take "==" then
    Parse.eat "}"
    return Rfl
  let a ← Term.parse vs
  if ← Parse.take "==" then
    let b ← Term.parse vs
    Parse.eat ":"
    let T ← Term.parse vs
    Parse.eat "}"
    return Eql a b T
  Parse.eat ":"
  let T ← Term.parse vs
  Parse.eat "}"
  return Ann a T

partial def Term.parse_typ : Parse Term := do
  Parse.eat "*"
  if ← Parse.take "2" then
    return Typ Q2
  Parse.eat "1"
  return Typ Q1

partial def Term.parse_let (vs : List String) : Parse Term := do
  Parse.eat "!"
  let q ← Quan.parse
  let k ← Parse.name
  Parse.eat "="
  let v ← Term.parse vs
  Parse.eat ";"
  let f ← Term.parse (k :: vs)
  return Let q v f

partial def Term.parse_bind (vs : List String) (c : String) : Parse Term := do
  Parse.eat c
  let q ← Quan.parse
  let k ← Parse.name
  Parse.eat ":"
  let A ← Term.parse vs
  Parse.eat "->"
  let B ← Term.parse (k :: vs)
  return if c == "∀" then All q A B else Sig q A B

partial def Term.parse_lam (vs : List String) : Parse Term := do
  Parse.eat "λ"
  if ← Parse.take "{" then
    Term.parse_match vs
  else
    let q ← Quan.parse
    let k ← Parse.name
    Parse.eat "=>"
    let f ← Term.parse (k :: vs)
    return Lam q f

partial def Term.parse_match (vs : List String) : Parse Term := do
  if ← Parse.take "}" then
    return Efq
  if ← Parse.take "(,)" then
    Parse.eat ":"
    let h ← Term.parse vs
    Parse.eat "}"
    return Prj h
  let k ← Parse.key
  Parse.eat ":"
  let h ← Term.parse vs
  Parse.eat ";"
  let m ← Term.parse vs
  Parse.eat "}"
  return Mat k h m

partial def Term.parse_paren (vs : List String) : Parse Term := do
  Parse.eat "("
  if ← Parse.take ")" then
    return Lab "()"
  let q ← Quan.parse
  let a ← Term.parse vs
  if ← Parse.take "," then
    let b ← Term.parse_tup vs
    return Tup q a b
  else if q == Q1 then
    Term.parse_args vs a
  else
    Parse.fail "a pair after a quantity mark"

-- the rest of a tuple, after a ","
partial def Term.parse_tup (vs : List String) : Parse Term := do
  let q ← Quan.parse
  let a ← Term.parse vs
  if ← Parse.take "," then
    let b ← Term.parse_tup vs
    return Tup q a b
  else if q == Q1 then
    Parse.eat ")"
    return a
  else
    Parse.fail "a pair after a quantity mark"

partial def Term.parse_args (vs : List String) (f : Term) : Parse Term := do
  if ← Parse.take ")" then
    return f
  let q ← Quan.parse
  let x ← Term.parse vs
  Term.parse_args vs (App q f x)

partial def Term.parse_enum (ks : List String) : Parse Term := do
  if ks.isEmpty then
    Parse.eat "<"
  if ← Parse.take ">" then
    return Enu ks.reverse
  let k ← Parse.label
  if ks.contains k then
    Parse.fail "a fresh label"
  let _ ← Parse.take ","
  Term.parse_enum (k :: ks)

partial def Term.parse_rwt (vs : List String) : Parse Term := do
  Parse.eat "%"
  let e ← Term.parse vs
  Parse.eat ":"
  let x ← Parse.name
  Parse.eat ","
  let h ← Parse.name
  Parse.eat "=>"
  let P ← Term.parse (h :: x :: vs)
  Parse.eat ";"
  let f ← Term.parse vs
  return Rwt e P f

end

partial def Book.parse_defs : Parse Book := do
  Parse.skip
  if (← getThe (List Char)).isEmpty then
    return []
  let k ← Parse.name
  let o := k == "opaque" && (← Parse.peek) != ':'
  let k ← if o then Parse.name else pure k
  Parse.eat ":"
  let T ← Term.parse []
  Parse.eat "="
  let v ← Term.parse []
  let ds ← Book.parse_defs
  return ⟨k, T, v, o⟩ :: ds

def Book.parse (s : String) : Res Book :=
  Book.parse_defs.run' s.toList

-- Evaluator
-- =========

-- wnf reduces a head on a spine. A λ or a λ-match fires on its next
-- argument; a def unfolds only when it is not opaque and its case tree
-- takes the whole walk (run), else the call stays, so a stuck call
-- folds back to itself. Each takes fuel and returns the fuel it left,
-- so one budget bounds all the work. A caller goes on with min m n, as
-- Lean needs to see the fuel shrink (m ≤ n holds anyway).
-- On a closed term (cl), a q=2 let value or argument, which is Data,
-- goes to normal form (val) before it is bound, so its copies share the
-- work. An open term stays lazy: its stuck parts can grow without end.

mutual

def Term.wnf (ck : Lib) (cl : Bool) : Nat → Term → List Arg → Term × Nat
  | 0, t, xs => (Term.spine t xs, 0)
  | n + 1, Ann x _, xs => Term.wnf ck cl n x xs
  | n + 1, Let q v f, xs =>
    let (v, m) := Term.val ck cl n q v
    Term.wnf ck cl (min m n) (Term.inst f v) xs
  | n + 1, App q f x, xs => Term.wnf ck cl n f ((q, x) :: xs)
  | n + 1, Rwt e P f, xs =>
    match Term.wnf ck cl n e [] with
    | (Rfl, m) => Term.wnf ck cl (min m n) f xs
    | (e, m)   => (Term.spine (Rwt e P f) xs, m)
  | n + 1, Ref k, xs =>
    match ck[k]? with
    | some ⟨_, _, v, false⟩ =>
      match Term.run ck cl n v [] xs with
      | (some t, m) => Term.wnf ck cl (min m n) t []
      | (none, m)   => (Term.spine (Ref k) xs, m)
    | _ => (Term.spine (Ref k) xs, n)
  | n + 1, t, xs =>
    match Term.fire ck cl n t [] xs with
    | (some (t, e, xs), m) =>
      let t := Term.sub (Env.sub e) t
      Term.wnf ck cl (min m n) t xs
    | (none, m) => (Term.spine t xs, m)

-- walks a def's case tree on a spine, binding its variables in the
-- environment e: some leaf when the walk leaves the tree
def Term.run (ck : Lib) (cl : Bool) : Nat → Term → Env → List Arg → Option Term × Nat
  | 0, _, _, _ => (none, 0)
  | n + 1, App q f (Var v), e, xs =>
    if Term.takes (Term.unspine f []).1 then
      Term.run ck cl n f e ((q, Env.sub e v) :: xs)
    else
      let t := Term.sub (Env.sub e) (App q f (Var v))
      let t := Term.spine t xs
      (some t, n)
  | n + 1, t, e, xs =>
    match Term.fire ck cl n t e xs with
    | (some (t, e, xs), m) => Term.run ck cl (min m n) t e xs
    | (none, m) =>
      if Term.takes t then
        (none, m)
      else
        let t := Term.sub (Env.sub e) t
        let t := Term.spine t xs
        (some t, m)

-- fires a λ or a λ-match on its next argument; a λ binds it in e
def Term.fire (ck : Lib) (cl : Bool) : Nat → Term → Env → List Arg → Option Step × Nat
  | n + 1, Lam q f, e, (_, x) :: xs =>
    let (x, m) := Term.val ck cl n q x
    (some (f, x :: e, xs), m)
  | n + 1, Prj h, e, (q, x) :: xs =>
    match Term.wnf ck cl n x [] with
    | (Tup r a b, n) =>
      let xs := (Quan.fld r q, a) :: (q, b) :: xs
      (some (h, e, xs), n)
    | (_, n)         => (none, n)
  | n + 1, Mat k h m, e, (q, x) :: xs =>
    match Term.wnf ck cl n x [] with
    | (Lab j, n) =>
      if j == k then
        (some (h, e, xs), n)
      else
        (some (m, e, (q, Lab j) :: xs), n)
    | (_, n)     => (none, n)
  | n, _, _, _ => (none, n)

-- a value bound at q: on a closed term, a q=2 one goes to normal form
def Term.val (ck : Lib) : Bool → Nat → Quan → Term → Term × Nat
  | true, n + 1, Q2, t =>
    match Term.wnf ck true n t [] with
    | (Tup q a b, m) =>
      let (a, m) := Term.val ck true (min m n) (Quan.fld q Q2) a
      let (b, m) := Term.val ck true (min m n) Q2 b
      (Tup q a b, m)
    | r => r
  | _, n, _, t => (t, n)

end

def Ctx.wnf (ck : Lib) (c : Ctx) (t : Term) : Term :=
  (Term.wnf ck c.isEmpty FUEL (Ctx.zeta c t) []).1

-- Equality
-- ========

-- the parts two weak heads must match on: the children of one former,
-- as pairs; none when the heads differ. Two λs match at one liveness,
-- as they type
def Term.parts : Term → Term → Option (List (Term × Term))
  | All q A B, All p C D => if q = p then some [(A, C), (B, D)] else none
  | Lam q f,   Lam p g   => if q.live = p.live then some [(f, g)] else none
  | App q f x, App p g y => if q = p then some [(f, g), (x, y)] else none
  | Sig q A B, Sig p C D => if q = p then some [(A, C), (B, D)] else none
  | Tup q a b, Tup p c d => if q = p then some [(a, c), (b, d)] else none
  | Prj h,     Prj g     => some [(h, g)]
  | Mat k h m, Mat j g n => if k = j then some [(h, g), (m, n)] else none
  | Eql a b T, Eql c d U => some [(a, c), (b, d), (T, U)]
  | Rwt e P f, Rwt d Q g => some [(e, d), (P, Q), (f, g)]
  | a,         b         => if a = b then some [] else none

-- a and b convert, lazily: they are equal, or their weak heads match
-- and each pair of parts converts, in turn. Returns the fuel left:
-- 0 when it ran out. A binder's parts may be open.
def Term.conv (ck : Lib) (cl : Bool) : Nat → Term → Term → Bool × Nat
  | 0, _, _ => (false, 0)
  | n + 1, a, b =>
    if a = b then
      (true, n)
    else
      let (a, m) := Term.wnf ck cl n a []
      let (b, m) := Term.wnf ck cl (min m n) b []
      match Term.parts a b with
      | some ps =>
        let go := fun (r : Bool × Nat) (p : Term × Term) =>
          if r.1 then Term.conv ck (cl && !Term.binds a) (min r.2 n) p.1 p.2 else r
        ps.foldl go (true, min m n)
      | none => (false, m)

-- U fits T: they convert, or U is Data and T a kind, or U is an enum
-- with fewer labels
def Term.fits (ck : Lib) (cl : Bool) (U T : Term) : Bool × Nat :=
  let (U, n) := Term.wnf ck cl FUEL U []
  let (T, n) := Term.wnf ck cl n T []
  match U, T with
  | Typ Q2, Typ _  => (true, n)
  | Enu ks, Enu js => (ks.all js.contains, n)
  | U,      T      => Term.conv ck cl n U T

-- Checker
-- =======

def Res.need (ok : Bool) (e : String) : Res Unit :=
  if ok then pure () else throw e

def Ctx.fail (c : Ctx) (x : String) (o : Term) : Res α :=
  let o := Term.show (Ctx.zeta c o) c.length
  throw ("expected: " ++ x ++ "\nobserved: " ++ o)

-- passes when r holds; else fails as out of fuel, or on the mismatch
def Ctx.need (c : Ctx) (r : Bool × Nat) (x : String) (o : Term) : Res Unit :=
  match r with
  | (true, _) => pure ()
  | (_, 0)    => throw "out of fuel"
  | _         => Ctx.fail c x o

def Ctx.fit (ck : Lib) (c : Ctx) (U T : Term) : Res Unit :=
  let U := Ctx.zeta c U
  let T := Ctx.zeta c T
  Ctx.need c (Term.fits ck c.isEmpty U T) (Term.show T c.length) U

mutual

-- Γ[i] = A              Book[k] = T         Γ ⊢ T : *1   Γ ⊢ x : T
-- ----------- var       ----------- ref     ---------------------- ann
-- Γ ⊢ i : A             Γ ⊢ k : T           Γ ⊢ {x : T} : T
--
-- Γ ⊢ A : *kind(q)   Γ, A ⊢ B : *1       Γ ⊢ f : ∀q x:A -> B   Γ ⊢ a : A
-- ------------------------------ all    ---------------------------- app
-- Γ ⊢ ∀q x:A -> B : *1                   Γ ⊢ (f q a) : B[a]
--
-- ------------ typ    ------------ enu    Γ ⊢ T : *1   Γ ⊢ a, b : T
-- Γ ⊢ *q : *1         Γ ⊢ <ks> : *2       ------------------------ eql
--                                         Γ ⊢ {a == b : T} : *2
def Term.infer (ck : Lib) : Nat → Ctx → Term → Res Term
  | 0, _, _ => throw "out of fuel"
  | _ + 1, c, Var i =>
    match c[i]? with
    | some (A, _) => pure (Term.ren (· + (i + 1)) A)
    | none        => throw "unbound variable"
  | _ + 1, _, Ref k =>
    match ck[k]? with
    | some d => pure d.T
    | none   => throw ("unknown def: " ++ k)
  | n + 1, c, Ann x T => do
    Term.check ck n c T (Typ Q1)
    Term.check ck n c x T
    pure T
  | _ + 1, _, Typ _ => pure (Typ Q1)
  | n + 1, c, All q A B => do
    Term.check ck n c A (Typ (Quan.kind q Q1))
    Term.check ck n ((A, none) :: c) B (Typ Q1)
    pure (Typ Q1)
  | n + 1, c, App q f x => do
    let F ← Term.infer ck n c f
    match Ctx.wnf ck c F with
    | All p A B => do
      Res.need (p == q) "an argument of its binder's quantity"
      Term.check ck n c x A
      pure (Term.inst B (Term.arg x A))
    | F => Ctx.fail c "a function" F
  | _ + 1, _, Enu _ => pure (Typ Q2)
  | n + 1, c, Eql a b T => do
    Term.check ck n c T (Typ Q1)
    Term.check ck n c a T
    Term.check ck n c b T
    pure (Typ Q2)
  | _ + 1, c, t => Ctx.fail c "an annotated term" t

-- Γ ⊢ v : V   V : *2 if q=2   Γ, V := v ⊢ f : T
-- -------------------------------------------- let
-- Γ ⊢ !q x = v; f : T
--
-- T = ∀p x:A -> B   live p = live q   A : *2 if q=2   Γ, A ⊢ f : B
-- ---------------------------------------------------------- lam
-- Γ ⊢ λq x => f : T
--
-- T = *g   Γ ⊢ A : *kind(q, g)   Γ, A ⊢ B : *g
-- ------------------------------------------- sig
-- Γ ⊢ Σq x:A -> B : T
--
-- T = Σq x:A -> B   Γ ⊢ a : A   Γ ⊢ b : B[a]      T = <ks>   k ∈ ks
-- ------------------------------------ tup     ---------------- lab
-- Γ ⊢ (q a, b) : T                              Γ ⊢ .k : T
--
-- T = ∀q s:(Σr x:A -> B) -> P   live q
-- Γ ⊢ h : ∀fld(r, q) x:A -> ∀q y:B -> P[(r x, y)]
-- ---------------------------------------------- prj
-- Γ ⊢ λ{(,): h} : T
--
-- T = ∀q s:<ks> -> P   live q   k ∈ ks
-- Γ ⊢ h : P[.k]   Γ ⊢ m : ∀q s:<ks - k> -> P
-- ----------------------------------------- mat
-- Γ ⊢ λ{.k: h; m} : T
--
-- T = ∀q s:<> -> P   live q       T = {a == b : A}   a ≡ b
-- ------------------------ efq    ----------------------- rfl
-- Γ ⊢ λ{} : T                     Γ ⊢ {==} : T
--
-- Γ ⊢ e : {a == b : A}   Γ, x : A, h : {a == x : A} ⊢ P : *1
-- P[b, e] ≤ T   Γ ⊢ f : P[a, {==}]
-- ------------------------------------------------------- rwt
-- Γ ⊢ %e : x, h => P; f : T
--
-- Γ ⊢ x : A   Γ ⊢ f : ∀q s:A -> T[x := s]    f's head is a λ or a λ-match
-- -------------------------------------------------------------- elim
-- Γ ⊢ (f q x) : T
--
-- Γ ⊢ x : U   U ≤ T
-- ----------------- any
-- Γ ⊢ x : T
def Term.check (ck : Lib) : Nat → Ctx → Term → Term → Res Unit
  | 0, _, _, _ => throw "out of fuel"
  | n + 1, c, Let q v f, T => do
    let V := Ctx.wnf ck c (← Term.infer ck n c v)
    if q == Q2 then
      Term.check ck n c V (Typ Q2)
    Term.check ck n ((V, some v) :: c) f (Term.ren Nat.succ T)
  | n + 1, c, Lam q f, T =>
    match Ctx.wnf ck c T with
    | All p A B => do
      let A := Ctx.wnf ck c A
      Res.need (Quan.live p == Quan.live q) "a λ of its binder's liveness"
      if q == Q2 then
        Term.check ck n c A (Typ Q2)
      Term.check ck n ((A, none) :: c) f B
    | T => Ctx.fail c "a function type" T
  | n + 1, c, Sig q A B, T =>
    match Ctx.wnf ck c T with
    | Typ g => do
      Term.check ck n c A (Typ (Quan.kind q g))
      Term.check ck n ((A, none) :: c) B (Typ g)
    | T => Ctx.fail c "a kind" T
  | n + 1, c, Tup q a b, T =>
    match Ctx.wnf ck c T with
    | Sig p A B => do
      Res.need (p == q) "a field of its Σ's quantity"
      Term.check ck n c a A
      Term.check ck n c b (Term.inst B a)
    | T => Ctx.fail c "a Σ type" T
  | _ + 1, c, Lab k, T =>
    match Ctx.wnf ck c T with
    | Enu ks => Res.need (ks.contains k) ("a label of " ++ Term.show (Enu ks) 0)
    | T      => Ctx.fail c "an enum" T
  | n + 1, c, Prj h, T =>
    match Ctx.wnf ck c T with
    | All q D P =>
      match Ctx.wnf ck c D with
      | Sig r A B => do
        Res.need (Quan.live q) "a live scrutinee"
        let P := Term.sub (Subst.tup r) P
        Term.check ck n c h (All (Quan.fld r q) A (All q B P))
      | D => Ctx.fail c "a Σ type" D
    | T => Ctx.fail c "a function type" T
  | n + 1, c, Mat k h m, T =>
    match Ctx.wnf ck c T with
    | All q D P =>
      match Ctx.wnf ck c D with
      | Enu ks => do
        Res.need (Quan.live q) "a live scrutinee"
        Res.need (ks.contains k) ("a label of " ++ Term.show (Enu ks) 0)
        Term.check ck n c h (Term.inst P (Lab k))
        Term.check ck n c m (All q (Enu (ks.erase k)) P)
      | D => Ctx.fail c "an enum" D
    | T => Ctx.fail c "a function type" T
  | _ + 1, c, Efq, T =>
    match Ctx.wnf ck c T with
    | All q D _ =>
      match Ctx.wnf ck c D with
      | Enu [] => Res.need (Quan.live q) "a live scrutinee"
      | D      => Ctx.fail c "an empty enum" D
    | T => Ctx.fail c "a function type" T
  | _ + 1, c, Rfl, T =>
    match Ctx.wnf ck c T with
    | Eql a b _ => Ctx.need c (Term.conv ck c.isEmpty FUEL a b) (Term.show a c.length) b
    | T => Ctx.fail c "an equation" T
  | n + 1, c, Rwt e P f, T => do
    let E ← Term.infer ck n c e
    match Ctx.wnf ck c E with
    | Eql a b A => do
      let E := Eql (Term.ren Nat.succ a) (Var 0) (Term.ren Nat.succ A)
      Term.check ck n ((E, none) :: (A, none) :: c) P (Typ Q1)
      Ctx.fit ck c (Term.inst (Term.inst P (Term.ren Nat.succ e)) b) T
      Term.check ck n c f (Term.inst (Term.inst P Rfl) a)
    | E => Ctx.fail c "an equation" E
  | n + 1, c, App q f (Var i), T =>
    if Term.takes (Term.unspine f []).1 then do
      let A ← Term.infer ck n c (Var i)
      let P := Term.ren (Ren.pick i) T
      Term.check ck n c f (All q A P)
    else do
      let U ← Term.infer ck n c (App q f (Var i))
      Ctx.fit ck c U T
  | n + 1, c, t, T => do
    let U ← Term.infer ck n c t
    Ctx.fit ck c U T

end

-- Termination
-- ===========

-- The live check reads only the live part. A binder's variable is used
-- live at most as its quantity allows (Term.uses); the two arms of a
-- match add up. A def's case tree gives each variable it binds a tag:
-- a column j and a path into it; a λ-match on a tagged variable splits
-- it into pieces one step deeper, or hits a label, which the guard
-- records. A live call must name an earlier def, or its own def with
-- arguments that descend: compared left to right, each live column gets
-- a rebuild of itself (eq) until one gets a rebuild of a piece of itself
-- (lt). A rebuild is a tagged variable, a hit label, or a live pair of
-- the two pieces of one split. Dead columns are skipped.

-- the live uses of variable i in t
def Term.uses : Term → Nat → Nat
  | Var j, i => if i == j then 1 else 0
  | Ann x _, i => Term.uses x i
  | Let q v f, i =>
    let v := if Quan.live q then Term.uses v i else 0
    let f := Term.uses f (i + 1)
    v + f
  | Lam _ f, i => Term.uses f (i + 1)
  | App q f x, i =>
    let f := Term.uses f i
    let x := if Quan.live q then Term.uses x i else 0
    f + x
  | Tup q a b, i =>
    let a := if Quan.live q then Term.uses a i else 0
    let b := Term.uses b i
    a + b
  | Prj h, i => Term.uses h i
  | Mat _ h m, i =>
    let h := Term.uses h i
    let m := Term.uses m i
    h + m
  | Rwt e _ f, i =>
    let e := Term.uses e i
    let f := Term.uses f i
    e + f
  | _, _ => 0

-- the paths of the pieces of column j that x rebuilds
def Term.pos (g : Guard) (j : Nat) : Term → List (List Bool)
  | Var v =>
    match g.tags[v]? with
    | some (some (c, π)) => if c == j then [π] else []
    | _                  => []
  | Lab k =>
    g.hits.filterMap fun ((c, π), l) =>
      if c == j && l == k then some π else none
  | Tup q a b =>
    let a := Term.pos g j a
    let b := Term.pos g j b
    let b := b.filterMap fun
      | true :: π => if a.contains (false :: π) then some π else none
      | _         => none
    if Quan.live q then b else []
  | _ => []

-- how the argument x at column j compares to that column: x rebuilds
-- the column (eq), or a piece of it (lt)
def Term.piece (g : Guard) (j : Nat) (x : Term) : Ordering :=
  let ps := Term.pos g j x
  if ps.contains [] then .eq else if ps.isEmpty then .gt else .lt

def Arg.cmp (g : Guard) (j : Nat) : Arg → Ordering
  | (q, x) =>
    if g.cols[j]? != some (Quan.live q) then
      .gt
    else if Quan.live q then
      Term.piece g j x
    else
      .eq

def Arg.descend (g : Guard) : Nat → List Arg → Ordering
  | _, [] => .eq
  | j, x :: xs =>
    match Arg.cmp g j x with
    | .eq => Arg.descend g (j + 1) xs
    | o   => o

-- a live call names an earlier def, or its own def on a descent
def Term.called (g : Guard) (t : Term) : Bool :=
  match Term.unspine t [] with
  | (Ref k, xs) =>
    match Book.index g.book k with
    | some j => j < g.self || (j == g.self && Arg.descend g 0 xs == .lt)
    | none   => false
  | _ => true

-- the live check of a term; top is false on the head of an App
def Term.live (g : Guard) : Bool → Term → Bool
  | top, App q f x =>
    let s := !top || Term.called g (App q f x)
    let f := Term.live g false f
    let x := !Quan.live q || Term.live g true x
    s && f && x
  | top, Ref k => !top || Term.called g (Ref k)
  | _, Ann x _ => Term.live g true x
  | _, Let q v f =>
    let a := Quan.allows q (Term.uses f 0)
    let v := !Quan.live q || Term.live g true v
    let f := Term.live (Guard.bind g none) true f
    a && v && f
  | _, Lam q f =>
    let a := Quan.allows q (Term.uses f 0)
    let f := Term.live (Guard.bind g none) true f
    a && f
  | _, Tup q a b =>
    let a := !Quan.live q || Term.live g true a
    let b := Term.live g true b
    a && b
  | _, Prj h => Term.live g true h
  | _, Mat _ h m =>
    let h := Term.live g true h
    let m := Term.live g true m
    h && m
  | _, Rwt e _ f =>
    let e := Term.live g true e
    let f := Term.live g true f
    e && f
  | _, _ => true

-- the live check of a def's case tree: ps are the pending arguments
def Term.tree (g : Guard) (ps : List Tag) : Term → Bool
  | Lam q f =>
    let (p, g, ps) := Guard.next g ps (Quan.live q)
    let a := Quan.allows q (Term.uses f 0)
    let f := Term.tree (Guard.bind g p) ps f
    a && f
  | Prj h =>
    let (p, g, ps) := Guard.next g ps true
    let a := p.map (fun (j, π) => (j, false :: π))
    let b := p.map (fun (j, π) => (j, true :: π))
    Term.tree g (a :: b :: ps) h
  | Mat k h m =>
    let (p, g, ps) := Guard.next g ps true
    let hits := p.toList.map (·, k) ++ g.hits
    let h := Term.tree { g with hits := hits } ps h
    let m := Term.tree g (p :: ps) m
    h && m
  | Efq => true
  | App q f (Var v) =>
    if Term.takes (Term.unspine f []).1 then
      Term.tree g ((g.tags[v]?).join :: ps) f
    else
      Term.live g true (App q f (Var v))
  | t => Term.live g true t

-- Validator
-- =========

def Def.check (bk : Book) (ls : Lib × Lib) (i : Nat) (d : Def) : Res Unit := do
  let ck := if d.o then ls.2 else ls.1
  Res.need (Book.index bk d.k == some i) "a fresh name"
  Term.check ck FUEL [] d.T (Typ Q1)
  Term.check ck FUEL [] d.v d.T
  Res.need (Term.ren Nat.succ d.v == d.v) "a closed def"
  let g : Guard := ⟨bk, i, [], [], []⟩
  Res.need (Term.tree g [] d.v) "affine live code, calls that descend"

-- ls holds bk, and bk with every def transparent
def Book.check_from (bk : Book) (ls : Lib × Lib) : Nat → List Def → Res Unit
  | _, [] => pure ()
  | i, d :: ds => do
    (Def.check bk ls i d).mapError (fun e => "In " ++ d.k ++ ":\n" ++ e)
    Book.check_from bk ls (i + 1) ds

def Book.check (bk : Book) : Res Unit :=
  Book.check_from bk (Lib.of bk, Lib.of (bk.map ({ · with o := false }))) 0 bk

-- Main
-- ====

def main (args : List String) : IO UInt32 := do
  match args with
  | [path] =>
    let s ← IO.FS.readFile path
    match Book.parse s >>= Book.check with
    | .ok _ =>
      IO.println "ALL PROOFS CHECK"
      pure 0
    | .error e =>
      IO.println ("SOME PROOFS FAIL\n" ++ e)
      pure 1
  | _ =>
    IO.println "usage: bendtt <file.bendtt>"
    pure 2

-- CLAIMS
-- ======
--
-- Part 2 states what Part 1's check guarantees. First the declarative
-- theory: parallel reduction (Par), its closure (Pars), conversion (Conv),
-- subsumption (Fits) and typing (Typed); the rules mirror the checker's,
-- one for one. Then the run-time semantics the proof uses: Data, values
-- (Value), the walk of a call through its def's case tree (Walk) and
-- call-by-value evaluation (Eval). Eval never runs a dead part, fires a
-- call only when its arguments walk the whole tree, and checks at run
-- time what types promise (a q=2 copy is Data, a λ-match gets a live
-- pair or label). The measure of the termination proof needs no types,
-- since these checks are in Eval; progress shows typed terms pass them.
-- Part 2 ignores the opaque flag: an opaque def unfolds to its model.

-- Reduction
-- ---------

def Term.Closed (t : Term) : Prop :=
  ∀ s : Subst, Term.sub s t = t

-- every def's body is closed
def Book.Closed (bk : Book) : Prop :=
  ∀ k d, Book.get bk k = some d → Term.Closed d.v

-- δ unfolds only a closed body, so Par commutes with substitution; a
-- λ+ steps to a λ and never back, so a step keeps types
inductive Par (bk : Book) : Term → Term → Prop
  | var   : Par bk (Var i) (Var i)
  | ref   : Par bk (Ref k) (Ref k)
  | ann   : Par bk x x' → Par bk T T' → Par bk (Ann x T) (Ann x' T')
  | lett  : Par bk v v' → Par bk f f' → Par bk (Let q v f) (Let q v' f')
  | typ   : Par bk (Typ q) (Typ q)
  | all   : Par bk A A' → Par bk B B' → Par bk (All q A B) (All q A' B')
  | lam   : Par bk f f' → (p = q ∨ p = q.lin) → Par bk (Lam q f) (Lam p f')
  | app   : Par bk f f' → Par bk x x' → Par bk (App q f x) (App q f' x')
  | sig   : Par bk A A' → Par bk B B' → Par bk (Sig q A B) (Sig q A' B')
  | tup   : Par bk a a' → Par bk b b' → Par bk (Tup q a b) (Tup q a' b')
  | prj   : Par bk h h' → Par bk (Prj h) (Prj h')
  | enu   : Par bk (Enu ks) (Enu ks)
  | lab   : Par bk (Lab k) (Lab k)
  | mat   : Par bk h h' → Par bk m m' → Par bk (Mat k h m) (Mat k h' m')
  | efq   : Par bk Efq Efq
  | eql   : Par bk a a' → Par bk b b' → Par bk T T' →
            Par bk (Eql a b T) (Eql a' b' T')
  | rfl   : Par bk Rfl Rfl
  | rwt   : Par bk e e' → Par bk P P' → Par bk f f' →
            Par bk (Rwt e P f) (Rwt e' P' f')
  | delta : Book.get bk k = some d → Term.Closed d.v → Par bk (Ref k) d.v
  | unann : Par bk x x' → Par bk (Ann x T) x'
  | unlet : Par bk v v' → Par bk f f' → Par bk (Let q v f) (Term.inst f' v')
  | beta  : Par bk f f' → Par bk x x' →
            Par bk (App q (Lam p f) x) (Term.inst f' x')
  | split : Par bk h h' → Par bk a a' → Par bk b b' →
            Par bk (App q (Prj h) (Tup r a b))
              (App q (App (Quan.fld r q) h' a') b')
  | hit   : Par bk h h' → Par bk (App q (Mat k h m) (Lab k)) h'
  | miss  : j ≠ k → Par bk m m' →
            Par bk (App q (Mat k h m) (Lab j)) (App q m' (Lab j))
  | cast  : Par bk f f' → Par bk (Rwt Rfl P f) f'

inductive Pars (bk : Book) : Term → Term → Prop
  | refl : Pars bk t t
  | step : Par bk t u → Pars bk u v → Pars bk t v

def Conv (bk : Book) (a b : Term) : Prop :=
  ∃ c, Pars bk a c ∧ Pars bk b c

-- U fits T: they convert, or U is Data and T a kind, or both are enums
-- and U's labels are T's
def Fits (bk : Book) (U T : Term) : Prop :=
  Conv bk U T
  ∨ (Conv bk U (Typ Q2) ∧ ∃ q, Conv bk T (Typ q))
  ∨ (∃ ks js, Conv bk U (Enu ks) ∧ Conv bk T (Enu js) ∧ ks ⊆ js)

-- Typing
-- ------

inductive Typed (bk : Book) : List Term → Term → Term → Prop
  | var  : Γ[i]? = some A → Typed bk Γ (Var i) (Term.ren (· + (i + 1)) A)
  -- any instance of a def's type: a checked def's type is closed
  | ref  : Book.get bk k = some d → Typed bk Γ (Ref k) (Term.sub σ d.T)
  | ann  : Typed bk Γ T (Typ Q1) → Typed bk Γ x T → Typed bk Γ (Ann x T) T
  | lett : Typed bk Γ v V → (q = Q2 → Typed bk Γ V (Typ Q2)) →
           Typed bk Γ (Term.inst f v) T → Typed bk Γ (Let q v f) T
  | typ  : Typed bk Γ (Typ q) (Typ Q1)
  | all  : Typed bk Γ A (Typ (Quan.kind q Q1)) → Typed bk (A :: Γ) B (Typ Q1) →
           Typed bk Γ (All q A B) (Typ Q1)
  | lam  : p.live = q.live → (q = Q2 → Typed bk Γ A (Typ Q2)) →
           Typed bk (A :: Γ) f B → Typed bk Γ (Lam q f) (All p A B)
  | app  : Typed bk Γ f (All q A B) → Typed bk Γ x A →
           Typed bk Γ (App q f x) (Term.inst B x)
  | sig  : Typed bk Γ A (Typ (Quan.kind q g)) → Typed bk (A :: Γ) B (Typ g) →
           Typed bk Γ (Sig q A B) (Typ g)
  | tup  : Typed bk Γ a A → Typed bk Γ b (Term.inst B a) →
           Typed bk Γ (Tup q a b) (Sig q A B)
  | prj  : q.live = true →
           Typed bk Γ h
             (All (Quan.fld r q) A (All q B (Term.sub (Subst.tup r) P))) →
           Typed bk Γ (Prj h) (All q (Sig r A B) P)
  | enu  : Typed bk Γ (Enu ks) (Typ Q2)
  | lab  : k ∈ ks → Typed bk Γ (Lab k) (Enu ks)
  | mat  : q.live = true → k ∈ ks → Typed bk Γ h (Term.inst P (Lab k)) →
           Typed bk Γ m (All q (Enu (ks.erase k)) P) →
           Typed bk Γ (Mat k h m) (All q (Enu ks) P)
  | efq  : q.live = true → Typed bk Γ Efq (All q (Enu []) P)
  | eql  : Typed bk Γ T (Typ Q1) → Typed bk Γ a T → Typed bk Γ b T →
           Typed bk Γ (Eql a b T) (Typ Q2)
  | rfl  : Conv bk a b → Typed bk Γ Rfl (Eql a b T)
  | rwt  : Typed bk Γ e (Eql a b A) →
           Typed bk (Eql (Term.ren Nat.succ a) (Var 0) (Term.ren Nat.succ A) :: A :: Γ) P (Typ Q1) →
           Fits bk (Term.inst (Term.inst P (Term.ren Nat.succ e)) b) T →
           Typed bk Γ f (Term.inst (Term.inst P Rfl) a) → Typed bk Γ (Rwt e P f) T
  | conv : Typed bk Γ t U → Fits bk U T → Typed bk Γ t T

-- every def's type is a type and its closed body has it
def Book.WellTyped (bk : Book) : Prop :=
  ∀ k d, Book.get bk k = some d →
    Typed bk [] d.T (Typ Q1) ∧ Typed bk [] d.v d.T ∧ Term.Closed d.v

-- every def is closed, and its case tree passed the live check at its
-- index
def Book.Live (bk : Book) : Prop :=
  Book.Closed bk ∧ ∀ k i d, Book.index bk k = some i → Book.get bk k = some d →
    Term.tree ⟨bk, i, [], [], []⟩ [] d.v = true

-- a live term outside the book: it may call any def
def Term.Live (bk : Book) (t : Term) : Prop :=
  Term.live ⟨bk, bk.length, [], [], []⟩ true t = true

-- Evaluation
-- ----------

-- Data: the live part holds labels, proofs and pairs, no λ, no call
inductive Data : Term → Prop
  | lab : Data (Lab k)
  | rfl : Data Rfl
  | tup : (q.live = true → Data a) → Data b → Data (Tup q a b)

-- a def's case tree walked on a spine, with an environment e for the
-- variables its λs bind: some leaf (under e, on the rest of the spine)
-- when it leaves the tree, none when it needs more arguments; the
-- walk never enters a substituted term, and never runs a dead part
inductive Walk (bk : Book) : Term → Env → List Arg → Option Term → Prop
  | lam  : p.live = q.live → (p = Q2 → Data x) →
           Walk bk f (x :: e) xs o → Walk bk (Lam p f) e ((q, x) :: xs) o
  | prj  : q.live = true →
           Walk bk h e ((Quan.fld r q, a) :: (q, b) :: xs) o →
           Walk bk (Prj h) e ((q, Tup r a b) :: xs) o
  | hit  : q.live = true → Walk bk h e xs o →
           Walk bk (Mat k h m) e ((q, Lab k) :: xs) o
  | miss : q.live = true → j ≠ k → Walk bk m e ((q, Lab j) :: xs) o →
           Walk bk (Mat k h m) e ((q, Lab j) :: xs) o
  | app  : Term.node (App q f (Var v)) = true →
           Walk bk f e ((q, Env.sub e v) :: xs) o →
           Walk bk (App q f (Var v)) e xs o
  | need : Term.takes t = true → Walk bk t e [] none
  | done : Term.node t = false →
           Walk bk t e xs (some (Term.spine (Term.sub (Env.sub e) t) xs))

mutual

inductive Value (bk : Book) : Term → Prop
  | lam  : Value bk (Lam q f)
  | prj  : Value bk (Prj h)
  | mat  : Value bk (Mat k h m)
  | efq  : Value bk Efq
  | lab  : Value bk (Lab k)
  | rfl  : Value bk Rfl
  | typ  : Value bk (Typ q)
  | all  : Value bk (All q A B)
  | sig  : Value bk (Sig q A B)
  | enu  : Value bk (Enu ks)
  | eql  : Value bk (Eql a b T)
  | tup  : (q.live = true → Value bk a) → Value bk b → Value bk (Tup q a b)
  | call : Book.get bk k = some d → Values bk xs → Walk bk d.v [] xs none →
           Value bk (Term.spine (Ref k) xs)

-- every live argument is a value
inductive Values (bk : Book) : List Arg → Prop
  | nil  : Values bk []
  | cons : (q.live = true → Value bk x) → Values bk xs →
           Values bk ((q, x) :: xs)

end

-- call-by-value evaluation of the live part
inductive Eval (bk : Book) : Term → Term → Prop
  | ann   : Eval bk (Ann x T) x
  | app_f : Eval bk f f' → Eval bk (App q f x) (App q f' x)
  | app_x : Value bk f → q.live = true → Eval bk x x' →
            Eval bk (App q f x) (App q f x')
  | beta  : p.live = q.live → (q.live = true → Value bk x) →
            (p = Q2 → Data x) → Eval bk (App q (Lam p f) x) (Term.inst f x)
  | split : q.live = true → Value bk (Tup r a b) →
            Eval bk (App q (Prj h) (Tup r a b))
              (App q (App (Quan.fld r q) h a) b)
  | hit   : q.live = true → Eval bk (App q (Mat k h m) (Lab k)) h
  | miss  : q.live = true → j ≠ k →
            Eval bk (App q (Mat k h m) (Lab j)) (App q m (Lab j))
  | call  : Book.get bk k = some d → Values bk xs → Walk bk d.v [] xs (some t) →
            Eval bk (Term.spine (Ref k) xs) t
  | lett  : q.live = true → Eval bk v v' → Eval bk (Let q v f) (Let q v' f)
  | unlet : (q.live = true → Value bk v) → (q = Q2 → Data v) →
            Eval bk (Let q v f) (Term.inst f v)
  | tup_a : q.live = true → Eval bk a a' → Eval bk (Tup q a b) (Tup q a' b)
  | tup_b : (q.live = true → Value bk a) → Eval bk b b' →
            Eval bk (Tup q a b) (Tup q a b')
  | rwt   : Eval bk e e' → Eval bk (Rwt e P f) (Rwt e' P f)
  | cast  : Eval bk (Rwt Rfl P f) f

-- Claims
-- ------

-- The main claim: no def of a checked book has type Empty (<>), even
-- up to conversion, so no checked def proves False. The claims below
-- are the steps of its proof.
def Claim.consistent : Prop :=
  ∀ bk k d, Book.check bk = .ok () → Book.get bk k = some d →
    ¬ Conv bk d.T (Enu [])

-- the checker is sound for the declarative theory and the live check
def Claim.sound : Prop :=
  ∀ bk, Book.check bk = .ok () → Book.WellTyped bk ∧ Book.Live bk

-- parallel reduction is confluent (Takahashi)
def Claim.confluent : Prop :=
  ∀ bk a b c, Pars bk a b → Pars bk a c → ∃ d, Pars bk b d ∧ Pars bk c d

-- subject reduction, anywhere, dead parts included
def Claim.sr : Prop :=
  ∀ bk Γ t u T, Book.WellTyped bk → Typed bk Γ t T → Par bk t u → Typed bk Γ u T

-- a closed typed term is a value, or it steps
def Claim.progress : Prop :=
  ∀ bk t T, Book.WellTyped bk → Book.Live bk → Typed bk [] t T →
    Value bk t ∨ ∃ u, Eval bk t u

-- live evaluation terminates; no types needed
def Claim.halts : Prop :=
  ∀ bk t, Book.Live bk → Term.Closed t → Term.Live bk t →
    Acc (fun u t => Eval bk t u) t

-- no value has type <>
def Claim.empty : Prop :=
  ∀ bk t, Book.WellTyped bk → Value bk t → ¬ Typed bk [] t (Enu [])

-- PROOF
-- =====
--
-- The route has no logical relation, no step index and no universe:
-- Takahashi confluence, syntactic subject reduction and progress, and an
-- untyped measure for live evaluation. Type : Type is harmless, since
-- nothing here asks a type to normalize: conversion is joinability, and
-- termination measures the live term, not its type.
--
-- Why the measure works. A live term is affine (Term.live), and Eval
-- never enters a dead part. Each Eval step either removes a redex node
-- (β, split, hit, miss, let, ann, cast) without copying a call, since a
-- q=1 value lands in at most one live place and a q=2 value is Data (no
-- λ, no call, no redex); or it fires a call, which replaces one call
-- label (def index, sizes of its columns) by the labels of the reached
-- branch: calls to earlier defs (a smaller index), and self-calls whose
-- columns are, left to right, rebuilt values (no bigger) and then a strict
-- piece (smaller). Labels live in a Dershowitz–Manna multiset, where each
-- redex node adds the least label. A dead region may hold Girard's
-- paradox: it is never run, and never measured.
--
-- Sections, and their key lemmas:
--   S1 Syntax             ren and sub compose (sub_sub)
--   S2 Confluence         Takahashi's complete development (confluent)
--   S3 Evaluator          wnf is a Pars step, conv a join (wnf_pars, conv_sound)
--   S4 Typing             typing survives substitution (typed_sub)
--   S5 Checker            each checker rule lands on its Typed rule (chk)
--   S6 Subject reduction  Par keeps the type (sr, eval_pars)
--   S7 Progress           canonical forms, the tree walk (progress, empty)
--   S8 Termination        a call becomes smaller calls (hcl, tp, halts)
--   S9 Assembly           consistent
--
-- Where the checker's side conditions are used:
--   live scrutinee (prj, mat, efq)  progress: Eval fires only on a live one
--   q=2 binder needs Data           canon_data: a q=2 copy holds no λ
--   uses (affinity)                 eval_decreases: β copies no call
--   called (order, descent)         hcl, tp, label_wf, dm_wf

-- Syntax
-- ------

theorem up_sub_ren : Subst.up σ ∘ Ren.up r = Subst.up (σ ∘ r) := by
  funext i; cases i <;> rfl

theorem sub_ren (t : Term) : Term.sub σ (Term.ren r t) = Term.sub (σ ∘ r) t := by
  induction t generalizing σ r <;> simp [Term.ren, Term.sub, up_sub_ren, *]

theorem up_ren_sub : Term.ren (Ren.up r) ∘ Subst.up σ = Subst.up (Term.ren r ∘ σ) := by
  funext i; cases i; rfl; simp [Subst.up, ren_ren]; rfl

theorem ren_sub (t : Term) :
    Term.ren r (Term.sub σ t) = Term.sub (Term.ren r ∘ σ) t := by
  induction t generalizing σ r <;> simp [Term.ren, Term.sub, ← up_ren_sub, *]

theorem up_sub : Term.sub (Subst.up τ) ∘ Subst.up σ = Subst.up (Term.sub τ ∘ σ) := by
  funext i; cases i; rfl; simp [Subst.up, sub_ren, ren_sub]; rfl

theorem sub_sub (t : Term) :
    Term.sub τ (Term.sub σ t) = Term.sub (Term.sub τ ∘ σ) t := by
  induction t generalizing σ τ <;> simp [Term.sub, ← up_sub, *]

theorem up_var : Subst.up Var = Var := by
  funext i; cases i <;> rfl

theorem sub_var (t : Term) : Term.sub Var t = t := by
  induction t <;> simp [Term.sub, up_var, *]

theorem ren_as_sub (t : Term) : Term.ren r t = Term.sub (Var ∘ r) t := by
  rw [← sub_ren, sub_var]

-- a term that r fixes is fixed by s, if s fixes r's fixed points
theorem ren_fix (t : Term) : Term.ren r t = t → (∀ i, r i = i → s i = Var i) →
    Term.sub s t = t := by
  have hu {r s} (h : ∀ i, r i = i → s i = Var i) i : Ren.up r i = i → Subst.up s i = Var i := by
    cases i <;> simp_all [Ren.up, Subst.up, Term.ren]
  induction t generalizing r s <;> simp [Term.ren, Term.sub] <;> intros <;> apply_rules [hu, And.intro]

-- the closedness test of Def.check
theorem ren_closed : Term.ren Nat.succ t = t → Term.Closed t :=
  fun h _ => ren_fix t h fun i e => absurd e (Nat.succ_ne_self i)

theorem inst_sub : Term.sub σ (Term.inst f v) =
    Term.inst (Term.sub (Subst.up σ) f) (Term.sub σ v) := by
  simp only [Term.inst, sub_sub]; congr 1; funext i
  cases i; rfl; simp [Subst.up, sub_ren]; exact (sub_var _).symm

theorem sub_succ : Term.sub (Subst.up σ) (Term.ren Nat.succ t) = Term.ren Nat.succ (Term.sub σ t) := by
  rw [sub_ren, ren_sub]; rfl

theorem pick_inst : Term.inst (Term.ren (Ren.pick i) T) (Var i) = T := by
  have : Subst.one (Var i) ∘ Ren.pick i = Var := by
    funext j; simp [Ren.pick]; split <;> simp_all [Subst.one]
  rw [Term.inst, sub_ren, this, sub_var]

theorem unspine_spine : Term.unspine (Term.spine t xs) [] = Term.unspine t xs := by
  induction xs generalizing t; rfl; apply_assumption

-- a checker context, declaratively: a let variable is its value
def Ctx.drop : Ctx → Subst
  | [] => Var
  | (_, some v) :: c => Term.sub (Ctx.drop c) ∘ Subst.one v
  | (_, none) :: c => Subst.up (Ctx.drop c)

def Ctx.decl : Ctx → List Term
  | [] => []
  | (_, some _) :: c => Ctx.decl c
  | (A, none) :: c => Term.sub (Ctx.drop c) A :: Ctx.decl c

theorem drop_sub (c : Ctx) : Term.sub (Ctx.drop c) ∘ Ctx.sub c = Ctx.drop c := by
  induction c; rfl
  rename_i e c ih; funext i; obtain ⟨_, _ | v⟩ := e <;> cases i <;> simp [Ctx.sub, sub_ren]; rfl
  exact (ren_sub _).symm.trans (congrArg _ (congrFun ih _))
  exact (sub_sub _).trans (congrArg (Term.sub · v) ih)
  exact congrFun ih _

-- the checker's zeta vanishes under Ctx.drop
theorem zeta_drop : Term.sub (Ctx.drop c) (Ctx.zeta c t) = Term.sub (Ctx.drop c) t := by
  unfold Ctx.zeta; split <;> simp [sub_sub, drop_sub]

-- Confluence
-- ----------

-- the complete development: every redex of t, at once
open Classical in
noncomputable def Term.dev (bk : Book) : Term → Term
  | Ref k =>
    match Book.get bk k with
    | some d => if Term.Closed d.v then d.v else Ref k
    | none   => Ref k
  | Ann x _ => Term.dev bk x
  | Let _ v f => Term.inst (Term.dev bk f) (Term.dev bk v)
  | All q A B => All q (Term.dev bk A) (Term.dev bk B)
  | Lam q f => Lam q.lin (Term.dev bk f)
  | App _ (Lam _ f) x => Term.inst (Term.dev bk f) (Term.dev bk x)
  | App q (Prj h) (Tup r a b) =>
    App q (App (Quan.fld r q) (Term.dev bk h) (Term.dev bk a)) (Term.dev bk b)
  | App q (Mat k h m) (Lab j) =>
    if j = k then Term.dev bk h else App q (Term.dev bk m) (Lab j)
  | App q f x => App q (Term.dev bk f) (Term.dev bk x)
  | Sig q A B => Sig q (Term.dev bk A) (Term.dev bk B)
  | Tup q a b => Tup q (Term.dev bk a) (Term.dev bk b)
  | Prj h => Prj (Term.dev bk h)
  | Mat k h m => Mat k (Term.dev bk h) (Term.dev bk m)
  | Eql a b T => Eql (Term.dev bk a) (Term.dev bk b) (Term.dev bk T)
  | Rwt Rfl _ f => Term.dev bk f
  | Rwt e P f => Rwt (Term.dev bk e) (Term.dev bk P) (Term.dev bk f)
  | t => t

theorem lin_eq {p q : Quan} : q.live = p.live → q.lin = p.lin := by
  cases p <;> cases q <;> decide

theorem par_refl (t : Term) : Par bk t t := by
  induction t <;> constructor <;> first | assumption | exact .inl rfl

theorem pars_trans : Pars bk a b → Pars bk b c → Pars bk a c
  | .refl, g => g
  | .step s h, g => .step s (pars_trans h g)

-- Pars is a congruence where Par is one
theorem pars_map (C : Term → Term) (hC : ∀ {a b}, Par bk a b → Par bk (C a) (C b)) :
    Pars bk a b → Pars bk (C a) (C b)
  | .refl => .refl
  | .step s h => .step (hC s) (pars_map C hC h)

theorem pars2 (C : Term → Term → Term)
    (hC : ∀ {a a' b b'}, Par bk a a' → Par bk b b' → Par bk (C a b) (C a' b')) :
    Pars bk a a' → Pars bk b b' → Pars bk (C a b) (C a' b') := fun ha hb =>
  pars_trans (pars_map (C · b) (hC · (par_refl b)) ha) (pars_map (C a') (hC (par_refl a')) hb)

theorem pars3 (C : Term → Term → Term → Term)
    (hC : ∀ {a a' b b' c c'}, Par bk a a' → Par bk b b' → Par bk c c' → Par bk (C a b c) (C a' b' c')) :
    Pars bk a a' → Pars bk b b' → Pars bk c c' → Pars bk (C a b c) (C a' b' c') := fun ha hb hc =>
  pars_trans (pars2 (C · · c) (hC · · (par_refl c)) ha hb) (pars_map (C a' b') (hC (par_refl _) (par_refl _)) hc)

theorem ren_inst : Term.ren r (Term.inst f v) =
    Term.inst (Term.ren (Ren.up r) f) (Term.ren r v) := by
  simp [ren_as_sub, inst_sub, ← up_sub_ren, up_var]

theorem par_ren : Par bk t u → Par bk (Term.ren r t) (Term.ren r u) := by
  intro h; induction h generalizing r <;> simp [Term.ren, ren_inst]
  case delta hk hc => rw [ren_as_sub, hc]; exact .delta hk hc
  all_goals first | apply Par.split | apply Par.miss | constructor
  all_goals first | assumption | apply_assumption

theorem par_sub : Par bk t u → (∀ i, Par bk (σ i) (τ i)) →
    Par bk (Term.sub σ t) (Term.sub τ u) := by
  have U {σ τ} (h : ∀ i, Par bk (σ i) (τ i)) : ∀ i, Par bk (Subst.up σ i) (Subst.up τ i)
    | 0 => .var | _ + 1 => par_ren (h _)
  intro h hs; induction h generalizing σ τ <;> simp [Term.sub, inst_sub]
  case delta hk hc => rw [hc]; exact .delta hk hc
  all_goals first | exact hs _ | apply Par.split | apply Par.miss | constructor
  all_goals first | assumption | (apply_assumption; (repeat apply U); exact hs)

theorem par_inst (hf : Par bk f f') (hv : Par bk v v') :
    Par bk (Term.inst f v) (Term.inst f' v') :=
  par_sub hf fun | 0 => hv | _ + 1 => .var

-- Takahashi: dev t is a Par reduct of every Par reduct of t
theorem triangle : Par bk t u → Par bk u (Term.dev bk t) := by
  intro h; induction h
  case ref => (conv => arg 3; whnf); split <;> (try split) <;> constructor <;> assumption
  case delta hk hc => (conv => arg 3; whnf); simp [hk, hc, par_refl]
  case app h1 h2 ih1 ih2 =>
    cases h1 <;> try exact .app ih1 ih2
    case lam => cases ih1; exact .beta ‹_› ih2
    all_goals cases h2 <;> try exact .app ih1 ih2
    all_goals cases ih1
    · cases ih2; exact .split ‹_› ‹_› ‹_›
    · show Par _ _ (ite ..); split
      · subst_vars; exact .hit ‹_›
      · exact .miss ‹_› ‹_›
  case rwt h1 _ _ _ _ ih => cases h1 <;> first | exact .rwt ‹_› ‹_› ‹_› | exact .cast ih
  case split ih1 ih2 ih3 => exact .app (.app ih1 ih2) ih3
  case hit => show Par _ _ (ite ..); simpa
  case miss hne _ ih => show Par _ _ (ite ..); simp only [hne]; exact .app ih .lab
  all_goals first | assumption | (first | constructor | apply par_inst) <;>
    first | assumption | (rcases ‹_ ∨ _› with rfl | rfl <;> simp)

-- the strip lemma, from the triangle
theorem strip : Par bk a b → Pars bk a c → ∃ d, Pars bk b d ∧ Par bk c d := by
  intro h p; induction p generalizing b with
  | refl => exact ⟨_, .refl, h⟩
  | step s _ ih => exact (ih (triangle s)).imp fun _ h' => ⟨.step (triangle h) h'.1, h'.2⟩

theorem confluent : Claim.confluent := by
  intro bk a b c p q; induction p generalizing c with
  | refl => exact ⟨c, q, .refl⟩
  | step s _ ih => have ⟨_, h1, h2⟩ := strip s q; exact (ih _ h1).imp fun _ h => ⟨h.1, .step h2 h.2⟩

theorem conv_trans : Conv bk a b → Conv bk b c → Conv bk a c := fun ⟨_, h1, h2⟩ ⟨_, h3, h4⟩ =>
  have ⟨_, h5, h6⟩ := confluent _ _ _ _ h2 h3
  ⟨_, pars_trans h1 h5, pars_trans h4 h6⟩

theorem conv_sub : Conv bk a b → Conv bk (Term.sub σ a) (Term.sub σ b) := fun ⟨_, h1, h2⟩ =>
  ⟨_, pars_map _ (par_sub · fun _ => par_refl _) h1, pars_map _ (par_sub · fun _ => par_refl _) h2⟩

-- the former of a type or value; 0 for a redex, variable or call
def Term.former : Term → Nat
  | Typ _     => 1
  | All _ _ _ => 2
  | Sig _ _ _ => 3
  | Enu _     => 4
  | Eql _ _ _ => 5
  | Lam _ _   => 6
  | Prj _     => 7
  | Mat _ _ _ => 8
  | Efq       => 9
  | Tup _ _ _ => 10
  | Lab _     => 11
  | Rfl       => 12
  | _         => 0

theorem pars_former : Pars bk a b → Term.former a ≠ 0 → Term.former b = Term.former a := by
  intro h n; induction h with
  | refl => rfl
  | step s _ ih => cases s <;> first | exact ih n | nomatch n rfl

-- a former only reduces to itself
theorem conv_former : Conv bk a b → Term.former a ≠ 0 → Term.former b ≠ 0 →
    Term.former a = Term.former b := fun ⟨_, h1, h2⟩ n1 n2 =>
  (pars_former h1 n1).symm.trans (pars_former h2 n2)

-- the parts of convertible All or Σ convert
theorem conv_bin (hC : C = All ∨ C = Sig) (h : Conv bk (C p A B) (C q A' B')) :
    p = q ∧ Conv bk A A' ∧ Conv bk B B' := by
  have I {t u p A B} (h : Pars bk t u) : t = C p A B →
      ∃ A' B', u = C p A' B' ∧ Pars bk A A' ∧ Pars bk B B' := by
    induction h generalizing A B with
    | refl => exact fun e => ⟨A, B, e, .refl, .refl⟩
    | step s _ ih =>
      rintro rfl; rcases hC with rfl | rfl <;> cases s <;>
        have ⟨_, _, e, h3, h4⟩ := ih rfl <;> exact ⟨_, _, e, .step ‹_› h3, .step ‹_› h4⟩
  have ⟨c, h1, h2⟩ := h
  obtain ⟨_, _, rfl, h3, h4⟩ := I h1 rfl
  have ⟨_, _, e2, h5, h6⟩ := I h2 rfl
  rcases hC with rfl | rfl <;> cases e2 <;> exact ⟨rfl, ⟨_, h3, h5⟩, ⟨_, h4, h6⟩⟩

theorem conv_all : Conv bk (All p A B) (All q A' B') →
    p = q ∧ Conv bk A A' ∧ Conv bk B B' := conv_bin (.inl rfl)

theorem conv_sig : Conv bk (Sig p A B) (Sig q A' B') →
    p = q ∧ Conv bk A A' ∧ Conv bk B B' := conv_bin (.inr rfl)

theorem pars_fix (h : ∀ v, Par bk t v → v = t) : Pars bk t u → u = t := by
  intro p; induction p with
  | refl => rfl
  | step s _ ih => cases h _ s; exact ih h

theorem conv_leaf : (Conv bk (Typ p) (Typ q) → p = q) ∧
    (Conv bk (Enu ks) (Enu js) → ks = js) := by
  constructor <;> intro ⟨c, h1, h2⟩ <;>
    cases pars_fix (fun _ s => by cases s; rfl) h1 <;>
    cases pars_fix (fun _ s => by cases s; rfl) h2 <;> rfl

theorem conv_typ_enu : Conv bk (Typ q) (Enu ks) → False :=
  fun h => nomatch conv_former h nofun nofun

theorem csym : Conv bk a b → Conv bk b a
  | ⟨c, h1, h2⟩ => ⟨c, h2, h1⟩

theorem enu_inj : Conv bk (Enu ks) (Enu js) → ks = js := (conv_leaf (p := Q0) (q := Q0)).2

theorem fits_trans : Fits bk A B → Fits bk B C → Fits bk A C := by
  have X := @conv_trans bk
  rintro (h1 | ⟨h1, q, h1'⟩ | ⟨ks, js, h1, h1', s1⟩) h2
  · exact h2.imp (X h1) (Or.imp (fun ⟨a, b⟩ => ⟨X h1 a, b⟩) fun ⟨k, j, a, b⟩ => ⟨k, j, X h1 a, b⟩)
  all_goals rcases h2 with h2 | ⟨h2, r, h2'⟩ | ⟨ks', js', h2, h2', s2⟩
  · exact .inr (.inl ⟨h1, q, X (csym h2) h1'⟩)
  · exact .inr (.inl ⟨h1, r, h2'⟩)
  · nomatch conv_typ_enu (X (csym h1') h2)
  · exact .inr (.inr ⟨ks, js, h1, X (csym h2) h1', s1⟩)
  · nomatch conv_typ_enu (X (csym h2) h1')
  · cases enu_inj (X (csym h1') h2)
    exact .inr (.inr ⟨ks, js', h1, h2', fun _ m => s2 (s1 m)⟩)

theorem fits_sub : Fits bk A B → Fits bk (Term.sub σ A) (Term.sub σ B) :=
  Or.imp conv_sub (Or.imp (fun ⟨a, q, b⟩ => ⟨conv_sub a, q, conv_sub b⟩)
    fun ⟨k, j, a, b, s⟩ => ⟨k, j, conv_sub a, conv_sub b, s⟩)

-- Evaluator
-- ---------

theorem par_spine : Par bk a b → Par bk (Term.spine a xs) (Term.spine b xs) :=
  match xs with
  | [] => id
  | x :: _ => fun h => (par_spine (.app h (par_refl x.2)) :)

theorem env_nil : Env.sub [] = Var := funext fun _ => rfl

theorem env_inst : Term.sub (Env.sub (x :: e)) f =
    Term.inst (Term.sub (Subst.up (Env.sub e)) f) x := by
  simp only [Term.inst, sub_sub]; congr 1; funext i; cases i
  · rfl
  · simp [Subst.up, sub_ren]; exact (sub_var _).symm

-- the checker's book ck holds bk's defs, up to their opaque flags, and
-- their bodies are closed
def Sees (ck : Lib) (bk : Book) : Prop :=
  ∀ k d, ck[k]? = some d → ∃ o, Book.get bk k = some { d with o } ∧ Term.Closed d.v

-- one strong induction on fuel for wnf, run, fire and val
theorem wnf_pars (hb : Sees ck bk) :
    Pars bk (Term.spine t xs) (Term.wnf ck cl n t xs).1 ∧
    (∀ {e u}, (Term.run ck cl n t e xs).1 = some u → Pars bk (Term.spine (Term.sub (Env.sub e) t) xs) u) ∧
    (∀ {e u e' ys k}, Term.fire ck cl n t e xs = (some (u, e', ys), k) →
      Pars bk (Term.spine (Term.sub (Env.sub e) t) xs) (Term.spine (Term.sub (Env.sub e') u) ys)) ∧
    ∀ {q v k}, Term.val ck cl n q t = (v, k) → Pars bk t v := by
  induction n using Nat.strongRecOn generalizing t xs
  rename_i n ih
  have S {a b c} xs (p : Pars bk a b) (s : Par bk b c) :=
    pars_map (Term.spine · xs) par_spine (pars_trans p (.step s .refl))
  have W {m a t xs} (p : Pars bk a (Term.spine t xs)) (h : m < n := by omega) := pars_trans p (ih _ h).1
  have V {m x v k} (ex : Term.wnf ck cl m x [] = (v, k)) (h : m < n := by omega) :=
    ex ▸ (ih _ h (t := x) (xs := [])).1
  have L {m q x v k} (ex : Term.val ck cl m q x = (v, k)) (h : m < n := by omega) := (ih _ h (xs := [])).2.2.2 ex
  have R1 {m t e xs u} (h : (Term.run ck cl m t e xs).1 = some u) (l : m < n := by omega) := (ih _ l).2.1 h
  have F {m t e xs u e' ys k} (ex : Term.fire ck cl m t e xs = (some (u, e', ys), k)) (h : m < n := by omega) :=
    (ih _ h).2.2.1 ex
  refine ⟨?_, fun h => ?_, fun h => ?_, fun h => ?_⟩
  · unfold Term.wnf; split <;> (try split) <;> (try split) <;> try exact .refl
    · exact W (S xs .refl (.unann (par_refl _)))
    · exact W (S xs (pars2 (Let _) .lett (L ‹_›) .refl) (.unlet (par_refl _) (par_refl _)))
    · exact W .refl
    · exact W (S xs (pars3 Rwt .rwt (V ‹_›) .refl .refl) (.cast (par_refl _)))
    · exact S xs (pars3 Rwt .rwt (V ‹_›) .refl .refl) (par_refl _)
    · rename_i _ _ _ hd _ _ _ hr; have ⟨_, hd, hc⟩ := hb _ _ hd
      have := R1 (by rw [hr]); rw [env_nil, sub_var] at this
      exact W (.step (par_spine (.delta hd hc)) this)
    · rename_i hf; exact W (by simpa [env_nil, sub_var] using F hf)
  · unfold Term.run at h
    split at h <;> (try split at h) <;> (try split at h) <;> (try cases h) <;> try exact .refl
    · exact (R1 h :)
    · exact pars_trans (F ‹_›) (R1 h)
  · unfold Term.fire at h
    split at h <;> (try split at h) <;> (try split at h) <;> cases h
    · rw [env_inst]; exact S _ (pars2 (App _) .app .refl (L ‹_›)) (.beta (par_refl _) (par_refl _))
    · exact S _ (pars2 (App _) .app .refl (V ‹_›)) (.split (par_refl _) (par_refl _) (par_refl _))
    · cases beq_iff_eq.1 ‹_›; exact S _ (pars2 (App _) .app .refl (V ‹_›)) (.hit (par_refl _))
    · exact S _ (pars2 (App _) .app .refl (V ‹_›)) (.miss (by simp_all) (par_refl _))
  · unfold Term.val at h; split at h
    · split at h
      · split at h; split at h; cases h
        exact pars_trans (V ‹_›) (pars2 (Tup _) .tup (L ‹_›) (L ‹_›))
      · exact V h
    · cases h; exact .refl

-- conv's fold: a true result passed every pair
theorem fold_true {g : Nat → Term → Term → Bool × Nat} : ∀ {s},
    (List.foldl (fun (r : Bool × Nat) (p : Term × Term) => if r.1 then g r.2 p.1 p.2 else r) s ps).1 = true →
    s.1 = true ∧ ∀ p ∈ ps, ∃ m, (g m p.1 p.2).1 = true := by
  induction ps with
  | nil => exact fun h => ⟨h, nofun⟩
  | cons p ps ih =>
    intro s h; have ⟨h1, h2⟩ := ih h
    simp only at h1; split at h1
    · exact ⟨‹_›, fun x m => (List.mem_cons.1 m).elim (· ▸ ⟨_, h1⟩) (h2 x)⟩
    · contradiction

-- λs of one liveness convert when their bodies do
theorem conv_lam (e : q.live = p.live) : Conv bk f g → Conv bk (Lam q f) (Lam p g)
  | ⟨_, h1, h2⟩ =>
    have L {q f c} (h : Pars bk f c) : Pars bk (Lam q f) (Lam q.lin c) :=
      .step (.lam (par_refl _) (.inr rfl)) (pars_map _ (.lam · (.inl rfl)) h)
    ⟨_, L h1, lin_eq e ▸ L h2⟩

-- heads whose parts convert convert
theorem parts_conv (h : Term.parts a b = some ps) (H : ∀ p ∈ ps, Conv bk p.1 p.2) :
    Conv bk a b := by
  unfold Term.parts at h
  split at h <;> (try split at h) <;> cases h <;> subst_vars <;>
    simp only [List.mem_cons, List.mem_nil_iff, forall_eq_or_imp, or_false, forall_eq] at H
  all_goals first
    | exact ⟨_, .refl, .refl⟩
    | exact conv_lam ‹_› H
    | (obtain ⟨_, h1, h2⟩ := H; refine ⟨_, pars_map _ ?_ h1, pars_map _ ?_ h2⟩)
    | (obtain ⟨⟨_, h1, h2⟩, _, h3, h4⟩ := H; refine ⟨_, pars2 _ ?_ h1 h3, pars2 _ ?_ h2 h4⟩)
    | (obtain ⟨⟨_, h1, h2⟩, ⟨_, h3, h4⟩, _, h5, h6⟩ := H
       refine ⟨_, pars3 _ ?_ h1 h3 h5, pars3 _ ?_ h2 h4 h6⟩)
  all_goals intros; constructor <;> assumption

theorem wnf_nil (hb : Sees ck bk) (e : Term.wnf ck cl n t [] = (u, k)) : Pars bk t u :=
  (e ▸ (wnf_pars (t := t) (xs := []) hb).1 :)

theorem conv_sound (hb : Sees ck bk) : (Term.conv ck cl n a b).1 = true → Conv bk a b := by
  induction n using Nat.strongRecOn generalizing a b cl; rename_i n ih
  unfold Term.conv; split
  · nofun
  split
  · intro _; subst_vars; exact ⟨_, .refl, .refl⟩
  split; split; split
  · intro h; rename_i hps
    have ⟨_, hf⟩ := fold_true (g := fun m x y => Term.conv ck _ (min m _) x y) h
    have ⟨c, h1, h2⟩ := parts_conv hps fun p m => have ⟨_, hp⟩ := hf p m; ih _ (by omega) hp
    exact ⟨c, pars_trans (wnf_nil hb ‹_›) h1, pars_trans (wnf_nil hb ‹_›) h2⟩
  · nofun

theorem fits_sound (hb : Sees ck bk) (h : (Term.fits ck cl U T).1 = true) : Fits bk U T := by
  unfold Term.fits at h; split at h; rename_i e1; split at h; rename_i e2
  have W1 : Conv bk U _ := ⟨_, wnf_nil hb e1, .refl⟩; have W2 : Conv bk T _ := ⟨_, wnf_nil hb e2, .refl⟩
  split at h
  · exact .inr (.inl ⟨W1, _, W2⟩)
  · exact .inr (.inr ⟨_, _, W1, W2, fun _ m => by simpa using List.all_eq_true.1 h _ m⟩)
  · exact .inl (conv_trans W1 (conv_trans (conv_sound hb h) (csym W2)))

-- Typing
-- ------

-- a renaming from Γ into Δ that keeps types
def RenOk (Δ : List Term) (r : Ren) (Γ : List Term) : Prop :=
  ∀ i A, Γ[i]? = some A →
    ∃ B, Δ[r i]? = some B ∧
      Term.ren (· + (r i + 1)) B = Term.ren r (Term.ren (· + (i + 1)) A)

-- a substitution from Γ into Δ that keeps types
def SubstOk (bk : Book) (Δ : List Term) (σ : Subst) (Γ : List Term) : Prop :=
  ∀ i A, Γ[i]? = some A →
    Typed bk Δ (σ i) (Term.sub σ (Term.ren (· + (i + 1)) A))

-- the Prj motive commutes with a lifted substitution
theorem tup_sub : Term.sub (Subst.up (Subst.up σ)) (Term.sub (Subst.tup r) P) =
    Term.sub (Subst.tup r) (Term.sub (Subst.up σ) P) := by
  simp only [sub_sub]; congr 1; funext i; cases i
  · rfl
  · show Term.ren _ (Term.ren _ _) = Term.sub _ (Term.ren _ _)
    rw [ren_ren, sub_ren, ren_as_sub]; rfl

-- one induction for renamings and substitutions: K types σ's
-- variables and lifts under a binder
theorem typed_gen (K : List Term → Subst → List Term → Prop)
    (hv : ∀ {Δ σ Γ}, K Δ σ Γ → SubstOk bk Δ σ Γ)
    (hu : ∀ {Δ σ Γ} A, K Δ σ Γ → K (Term.sub σ A :: Δ) (Subst.up σ) (A :: Γ))
    (h : Typed bk Γ t T) : K Δ σ Γ → Typed bk Δ (Term.sub σ t) (Term.sub σ T) := by
  induction h generalizing Δ σ <;> intro k <;> (try simp only [Term.sub, inst_sub, tup_sub] at *)
  case var h => exact hv k _ _ h
  case ref h => rw [sub_sub]; exact .ref h
  case rwt h _ ih1 ih2 ih3 =>
    exact .rwt (ih1 k) (by simpa only [Term.sub, Subst.up, sub_succ] using ih2 (hu _ (hu _ k)))
      (by simpa only [inst_sub, sub_succ] using fits_sub h) (ih3 k)
  all_goals constructor <;> solve_by_elim [conv_sub, fits_sub]

theorem typed_ren : Typed bk Γ t T → RenOk Δ r Γ →
    Typed bk Δ (Term.ren r t) (Term.ren r T) := by
  intro h k
  simp only [ren_as_sub]
  refine typed_gen (fun Δ σ Γ => ∃ r, σ = Var ∘ r ∧ RenOk Δ r Γ) ?_ ?_ h ⟨r, rfl, k⟩
  · rintro Δ _ Γ ⟨r, rfl, k⟩ i A hA
    have ⟨B, hB, e⟩ := k i A hA; exact ren_as_sub _ ▸ e ▸ Typed.var hB
  · rintro Δ _ Γ A ⟨r, rfl, k⟩
    refine ⟨Ren.up r, by funext i; cases i <;> rfl, fun i B hB => ?_⟩; cases i
    · cases hB; refine ⟨_, rfl, ?_⟩; rw [← ren_as_sub, ren_ren, ren_ren]; rfl
    · obtain ⟨B', hB', e⟩ := k _ B hB
      have := congrArg (Term.ren Nat.succ) e
      simp only [ren_ren] at this ⊢; exact ⟨B', hB', this⟩

-- SubstOk lifts under a binder, by typed_ren
theorem substok_up (k : SubstOk bk Δ σ Γ) :
    SubstOk bk (Term.sub σ A :: Δ) (Subst.up σ) (A :: Γ) := by
  intro i B hB; rw [sub_ren]; cases i
  · cases hB; exact ren_sub _ ▸ Typed.var rfl
  · exact (sub_ren _ ▸ ren_sub _ ▸ typed_ren (r := Nat.succ) (Δ := Term.sub σ A :: Δ) (k _ B hB)
      (fun j B h => ⟨B, h, by rw [ren_ren]; rfl⟩) :)

theorem typed_sub : Typed bk Γ t T → SubstOk bk Δ σ Γ →
    Typed bk Δ (Term.sub σ t) (Term.sub σ T) :=
  typed_gen (SubstOk bk) id fun _ => substok_up

theorem typed_inst : Typed bk (A :: Γ) f B → Typed bk Γ v A →
    Typed bk Γ (Term.inst f v) (Term.inst B v) := by
  intro h hv
  refine typed_sub h fun i A' hA => ?_
  rw [sub_ren]; cases i
  · cases hA; exact (sub_var A).symm ▸ hv
  · exact ren_as_sub _ ▸ Typed.var hA

-- Checker
-- -------

section

-- every variable has its type, through Ctx.drop
def Ctx.ok (bk : Book) (c : Ctx) : Prop :=
  SubstOk bk (Ctx.decl c) (Ctx.drop c) (c.map (·.1))

theorem ok_let (hc : Ctx.ok bk c)
    (h : Typed bk (Ctx.decl c) (Term.sub (Ctx.drop c) v) (Term.sub (Ctx.drop c) V)) :
    Ctx.ok bk ((V, some v) :: c) := by
  intro i A e; rw [sub_ren]; cases i
  · cases e; exact h
  · exact (sub_ren _ ▸ hc _ _ e :)

-- a checker judgment, read through Ctx.drop
def Chk (bk : Book) (c : Ctx) (t T : Term) : Prop :=
  Typed bk (Ctx.decl c) (Term.sub (Ctx.drop c) t) (Term.sub (Ctx.drop c) T)

-- the checker's monad, read as facts (local simp lemmas)
theorem ok_bind {x : Res α} {f : α → Res β} : (x >>= f) = .ok b ↔ ∃ a, x = .ok a ∧ f a = .ok b := by
  cases x <;> simp [bind, Except.bind]

theorem ok_map {x : Res α} : (f <$> x) = .ok b ↔ ∃ a, x = .ok a ∧ f a = b := by
  cases x <;> simp [Functor.map, Except.map]

theorem ok_pure : (pure a : Res α) = .ok b ↔ a = b := by
  simp [pure, Except.pure]

theorem ok_unit {P : Unit → Prop} : (∃ x, P x) ↔ P () :=
  ⟨fun ⟨⟨⟩, h⟩ => h, fun h => ⟨_, h⟩⟩

theorem ok_need : Res.need b e = .ok a ↔ b = true := by
  cases b <;> simp [Res.need] <;> rfl

theorem ok_fail : Ctx.fail c x o = .ok a ↔ False := ⟨nofun, nofun⟩

theorem ok_cneed : Ctx.need c r x o = .ok a ↔ r.1 = true := by
  rcases r with ⟨_ | _, _ | _⟩ <;> simp [Ctx.need, ok_fail] <;> rfl

theorem ok_if [Decidable p] {x y : Res Unit} :
    (if p then x >>= (fun _ => y) else y) = .ok () ↔ (p → x = .ok ()) ∧ y = .ok () := by
  by_cases hp : p <;> simp [hp, ok_bind, ok_unit]

attribute [local simp] ok_bind ok_map ok_pure ok_unit ok_need ok_cneed ok_fail ok_if

theorem fit_sound (hb : Sees ck bk) (h : Ctx.fit ck c U T = .ok a) :
    Fits bk (Term.sub (Ctx.drop c) U) (Term.sub (Ctx.drop c) T) :=
  (zeta_drop ▸ zeta_drop ▸ fits_sub (σ := Ctx.drop c) (fits_sound hb (ok_cneed.1 h)) :)

theorem wnf_conv (hcl : Sees ck bk) : Conv bk (Term.sub (Ctx.drop c) T) (Term.sub (Ctx.drop c) (Ctx.wnf ck c T)) :=
  zeta_drop ▸ conv_sub ⟨_, (wnf_pars (xs := []) hcl).1, .refl⟩

theorem pars_all : Pars bk a b → Pars bk (All q a P) (All q b P) :=
  pars_map _ (.all · (par_refl P))

-- a checker type fits to and from its Ctx.wnf
theorem wnf_fits (hcl : Sees ck bk) (e : Ctx.wnf ck c T = W) :
    Fits bk (Term.sub (Ctx.drop c) W) (Term.sub (Ctx.drop c) T) ∧
    Fits bk (Term.sub (Ctx.drop c) T) (Term.sub (Ctx.drop c) W) :=
  have h := e ▸ wnf_conv (c := c) (T := T) hcl
  ⟨.inl (csym h), .inl h⟩

theorem snd_wnf2 (hcl : Sees ck bk) (e : Ctx.wnf ck c T = All q D P) (e' : Ctx.wnf ck c D = X)
    (h : Typed bk (Ctx.decl c) x
      (All q (Term.sub (Ctx.drop c) X) (Term.sub (Subst.up (Ctx.drop c)) P))) :
    Typed bk (Ctx.decl c) x (Term.sub (Ctx.drop c) T) :=
  have ⟨_, h1, h2⟩ := e' ▸ wnf_conv (c := c) (T := D) hcl
  .conv (.conv h (.inl ⟨_, pars_all h2, pars_all h1⟩)) (wnf_fits hcl e).1

-- each checker rule lands on its Typed rule, through Ctx.drop
theorem chk (hcl : Sees ck bk) (n : Nat) : ∀ c t T, Ctx.ok bk c →
    (Term.infer ck n c t = .ok T → Chk bk c t T) ∧
    (Term.check ck n c t T = .ok () → Chk bk c t T) := by
  induction n with
  | zero => intros; constructor <;> nofun
  | succ n ih =>
  intro c t T hc
  have I t T := (ih c t T hc).1
  have C t T := (ih c t T hc).2
  have B {A t T} := (ih ((A, none) :: c) t T (substok_up hc)).2
  have A {t T} (h : (Term.infer ck n c t >>= (Ctx.fit ck c · T)) = .ok ()) :=
    have ⟨_, h1, h⟩ := ok_bind.1 h
    Typed.conv (I _ _ h1) (fit_sound hcl h)
  unfold Chk at *
  refine ⟨fun h => ?_, fun h => ?_⟩
  · cases t <;> simp only [Term.infer] at h <;> (try split at h) <;> simp at h <;> try subst h
    · rename_i e; exact hc _ _ (by simp [e])
    · rename_i e; have ⟨_, e, _⟩ := hcl _ _ e; exact (Typed.ref e :)
    · obtain ⟨h1, h2, rfl⟩ := h; exact .ann (C _ _ h1) (C _ _ h2)
    · exact .typ
    · obtain ⟨h1, h2, rfl⟩ := h; exact .all (C _ _ h1) (B h2)
    · obtain ⟨F, h1, h⟩ := h; split at h <;> simp at h; rename_i e; obtain ⟨rfl, h2, rfl⟩ := h
      rw [inst_sub]
      refine .conv (.app (.conv (I _ _ h1) (wnf_fits hcl e).2) (C _ _ h2))
        (.inl ⟨_, .refl, .step (par_inst (par_refl _) ?_) .refl⟩)
      unfold Term.arg; split
      · exact .unann (par_refl _)
      · exact par_refl _
    · exact .enu
    · obtain ⟨h1, h2, h3, rfl⟩ := h; exact .eql (C _ _ h1) (C _ _ h2) (C _ _ h3)
  · cases t <;> (try simp [Term.check] at h) <;> (try split at h) <;>
      (try simp at h) <;> (try split at h) <;> (try simp at h)
    all_goals try first | exact A h | exact A (ok_bind.2 h)
    · obtain ⟨V, h1, h3, h2⟩ := h
      have h1 := Typed.conv (I _ _ h1) (wnf_fits hcl rfl).2
      have := (ih _ _ _ (ok_let hc h1)).2 h2
      rw [Ctx.drop, sub_ren, ← sub_sub] at this
      exact .lett h1 (fun e => C _ _ (h3 e)) (inst_sub ▸ this)
    · rename_i e; obtain ⟨hp, h3, h2⟩ := h
      exact snd_wnf2 hcl e rfl (.lam hp (fun e => C _ _ (h3 e)) (B h2))
    · rename_i x
      cases x <;> simp only [Term.check] at h <;> (try split at h) <;> try exact A h
      rename_i i _; obtain ⟨A, h1, h2⟩ := ok_bind.1 h
      rw [← pick_inst (T := T) (i := i), inst_sub]; exact .app (C _ _ h2) (I _ _ h1)
    · rename_i e; obtain ⟨h1, h2⟩ := h; exact .conv (.sig (C _ _ h1) (B h2)) (wnf_fits hcl e).1
    · rename_i e; obtain ⟨rfl, h1, h2⟩ := h
      exact .conv (.tup (C _ _ h1) (inst_sub ▸ C _ _ h2)) (wnf_fits hcl e).1
    · rename_i e _ _ _ _ e'; obtain ⟨hq, h⟩ := h
      exact snd_wnf2 hcl e e' (.prj hq (by simpa only [Term.sub, tup_sub] using C _ _ h))
    · rename_i e; exact .conv (.lab h) (wnf_fits hcl e).1
    · rename_i e _ _ e'; obtain ⟨hq, hk, h1, h2⟩ := h
      exact snd_wnf2 hcl e e' (.mat hq hk (inst_sub ▸ C _ _ h1 :) (C _ _ h2))
    · rename_i e _ e'; exact snd_wnf2 hcl e e' (.efq h)
    · rename_i e; exact .conv (.rfl (conv_sub (conv_sound hcl h))) (wnf_fits hcl e).1
    · obtain ⟨E, h1, h⟩ := h; split at h <;> simp at h; rename_i e; obtain ⟨h2, h3, h4⟩ := h
      refine .rwt (.conv (I _ _ h1) (wnf_fits hcl e).2) ?_ ?_ ?_
      · simpa only [Ctx.decl, Ctx.drop, Term.sub, Subst.up, sub_succ] using
          (ih ((_, none) :: (_, none) :: c) _ _ (substok_up (substok_up hc))).2 h2
      · simpa only [inst_sub, sub_succ] using fit_sound hcl h3
      · simpa only [inst_sub, Term.sub] using C _ _ h4

theorem lib_get : (Lib.of bk)[k]? = Book.get bk k := by
  induction bk with
  | nil => simp [Lib.of, Book.get]
  | cons d bk ih => by_cases h : d.k = k <;> simp_all [Lib.of, Book.get, Std.HashMap.getElem?_insert]

theorem check_from_ok : ∀ ds i, Book.check_from bk ls i ds = .ok () →
    ∀ d ∈ ds, ∃ i, Def.check bk ls i d = .ok ()
  | [], _, _, _, h => nomatch h
  | d :: ds, i, h, e, he => by
    obtain ⟨_, h1, h⟩ := ok_bind.1 h
    cases he with
    | head => exact ⟨i, by cases h2 : Def.check bk ls i d <;> simp_all [Except.mapError]⟩
    | tail _ he => exact check_from_ok ds _ h e he

theorem book_check : Claim.sound := by
  intro bk h
  -- a def checks against ck: bk, or bk with no opaque flag
  have get k d (e : Book.get bk k = some d) : ∃ i, Book.index bk k = some i ∧ ∃ ck,
      (Book.Closed bk → Sees ck bk) ∧ Term.check ck FUEL [] d.T (Typ Q1) = .ok () ∧ Term.check ck FUEL [] d.v d.T = .ok () ∧
      Term.ren Nat.succ d.v = d.v ∧ Term.tree ⟨bk, i, [], [], []⟩ [] d.v = true := by
    obtain ⟨i, h⟩ := check_from_ok _ 0 h d (List.mem_of_find?_eq_some e)
    obtain rfl : d.k = k := by simpa using List.find?_some e
    simp [Def.check] at h
    refine ⟨i, h.1, _, fun hcl k d e => ?_, h.2⟩
    split at e <;> rw [lib_get] at e <;> (try (simp [Book.get, List.find?_map] at e; obtain ⟨d, e, rfl⟩ := e)) <;>
      exact ⟨d.o, e, hcl k d e⟩
  have hcl : Book.Closed bk := fun k d e =>
    have ⟨_, _, _, _, _, _, c, _⟩ := get k d e
    ren_closed c
  have K ck t T (s : Sees ck bk) := (chk s FUEL [] t T nofun).2
  simp only [Chk, Ctx.decl, Ctx.drop, sub_var] at K
  refine ⟨fun k d e => ?_, hcl, fun k i d ei e => ?_⟩ <;> obtain ⟨j, ej, ck, s, a, b, c, t⟩ := get k d e
  · exact ⟨K _ _ _ (s hcl) a, K _ _ _ (s hcl) b, ren_closed c⟩
  · cases ei.symm.trans ej; exact t

end

-- Subject reduction
-- -----------------

theorem pconv (h : Par bk a b) : Conv bk a b := ⟨b, .step h .refl, .refl⟩

theorem conv_inst : Conv bk a b → Conv bk (Term.inst P a) (Term.inst P b)
  | ⟨_, h1, h2⟩ => ⟨_, pars_map _ (par_inst (par_refl P)) h1, pars_map _ (par_inst (par_refl P)) h2⟩

theorem fits_conv (h : Fits bk U T) (h0 : U.former ≠ 0 := by simp [Term.former])
    (h1 : U.former ≠ 1 := by simp [Term.former]) (h4 : U.former ≠ 4 := by simp [Term.former]) : Conv bk U T := by
  rcases h with h | ⟨h, _⟩ | ⟨_, _, h, _⟩
  · exact h
  all_goals exact absurd (conv_former h h0 nofun) ‹_›

-- what the syntax-directed rule of t says about t's type U
def Gen (bk : Book) (Γ : List Term) : Term → Term → Prop
  | Lam q f, U => ∃ p A B, U = All p A B ∧ p.live = q.live ∧
    (q = Q2 → Typed bk Γ A (Typ Q2)) ∧ Typed bk (A :: Γ) f B
  | App q f x, U => ∃ A B, U = Term.inst B x ∧ Typed bk Γ f (All q A B) ∧ Typed bk Γ x A
  | Tup q a b, U => ∃ A B, U = Sig q A B ∧ Typed bk Γ a A ∧ Typed bk Γ b (Term.inst B a)
  | Prj h, U => ∃ q r A B P, U = All q (Sig r A B) P ∧ q.live ∧
    Typed bk Γ h (All (Quan.fld r q) A (All q B (Term.sub (Subst.tup r) P)))
  | Mat k h m, U => ∃ q ks P, U = All q (Enu ks) P ∧ q.live ∧
    Typed bk Γ h (Term.inst P (Lab k)) ∧ Typed bk Γ m (All q (Enu (ks.erase k)) P)
  | Efq, U => ∃ q P, U = All q (Enu []) P ∧ q.live
  | Lab k, U => ∃ ks, U = Enu ks ∧ k ∈ ks
  | Rfl, U => ∃ a b T, U = Eql a b T ∧ Conv bk a b
  | Sig q A B, U => ∃ g, U = Typ g ∧ Typed bk Γ A (Typ (Quan.kind q g)) ∧
    Typed bk (A :: Γ) B (Typ g)
  | Typ _, U | All .., U => U = Typ Q1
  | _, _ => True

-- the former of a value's type
def Term.tform : Term → Nat
  | Typ _ | All .. | Sig .. | Enu _ | Eql .. => 1
  | Tup .. => 3
  | Lab _ => 4
  | Rfl => 5
  | _ => 2

theorem gen (h : Typed bk Γ t T) :
    ∃ U, Gen bk Γ t U ∧ Fits bk U T ∧ (t.former ≠ 0 → U.former = t.tform) := by
  induction h
  all_goals first
    | refine ⟨_, ?_, .inl ⟨_, .refl, .refl⟩, by simp [Term.former, Term.tform]⟩; simp only [Gen]
      repeat' first | assumption | refine ⟨_, ?_⟩ | constructor
      done
    | rename_i ih; exact ih.imp fun _ ⟨g, f, e⟩ => ⟨g, fits_trans f ‹_›, e⟩

theorem ctx_par (h : Typed bk (A :: Γ) t T) (p : Par bk A A') : Typed bk (A' :: Γ) t T := by
  refine sub_var t ▸ sub_var T ▸ typed_sub h fun i B e => ?_
  rw [sub_var]; cases i
  · cases e; exact .conv (.var rfl) (.inl (csym (pconv (par_ren p))))
  · exact .var e

theorem pars_eql : Pars bk s c → s = Eql a b T →
    ∃ x y z, c = Eql x y z ∧ Pars bk a x ∧ Pars bk b y := by
  intro h; induction h generalizing a b T with
  | refl => exact fun e => ⟨_, _, _, e, .refl, .refl⟩
  | step p _ ih => rintro rfl; cases p with
    | eql pa pb _ => have ⟨_, _, _, e, h1, h2⟩ := ih rfl; exact ⟨_, _, _, e, .step pa h1, .step pb h2⟩

theorem conv_eql (h : Conv bk (Eql a b T) (Eql a' b' T')) : Conv bk a a' ∧ Conv bk b b' := by
  have ⟨c, h1, h2⟩ := h
  obtain ⟨_, _, _, rfl, h3, h4⟩ := pars_eql h1 rfl
  obtain ⟨_, _, _, ⟨⟩, h5, h6⟩ := pars_eql h2 rfl
  exact ⟨⟨_, h3, h5⟩, ⟨_, h4, h6⟩⟩

theorem lab_in (h : Typed bk Γ (Lab j) A) (c : Conv bk A (Enu ks)) : j ∈ ks := by
  obtain ⟨_, ⟨js, rfl, hj⟩, hU, _⟩ := gen h
  rcases hU with h | ⟨h, _⟩ | ⟨_, _, h, h', s⟩
  · rwa [← enu_inj (conv_trans h c)]
  · nomatch conv_typ_enu (csym h)
  · cases enu_inj h; cases enu_inj (conv_trans (csym h') c); exact s hj

theorem split_inst : Term.inst (Term.sub (Subst.up (Subst.one a)) (Term.sub (Subst.tup r) P)) b =
    Term.inst P (Tup r a b) := by
  simp only [Term.inst, sub_sub]; congr 1; funext i; cases i
  · exact congrArg (Tup r · b) ((sub_ren _).trans (sub_var a))
  · rfl

-- induction on Typed, inverting the redex by gen
theorem sr : Claim.sr := by
  intro bk Γ t u T wt h hp
  have pi := fun {f v v'} (p : Par bk v v') => csym (pconv (par_inst (par_refl f) p))
  induction h generalizing u
  case ref e => cases hp with
    | ref => exact .ref e
    | delta e' hc => cases e.symm.trans e'; rw [← hc]; exact typed_sub (wt _ _ e).2.1 nofun
  case ann _ _ ihT ihx => cases hp with
    | ann px pT => exact .conv (.ann (ihT _ pT) (.conv (ihx _ px) (.inl (pconv pT)))) (.inl (csym (pconv pT)))
    | unann px => exact ihx _ px
  case lett _ hq _ ihv _ ihf => cases hp with
    | lett pv pf => exact .lett (ihv _ pv) hq (ihf _ (par_inst pf pv))
    | unlet pv pf => exact ihf _ (par_inst pf pv)
  case tup _ _ iha ihb => cases hp with
    | tup pa pb => exact .tup (iha _ pa) (.conv (ihb _ pb) (.inl (csym (pi pa))))
  case eql _ _ _ ihT iha ihb => cases hp with
    | eql pa pb pT =>
      exact .eql (ihT _ pT) (.conv (iha _ pa) (.inl (pconv pT))) (.conv (ihb _ pb) (.inl (pconv pT)))
  case rwt he _ hF _ ihe ihP ihf => cases hp with
    | rwt pe pP pf =>
      exact .rwt (ihe _ pe) (ihP _ pP) (fits_trans (.inl (csym (pconv (par_inst (par_inst pP (par_ren pe)) (par_refl _))))) hF)
        (.conv (ihf _ pf) (.inl (pconv (par_inst (par_inst pP .rfl) (par_refl _)))))
    | cast pf =>
      obtain ⟨_, ⟨a, b, _, rfl, hc⟩, hU, _⟩ := gen he
      have ⟨ha, hb⟩ := conv_eql (fits_conv hU)
      exact .conv (ihf _ pf) (fits_trans (.inl (conv_inst (conv_trans (csym ha) (conv_trans hc hb)))) hF)
  case conv _ hf ih => exact .conv (ih _ hp) hf
  -- a λ+ stepped to a λ keeps its liveness and needs no Data
  case lam q _ _ _ _ _ hl hq _ _ ihf => cases hp with
    | lam pf e => cases q <;> rcases e with rfl | rfl <;> exact .lam hl (by first | exact hq | nofun) (ihf _ pf)
  case app _ hx ihf ihx => cases hp with
    | app pf px => exact .conv (.app (ihf _ pf) (ihx _ px)) (.inl (pi px))
    | beta pf px =>
      obtain ⟨_, ⟨_, _, _, rfl, _, _, hb⟩, hF, _⟩ := gen (ihf _ (.lam pf (.inl rfl)))
      have ⟨_, hA, hB⟩ := conv_all (fits_conv hF)
      exact .conv (typed_inst hb (.conv (ihx _ px) (.inl (csym hA))))
        (.inl (conv_trans (conv_sub hB) (pi px)))
    | split ph pa pb =>
      obtain ⟨_, ⟨_, _, _, _, _, rfl, _, hh⟩, hU, _⟩ := gen (ihf _ (.prj ph))
      obtain ⟨rfl, hS, hP⟩ := conv_all (fits_conv hU)
      obtain ⟨_, ⟨_, _, rfl, ha, hb⟩, hT, _⟩ := gen (ihx _ (.tup pa pb))
      obtain ⟨rfl, hA, hB⟩ := conv_sig (conv_trans (fits_conv hT) (csym hS))
      exact .conv (split_inst ▸ Typed.app (Typed.app hh (.conv ha (.inl hA))) (.conv hb (.inl (conv_sub hB))) :)
        (.inl (conv_trans (conv_sub hP) (pi (.tup pa pb))))
    | hit ph =>
      obtain ⟨_, ⟨_, _, _, rfl, _, hh, _⟩, hU, _⟩ := gen (ihf _ (.mat ph (par_refl _)))
      exact .conv hh (.inl (conv_sub (conv_all (fits_conv hU)).2.2))
    | miss hjk pm =>
      obtain ⟨_, ⟨_, ks, _, rfl, _, _, hm⟩, hU, _⟩ := gen (ihf _ (.mat (par_refl _) pm))
      obtain ⟨rfl, hE, hP⟩ := conv_all (fits_conv hU)
      exact .conv (.app hm (.lab ((List.mem_erase_of_ne hjk).2 (lab_in hx (csym hE))))) (.inl (conv_sub hP))
  all_goals cases hp; constructor <;> first
    | assumption | (apply_assumption <;> assumption) | exact ctx_par (by apply_assumption <;> assumption) ‹_›

theorem pars_sr : Book.WellTyped bk → Typed bk Γ t T → Pars bk t u → Typed bk Γ u T := by
  intro wt h p; induction p with
  | refl => exact h
  | step s _ ih => exact ih (sr _ _ _ _ _ wt h s)

theorem takes_sub (h : Term.takes t = true) : Term.takes (Term.sub σ t) = true := by
  cases t <;> simp_all [Term.takes, Term.sub]

-- a walk that needs more arguments reduces the spine to a λ or a λ-match
theorem walk_pars' (w : Walk bk t e xs o) : ∃ v,
    Pars bk (Term.spine (Term.sub (Env.sub e) t) xs) v ∧ (o = some v ∨ o = none ∧ Term.takes v) := by
  induction w
  case app ih => exact ih
  case need h => exact ⟨_, .refl, .inr ⟨rfl, takes_sub h⟩⟩
  case done => exact ⟨_, .refl, .inl rfl⟩
  all_goals rename_i ih; have ⟨v, p, h⟩ := ih; refine ⟨v, .step ?_ p, h⟩; try rw [env_inst]
  all_goals refine par_spine (a := App ..) ?_; first | apply Par.beta | apply Par.split | apply Par.hit | apply Par.miss
  all_goals first | assumption | exact par_refl _

theorem eval_pars : Book.Closed bk → Eval bk t u → Pars bk t u := by
  intro hc h; induction h
  case call e _ w =>
    obtain ⟨_, p, h | ⟨h, _⟩⟩ := walk_pars' w <;> cases h
    rw [env_nil, sub_var] at p; exact .step (par_spine (.delta e (hc _ _ e))) p
  all_goals first
    | (first | apply pars2 _ .app | apply pars2 _ .tup | apply pars2 _ .lett | apply pars3 _ .rwt) <;>
      first | assumption | exact .refl
    | refine .step ?_ .refl; first | apply Par.split | apply Par.miss | constructor
  all_goals first | assumption | exact par_refl _

-- Progress
-- --------

theorem spine_ft (h : t.former = 0 ∧ t.tform = 2) :
    (Term.spine t xs).former = 0 ∧ (Term.spine t xs).tform = 2 := by
  induction xs generalizing t with
  | nil => exact h
  | cons _ _ ih => exact ih ⟨rfl, rfl⟩

theorem spine_append : Term.spine t (xs ++ ys) = Term.spine (Term.spine t xs) ys := by
  induction xs generalizing t <;> first | rfl | apply_assumption

theorem spine_snoc : Term.spine t (xs ++ [(q, x)]) = App q (Term.spine t xs) x := spine_append

theorem spine_head (e : t = Term.spine (Ref k) xs) : Term.unspine t [] = (Ref k, xs) := by
  rw [e, unspine_spine]; rfl

theorem values_snoc : Values bk (xs ++ [(q, x)]) ↔ Values bk xs ∧ (q.live → Value bk x) := by
  induction xs with
  | nil => exact ⟨fun | .cons h .nil => ⟨.nil, h⟩, fun ⟨_, h⟩ => .cons h .nil⟩
  | cons _ _ ih => exact ⟨fun | .cons h hs => (ih.1 hs).imp_left (.cons h),
      fun ⟨.cons h hs, hx⟩ => .cons h (ih.2 ⟨hs, hx⟩)⟩

-- a walk that needs more arguments needed them before the last one
theorem walk_init (w : Walk bk t e zs o) : zs = xs ++ [p] → o = none → Walk bk t e xs none := by
  induction w generalizing xs <;> intro h n
  case app hn _ ih => exact .app hn (ih (congrArg _ h) n)
  case need => cases xs <;> cases h
  case done => cases n
  all_goals
    cases xs; exact .need rfl
    cases h; constructor <;> first | assumption | (apply_assumption <;> first | rfl | exact n)

-- a value that is no former is a call
theorem value_inv (v : Value bk t) (e : t.former = 0) : ∃ k d xs, t = Term.spine (Ref k) xs ∧
    Book.get bk k = some d ∧ Values bk xs ∧ Walk bk d.v [] xs none := by
  cases v <;> first | exact ⟨_, _, _, rfl, ‹_›, ‹_›, ‹_›⟩ | nomatch e

theorem value_app (v : Value bk (App q f x)) : Value bk f ∧ (q.live → Value bk x) := by
  have ⟨k, d, xs, e, hk, vs, w⟩ := value_inv v rfl
  rcases xs.eq_nil_or_concat with rfl | ⟨ys, ⟨q', x'⟩, rfl⟩; cases e
  simp only [List.concat_eq_append, spine_snoc] at e vs w; cases e
  exact (values_snoc.1 vs).imp_left (.call hk · (walk_init w rfl rfl))

theorem value_tup (v : Value bk (Tup q a b)) : (q.live → Value bk a) ∧ Value bk b := by
  generalize e : Tup q a b = t at v
  cases v <;> first
    | (cases e <;> exact ⟨‹_›, ‹_›⟩)
    | exact nomatch (congrArg Term.former e).trans (spine_ft ⟨rfl, rfl⟩).1

theorem value_call (v : Value bk (Term.spine (Ref k) xs)) :
    ∃ d, Book.get bk k = some d ∧ Walk bk d.v [] xs none := by
  have ⟨_, d, _, e, hk, _, w⟩ := value_inv v (spine_ft ⟨rfl, rfl⟩).1
  cases (spine_head e).symm.trans (spine_head rfl); exact ⟨d, hk, w⟩

theorem node_takes : Term.takes t = true → Term.node t = true := by
  cases t <;> simp_all [Term.node, Term.takes]

-- a walk that leaves the tree never needs more arguments
theorem walk_sn (w : Walk bk t e xs o) (w' : Walk bk t e xs none) : o = none := by
  induction w <;> cases w' <;> first
    | exact nomatch ‹Term.node _ = false›.symm.trans (node_takes ‹_›)
    | simp_all [Term.node, Term.takes]

theorem eval_value : Eval bk t u → Value bk t → False := by
  intro h v; induction h
  case app_f ih => exact ih (value_app v).1
  case app_x l _ ih => exact ih ((value_app v).2 l)
  case tup_a l _ ih => exact ih ((value_tup v).1 l)
  case tup_b ih => exact ih (value_tup v).2
  case call hk _ w => have ⟨_, hk', w'⟩ := value_call v; cases hk.symm.trans hk'; exact nomatch walk_sn w w'
  all_goals have ⟨_, _, _, e, _⟩ := value_inv v rfl; simpa [Term.unspine] using spine_head e

theorem tform_ne : Term.tform t ≠ 0 := by
  cases t <;> nofun

theorem fits_former (h : Fits bk U T) (c : Conv bk T X) (hU : U.former ≠ 0) (hX : X.former ≠ 0) :
    U.former = X.former := by
  rcases h with h | ⟨h, _, h'⟩ | ⟨_, _, h, h', _⟩
  · exact conv_former (conv_trans h c) hU hX
  all_goals exact (conv_former h hU nofun).trans (conv_former (conv_trans (csym c) h') hX nofun).symm

theorem conv_typed (wt : Book.WellTyped bk) (h : Typed bk Γ T K) :
    Conv bk X T → X.former ≠ 0 → ∃ Y, Typed bk Γ Y K ∧ Conv bk X Y ∧ Y.former = X.former
  | ⟨C, h1, h2⟩, n => ⟨C, pars_sr wt h h2, ⟨C, h1, .refl⟩, pars_former h1 n⟩

-- a closed value's type fits its former's
theorem value_fits (wt : Book.WellTyped bk) (v : Value bk t) (h : Typed bk [] t T) :
    ∃ U, Fits bk U T ∧ U.former = t.tform := by
  cases v
  case call _ _ _ hk _ w =>
    obtain ⟨v, p, h | ⟨-, tk⟩⟩ := walk_pars' w; cases h
    rw [env_nil, sub_var] at p
    have ⟨U, _, f, e⟩ := gen (pars_sr wt h (.step (par_spine (.delta hk (wt _ _ hk).2.2)) p))
    refine ⟨U, f, .trans ?_ (spine_ft ⟨rfl, rfl⟩).2.symm⟩
    cases v <;> simp [Term.takes] at tk <;> exact e nofun
  all_goals have ⟨U, _, f, e⟩ := gen h; exact ⟨U, f, e nofun⟩

theorem canon_fun : Book.WellTyped bk → Value bk t → Typed bk [] t T →
    Conv bk T (All q A B) →
    Term.former t ∈ [6, 7, 8, 9] ∨ ∃ k xs, t = Term.spine (Ref k) xs := by
  intro wt v h c
  have ⟨U, f, e⟩ := value_fits wt v h
  have := e ▸ fits_former f c (e ▸ tform_ne) nofun
  cases v <;> (try simp [Term.tform, Term.former] at this ⊢) <;> exact .inr ⟨_, _, rfl⟩

theorem canon_pair : Book.WellTyped bk → Value bk t → Typed bk [] t T →
    (Conv bk T (Sig r A B) → ∃ a b, t = Tup r a b) ∧
    (Conv bk T (Enu ks) → ∃ k, k ∈ ks ∧ t = Lab k) ∧
    (Conv bk T (Eql a b A) → t = Rfl) := by
  intro wt v h
  have ⟨U, f, e⟩ := value_fits wt v h
  refine ⟨fun c => ?_, fun c => ?_, fun c => ?_⟩ <;> have := e ▸ fits_former f c (e ▸ tform_ne) nofun <;>
    cases v <;> (try simp [Term.tform, Term.former] at this) <;>
    (try exact nomatch (spine_ft ⟨rfl, rfl⟩).2.symm.trans this)
  · obtain ⟨_, ⟨_, _, rfl, _⟩, f', _⟩ := gen h; exact ⟨_, _, by rw [(conv_sig (conv_trans (fits_conv f') c)).1]⟩
  · exact ⟨_, lab_in h c, rfl⟩
  · rfl

theorem canon_enu (wt : Book.WellTyped bk) (v : Value bk t) (h : Typed bk [] t T)
    (c : Conv bk T (Enu ks)) : ∃ k, k ∈ ks ∧ t = Lab k :=
  (canon_pair (r := Q0) (A := Rfl) (B := Rfl) (a := Rfl) (b := Rfl) wt v h).2.1 c

theorem typ2 : Fits bk (Typ g) (Typ Q2) → g = Q2 := by
  rintro (c | ⟨c, _⟩ | ⟨_, _, c, _⟩) <;> first | exact (conv_leaf (ks := []) (js := [])).1 c | exact (conv_typ_enu c).elim

-- a type of kind *2 is no kind and no ∀
theorem no_kind2 (wt : Book.WellTyped bk) (hT : Typed bk [] T (Typ Q2)) (f : Fits bk U T)
    (e : U.former = 1 ∨ U.former = 2) : False := by
  have key : ∀ {X}, Conv bk X T → X.former = 1 ∨ X.former = 2 → False := fun c e => by
    have ⟨Y, hY, _, eY⟩ := conv_typed wt hT c (by omega)
    have ⟨_, g, f', _⟩ := gen hY
    rw [← eY] at e
    cases Y <;> simp [Term.former] at e <;> cases g <;> exact nomatch typ2 f'
  rcases f with c | ⟨_, _, c⟩ | ⟨_, _, c, _⟩
  · exact key c e
  · exact key (csym c) (.inl rfl)
  · rcases e with e | e <;> exact nomatch e.symm.trans (conv_former c (by omega) nofun)

theorem kind_live : q.live = true → Quan.kind q Q2 = Q2 := by
  cases q <;> decide

-- no λ, call or type has a type of kind *2
theorem canon_data : Book.WellTyped bk → Value bk t → Typed bk [] t T →
    Typed bk [] T (Typ Q2) → Data t := by
  intro wt v h hT
  have ⟨U, f, e⟩ := value_fits wt v h
  cases v
  case tup _ _ _ ha hb =>
    obtain ⟨_, ⟨A, B, rfl, h1, h2⟩, f', _⟩ := gen h
    have ⟨Y, hY, c, eY⟩ := conv_typed wt hT (fits_conv f') nofun
    cases Y <;> cases eY
    obtain ⟨rfl, hA, hB⟩ := conv_sig c
    obtain ⟨_, ⟨g, rfl, hA', hB'⟩, f'', _⟩ := gen hY
    cases typ2 f''
    exact .tup (fun l => canon_data wt (ha l) (.conv h1 (.inl hA)) (kind_live l ▸ hA'))
      (canon_data wt hb (.conv h2 (.inl (conv_sub hB))) (typed_inst hB' (.conv h1 (.inl hA))))
  all_goals first | constructor | refine (no_kind2 wt hT f ?_).elim; rw [e]; first
    | exact .inr (spine_ft ⟨rfl, rfl⟩).2 | simp [Term.tform]

theorem spine_arg (h : Typed bk [] (Term.spine (App q f x) xs) T) :
    ∃ A B, Typed bk [] f (All q A B) ∧ Typed bk [] x A := by
  induction xs generalizing q f x T
  rotate_left; rename_i ih; have ⟨_, _, h, _⟩ := ih h
  all_goals have ⟨_, ⟨A, B, _, h⟩, _⟩ := gen h; exact ⟨A, B, h⟩

theorem no_var (h : Typed bk Γ t A) : Γ = [] → t = Var w → False := by
  induction h
  case var => rintro rfl _; simp_all
  case conv => assumption
  all_goals intro _ e; cases e

theorem index_of_get (h : Book.get bk k = some d) : ∃ i, Book.index bk k = some i :=
  Option.isSome_iff_exists.1 (by simpa [Book.index, Book.get] using congrArg Option.isSome h)

-- what a closed typed λ or λ-match needs of its argument x at q
def Fire (q : Quan) (x : Term) : Term → Prop
  | Lam p _   => p.live = q.live ∧ (p = Q2 → Data x)
  | Prj _     => q.live ∧ ∃ r a b, x = Tup r a b
  | Mat _ _ _ => q.live ∧ ∃ j, x = Lab j
  | Efq       => False
  | _         => True

theorem fire_ok (wt : Book.WellTyped bk) (hf : Typed bk [] f (All q A B)) (hx : Typed bk [] x A)
    (vx : q.live = true → Value bk x) : Fire q x f := by
  have ⟨_, g, F, _⟩ := gen hf
  cases f <;> simp only [Fire, Gen] at g ⊢
  case Lam =>
    obtain ⟨_, _, _, rfl, pl, hq, _⟩ := g
    obtain ⟨rfl, hA, _⟩ := conv_all (fits_conv F)
    exact ⟨pl.symm, fun e => canon_data wt (vx (by subst e; exact pl)) (.conv hx (.inl (csym hA))) (hq e)⟩
  case Prj =>
    obtain ⟨_, _, _, _, _, rfl, l, _⟩ := g
    obtain ⟨rfl, hS, _⟩ := conv_all (fits_conv F)
    exact ⟨l, _, (canon_pair (ks := []) (a := Rfl) (b := Rfl) wt (vx l) hx).1 (csym hS)⟩
  case Mat =>
    obtain ⟨_, _, _, rfl, l, _⟩ := g
    obtain ⟨rfl, hE, _⟩ := conv_all (fits_conv F)
    exact ⟨l, (canon_enu wt (vx l) hx (csym hE)).imp fun _ => And.right⟩
  case Efq =>
    obtain ⟨_, _, rfl, l⟩ := g
    obtain ⟨rfl, hE, _⟩ := conv_all (fits_conv F)
    exact (canon_enu wt (vx l) hx (csym hE)).elim nofun

theorem arg_fire (wt : Book.WellTyped bk) (h : Typed bk [] (Term.spine t ((q, x) :: xs)) T)
    (vx : q.live = true → Value bk x) : Fire q x t :=
  let ⟨_, _, hf, hx⟩ := spine_arg h; fire_ok wt hf hx vx

-- an env entry is a value, unused, or a variable
def EnvOk (bk : Book) (e : List Term) (t : Term) : Prop :=
  ∀ i, Value bk (Env.sub e i) ∨ Term.uses t i = 0 ∨ ∃ w, Env.sub e i = Var w

theorem walk_go (wt : Book.WellTyped bk) (t : Term) : ∀ e xs T, (∃ g ps, Term.tree g ps t = true) →
    EnvOk bk e t → Values bk xs → Typed bk [] (Term.spine (Term.sub (Env.sub e) t) xs) T →
    ∃ o, Walk bk t e xs o := by
  have S := fun {t u T} => sr bk [] t u T wt
  have M : ∀ {e s t}, EnvOk bk e t →
      ∀ (_ : ∀ i, Term.uses s i ≤ Term.uses t i := by simp [Term.uses]), EnvOk bk e s :=
    fun hu le i => (hu i).imp_right (Or.imp_left fun h => by have := le i; omega)
  induction t <;> intro e xs T ⟨g, ps, ht⟩ hu vs hty
  case App q f y ihf ihy =>
    cases y
    case Var v =>
      cases hn : Term.takes (Term.unspine f []).1
      · exact ⟨_, .done hn⟩
      simp only [Term.tree, hn] at ht
      refine (ihf _ _ T ⟨_, _, ht⟩ (M hu) (.cons (fun l => ?_) vs) hty).imp fun _ => .app hn
      rcases hu v with h | h | ⟨_, h⟩
      · exact h
      · simp [Term.uses, l] at h
      · have ⟨_, _, _, hx⟩ := spine_arg hty; exact (no_var hx rfl h).elim
    all_goals exact ⟨_, .done rfl⟩
  all_goals first | exact ⟨_, .done rfl⟩ | (cases vs; exact ⟨_, .need rfl⟩)
  case Lam.cons p f ih x xs q vx vs =>
    have ⟨pl, dx⟩ : Fire q x (Lam p _) := arg_fire wt hty vx
    simp only [Term.tree, Bool.and_eq_true] at ht
    refine (ih (x :: e) xs T ⟨_, _, ht.2⟩ (fun | 0 => ?_ | i + 1 => hu i) vs
      (S hty (by rw [env_inst]; exact par_spine (a := App ..) (.beta (par_refl _) (par_refl _))))).imp
      fun _ => .lam pl dx
    cases p <;> first | exact .inl (vx (pl ▸ rfl)) | exact .inr (.inl (beq_iff_eq.1 ht.1))
  case Prj.cons h ih x xs q vx vs =>
    obtain ⟨l, r, _, _, rfl⟩ : Fire q x (Prj _) := arg_fire wt hty vx
    have ⟨va, vb⟩ := value_tup (vx l)
    exact (ih _ _ T ⟨_, _, ht⟩ hu
      (.cons (fun l' => va (by cases r <;> trivial)) (.cons (fun _ => vb) vs))
      (S hty (par_spine (a := App ..) (.split (par_refl _) (par_refl _) (par_refl _))))).imp fun _ => .prj l
  case Mat.cons k h m ihh ihm x xs q vx vs =>
    obtain ⟨l, j, rfl⟩ : Fire q x (Mat _ _ _) := arg_fire wt hty vx
    simp only [Term.tree, Bool.and_eq_true] at ht
    by_cases ej : j = k
    · subst ej
      exact (ihh _ _ T ⟨_, _, ht.1⟩ (M hu) vs
        (S hty (par_spine (a := App ..) (.hit (par_refl _))))).imp fun _ => .hit l
    · exact (ihm _ _ T ⟨_, _, ht.2⟩ (M hu)
        (.cons (fun _ => .lab) vs) (S hty (par_spine (a := App ..) (.miss ej (par_refl _))))).imp fun _ => .miss l ej
  case Efq.cons => exact (arg_fire (t := Efq) wt hty ‹_›).elim

theorem walk_total : Book.WellTyped bk → Book.Live bk → Book.get bk k = some d → Values bk xs →
    Typed bk [] (Term.spine (Ref k) xs) T → ∃ o, Walk bk d.v [] xs o := by
  intro wt lv hk vs h
  have ⟨i, hi⟩ := index_of_get hk
  refine walk_go wt _ _ _ T ⟨_, _, lv.2 k i d hi hk⟩ (fun i => .inr (.inr ⟨i, rfl⟩)) vs ?_
  rw [env_nil, sub_var]; exact sr _ _ _ _ _ wt h (par_spine (.delta hk (wt _ _ hk).2.2))

theorem call_ok (wt : Book.WellTyped bk) (lv : Book.Live bk) (hk : Book.get bk k = some d)
    (vs : Values bk xs) (h : Typed bk [] (Term.spine (Ref k) xs) T) :
    Value bk (Term.spine (Ref k) xs) ∨ ∃ u, Eval bk (Term.spine (Ref k) xs) u := by
  obtain ⟨_ | _, w⟩ := walk_total wt lv hk vs h
  · exact .inl (.call hk vs w)
  · exact .inr ⟨_, .call hk vs w⟩

theorem live_or (ih : Quan.live q = true → Value bk x ∨ ∃ u, Eval bk x u) :
    (Quan.live q = true → Value bk x) ∨ ∃ u, Quan.live q = true ∧ Eval bk x u := by
  cases l : Quan.live q; exact .inl nofun
  exact (ih l).imp (fun v _ => v) fun ⟨u, s⟩ => ⟨u, rfl, s⟩

theorem progress : Claim.progress := by
  intro bk t T wt lv h
  generalize eΓ : ([] : List Term) = Γ at h
  induction h <;> subst eΓ
  case var e => simp at e
  case ref hk => exact call_ok (xs := []) wt lv hk .nil (.ref (σ := Var) hk)
  case ann => exact .inr ⟨_, .ann⟩
  case lett hv hq _ ihv _ _ =>
    exact .inr <| (live_or fun _ => ihv rfl).elim
      (fun v => ⟨_, .unlet v fun e => canon_data wt (v (e ▸ rfl)) hv (hq e)⟩) fun ⟨_, l, s⟩ => ⟨_, .lett l s⟩
  case app hf hx ihf ihx =>
    refine (ihf rfl).elim (fun vf => ?_) fun ⟨_, s⟩ => .inr ⟨_, .app_f s⟩
    refine (live_or fun _ => ihx rfl).elim (fun vx => ?_) fun ⟨_, l, s⟩ => .inr ⟨_, .app_x vf l s⟩
    have F := fire_ok wt hf hx vx
    have C := canon_fun wt vf hf ⟨_, .refl, .refl⟩
    cases vf
    case lam => exact .inr ⟨_, .beta F.1 vx F.2⟩
    case prj => obtain ⟨l, _, _, _, rfl⟩ := F; exact .inr ⟨_, .split l (vx l)⟩
    case mat k _ _ => obtain ⟨l, j, rfl⟩ := F; exact .inr (if e : j = k then e ▸ ⟨_, .hit l⟩ else ⟨_, .miss l e⟩)
    case efq => exact F.elim
    case call hk vs _ =>
      rw [← spine_snoc]; exact call_ok wt lv hk (values_snoc.2 ⟨vs, vx⟩) (spine_snoc ▸ Typed.app hf hx)
    all_goals
      rcases C with e | ⟨_, _, e⟩; simp [Term.former] at e
      exact nomatch (congrArg Term.former e).trans (spine_ft ⟨rfl, rfl⟩).1
  case tup _ _ iha ihb =>
    exact (live_or fun _ => iha rfl).elim (fun va => (ihb rfl).imp (.tup va) fun ⟨_, s⟩ => ⟨_, .tup_b va s⟩)
      fun ⟨_, l, s⟩ => .inr ⟨_, .tup_a l s⟩
  case rwt _ he _ _ ihe _ _ =>
    exact .inr <| (ihe rfl).elim
      (fun ve => (canon_pair (r := Q0) (B := Rfl) (ks := []) wt ve he).2.2 ⟨_, .refl, .refl⟩ ▸ ⟨_, .cast⟩)
      fun ⟨_, s⟩ => ⟨_, .rwt s⟩
  case conv _ _ ih => exact ih rfl
  all_goals exact .inl (by constructor)

theorem empty : Claim.empty := fun _ _ wt v h =>
  (canon_enu wt v h ⟨_, .refl, .refl⟩).elim nofun

-- Termination
-- -----------

-- unfolds the live check into props
syntax "lv" (Lean.Parser.Tactic.location)? : tactic
macro_rules
  | `(tactic| lv $[$l]?) =>
    `(tactic| simp only [Term.Live, Term.live, Bool.and_eq_true, Bool.or_eq_true, Bool.not_eq_true'] $[$l]?)

-- the size of a term's live part
def Term.size : Term → Nat
  | Ann x _ => Term.size x + 1
  | Let q v f => (if q.live then Term.size v else 0) + Term.size f + 1
  | Lam _ f => Term.size f + 1
  | App q f x => Term.size f + (if q.live then Term.size x else 0) + 1
  | Tup q a b => (if q.live then Term.size a else 0) + Term.size b + 1
  | Prj h => Term.size h + 1
  | Mat _ h m => Term.size h + Term.size m + 1
  | Rwt e _ f => Term.size e + Term.size f + 1
  | _ => 1

-- a column's size: a closed value's live size, 0 when dead, none (ω)
-- when not yet a closed value
open Classical in
noncomputable def Arg.size (bk : Book) : Arg → Option Nat
  | (q, x) =>
    if q.live then
      if Value bk x ∧ Term.Closed x then some (Term.size x) else none
    else
      some 0

-- a call's label: its def's index + 1, and the sizes of its first n
-- arguments, where n bounds the columns of the def's tree; a redex
-- node's label is (0, []), below every call's
abbrev Label := Nat × List (Option Nat)

-- the first n entries of l, padded with none
def Pad : Nat → List (Option Nat) → List (Option Nat)
  | 0, _ => []
  | n + 1, l => l.headD none :: Pad n l.tail

noncomputable def Term.label (bk : Book) (k : String) (xs : List Arg) : Label :=
  let i := (Book.index bk k).getD 0 + 1
  let n := ((Book.get bk k).map (fun d => Term.size d.v)).getD 0
  (i, Pad n (xs.map (Arg.size bk)))

-- the labels of the live calls and redex nodes of a term; top is false
-- on an App head
noncomputable def Term.labels (bk : Book) : Bool → Term → List Label
  | top, App q f x =>
    let s :=
      match top, Term.unspine (App q f x) [] with
      | true, (Ref k, xs) => [Term.label bk k xs]
      | _,    _           => []
    let f := Term.labels bk false f
    let x := if q.live then Term.labels bk true x else []
    s ++ f ++ x
  | top, Ref k => if top then [Term.label bk k []] else []
  | _, Ann x _ => (0, []) :: Term.labels bk true x
  | _, Let q v f =>
    let v := if q.live then Term.labels bk true v else []
    (0, []) :: v ++ Term.labels bk true f
  | _, Lam _ f => (0, []) :: Term.labels bk true f
  | _, Tup q a b =>
    let a := if q.live then Term.labels bk true a else []
    a ++ Term.labels bk true b
  | _, Prj h => (0, []) :: Term.labels bk true h
  | _, Mat _ h m => (0, []) :: Term.labels bk true h ++ Term.labels bk true m
  | _, Rwt e _ f => (0, []) :: Term.labels bk true e ++ Term.labels bk true f
  | _, _ => []

def Size.lt : Option Nat → Option Nat → Prop
  | some a, some b => a < b
  | some _, none   => True
  | none,   _      => False

-- lexicographic order on lists of one length
inductive Lex (r : α → α → Prop) : List α → List α → Prop
  | head : r a b → as.length = bs.length → Lex r (a :: as) (b :: bs)
  | tail : Lex r as bs → Lex r (a :: as) (a :: bs)

def Label.lt (l m : Label) : Prop :=
  l.1 < m.1 ∨ (l.1 = m.1 ∧ Lex Size.lt l.2 m.2)

-- Dershowitz–Manna: replace one element by any number of smaller ones
def DM1 (r : α → α → Prop) (M N : List α) : Prop :=
  ∃ X x ys, List.Perm N (x :: X) ∧ List.Perm M (ys ++ X) ∧ ∀ y ∈ ys, r y x

def DM (r : α → α → Prop) : List α → List α → Prop :=
  Relation.TransGen (DM1 r)

def DMle (r : α → α → Prop) (M N : List α) : Prop :=
  List.Perm M N ∨ DM r M N

-- the measure: the multiset of labels
def Measure.lt (bk : Book) (u t : Term) : Prop :=
  DM Label.lt (Term.labels bk true u) (Term.labels bk true t)

theorem dm1_perm (h : DM1 r M N) (hm : List.Perm M M') (hn : List.Perm N N') : DM1 r M' N' :=
  let ⟨X, x, ys, h1, h2, h3⟩ := h; ⟨X, x, ys, hn.symm.trans h1, hm.symm.trans h2, h3⟩

theorem acc_perm (h : Acc (DM1 r) M) (hp : List.Perm M M') : Acc (DM1 r) M' :=
  ⟨_, fun _ d => h.inv (dm1_perm d (.refl _) hp.symm)⟩

-- the classic proof: accessibility of each element lifts to
-- accessibility of the lists built from it (Nipkow's formulation)
theorem dm_wf : WellFounded r → WellFounded (DM r) := by
  intro hr; classical
  refine WellFounded.transGen ⟨fun M => ?_⟩
  induction M with
  | nil => exact ⟨_, fun _ ⟨_, _, _, h, _⟩ => nomatch h.length_eq⟩
  | cons a M ih =>
    revert M
    induction a using hr.induction with
    | _ a iha =>
    have hZ : ∀ Z : List _, (∀ z ∈ Z, r z a) → ∀ N, Acc (DM1 r) N → Acc (DM1 r) (Z ++ N) := by
      intro Z; induction Z with
      | nil => exact fun _ _ => id
      | cons z Z ih => exact fun hz N h => iha z (hz z (.head _)) _ (ih (fun y hy => hz y (.tail _ hy)) N h)
    intro M hM
    induction hM with
    | intro M hM ihM =>
    refine ⟨_, fun M' ⟨X, x, ys, h1, h2, h3⟩ => ?_⟩
    by_cases e : a = x
    · subst e; exact acc_perm (hZ ys h3 _ ⟨_, hM⟩) ((h1.cons_inv.append_left ys).trans h2.symm)
    · have ha : a ∈ X := (List.mem_cons.1 (h1.subset (.head _))).resolve_left e
      have hX := List.perm_cons_erase ha
      exact acc_perm (ihM _ ⟨_, x, ys, (h1.trans ((hX.cons x).trans (.swap _ _ _))).cons_inv, .refl _, h3⟩)
        ((List.perm_middle.symm.trans (hX.append_left ys).symm).trans h2.symm)

theorem lex_len : Lex r a b → a.length = b.length := by
  intro h; induction h <;> simp_all

-- Nat.lt, then Lex over Size.lt on lists of one length, by
-- induction on the length
theorem label_wf : WellFounded Label.lt := by
  have hn : ∀ n, Acc Size.lt (some n) := fun n => Nat.strongRecOn n fun n ih => ⟨_, fun | some b, hb => ih b hb⟩
  have hs : WellFounded Size.lt := ⟨fun _ => ⟨_, fun | some b, _ => hn b⟩⟩
  have hl : ∀ n (l : List (Option Nat)), l.length = n → Acc (Lex Size.lt) l := by
    intro n; induction n with
    | zero => rintro (_ | _) ⟨⟩; exact ⟨_, nofun⟩
    | succ n ih =>
      rintro (_ | ⟨b, l⟩) hl <;> simp at hl
      induction b using hs.induction generalizing l with | _ b ihb =>
      induction ih l hl with | intro l _ ihl =>
      exact ⟨_, fun m h => by
        cases h with
        | head h e' => exact ihb _ h _ (e'.trans hl)
        | tail h => exact ihl _ h ((lex_len h).trans hl)⟩
  exact Subrelation.wf (Prod.lex_def.2 ·) (Prod.lex Nat.lt_wfRel ⟨_, ⟨fun l => hl _ l rfl⟩⟩).wf

theorem dm_app (h : DM r M N) : DM r (M ++ P) (N ++ P) := by
  have : ∀ {M N}, DM1 r M N → DM1 r (M ++ P) (N ++ P) := fun ⟨X, x, ys, h1, h2, h3⟩ =>
    ⟨X ++ P, x, ys, h1.append_right P, by simpa using h2.append_right P, h3⟩
  induction h with
  | single h => exact .single (this h)
  | tail _ h ih => exact .tail ih (this h)

theorem dm_perm (h : DM r M N) (hm : List.Perm M M') (hn : List.Perm N N') : DM r M' N' := by
  induction h generalizing N' with
  | single h => exact .single (dm1_perm h hm hn)
  | tail _ h ih => exact .tail (ih (.refl _)) (dm1_perm h (.refl _) hn)

theorem le_dm (h1 : DMle r M N) (h2 : DM r N P) : DM r M P :=
  h1.elim (fun p => dm_perm h2 p.symm (.refl _)) (·.trans h2)

theorem le_le (h1 : DMle r M N) (h2 : DMle r N P) : DMle r M P :=
  h2.elim (fun p => h1.elim (fun q => .inl (q.trans p)) (fun d => .inr (dm_perm d (.refl _) p)))
    (fun d => .inr (le_dm h1 d))

theorem dm_left (h : DM r N N') : DM r (P ++ N) (P ++ N') :=
  dm_perm (dm_app h) List.perm_append_comm List.perm_append_comm

-- DM is monotone: DMle on a part, DM on another, gives DM on the
-- sum; a label drops (ω to a size) when a column becomes a value
theorem dm_mono : DMle r M M' → DM r N N' → DM r (M ++ N) (M' ++ N') :=
  fun h1 h2 => h1.elim (fun p => dm_perm (dm_left h2) (.refl _) (p.append_right _))
    fun d => (dm_left h2).trans (dm_app d)

theorem le_app (h1 : DMle r M M') (h2 : DMle r N N') : DMle r (M ++ N) (M' ++ N') :=
  h2.elim (fun p => le_le (h1.elim (fun q => .inl (q.append_right _)) (fun d => .inr (dm_app d)))
    (.inl (p.append_left _))) (fun d => .inr (dm_mono h1 d))

theorem le_rfl : DMle r M M := .inl (.refl _)

theorem dm_repl (h : DMle r M N) (ho : ∀ y ∈ O, r y x) : DM r (O ++ M) (x :: N) :=
  le_dm (le_app le_rfl h) (.single ⟨N, x, O, .refl _, .refl _, ho⟩)

theorem dm_cons (h : DMle r M N) : DM r M (x :: N) := dm_repl (O := []) h nofun

theorem le_nil : DMle r [] N := by
  induction N; exact le_rfl; exact .inr (dm_cons ‹_›)


-- Labels
-- ------

def Size.le (a b : Option Nat) : Prop := a = b ∨ Size.lt a b

-- pointwise ≤ on size lists; the right one may be shorter (ω after it)
inductive SL : List (Option Nat) → List (Option Nat) → Prop
  | nil : SL l []
  | cons : Size.le a b → SL l m → SL (a :: l) (b :: m)

abbrev ArgsLe (bk : Book) (xs ys : List Arg) : Prop :=
  SL (xs.map (Arg.size bk)) (ys.map (Arg.size bk))

-- the label of a spine's head
noncomputable def Term.hd (bk : Book) : Term × List Arg → List Label
  | (Ref k, xs) => [Term.label bk k xs]
  | _ => []

noncomputable def Args.labels (bk : Book) : List Arg → List Label
  | [] => []
  | (q, x) :: xs => (if q.live then Term.labels bk true x else []) ++ Args.labels bk xs

theorem size_le_none : Size.le a none := by
  cases a <;> simp [Size.le, Size.lt]

theorem sl_app : SL (l ++ m) l := by
  induction l; exact .nil; exact .cons (.inl rfl) ‹_›

theorem sl_refl : SL l l := by simpa using sl_app (l := l) (m := [])

theorem pad_len : (Pad n l).length = n := by
  induction n generalizing l <;> simp_all [Pad]

theorem pad_le (h : SL A B) : Pad n A = Pad n B ∨ Lex Size.lt (Pad n A) (Pad n B) := by
  induction n generalizing A B with
  | zero => exact .inl rfl
  | succ n ih =>
    have : Size.le (A.headD none) (B.headD none) ∧ SL A.tail B.tail := by
      cases h <;> simp [size_le_none, SL.nil, *]
    rcases this.1 with e | e
    · rcases ih this.2 with e' | e' <;> simp only [Pad, e, e', eq_self, true_or]
      exact .inr (.tail e')
    · exact .inr (.head e (by simp [pad_len]))

theorem label_le (h : ArgsLe bk xs ys) : DMle Label.lt [Term.label bk k xs] [Term.label bk k ys] := by
  simp only [Term.label]
  exact (pad_le h).elim (fun e => .inl (by rw [e]))
    fun e => .inr (dm_repl (O := [_]) le_nil fun y hy => List.mem_singleton.1 hy ▸ .inr ⟨rfl, e⟩)

theorem hd_le (h : ArgsLe bk xs ys) : DMle Label.lt (Term.hd bk (t, xs)) (Term.hd bk (t, ys)) := by
  cases t <;> first | exact le_rfl | exact label_le h

theorem unspine_app : Term.unspine t xs = ((Term.unspine t []).1, (Term.unspine t []).2 ++ xs) := by
  induction t generalizing xs with
  | App q f x ihf _ => simp only [Term.unspine]; rw [ihf, ihf (xs := [(q, x)])]; simp
  | _ => rfl

theorem labels_app : Term.labels bk false (App q f x) =
    Term.labels bk false f ++ (if q.live then Term.labels bk true x else []) := by
  simp [Term.labels]

theorem labels_top (t : Term) :
    Term.labels bk true t = Term.hd bk (Term.unspine t []) ++ Term.labels bk false t := by
  cases t <;> try rfl
  case App q f x =>
    simp only [Term.labels]
    cases Term.unspine (App q f x) [] with | mk h _ => cases h <;> simp [Term.hd]

theorem labels_spine (t : Term) (es : List Arg) : Term.labels bk true (Term.spine t es) =
    Term.hd bk (Term.unspine t es) ++ Term.labels bk false t ++ Args.labels bk es := by
  induction es generalizing t with
  | nil => simp [Term.spine, Args.labels, labels_top]
  | cons e es ih => simp [Term.spine, ih, Term.unspine, labels_app, Args.labels]

theorem args_append : Args.labels bk (xs ++ ys) = Args.labels bk xs ++ Args.labels bk ys := by
  induction xs <;> simp [Args.labels, *]

theorem hd_ext : DMle Label.lt (Term.hd bk (Term.unspine u es)) (Term.hd bk (Term.unspine u [])) := by
  rw [unspine_app (xs := es)]; exact hd_le (by simpa [ArgsLe] using sl_app)

-- extra arguments only lower the head's label
theorem labels_ext (u : Term) (es : List Arg) : DMle Label.lt (Term.labels bk true (Term.spine u es))
    (Term.labels bk true u ++ Args.labels bk es) := by
  rw [labels_spine, labels_top]; exact le_app (le_app hd_ext le_rfl) le_rfl

theorem size_sub : Size.le (Arg.size bk (q, Term.sub σ y)) (Arg.size bk (q, y)) := by
  by_cases h : Value bk y ∧ Term.Closed y
  · rw [h.2 σ]; exact .inl rfl
  · simp only [Arg.size, h]; split <;> first | exact size_le_none | exact .inl rfl


-- Closed terms, uses
-- ------------------

theorem closed_ren (h : Term.Closed t) : Term.ren r t = t := by
  rw [ren_as_sub]; exact h _

theorem closed_iff : Term.Closed t ↔ Term.ren Nat.succ t = t :=
  ⟨closed_ren, ren_closed⟩

-- splits a closed term into its closed parts
macro "cl" t:term : tactic => `(tactic| simpa [closed_iff, Term.ren] using $t)

-- Par keeps the terms that a renaming fixes, so Pars keeps Closed
theorem par_fix (h : Par bk t u) : Term.ren r t = t → Term.ren r u = u := by
  induction h generalizing r <;> simp_all [Term.ren, ren_inst, closed_ren]

theorem pars_closed (p : Pars bk t u) (c : Term.Closed t) : Term.Closed u := by
  induction p with
  | refl => exact c
  | step s _ ih => exact ih (ren_closed (par_fix s (closed_ren c)))

theorem closed_spine : Term.Closed (Term.spine t as) ↔ Term.Closed t ∧ ∀ a ∈ as, Term.Closed a.2 := by
  induction as generalizing t with
  | nil => simp [Term.spine]
  | cons a as ih => simp [Term.spine, ih, closed_iff, Term.ren, and_assoc]

theorem closed_uses (h : Term.Closed y) : Term.uses y i = 0 := by
  have (t : Term) : ∀ {r i}, (∀ v, i ≠ r v) → Term.uses (Term.ren r t) i = 0 := by
    have up : ∀ {r : Ren} {i}, (∀ v, i ≠ r v) → ∀ v, i + 1 ≠ Ren.up r v := fun h v => by
      cases v <;> simp [Ren.up, h]
    induction t <;> intro r i h
    case Let ihv ihf => simp [Term.ren, Term.uses, ihv h, ihf (up h)]
    case Lam ih => exact ih (up h)
    all_goals simp_all [Term.ren, Term.uses]
  exact closed_ren (r := (· + i + 1)) h ▸ this y fun v => by omega

-- τ keeps each variable below n, and sends the others to closed terms
-- or to variables from n on
def UH (τ : Subst) (n : Nat) : Prop :=
  ∀ v, (v < n → τ v = Var v) ∧ (n ≤ v → (∃ w, n ≤ w ∧ τ v = Var w) ∨ Term.Closed (τ v))

theorem uh_up (h : UH τ n) : UH (Subst.up τ) (n + 1) := by
  rintro (_ | v)
  · exact ⟨fun _ => rfl, by omega⟩
  obtain ⟨h1, h2⟩ := h v
  refine ⟨fun e => by simp [Subst.up, h1 (by omega), Term.ren], fun e => ?_⟩
  rcases h2 (by omega) with ⟨w, hw, e'⟩ | hc
  · simp [Subst.up, e', Term.ren, hw]
  · simp [Subst.up, closed_ren hc, hc]

theorem uses_sub (t : Term) : UH τ n → i < n → Term.uses (Term.sub τ t) i = Term.uses t i := by
  induction t generalizing τ n i <;> intro h hi
  case Var v =>
    obtain ⟨h1, h2⟩ := h v
    by_cases e : v < n
    · simp [Term.sub, h1 e]
    · rcases h2 (by omega) with ⟨w, hw, e'⟩ | hc <;>
        simp [Term.sub, Term.uses, closed_uses, *, show i ≠ v by omega] <;> omega
  case Let ihv ihf => simp [Term.sub, Term.uses, ihv h hi, ihf (uh_up h) (Nat.succ_lt_succ hi)]
  case Lam ih => exact ih (uh_up h) (Nat.succ_lt_succ hi)
  case App iha ihb | Tup iha ihb | Mat iha ihb | Rwt iha _ ihb =>
    simp [Term.sub, Term.uses, iha h hi, ihb h hi]
  case Ann ih _ | Prj ih => exact ih h hi
  all_goals rfl

-- Live terms
-- ----------

def RefOK (bk : Book) (u : Term) : Prop :=
  ∀ k, (Term.unspine u []).1 = Ref k → (Book.index bk k).isSome

theorem index_lt : Book.index bk k = some j → j < bk.length :=
  fun h => (List.findIdx?_eq_some_iff_findIdx_eq.1 h).1

theorem called_ok : Term.called g u = true → RefOK g.book u := by
  intro h k e
  unfold Term.called at h
  generalize Term.unspine u [] = p at h e
  obtain ⟨_, xs⟩ := p; subst e
  simp only at h; split at h <;> simp_all

theorem ok_called (hi : g.self = g.book.length) (h : RefOK g.book u) : Term.called g u = true := by
  simp only [Term.called]; split
  next k _ e => obtain ⟨j, hj⟩ := Option.isSome_iff_exists.1 (h k (by rw [e])); simp [hj, hi, index_lt hj]
  next => rfl

theorem live_call (h : Term.live g true t = true) (e : Term.unspine t [] = (Ref k, ys)) :
    ∃ j, Book.index g.book k = some j ∧ (j < g.self ∨ (j = g.self ∧ Arg.descend g 0 ys = .lt)) := by
  have c : Term.called g t = true := by
    cases t <;> simp [Term.live] at h
    case App => exact h.1.1
    case Ref => exact h
    all_goals cases e
  simp only [Term.called, e] at c
  split at c <;> simp at c
  exact ⟨_, ‹_›, c⟩

theorem live_ok : Term.live g true u = true → RefOK g.book u :=
  fun h _ e => let ⟨_, hj, _⟩ := live_call h (Prod.ext e rfl); by simp [hj]

theorem live_mono : Term.live g true u = true → Term.live g false u = true := by
  cases u <;> simp_all [Term.live]

-- σ's used values are closed and live at any outer guard
def LiveV (bk : Book) (σ : Subst) (t : Term) : Prop :=
  ∀ v, (∃ w, σ v = Var w) ∨ (Term.Closed (σ v) ∧ (Term.uses t v ≠ 0 →
    ∀ G : Guard, G.book = bk → G.self = bk.length → Term.live G true (σ v) = true))

theorem livev_mono (h : LiveV bk σ t)
    (hu : ∀ v, Term.uses t' v ≠ 0 → Term.uses t v ≠ 0 := by intro v n; simp_all [Term.uses]) :
    LiveV bk σ t' :=
  fun v => (h v).imp_right fun ⟨c, u⟩ => ⟨c, fun n => u (hu v n)⟩

theorem livev_up (h : LiveV bk σ t) (hu : ∀ v, Term.uses f (v + 1) ≠ 0 → Term.uses t v ≠ 0) :
    LiveV bk (Subst.up σ) f := by
  rintro (_ | v)
  · exact .inl ⟨0, rfl⟩
  rcases h v with ⟨w, e⟩ | ⟨c, u⟩
  · simp [Subst.up, e, Term.ren]
  · simp only [Subst.up, closed_ren c]; exact .inr ⟨c, fun n => u (hu v n)⟩

theorem uh_live (h : LiveV bk σ t) : UH (Subst.up σ) 1 :=
  uh_up fun v => ⟨by omega, fun _ => (h v).imp (fun ⟨w, e⟩ => ⟨w, by omega, e⟩) And.left⟩

theorem qlive {q : Quan} (ih : q.live = true → A → B) (h : q.live = false ∨ A) : q.live = false ∨ B := by
  cases hq : q.live <;> simp_all

theorem spine_unspine : Term.spine (Term.unspine t xs).1 (Term.unspine t xs).2 = Term.spine t xs := by
  induction t generalizing xs with
  | App q f x ih _ => exact ih
  | _ => rfl

theorem uses_spine : Term.uses h v ≤ Term.uses (Term.spine h ys) v ∧
    ∀ a ∈ ys, a.1.live = true → Term.uses a.2 v ≤ Term.uses (Term.spine h ys) v := by
  induction ys generalizing h with
  | nil => simp [Term.spine]
  | cons a ys ih =>
    have ⟨h1, h2⟩ := ih (h := App a.1 h a.2)
    refine ⟨Nat.le_trans (by simp [Term.uses]) h1, fun b m hq => ?_⟩
    cases m; exact Nat.le_trans (by simp [Term.uses, hq]) h1; exact h2 b ‹_› hq

theorem head_used (h : (Term.unspine t []).1 = Var v) : Term.uses t v ≠ 0 := by
  have := (uses_spine (h := (Term.unspine t []).1) (v := v) (ys := (Term.unspine t []).2)).1
  rw [spine_unspine, h] at this; simp [Term.uses, Term.spine] at this; omega

theorem ok_app : RefOK bk (App q t x) ↔ RefOK bk t := by
  simp only [RefOK, Term.unspine]; rw [unspine_app]

theorem ref_sub (h : RefOK bk t) (hv : ∀ v, (Term.unspine t []).1 = Var v → RefOK bk (σ v)) :
    RefOK bk (Term.sub σ t) := by
  induction t with
  | App q f x ih _ =>
    refine ok_app.2 (ih (ok_app.1 h) fun v e => hv v ?_)
    rwa [Term.unspine, unspine_app]
  | Var v => exact hv v rfl
  | _ => first | exact h | intro k hk; cases hk

theorem live_sub (t : Term) : ∀ {g G : Guard} {σ top}, G.book = g.book → G.self = G.book.length →
    LiveV G.book σ t → Term.live g top t = true → Term.live G top (Term.sub σ t) = true := by
  induction t <;> intro g G σ top hb hi hv h <;> simp only [Term.sub] <;> lv at h ⊢
  case Var v =>
    rcases hv v with ⟨w, e⟩ | ⟨_, h⟩
    · simp [e, Term.live]
    · have := h (by simp [Term.uses]) G rfl hi
      exact top.rec (live_mono this) this
  case Ref => exact h.imp_right fun c => ok_called hi (hb ▸ called_ok c)
  case App q f x ihf ihx =>
    refine ⟨⟨h.1.1.imp_right fun c => ok_called hi ?_, ihf hb hi (livev_mono hv) h.1.2⟩,
      qlive (fun hq => ihx hb hi (livev_mono hv)) h.2⟩
    refine ref_sub (t := App q f x) (hb ▸ called_ok c) fun v e => ?_
    rcases hv v with ⟨w, e'⟩ | ⟨_, u⟩
    · intro k hk; simp [e', Term.unspine] at hk
    · exact live_ok (u (head_used e) G rfl hi)
  case Lam f ih =>
    exact ⟨uses_sub f (uh_live hv) Nat.one_pos ▸ h.1,
      ih (g := g.bind none) (G := G.bind none) hb hi (livev_up hv fun _ n => n) h.2⟩
  case Let f ihv ihf =>
    exact ⟨⟨uses_sub f (uh_live hv) Nat.one_pos ▸ h.1.1,
      qlive (fun hq => ihv hb hi (livev_mono hv)) h.1.2⟩,
      ihf (g := g.bind none) (G := G.bind none) hb hi (livev_up hv fun _ n => by simp [Term.uses, n]) h.2⟩
  case Tup iha ihb =>
    exact ⟨qlive (fun hq => iha hb hi (livev_mono hv)) h.1, ihb hb hi (livev_mono hv) h.2⟩
  case Mat iha ihb | Rwt iha _ ihb =>
    exact ⟨iha hb hi (livev_mono hv) h.1, ihb hb hi (livev_mono hv) h.2⟩
  case Prj ih | Ann ih _ => exact ih hb hi (livev_mono hv) h


theorem live_up (h : Term.live g top u = true) (hb : G.book = g.book) (hi : G.self = G.book.length) :
    Term.live G top u = true :=
  sub_var u ▸ live_sub u hb hi (fun v => .inl ⟨v, rfl⟩) h

theorem called_iff (hi : g.self = g.book.length) : Term.called g u = true ↔ RefOK g.book u :=
  ⟨called_ok, ok_called hi⟩

theorem live_top (hi : g.self = g.book.length) :
    Term.live g true u = true ↔ RefOK g.book u ∧ Term.live g false u = true := by
  refine ⟨fun h => ⟨live_ok h, live_mono h⟩, fun ⟨h1, h2⟩ => ?_⟩
  cases u <;> simp_all [Term.live]
  case App | Ref => exact ok_called hi h1

theorem live_spine : Term.Live bk (Term.spine t as) ↔
    Term.Live bk t ∧ ∀ a ∈ as, a.1.live = true → Term.Live bk a.2 := by
  induction as generalizing t with
  | nil => simp [Term.spine]
  | cons a as ih =>
    obtain ⟨q, x⟩ := a
    rw [Term.spine, ih]
    cases hq : q.live <;> simp [Term.Live, live_top (g := ⟨bk, bk.length, [], [], []⟩) rfl, Term.live,
      called_iff (g := ⟨bk, bk.length, [], [], []⟩) rfl, ok_app, and_assoc, hq]

-- Budgets
-- -------

-- a binder's view of ls: its own variable has no labels
def Bud.up (ls : Nat → List Label) : Nat → List Label
  | 0 => []
  | v + 1 => ls v

-- the labels that t's live variables get from ls, once per live use
def Term.bud (ls : Nat → List Label) : Term → List Label
  | Var i => ls i
  | Ann x _ => Term.bud ls x
  | Let q v f => (if q.live then Term.bud ls v else []) ++ Term.bud (Bud.up ls) f
  | Lam _ f => Term.bud (Bud.up ls) f
  | App q f x => Term.bud ls f ++ (if q.live then Term.bud ls x else [])
  | Tup q a b => (if q.live then Term.bud ls a else []) ++ Term.bud ls b
  | Prj h => Term.bud ls h
  | Mat _ h m => Term.bud ls h ++ Term.bud ls m
  | Rwt e _ f => Term.bud ls e ++ Term.bud ls f
  | _ => []

-- no labels in, none out
theorem bud_nil (t : Term) : ∀ {ls : Nat → List Label}, (∀ v, ls v = []) → Term.bud ls t = [] := by
  have up : ∀ {ls : Nat → List Label}, (∀ v, ls v = []) → ∀ v, Bud.up ls v = [] :=
    fun h v => by cases v <;> simp [Bud.up, h]
  induction t <;> intro ls h <;> simp_all [Term.bud]

theorem le_sub' : DMle r N (M ++ N) := le_app le_nil le_rfl

theorem le_sub : DMle r M (M ++ N) := le_le le_sub' (.inl List.perm_append_comm)

-- two parts, each below its rest and a leftover: the rests, then the
-- leftovers
theorem once2 (h1 : DMle r A (A' ++ X)) (h2 : DMle r B (B' ++ Y)) (h3 : DMle r (X ++ Y) Z) :
    DMle r (A ++ B) (A' ++ B' ++ Z) :=
  le_le (le_app h1 h2)
    (le_le (.inl (by simp [List.perm_append_left_iff, List.perm_append_comm_assoc])) (le_app le_rfl h3))

-- the leftovers of two parts' a and b uses fit in one: a variable used
-- twice has no labels
theorem once_add (h : 2 ≤ a + b → l = []) :
    DMle r ((if a = 0 then [] else l) ++ (if b = 0 then [] else l)) (if a + b = 0 then [] else l) := by
  by_cases hu : 2 ≤ a + b
  · simpa [h hu] using le_rfl
  · refine .inl (.of_eq ?_)
    split <;> split <;> simp_all <;> omega

-- a dead part adds no labels and no uses
theorem once_if {q : Quan} (h : q.live = true → DMle r A (A' ++ (if u = 0 then [] else l))) :
    DMle r (if q.live then A else [])
      ((if q.live then A' else []) ++ (if (if q.live then u else 0) = 0 then [] else l)) := by
  cases hq : q.live <;> simp [le_rfl, h, hq]

-- a variable used once, or of no labels, gives its labels once
theorem bud_once (t : Term) : ∀ {ls : Nat → List Label} {i}, (2 ≤ Term.uses t i → ls i = []) →
    DMle Label.lt (Term.bud ls t)
      (Term.bud (fun v => if v = i then [] else ls v) t ++ (if Term.uses t i = 0 then [] else ls i)) := by
  have up : ∀ {ls : Nat → List Label} {i}, Bud.up (fun v => if v = i then [] else ls v) =
      fun v => if v = i + 1 then [] else Bud.up ls v := funext fun v => by cases v <;> simp [Bud.up]
  induction t <;> intro ls i h <;> simp only [Term.bud, Term.uses, up] at h ⊢
  case Var j => by_cases e : j = i <;> simp [e, Ne.symm] <;> exact le_rfl
  case App ihf ihx =>
    exact once2 (ihf fun e => h (by omega)) (once_if fun hq => ihx fun e => h (by simp [hq]; omega)) (once_add h)
  case Let iha ihb | Tup iha ihb =>
    exact once2 (once_if fun hq => iha fun e => h (by simp [hq]; omega)) (ihb fun e => h (by omega)) (once_add h)
  case Mat iha ihb | Rwt iha _ ihb =>
    exact once2 (iha fun e => h (by omega)) (ihb fun e => h (by omega)) (once_add h)
  case Lam ih | Prj ih | Ann ih _ => exact ih h
  all_goals exact le_nil

-- the image of a substitution under the labels, and its used budget
def Good (L : Label) (P : Prop) (A B C : List Label) : Prop :=
  ∃ O, DMle Label.lt A (O ++ B) ∧ DMle Label.lt O C ∧ (P → ∀ l ∈ O, Label.lt l L)

theorem good_nil : Good L P [] B [] := ⟨[], le_nil, le_rfl, by simp⟩

theorem good_cons (hL : 0 < L.1) (h : Good L P A B C) : Good L P ((0, []) :: A) B ((0, []) :: C) :=
  let ⟨O, h1, h2, h3⟩ := h
  ⟨(0, []) :: O, le_app (le_rfl (M := [_])) h1, le_app (le_rfl (M := [_])) h2,
    fun p l hl => (List.mem_cons.1 hl).elim (fun e => e ▸ .inl hL) (h3 p l)⟩

theorem good_app (h1 : Good L P A1 B1 C1) (h2 : Good L P A2 B2 C2) :
    Good L P (A1 ++ A2) (B1 ++ B2) (C1 ++ C2) :=
  let ⟨O1, a1, b1, c1⟩ := h1; let ⟨O2, a2, b2, c2⟩ := h2
  ⟨O1 ++ O2, once2 a1 a2 le_rfl, le_app b1 b2,
    fun p l hl => (List.mem_append.1 hl).elim (c1 p l) (c2 p l)⟩

theorem good_mono (h : Good L P A B C) (hp : P' → P) : Good L P' A B C :=
  let ⟨O, a, b, c⟩ := h; ⟨O, a, b, fun p => c (hp p)⟩


-- Frames
-- ------

-- a call of def k (index i, body d) on xs, inside a spine that adds zs;
-- cs are the columns its walk made so far
structure Frame where
  bk : Book
  k : String
  i : Nat
  d : Def
  xs : List Arg
  zs : List Arg
  cs : List Bool
  hs : List ((Nat × List Bool) × String)

noncomputable def Frame.L (F : Frame) : Label := Term.label F.bk F.k (F.xs ++ F.zs)

abbrev Frame.g (F : Frame) (ts : List Tag) : Guard := ⟨F.bk, F.i, F.cs, ts, F.hs⟩

-- the args are closed, and live ones are live values
def AOK (bk : Book) (as : List Arg) : Prop :=
  ∀ a ∈ as, Term.Closed a.2 ∧ (a.1.live = true → Value bk a.2 ∧ Term.Live bk a.2)

-- the columns are the liveness of the first args
def CS (xs : List Arg) (cs : List Bool) : Prop :=
  cs = (xs.map (·.1.live)).take cs.length

-- the piece at path π of t: each step, innermost first, takes a pair's
-- live first field (false) or its second (true)
def Term.get : List Bool → Term → Option Term
  | [], t => some t
  | b :: π, t =>
    match Term.get π t with
    | some (Tup r x y) => if b then some y else if r.live then some x else none
    | _ => none

-- the piece at path π of column c
def Arg.at (xs : List Arg) (c : Nat) (π : List Bool) : Option Term :=
  xs[c]?.bind fun a => Term.get π a.2

-- the labels hs recorded are the labels at their paths
def Hits (xs : List Arg) (hs : List ((Nat × List Bool) × String)) : Prop :=
  ∀ c π k, ((c, π), k) ∈ hs → Arg.at xs c π = some (Lab k)

def Frame.ok (F : Frame) : Prop :=
  Book.index F.bk F.k = some F.i ∧ Book.get F.bk F.k = some F.d ∧ AOK F.bk F.xs ∧
  F.cs.length ≤ Term.size F.d.v ∧ CS F.xs F.cs ∧ Hits F.xs F.hs

-- a live use of a tagged variable holds the piece its tag names
def Frame.tags (F : Frame) (ts : List Tag) (σ : Subst) (t : Term) : Prop :=
  ∀ v c π, ts[v]? = some (some (c, π)) → Term.uses t v ≠ 0 → Arg.at F.xs c π = some (σ v)

theorem tags_mono {F : Frame} (h : F.tags ts σ t)
    (hu : ∀ v, Term.uses t' v ≠ 0 → Term.uses t v ≠ 0 := by intro v n; simp_all [Term.uses]) :
    F.tags ts σ t' := fun v c o e n => h v c o e (hu v n)

theorem get_le (h : Term.get π X = some Y) : Term.size Y + π.length ≤ Term.size X := by
  induction π generalizing Y with
  | nil => cases h; simp
  | cons b π ih =>
    simp only [Term.get] at h; split at h
    next e =>
      have := ih e; simp only [Term.size] at this
      split at h <;> (try split at h) <;> cases h <;> simp_all <;> omega
    next => cases h

theorem get_val (hc : Term.Closed X) (h : Term.get π X = some Y) :
    Term.Closed Y ∧ (Value bk X → Value bk Y) := by
  induction π generalizing Y with
  | nil => cases h; exact ⟨hc, id⟩
  | cons b π ih =>
    simp only [Term.get] at h; split at h
    next r x y e =>
      have ⟨c, v⟩ := ih e
      have ⟨ca, cb⟩ : Term.Closed x ∧ Term.Closed y := by cl c
      split at h <;> (try split at h) <;> cases h
      · exact ⟨cb, fun h => (value_tup (v h)).2⟩
      · exact ⟨ca, fun h => (value_tup (v h)).1 ‹_›⟩
    next => cases h

theorem at_cons (h : Arg.at xs c π = some (Tup r x y)) :
    Arg.at xs c (true :: π) = some y ∧ (r.live = true → Arg.at xs c (false :: π) = some x) := by
  simp only [Arg.at, Option.bind_eq_some_iff] at h ⊢
  obtain ⟨a, ha, h⟩ := h
  exact ⟨⟨a, ha, by simp [Term.get, h]⟩, fun l => ⟨a, ha, by simp [Term.get, h, l]⟩⟩

-- t's head call, under σ and on es, is below the frame's call
def Frame.hc (F : Frame) (σ : Subst) (t : Term) (es : List Arg) : Prop :=
  ∀ k ys, Term.unspine t [] = (Ref k, ys) →
    Label.lt (Term.label F.bk k (ys.map (fun a => (a.1, Term.sub σ a.2)) ++ es)) F.L

theorem values_mem (h : Values bk xs) (m : a ∈ xs) (hl : a.1.live = true) : Value bk a.2 := by
  induction xs with
  | nil => cases m
  | cons _ _ ih =>
    cases h with | cons hx hs => cases m; exact hx hl; exact ih hs ‹_›

theorem index_key (h : Book.index bk k = some j) : ∃ hj : j < bk.length, bk[j].k = k := by
  obtain ⟨hj, hp, _⟩ := List.findIdx?_eq_some_iff_getElem.1 h
  exact ⟨hj, by simpa using hp⟩

-- a rebuild of the piece at π of a column of value X is a closed value,
-- no bigger than that piece
theorem pos_ok {F : Frame} (ho : F.ok) (ha : F.xs[c]? = some (qa, X)) (hv : Value F.bk X)
    (x : Term) : ∀ {π}, F.tags ts σ x → π ∈ Term.pos (F.g ts) c x →
    ∃ y, Term.get π X = some y ∧ Value F.bk (Term.sub σ x) ∧ Term.Closed (Term.sub σ x) ∧
      Term.size (Term.sub σ x) ≤ Term.size y := by
  have hX := (ho.2.2.1 _ (List.mem_of_getElem? ha)).1
  have A : ∀ {π}, Arg.at F.xs c π = Term.get π X := by simp [Arg.at, ha]
  induction x <;> intro π ht hp <;> simp only [Term.pos] at hp
  case Var v =>
    split at hp <;> simp at hp
    obtain ⟨rfl, rfl⟩ := hp
    have h := A ▸ ht v _ _ ‹_› (by simp [Term.uses])
    have g := get_val (bk := F.bk) hX h
    exact ⟨_, h, g.2 hv, g.1, Nat.le_refl _⟩
  case Lab k =>
    simp at hp; obtain ⟨_, _, _, m, ⟨rfl, rfl⟩, rfl⟩ := hp
    exact ⟨_, A ▸ ho.2.2.2.2.2 _ _ _ m, .lab, fun _ => rfl, Nat.le_refl _⟩
  case Tup iha ihb =>
    split at hp <;> simp at hp
    rename_i l
    obtain ⟨π', mb, e⟩ := hp
    split at e <;> simp at e
    obtain ⟨ma, rfl⟩ := e
    have ⟨yb, gb, vb, cb, sb⟩ := ihb (tags_mono ht) mb
    have ⟨ya, ga, va, ca, sa⟩ := iha (tags_mono ht) ma
    simp only [Term.get] at gb ga; split at gb <;> simp at gb
    rename_i e; simp [e] at ga; obtain ⟨lr, rfl⟩ := ga; subst gb
    refine ⟨_, e, .tup (fun _ => va) vb, by simp only [Term.sub]; cl And.intro ca cb, ?_⟩
    simp [Term.sub, Term.size, l, lr]; omega
  all_goals cases hp

-- column j holds xa, of the liveness of arg (q, y): an eq arg is no
-- bigger, a lt arg is smaller
theorem cmp_size {F : Frame} (ho : F.ok) (ht : q.live = true → F.tags ts σ y)
    (e : F.cs[j]? = some q.live) (ha : F.xs[j]? = some (qa, xa)) (hl : qa.live = q.live) :
    (Arg.cmp (F.g ts) j (q, y) = .eq →
      Size.le (Arg.size F.bk (q, Term.sub σ y)) (Arg.size F.bk (qa, xa))) ∧
    (Arg.cmp (F.g ts) j (q, y) = .lt →
      Size.lt (Arg.size F.bk (q, Term.sub σ y)) (Arg.size F.bk (qa, xa))) := by
  simp only [Arg.cmp, e, bne_self_eq_false, Bool.false_eq_true, ite_false]
  cases hq : q.live
  · simp [Arg.size, hq, hl, Size.le]
  have ⟨c2, v2⟩ := ho.2.2.1 _ (List.mem_of_getElem? ha)
  have v2 := (v2 (hl.trans hq)).1
  simp only [ite_true, Term.piece, Arg.size, hl, hq, v2, c2, and_self]
  split
  · rename_i h0
    have ⟨_, g, v, c, s⟩ := pos_ok ho ha v2 y (ht hq) (List.contains_iff_mem.1 h0); cases g
    refine ⟨fun _ => ?_, nofun⟩; rw [ite_eq_left ⟨v, c⟩]
    exact (Nat.eq_or_lt_of_le s).imp (congrArg some) id
  split; · simp
  rename_i h0 h1
  obtain ⟨π, m⟩ := List.exists_mem_of_ne_nil _ (by simpa using h1)
  have ⟨_, g, v, c, s⟩ := pos_ok ho ha v2 y (ht hq) m
  have := get_le g
  refine ⟨nofun, fun _ => ?_⟩; rw [ite_eq_left ⟨v, c⟩]
  cases π
  · exact absurd (List.contains_iff_mem.2 m) h0
  · simp at this; show _ < _; omega

-- a descent from column j on: column by column, the call's sizes are
-- no bigger than B's until one is smaller
theorem desc_lex {F : Frame} (ho : F.ok) (ys : List Arg) :
    ∀ j n (B : List (Option Nat)), (∀ a ∈ ys, a.1.live = true → F.tags ts σ a.2) →
    Arg.descend (F.g ts) j ys = .lt → F.cs.length ≤ j + n →
    (∀ c a, F.xs[j + c]? = some a → B[c]? = some (Arg.size F.bk a)) →
    Lex Size.lt (Pad n ((ys.map (fun a => (a.1, Term.sub σ a.2)) ++ es).map (Arg.size F.bk))) (Pad n B) := by
  induction ys with
  | nil => simp [Arg.descend]
  | cons y ys ih =>
    obtain ⟨q, y⟩ := y
    intro j n B hu d hn hB
    simp only [Arg.descend] at d
    have e : F.cs[j]? = some q.live := Classical.byContradiction fun e => by simp [Arg.cmp, e] at d
    obtain ⟨⟨qa, xa⟩, ha, hl⟩ : ∃ a : Arg, F.xs[j]? = some a ∧ a.1.live = q.live := by
      rw [ho.2.2.2.2.1] at e; simp [List.getElem?_take] at e; simpa using e.2
    have C := cmp_size ho (hu _ (.head _)) e ha hl
    cases n; have := (List.getElem?_eq_some_iff.1 e).1; omega
    cases B with
    | nil => cases hB 0 _ ha
    | cons b B =>
    obtain rfl : b = Arg.size F.bk (qa, xa) := by simpa using hB 0 _ ha
    cases h : Arg.cmp (F.g ts) j (q, y) <;> rw [h] at d
    · exact .head (C.2 h) (by simp [pad_len])
    · rcases C.1 h with s | s
      · simp only [Pad, List.map_cons, List.cons_append, s]
        exact .tail (ih (j + 1) _ B (fun a m => hu a (.tail _ m)) d (by omega)
          fun c a e => by simpa using hB (c + 1) a (by rw [← e]; congr 1; omega))
      · exact .head s (by simp [pad_len])
    · cases d

-- the live check at the def's guard puts a live call below the frame's
theorem hcl {F : Frame} (ho : F.ok) (h : Term.live (F.g ts) true t = true) (ht : F.tags ts σ t) :
    F.hc σ t es := by
  intro k ys e
  obtain ⟨j, hj, hlt | ⟨rfl, hdesc⟩⟩ := live_call h e
  · left; simpa [Frame.L, Term.label, hj, ho.1]
  obtain rfl : k = F.k := (index_key hj).2.symm.trans (index_key ho.1).2
  have et : Term.spine (Ref F.k) ys = t := by simpa [e, Term.spine] using spine_unspine (t := t) (xs := [])
  refine .inr ⟨rfl, ?_⟩
  simp only [Frame.L, Term.label, ho.2.1, Option.map_some, Option.getD_some]
  refine desc_lex ho ys 0 _ _ (fun a m hq => tags_mono ht fun v n => ?_) hdesc (by simpa using ho.2.2.2.1)
    fun c a e => by
      simp at e; rw [List.getElem?_map, List.getElem?_append_left (List.getElem?_eq_some_iff.1 e).1, e]; rfl
  have := (uses_spine (h := Ref F.k) (v := v)).2 a m hq
  rw [et] at this; omega


-- The substitution lemma
-- ----------------------

-- the labels of t under σ, on extra args es, but the top-level App's
noncomputable def Lhs (bk : Book) (σ : Subst) (t : Term) (es : List Arg) : List Label :=
  Term.hd bk (Term.unspine (Term.sub σ t) es) ++ Term.labels bk false (Term.sub σ t)

theorem lhs_nil : Term.labels bk true (Term.sub σ t) = Lhs bk σ t [] := labels_top _

-- unfolds Lhs one node down
macro "unlhs" : tactic => `(tactic| simp only [Lhs, Term.sub, Term.unspine, Term.hd, Term.labels,
  List.nil_append] <;> simp only [lhs_nil])

-- σ is a variable, or a closed term
def VM (σ : Subst) : Prop := ∀ v, (∃ w, σ v = Var w) ∨ Term.Closed (σ v)

theorem vm_up (h : VM σ) : VM (Subst.up σ) := by
  rintro (_ | v)
  · exact .inl ⟨0, rfl⟩
  rcases h v with ⟨w, e⟩ | hc
  · simp [Subst.up, e, Term.ren]
  · simp [Subst.up, closed_ren hc, hc]

theorem bud_up (h : VM σ) :
    (fun v => Term.labels bk true (Subst.up σ v)) = Bud.up (fun v => Term.labels bk true (σ v)) := by
  funext v; rcases v with _ | v
  · rfl
  rcases h v with ⟨w, e⟩ | hc
  · simp [Subst.up, e, Term.ren, Term.labels, Bud.up]
  · simp only [Subst.up, closed_ren hc, Bud.up]

theorem tags_up {F : Frame} (ho : F.ok) (h : F.tags ts σ t)
    (hu : ∀ v, Term.uses f (v + 1) ≠ 0 → Term.uses t v ≠ 0 := by intro v n; simp_all [Term.uses]) :
    F.tags (none :: ts) (Subst.up σ) f := by
  rintro (_ | v) c π e n
  · cases e
  have r := h v c π e (hu v n)
  obtain ⟨a, ha, g⟩ := Option.bind_eq_some_iff.1 r
  rwa [Subst.up, closed_ren (get_val (bk := F.bk) (ho.2.2.1 a (List.mem_of_getElem? ha)).1 g).1]

theorem good_top {F : Frame} (h : Good F.L (F.ok ∧ Term.live (F.g ts) false c = true ∧
    F.tags ts σ c ∧ F.hc σ c []) A B C) :
    Good F.L (F.ok ∧ Term.live (F.g ts) true c = true ∧ F.tags ts σ c) A B C :=
  good_mono h fun ⟨a, b, c⟩ => ⟨a, live_mono b, c, hcl a b c⟩

theorem good_if {q : Quan} (h : q.live = true → Good L P A B C) :
    Good L P (if q.live then A else []) (if q.live then B else []) (if q.live then C else []) := by
  cases hq : q.live <;> simp [good_nil, h, hq]

-- a child at a top position: its tags come from the parent's
theorem good_ch {F : Frame} (ih : Good F.L (F.ok ∧ Term.live (F.g ts) false c = true ∧
      F.tags ts σ c ∧ F.hc σ c []) A B C)
    (hu : ∀ v, Term.uses c v ≠ 0 → Term.uses t v ≠ 0 := by intro v n; simp_all [Term.uses])
    (hl : Term.live (F.g ts) false t = true → Term.live (F.g ts) true c = true :=
      by intro l; simp_all [Term.live]) :
    Good F.L (F.ok ∧ Term.live (F.g ts) false t = true ∧ F.tags ts σ t ∧ F.hc σ t es) A B C :=
  good_mono (good_top ih) fun ⟨o, l, tg, _⟩ => ⟨o, hl l, tags_mono tg hu⟩


theorem gsl (F : Frame) (t : Term) : ∀ {ts : List Tag} {σ : Subst} {es es₀ : List Arg},
    VM σ → ArgsLe F.bk es es₀ →
    Good F.L (F.ok ∧ Term.live (F.g ts) false t = true ∧ F.tags ts σ t ∧ F.hc σ t es)
      (Lhs F.bk σ t es) (Term.bud (fun v => Term.labels F.bk true (σ v)) t) (Lhs F.bk Var t es₀) := by
  have hL : 0 < F.L.1 := Nat.succ_pos _
  induction t <;> intro ts σ es es₀ hv hE
  case Var =>
    refine ⟨[], ?_, le_nil, by simp⟩
    simp only [Lhs, Term.sub, Term.bud, List.nil_append]
    exact le_le (le_app hd_ext le_rfl) (.inl (by rw [labels_top]))
  case Ref k =>
    simp [Lhs, Term.sub, Term.unspine, Term.hd, Term.labels, Term.bud]
    exact ⟨_, le_sub, label_le hE,
      fun ⟨_, _, _, h⟩ l hl => List.mem_singleton.1 hl ▸ by simpa using h k [] rfl⟩
  case App q f x ihf ihx =>
    have e : ∀ σ es, Lhs F.bk σ (App q f x) es =
        Lhs F.bk σ f ((q, Term.sub σ x) :: es) ++ (if q.live then Lhs F.bk σ x [] else []) := by
      intro σ es; simp [Lhs, Term.sub, Term.unspine, labels_app, labels_top]
    rw [e, e, sub_var]
    refine good_app (good_mono (ihf (ts := ts) hv (.cons size_sub hE)) ?_)
      (good_if fun hq => good_ch (ihx hv .nil))
    rintro ⟨o, l, tg, hc⟩
    lv at l
    refine ⟨o, l.1.2, tags_mono tg, fun k ys e' => ?_⟩
    simpa using hc k (ys ++ [(q, x)]) (by show Term.unspine f [(q, x)] = _; rw [unspine_app, e'])
  all_goals try unlhs
  case Lam ih =>
    rw [up_var]
    have := bud_up hv ▸ ih (ts := none :: ts) (es := []) (es₀ := []) (vm_up hv) .nil
    exact good_cons hL (good_mono (good_top this) fun ⟨o, l, tg, _⟩ => ⟨o, by lv at l; exact l.2, tags_up o tg⟩)
  case Let ihv ihf =>
    rw [up_var]
    have hf := bud_up hv ▸ ihf (ts := none :: ts) (es := []) (es₀ := []) (vm_up hv) .nil
    exact good_cons hL (good_app (good_if fun hq => good_ch (ihv hv .nil))
      (good_mono (good_top hf) fun ⟨o, l, tg, _⟩ => ⟨o, by lv at l; exact l.2, tags_up o tg⟩))
  case Tup iha ihb => exact good_app (good_if fun hq => good_ch (iha hv .nil)) (good_ch (ihb hv .nil))
  case Mat iha ihb | Rwt iha _ ihb => exact good_cons hL (good_app (good_ch (iha hv .nil)) (good_ch (ihb hv .nil)))
  case Prj ih | Ann ih _ => exact good_cons hL (good_ch (ih hv .nil))
  all_goals exact good_nil


theorem data_labels (h : Data v) : Term.labels bk true v = [] := by
  induction h with
  | lab | rfl => rfl
  | tup _ _ iha ihb => simp only [Term.labels]; split <;> simp_all

-- The tree walk
-- -------------

def Ren.lift : Nat → Ren
  | 0 => Nat.succ
  | n + 1 => Ren.up (Ren.lift n)

theorem lift_fix : Ren.lift n v = v → v < n := by
  induction n generalizing v with
  | zero => simp [Ren.lift]
  | succ n ih => cases v <;> simp_all [Ren.lift, Ren.up]

theorem env_var (h : e.length ≤ v) : Env.sub e v = Var (v - e.length) := by
  induction e generalizing v <;> cases v <;> simp_all [Env.sub]

theorem tree_leaf (h : Term.node t = false) : Term.tree g ps t = Term.live g true t := by
  cases t <;> simp_all [Term.node, Term.takes, Term.tree]
  case App x => cases x <;> simp_all [Term.tree, Term.takes]

theorem fld_live {q : Quan} (h : q.live = true) : (Quan.fld r q).live = r.live := by
  cases r <;> cases q <;> simp_all [Quan.fld, Quan.live]

theorem allows_live {q : Quan} (h : Quan.allows q n = true) (hn : n ≠ 0) : q.live = true := by
  cases q <;> simp_all [Quan.allows, Quan.live]

theorem allows_two {q : Quan} (h : Quan.allows q n = true) (hn : 2 ≤ n) : q = Q2 := by
  cases q <;> simp_all [Quan.allows] <;> omega

-- the next argument of the walk: a pending one, or a new column
-- the pending args carry their tags' relation
inductive PR (bk : Book) (xs : List Arg) : List Tag → List Arg → Prop
  | nil : PR bk xs [] []
  | cons : (∀ c π, p = some (c, π) → a.1.live = true → Arg.at xs c π = some a.2) → PR bk xs ps as →
      PR bk xs (p :: ps) (a :: as)

-- the next argument of the walk: a pending one, or a new column
theorem next_ok (hq : q.live = l) (hpe : (q, x) :: as' = pend ++ xs.drop cs.length)
    (hp : PR bk xs ps pend) (hcs : CS xs cs) :
    ∃ pt cs' ps' pend', Guard.next ⟨bk, i, cs, ts, hs⟩ ps l = (pt, ⟨bk, i, cs', ts, hs⟩, ps') ∧
      as' = pend' ++ xs.drop cs'.length ∧ PR bk xs ps' pend' ∧
      (∀ c π, pt = some (c, π) → q.live = true → Arg.at xs c π = some x) ∧ CS xs cs' ∧
      cs'.length ≤ cs.length + 1 := by
  cases hp with
  | nil =>
    have h1 : xs[cs.length]? = some (q, x) := by
      have := congrArg (·[0]?) hpe; simpa [List.getElem?_drop] using this.symm
    have h2 : xs.drop (cs.length + 1) = as' := by simpa [List.tail_drop] using (congrArg List.tail hpe).symm
    refine ⟨_, cs ++ [l], [], [], rfl, by simp [h2], .nil, fun _ _ e _ => ?_, ?_, by simp⟩
    · cases e; simp [Arg.at, h1, Term.get]
    rw [CS] at hcs ⊢; simp [List.take_add_one, ← hcs, h1, hq]
  | cons h hp =>
    cases hpe; exact ⟨_, cs, _, _, rfl, rfl, hp, h, hcs, by omega⟩

-- the walk's invariant at tree node t with env e and args as
-- the env's entries are closed, and used ones are live values
def EOK (bk : Book) (e : List Term) (t : Term) : Prop :=
  ∀ v, v < e.length → Term.Closed (Env.sub e v) ∧
    (Term.uses t v ≠ 0 → Value bk (Env.sub e v) ∧ Term.Live bk (Env.sub e v))

theorem eok_mono (h : EOK bk e t) (hu : ∀ v, Term.uses t' v ≤ Term.uses t v := by intro v; simp [Term.uses]) :
    EOK bk e t' :=
  fun v l => let ⟨c, u⟩ := h v l; ⟨c, fun n => u (by have := hu v; omega)⟩

def WInv (bk : Book) (k : String) (i : Nat) (d : Def) (xs : List Arg) (t : Term) (e : List Term)
    (as : List Arg) (ts : List Tag) (cs : List Bool) (hs : List ((Nat × List Bool) × String))
    (ps : List Tag) : Prop :=
  Term.tree ⟨bk, i, cs, ts, hs⟩ ps t = true ∧ Term.ren (Ren.lift e.length) t = t ∧ EOK bk e t ∧
  Frame.tags ⟨bk, k, i, d, xs, [], cs, hs⟩ ts (Env.sub e) t ∧
  (∃ pend, as = pend ++ xs.drop cs.length ∧ PR bk xs ps pend) ∧
  cs.length + Term.size t ≤ Term.size d.v ∧ CS xs cs ∧ AOK bk as ∧
  DMle Label.lt (Term.bud (fun v => Term.labels bk true (Env.sub e v)) t ++ Args.labels bk as)
    (Args.labels bk xs) ∧ Hits xs hs

-- a call's walk: the reached leaf, under the env, is live, and its
-- labels are below the call's
theorem tp (hk : Book.index bk k = some i) (hd : Book.get bk k = some d) (hx : AOK bk xs)
    (w : Walk bk t e as o) : ∀ ts cs ls ps r, o = some r → WInv bk k i d xs t e as ts cs ls ps →
    Term.Live bk r ∧ ∀ zs, DM Label.lt (Term.labels bk true (Term.spine r zs))
      (Term.label bk k (xs ++ zs) :: (Args.labels bk xs ++ Args.labels bk zs)) := by
  induction w <;> rintro ts cs ls ps r0 ⟨⟩ ⟨ht, hr, hE, htg, ⟨pend, hpe, hp⟩, hsz, hcs, ha, hbud, hh⟩
  all_goals try simp only [Term.size] at hsz
  all_goals try
    obtain ⟨pt, cs', ps', pend', hn, hpe', hp', hx', hcs', hlen⟩ :=
      next_ok (by first | assumption | exact .symm (by assumption)) hpe hp hcs
    simp only [Term.tree] at ht; rw [hn] at ht; try simp only [Bool.and_eq_true] at ht
  case lam f e xs' q pl dx w ih =>
    have lq : Term.uses f 0 ≠ 0 → q.live = true := (pl ▸ allows_live ht.1 ·)
    refine ih _ cs' _ _ _ rfl ⟨ht.2, (Lam.inj hr).2,
      fun | 0, _ => (ha _ (.head _)).imp_right (· ∘ lq) | v + 1, hv => hE v (by simpa using hv),
      fun | 0, c, o, e', h => hx' c o (Option.some.inj e') (lq h) | v + 1, c, o, e', h => htg v c o e' h,
      ⟨pend', hpe', hp'⟩, by omega, hcs', fun a h => ha a (.tail _ h),
      le_le (le_app (le_le (bud_once (i := 0) f fun h => data_labels (dx (allows_two ht.1 h)))
        (le_app (.inl (.of_eq (congrArg (Term.bud · f) (funext fun v => by cases v <;> rfl))))
          (by split; exact le_nil; simp [lq ‹_›]; exact le_rfl))) le_rfl)
        (le_le (.inl (.of_eq (List.append_assoc _ _ _))) hbud), hh⟩
  case prj r q a b xs' hq w ih =>
    have ⟨ct, vt⟩ := ha _ (.head _)
    have ⟨vt, lt⟩ := vt hq
    have ⟨va, vb⟩ := value_tup vt
    have ⟨ca, cb⟩ : Term.Closed a ∧ Term.Closed b := by cl ct
    have fl := fld_live (r := r) hq
    lv at lt
    refine ih _ _ _ _ _ rfl ⟨ht, Prj.inj hr, hE, htg,
      ⟨(Quan.fld r q, a) :: (q, b) :: pend', by simp [hpe'], .cons (fun c o e l => ?_) (.cons (fun c o e _ => ?_) hp')⟩,
      by omega, hcs', fun
        | _, .head _ => ⟨ca, fun l => ⟨va (fl ▸ l), lt.1.resolve_left (by simp [← fl, l])⟩⟩
        | _, .tail _ (.head _) => ⟨cb, fun _ => ⟨vb, lt.2⟩⟩
        | _, .tail _ (.tail _ hy) => ha _ (.tail _ hy),
      by simpa [Args.labels, fl, hq, Term.labels, List.append_assoc, Term.bud] using hbud, hh⟩
    all_goals simp at e; obtain ⟨_, _, rfl, rfl, rfl⟩ := e
    exact (at_cons (hx' _ _ rfl hq)).2 (fl ▸ l)
    exact (at_cons (hx' _ _ rfl hq)).1
  case hit hq w ih =>
    refine ih _ _ _ _ _ rfl ⟨ht.1, (Mat.inj hr).2.1, eok_mono hE, tags_mono htg,
      ⟨pend', hpe', hp'⟩, by omega, hcs', fun a h => ha a (.tail _ h), le_le (le_app le_sub le_rfl)
      (by simpa [Args.labels, Term.labels, Term.bud] using hbud), fun c π k hm => by
        simp at hm; rcases hm with ⟨_, _, e, ⟨rfl, rfl⟩, rfl⟩ | hm; exact hx' _ _ e hq; exact hh _ _ _ hm⟩
  case miss q xs' h hq hj w ih =>
    refine ih _ _ _ _ _ rfl ⟨ht.2, (Mat.inj hr).2.2, eok_mono hE, tags_mono htg,
      ⟨(q, _) :: pend', by simp [hpe'], .cons (fun c o e _ => hx' c o e hq) hp'⟩,
      by omega, hcs', ha, le_le (le_app le_sub' le_rfl) hbud, hh⟩
  case app q f v e xs' hn w ih =>
    simp only [Term.tree, show Term.takes _ = true from hn] at ht
    simp [Term.ren] at hr; have hv' := lift_fix hr.2
    have huv : q.live = true → Term.uses (App q f (Var v)) v ≠ 0 := by simp +contextual [Term.uses]
    exact ih _ _ _ _ _ rfl ⟨ht, hr.1, eok_mono hE, tags_mono htg,
      ⟨(q, _) :: pend, by simp [hpe], .cons (fun c o e l => htg v c o (Option.join_eq_some_iff.1 e) (huv l)) hp⟩,
      by omega, hcs, fun | _, .head _ => (hE v hv').imp_right (· ∘ huv) | _, .tail _ hy => ha _ hy,
      le_le (.inl (.of_eq (List.append_assoc _ _ _).symm)) hbud, hh⟩
  case done t e xs' hn =>
    rw [tree_leaf hn] at ht
    have hV : LiveV bk (Env.sub e) t := fun v => if hv : v < e.length then
      .inr ((hE v hv).imp_right fun h n G hG hi => live_up (h n).2 hG (hG ▸ hi))
      else .inl ⟨_, env_var (by omega)⟩
    refine ⟨live_spine.2 ⟨live_sub t (by rfl) rfl hV ht, fun a h l => ((ha a h).2 l).2⟩, fun zs => ?_⟩
    let F : Frame := ⟨bk, k, i, d, xs, zs, cs, ls⟩
    have hF : F.ok := ⟨hk, hd, hx, Nat.le_of_add_right_le hsz, hcs, hh⟩
    obtain ⟨O, h1, _, h3⟩ := gsl F t (ts := ts) (es := xs' ++ zs) (fun v => (hV v).imp_right And.left) sl_refl
    rw [← spine_append, labels_spine, args_append]
    exact le_dm (le_le (le_app h1 le_rfl) (.inl (.of_eq (by simp only [List.append_assoc]; rfl))))
      (dm_repl (le_app hbud le_rfl) (h3 ⟨hF, live_mono ht, htg, hcl hF ht htg⟩))

-- Evaluation
-- ----------

theorem closed_app : Term.Closed (App q f x) ↔ Term.Closed f ∧ Term.Closed x := by
  simp [closed_iff, Term.ren]

theorem sl_mid (h : Size.le a b) : SL (l ++ a :: r) (l ++ b :: r) := by
  induction l; exact .cons h sl_refl; exact .cons (.inl rfl) ‹_›

-- β and let: the body stays live, and x lands in at most one live
-- place, or has no labels
theorem inst_ok {p q : Quan} (ha : Quan.allows p (Term.uses f 0) = true) (pq : p.live = q.live)
    (hf : Term.live ⟨bk, bk.length, [], [none], []⟩ true f = true) (hx : Term.Closed x)
    (hl : q.live = true → Term.Live bk x) (hd : p = Q2 → Data x) :
    Term.Live bk (Term.inst f x) ∧ DMle Label.lt (Term.labels bk true (Term.inst f x))
      (Term.labels bk true f ++ (if q.live then Term.labels bk true x else [])) := by
  refine ⟨live_sub f (by rfl) rfl (fun
    | 0 => .inr ⟨hx, fun n G hG hi => live_up (hl (pq ▸ allows_live ha n)) hG (hG ▸ hi)⟩
    | v + 1 => .inl ⟨v, rfl⟩) hf, ?_⟩
  obtain ⟨O, h1, h2, _⟩ := gsl ⟨bk, "", 0, default, [], [], [], []⟩ f (ts := []) (es₀ := [])
    (σ := Subst.one x) (fun | 0 => .inr hx | v + 1 => .inl ⟨v, rfl⟩) .nil
  rw [← lhs_nil] at h1 h2; rw [sub_var] at h2
  refine le_le h1 (le_app h2 (le_le (bud_once (i := 0) f fun h => data_labels (hd (allows_two ha h))) ?_))
  rw [bud_nil f fun v => by cases v <;> simp [Subst.one, Term.labels], List.nil_append]
  split; exact le_nil; simp [← pq, allows_live ha ‹_›]; exact le_rfl

theorem live_app : Term.Live bk (App q f x) ↔ Term.Live bk f ∧ (q.live = true → Term.Live bk x) :=
  (live_spine (t := f) (as := [(q, x)])).trans (by simp)

-- a step at a head that is no call lifts to any spine
theorem dm_spine (h : DM Label.lt (Term.labels bk true u) (Term.labels bk true t))
    (ht : ∀ zs, Term.hd bk (Term.unspine t zs) = []) (zs : List Arg) :
    DM Label.lt (Term.labels bk true (Term.spine u zs)) (Term.labels bk true (Term.spine t zs)) := by
  rw [labels_top t, ht] at h
  exact le_dm (labels_ext u zs) (by rw [labels_spine, ht]; exact dm_app h)

-- each step keeps Live, and lowers the labels in any spine
theorem ev (hb : Book.Live bk) (h : Eval bk t u) : Term.Closed t → Term.Live bk t → Term.Live bk u ∧
    ∀ zs, DM Label.lt (Term.labels bk true (Term.spine u zs)) (Term.labels bk true (Term.spine t zs)) := by
  induction h <;> intro hc hl <;> try exact ⟨hl, dm_spine (dm_cons le_rfl) fun _ => rfl⟩
  case app_f ih =>
    have ⟨lf, lx⟩ := live_app.1 hl
    have ⟨l, dd⟩ := ih (closed_app.1 hc).1 lf
    exact ⟨live_app.2 ⟨l, lx⟩, fun zs => dd ((_, _) :: zs)⟩
  case app_x f x x' q vf hq hx ih =>
    have ⟨lf, lx⟩ := live_app.1 hl
    have ⟨l, dd⟩ := ih (closed_app.1 hc).2 (lx hq)
    refine ⟨live_app.2 ⟨lf, fun _ => l⟩, fun zs => ?_⟩
    erw [labels_spine f ((q, x') :: zs), labels_spine f ((q, x) :: zs), unspine_app (xs := _ :: zs),
      unspine_app (xs := _ :: zs)]
    simp only [Args.labels, hq]
    exact dm_mono (le_app (hd_le (by
      simp only [ArgsLe, List.map_append, List.map_cons, Arg.size, hq,
        show ¬(Value bk x ∧ Term.Closed x) from fun h => eval_value hx h.1]
      exact sl_mid size_le_none)) le_rfl) (dm_app (dd []))
  case beta =>
    have ⟨ll, lx⟩ := live_app.1 hl
    lv at ll
    have ⟨li, di⟩ := inst_ok ll.1 ‹_› ll.2 (closed_app.1 hc).2 lx ‹_›
    exact ⟨li, dm_spine (dm_cons di) fun _ => rfl⟩
  case split r a b q h hq vt =>
    have ⟨lp, lt⟩ := live_app.1 hl
    have lt := lt hq
    lv at lt
    have fl := fld_live (r := r) hq
    exact ⟨live_app.2 ⟨live_app.2 ⟨lp, fun l => lt.1.resolve_left (by simp [← fl, l])⟩,
      fun _ => lt.2⟩, dm_spine (dm_cons (le_le (labels_ext _ [(_, _), (_, _)])
        (.inl (.of_eq (by simp [Args.labels, fl, hq, Term.labels]))))) fun _ => rfl⟩
  case hit =>
    have ⟨lm, _⟩ := live_app.1 hl
    lv at lm
    exact ⟨lm.1, dm_spine (dm_cons (le_le le_sub le_sub)) fun _ => rfl⟩
  case miss =>
    have ⟨lm, _⟩ := live_app.1 hl
    lv at lm
    exact ⟨live_app.2 ⟨lm.2, fun _ => rfl⟩, dm_spine (dm_cons (le_le (labels_ext _ [(_, _)])
      (le_app le_sub' (.inl (.of_eq (List.append_nil _)))))) fun _ => rfl⟩
  case call k d xs t hd hv w =>
    obtain ⟨i, hk⟩ := index_of_get hd
    have hx : AOK bk xs := fun a h =>
      ⟨(closed_spine.1 hc).2 a h, fun l => ⟨values_mem hv h l, (live_spine.1 hl).2 a h l⟩⟩
    have ⟨l, dd⟩ := tp hk hd hx w [] [] [] [] t rfl ⟨hb.2 k i d hk hd, closed_ren (hb.1 k d hd),
      nofun, nofun, ⟨[], rfl, .nil⟩, by simp,
      rfl, hx, by rw [bud_nil]; exact le_rfl; exact fun _ => rfl, nofun⟩
    refine ⟨l, fun zs => ?_⟩
    rw [← spine_append, labels_spine (Ref k), args_append]
    simpa [Term.unspine, Term.hd, Term.labels] using dd zs
  case lett hq _ ih =>
    lv at hl
    have ⟨l, dd⟩ := ih (by cl hc : _ ∧ _).1 (hl.1.2.resolve_left (by simp [hq]))
    refine ⟨by lv; exact ⟨⟨hl.1.1, .inr l⟩, hl.2⟩, dm_spine ?_ fun _ => rfl⟩
    simp only [Term.labels, hq]; exact dm_left (P := [(0, [])]) (dm_app (dd []))
  case unlet =>
    lv at hl
    have ⟨li, di⟩ := inst_ok hl.1.1 rfl hl.2 (by cl hc : _ ∧ _).1 (fun h => hl.1.2.resolve_left (by simp [h])) ‹_›
    exact ⟨li, dm_spine (dm_cons (le_le di (.inl List.perm_append_comm))) fun _ => rfl⟩
  case tup_a hq _ ih =>
    lv at hl
    have ⟨l, dd⟩ := ih (by cl hc : _ ∧ _).1 (hl.1.resolve_left (by simp [hq]))
    refine ⟨by lv; exact ⟨.inr l, hl.2⟩, dm_spine ?_ fun _ => rfl⟩
    simp only [Term.labels, hq]; exact dm_app (dd [])
  case tup_b ih =>
    lv at hl
    have ⟨l, dd⟩ := ih (by cl hc : _ ∧ _).2 hl.2
    exact ⟨by lv; exact ⟨hl.1, l⟩, dm_spine (dm_left (dd [])) fun _ => rfl⟩
  case rwt ih =>
    lv at hl
    have ⟨l, dd⟩ := ih (by cl hc : _ ∧ _).1 hl.1
    exact ⟨by lv; exact ⟨l, hl.2⟩, dm_spine (dm_app (dm_left (P := [(0, [])]) (dd []))) fun _ => rfl⟩

-- a step keeps Closed (pars_closed) and Live, and lowers the labels (ev)
theorem eval_decreases : Book.Live bk → Term.Closed t → Term.Live bk t →
    Eval bk t u → Term.Closed u ∧ Term.Live bk u ∧ Measure.lt bk u t :=
  fun hb hc hl h => let ⟨l, d⟩ := ev hb h hc hl; ⟨pars_closed (eval_pars hb.1 h) hc, l, d []⟩

-- Measure.lt is well founded (dm_wf, label_wf);
-- eval_decreases carries Closed and Live along each chain
theorem halts : Claim.halts := by
  intro bk t hb hc hl
  induction (InvImage.wf (Term.labels bk true) (dm_wf label_wf)).apply t with
  | intro t _ ih => exact ⟨_, fun u h => let ⟨c, l, m⟩ := eval_decreases hb hc hl h; ih u m c l⟩

-- Assembly
-- --------

-- Ref k is live and typed at <>; by halts, progress, empty and sr, no
-- term reached from it has type <>
theorem consistent : Claim.consistent := by
  intro bk k d ok get hc
  have ⟨wt, lv⟩ := book_check bk ok
  have ⟨i, hi⟩ := index_of_get get
  suffices ∀ t, Acc (fun u t => Eval bk t u) t → ¬ Typed bk [] t (Enu []) from
    this _ (halts bk _ lv (fun _ => rfl) (by
      simp [Term.Live, Term.live, Term.called, Term.unspine, hi, (List.findIdx?_eq_some_iff_findIdx_eq.1 hi).1]))
      (.conv (.ref get) (.inl (conv_sub (σ := Var) hc)))
  intro t a ht; induction a with
  | intro t _ ih =>
    exact (progress bk t _ wt lv ht).elim (empty bk t wt · ht)
      fun ⟨u, e⟩ => ih u e (pars_sr wt ht (eval_pars lv.1 e))
