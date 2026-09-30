# Phase25 adapted pinned tests/run/list_map_fold_ops.bend
# Pinned first-order map/fold mechanism with runtime list length and values.
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
def make(+n: Nat, +seed: U32) -> List<&2,U32>:
  match n:
    case 0n: Nil{}
    case 1n+p: Con{U32.add(seed, U32.from_nat(p)), make(p, seed)}

@unsafe
def digest(xs: List<&2,U32>, acc: U32) -> U32:
  match xs:
    case Nil{}: acc
    case Con{h, t}: digest(t, U32.add(U32.mul(acc, 33), h))

@unsafe
def dbl(xs: List<&2,U32>) -> List<&2,U32>:
  match xs:
    case Nil{}: Nil{}
    case Con{h,t}: Con{U32.mul(h,2),dbl(t)}

@unsafe
def bench(+size: U32, +seed: U32) -> U32:
  digest(dbl(make(U32.to_nat(size),seed)),seed)

