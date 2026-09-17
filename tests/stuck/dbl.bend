# the stuck family (HVM4 red_dbl_stuck): dbl(2n+x) unfolds twice,
# two successors a step, and sticks on x.
import Base

law dbl:
  for a: Nat
  Nat

def dbl(a):
  match a:
    case 0n:
      0n
    case 1n+p:
      2n+dbl(p)

law main:
  @x:Nat -> Nat

def main():
  x => dbl(2n+x)

#|x => 4n+dbl(x)
