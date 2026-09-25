# Vec (type-family) ladder, state 0: the INDEX renders inside the
# stuck family application -- Vec(Nat.add(n, 0n)), the ref cut, never
# the family's unfolded match
import Base

law Vec:
  for n: Nat
  Type

def Vec(n):
  match n:
    case 0n:
      Unit
    case 1n+p:
      Nat & Vec(p)

law vpad:
  for n: Nat
  for v: Vec(n)
  Vec(Nat.add(n, 0n))

def vpad(n, v):
  v

#|Error:
#|- expected : Vec(Nat.add(n, 0n))
#|- observed : Vec(n)
#|Context:
#|- n : Nat
#|- v : Vec(n)
#|Location: vpad
#|22 | def vpad(n, v):
#|23>|   v
#|   |   ^
#|24 | 
#|exit 1
