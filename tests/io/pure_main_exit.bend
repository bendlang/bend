# a pure main through every backend, fork tree included: the built
# binary prints the result word and exits 0.
# ported from bend3: the fork depth becomes Nat fuel (bend has no
# word patterns), `a & b = x & y` becomes the parallel let,
# shared binders take + Nat/+ U32 (both Data); bend3's result-word exit code
# is bend3 CLI behavior -- bend binaries print and exit 0
import Base

law leaf:
  for +i: U32
  U32

def leaf(i):
  U32.mul(i, i)

law tree:
  for +d: Nat
  for +i: U32
  U32

def tree(d, i):
  match d:
    case 0n:
      leaf(i)
    case 1n+e:
      a b = tree(e, U32.mul(i, 2)) tree(e, U32.add(U32.mul(i, 2), 1))
      U32.add(a, b)

law main.out:
  U32

def main.out():
  tree(3n, 1)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|1100
