# CONFLUENCE of copies under real threads: ONE list over-used by four
# fork siblings at once, each folding with a different salt -- the
# checksum is identical in the interpreter, at one thread and at eight
# (verified against an independent host-JS mirror: 2827519320).
# ported from bend3: the builder takes Nat fuel with a + U32 mirror,
# forks spell the parallel let, the shared list and reused
# words take + binders (L declares Data, so it duplicates freely),
# operators spell U32.xor/mul/add
import Base

type L is Data:
  LC{h: U32, t: L}
  LN{}

law mk:
  for  n: Nat
  for +m: U32
  L

def mk(n, m):
  match n:
    case 0n:
      LN{}
    case 1n+p:
      LC{U32.mul(m, 2654435761), mk(p, U32.sub(m, 1))}

law fold:
  for xs   : L
  for salt : U32
  U32

def fold(xs, salt):
  match xs:
    case LN{}:
      salt
    case LC{h, t}:
      fold(t, U32.add(U32.mul(U32.xor(salt, h), 31), 7))

law burst:
  for +xs: L
  U32

def burst(xs):
  a b c d = fold(xs, 1) fold(xs, 2) fold(xs, 3) fold(xs, 4)
  U32.add(U32.add(U32.add(a, U32.mul(b, 3)), U32.mul(c, 7)), U32.mul(d, 11))

law main.out:
  U32

def main.out():
  xs = mk(24n, 24)
  burst(xs)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|2827519320
