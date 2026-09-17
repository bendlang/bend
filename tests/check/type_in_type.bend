# main can be a theorem (the run prints {==}), and Type : Type is real:
# a def may yield Type itself.
# ported from bend3
import Base

law t:
  Type

def t(): Type

law main:
  {U32.add(2, 2) == 4 : U32}

def main(): {==}

#|{==}
