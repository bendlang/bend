# closure/HOF pipelines: compose chains (every closure consumed exactly
# once), a recursively BUILT closure chain, and a closure stored in and
# extracted from a constructor field
# ported from bend3: generics become erased Type params, the chain
# counter becomes Nat with its U32 image rebuilt via U32.from_nat
import Base

law compose:
  for -A: Type
  for -B: Type
  for -C: Type
  for  f: A -> B
  for  g: B -> C
  A -> C

def compose(A, B, C, f, g):
  x => g(f(x))

type FBox is Type:
  MkF{f: U32 -> U32}

law chain:
  for +n: Nat
  U32 -> U32

def chain(n):
  match n:
    case 0n:
      x => x
    case 1n+p:
      k = U32.add(1, U32.from_nat(p))
      compose(U32, U32, U32, x => U32.add(x, k), chain(p))

law unbox:
  for b: FBox
  U32

def unbox(b):
  match b:
    case MkF{f}:
      f(4)

law sqr:
  for x: U32
  U32

def sqr(x):
  +y = x
  U32.mul(y, y)

law main.out:
  U32

def main.out():
  a = (compose(U32, U32, U32, compose(U32, U32, U32, x => U32.add(x, 1), x => U32.mul(x, 2)), sqr))(3)
  b = (chain(3n))(10)
  c = unbox(MkF{y => U32.mul(y, 5)})
  U32.add(U32.add(U32.mul(a, 1000), U32.mul(b, 10)), c)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|64180
