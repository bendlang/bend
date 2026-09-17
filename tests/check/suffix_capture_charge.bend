# bend3 priced a suffix capture (a let-bound value re-charged at every
# split leaf); bend has no splits and bans the let-then-match: the
# dispatch moves behind its own def, the affine wall owns the class
# (the capture twins pin it), and main answers 0
import Base

law use2.go:
  for k: Nat
  U32

def use2.go(k):
  match k:
    case Zero{}:
      0
    case Succ{p}:
      1

law use2:
  for n: Nat
  U32

def use2(n):
  use2.go(n)

law main:
  U32

def main():
  0

#|0
