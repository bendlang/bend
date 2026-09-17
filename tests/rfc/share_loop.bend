# the tail-loop retention class: each iteration takes one more handle
# off the shared tree, consumes it whole, and recurses -- sharing
# frees per iteration, nothing accumulates across 4096 rounds over a
# 63-node tree.
# ported from bend3: +Tree rides the + binder over the Data Tree, the
# counter becomes Nat; no interp lane (4096 structural-Word tree sums
# need minutes there)
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

law sum:
  for t: Tree
  U32

def sum(t):
  match t:
    case Lf{v}:
      v
    case Nd{a, b}:
      U32.add(sum(a), sum(b))

law spin:
  for n   : Nat
  for +t  : Tree
  for acc : U32
  U32

def spin(n, t, acc):
  match n:
    case 0n:
      U32.add(acc, sum(t))
    case 1n+m:
      spin(m, t, U32.add(acc, sum(t)))

law main.out:
  Nat

def main.out():
  U32.to_nat(spin(4096n, gen(5n, 1), 0))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|6227440n
