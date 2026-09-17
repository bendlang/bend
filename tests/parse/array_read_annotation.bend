# an array read is an ordinary term: it takes an ascription like any
# other (bend3 pinned annotation placement on its slab reads)
import Base

law main.out:
  U32

law main.rd:
  for r: Array<U32> & U32
  U32

def main.rd(r):
  (a2, x) = r
  x

def main.out():
  main.rd({[4 : U32*2n][0] : Array<U32> & U32})

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|4
