# a dropped closure whose capture is an array: the drop must collect the
# captured tree (bend3 pinned its slab drop walk; the capture-drop is
# the dialect-neutral part)
# ported from bend3: the 2^17-slot slab becomes a 16-leaf Base Array
import Base

law foo.go:
  for x: U32
  for r: Array<U32> & U32
  U32

def foo.go(x, r):
  (a2, v) = r
  U32.add(v, x)

law foo:
  for a: Array<U32>
  for x: U32
  U32

def foo(a, x):
  foo.go(x, Array.get(U32, a, 12))

law main.out:
  U32

def main.out():
  g = foo([7 : U32*16n])
  5

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|5
