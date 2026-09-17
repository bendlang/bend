# a compiled F32 inside a constructor: the record is built at runtime
# and an IO main prints its fields through F32.show, the same on every
# lane (2.0 prints as 2, 0.1 as the shortest digits that read back)
import Base

type FV is Data:
  FV{a: F32, b: F32, c: F32}

def FV.show(v: FV) -> String:
  match v:
    case FV{a, b, c}:
      "FV{" ++ F32.show(a) ++ ", " ++ F32.show(b) ++ ", " ++ F32.show(c) ++ "}"

law main:
  IO(Unit)

def main():
  IO.print(FV.show(FV{2.0, 0.5, 0.1}))

#|FV{2, 0.5, 0.1}
