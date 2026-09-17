# bend3's capture-position hoist (an under-applied call's argument
# minting apply$ in a pure leaf); bend has no taint hoist and
# under-applied defs are plain values -- the partial applications bind,
# apply later, and the value carries: 28
import Base

type Pr8 is Data:
  Pr8{x: U32, y: U32}

law add3:
  for a: U32
  for b: U32
  for c: U32
  U32

def add3(a, b, c):
  (a + b + c : U32)

law sum8:
  for p: Pr8
  U32

def sum8(p):
  match p:
    case Pr8{x, y}:
      (x + y : U32)

law main.out:
  Nat

def main.out():
  g = {y => (y + 1 : U32) : U32 -> U32}
  h = {add3(g(2)) : U32 -> U32 -> U32}
  k = {add3(sum8(Pr8{7, 8})) : U32 -> U32 -> U32}
  U32.to_nat((h(3, 4) + k(1, 2) : U32))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|28n
