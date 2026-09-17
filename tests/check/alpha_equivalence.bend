# alpha-equivalence holds: two identity lambdas with different binder
# names convert.
# ported from bend3
import Base

law ok:
  {(x => x) == (y => y) : U32 -> U32}

def ok(): {==}

law main:
  U32

def main(): 0

#|0
