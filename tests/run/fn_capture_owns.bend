# a lambda owns what it captures: a def that uses its argument AND
# returns a lambda that also uses it -- the closure owns its instance,
# the original dies in make's body. Pre-fix (bend3) this read freed
# memory when main applied f.
# ported from bend3: the doubled tree takes a +Tree binder (Tree is
# Data), depth rides Nat, the answer reads back via U32.to_nat
import Base

type Tree is Data:
  Lf{v: U32}
  Nd{l: Tree, r: Tree}

law build:
  for +d: Nat
  for +x: U32
  Tree

def build(d, x):
  match d:
    case 0n:
      Lf{x}
    case 1n+e:
      Nd{build(e, U32.add(x, x)), build(e, U32.add(U32.add(x, x), 1))}

law tsum:
  for t: Tree
  U32

def tsum(t):
  match t:
    case Lf{v}:
      v
    case Nd{l, r}:
      U32.add(tsum(l), tsum(r))

law make:
  for +x: Tree
  Unit -> U32

def make(x):
  a = tsum(x)
  u => U32.add(a, tsum(x))

law main.out:
  Nat

def main.out():
  t = build(3n, 1)
  f = make(t)
  U32.to_nat(f(Unit{}))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|184n
