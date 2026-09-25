# a - local is erased: its name is dead in the body, so a live use is
# refused. body_flatten once joined the local's - with its pattern's 1,
# which yielded 1 and lost the erasure
import Base

def f(x: Nat) -> Nat:
  -y = x
  y

#|Error:
#|- expected : -y
#|- observed : y
#|Context:
#|- x : Nat
#|Location: f
#|6 | def f(x: Nat) -> Nat:
#|7>|   -y = x
#|  |   ^^
#|8 |   y
#|exit 1
