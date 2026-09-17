# over-use pays clones: keep retains x's nodes in its result, so each
# extra use pays a copy and the last use owns
# ported from bend3: the counter walks a Nat, the share a +param
import Base

type Tr is Data:
  Lf{v: U32}
  Nd{a: Tr, b: Tr}

law gen:
  for +d: Nat
  for +i: U32
  Tr

def gen(d, i):
  match d:
    case 0n:
      Lf{i}
    case 1n+p:
      Nd{gen(p, U32.mul(i, 2)), gen(p, U32.add(U32.mul(i, 2), 1))}

law keep:
  for x: Tr
  Tr

def keep(x):
  match x:
    case Lf{v}:
      Lf{v}
    case Nd{a, b}:
      Nd{a, b}

law tsum:
  for t: Tr
  U32

def tsum(t):
  match t:
    case Lf{v}:
      v
    case Nd{a, b}:
      U32.add(tsum(a), tsum(b))

law foo:
  for +x: Tr
  U32

def foo(x):
  a = keep(x)
  b = keep(x)
  U32.add(tsum(a), tsum(b))

law main.out:
  U32

def main.out():
  foo(gen(5n, 1))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|3040
