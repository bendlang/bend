# bend3 pinned elif alignment against its layout; bend is layout-free
# and any indentation reads the same case chain (the if sugar is gone:
# a Bool branch is a match in its own def)
import Base

law f.go:
  for z: Bool
  U32

def f.go(z):
  match z:
   case True{}: 5
        case False{}:
      6

law f:
  for x: U32
  U32

def f(x):
  f.go(U32.is_zero(x))

law main.out:
  U32

def main.out():
  (f(0) * 10 + f(3) : U32)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|56
