import Base

# The checker reads U32.mul_hi through its Base definition: 0 * b has no high half.

law mul_hi_zero_l:
  for b: U32
  {U32.mul_hi(0, b) == 0 : U32}

def mul_hi_zero_l(b):
  {==}

def main() -> {U32.mul_hi(0, 7) == 0 : U32}:
  mul_hi_zero_l(7)

#|{==}
