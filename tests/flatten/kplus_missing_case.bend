# K+ density pin, respelled as bend's wall: bend3's book-free
# flattener minted an absurd lane for the absent literal 1 and the
# CHECKER refused coverage; bend has no K+ patterns at all -- `2+k`
# in a pattern is refused at parse, before any flattening exists
import Base

law f:
  for n: U32
  U32

def f(n):
  match n:
    case 0:
      0
    case 2+k:
      k

law main:
  U32

def main():
  f(3)

#|Error:
#|- expected : 1 patterns (one per scrutinee)
#|- observed : '
#|'
#|Location:
#|14 |       0
#|15>|     case 2+k:
#|16 |       k
#|exit 1
