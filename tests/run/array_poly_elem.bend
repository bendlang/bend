# the widened element: Array.get and Array.new take any Data element
# with an explicit T; word enums (Bool, Cmp, a user's nullary Dir) ride
# the flat word layout, F32 rides its bits, and the a[i] sugar stays
# the U32 spelling
import Base

type Dir is Data:
  N{}
  E{}
  S{}
  W{}

law d2u:
  for d: Dir
  U32

def d2u(d):
  match d:
    case N{}:
      0
    case E{}:
      1
    case S{}:
      2
    case W{}:
      3

law b2u:
  for b: Bool
  U32

def b2u(b):
  match b:
    case False{}:
      0
    case True{}:
      1

law c2u:
  for c: Cmp
  U32

def c2u(c):
  match c:
    case LT{}:
      0
    case EQ{}:
      1
    case GT{}:
      2

law rdb:
  for r: Array<Bool> & Bool
  U32

def rdb(r):
  (a2, v) = r
  b2u(v)

law rdd:
  for r: Array<Dir> & Dir
  U32

def rdd(r):
  (a2, v) = r
  d2u(v)

law rdc:
  for r: Array<Cmp> & Cmp
  U32

def rdc(r):
  (a2, v) = r
  c2u(v)

law rdf:
  for r: Array<F32> & F32
  U32

def rdf(r):
  (a2, v) = r
  F32.to_u32(v)

law swc:
  for r: Array<Cmp> & Cmp
  U32

def swc(r):
  (a2, old) = r
  U32.add(U32.mul(c2u(old), 10), rdc(Array.get(Cmp, a2, 0)))

law main.out:
  U32

def main.out():
  b1 = rdb(Array.get(Bool, Array.set(Bool, [False{} : Bool*4n], 1, True{}), 1))
  b0 = rdb(Array.get(Bool, [False{} : Bool*2n], 0))
  dd = rdd(Array.get(Dir, Array.set(Dir, [N{} : Dir*4n], 2, S{}), 2))
  sw = swc(Array.swap(Cmp, [EQ{} : Cmp*2n], 0, GT{}))
  ff = rdf(Array.get(F32, [F32.div(U32.to_f32(5), U32.to_f32(2)) : F32*2n], 1))
  U32.add(U32.mul(U32.add(U32.mul(U32.add(U32.mul(U32.add(U32.mul(b1, 10), b0), 10), dd), 100), sw), 10), ff)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|102122
