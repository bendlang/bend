# Phase25 association-list lookup analogue
# Build immutable numeric bindings and probe first-hit/miss paths; not the persistent compiler trie.
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

type Binding is Data:
  Bind{key: U32,value: U32}

@unsafe
def make(+n: Nat,+seed: U32) -> List<&2,Binding>:
  match n:
    case 0n: Nil{}
    case 1n+p: Con{Bind{U32.from_nat(p),U32.add(seed,U32.from_nat(p))},make(p,seed)}

@unsafe
def get(+xs: List<&2,Binding>,+key: U32) -> U32:
  match xs:
    case Nil{}: 0
    case Con{Bind{k,v},rest}: pick(U32,U32.is_eq(k,key),u => v,u => get(rest,key))

@unsafe
def bench(+size: U32,+seed: U32) -> U32:
  +xs = make(U32.to_nat(size),seed)
  U32.add(get(xs,U32.shr(size)),get(xs,U32.add(size,1)))

