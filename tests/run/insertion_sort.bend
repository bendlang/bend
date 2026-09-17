# a handwritten insertion sort (structural recursion, own list ADT):
# a wildly different shape from the Base radix sort, same order
# ported from bend3: if/else becomes a Bool match, compared heads
# + binders; strict -- the dispatch helper folded into insert's own
# case tree, compared words +U32 binders
import Base

type L is Data:
  C{h: U32, t: L}
  N{}

law ins.rev:
  for pre: L
  for rem: L
  L

def ins.rev(pre, rem):
  match pre:
    case N{}:
      rem
    case C{h, t}:
      ins.rev(t, C{h, rem})

law ins.le:
  for +x  : U32
  for +h  : U32
  for pre : L
  for t   : L
  for z   : Bool
  L & L & Bool

def ins.le(x, h, pre, t, z):
  match z:
    case True{}:
      (C{x, pre}, C{h, t}, False{})
    case False{}:
      (C{h, pre}, t, True{})

law ins.step:
  for +x : U32
  for st : L & L & Bool
  L & L & Bool

def ins.step(x, st):
  match st:
    case (pre, N{}, True{}):
      (C{x, pre}, N{}, False{})
    case (pre, C{h0, t}, True{}):
      +h = {h0 : U32}
      ins.le(x, h, pre, t, U32.is_le(x, h))
    case (pre, rem, False{}):
      (pre, rem, False{})

law ins.go:
  for fuel : Nat
  for +x   : U32
  for st   : L & L & Bool
  L & L & Bool

def ins.go(fuel, x, st):
  match fuel:
    case 0n:
      st
    case 1n+f:
      ins.go(f, x, ins.step(x, st))

law insert.fin:
  for st: L & L & Bool
  L

def insert.fin(st):
  match st:
    case (pre, rem, live):
      ins.rev(pre, rem)

law insert:
  for +x : U32
  for xs : L
  L

def insert(x, xs):
  insert.fin(ins.go(8n, x, (N{}, xs, True{})))

law isort:
  for xs: L
  L

def isort(xs):
  match xs:
    case N{}:
      N{}
    case C{h, t}:
      insert(h, isort(t))

law digest:
  for xs: L
  U32

def digest(xs):
  match xs:
    case N{}:
      0
    case C{h, t}:
      U32.add(h, U32.mul(10, digest(t)))

law main.out:
  U32

def main.out():
  xs = {C{5, C{3, C{9, C{1, C{4, C{2, N{}}}}}}} : L}
  digest(isort(xs))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|954321
