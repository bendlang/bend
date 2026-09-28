# a fork is two handles to one array: sixteen threads share one buffer of
# 256 cells under a bang, each stores (i + 1) * (j + 1) into its own cells
# j = 2..15 of slice i with Array.set, and every thread adds i + 1 to cell
# 0 and maxes i * 7 mod 13 into cell 1 through the atomics. The joined
# buffer then runs every other atomic once, each printing its exact old
# value (136 = 16 * 17 / 2, then 100, 100, 96, 99, 156, 42, 42, 7), reads
# cells 0 and 1 back (8 and 12), and folds every cell from 255 down to 0
# into s = s * 31 + x, which a plain script puts at 845495236
import Base

@unsafe
def fill(+i: U32, +n: Nat, buf: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      buf
    case 1n+p:
      +j = U32.add(U32.from_nat(p), 2)
      fill(i, p, Array.set(U32, buf, U32.add(U32.mul(i, 16), j),
        U32.mul(U32.add(i, 1), U32.add(j, 1))))

@unsafe
def kernel(+i: U32, buf: Array<U32>) -> Array<U32>:
  Array.set.fin(U32, Array.atomic.max(Array.set.fin(U32,
    Array.atomic.add(fill(i, 14n, buf), 0, U32.add(i, 1))), 1,
    U32.mod(U32.mul(i, 7), 13)))

@unsafe
def launch(+d: Nat, +i: U32, +buf: Array<U32>) -> Array<U32>:
  match d:
    case 0n:
      kernel(i, buf)
    case 1n+p:
      +k = U32.mul(i, 2)
      l r = launch(p, k, buf) launch(p, U32.add(k, 1), buf)
      Array.join(U32, l, r)

law fold:
  for  b: Array<U32>
  for +n: Nat
  for +s: U32
  U32

@unsafe
def fold.at(n: Nat, +s: U32, r: Array<U32> & U32) -> U32:
  (b, x) = r
  fold(b, n, U32.add(U32.mul(s, 31), x))

def fold(b, n, s):
  match n:
    case 0n:
      s
    case 1n+p:
      fold.at(p, s, Array.get(U32, b, U32.from_nat(p)))

def s11(r: Array<U32> & U32) -> IO(Unit):
  (b, x) = r
  do IO<Unit>:
    Unit <- IO.print(U32.show(x))
    IO.print(U32.show(fold(b, 256n, 0)))

def s10(r: Array<U32> & U32) -> IO(Unit):
  (b, x) = r
  do IO<Unit>:
    Unit <- IO.print(U32.show(x))
    s11(Array.get(U32, b, 1))

def s9(r: Array<U32> & U32) -> IO(Unit):
  (b, o) = r
  do IO<Unit>:
    Unit <- IO.print(U32.show(o))
    s10(Array.get(U32, b, 0))

def s8(r: Array<U32> & U32) -> IO(Unit):
  (b, o) = r
  do IO<Unit>:
    Unit <- IO.print(U32.show(o))
    s9(Array.atomic.add(b, 0, 1))

def s7(r: Array<U32> & U32) -> IO(Unit):
  (b, o) = r
  do IO<Unit>:
    Unit <- IO.print(U32.show(o))
    s8(Array.atomic.cas(b, 0, 42, 7))

def s6(r: Array<U32> & U32) -> IO(Unit):
  (b, o) = r
  do IO<Unit>:
    Unit <- IO.print(U32.show(o))
    s7(Array.atomic.cas(b, 0, 41, 7))

def s5(r: Array<U32> & U32) -> IO(Unit):
  (b, o) = r
  do IO<Unit>:
    Unit <- IO.print(U32.show(o))
    s6(Array.atomic.exch(b, 0, 42))

def s4(r: Array<U32> & U32) -> IO(Unit):
  (b, o) = r
  do IO<Unit>:
    Unit <- IO.print(U32.show(o))
    s5(Array.atomic.xor(b, 0, 255))

def s3(r: Array<U32> & U32) -> IO(Unit):
  (b, o) = r
  do IO<Unit>:
    Unit <- IO.print(U32.show(o))
    s4(Array.atomic.or(b, 0, 3))

def s2(r: Array<U32> & U32) -> IO(Unit):
  (b, o) = r
  do IO<Unit>:
    Unit <- IO.print(U32.show(o))
    s3(Array.atomic.and(b, 0, 96))

def s1(r: Array<U32> & U32) -> IO(Unit):
  (b, o) = r
  do IO<Unit>:
    Unit <- IO.print(U32.show(o))
    s2(Array.atomic.max(b, 0, 7))

def main() -> IO(Unit):
  s1(Array.atomic.min(launch!(4n, 0, Array.new(U32, 8n, 0)), 0, 100))

#|136
#|100
#|100
#|96
#|99
#|156
#|42
#|42
#|7
#|8
#|12
#|845495236
