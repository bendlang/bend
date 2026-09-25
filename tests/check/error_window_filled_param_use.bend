# the same missing window through an assert's fill: parse_def_fill made
# its parameter PVars without a span too
import Base

law h:
  for p: Nat
  Bool

def h(p):
  Bool.and(True{}, p)

#|Error:
#|- expected : Bool
#|- observed : Nat
#|Context:
#|- p : Nat
#|Location: h
#| 9 | def h(p):
#|10>|   Bool.and(True{}, p)
#|   |                    ^
#|11 | 
#|exit 1
