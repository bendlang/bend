# Nat literals are BIDIRECTIONAL: 2n parses to Succ{Succ{Zero{}}}, and
# the printer renders closed chains back as Nn -- inside tuples and
# ctor spines alike. A broken chain (Succ of a var) prints plain.
# ported from bend3: list literals become Con/Nil spines, the stuck
# def rides the tuple as a lambda component; no C lane (a List is not
# C-showable)
import Base

law dbl:
  for n: Nat
  Nat

def dbl(n):
  match n:
    case 0n:
      0n
    case 1n+p:
      Succ{Succ{dbl(p)}}

law main:
  Pair(Nat, Pair(Nat, Pair(List<&2, Nat>, @k:Nat -> Nat)))

def main():
  (dbl(2n), 0n, [3n, dbl(1n)], n => Succ{n})

#|(4n, 0n, [3n, 2n], n => 1n+n)
