# comp-splice pin (comp_splice_tuple_goal): bend3's tuple-goal templates
# (a generic ctor field holding a tuple of both worlds). bend's ~ law
# wrap checks once, f opaque; the pin moves to main's (a, b) = wrap(..),
# a destructure of a computed value. (bend3's R.Done/R.Fail respell as
# bare RDone/RFail: bend ctor names are bare and Result owns Done/Fail.)
import Base

type R<-A: Type> is Type:
  RDone{v: (U32 & A)}
  RFail{}

law wrap:
  for ~f: U32 -> U32
  for x: U32
  (U32 & U32)

def wrap(f, x):
  (7, f(x))

law main:
  U32

def main():
  (a, b) = wrap(y => (y + 1 : U32), 34)
  (a + b : U32)

#|Error:
#|- message  : a parameter or field scrutinee (a match cannot scrutinize a computed value: give it its own def)
#|Location:
#|23 | def main():
#|24>|   (a, b) = wrap(y => (y + 1 : U32), 34)
#|   |            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#|25 |   (a + b : U32)
#|exit 1
