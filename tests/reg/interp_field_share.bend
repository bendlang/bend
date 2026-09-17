# regression witness: the interpreter memoized a cell's constructor but
# handed its fields out as bare terms, so two consumers of one value
# re-evaluated every field: call-by-need for binders, call-by-name below
# them. Here each step's tree holds two leaves whose values are the lazy
# sum of the previous tree, and the next step sums it twice -- constant
# work per step compiled, 2^n interpreted (n=14 took a second, n=20 does
# not finish). A value stored into a cell now cells its fields too. The
# main answers U32 so the run is the interpreter's (an IO main runs the
# JS backend): 2^20, shown as its Word chain.
import Base

type Tree is Data:
  Leaf{v: U32}
  Node{l: Tree, r: Tree}

def sum(t: Tree) -> U32:
  match t:
    case Leaf{v}:
      v
    case Node{l, r}:
      (sum(l) + sum(r) : U32)

def go(+n: Nat, +t: Tree) -> Tree:
  match n:
    case 0n:
      t
    case 1n+p:
      go(p, Node{Leaf{sum(t)}, Leaf{sum(t)}})

def main() -> U32:
  sum(go(U32.to_nat(20), Leaf{1}))

#|1048576
