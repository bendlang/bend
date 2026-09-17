# A memory allocator keeps a free list: the sizes, in bytes, of the
# blocks it can hand out. A fresh arena of k pages of s bytes each is
# carved into k free blocks of s bytes. Prove that the free bytes of a
# fresh arena, the sum of its free list, are k times s.

import Base

# the free bytes of a free list
def total(xs: List<Nat>) -> Nat:
  match xs:
    case Nil{}:
      0n
    case h <> t:
      Nat.add(h, total(t))

# the free list of a fresh arena: k blocks of s bytes
def carve(k: Nat, +s: Nat) -> List<Nat>:
  match k:
    case 0n:
      Nil{}
    case 1n+p:
      s <> carve(p, s)

# LAW: a fresh arena has k times s free bytes
law carve_total:
  for k: Nat
  for s: Nat
  {total(carve(k, s)) == Nat.mul(k, s) : Nat}

# solution

def carve_total(k, s):
  match k:
    case 0n:
      {==}
    case 1n+p:
      %carve_total(p, s) : {total(carve(1n+p, s)) == Nat.add(s, _) : Nat}
      {==}
