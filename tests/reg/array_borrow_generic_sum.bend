# regression witness: a borrowed array cell of a SUM element survives a
# layout change whose arms disagree on the cell. Converting Tg<U32> to
# Tg<A> (the parameter boxed) leaves word 1 owned under One (the boxed
# x) and borrowed under Two (the list), word 2 the reverse. val_arms
# keeps such words per arm behind the tag; a single mark would keep the
# wrong cell (or, before, none: the list freed twice, memory fault).
import Base

type Tg<-A: Data> is Data:
  One{x: A, l: List<&2, U32>}
  Two{l: List<&2, U32>, y: A}

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
  Array<Tg<U32>>

def mk():
  ANode{ALeaf{One{1, [10, 20]}},
    ALeaf{Two{[30, 40], 2}}}

law poly.fin:
  for -A: Data
  for  s: U32
  for  r: Array<Tg<A>> & Tg<A>
  A & U32

def poly.fin(A, s, r):
  (arr, p) = r
  match p:
    case One{x, l}:
      (x, U32.add(s, sum(l)))
    case Two{l, y}:
      (y, U32.add(s, sum(l)))

law poly:
  for -A: Data
  for  r: Array<Tg<A>> & Tg<A>
  A & (A & U32)

def poly(A, r):
  (arr, p) = r
  match p:
    case One{x, l}:
      +s = sum(l)
      t = sum([s, s])
      (x, poly.fin(A, U32.add(s, t), Array.get(Tg<A>, arr, 1)))
    case Two{l, y}:
      +s = sum(l)
      t = sum([s, s])
      (y, poly.fin(A, U32.add(s, t), Array.get(Tg<A>, arr, 0)))

law go2:
  for r: U32 & (U32 & U32)
  U32

def go2(r):
  (x, r2) = r
  (y, s) = r2
  U32.add(s, U32.add(U32.mul(x, 100), U32.mul(y, 1000)))

law go:
  for arr: Array<Tg<U32>>
  U32

def go(arr):
  r = Array.get(Tg<U32>, arr, 0)
  go2(poly(U32, r))

law main.out:
  U32

def main.out():
  go(mk())

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|2260
