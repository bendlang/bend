# a named hole ?name is the loud hole: it fails its check, showing
# the goal it was asked to fill
import Base

law th:
  for n: Nat
  {Nat.add(n, 0n) == n : Nat}

def th(n):
  ?help

#|Error:
#|- expected : {Nat.add(n, 0n) == n : Nat}
#|- observed : ?help
#|Context:
#|- n : Nat
#|Location: th
#| 9 | def th(n):
#|10>|   ?help
#|11 |
#|exit 1
