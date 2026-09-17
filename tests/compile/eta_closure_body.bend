# eta-short closure body: a def that returns its function arg bare
# ported from bend3 (x * 2 -> U32.mul)
import Base

law double:
  U32 -> U32

def double():
  x => U32.mul(x, 2)

law twice:
  (U32 -> U32) -> U32 -> U32

def twice():
  f => x => f(x)

law comp:
  (U32 -> U32) -> U32 -> U32

def comp():
  f => f

law main.out:
  U32

def main.out():
  U32.add(twice(double, 10), comp(double, 11))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|42
