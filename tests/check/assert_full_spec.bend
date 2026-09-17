# the full assert spec shape: `forall x : T where P` (the clause packs
# into a sigma &x:T -> P), `exists y : T` (the result sigma), a closing
# equation -- and its fill, an unannotated def whose param binds the
# packed clause. The proof runs: an impossible arm dies by \{} on the
# where-evidence, the inductive arm rewrites the IH.
# ported from bend3: the where witness is the SIGMA, so the equation
# projects it (Sigma.fst) and the fill destructures before a helper
# (nested matches go in binder order)
import Base

law Sigma.fst:
  for -A: Type
  for -B: @-x: A -> Type
  for  p: Sigma<&1, &1, A, B>
  A

def Sigma.fst(A, B, p):
  match p:
    case (x, y):
      x

law IsEven:
  for x: Nat
  Type

def IsEven(x):
  match x:
    case Zero{}:
      Unit
    case Succ{p}:
      match p:
        case Zero{}:
          Empty
        case Succ{q}:
          IsEven(q)

law go.put:
  for -q : Nat
  for r  : (&y:Nat -> {Nat.mul(y, 2n) == q : Nat})
  exs y2 : Nat
  {Nat.mul(y2, 2n) == 2n+q : Nat}

def go.put(q, r):
  (y, prf) = r
  (Succ{y}, %h@prf : {Nat.mul(Succ{y}, 2n) == Succ{Succ{_}} : Nat}; {==})

law go:
  for n: Nat
  for e: IsEven(n)
  (&y:Nat -> {Nat.mul(y, 2n) == n : Nat})

def go(n, e):
  match n:
    case Zero{}:
      (0n, {==})
    case Succ{p}:
      match p:
        case Zero{}:
          Empty.absurd((&y:Nat -> {Nat.mul(y, 2n) == 1n : Nat}), e)
        case Succ{q}:
          go.put(q, go(q, e))

law my_thesis:
  for x: Nat where IsEven(x)
  exs y: Nat
  {Nat.mul(y, 2n) == Sigma.fst(Nat, k => IsEven(k), x) : Nat}

def my_thesis(x):
  (n, e) = x
  go(n, e)

law main:
  &y:Nat -> {Nat.mul(y, 2n) == 6n : Nat}

def main(): my_thesis((6n, Unit{}))

#|(3n, {==})
