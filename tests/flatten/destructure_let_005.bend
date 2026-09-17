# constructor destructuring rides a worker def: the ctor value sits in
# the call's argument, a checked position, so it needs no annotation
# ported from bend3: local Pair renamed (base owns the def name), and
# the word literal becomes a param (a U32 literal shows as its Word chain)
import Base

type Duo is Data:
  P{a: U32, b: U32}

law go:
  for d: Duo
  for k: U32
  U32

def go(d, k):
  P{a, b} = d
  (a * k + b : U32)

law main:
  for x: U32
  for y: U32
  for k: U32
  U32

def main(x, y, k):
  go(P{x, y}, k)

#|x => y => k => U32.add(U32.mul(x, k), y)
