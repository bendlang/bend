# float edges where JS's built-ins part from C: pow's C99 specials (1 to
# any power, -1 to +-inf), printf's even tie on a last digit, and strtof's
# single rounding of a decimal just past a float midpoint
import Base

law val:
  for m: Maybe<&2, F32>
  F32

def val(m):
  match m:
    case None{}:
      0.0
    case Some{v}:
      v

law num:
  for s: String
  F32

def num(s):
  val(F32.read(s))

law main.out:
  String

def main.out():
  nan = num("nan")
  inf = num("inf")
  a = F32.show(F32.pow(1.0, nan))
  b = F32.show(F32.pow(F32.neg(1.0), inf))
  c = F32.show(F32.pow(F32.neg(1.0), num("-inf")))
  d = F32.show(1.44140625)
  e = F32.show(num("1.0000000596046447753906250001"))
  f = F32.show(num("1.0000000596046447753906249999"))
  a ++ " " ++ b ++ " " ++ c ++ " " ++ d ++ " " ++ e ++ " " ++ f

law main:
  IO(Unit)

def main():
  IO.print(main.out())

#|1 1 1 1.4414062 1.0000001 1
