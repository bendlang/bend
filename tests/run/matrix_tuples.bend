# tuples as data: 2x2 matrices of words as nested pairs, multiplied and
# squared; ((1,1),(1,0))^4 carries fib in its cells
# ported from bend3: cell reuse rides annotated + rebinding;
# destructures happen in helper defs; strict -- the squared matrix
# is a reusable (&2) nested Sigma pair held by a + binder
import Base

law P2:
  Data

def P2(): Sigma<&2, &2, U32, _ => U32>

law M2:
  Data

def M2(): Sigma<&2, &2, P2(), _ => P2()>

law mmul:
  for m: M2()
  for n: M2()
  M2()

def mmul(m, n):
  ((a0, b0), (c0, d0)) = m
  ((e0, f0), (g0, h0)) = n
  +a = {a0 : U32}
  +b = {b0 : U32}
  +c = {c0 : U32}
  +d = {d0 : U32}
  +e = {e0 : U32}
  +f = {f0 : U32}
  +g = {g0 : U32}
  +h = {h0 : U32}
  ((U32.add(U32.mul(a, e), U32.mul(b, g)), U32.add(U32.mul(a, f), U32.mul(b, h))), (U32.add(U32.mul(c, e), U32.mul(d, g)), U32.add(U32.mul(c, f), U32.mul(d, h))))

law sq:
  for +m: M2()
  M2()

def sq(m):
  mmul(m, m)

law dig:
  for m4: M2()
  U32

def dig(m4):
  ((a, b), (c, d)) = m4
  U32.add(U32.add(U32.add(U32.mul(a, 1000), U32.mul(b, 100)), U32.mul(c, 10)), d)

law main.out:
  U32

def main.out():
  dig(sq(sq(((1, 1), (1, 0)))))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|5332
