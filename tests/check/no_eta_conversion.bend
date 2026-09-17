# conversion is up to ETA for functions: {(x => g(x)) == g} at a
# function carrier closes by refl.
# ported from bend3: bend3 refused eta; bend pins the opposite law
import Base

law f:
  for g: U32 -> U32
  {(x => g(x)) == g : U32 -> U32}

def f(g):
  {==}

law main:
  U32

def main(): 0

#|0
