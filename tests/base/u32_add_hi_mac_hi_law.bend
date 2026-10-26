import Base

# The checker reads both primitives through their Base definitions.

law add_hi_zero:
  for a: U32
  {U32.add_hi(0, 0) == 0 : U32}

def add_hi_zero(a):
  {==}

law mac_hi_zero:
  for c: U32
  {U32.mac_hi(0, c, 0, 0) == 0 : U32}

def mac_hi_zero(c):
  {==}

def main() -> {U32.mac_hi(0, 9, 0, 0) == 0 : U32}:
  mac_hi_zero(9)

#|{==}
