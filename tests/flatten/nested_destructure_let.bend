# NESTED destructure of a param: the pattern digs into a field's own
# (single) constructor in the same statement
# ported from bend3: local Pair renamed (base owns the def name)
import Base

type Box is Data:
  B{v: U32}

type Duo is Data:
  P{a: Box, b: U32}

law main:
  for w: Duo
  U32

def main(w):
  P{B{x}, y} = w
  (x + y : U32)

#|\{P: \{B: (x => y => U32.add(x, y))}}
