# the hyperbolic family reaches its native: sinh, cosh and tanh are
# one libm call each, and tanh saturates to 1 well before 20.0
import Base

law main.out:
  String

def main.out():
  a = F32.show(F32.sinh(1.0))
  b = F32.show(F32.cosh(1.0))
  c = F32.show(F32.tanh(1.0))
  d = F32.show(F32.tanh(20.0))
  a ++ " " ++ b ++ " " ++ c ++ " " ++ d

law main:
  IO(Unit)

def main():
  IO.print(main.out())

#|1.1752012 1.5430807 0.7615942 1
