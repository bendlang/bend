# regression witness (266a45e): a nested Array reaches its consumers
# whole in a KEEP-FREE program -- the cow that unwraps the runtime's
# per-cell seals was once gated on a program-level keep, so block ops
# on an inner array ran on the redirect cell as if it were the block.
import Base

law rd:
  for a: Array<U32>
  U32

def rd(a):
  match a:
    case ALeaf{x}:
      x
    case ANode{xs, ys}:
      U32.add(rd(xs), rd(ys))

law rdd:
  for n: Array<Array<U32>>
  U32

def rdd(n):
  match n:
    case ALeaf{inner}:
      rd(inner)
    case ANode{xs, ys}:
      U32.add(rdd(xs), rdd(ys))

law mk2:
  Array<Array<U32>>

def mk2():
  ANode{ALeaf{ANode{ALeaf{10}, ALeaf{20}}}, ALeaf{ANode{ALeaf{30}, ALeaf{2}}}}

law main.out:
  U32

law main.go:
  for w: Array<Array<U32>> & Array<U32>
  U32

def main.go(w):
  (rest, got) = w
  U32.add(rdd(rest), U32.add(rd(got), rdd(mk2())))

def main.out():
  main.go(Array.swap(Array<U32>, mk2(), 1, ANode{ALeaf{5}, ALeaf{6}}))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|135
