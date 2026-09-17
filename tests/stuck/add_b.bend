# the stuck family (HVM4 red_add_stuck_b): a closed first argument
# unfolds add to the end, and the open second argument rides through.
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
  x => add(2n, 2n+x)

#|x => 4n+x
