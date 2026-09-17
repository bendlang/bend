# a capturing closure (partial application) passed into a matching def
# ported from bend3 (a + b -> U32.add)
import Base

type PairU is Data:
  MkPair{a: U32, b: U32}

law mkadd:
  U32 -> U32 -> U32

def mkadd():
  n => x => U32.add(x, n)

law fold:
  for p: PairU
  for f: U32 -> U32
  U32

def fold(p, f):
  match p:
    case MkPair{a, b}:
      f(U32.add(a, b))

law main.out:
  U32

def main.out():
  fold(MkPair{3, 4}, mkadd(10))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|17
