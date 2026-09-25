# F64 is IEEE 754 binary64 with one NaN: every lane prints the same
# shortest text and bits for sums, products, quotients, square roots and fma
# (one rounding: 0.1 * 10 - 1 is 5.55e-17 fused and 0 unfused), subnormals,
# signed zeros and infinities; a NaN result is 0x7FF8000000000000 while neg
# and abs keep a payload; a comparison with a NaN is false but is_ne; the
# conversions answer 0 for NaN, negatives and overflow; the #| lines are
# Python's binary64
import Base

def f(x: F64) -> String:
  F64.show(x)

def u(x: U64) -> String:
  U64.show(x)

def mr(m: Maybe<&2, F64>) -> String:
  match m:
    case None{}:
      "None"
    case Some{v}:
      F64.show(v)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(f(F64.add(0.1f64, 0.2f64)))
    Unit <- IO.print(f(F64.sub(1.0f64, 0.9f64)))
    Unit <- IO.print(f(F64.mul(3.0f64, 7.0f64)))
    Unit <- IO.print(f(F64.mul(1.0e308f64, 10.0f64)))
    Unit <- IO.print(f(F64.div(1.0f64, 3.0f64)))
    Unit <- IO.print(f(F64.div(1.0f64, 0.0f64)))
    Unit <- IO.print(f(F64.div(F64.neg(1.0f64), 0.0f64)))
    Unit <- IO.print(f(F64.div(0.0f64, 0.0f64)))
    Unit <- IO.print(f(F64.sqrt(2.0f64)))
    Unit <- IO.print(f(F64.sqrt(F64.neg(1.0f64))))
    Unit <- IO.print(f(F64.sqrt(F64.neg(0.0f64))))
    Unit <- IO.print(f(F64.fma(0.1f64, 10.0f64, F64.neg(1.0f64))))
    Unit <- IO.print(f(F64.add(F64.mul(0.1f64, 10.0f64), F64.neg(1.0f64))))
    Unit <- IO.print(f(F64{1u64}))
    Unit <- IO.print(f(F64{4503599627370496u64}))
    Unit <- IO.print(f(F64{9218868437227405311u64}))
    Unit <- IO.print(f(F64.div(F64{1u64}, 2.0f64)))
    Unit <- IO.print(f(F64.mul(F64{4503599627370496u64}, 0.5f64)))
    Unit <- IO.print(f(F64.neg(0.0f64)))
    Unit <- IO.print(f(F64.abs(F64.neg(2.5f64))))
    Unit <- IO.print(f(1.0e21f64))
    Unit <- IO.print(f(123456789012345680000.0f64))
    Unit <- IO.print(f(0.000001f64))
    Unit <- IO.print(f(0.0000001f64))
    Unit <- IO.print(f(5f64))
    Unit <- IO.print(f(U64.to_f64(18446744073709551615u64)))
    Unit <- IO.print(f(U64.to_f64(9007199254740993u64)))
    Unit <- IO.print(f(U32.to_f64(4294967295)))
    Unit <- IO.print(f(F32.to_f64(0.1)))
    Unit <- IO.print(f(F64.min(F64.nan(), 1.0f64)))
    Unit <- IO.print(f(F64.min(1.0f64, F64.nan())))
    Unit <- IO.print(f(F64.max(F64.neg(0.0f64), 0.0f64)))
    Unit <- IO.print(u(F64.bits(F64.div(0.0f64, 0.0f64))))
    Unit <- IO.print(u(F64.bits(F64.add(F64{9221120237041090851u64}, 1.0f64))))
    Unit <- IO.print(u(F64.bits(F64.neg(F64{9221120237041090851u64}))))
    Unit <- IO.print(u(F64.bits(F64.abs(F64{18443366373989023744u64}))))
    Unit <- IO.print(u(F64.bits(F64{18443366373989023744u64})))
    Unit <- IO.print(u(F64.bits(F64.neg(0.0f64))))
    Unit <- IO.print(Bool.show(F64.is_eq(0.0f64, F64.neg(0.0f64))))
    Unit <- IO.print(Bool.show(F64.is_lt(F64.neg(0.0f64), 0.0f64)))
    Unit <- IO.print(Bool.show(F64.is_eq(F64.nan(), F64.nan())))
    Unit <- IO.print(Bool.show(F64.is_ne(F64.nan(), F64.nan())))
    Unit <- IO.print(Bool.show(F64.is_lt(F64.nan(), 1.0f64)))
    Unit <- IO.print(Bool.show(F64.is_ge(F64.nan(), 1.0f64)))
    Unit <- IO.print(Bool.show(F64.is_le(1.0f64, 1.0f64)))
    Unit <- IO.print(Bool.show(F64.is_gt(F64{1u64}, 0.0f64)))
    Unit <- IO.print(Bool.show(F64.is_nan(F64{9218868437227405313u64})))
    Unit <- IO.print(Bool.show(F64.is_nan(F64{9218868437227405312u64})))
    Unit <- IO.print(u(F64.to_u64(1.0e19f64)))
    Unit <- IO.print(u(F64.to_u64(F64.neg(1.0f64))))
    Unit <- IO.print(u(F64.to_u64(18446744073709551616.0f64)))
    Unit <- IO.print(u(F64.to_u64(18446744073709549568.0f64)))
    Unit <- IO.print(u(F64.to_u64(F64.nan())))
    Unit <- IO.print(u(F64.to_u64(2.75f64)))
    Unit <- IO.print(u(U32.to_u64(F64.to_u32(4294967295.9f64))))
    Unit <- IO.print(u(U32.to_u64(F64.to_u32(4294967296.0f64))))
    Unit <- IO.print(u(U32.to_u64(F32.bits(F64.to_f32(0.1f64)))))
    Unit <- IO.print(u(U32.to_u64(F32.bits(F64.to_f32(1.0e39f64)))))
    Unit <- IO.print(u(U32.to_u64(F32.bits(F64.to_f32(F64.nan())))))
    Unit <- IO.print(mr(F64.read("0.1")))
    Unit <- IO.print(mr(F64.read("1e400")))
    Unit <- IO.print(mr(F64.read("-2.5e-3")))
    Unit <- IO.print(mr(F64.read("abc")))
    Unit <- IO.print(mr(F64.read("")))
    Unit <- IO.print(mr(F64.read("inf")))
    IO.print(f(F64.nan()))

#|0.30000000000000004
#|0.09999999999999998
#|21
#|inf
#|0.3333333333333333
#|inf
#|-inf
#|nan
#|1.4142135623730951
#|nan
#|-0
#|5.551115123125783e-17
#|0
#|5e-324
#|2.2250738585072014e-308
#|1.7976931348623157e+308
#|0
#|1.1125369292536007e-308
#|-0
#|2.5
#|1e+21
#|123456789012345680000
#|0.000001
#|1e-7
#|5
#|18446744073709552000
#|9007199254740992
#|4294967295
#|0.10000000149011612
#|1
#|nan
#|-0
#|9221120237041090560
#|9221120237041090560
#|18444492273895866659
#|9219994337134247936
#|18443366373989023744
#|9223372036854775808
#|True
#|False
#|False
#|True
#|False
#|False
#|True
#|True
#|True
#|False
#|10000000000000000000
#|0
#|0
#|18446744073709549568
#|0
#|2
#|4294967295
#|0
#|1036831949
#|2139095040
#|2143289344
#|0.1
#|inf
#|-0.0025
#|None
#|None
#|inf
#|nan
