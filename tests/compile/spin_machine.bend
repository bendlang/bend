# a looping def whose root chain opens a non-flat single-arm ctor arg,
# with both loop-jump feeds (an inline ctor literal and a variable)
# ported from bend3: the phase counter walks a Nat (2n+m literal
# patterns), state ctors carry over; strict -- the counter leads the
# columns so the descent carries it
import Base

type Ll is Data:
  Cc{h: U32, t: Ll}
  Nn{}

type St is Data:
  Mk{a: U32, b: U32, xs: Ll}

law lsum:
  for xs: Ll
  U32

def lsum(xs):
  match xs:
    case Nn{}:
      0
    case Cc{h, t}:
      U32.add(h, lsum(t))

law go:
  for n: Nat
  for s: St
  for p: St
  U32

def go(n, s, p):
  match n s:
    case 0n Mk{a, b, xs}:
      U32.add(U32.add(a, b), lsum(xs))
    case 1n Mk{a, b, xs}:
      U32.add(1, go(0n, Mk{U32.add(a, 5), b, Cc{9, xs}}, p))
    case 2n+m0 Mk{a, b, xs}:
      +m = {m0 : Nat}
      go(1n+m, p, Mk{U32.add(a, 1), U32.add(b, 2), Cc{U32.add(2, U32.from_nat(m)), xs}})

law main.out:
  U32

def main.out():
  go(3n, Mk{1, 2, Nn{}}, Mk{4, 4, Nn{}})

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|24
