# nested pattern in a recursive def, on a shared value: fib reuses the
# pattern field p across both forked calls
# ported from bend3: the reuse rides a +scrutinee, the fork a
# parallel let
import Base

type Nt is Data:
  Zr{}
  Sc{p: Nt}

law fib:
  for +n: Nt
  U32

def fib(n):
  match n:
    case Zr{}:
      1
    case Sc{Zr{}}:
      1
    case Sc{Sc{p}}:
      a b = fib(p) fib(Sc{p})
      U32.add(a, b)

law mk:
  for m: Nat
  Nt

def mk(m):
  match m:
    case 0n:
      Zr{}
    case 1n+p:
      Sc{mk(p)}

law main.out:
  U32

def main.out():
  fib(mk(15n))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|987
