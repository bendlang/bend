# forks nest: a fork binding's body may fork again, and a fork value
# may itself be a call whose argument forked -- ported from bend3's
# second arity shape
import Base

law w:
  for n: U32
  U32

def w(n):
  (n + 1 : U32)

law inner:
  for x: U32
  U32

def inner(x):
  p q = w(x) w(10)
  (p + q : U32)

law main.out:
  U32

def main.out():
  a b = inner(1) inner(2)
  (a * 100 + b : U32)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|1314
