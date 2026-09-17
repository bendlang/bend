# the binderless set: a[i] <- v is a TERM answering the written array,
# so bend3's wildcard statement form is just an expression feeding the
# next read -- the displaced element is dropped by Array.set
import Base

law main.b:
  for x: U32
  for r: Array<U32> & U32
  U32

def main.b(x, r):
  (a3, y) = r
  (x * 10 + y : U32)

law main.a:
  for r: Array<U32> & U32
  U32

def main.a(r):
  (a2, x) = r
  main.b(x, a2[1])

law main.out:
  U32

def main.out():
  main.a((([0 : U32*4n][0] <- 3)[1] <- 4)[0])

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|34
