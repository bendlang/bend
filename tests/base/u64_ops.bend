# U64 is wrapping 64-bit arithmetic on every lane: add, sub and mul wrap,
# mul_hi is the product's high word, div by zero is 0 and mod by zero the
# dividend, a shift past 63 is 0, clz of 0 is 64, and read refuses a sign or
# a value past 2^64-1; the #| lines are exact integer arithmetic (Python)
import Base

def u(x: U64) -> String:
  U64.show(x)

def mr(m: Maybe<&2, U64>) -> String:
  match m:
    case None{}:
      "None"
    case Some{v}:
      U64.show(v)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(u(U64.add(18446744073709551615u64, 2u64)))
    Unit <- IO.print(u(U64.sub(0u64, 1u64)))
    Unit <- IO.print(u(U64.mul(12345678901234567890u64, 3u64)))
    Unit <- IO.print(u(U64.mul(4294967296u64, 4294967296u64)))
    Unit <- IO.print(u(U64.mul_hi(18446744073709551615u64, 18446744073709551615u64)))
    Unit <- IO.print(u(U64.mul_hi(12345678901234567890u64, 9876543210987654321u64)))
    Unit <- IO.print(u(U64.div(18446744073709551615u64, 3u64)))
    Unit <- IO.print(u(U64.div(7u64, 0u64)))
    Unit <- IO.print(u(U64.mod(18446744073709551615u64, 1000u64)))
    Unit <- IO.print(u(U64.mod(7u64, 0u64)))
    Unit <- IO.print(u(U64.and(12345678901234567890u64, 9876543210987654321u64)))
    Unit <- IO.print(u(U64.or(12345678901234567890u64, 9876543210987654321u64)))
    Unit <- IO.print(u(U64.xor(12345678901234567890u64, 9876543210987654321u64)))
    Unit <- IO.print(u(U64.not(12345678901234567890u64)))
    Unit <- IO.print(u(U64.shln(1u64, 63n)))
    Unit <- IO.print(u(U64.shln(1u64, 64n)))
    Unit <- IO.print(u(U64.shln(3u64, 200n)))
    Unit <- IO.print(u(U64.shrn(18446744073709551615u64, 60n)))
    Unit <- IO.print(u(U64.shrn(18446744073709551615u64, 64n)))
    Unit <- IO.print(u(U64.shl(9223372036854775809u64)))
    Unit <- IO.print(u(U64.shr(9223372036854775809u64)))
    Unit <- IO.print(u(U64.inc(18446744073709551615u64)))
    Unit <- IO.print(u(U32.to_u64(U64.clz(0u64))))
    Unit <- IO.print(u(U32.to_u64(U64.clz(1u64))))
    Unit <- IO.print(u(U32.to_u64(U64.clz(4294967296u64))))
    Unit <- IO.print(u(U32.to_u64(U64.clz(18446744073709551615u64))))
    Unit <- IO.print(u(U64.min(3u64, 18446744073709551615u64)))
    Unit <- IO.print(u(U64.max(3u64, 18446744073709551615u64)))
    Unit <- IO.print(u(U64.from_nat(U32.to_nat(4294967295))))
    Unit <- IO.print(u(U32.to_u64(U64.to_u32(4294967297u64))))
    Unit <- IO.print(u(U32.to_u64(4294967295)))
    Unit <- IO.print(Bool.show(U64.is_lt(1u64, 18446744073709551615u64)))
    Unit <- IO.print(Bool.show(U64.is_lt(18446744073709551615u64, 1u64)))
    Unit <- IO.print(Bool.show(U64.is_le(9223372036854775808u64, 9223372036854775808u64)))
    Unit <- IO.print(Bool.show(U64.is_gt(9223372036854775808u64, 9223372036854775807u64)))
    Unit <- IO.print(Bool.show(U64.is_ge(0u64, 1u64)))
    Unit <- IO.print(Bool.show(U64.is_eq(4294967296u64, 4294967296u64)))
    Unit <- IO.print(Bool.show(U64.is_ne(4294967296u64, 1u64)))
    Unit <- IO.print(Bool.show(U64.is_zero(0u64)))
    Unit <- IO.print(mr(U64.read("18446744073709551615")))
    Unit <- IO.print(mr(U64.read("18446744073709551616")))
    Unit <- IO.print(mr(U64.read("")))
    Unit <- IO.print(mr(U64.read("12a")))
    Unit <- IO.print(mr(U64.read("007")))
    Unit <- IO.print(mr(U64.read("+1")))
    Unit <- IO.print(Nat.show(U64.to_nat(281474976710655u64)))
    IO.print(u(18446744073709551615u64))

#|1
#|18446744073709551615
#|143548556284600438
#|0
#|18446744073709551614
#|6609981178781634653
#|6148914691236517205
#|0
#|615
#|7
#|9876536407748970640
#|12345685704473251571
#|2469149296724280931
#|6101065172474983725
#|9223372036854775808
#|0
#|0
#|15
#|0
#|2
#|4611686018427387904
#|0
#|64
#|63
#|31
#|0
#|3
#|18446744073709551615
#|4294967295
#|1
#|4294967295
#|True
#|False
#|True
#|True
#|False
#|True
#|True
#|True
#|18446744073709551615
#|None
#|None
#|None
#|7
#|None
#|281474976710655
#|18446744073709551615
