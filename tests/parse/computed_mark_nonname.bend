# bend3's ! computed mark suffixed only names and failed loudly
# elsewhere; bend's ! is the GPU bang glued before a call's parens,
# so the postfix spelling on a completed call dies at parse the same
# way, by bend's own grammar
import Base

law f:
  for x: U32
  U32

def f(x):
  x

law main:
  U32

def main():
  f(1)!

#|Error:
#|- expected : 'def', 'type' or 'law'
#|- observed : '!'
#|Location:
#|17 | def main():
#|18>|   f(1)!
#|   |       ^
#|19 |
#|exit 1
