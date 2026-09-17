# Array.size answers the array and its element count (1 << class); a
# matched half reports half the parent, a leaf reports 1
import Base

law sz:
  for r: Array<U32> & U32
  U32

def sz(r):
  (a2, n) = r
  n

law half:
  for a: Array<U32>
  U32

def half(a):
  match a:
    case ALeaf{x}:
      x
    case ANode{xs, ys}:
      sz(Array.size(U32, xs))

law main.out:
  U32

def main.out():
  s16 = sz(Array.size(U32, [7 : U32*16n]))
  s8 = half([7 : U32*16n])
  s1 = sz(Array.size(U32, ALeaf{9}))
  U32.add(U32.mul(U32.add(U32.mul(s16, 100), s8), 10), s1)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|16081
