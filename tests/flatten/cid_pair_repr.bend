# bend3's cid-pair ctor representation (boxed and word rows chosen per
# field type variable); bend's emitter has no cid pairs and the
# test's generic defs are ruled out with def<A> (collides with infix
# <) -- the family's own head dies at parse
import Base

type Box7<-A: Type> is Type:
  Box7{x: A}

law wrap:
  for -A: Type
  for x: A
  Result<&2, &1, U32, A>

def wrap<A>(x):
  Done{x}

law main:
  U32

def main():
  0

#|Error:
#|- expected : '('
#|- observed : '<'
#|Location:
#|14 | 
#|15>| def wrap<A>(x):
#|16 |   Done{x}
#|exit 1
