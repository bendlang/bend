# rfc (rfc_share_map): a Map<Duo> read twice. Map.get keeps the leaf's
# value (+v2 = v, a share of the map's own type parameter V) and hands
# a copy out beside the map, so the Duo node is shared by the map and
# the reader. The sharing analysis must heat what Map.get's callers
# pass for V (the marker rides Map.get.leaf~0 up to Map.get~0, then to
# the call with Duo), or Duo stays cold, opn opens the node raw behind
# its count cell, and the C lanes died "bend: error 7" while 1067
# tests passed. Expect 6n on every lane.
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

law get2.fin:
  for p: Map<&2, Duo> & Duo
  for x: Duo
  Nat

def get2.fin(p, x):
  (m, y) = p
  Nat.add(opn(x), opn(y))

law get2.go:
  for p: Map<&2, Duo> & Duo
  Nat

def get2.go(p):
  (m, x) = p
  get2.fin(Map.get(Duo, Dd{0n, 0n}, m, "k"), x)

law get2:
  for m: Map<&2, Duo>
  Nat

def get2(m):
  get2.go(Map.get(Duo, Dd{0n, 0n}, m, "k"))

law main.out:
  Nat

def main.out():
  get2(Map.set(&2, Duo, Map.new(&2, Duo), "k", Dd{1n, 2n}))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|6n
