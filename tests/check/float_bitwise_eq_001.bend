# single-precision rounding law: 0.1 + 0.2 rounds to exactly the
# f32 of 0.3 (0x3E99999A both ways), unlike the double-precision folk
# inequality -- neither side is less
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
  (bu((0.1 + 0.2 < 0.3 : F32)) + bu((0.3 < 0.1 + 0.2 : F32)) : U32)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|0
