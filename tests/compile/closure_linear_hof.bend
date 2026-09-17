# a HOF taking a linear closure
# ported from bend3 (a + b -> U32.add)
import Base

law run:
  (U32 -> U32) -> U32 -> U32

def run():
  f => x => f(x)

law plus:
  U32 -> U32 -> U32

def plus():
  a => b => U32.add(a, b)

law main.out:
  U32

def main.out():
  run(plus(40), 2)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|42
