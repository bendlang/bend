# an all-word record used twice as constructor fields AND read after:
# every use of the words-held value must own its instance (a shared
# box double-frees), and a copy of words is the words. 16-instead-of
# -18 was the shared-box failure.
# ported from bend3: f32 literals rebuild via U32.to_f32 (bend has
# no float literal), the reused record takes a + binder, and the pair
# lands in a worker def's parameter (a computed destructure is a
# banned form); no interp lane (Base's F32 axioms are stuck there)
import Base

type V3 is Data:
  Vec{x: F32, y: F32, z: F32}

type Two is Data:
  Tw{a: V3, b: V3}

law vsum:
  for v: V3
  F32

def vsum(v):
  Vec{x, y, z} = v
  F32.add(F32.add(x, y), z)

law pair:
  for +p: V3
  Two

def pair(p):
  Tw{p, p}

law main.out:
  U32

law main.rd:
  for p: V3
  for t: Two
  U32

def main.rd(p, t):
  Tw{a, b} = t
  F32.to_u32(F32.add(F32.add(vsum(a), vsum(b)), vsum(p)))

def main.out():
  +p = {Vec{U32.to_f32(1), U32.to_f32(2), U32.to_f32(3)} : V3}
  main.rd(p, pair(p))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|18
