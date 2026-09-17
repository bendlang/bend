# f32: a single-f32-field ctor and f32 array elements move by swap
# ported from bend3: the [:F32] literal becomes an explicit 4-leaf
# tree (xs = the LOW flat half: index 1 is xs.ys), gets become
# swaps, literals rebuild via F32.div; no
# interpreter lane (Base's F32 axioms are stuck there)
import Base

type FBx is Data:
  MkFBx{x: F32}

law fl:
  for n: U32
  for d: U32
  F32

def fl(n, d):
  F32.div(U32.to_f32(n), U32.to_f32(d))

law unbox:
  for b: FBx
  F32

def unbox(b):
  match b:
    case MkFBx{x}:
      x

law main.b:
  for x: F32
  for r: Array<F32> & F32
  U32

def main.b(x, r):
  (b3, z) = r
  F32.to_u32(F32.mul(F32.add(x, F32.add(unbox(MkFBx{fl(5, 2)}), z)), fl(100, 1)))

law main.a:
  for r: Array<F32> & F32
  U32

def main.a(r):
  (b2, x) = r
  main.b(x, Array.swap(F32, b2, 0, U32.to_f32(0)))

law main.out:
  U32

def main.out():
  main.a(Array.swap(F32, ANode{ANode{ALeaf{U32.to_f32(0)}, ALeaf{fl(5, 4)}}, ANode{ALeaf{U32.to_f32(0)}, ALeaf{U32.to_f32(0)}}}, 1, U32.to_f32(0)))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|375
