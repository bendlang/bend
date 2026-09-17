# bend3's stale-taint fork grouping (a sibling whose taint dies in the
# unfold); bend has no taint pass, so the shape itself carries -- the
# recursive sibling rides a Nat countdown with a +U32 mirror (a copy
# destructure cannot feed a self-call), the pure sibling folds, and
# the fork-let joins them: 9
import Base

law tl:
  for n  : Nat
  for +i : U32
  for a0 : U32
  U32

def tl(n, i, a0):
  match n:
    case Zero{}:
      (a0 * 2 : U32)
    case Succ{k}:
      tl(k, (i - 1 : U32), i)

law hf:
  for f: U32 -> U32
  for x: U32
  U32

def hf(f, x):
  (f(1) + 2 : U32)

law main.out:
  Nat

def main.out():
  p0 p1 = tl(10n, 10, 3) hf(y => 5, 7)
  U32.to_nat((p0 + p1 : U32))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|9n
