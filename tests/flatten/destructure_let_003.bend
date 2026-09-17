# destructure of a PARAM: `P{a,b} = w` on a param var refines the column
# in place -- a direct one-case tree
# ported from bend3: local Pair renamed (base owns the def name)
import Base

type Duo is Data:
  P{a: U32, b: U32}

law main:
  for w: Duo
  U32

def main(w):
  P{a, b} = w
  (a + b : U32)

#|\{P: (a => b => U32.add(a, b))}
