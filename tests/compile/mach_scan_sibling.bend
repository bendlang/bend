# mixed fork, calm sibling first: a leaf forking a discard-only callee
# beside a recursive self call must still loop, not respin
# ported from bend3: counters walk Nats, the fork a parallel let
import Base

type Tr is Data:
  Lf{v: U32}
  Nd{h: U32, l: Tr, r: Tr}

law gen:
  for +d: Nat
  for +s: U32
  Tr

def gen(d, s):
  match d:
    case 0n:
      Lf{s}
    case 1n+p:
      Nd{U32.mul(s, 2654435761), gen(p, U32.add(U32.mul(s, 1664525), 1)), gen(p, U32.add(U32.mul(s, 214013), 3))}

law burncalm:
  for t: Tr
  U32

def burncalm(t):
  7

law walk:
  for t   : Tr
  for acc : U32
  U32

def walk(t, acc):
  match t:
    case Lf{v}:
      U32.add(acc, v)
    case Nd{h, l, r}:
      a b = burncalm(r) walk(l, U32.add(acc, h))
      U32.add(a, b)

law main.out:
  U32

def main.out():
  walk(gen(8n, 3), 0)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|356721367
