# CONFLUENCE under real threads: a 4096-leaf fork tree of
# wrap-arithmetic leaves gives the SAME U32 checksum at one thread and
# at eight -- 506569506, bend3's own golden (verified against an
# independent host-JS mirror). No interp lane: the structural Word
# evaluator needs minutes for 4096 hash leaves, so the pin is one
# thread v eight v the JS oracle.
# ported from bend3: depth becomes Nat fuel, forks spell the
# parallel let, operators spell U32.xor/shln/shrn/mul/add, reused
# words take + U32 binders (U32 is Data)
import Base

law leaf:
  for +i: U32
  U32

def leaf(i):
  +x = {U32.mul(U32.xor(i, U32.shln(i, 13n)), 2654435761) : U32}
  U32.add(U32.xor(x, U32.shrn(x, 17n)), i)

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
  tree(12n, 1)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|506569506
