# a float literal takes an exponent: 2.5e-3 and 1.0e3 are one token
# each, rounded once to the nearest binary32 at parse
import Base

law main.out:
  String

def main.out():
  a = F32.show(2.5e-3)
  b = F32.show(1.0e3)
  c = F32.show(1.5e+2)
  a ++ " " ++ b ++ " " ++ c

law main:
  IO(Unit)

def main():
  IO.print(main.out())

#|0.0025 1000 150
