# regression witness: a width-2 let whose values are all calls became a
# FORK before any liveness check, so a binding the body never used
# (y below) still ran its call, took a joiner slot and minted the
# sequential chain beside it. Dead binders are now pruned first, as
# the single let always did: the let drops to width 1 and is a CUT,
# and sum(b) never runs.
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
      U32.add(x, 1)

law main.out:
  U32

def main.out():
  sum(gen(4n, 0))

law main:
  IO(Unit)

def main():
  do IO<Unit>:
    w : Unit <- IO.print(U32.show(main.out()))
    IO.pure(Unit, Unit{})

#|4
