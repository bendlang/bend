# F32 + - * / are exact IEEE f32 on every executor: 0.1+0.2 EQUALS 0.3
# in f32 (both round to 0x3E99999A), precision loss at 2^24, exact
# casts. the fl helper predates exact literals and still holds: each
# division is the correctly rounded f32. equality is spelled through
# F32.is_lt both ways; no interpreter lane (F32 axioms are stuck)
import Base

law bu:
  for b: Bool
  U32

def bu(b):
  match b:
    case False{}:
      0
    case True{}:
      1

law fl:
  for n: U32
  for d: U32
  F32

def fl(n, d):
  F32.div(U32.to_f32(n), U32.to_f32(d))

law feq:
  for +a: F32
  for +b: F32
  Bool

def feq(a, b):
  Bool.and(Bool.not(F32.is_lt(a, b)), Bool.not(F32.is_lt(b, a)))

law main.out:
  U32

def main.out():
  b0 = bu(feq(F32.add(fl(1, 10), fl(2, 10)), fl(3, 10)))
  b1 = bu(U32.is_eq(F32.to_u32(F32.mul(F32.add(fl(1, 10), fl(2, 10)), fl(1000000, 1))), 300000))
  b2 = bu(feq(F32.add(fl(16777216, 1), fl(1, 1)), fl(16777216, 1)))
  b3 = bu(feq(U32.to_f32(16777217), fl(16777216, 1)))
  b4 = bu(U32.is_eq(F32.to_u32(fl(39, 10)), 3))
  b5 = bu(feq(F32.div(fl(10, 1), fl(4, 1)), fl(5, 2)))
  b6 = bu(feq(F32.mul(fl(2, 1), fl(3, 2)), fl(3, 1)))
  b7 = bu(U32.is_eq(F32.to_u32(U32.to_f32(123456)), 123456))
  U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(b0, b1), b2), b3), b4), b5), b6), b7)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|8
