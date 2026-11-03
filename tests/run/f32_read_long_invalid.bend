# The JS reader must reject a long integer with an invalid suffix without
# splitting its digits between two overlapping repetitions. A long decimal
# midpoint with a trailing space must be rejected before exact rounding.
# Build both with a tail-recursive accumulator to avoid exhausting the stack.
import Base

def digits(n: Nat, +digit: Char, acc: String) -> String:
  match n:
    case 0n:
      acc
    case 1n+p:
      digits(p, digit, SCon{digit, acc})

def seen(m: Maybe<&2, F32>) -> String:
  match m:
    case None{}:
      "none"
    case Some{v}:
      F32.show(v)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(seen(F32.read(digits(100000n, '1', "x"))))
    IO.print(seen(F32.read("1.000000059604644775390625"
      ++ digits(5000n, '0', " "))))

#|none
#|none
