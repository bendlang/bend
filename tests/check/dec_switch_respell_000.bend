# bend3's dec-swi respelling pin, unsound side: a 1+p miss substituted
# the DECREMENTED scrutinee and a false nth equation PROVED. bend has
# no dec switch and no pred substitution -- the inner counter match's
# `1+p` arm is refused at parse, so the unsound lane cannot be spelled
import Base

law nth:
  for d: U32
  for i: U32
  for xs: List<&2, U32>
  U32

def nth(d, i, xs):
  match xs:
    case Nil{}:
      d
    case h <> t:
      match i:
        case 0:
          h
        case 1+p:
          nth(d, p, t)

law main:
  U32

def main():
  0

#|Error:
#|- expected : 1 patterns (one per scrutinee)
#|- observed : '
#|'
#|Location:
#|20 |           h
#|21>|         case 1+p:
#|22 |           nth(d, p, t)
#|exit 1
