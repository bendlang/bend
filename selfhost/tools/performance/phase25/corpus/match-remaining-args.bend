# Phase25 compiler subst_node/tele_check calling-shape analogue
# A matcher precedes remaining shared scalar arguments; the recursive work consumes all fields.
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
def walk(xs: List<&2,U32>, +scale: U32, +offset: U32) -> U32:
  match xs:
    case Nil{}: offset
    case Con{h,t}: U32.add(U32.add(U32.mul(h,scale),offset),walk(t,scale,offset))

@unsafe
def bench(+size: U32, +seed: U32) -> U32:
  walk(make(U32.to_nat(size),seed),3,seed)

