# match default arm that rebinds and rebuilds
# ported from bend3: local Nat-like type with bare ctor names
import Base

type Nt is Data:
  Zr{}
  Sc{p: Nt}

law peel:
  for a: Nt
  for b: Nt
  Nt

def peel(a, b):
  match a, b:
    case Sc{x}, Sc{y}:
      x
    case Zr{}, y:
      y
    case x, y:
      x

law size:
  for n: Nt
  U32

def size(n):
  match n:
    case Zr{}:
      0
    case Sc{p}:
      U32.add(1, size(p))

law main.out:
  U32

def main.out():
  U32.add(size(peel(Sc{Sc{Zr{}}}, Sc{Zr{}})), size(peel(Sc{Zr{}}, Zr{})))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|2
