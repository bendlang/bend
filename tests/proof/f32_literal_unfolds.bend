# a float literal is one Lit node holding its bits: two spellings of
# the same f32 compare equal, and the exponent form is the same literal
import Base

law sci_eq:
  {1.5e3 == 1500.0 : F32}

def sci_eq():
  {==}

law exp_eq:
  {1.25e-2 == 0.0125 : F32}

def exp_eq():
  {==}

def main() -> U32:
  0

#|0
