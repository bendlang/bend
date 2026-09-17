# `<-` statements: the bind belongs to do-notation, so outside a
# do-block it is refused.
# ported from bend3
import Base

law f:
  for g: @_:(U32 -> U32) -> U32
  U32

def f(g):
  x <- g
  x

law main:
  U32

def main(): f(k => k(41))

#|Error:
#|- expected : 'def', 'type' or 'law'
#|- observed : '<'
#|Location:
#|10 | def f(g):
#|11>|   x <- g
#|12 |   x
#|exit 1
