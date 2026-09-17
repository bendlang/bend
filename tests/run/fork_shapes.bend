# fork shapes per the GUIDE: a width-2 tree, a width-4 burst and a width-8
# burst in ONE statement each; T=1 execution pins the joined result
# ported from bend3: `a & b = x & y` forks become parallel lets,
# tree depth becomes Nat, the shared index a +U32 binder
import Base

law leaf:
  for +i: U32
  U32

def leaf(i):
  U32.add(U32.mul(i, i), 1)

law tree:
  for +d: Nat
  for +i: U32
  U32

def tree(d, i):
  match d:
    case 0n:
      leaf(i)
    case 1n+p:
      a b = tree(p, U32.mul(i, 2)) tree(p, U32.add(U32.mul(i, 2), 1))
      U32.add(a, b)

law burst4:
  for +i: U32
  U32

def burst4(i):
  a b c d = leaf(i) leaf(U32.add(i, 1)) leaf(U32.add(i, 2)) leaf(U32.add(i, 3))
  U32.add(U32.add(U32.add(a, b), c), d)

law burst8:
  for +i: U32
  U32

def burst8(i):
  a b c d e f g h = leaf(i) leaf(U32.add(i, 1)) leaf(U32.add(i, 2)) leaf(U32.add(i, 3)) leaf(U32.add(i, 4)) leaf(U32.add(i, 5)) leaf(U32.add(i, 6)) leaf(U32.add(i, 7))
  U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(a, b), c), d), e), f), g), h)

law main.out:
  U32

def main.out():
  U32.add(U32.add(U32.mul(tree(3n, 0), 10000), U32.mul(burst4(1), 100)), burst8(1))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|1483612
