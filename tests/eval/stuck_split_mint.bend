# a stuck worker-split match in an eval dump: probe routes its
# computed scrutinee through probe.at (a computed match is a banned
# form), and the stuck call reads back compactly as probe.at(dbl(n)),
# never as the unfolded match literal.
# ported from bend3: the arm values become Bool for a readable golden,
# main wraps the stuck call under a lambda (an unapplied def stays
# closed)
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

law probe.at:
  for m: Nat
  Bool

def probe.at(m):
  match m:
    case 0n:
      True{}
    case 1n+p:
      False{}

law probe:
  for n: Nat
  Bool

def probe(n):
  probe.at(dbl(n))

law main:
  @n:Nat -> Bool

def main():
  n => probe(n)

#|n => probe.at(dbl(n))
