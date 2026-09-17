# regression witness: a let reaching expr rather than leaf -- here the
# block body of an erased-binder lambda in argument position, which
# expr walks in place -- took a "local" path when its body held no call:
# the value was carbonized under the pass-through continuation, so a
# call-valued let minted an identity "$k" and the let stayed inside the
# argument, where the C emitter admits only flat calls ("an
# under-applied def value: gen"). expr now threads every let through
# its continuation like leaf does, so the cuts land outside the call.
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


law konst:
  for f: @-x: Nat -> U32
  U32

def konst(f):
  f(0n)

law main.out:
  U32

def main.out():
  konst(x =>
    y = sum(gen(3n, 0))
    U32.add(y, 1))

law main:
  IO(Unit)

def main():
  do IO<Unit>:
    w : Unit <- IO.print(U32.show(main.out()))
    IO.pure(Unit, Unit{})

#|29
