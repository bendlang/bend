# 3x3 matrix multiply over flat word arrays: dot-product loops threading
# TWO linear arrays through nested tuples; digest weighs all 9 cells
# ported from bend3: the 16-slot slabs become [0 : U32*16n] + swap
# writes, loop counters become Nat with U32 images via U32.from_nat;
# strict -- the read defs folded into the counter matches, shared
# words +U32, walked Nats +Nat
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

law dot:
  for k   : Nat
  for +i  : U32
  for +j  : U32
  for wa  : Array<U32> & U32
  for wb  : Array<U32> & U32
  for acc : U32
  (Array<U32> & (Array<U32> & U32))

def dot(k, i, j, wa, wb, acc):
  match k:
    case 0n:
      (a2, x) = wa
      (b2, y) = wb
      (a2, (b2, acc))
    case 1n+t0:
      (a2, x) = wa
      (b2, y) = wb
      +t = {t0 : Nat}
      +tn = {U32.from_nat(Nat.sub(t, 1n)) : U32}
      dot(t, i, j, Array.get(U32, a2, U32.add(U32.mul(i, 3), tn)),
        Array.get(U32, b2, U32.add(U32.mul(tn, 3), j)),
        U32.add(acc, U32.mul(x, y)))

law cells:
  for c   : Nat
  for wd  : (Array<U32> & (Array<U32> & U32))
  for acc : U32
  U32

def cells(c, wd, acc):
  match c:
    case 0n:
      (a2, (b2, v)) = wd
      acc
    case 1n+t0:
      (a2, (b2, v)) = wd
      +t = {t0 : Nat}
      +tt = {U32.from_nat(t) : U32}
      +tn = {U32.from_nat(Nat.sub(t, 1n)) : U32}
      +i = {U32.div(tn, 3) : U32}
      +j = {U32.mod(tn, 3) : U32}
      cells(t, dot(3n, i, j, Array.get(U32, a2, U32.add(U32.mul(i, 3), 2)),
        Array.get(U32, b2, U32.add(6, j)), 0),
        U32.add(acc, U32.mul(v, U32.add(tt, 1))))

law builda:
  Array<U32>

def builda():
  wr(wr(wr(wr(wr(wr(wr(wr(wr([0 : U32*16n], 0, 1), 1, 2), 2, 3), 3, 4), 4, 5), 5, 6), 6, 7), 7, 8), 8, 9)

law buildb:
  Array<U32>

def buildb():
  wr(wr(wr(wr(wr(wr(wr(wr(wr([0 : U32*16n], 0, 9), 1, 8), 2, 7), 3, 6), 4, 5), 5, 4), 6, 3), 7, 2), 8, 1)

law main.out:
  U32

def main.out():
  cells(9n, dot(3n, 2, 2, Array.get(U32, builda(), 8), Array.get(U32, buildb(), 8), 0), 0)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|3825
