# deep nesting traffic: a 4-deep right-nested tuple fully opened and
# rebuilt reversed; a record-of-records rebuilt with one deep field bumped
# ported from bend3: tuple destructures ride helper defs (a bend
# pattern-let wants a binder-consuming call on the right)
import Base

type Inner is Data:
  I2{x: U32, y: U32}

type Outer is Data:
  O3{a: Inner, b: Inner, n: U32}

law bump.at:
  for b: Inner
  for a: Inner
  for n: U32
  Outer

def bump.at(b, a, n):
  match b:
    case I2{bx, by}:
      O3{a, I2{bx, U32.add(by, 10)}, n}

law bump:
  for o: Outer
  Outer

def bump(o):
  match o:
    case O3{a, b, n}:
      bump.at(b, a, n)

law odig.b:
  for b  : Inner
  for ax : U32
  for ay : U32
  for n  : U32
  U32

def odig.b(b, ax, ay, n):
  match b:
    case I2{bx, by}:
      U32.add(U32.add(U32.add(U32.add(ax, U32.mul(ay, 10)), U32.mul(bx, 100)), U32.mul(by, 1000)), U32.mul(n, 10000))

law odig.a:
  for a: Inner
  for b: Inner
  for n: U32
  U32

def odig.a(a, b, n):
  match a:
    case I2{ax, ay}:
      odig.b(b, ax, ay, n)

law odig:
  for o: Outer
  U32

def odig(o):
  match o:
    case O3{a, b, n}:
      odig.a(a, b, n)

law flip:
  for t: (U32 & U32 & U32 & U32 & U32)
  (U32 & U32 & U32 & U32 & U32)

def flip(t):
  (a, b, c, d, e) = t
  (e, d, c, b, a)

law tdig:
  for t: (U32 & U32 & U32 & U32 & U32)
  U32

def tdig(t):
  (p, q, r, s, u) = t
  U32.add(U32.add(U32.add(U32.add(U32.mul(p, 10000), U32.mul(q, 1000)), U32.mul(r, 100)), U32.mul(s, 10)), u)

law main.out:
  U32

def main.out():
  tup = tdig(flip((1, (2, (3, (4, 5))))))
  rec = odig(bump(O3{I2{1, 2}, I2{3, 4}, 9}))
  U32.add(tup, rec)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|158642
