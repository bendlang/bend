# every trig name reaches its native: sin, cos and tan are one libm
# call on each backend, and the four lanes print the same six digits
import Base

law main.out:
  String

def main.out():
  s = F32.show(F32.sin(1.0))
  c = F32.show(F32.cos(1.0))
  t = F32.show(F32.tan(1.0))
  s ++ " " ++ c ++ " " ++ t

law main:
  IO(Unit)

def main():
  IO.print(main.out())

#|0.84147096 0.5403023 1.5574077
