# rounding and sign reach their natives: floor, ceil and trunc part
# ways on a negative operand, and abs is fabs
import Base

law main.out:
  String

def main.out():
  a = F32.show(F32.floor((0.0 - 1.5 : F32)))
  b = F32.show(F32.ceil((0.0 - 1.5 : F32)))
  c = F32.show(F32.trunc((0.0 - 1.5 : F32)))
  d = F32.show(F32.abs((0.0 - 1.5 : F32)))
  a ++ " " ++ b ++ " " ++ c ++ " " ++ d

law main:
  IO(Unit)

def main():
  IO.print(main.out())

#|-2 -1 -1 1.5
