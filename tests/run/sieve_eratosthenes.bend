# sieve of Eratosthenes over a word array: mark multiples in place,
# count survivors -- 11 primes at or below 31
# ported from bend3: the 32-slot slab becomes [0 : U32*32n], fuel
# and walk counters become Nat, U32 dispatches nested Bool matches
# (j >= 2 is spelled U32.is_le(2, j): tocl lacks u32_is_ge, see
# run_word_compare's yellow); strict -- the continuation defs folded
# into the fuel matches, shared words +U32, walked Nats +Nat
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

law mark:
  for fuel  : Nat
  for +mult : U32
  for +step : U32
  for st    : Array<U32> & Bool
  Array<U32>

def mark(fuel, mult0, step0, st):
  match fuel:
    case 0n:
      (m, live) = st
      m
    case 1n+f:
      (m, live) = st
      match live:
        case False{}:
          m
        case True{}:
          +mult = {mult0 : U32}
          +step = {step0 : U32}
          mark(f, U32.add(mult, step), step,
            (wr(m, mult, 1), U32.is_lt(U32.add(mult, step), 32)))

law sieve.step:
  for +p : U32
  for m2 : Array<U32>
  for z  : Bool
  Array<U32>

def sieve.step(p, m2, z):
  match z:
    case True{}:
      +pp = {U32.mul(p, p) : U32}
      mark(16n, pp, p, (m2, U32.is_lt(pp, 32)))
    case False{}:
      m2

law sieve:
  for fuel : Nat
  for +p   : U32
  for w    : Array<U32> & U32
  Array<U32>

def sieve(fuel, p0, w):
  match fuel:
    case 0n:
      (m2, v) = w
      m2
    case 1n+f:
      (m2, v) = w
      +p = {p0 : U32}
      +q = {U32.add(p, 1) : U32}
      sieve(f, q, Array.get(U32, sieve.step(p, m2, U32.is_zero(v)), q))


law survivors:
  for i   : Nat
  for w   : Array<U32> & U32
  for acc : U32
  U32

law survivors.bit:
  for z: Bool
  U32

def survivors.bit(z):
  match z:
    case True{}:
      1
    case False{}:
      0

def survivors(i, w, acc):
  match i:
    case 0n:
      (m2, v) = w
      acc
    case 1n+p0:
      (m2, v) = w
      +p = {p0 : Nat}
      +j = {U32.from_nat(p) : U32}
      survivors(p, Array.get(U32, m2, U32.from_nat(Nat.sub(p, 1n))),
        U32.add(acc, survivors.bit(Bool.and(U32.is_le(2, j), U32.is_zero(v)))))

law main.out:
  U32

def main.out():
  survivors(32n, Array.get(U32, sieve(4n, 2, Array.get(U32, [0 : U32*32n], 2)), 31), 0)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|11
