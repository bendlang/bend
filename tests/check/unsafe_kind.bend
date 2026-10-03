# attack.bend — the identical expression inlined into the kind
import Base

def qsize(j: Array<Nat>) -> Quant:
  match j:
    case ALeaf{value}: &1
    case ANode{xs, ys}: &1

type D is Kind(qsize(Array.join(Nat, ALeaf{0n}, ALeaf{0n}))):
  Mk{}

def use(d: D) -> Nat:
  match d:
    case Mk{}: 0n

#|SOME PROOFS FAIL
#|Error: 2 defs rely on unsafe or foreign code:
#|- D
#|- use
#|exit 1
