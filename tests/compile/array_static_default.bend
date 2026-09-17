# boxed-element array: entries move in and out by swap, defaults included
# (bend3 pinned its static-default storage; the swap semantics is the
# dialect-neutral part)
# ported from bend3: the [:Opt] literal becomes an explicit 4-leaf tree
import Base

type Opt is Data:
  Pt{a: U32, b: U32}
  Nt{}

law osum:
  for o: Opt
  U32

def osum(o):
  match o:
    case Pt{a, b}:
      U32.add(a, b)
    case Nt{}:
      100

law main.d:
  for x: Opt
  for y: Opt
  for z: Opt
  for r: Array<Opt> & Opt
  U32

def main.d(x, y, z, r):
  (a4, w) = r
  U32.add(U32.add(osum(x), osum(y)), U32.add(osum(z), osum(w)))

law main.c:
  for x: Opt
  for y: Opt
  for r: Array<Opt> & Opt
  U32

def main.c(x, y, r):
  (a3, z) = r
  main.d(x, y, z, Array.swap(Opt, a3, 2, Nt{}))

law main.b:
  for x: Opt
  for r: Array<Opt> & Opt
  U32

def main.b(x, r):
  (a2, y) = r
  main.c(x, y, Array.swap(Opt, a2, 3, Nt{}))

law main.a:
  for r: Array<Opt> & Opt
  U32

def main.a(r):
  (a1, x) = r
  main.b(x, Array.swap(Opt, a1, 1, Nt{}))

law main.out:
  U32

def main.out():
  main.a(Array.swap(Opt, ANode{ANode{ALeaf{Pt{1, 2}}, ALeaf{Nt{}}}, ANode{ALeaf{Pt{5, 6}}, ALeaf{Nt{}}}}, 0, Nt{}))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|214
