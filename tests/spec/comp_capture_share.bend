# comp-splice pin (spec_comp_capture_share): bend3's capture honesty,
# positive side -- a spliced lambda's captured runtime var kept its true
# multiplicity in the residual. bend has no comp surface (and its core
# is affine: a Many capture has no free contraction to ride); the ~
# binder pins bend's own parse refusal.
import Base

type L is Data:
  C{h: U32, t: L}
  N{}

law apply:
  for ~f: U32 -> U32
  for x: U32
  U32

def apply(f, x):
  f(x)

law once:
  for k: U32
  for x: U32
  U32

def once(k, x):
  apply(y => (y + k : U32), x)

law main:
  U32

def main():
  once(10, 1)

#|Error:
#|- expected : a name
#|- observed : '~'
#|Location:
#|12 | law apply:
#|13>|   for ~f: U32 -> U32
#|14 |   for x: U32
#|exit 1
