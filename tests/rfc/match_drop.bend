# drop-driven collection on shared values: peek reads only the left
# spine of the shared tree (the right children drop), and waste never
# uses its tree argument at all -- a whole-value drop. Values exact.
# ported from bend3: the +Tree ascription becomes a + let (bend's +
# is a binder over the Data-kinded Tree, not a type),
# depth rides Nat
import Base

type Tree is Data:
  Lf{v: U32}
  Nd{a: Tree, b: Tree}

law gen:
  for +d: Nat
  for +i: U32
  Tree

def gen(d, i):
  match d:
    case 0n:
      Lf{i}
    case 1n+e:
      Nd{gen(e, U32.mul(i, 2)), gen(e, U32.add(U32.mul(i, 2), 1))}

law peek:
  for t: Tree
  U32

def peek(t):
  match t:
    case Lf{v}:
      v
    case Nd{a, b}:
      peek(a)

law waste:
  for t: Tree
  for x: U32
  U32

def waste(t, x):
  x

law main.out:
  Nat

def main.out():
  +t = {gen(5n, 1) : Tree}
  a = peek(t)
  b = waste(t, 7)
  U32.to_nat(U32.add(a, b))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|39n
