# tuple ladder, complete: destructuring the pair mid-proof computes
# both swaps away
import Base

law swap:
  for -A: Type
  for -B: Type
  for  p: A & B
  B & A

def swap(A, B, p):
  (a, b) = p
  (b, a)

law swap_swap:
  for p: Nat & Nat
  {swap(Nat, Nat, swap(Nat, Nat, p)) == p : Nat & Nat}

def swap_swap(p):
  (a, b) = p
  {==}

#|All terms check.
