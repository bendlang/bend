# Phase25 compiler closure-shape analogue
# Fresh scalar capture passed once through an ordinary function argument; inspect emission for inlining.
import Base

# Runtime inputs and scalar result are shared by both generated-program lanes.
@unsafe
def pick(-A: Type, +b: Bool, yes: Unit -> A, no: Unit -> A) -> A:
  match b:
    case True{}: yes(Unit{})
    case False{}: no(Unit{})

def b2u(b: Bool) -> U32:
  match b:
    case True{}: 1
    case False{}: 0

@unsafe
def use(f: U32 -> U32, x: U32) -> U32:
  f(x)

@unsafe
def spin(+n: Nat, +acc: U32) -> U32:
  match n:
    case 0n: acc
    case 1n+p: spin(p,use(x => U32.add(x,acc),U32.from_nat(n)))

@unsafe
def bench(+size: U32, +seed: U32) -> U32:
  spin(U32.to_nat(size),seed)

