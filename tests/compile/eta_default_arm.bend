# eta default: the lambda-match default tail is a bare Ref taking the
# whole value
# ported from bend3: the U32 switch becomes a lambda-match on a local
# Nat-like type; dec drops one Sc and counts the rest
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

law dec:
  for n: Nt
  U32

def dec(n):
  match n:
    case Zr{}:
      0
    case Sc{p}:
      size(p)

law f:
  Nt -> U32

def f():
  \{Zr: 100; dec}

law main.out:
  U32

def main.out():
  U32.add(f(Zr{}), f(Sc{Sc{Sc{Sc{Sc{Sc{Sc{Sc{Zr{}}}}}}}}}))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|107
