# regression witness (2ff58c0): an Array of heap-owning elements keeps
# tag, cid and RFC bit through the round trip -- the flat lane once
# packed every element into a u32 cell, so a two-constructor element
# came back as a bare loc and every match fell into the last arm. The
# shared read rides a local Arr.clone (an Array is affine; its Data
# cells duplicate through + fields), strict.
import Base

type Cell is Data:
  CA{v: U32}
  CB{}

law Arr.clone.leaf:
  for +x: Cell
  Array<Cell> & Array<Cell>

def Arr.clone.leaf(x):
  (ALeaf{x}, ALeaf{x})

law Arr.clone.node:
  for cx: Array<Cell> & Array<Cell>
  for cy: Array<Cell> & Array<Cell>
  Array<Cell> & Array<Cell>

def Arr.clone.node(cx, cy):
  (ax, ay) = cx
  (bx, by) = cy
  (ANode{ax, bx}, ANode{ay, by})

law Arr.clone:
  for t: Array<Cell>
  Array<Cell> & Array<Cell>

def Arr.clone(t):
  match t:
    case ALeaf{x}:
      Arr.clone.leaf(x)
    case ANode{xs, ys}:
      Arr.clone.node(Arr.clone(xs), Arr.clone(ys))

law cw:
  for c: Cell
  U32

def cw(c):
  match c:
    case CA{v}:
      v
    case CB{}:
      100

law csum:
  for a: Array<Cell>
  U32

def csum(a):
  match a:
    case ALeaf{x}:
      cw(x)
    case ANode{xs, ys}:
      U32.add(csum(xs), csum(ys))

law mkc:
  Array<Cell>

def mkc():
  ANode{ANode{ALeaf{CA{7}}, ALeaf{CB{}}}, ANode{ALeaf{CA{30}}, ALeaf{CB{}}}}

law shared.go:
  for p: Array<Cell> & Array<Cell>
  U32

def shared.go(p):
  (a, b) = p
  U32.add(csum(a), csum(b))

law shared:
  for a: Array<Cell>
  U32

def shared(a):
  shared.go(Arr.clone(a))

law main.out:
  U32

law main.go:
  for w: Array<Cell> & Cell
  U32

def main.go(w):
  (b, old) = w
  U32.add(csum(b), U32.add(cw(old), shared(mkc())))

def main.out():
  main.go(Array.swap(Cell, mkc(), 1, CA{5}))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|716
