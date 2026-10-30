# Specification helpers for LAWS.bend, not part of the editable program.
# Keep this file and LAWS.bend unchanged when rewriting main.bend or PROOF.bend.
# main.bend uses LE from here, and may not change it.

import Base

# LE(a, b) is the type of proofs of a <= b: Unit when it holds, Empty
# when it fails
def LE(a: Nat, b: Nat) -> Data:
  match a b:
    case 0n b0:
      Unit
    case 1n+a1 0n:
      Empty
    case 1n+a1 1n+b1:
      LE(a1, b1)

# Sorted.from(lo, xs): every element is at least lo and the list ascends
def Sorted.from(lo: Nat, xs: List<&2, Nat>) -> Type:
  match xs:
    case Nil{}:
      Unit
    case h <> t:
      (LE(lo, h) & Sorted.from(h, t))

def Sorted(xs: List<&2, Nat>) -> Type:
  Sorted.from(0n, xs)

# n plus one when b holds
def bump(b: Bool, n: Nat) -> Nat:
  match b:
    case True{}:
      1n+n
    case False{}:
      n

# how many times x occurs in xs
def count(+x: Nat, xs: List<&2, Nat>) -> Nat:
  match xs:
    case Nil{}:
      0n
    case h <> t:
      bump(Cmp.is_eq(Nat.cmp(x, h)), count(x, t))
