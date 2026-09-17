# a tree used twice: the extra use pays a copy; peek opens two levels
# deep while sum walks whole, both off one binder
# ported from bend3: counters walk Nats, forks are parallel lets,
# the share a +param
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
      l r = gen(p, U32.mul(i, 2)) gen(p, U32.add(U32.mul(i, 2), 1))
      Nd{l, r}

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

law peek:
  for t: Tr
  U32

def peek(t):
  match t:
    case Lf{v}:
      v
    case Nd{Lf{v}, b}:
      s = sum(b)
      U32.add(v, s)
    case Nd{Nd{aa, ab}, b}:
      x y = sum(aa) sum(ab)
      z = sum(b)
      U32.add(x, U32.add(y, z))

law dup_use:
  for +t: Tr
  U32

def dup_use(t):
  a b = sum(t) peek(t)
  U32.add(a, b)

law main.out:
  U32

def main.out():
  dup_use(gen(4n, 1))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|752
