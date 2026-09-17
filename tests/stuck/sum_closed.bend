# the stuck family's closed twin (HVM4 red_sum): sum(3n) = 0+1+2+3.
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
  Nat

def main():
  sum(3n)

#|6n
