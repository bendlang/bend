# a u64 literal is its two U32 halves, so the checker reduces U64 on
# literals: a wrapping operation meets its literal result, mul_hi is the
# high word of a full 128-bit product, a match reads a wide literal
# pattern, and U64.add_comm proves commutativity from Word.add_comm
import Base

law halves:
  {4294967296u64 == U64{0, 1} : U64}

def halves():
  {==}

law wrap_inc:
  {U64.inc(18446744073709551615u64) == 0u64 : U64}

def wrap_inc():
  {==}

law wrap_add:
  {U64.add(18446744073709551610u64, 10u64) == 4u64 : U64}

def wrap_add():
  {==}

law sub_wrap:
  {U64.sub(0u64, 1u64) == 18446744073709551615u64 : U64}

def sub_wrap():
  {==}

law mul_hi_max:
  {U64.mul_hi(18446744073709551615u64, 18446744073709551615u64)
    == 18446744073709551614u64 : U64}

def mul_hi_max():
  {==}

law comm:
  for a: U64
  for b: U64
  {U64.add(a, b) == U64.add(b, a) : U64}

def comm(a, b):
  U64.add_comm(a, b)

def classify(n: U64) -> U32:
  match n:
    case 3000000000u64:
      7
    case 18446744073709551615u64:
      9
    case _:
      1

law classify_max:
  {classify(18446744073709551615u64) == 9 : U32}

def classify_max():
  {==}

def main() -> U32:
  U32.add(classify(3000000000u64), classify(18446744073709551615u64))

#|16
