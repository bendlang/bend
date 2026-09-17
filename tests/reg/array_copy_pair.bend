# regression witness (cce7c6b): Array.clone answers its PAIR -- a
# template index shift once turned the second half into the immediate
# word zero (Tuple{kept, 0}, silent). Both halves are swap-probed.
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

law mk:
  Array<U32>

def mk():
  ANode{ANode{ALeaf{1}, ALeaf{2}}, ANode{ALeaf{3}, ALeaf{4}}}

law main.out:
  U32

law main.snd:
  for x2 : Array<U32>
  for xo : U32
  for w  : Array<U32> & U32
  U32

def main.snd(x2, xo, w):
  (y2, yo) = w
  U32.add(rd(x2), U32.add(rd(y2), U32.add(xo, yo)))

law main.fst:
  for y: Array<U32>
  for w: Array<U32> & U32
  U32

def main.fst(y, w):
  (x2, xo) = w
  main.snd(x2, xo, Array.swap(U32, y, 2, 7))

law main.go:
  for w: Array<U32> & Array<U32>
  U32

def main.go(w):
  (x, y) = w
  main.fst(y, Array.swap(U32, x, 1, 9))

def main.out():
  main.go(Array.clone(U32, mk()))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|36
