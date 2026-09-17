# default rebind then deeper columns re-matched
# ported from bend3: local Nat-like type with bare ctor names
import Base

type Nt is Data:
  Zr{}
  Sc{p: Nt}

law g:
  for a: Nt
  for b: Nt
  U32

def g(a, b):
  match a, b:
    case Zr{}, Zr{}:
      1
    case x, Zr{}:
      2
    case Zr{}, Sc{y}:
      3
    case x, Sc{y}:
      4

law main.out:
  U32

def main.out():
  U32.add(g(Zr{}, Zr{}), U32.add(g(Sc{Zr{}}, Zr{}), U32.add(g(Zr{}, Sc{Zr{}}), g(Sc{Zr{}}, Sc{Zr{}}))))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|10
