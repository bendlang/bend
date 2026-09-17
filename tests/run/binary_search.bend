# binary search over a sorted array: O(1) reads drive a fuel-bounded
# halving loop; arrays are linear, so the search hands the array back
# (container FIRST, answer second) -- hits index, misses 99
# ported from bend3: the slab literal becomes Array.new + swap writes
# (8 = 2^3 slots), fuel becomes Nat; strict -- the continuation defs
# folded into the fuel match, shared words +U32 binders
import Base

law wr:
  for m: Array<U32>
  for i: U32
  for v: U32
  Array<U32>

law wr.fin:
  for w: Array<U32> & U32
  Array<U32>

def wr.fin(w):
  (m2, old) = w
  m2

def wr(m, i, v):
  wr.fin(Array.swap(U32, m, i, v))

law bstep.lt:
  for m2  : Array<U32>
  for lo  : U32
  for hi  : U32
  for mid : U32
  for d   : Bool
  Array<U32> & U32 & U32 & U32

def bstep.lt(m2, lo, hi, mid, d):
  match d:
    case True{}:
      (m2, 99, U32.add(mid, 1), hi)
    case False{}:
      (m2, 99, lo, mid)

law bstep.eq:
  for +x  : U32
  for m2  : Array<U32>
  for lo  : U32
  for +hi : U32
  for mid : U32
  for +v  : U32
  for e   : Bool
  Array<U32> & U32 & U32 & U32

def bstep.eq(x, m2, lo, hi, mid, v, e):
  match e:
    case True{}:
      (m2, mid, hi, hi)
    case False{}:
      bstep.lt(m2, lo, hi, mid, U32.is_lt(v, x))

law bstep.read:
  for +x   : U32
  for lo   : U32
  for +hi  : U32
  for +mid : U32
  for w    : Array<U32> & U32
  Array<U32> & U32 & U32 & U32

def bstep.read(x, lo, hi, mid, w):
  (m2, v0) = w
  +v = {v0 : U32}
  bstep.eq(x, m2, lo, hi, mid, v, U32.is_eq(v, x))

law bstep.live:
  for +x  : U32
  for m   : Array<U32>
  for res : U32
  for +lo : U32
  for +hi : U32
  for go  : Bool
  Array<U32> & U32 & U32 & U32

def bstep.live(x, m, res, lo, hi, go):
  match go:
    case False{}:
      (m, res, lo, hi)
    case True{}:
      +mid = {U32.div(U32.add(lo, hi), 2) : U32}
      bstep.read(x, lo, hi, mid, Array.get(U32, m, mid))

law bstep:
  for +x : U32
  for st : Array<U32> & U32 & U32 & U32
  Array<U32> & U32 & U32 & U32

def bstep(x, st):
  (m, res, lo0, hi0) = st
  +lo = {lo0 : U32}
  +hi = {hi0 : U32}
  bstep.live(x, m, res, lo, hi, U32.is_lt(lo, hi))

law bsearch:
  for fuel : Nat
  for +x   : U32
  for st   : Array<U32> & U32 & U32 & U32
  (Array<U32> & U32)

def bsearch(fuel, x, st):
  match fuel:
    case 0n:
      (m, res, lo, hi) = st
      (m, res)
    case 1n+f:
      bsearch(f, x, bstep(x, st))

law build:
  Array<U32>

def build():
  wr(wr(wr(wr(wr(wr(wr(wr([0 : U32*8n], 0, 1), 1, 3), 2, 4), 3, 5), 4, 9), 5, 12), 6, 20), 7, 31)

law bs:
  for  m: Array<U32>
  for +x: U32
  Array<U32> & U32

def bs(m, x):
  bsearch(5n, x, (m, 99, 0, 8))

law go.d:
  for acc : U32
  for w   : Array<U32> & U32
  U32

def go.d(acc, w):
  (m4, d) = w
  U32.add(acc, d)

law go.c:
  for acc : U32
  for w   : Array<U32> & U32
  U32

def go.c(acc, w):
  (m3, c) = w
  go.d(U32.add(acc, U32.mul(c, 10)), bs(m3, 2))

law go.b:
  for acc : U32
  for w   : Array<U32> & U32
  U32

def go.b(acc, w):
  (m2, b) = w
  go.c(U32.add(acc, U32.mul(b, 100)), bs(m2, 31))

law go.a:
  for w: Array<U32> & U32
  U32

def go.a(w):
  (m1, a) = w
  go.b(U32.mul(a, 1000), bs(m1, 1))

law go:
  for m: Array<U32>
  U32

def go(m):
  go.a(bs(m, 9))

law main.out:
  U32

def main.out():
  go(build())

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|4169
