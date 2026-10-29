# proof_insertion_sort: insertion sort on lists of Base's Nat. The
# comparison le_case returns evidence, a proof of x <= h or of h <= x
# in SPEC.bend's order, so a proof about insert can branch on the fact
# the program did. LAWS.bend states that sort's output is sorted and a
# permutation of its input; PROOF.bend proves it. main prints [1n, 2n, 3n].
#
#   bend demos/proof_insertion_sort/main.bend

import Base
import ./SPEC.bend as Spec

# Order
# -----

# the verdict of a comparison, with its evidence
def le_case(x: Nat, h: Nat) -> Or(Spec.LE(x, h), Spec.LE(h, x)):
  match x h:
    case 0n b:
      Inl{Unit{}}
    case 1n+a 0n:
      Inr{Unit{}}
    case 1n+a 1n+b:
      le_case(a, b)

# Sorting
# -------

# where x goes, given the verdict c against the head h; r is x
# inserted into the tail t
def dec(x: Nat, h: Nat, t: List<&2, Nat>, r: List<&2, Nat>,
  c: Or(Spec.LE(x, h), Spec.LE(h, x))) -> List<&2, Nat>:
  match c:
    case Inl{e}:
      x <> h <> t
    case Inr{e}:
      h <> r

def insert(+x: Nat, +xs: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      [x]
    case h <> t:
      dec(x, h, t, insert(x, t), le_case(x, h))

def sort(xs: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      Nil{}
    case h <> t:
      insert(h, sort(t))

def main() -> List<&2, Nat>:
  sort([3n, 1n, 2n])
