# eta-short ctor arm: the Sc arm of a lambda-match is a bare Ref
# consuming the field
# ported from bend3: local Nat-like type with bare ctor names
import Base

type Nt is Data:
  Zr{}
  Sc{p: Nt}

law size:
  for n: Nt
  U32

def size(n):
  match n:
    case Zr{}:
      0
    case Sc{p}:
      U32.add(1, size(p))

law f:
  Nt -> U32

def f():
  \{Zr: 99; Sc: size}

law main.out:
  U32

def main.out():
  U32.add(f(Zr{}), f(Sc{Sc{Zr{}}}))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|100
