# bend3's stale-taint bare-call variant (mid's recursion dies inside
# its own unfold); bend has no taint bits to go stale, so the sibling
# shape carries end to end -- the countdown on a Nat mirror with a +
# word binder (a copy destructure cannot feed a self-call), mid as a
# plain pure binding in the fork: 10
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

law mid:
  for x: U32
  U32

def mid(x):
  (hf(y => 5, x) + 1 : U32)

law main.out:
  Nat

def main.out():
  p0 p1 = tl(10n, 10, 3) mid(7)
  U32.to_nat((p0 + p1 : U32))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|10n
