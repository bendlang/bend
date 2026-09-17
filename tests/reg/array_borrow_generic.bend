# regression witness: a borrowed array cell survives a layout change.
# Array.get lends the element's box words (blk_keep materializes an
# owner); passing the element to a generic def converts its flat layout
# (the type parameter boxed) and val_to once dropped the borrow marks
# on the way, so the callee owned a list the array still held: freed
# twice, memory fault. sum(Con{s2, ..}) reuses the freed nodes so a
# wrong read shows before the array is dropped.
import Base

type Ent<-A: Data> is Data:
  E{n: A, l: List<&2, U32>}

law sum:
  for l: List<&2, U32>
  U32

def sum(l):
  match l:
    case Nil{}:
      0
    case h <> t:
      U32.add(h, sum(t))

law mk:
  Array<Ent<U32>>

def mk():
  ANode{ALeaf{E{1, [10, 20]}}, ALeaf{E{2, [30]}}}

law poly.fin:
  for -A: Data
  for  s: U32
  for  r: Array<Ent<A>> & Ent<A>
  U32

def poly.fin(A, s, r):
  (arr, p) = r
  match p:
    case E{x, l}:
      U32.add(s, sum(l))

law poly:
  for -A: Data
  for  r: Array<Ent<A>> & Ent<A>
  U32

def poly(A, r):
  (arr, p) = r
  match p:
    case E{x, l}:
      +s = sum(l)
      t = sum([s, s])
      poly.fin(A, U32.add(s, t), Array.get(Ent<A>, arr, 0))

law go:
  for arr: Array<Ent<U32>>
  U32

def go(arr):
  r = Array.get(Ent<U32>, arr, 0)
  poly(U32, r)

law main.out:
  U32

def main.out():
  go(mk())

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|120
