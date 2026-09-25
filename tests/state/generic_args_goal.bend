# tuple ladder, state 0: a generic def's erased Type args display in
# the stuck call, and the context shows the sigma spelling of the pair
# (Sigma<&1, &1, Nat, _ => Nat>), never a match literal
import Base

law swap:
  for -A: Type
  for -B: Type
  for p: A & B
  B & A

def swap(A, B, p):
  (a, b) = p
  (b, a)

law swap_swap:
  for p: Nat & Nat
  {swap(Nat, Nat, swap(Nat, Nat, p)) == p : Nat & Nat}

def swap_swap(p):
  {==}

#|Error:
#|- expected : swap(Nat, Nat, swap(Nat, Nat, p))
#|- observed : p
#|Context:
#|- p : Sigma<&1, &1, Nat, _ => Nat>
#|Location: swap_swap
#|20 | def swap_swap(p):
#|21>|   {==}
#|   |   ^^^^
#|22 |
#|exit 1
