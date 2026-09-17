# recursive def whose tail builds a ctor from two recursive calls, and a
# forked consumer
# ported from bend3: counters walk Nats, the fork becomes a parallel let
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

law sum:
  for t: Tr
  U32

def sum(t):
  match t:
    case Lf{v}:
      v
    case Nd{a, b}:
      x y = sum(a) sum(b)
      U32.add(x, y)

law main.out:
  U32

def main.out():
  sum(gen(6n, 0))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|2016
