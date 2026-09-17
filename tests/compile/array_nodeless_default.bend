# boxed-element array of nullary-heavy ctors: swaps move owned values in
# and out (bend3 pinned its nodeless-default refc elision; the moves are
# the dialect-neutral part)
# ported from bend3: the [:Slot] literal becomes an explicit 4-leaf tree
import Base

type Vl is Data:
  MkVl{n: U32}

type Slot is Data:
  Emp{}
  Sub{v: Vl}

law slot_num:
  for s: Slot
  U32

def slot_num(s):
  match s:
    case Emp{}:
      0
    case Sub{MkVl{n}}:
      n

law go.b:
  for a: Slot
  for r: Array<Slot> & Slot
  U32

def go.b(a, r):
  (e2, b) = r
  U32.add(U32.mul(100, slot_num(a)), slot_num(b))

law go.a:
  for r: Array<Slot> & Slot
  U32

def go.a(r):
  (e1, a) = r
  go.b(a, Array.swap(Slot, e1, 0, Emp{}))

law go:
  for e: Array<Slot>
  U32

def go(e):
  go.a(Array.swap(Slot, e, 0, Sub{MkVl{7}}))

law main.out:
  U32

def main.out():
  go(ANode{ANode{ALeaf{Emp{}}, ALeaf{Emp{}}}, ANode{ALeaf{Emp{}}, ALeaf{Emp{}}}})

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|7
