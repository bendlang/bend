# computed (with) matches at runtime: dispatch on a call's result, nested
# computed scrutinees, and a value column beside a pattern column
# ported from bend3: U32 comparisons become Bool matches, compared
# words +U32 binders
import Base

type Ord is Data:
  Lt{}
  Eq{}
  Gt{}

law cmp:
  for +a: U32
  for +b: U32
  Ord

law cmp.eq:
  for z: Bool
  Ord

def cmp.eq(z):
  match z:
    case True{}:
      Eq{}
    case False{}:
      Gt{}

law cmp.lt:
  for +a: U32
  for +b: U32
  for  z: Bool
  Ord

def cmp.lt(a, b, z):
  match z:
    case True{}:
      Lt{}
    case False{}:
      cmp.eq(U32.is_eq(a, b))

def cmp(a, b):
  cmp.lt(a, b, U32.is_lt(a, b))

law rank:
  for a: U32
  for b: U32
  U32

law rank.fin:
  for o: Ord
  U32

def rank.fin(o):
  match o:
    case Lt{}:
      1
    case Eq{}:
      2
    case Gt{}:
      3

def rank(a, b):
  rank.fin(cmp(a, b))

law main.out:
  U32

def main.out():
  U32.add(U32.add(U32.mul(rank(1, 5), 100), U32.mul(rank(4, 4), 10)), rank(9, 2))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|123
