# a fold with a ref as its template function: foldr(~add, 0n,
# Con{2n, Con{x, xs}}) unfolds two cells, the first add runs on 2n
# and the second sticks on x, over the fold stuck on xs, shown by
# its template instance name (foldr~0), with its argument.
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

def foldr(~f: Nat -> Nat -> Nat, z: Nat, l: List<Nat>) -> Nat:
  match l:
    case Nil{}:
      z
    case h <> t:
      f(h, foldr(~f, z, t))

law main:
  @x:Nat -> @xs:List<Nat> -> Nat

def main():
  x => xs => foldr(~add, 0n, 2n <> x <> xs)

#|x => xs => 2n+add(x, foldr~0(add, 0n, xs))
