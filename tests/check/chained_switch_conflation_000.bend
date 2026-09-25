# bend3's dec-swi conflation pin (stuck side) leaned on a 0/1/2+q
# chain and the frame's carried original. bend has no dec switch and
# no K+ pattern to conflate: the chain's own spelling is refused at
# parse, before any goal exists
import Base

law g:
  for n: U32
  U32

def g(n):
  match n:
    case 0:
      10
    case 1:
      20
    case 2+q:
      q

law main:
  U32

def main():
  g(1)

#|Error:
#|- expected : 1 patterns (one per scrutinee)
#|- observed : '2+q'
#|Location:
#|16 |       20
#|17>|     case 2+q:
#|   |          ^^^
#|18 |       q
#|exit 1
