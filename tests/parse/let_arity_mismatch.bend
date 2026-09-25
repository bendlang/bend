# the comma parallel let is not grammar: a bend let binds ONE name (or
# one ctor pattern), so `a, b = v` fails at the comma.
# ported from bend3: bend3 pinned the let-arity page of its fork let;
# bend has no comma let at all, so the port pins the refusal
import Base

law f:
  for x: U32
  U32

def f(x):
  x

law main:
  U32

def main():
  a, b = f(1)
  a

#|Error:
#|- expected : 'def', 'type' or 'law'
#|- observed : ','
#|Location:
#|17 | def main():
#|18>|   a, b = f(1)
#|   |    ^
#|19 |   a
#|exit 1
