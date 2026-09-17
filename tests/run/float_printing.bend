# printing is six significant digits on every lane, and the two
# printers part ways on a tie: %g rounds 0.0009765625 to even and
# toPrecision rounds it up, which is the lane split pinned below
import Base

law main.out:
  String

def main.out():
  a = F32.show(2.0)
  b = F32.show(100.25)
  c = F32.show((1.0 / 3.0 : F32))
  d = F32.show(0.0009765625)
  e = F32.show(123456.0)
  a ++ " " ++ b ++ " " ++ c ++ " " ++ d ++ " " ++ e

law main:
  IO(Unit)

def main():
  IO.print(main.out())

#|2 100.25 0.33333334 0.0009765625 123456
