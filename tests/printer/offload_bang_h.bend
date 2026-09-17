# f!(x) marks a reference for offloading (Ref.b, the fork-let's mark);
# the printer dropped the mark, so a shown def read as a plain call and
# the bang did not survive a print-parse round trip
import Base

def f(n: Nat) -> Nat:
  n

def g(n: Nat) -> Nat:
  f!(n)

def main(+n: Nat) -> Nat:
  a b = f!(n) f(n)
  Nat.add(a, b)

#|n => Nat.add(n, n)
