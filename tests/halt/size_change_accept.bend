# bend3's size-change matrix composition accepted role-swapping
# columns (interleave trades xs and ys); bend's law is fixed
# left-to-right EQ-until-LT, so the swap refuses by design
import Base

law interleave:
  for xs: List<&2, U32>
  for ys: List<&2, U32>
  List<&2, U32>

def interleave(xs, ys):
  match xs:
    case Nil{}:
      ys
    case h <> t:
      h <> interleave(ys, t)

law main:
  U32

def main():
  0

#|Error:
#|- expected : a decreasing self-call (arguments are read left to right: each passed unchanged until one shrinks)
#|- observed : interleave
#|Context:
#|- h  : U32
#|- t  : List<&2, U32>
#|- ys : List<&2, U32>
#|Location: interleave
#|15 |     case h <> t:
#|16>|       h <> interleave(ys, t)
#|17 |
#|exit 1
