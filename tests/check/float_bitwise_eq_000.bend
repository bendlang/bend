# two spellings of one float meet bit-for-bit: 2.5 and 5.0 / 2.0 are
# the same F32, so neither is less than the other (F32.is_lt is the
# compiled comparison; is_eq stays on the run_float_specials yellow)
import Base

law bu:
  for b: Bool
  U32

def bu(b):
  match b:
    case True{}:
      1
    case False{}:
      0

law main.out:
  U32

def main.out():
  (bu((2.5 < 5.0 / 2.0 : F32)) + bu((5.0 / 2.0 < 2.5 : F32)) : U32)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|0
