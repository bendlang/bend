# Specification helpers for LAWS.bend, not part of the editable program.
# Keep this file and LAWS.bend unchanged when rewriting main.bend or PROOF.bend.

import Base
import ./main.bend as Sort

# the leaves of a tree, added
def sum(d: Nat, t: Sort.Tree(d)) -> Nat:
  match d:
    case 0n:
      t
    case 1n++p:
      (x, y) = t
      Nat.add(sum(p, x), sum(p, y))
