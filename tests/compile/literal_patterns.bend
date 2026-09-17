# non-zero literal patterns
# ported from bend3: the U32 switch becomes Nat literal patterns
import Base

law f:
  for k: Nat
  U32

def f(k):
  match k:
    case 0n:
      10
    case 1n:
      20
    case 5n:
      50
    case k2:
      U32.from_nat(k2)

law main.out:
  U32

def main.out():
  U32.add(f(0n), U32.add(f(1n), U32.add(f(5n), f(7n))))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|87
