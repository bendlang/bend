# chained destructures of TWO params: two statements, two columns refined
# in place
# ported from bend3: local Pair renamed (base owns the def name)
import Base

type Duo is Data:
  P{a: U32, b: U32}

law main:
  for u: Duo
  for v: Duo
  U32

def main(u, v):
  P{a, b} = u
  P{c, d} = v
  (a * c + b * d : U32)

#|\{P: (a => b => \{P: (c => d => U32.add(U32.mul(a, c), U32.mul(b, d)))})}
