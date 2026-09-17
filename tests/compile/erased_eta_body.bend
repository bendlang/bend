# eta-short body under an erased param: the alias def is a bare Ref at a
# forall type with an erased binder, and the spine must keep the erased
# position
# ported from bend3
import Base

law id:
  for -a: Type
  for  x: a
  a

def id(a, x):
  x

law same:
  @-a: Type -> @x: a -> a

def same():
  id

law main.out:
  U32

def main.out():
  same(U32, 21)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|21
