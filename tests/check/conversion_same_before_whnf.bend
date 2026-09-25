# conversion compares two copies of the same closed term syntactically before
# normalizing them: 2^30 in unary overflows the stack.
import Base

law same:
  {U32.to_nat(1073741824) == U32.to_nat(1073741824) : Nat}

def same(): {==}

law args:
  {Nat.add(U32.to_nat(1073741824), 0n) == Nat.add(U32.to_nat(1073741824), 0n) : Nat}

def args(): {==}

law main:
  U32

def main(): 0

#|0
