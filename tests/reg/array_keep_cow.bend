# regression witness (bc040b8 lineage): Array.clone answers two whole
# independent arrays -- bc040b8 walled this shape loud, the ARR turns
# ran it through a copy-on-write, and the eager clone now copies at
# the clone site. An Array is affine: only clone makes two.
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

law main.out:
  U32

law main.fin:
  for a: Array<U32>
  for w: Array<U32> & U32
  U32

def main.fin(a, w):
  (b, old) = w
  U32.add(rd(b), U32.add(rd(a), old))

law main.go:
  for c: Array<U32> & Array<U32>
  U32

def main.go(c):
  (a, b) = c
  main.fin(a, Array.swap(U32, b, 2, 50))

def main.out():
  main.go(Array.clone(U32, ANode{ANode{ALeaf{1}, ALeaf{2}}, ANode{ALeaf{3}, ALeaf{4}}}))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|70
