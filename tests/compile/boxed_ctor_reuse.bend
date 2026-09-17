# 2-u32-field ctor (boxed) built by a closure; the word feeds two uses
# ported from bend3: the contraction becomes a +param helper aliased at
# the matching @+ type (U32 is Data, so the + binder is licensed
# directly)
import Base

type Point is Data:
  MkPt{x: U32, y: U32}

law mk.go:
  for +n: U32
  Point

def mk.go(n):
  MkPt{n, U32.mul(n, 2)}

law mk:
  @+n: U32 -> Point

def mk():
  mk.go

law get:
  for p: Point
  U32

def get(p):
  match p:
    case MkPt{x, y}:
      U32.add(x, y)

law main.out:
  U32

def main.out():
  get(mk(5))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|15
