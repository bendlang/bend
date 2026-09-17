# a claim of Data-kindedness for every T is a def like any other: its
# fill is live, so a circular fill is a live self-reference, must
# decrease (no live column shrinks: T is erased) and cannot
# manufacture Data for every T
import Base

law Forge:
  for -T: Type
  Data

def Forge(T):
  Forge(T)

law main:
  Nat

def main():
  0n

#|Error:
#|- expected : a decreasing self-call (arguments are read left to right: each passed unchanged until one shrinks)
#|- observed : Forge
#|Context:
#|- T : Type
#|Location: Forge
#|11 | def Forge(T):
#|12>|   Forge(T)
#|13 |
#|exit 1
