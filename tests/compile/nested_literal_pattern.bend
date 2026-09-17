# literal pattern nested inside a ctor
# ported from bend3: the U32 field becomes a Nat, the literal a 0n
import Base

type Nt is Data:
  Zr{}
  Sc{p: Nat}

law f:
  for n: Nt
  U32

def f(n):
  match n:
    case Zr{}:
      0
    case Sc{0n}:
      100
    case Sc{k}:
      U32.from_nat(k)

law main.out:
  U32

def main.out():
  U32.add(f(Sc{0n}), U32.add(f(Sc{7n}), f(Zr{})))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|107
