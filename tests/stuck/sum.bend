# the stuck family, from HVM4 (test/red_*_stuck.hvm4, before 3b63a8d):
# a ref applied to a constructor prefix over a free variable unfolds
# through the prefix and sticks on the variable. sum(3n+x) matches
# three times, and each step leaves an add stuck on x.
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

law sum:
  for +a: Nat
  Nat

def sum(a):
  match a:
    case 0n:
      0n
    case 1n+p:
      1n+add(p, sum(p))

law main:
  @x:Nat -> Nat

def main():
  x => sum(3n+x)

#|x => 3n+add(x, 2n+add(x, 1n+add(x, sum(x))))
