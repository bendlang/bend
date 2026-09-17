# bend3's comp_loops demotion-verdict/flip agreement pin (an 18-arg
# split aux fused as a join member); bend's tocl has no verdict
# machinery, so the shape itself carries -- the wide F32 state record,
# the record-returning helper and the countdown loop answer the same
# 536 on the compiled lanes (floats are interp axioms; contraction
# rides + binders)
import Base

type S9 is Data:
  S9{a: F32, b: F32, c: F32, d: F32, e: F32, f: F32, g: F32, h: F32, i: F32, j: F32, k: F32, l: F32, m: F32, n: F32, o: F32, p: F32}

type Q9 is Data:
  Q9{u: F32, v: F32}

law spin.go:
  for  t: Nat
  for +x: F32
  for  f: Bool
  F32

def spin.go(t, x, f):
  match t:
    case Zero{}:
      x
    case Succ{k}:
      match f:
        case True{}:
          +x2 = (x - 10.0 : F32);
          spin.go(k, x2, F32.is_ge(x2, 10.0))
        case False{}:
          x

law spin:
  for  t: Nat
  for +x: F32
  F32

def spin(t, x):
  spin.go(t, x, F32.is_ge(x, 10.0))

law mix:
  for +x: F32
  for +y: F32
  Q9

def mix(x, y):
  Q9{(x + y : F32), (x - y : F32)}

law step.fin:
  for  a: F32
  for  b: F32
  for +c: F32
  for  d: F32
  for  e: F32
  for  f: F32
  for  g: F32
  for  h: F32
  for  i: F32
  for  j: F32
  for  k: F32
  for  l: F32
  for  m: F32
  for  n: F32
  for  o: F32
  for  p: F32
  for  q: Q9
  S9

def step.fin(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q):
  Q9{u, v} = q
  x = (a * 2.0 : F32)
  y = (b * 2.0 : F32)
  z = (c * 2.0 : F32)
  S9{(u + x : F32), (v + y : F32), spin(4n, ((c + z) * 4.0 : F32)), d, e, f, g, h, i, j, k, l, m, n, o, p}

law step:
  for +w: S9
  S9

def step(w):
  S9{a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p} = w
  step.fin(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, mix(a, b))

law main.go:
  for r: S9
  U32

def main.go(r):
  S9{a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p} = r
  F32.to_u32((a * 100.0 + b * 10.0 + c : F32))

law main.out:
  U32

def main.out():
  main.go(step(S9{1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0}))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|536
