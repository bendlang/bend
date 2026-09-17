# exact coverage, no default arm
# ported from bend3: local Nat-like type with bare ctor names
import Base

type Nt is Data:
  Zr{}
  Sc{p: Nt}

law flip:
  for n: Nt
  Nt

def flip(n):
  match n:
    case Zr{}:
      Sc{Zr{}}
    case Sc{p}:
      p

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
  size(flip(flip(Sc{Zr{}})))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|1
