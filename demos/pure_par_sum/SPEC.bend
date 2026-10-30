# Specification helpers for LAWS.bend, not part of the editable program.
# Keep this file and LAWS.bend unchanged when rewriting main.bend or PROOF.bend.

import Base

def pow2(d: Nat) -> Nat:
  match d:
    case 0n:
      1n
    case 1n+p:
      +h = pow2(p)
      Nat.add(h, h)

# the n numbers from i, added one by one
def seq(n: Nat, +i: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n++m:
      Nat.add(seq(m, i), Nat.add(m, i))
