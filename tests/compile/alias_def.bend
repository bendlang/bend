# alias def: body is a bare Ref; ported from bend3 (x * 3 -> U32.mul)
import Base

law g:
  U32 -> U32

def g():
  x => U32.mul(x, 3)

law f:
  U32 -> U32

def f():
  g

law main.out:
  U32

def main.out():
  f(7)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|21
