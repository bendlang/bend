# ported from bend3: a float-builtin call with the wrong arity errors.
# bend3's builtins were $-sigiled unary calls and the mismatch was a
# parse error; bend's F32.sqrt is an ordinary 1-ary base axiom, so the
# respelling is the checker's: the over-applied F32.sqrt(1.0) is an
# F32, not a function.
import Base

law main:
  F32

def main():
  F32.sqrt(1.0, 2.0)

#|Error:
#|- expected : a function type
#|- observed : F32
#|Location: main
#|11 | def main():
#|12>|   F32.sqrt(1.0, 2.0)
#|   |   ^^^^^^^^^^^^^^^^^^
#|13 |
#|exit 1
