# number <-> text: U32.show/read round trips (through U32.MAX), and
# read rejects junk
# ported from bend3: U32.read answers Maybe<&2, U32> (no Parser module),
# so rejection reads None; the F32.show half is dropped (bend has no
# float text); the interp lane is dropped (the evaluator has no u32
# natives, so U32.MAX's show cannot reduce there)
import Base

law bu:
  for b: Bool
  U32

def bu(b):
  match b:
    case False{}:
      0
    case True{}:
      1

law rd.go:
  for m: Maybe<&2, U32>
  U32

def rd.go(m):
  match m:
    case Some{v}:
      v
    case None{}:
      999

law rd:
  for s: String
  U32

def rd(s):
  rd.go(U32.read(s))

law main.out:
  U32

def main.out():
  b0 = bu(String.eq(U32.show(4242), "4242"))
  b1 = bu(String.eq(U32.show(0), "0"))
  b2 = bu(U32.is_eq(rd("123"), 123))
  b3 = bu(U32.is_eq(rd(U32.show(4294967295)), 4294967295))
  b4 = bu(U32.is_eq(rd("x"), 999))
  U32.add(U32.add(U32.add(U32.add(b0, b1), b2), b3), b4)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|5
