# F64.read: whole-decimal validation -- decimals, inf, nan land on Some; junk
# and trailing junk on None; a show -> read round trip lands back on the same
# bits (via the print of the re-shown value)
import Base

law pick:
  for m: Maybe<&2, F64>
  String

def pick(m):
  match m:
    case Some{x}:
      F64.show(x)
    case None{}:
      "NONE"

law main:
  IO(Unit)

def main():
  do IO<Unit>:
    IO.print(pick(F64.read("-1.5")))
    IO.print(pick(F64.read("inf")))
    IO.print(pick(F64.read("nan")))
    IO.print(pick(F64.read("hello")))
    IO.print(pick(F64.read("1.25junk")))
    IO.print(pick(F64.read(F64.show(F64.add(0.1d, 0.2d)))))

#|-1.5
#|inf
#|nan
#|NONE
#|NONE
#|0.30000000000000004
