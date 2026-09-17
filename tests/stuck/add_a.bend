# the stuck family (HVM4 red_add_stuck_a): add recurses on its first
# argument, so a prefix there unfolds and the call sticks on x.
import Base

law add:
  for a: Nat
  for b: Nat
  Nat

def add(a, b):
  match a:
    case 0n:
      b
    case 1n+p:
      1n+add(p, b)

law main:
  @x:Nat -> Nat

def main():
  x => add(2n+x, 2n)

#|x => 2n+add(x, 2n)
