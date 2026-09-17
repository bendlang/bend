# io (io_marshal_char_scalar): a Char is born only at a Unicode
# scalar code -- char_new's law, the ONE Char-from-code site every
# lane shares now that the interpreter runs the compiled JS itself.
# This golden pinned the dead interp-side refusal (term_of's scalar
# guard); the law survives it: a Chr{code} build at a non-scalar code
# fail-stops in char_new, in the interpreter exactly as in the
# compiled program. The three boundary scalars (55295, 57344,
# 1114111) cross first: a guard misfiring on any of them would name
# that code in the refusal instead of 55296. The compiled leg dies
# on the same throw, fail-stopped by io_exit's catch as the same
# one-line spelling on stderr, exit 1 - pinned below.
import Base

law echo:
  for c: Char
  IO(Char)

def echo(c):
  import "./marshal_char_scalar.js"

law main:
  IO(U32)

def main():
  do IO<U32>:
    a : Char <- echo(Chr{55295})
    b : Char <- echo(Chr{57344})
    c : Char <- echo(Chr{1114111})
    d : Char <- echo(Chr{55296})
    return 0

#|bend: 55296 is not a Unicode scalar value
#|exit 1
