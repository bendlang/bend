# read-modify-write loops over a word array: fill 8 slots with squares,
# then fold them back; F32 arrays store exact f32 cells
# ported from bend3: the slab becomes [0 : U32*8n], counters Nat;
# f32 literals are rebuilt exactly via F32.div of small integers, so
# there is no interpreter lane (Base's F32 axioms are stuck there);
# strict -- the index defs folded in, walked Nats +Nat, indexes +U32
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

law fl:
  for n: U32
  for d: U32
  F32

def fl(n, d):
  F32.div(U32.to_f32(n), U32.to_f32(d))

law fill:
  for i: Nat
  for m: Array<U32>
  Array<U32>

def fill(i, m):
  match i:
    case 0n:
      m
    case 1n+p0:
      +p = {p0 : Nat}
      +j = {U32.from_nat(p) : U32}
      fill(p, wr(m, j, U32.mul(j, j)))

law total:
  for i   : Nat
  for w   : Array<U32> & U32
  for acc : U32
  U32

def total(i, w, acc):
  match i:
    case 0n:
      (m2, v) = w
      U32.add(acc, v)
    case 1n+p0:
      (m2, v) = w
      +p = {p0 : Nat}
      total(p, Array.get(U32, m2, U32.from_nat(p)), U32.add(acc, v))

law fsum:
  U32

def fsum():
  F32.to_u32(F32.mul(F32.add(fl(3, 2), fl(9, 4)), fl(100, 1)))

law main.out:
  U32

def main.out():
  U32.add(U32.mul(total(8n, (fill(8n, [0 : U32*8n]), 0), 0), 1000), fsum())

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|140375
