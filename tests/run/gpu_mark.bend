# the GPU mark f!(x) has zero semantic content: interpreter and CPU-only
# compiled code treat it exactly as f(x)
# ported from bend3: depth becomes Nat, the fork a parallel let
import Base

law gmark:
  for +d: Nat
  U32

def gmark(d):
  match d:
    case 0n:
      3
    case 1n+p:
      a b = gmark(p) gmark(p)
      U32.add(a, b)

law main.out:
  U32

def main.out():
  x = gmark!(2n)
  y = gmark(2n)
  U32.add(U32.mul(x, 100), y)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|1212
