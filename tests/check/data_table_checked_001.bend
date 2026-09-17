# the twin surface, carried whole: an inequality field ({0 != 0 : U32})
# is a FUNCTION into Empty from parse time -- bend3 derived a null Data
# table over the desugared field and refused the duplication; bend is
# affine for every type and refuses the same double spend with the same
# verdict, no table needed. The {a != b : T} sugar itself carries.
# ported from bend3: the let-then-match bodies route through helper
# defs (match heads a def body only); ctor names bare and unique
import Base

type Box6 is Type:
  MkBox6{proof: {0 != 0 : U32}}

law delta.fin:
  for first : {0 != 0 : U32}
  for b     : Box6
  Empty

def delta.fin(first, b):
  match b:
    case MkBox6{second}:
      first({==})

law delta.go:
  for a: Box6
  for b: Box6
  Empty

def delta.go(a, b):
  match a:
    case MkBox6{first}:
      delta.fin(first, b)

law delta:
  for box: Box6
  Empty

def delta(box):
  delta.go(box, box)

law main:
  Empty

def main(): delta(MkBox6{argument => delta(MkBox6{argument})})

#|Error:
#|- expected : box
#|- observed : box (consumed more than once)
#|Location: delta
#|36 | 
#|37>| def delta(box):
#|38 |   delta.go(box, box)
#|exit 1
