# an f64 literal is its binary64 bits and F64's ops are defs, so the
# checker computes IEEE arithmetic on literals: two spellings of one double
# are one literal, F64.bits reads any U64 back, neg twice is the identity
# on a literal, and 1.0 + 2.0 reduces to 3.0 through the soft float
import Base

law sci_eq:
  {1.5e3f64 == 1500.0f64 : F64}

def sci_eq():
  {==}

law one_bits:
  {F64.bits(1.0f64) == 4607182418800017408u64 : U64}

def one_bits():
  {==}

law bits_of:
  for x: U64
  {F64.bits(F64{x}) == x : U64}

def bits_of(x):
  {==}

law neg_neg:
  {F64.neg(F64.neg(2.5f64)) == 2.5f64 : F64}

def neg_neg():
  {==}

law one_plus_two:
  {F64.add(1.0f64, 2.0f64) == 3.0f64 : F64}

def one_plus_two():
  {==}

def main() -> U32:
  0

#|0
