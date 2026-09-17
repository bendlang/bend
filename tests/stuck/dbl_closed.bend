# the stuck family's closed twin (HVM4 red_dbl): dbl(3n).
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
  Nat

def main():
  dbl(3n)

#|6n
