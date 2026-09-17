# bend3 joined dependent hypotheses into the motive's suffix so both
# retyped per arm; bend bans the computed match outright (a
# lambda-match application is a banned form) -- the spelling that
# NEEDED the specialization refuses at the flattener, and that refusal
# is the design's own pin (the freeze twins hold the accepted half)
import Base

law j9:
  for n: Bool
  for e: {Bool.not(n) == False{} : Bool}
  {n == True{} : Bool}

def j9(n, e):
  match Bool.not(n):
    case False{}:
      {==}
    case True{}:
      {==}

law main:
  Nat

def main():
  0n

#|Error:
#|- message  : a parameter or field scrutinee (a match cannot scrutinize a computed value: give it its own def)
#|Location:
#|13 | def j9(n, e):
#|14>|   match Bool.not(n):
#|15 |     case False{}:
#|exit 1
