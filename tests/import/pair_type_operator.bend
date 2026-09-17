# A & B is core grammar (Pair via Sigma), gated on nothing but the
# name -- with Base it is Pair(A, B) (bend3 gated the bare & on
# `import Pair`)
import Base

law main.out:
  U32

law main.rd:
  for r: U32 & U32
  U32

def main.rd(r):
  (a, b) = r
  (a * 10 + b : U32)

def main.out():
  main.rd({(3, 4) : U32 & U32})

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|34
