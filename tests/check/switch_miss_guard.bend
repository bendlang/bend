# bend3's miss-arm guard: inside a 5-switch's miss arm the binder may
# still be 0, so a stuck 0-switch must not take its miss branch. bend
# respells both switches as literal-chain patterns; the catch-all arm's
# goal specializes only to the open word chain, where literal-defined
# isZ stays stuck, and the arm refuses: the same verdict, bend's law
import Base

law isZ:
  for n: U32
  Type

def isZ(n):
  match n:
    case 0:
      U32
    case p:
      F32

law pick:
  for n: U32
  isZ(n)

def pick(n):
  match n:
    case 5:
      1.5
    case p:
      1.5

law main:
  U32

def main():
  0

#|Error:
#|- expected : isZ(U32{WCon{_4, _5}})
#|- observed : F32
#|Context:
#|- _4 : Bool<> - True{}
#|- _5 : Word.Con<30n>
#|Location: pick
#|27 |     case p:
#|28>|       1.5
#|   |       ^^^
#|29 |
#|exit 1
