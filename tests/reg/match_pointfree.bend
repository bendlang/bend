# regression witness (29e9611): a point-free match arm applies its
# obligations -- shapes of that repair's silent miscompile (each once
# printed a closure word, exit 0): a bare match value at a hof mixing
# a literal and a point-free arm, a field AND a rest argument absorbed
# through eta layers, a point-free DEFAULT TAIL, and a match value
# (through the hof door: the applied bare match is a banned form now)
# whose point-free targets hold a surviving recursive call over a heap
# datatype.
import Base

type Pt is Data:
  Pl{v: U32}
  Pn{a: Pt, b: Pt}

law psum:
  for t: Pt
  U32

def psum(t):
  match t:
    case Pl{v}:
      v
    case Pn{a, b}:
      U32.add(psum(a), psum(b))

law pboth:
  for a: Pt
  for b: Pt
  U32

def pboth(a, b):
  U32.add(psum(a), psum(b))

law pleaf:
  for v: U32
  U32

def pleaf(v):
  v

law hof:
  for f: Nat -> Nat
  for x: Nat
  Nat

def hof(f, x):
  f(x)

law hof2:
  for f: Nat -> Nat -> Nat
  for x: Nat
  for y: Nat
  Nat

def hof2(f, x, y):
  f(x, y)

law pf_heap:
  for t: Pt
  U32

law hofp:
  for f: Pt -> U32
  for t: Pt
  U32

def hofp(f, t):
  f(t)

def pf_heap(t):
  hofp({\{Pl: pleaf; Pn: pboth} : Pt -> U32}, t)

law main.out:
  U32

def main.out():
  c = hof(\{Zero: 9n; Succ: Nat.double}, 4n)
  b = hof2(\{Zero: z => z; Succ: Nat.add}, 3n, 10n)
  e = hof(\{Zero: 1n; Nat.double}, 5n)
  d = pf_heap(Pn{Pn{Pl{1}, Pl{2}}, Pl{3}})
  U32.add(d, U32.from_nat(Nat.add(c, Nat.add(b, e))))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|34
