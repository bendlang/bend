# a non-linear argument: sq(1n+x) is mul(1n+x, 1n+x), which unfolds
# one step to add(1n+x, mul(x, 1n+x)); the add unfolds through its
# prefix and sticks on x, with the copy of 1n+x kept in the inner
# stuck call.
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

law sq:
  for +a: Nat
  Nat

def sq(a):
  mul(a, a)

law main:
  @x:Nat -> Nat

def main():
  x => sq(1n+x)

#|x => 1n+add(x, mul(x, 1n+x))
