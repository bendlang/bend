# closure literal of a recursive def + dispatch through dynamic apply
# ported from bend3: the counter walks a Nat, its U32 image rebuilt
import Base

law go:
  for +n: Nat
  for  k: U32 -> U32
  U32

def go(n, k):
  match n:
    case 0n:
      k(0)
    case 1n+p:
      go(p, r => k(U32.add(r, U32.add(1, U32.from_nat(p)))))

law use:
  ((U32 -> U32) -> U32) -> U32

def use():
  f => f(x => U32.add(x, 1000))

law main.out:
  U32

def main.out():
  use(go(10n))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|1055
