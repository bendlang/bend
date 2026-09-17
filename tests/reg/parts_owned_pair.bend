# regression witness (f72dc46): a fused record's OWNED fields obey the
# use counts -- a Parts-bound pair holding a block was once
# rebuilt at every use (two Tuples aliasing one array, use-after-free)
# and never dropped in the arm that ignores it (a leak). The doubled
# read rides a local Pr.clone over Array.clone (the pair is affine),
# strict.
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

law go:
  for p: Array<U32> & U32
  U32

def go(p):
  match p:
    case Tuple{b, o}:
      U32.add(rd(b), o)

law Pr.clone.go:
  for +o: U32
  for  c: Array<U32> & Array<U32>
  (Array<U32> & U32) & (Array<U32> & U32)

def Pr.clone.go(o, c):
  (a, b) = c
  ((a, o), (b, o))

law Pr.clone:
  for p: Array<U32> & U32
  (Array<U32> & U32) & (Array<U32> & U32)

def Pr.clone(p):
  (a, o) = p
  Pr.clone.go(o, Array.clone(U32, a))

law use2.go:
  for c: (Array<U32> & U32) & (Array<U32> & U32)
  U32

def use2.go(c):
  (p, q) = c
  U32.add(go(p), go(q))

law use2:
  for p: Array<U32> & U32
  U32

def use2(p):
  use2.go(Pr.clone(p))

law pick2:
  for c: Bool
  for p: Array<U32> & U32
  U32

def pick2(c, p):
  match c:
    case True{}:
      go(p)
    case False{}:
      5

law main.out:
  U32

def main.out():
  a = use2(Array.swap(U32, mk(), 1, 9))
  b = pick2(False{}, Array.swap(U32, mk(), 2, 8))
  c = pick2(True{}, Array.swap(U32, mk(), 0, 6))
  U32.add(a, U32.add(b, c))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|59
