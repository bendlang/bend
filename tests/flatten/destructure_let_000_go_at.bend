# destructuring let: `Ctr{..} = v` is a one-case match; on a param var it
# refines the column in place; a computed value moves to a worker def
# whose parameter carries the destructure (the applied form is banned)
# ported from bend3: local Pair renamed (base owns the def name), and
# the word literals become params (a U32 literal shows as its Word chain)
import Base

type Duo is Data:
  P{a: U32, b: U32}

law swap:
  for p: Duo
  Duo

def swap(p):
  P{a, b} = p
  P{b, a}

law mk:
  for n: U32
  for o: U32
  Duo

def mk(n, o):
  P{n, o}

law main:
  for d: Duo
  for k: U32
  U32

def main(d, k):
  P{a, b} = d
  (a * k + b : U32)

law go:
  for n: U32
  for o: U32
  for k: U32
  U32

def go(n, o, k):
  main(mk(n, o), k)

#|\{P: (a => b => k => U32.add(U32.mul(a, k), b))}
