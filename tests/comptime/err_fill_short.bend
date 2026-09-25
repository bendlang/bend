# a law's ~ clauses are its fill's leading binders: a fill that binds
# fewer names than the law has ~ clauses is refused where it is written
# (its instance would have no binder to fix)
import Base

def inc(n: Nat) -> Nat:
  (1n + n : Nat)

law F:
  for ~f: (Nat -> Nat) -> Nat
  for ~g: Nat -> Nat
  Nat

def F(f):
  f

def main() -> Nat:
  F(~(h => h(1n)), ~inc)

#|Error:
#|- expected : a name for each ~ clause of the law (2)
#|- observed : ':'
#|Location:
#|13 |
#|14>| def F(f):
#|   |         ^
#|15 |   f
#|exit 1
