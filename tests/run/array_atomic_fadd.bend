# the same tree over an Array<F32>: sixteen threads share one buffer of
# 256 cells under a bang, each stores (i + 1) + j / 4 into its own cells
# j = 2..15 of slice i, and every thread fadds (i + 1) / 2 into cell 0.
# Every value is a quarter under 2^24, so the sums are exact whatever the
# order: cell 0 holds 68, one more fadd of 0.25 returns that 68, and the
# cells then fold to 68.25 + 14 * 136 + 16 * 119 / 4 = 2448.25
import Base

@unsafe
def fill(+i: U32, +n: Nat, buf: Array<F32>) -> Array<F32>:
  match n:
    case 0n:
      buf
    case 1n+p:
      +j = U32.add(U32.from_nat(p), 2)
      fill(i, p, Array.set(F32, buf, U32.add(U32.mul(i, 16), j),
        F32.add(U32.to_f32(U32.add(i, 1)), F32.div(U32.to_f32(j), 4.0))))

@unsafe
def kernel(+i: U32, buf: Array<F32>) -> Array<F32>:
  Array.set.fin(F32, Array.atomic.fadd(fill(i, 14n, buf), 0,
    F32.div(U32.to_f32(U32.add(i, 1)), 2.0)))

@unsafe
def launch(+d: Nat, +i: U32, +buf: Array<F32>) -> Array<F32>:
  match d:
    case 0n:
      kernel(i, buf)
    case 1n+p:
      +k = U32.mul(i, 2)
      l r = launch(p, k, buf) launch(p, U32.add(k, 1), buf)
      Array.join(F32, l, r)

law fold:
  for  b: Array<F32>
  for +n: Nat
  for +s: F32
  F32

@unsafe
def fold.at(n: Nat, +s: F32, r: Array<F32> & F32) -> F32:
  (b, x) = r
  fold(b, n, F32.add(s, x))

def fold(b, n, s):
  match n:
    case 0n:
      s
    case 1n+p:
      fold.at(p, s, Array.get(F32, b, U32.from_nat(p)))

def s1(r: Array<F32> & F32) -> IO(Unit):
  (b, o) = r
  do IO<Unit>:
    Unit <- IO.print(F32.show(o))
    IO.print(F32.show(fold(b, 256n, 0.0)))

def main() -> IO(Unit):
  s1(Array.atomic.fadd(launch!(4n, 0, Array.new(F32, 8n, 0.0)), 0, 0.25))

#|68
#|2448.25
