# bend3's dec-swi respelling pin, hit side: the value 1 reached the
# second literal case as the pred 0 and a stuck pick(1,b) respelled as
# pick(0,b). bend has no dec switch: the 0/1/2+p chain dies at its
# K+ arm's parse, and no pred ever exists to misspell
import Base

type B2 is Data:
  T2{}
  F2{}

law pick:
  for i: U32
  for b: B2
  U32

def pick(i, b):
  match i:
    case 0:
      0
    case 1:
      match b:
        case T2{}:
          1
        case F2{}:
          0
    case 2+p:
      p

law main:
  U32

def main():
  0

#|Error:
#|- expected : 1 patterns (one per scrutinee)
#|- observed : '
#|'
#|Location:
#|25 |           0
#|26>|     case 2+p:
#|27 |       p
#|exit 1
