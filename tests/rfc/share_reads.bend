# a shared value read twice: each extra use of the + handle is a
# retain, every match unshares one layer, values stay exact -- the
# whole-tree double walk answers twice the single sum.
# ported from bend3: +Tree rides the + binder over the Data Tree. The
# csrc pins hold the segments to the SHARED path, where bend3 pinned
# sha_move/seq_sha_step: the Nd build seals its fields ref-counted
# (rfc_seal) and foo's second read of x is a keep (term_keep bumps
# the count -- nothing copied), never a clone.
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

law bar:
  for x: Tree
  U32

def bar(x):
  match x:
    case Lf{v}:
      v
    case Nd{a, b}:
      U32.add(bar(a), bar(b))

law foo:
  for +x: Tree
  U32

def foo(x):
  a = bar(x)
  b = bar(x)
  U32.add(a, b)

law main.out:
  Nat

def main.out():
  U32.to_nat(foo(gen(5n, 1)))


law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|3040n
