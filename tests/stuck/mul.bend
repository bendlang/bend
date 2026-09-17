# mul(2n+x, y) unfolds twice and leaves every add stuck on y: the
# goal is the same term Agda shows, add(y, add(y, mul(x, y))), not the
# original call and not mul's match.
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

law mul:
  for a: Nat
  for +b: Nat
  Nat

def mul(a, b):
  match a:
    case 0n:
      0n
    case 1n+p:
      add(b, mul(p, b))

law main:
  @x:Nat -> @y:Nat -> Nat

def main():
  x => y => mul(2n+x, y)

#|x => y => add(y, add(y, mul(x, y)))
