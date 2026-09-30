# Phase25 compiler mechanism analogue
# Same recurrence in thunk-choice versus Boolean-worker source shape.
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
def spin(+n: Nat, +acc: U32) -> U32:
  match n:
    case 0n: acc
    case 1n+p: pick(U32, U32.is_even(acc), u => spin(p, U32.add(acc, 3)), u => spin(p, U32.add(acc, 5)))

@unsafe
def bench(+size: U32, +seed: U32) -> U32:
  spin(U32.to_nat(size), seed)

