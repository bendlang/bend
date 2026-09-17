# rfc (rfc_share_poly): the plainest polymorphic share. twice keeps
# +x: A and opens it twice through f and g; the caller passes Duo, a
# two-Nat record, so the keep wraps a node. The sharing analysis
# must heat what the caller passes for A (cb.own names the def's own
# erased parameter, cb.poly carries the marker to the call site), or
# Duo stays cold, opn opens the node raw behind the count-2 cell, and
# the C lanes died "bend: error 7" while 1067 tests passed. Expect
# 6n on every lane.
import Base

type Duo is Data:
  Dd{a: Nat, b: Nat}

law opn:
  for m: Duo
  Nat

def opn(m):
  match m:
    case Dd{a, b}:
      Nat.add(a, b)

law twice:
  for -A: Data
  for +x: A
  for f: A -> Nat
  for g: A -> Nat
  Nat

def twice(A, x, f, g):
  Nat.add(f(x), g(x))

law main.out:
  Nat

def main.out():
  twice(Duo, Dd{1n, 2n}, opn, opn)

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|6n
