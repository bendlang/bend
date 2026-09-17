# fork members that are not bare calls (ops over recursive calls)
# ported from bend3: the counter walks a Nat, the fork a parallel let,
# the shared argument a +param
import Base

law f:
  for +n: Nat
  U32

def f(n):
  match n:
    case 0n:
      1
    case 1n+p:
      U32.add(f(p), U32.add(1, U32.from_nat(p)))

law g:
  for +x: Nat
  U32

def g(x):
  a b = U32.add(f(x), 1) U32.mul(f(x), 2)
  U32.add(a, b)

law main.out:
  U32

def main.out():
  g(10n)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|169
