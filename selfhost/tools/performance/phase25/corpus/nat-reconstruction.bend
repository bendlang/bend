# Phase25 adapted pinned Nat scalar constructor mechanism
# Runtime Nat conversion and successor prefix reconstruction; no large literal embedded in source.
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
def copy(+n: Nat) -> Nat:
  match n:
    case 0n: 0n
    case 1n+p: 1n+copy(p)

@unsafe
def bench(+size: U32,+seed: U32) -> U32:
  U32.from_nat(copy(U32.to_nat(U32.add(size,seed))))

