# the boxed read: Array.get on a record element hands the element out
# SHARED (the slot and the reader both own it through its refcount);
# Array.new spreads one record over every slot the same way, and swap
# moves a shared old value out whole
import Base

type Pt is Data:
  MkPt{x: U32, y: U32}

law psum:
  for p: Pt
  U32

def psum(p):
  match p:
    case MkPt{x, y}:
      U32.add(x, y)

law s4:
  for acc : U32
  for r   : Array<Pt> & Pt
  U32

def s4(acc, r):
  (a2, p) = r
  U32.add(U32.mul(acc, 100), psum(p))

law s3:
  for acc : U32
  for r   : Array<Pt> & Pt
  U32

def s3(acc, r):
  (a, old) = r
  s4(U32.add(U32.mul(acc, 10), psum(old)), Array.get(Pt, a, 1))

law s2:
  for acc : U32
  for r   : Array<Pt> & Pt
  U32

def s2(acc, r):
  (a, p) = r
  s3(U32.add(U32.mul(acc, 10), psum(p)), Array.swap(Pt, a, 1, MkPt{5, 6}))

law s1:
  for r: Array<Pt> & Pt
  U32

def s1(r):
  (a, p) = r
  s2(psum(p), Array.get(Pt, a, 3))

law s0:
  for a: Array<Pt>
  U32

def s0(a):
  s1(Array.get(Pt, a, 0))

law leafp:
  for r: Array<Pt> & Pt
  U32

def leafp(r):
  (a2, p) = r
  psum(p)

law main.out:
  U32

def main.out():
  U32.add(U32.mul(s0([MkPt{3, 4} : Pt*4n]), 10), leafp(Array.get(Pt, ALeaf{MkPt{1, 2}}, 0)))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|777113
