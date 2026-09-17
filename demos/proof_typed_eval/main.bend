# proof_typed_eval: an intrinsically-typed expression language. An
# Expr<t> is a program of object type t, well-typed by construction:
# each constructor carries an equation {TNum{} == t : Ty} (the Ford
# trick). eval maps it to Val(t) with no error case; opt folds its
# constants. LAWS.bend states that opt keeps and computes the meaning
# of every program; PROOF.bend proves it. main folds and evaluates a
# sample program: 13n.
#
#   bend demos/proof_typed_eval/main.bend

import Base

# Types
# -----

# the object language's types
type Ty is Data:
  TNum{}
  TBool{}

# the meaning of a type: a Bend type
def Val(t: Ty) -> Type:
  match t:
    case TNum{}:
      Nat
    case TBool{}:
      Bool

# typed expressions: eq pins t to the type the constructor produces
type Expr<-t: Ty> is Data:
  Num{n: Nat, eq: {TNum{} == t : Ty}}
  Bit{b: Bool, eq: {TBool{} == t : Ty}}
  Add{a: Expr<TNum{}>, b: Expr<TNum{}>, eq: {TNum{} == t : Ty}}
  IsZero{a: Expr<TNum{}>, eq: {TBool{} == t : Ty}}
  If{c: Expr<TBool{}>, a: Expr<t>, b: Expr<t>}

# the literal of a value: the program that is that value
def lit(t: Ty, v: Val(t)) -> Expr<t>:
  match t:
    case TNum{}:
      Num{v, {==}}
    case TBool{}:
      Bit{v, {==}}

# Evaluation
# ----------

def is_zero(n: Nat) -> Bool:
  match n:
    case 0n:
      True{}
    case 1n+p:
      False{}

# the meaning of If: a branch chosen by a Bool
def pick(-t: Ty, b: Bool, x: Val(t), y: Val(t)) -> Val(t):
  match b:
    case True{}:
      x
    case False{}:
      y

# the meaning of a program: one arm per constructor, no error case;
# each arm rewrites its eq so the value lands in Val(t)
def eval(-t: Ty, e: Expr<t>) -> Val(t):
  match e:
    case Num{n, eq}:
      %eq : Val(_)
      n
    case Bit{b, eq}:
      %eq : Val(_)
      b
    case Add{a, b, eq}:
      %eq : Val(_)
      Nat.add(eval(TNum{}, a), eval(TNum{}, b))
    case IsZero{a, eq}:
      %eq : Val(_)
      is_zero(eval(TNum{}, a))
    case If{c, a, b}:
      pick(t, eval(TBool{}, c), eval(t, a), eval(t, b))

# Constant folding
# ----------------

# a sum of two literals is a literal
def fold_add(a: Expr<TNum{}>, b: Expr<TNum{}>) -> Expr<TNum{}>:
  match a b:
    case Num{x, _} Num{y, _}:
      Num{Nat.add(x, y), {==}}
    case a b:
      Add{a, b, {==}}

# a zero test of a literal is a literal
def fold_zero(a: Expr<TNum{}>) -> Expr<TBool{}>:
  match a:
    case Num{n, _}:
      Bit{is_zero(n), {==}}
    case a:
      IsZero{a, {==}}

# a branch on a literal is the branch it picks
def fold_if(-t: Ty, c: Expr<TBool{}>, a: Expr<t>, b: Expr<t>) -> Expr<t>:
  match c:
    case Bit{True{}, _}:
      a
    case Bit{False{}, _}:
      b
    case c:
      If{c, a, b}

# the optimizer: folds every subterm, then the node above it
def opt(-t: Ty, e: Expr<t>) -> Expr<t>:
  match e:
    case Num{n, eq}:
      Num{n, eq}
    case Bit{b, eq}:
      Bit{b, eq}
    case Add{a, b, eq}:
      %eq : Expr<_>
      fold_add(opt(TNum{}, a), opt(TNum{}, b))
    case IsZero{a, eq}:
      %eq : Expr<_>
      fold_zero(opt(TNum{}, a))
    case If{c, a, b}:
      fold_if(t, opt(TBool{}, c), opt(t, a), opt(t, b))

# Main
# ----

# if iszero (0 + 0) then 10 else 20, plus 3; every {==} is a typing
# fact that Bend checks: Num{0n, {==}} at type TBool would not build
def sample() -> Expr<TNum{}>:
  Add{If{IsZero{Add{Num{0n, {==}}, Num{0n, {==}}, {==}}, {==}}, Num{10n, {==}}, Num{20n, {==}}}, Num{3n, {==}}, {==}}

def main() -> Nat:
  eval(TNum{}, opt(TNum{}, sample()))
