# Rand is a pure linear token: seeded once, next/range thread it and are
# fully deterministic on every executor
# ported from bend3: bend-base Rand (xorshift32, zero seed remapped to
# 2654435769) is inlined; the full-word mods keep this off the
# interpreter (unary Nat division there is astronomic); strict -- the
# mix chain rides annotated +U32 rebinds, the continuation defs fold
# into sequential destructures
import Base

type Rnd is Data:
  Rnd{state: U32}

law rnew.if:
  for +seed : U32
  for z     : Bool
  Rnd

def rnew.if(seed, z):
  match z:
    case True{}:
      Rnd{2654435769}
    case False{}:
      Rnd{seed}

law rnew:
  for +seed: U32
  Rnd

def rnew(seed):
  rnew.if(seed, U32.is_zero(seed))

law rnext:
  for r: Rnd
  (Rnd & U32)

def rnext(r):
  match r:
    case Rnd{+s0}:
      +a = U32.xor(s0, U32.shln(s0, 13n))
      +b = U32.xor(a, U32.shrn(a, 17n))
      +c = U32.xor(b, U32.shln(b, 5n))
      (Rnd{c}, c)

law rrange.go:
  for n  : U32
  for rx : Rnd & U32
  (Rnd & U32)

def rrange.go(n, rx):
  (r2, x) = rx
  (r2, U32.mod(x, n))

law rrange:
  for r: Rnd
  for n: U32
  (Rnd & U32)

def rrange(r, n):
  rrange.go(n, rnext(r))

law go.c:
  for a  : U32
  for b  : U32
  for rc : Rnd & U32
  U32

def go.c(a, b, rc):
  (r3, c) = rc
  U32.add(U32.add(U32.mul(U32.mod(a, 1000), 10000), U32.mul(U32.mod(b, 1000), 10)), c)

law go.b:
  for a  : U32
  for rb : Rnd & U32
  U32

def go.b(a, rb):
  (r2, b) = rb
  go.c(a, b, rrange(r2, 10))

law go.a:
  for ra: Rnd & U32
  U32

def go.a(ra):
  (r1, a) = ra
  go.b(a, rnext(r1))

law go:
  for r: Rnd
  U32

def go(r):
  go.a(rnext(r))

law main.out:
  U32

def main.out():
  go(rnew(42))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|4323489
