# the parallel let: x y z = u v w -- one Let binding three names to
# three values (no arity cap, bend3's dead-cap law carried). ported
# from bend3: the values are calls
import Base

law f:
  for n: U32
  U32

def f(n):
  (n * 3 : U32)

law main.out:
  U32

def main.out():
  a b c = f(1) f(2) f(3)
  (a + b + c : U32)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|18
