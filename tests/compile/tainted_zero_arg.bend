# zero-arg def referencing a recursive (forked) def, used as a bare value
# ported from bend3: counters walk Nats, forks are parallel lets
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

law t:
  Tr

def t():
  gen(5n, 0)

law main.out:
  U32

def main.out():
  sum(t)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|496
