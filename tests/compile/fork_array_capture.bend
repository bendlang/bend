# an array living across a fork
# ported from bend3: the 2-slot [:U32] literal becomes an explicit tree,
# the fork a parallel let, the work counter a Nat
import Base

law work:
  for +n: Nat
  U32

def work(n):
  match n:
    case 0n:
      1
    case 1n+p:
      U32.add(U32.add(1, U32.from_nat(p)), work(p))

law f.fin:
  for r1 : U32
  for r2 : U32
  for r  : Array<U32> & U32
  U32

def f.fin(r1, r2, r):
  (a3, y) = r
  U32.add(U32.add(r1, r2), y)

law f.go:
  for r: Array<U32> & U32
  U32

def f.go(r):
  (a2, x) = r
  r1 r2 = work(U32.to_nat(x)) work(7n)
  f.fin(r1, r2, Array.get(U32, a2, 1))

law f:
  for a: Array<U32>
  U32

def f(a):
  f.go(Array.get(U32, a, 0))

law main.out:
  U32

def main.out():
  f(ANode{ALeaf{4}, ALeaf{9}})

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|49
