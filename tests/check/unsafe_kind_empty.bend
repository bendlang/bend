# attack.bend — the identical expression inlined into the kind
import Base

def qsize(j: Array<Nat>) -> Quant:
  match j:
    case ALeaf{value}: &1
    case ANode{xs, ys}: &1

type Zero is Kind(qsize(Array.join(Nat, ALeaf{0n}, ALeaf{0n}))):

#|SOME PROOFS FAIL
#|Error: 1 def relies on unsafe or foreign code:
#|- Zero
#|exit 1
