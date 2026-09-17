# a higher-order map over an open list, its function a template (a
# closure is linear, a ~ argument is not): the two known cells
# unfold, dbl runs on the literal and sticks on x inside its cell,
# and the tail sticks on xs with dbl still in the call. The call
# shows the template instance name (map~0), with its argument.
# a spelling to review: Agda shows map dbl xs.
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

def map(~f: Nat -> Nat, l: List<Nat>) -> List<Nat>:
  match l:
    case Nil{}:
      Nil{}
    case h <> t:
      f(h) <> map(~f, t)

law main:
  @x:Nat -> @xs:List<Nat> -> List<Nat>

def main():
  x => xs => map(~dbl, 1n <> x <> xs)

#|x => xs => 2n <> dbl(x) <> map~0(dbl, xs)
