# branching survives compilation: recursion through a parity Bool
# dispatch, comparison-fed matches, and a Bool argument all emit plain
# C branches -- the interpreter and every backend agree on 518.
# ported from bend3: the word-case loop becomes Nat fuel with a + U32
# mirror (U32 is Data; bend has no word patterns), if/else becomes a
# worker def over the parity Bool, and bend3's Bool<->word bridge (case
# 0:/case t: on a Bool) is bend3-only -- flip matches real ctors
import Base

law odd:
  for x: U32
  Bool

def odd(x):
  U32.is_eq(U32.mod(x, 2), 1)

law steps:
  for k   : Nat
  for +n  : U32
  for acc : U32
  U32

law steps.acc:
  for z   : Bool
  for acc : U32
  U32

def steps.acc(z, acc):
  match z:
    case True{}:
      U32.add(U32.mul(acc, 2), 1)
    case False{}:
      U32.add(acc, 3)

def steps(k, n, acc):
  match k:
    case 0n:
      acc
    case 1n+k2:
      steps(k2, U32.sub(n, 1), steps.acc(odd(n), acc))

law flip:
  for b: Bool
  U32

def flip(b):
  match b:
    case False{}:
      100
    case True{}:
      201

law main.out:
  U32

def main.out():
  U32.add(U32.add(steps(10n, 10, 0), flip(odd(7))), flip(odd(8)))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|518
