# the second ordinary program: floats and an Array<F32> beside Map,
# Set, number-text and a KEPT tuple binder, all in ONE book - crossing
# the whole-book representation seams (shared Tup, F32 array cells)
# where the merged-book defects lived (reg_share_tuple_global, the
# map_set_ops shard divergence); no interp lane (F32 axioms stuck there)
import Base

law b2u:
  for b: Bool
  U32

def b2u(b):
  match b:
    case False{}:
      0
    case True{}:
      1

law P2:
  Data

def P2(): Sigma<&2, &2, U32, _ => U32>

law pa:
  for q: P2()
  U32

def pa(q):
  (a, b) = q
  a

law pb:
  for q: P2()
  U32

def pb(q):
  (a, b) = q
  b

law keep2:
  for +p: P2()
  U32

def keep2(p):
  (pa(p) + pb(p) : U32)

law rdu:
  for s: String
  U32

law rdu.fin:
  for o: Maybe<&2, U32>
  U32

def rdu.fin(o):
  match o:
    case Some{v}:
      v
    case None{}:
      999

def rdu(s):
  rdu.fin(U32.read(s))

law rdn:
  for s: String
  Nat

law rdn.fin:
  for o: Maybe<&2, Nat>
  Nat

def rdn.fin(o):
  match o:
    case Some{v}:
      v
    case None{}:
      0n

def rdn(s):
  rdn.fin(Nat.read(s))

law fpart:
  U32

law fpart.b:
  for v0 : F32
  for w  : Array<F32> & F32
  U32

def fpart.b(v0, w):
  (m3, v1) = w
  F32.to_u32(((v0 + v1) * (6.25 - 2.25) : F32))

law fpart.a:
  for w: Array<F32> & F32
  U32

def fpart.a(w):
  (m2, v0) = w
  fpart.b(v0, Array.swap(F32, m2, 1, 0.25))

def fpart():
  fpart.a(Array.swap(F32, {ANode{ALeaf{0.5}, ALeaf{1.5}} : Array<F32>}, 0, 2.0))

law main.out:
  U32

law main.b:
  for c0 : U32
  for w  : Map<&2, U32> & U32
  U32

def main.b(c0, w):
  (m2, v) = w
  c1 = b2u(U32.is_eq(v, 70))
  c2 = b2u(U32.is_eq((rdu("29") + U32.from_nat(rdn("13")) : U32), 42))
  c3 = b2u(U32.is_eq(keep2((3, 4)), 7))
  (fpart() * 10000 + c0 * 1000 + c1 * 100 + c2 * 10 + c3 : U32)

law main.a:
  for w: Set() & Bool
  U32

def main.a(w):
  (s2, h12) = w
  main.b(b2u(h12), Map.get(U32, 0,
    Map.set(&2, U32, Map.new(&2, U32), "k" ++ U32.show(7), 70), "k7"))

def main.out():
  main.a(Set.has(Set.add(Set.add(Set.new(), U32.show(12)), Nat.show(3n)), "12"))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|81111
