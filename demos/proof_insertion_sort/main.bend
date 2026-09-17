# proof_insertion_sort: insertion sort on lists of Base's Nat. The
# comparison le_case returns evidence, a proof of x <= h or of h <= x,
# so a proof about insert can branch on the fact the program did.
# LAWS.bend states that sort's output is sorted and a permutation of
# its input; PROOF.bend proves it. main prints [1n, 2n, 3n].
#
#   bend demos/proof_insertion_sort/main.bend

import Base

# Order
# -----

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

# the verdict of a comparison, with its evidence
def le_case(x: Nat, h: Nat) -> Or(LE(x, h), LE(h, x)):
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
def dec(x: Nat, h: Nat, t: List<&2, Nat>, r: List<&2, Nat>, c: Or(LE(x, h), LE(h, x))) -> List<&2, Nat>:
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

# Sortedness and counts
# ---------------------

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

def main() -> List<&2, Nat>:
  sort([3n, 1n, 2n])
