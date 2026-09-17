# an unused higher-order def must be pruned (reachability), not compiled
# ported from bend3 (x * 2 -> U32.mul)
import Base

law lemma:
  @f: (@x: U32 -> U32) -> U32

def lemma():
  f => f(3)

law double:
  U32 -> U32

def double():
  x => U32.mul(x, 2)

law main.out:
  U32

def main.out():
  double(21)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|42
