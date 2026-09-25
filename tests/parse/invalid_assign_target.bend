# error census: a statement head that is neither binder nor ctor
# pattern (f(1) = 3) fails at the reinterpret point.
# ported from bend3
import Base

law f:
  for x: U32
  U32

def f(x):
  x

law main:
  U32

def main():
  f(1) = 3
  0

#|Error:
#|- expected : a pattern (a binder or a constructor)
#|- observed : f(1)
#|Location:
#|16 | def main():
#|17>|   f(1) = 3
#|   |   ^^^^
#|18 |   0
#|exit 1
