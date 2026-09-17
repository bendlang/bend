# an eta-short arm (the def returns a function) whose leaf holds a
# plain let and tails the self-recursive call: the saturating
# application must commute through the statement
# ported from bend3: the counter walks a Nat, its U32 image rebuilt
import Base

law go:
  for +f  : Nat
  for acc : U32
  U32 -> U32

def go(f, acc):
  match f:
    case 0n:
      x => U32.add(x, acc)
    case 1n+g:
      a = U32.add(acc, U32.add(1, U32.from_nat(g)))
      go(g, a)

law main.out:
  U32

def main.out():
  go(3n, 0)(10)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|16
