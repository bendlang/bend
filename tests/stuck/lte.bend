# a nested match: lte(1n+x, y) passes the outer match and sticks on
# the inner one. The goal must fold back to the call, lte(1n+x, y),
# as Agda shows a case tree stuck at its second split, never the
# inner match over y.
import Base

law lte:
  for a: Nat
  for b: Nat
  Bool

def lte(a, b):
  match a:
    case 0n:
      True{}
    case 1n+p:
      match b:
        case 0n:
          False{}
        case 1n+q:
          lte(p, q)

law main:
  @x:Nat -> @y:Nat -> Bool

def main():
  x => y => lte(1n+x, y)

#|x => y => lte(1n+x, y)
