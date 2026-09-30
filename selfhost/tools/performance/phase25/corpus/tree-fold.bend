# Phase25 adapted local tests/fixtures/tree.bend
# Fixed depth5 tree, runtime seed and traversal count; repeated shared use is not graph normalization.
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

type Tree is Data:
  Leaf{value: U32}
  Branch{left: Tree, right: Tree}

@unsafe
def gen(+n: Nat, +seed: U32) -> Tree:
  match n:
    case 0n: Leaf{seed}
    case 1n+p: Branch{gen(p,U32.mul(seed,2)),gen(p,U32.add(U32.mul(seed,2),1))}

@unsafe
def total(t: Tree) -> U32:
  match t:
    case Leaf{x}: x
    case Branch{l,r}: U32.add(total(l),total(r))

@unsafe
def spin(+n: Nat, +t: Tree, acc: U32) -> U32:
  match n:
    case 0n: acc
    case 1n+p: spin(p,t,U32.add(acc,total(t)))

@unsafe
def bench(+size: U32, +seed: U32) -> U32:
  spin(U32.to_nat(size),gen(5n,seed),seed)

