# fma rounds a * b + c once: the low bits of x * x survive the cancellation
# that mul then add loses; a sum just under a halfway point rounds down where
# mul's own rounding lands on the point and ties up; a signed zero and a nan
# come out as one rounding makes them
import Base

def bits(x: F32) -> String:
  U32.show(F32.bits(x))

def cancel.go(+x: F32, +p: F32) -> String:
  bits(F32.fma(x, x, F32.neg(p))) ++ " " ++ bits(F32.add(p, F32.neg(p)))

def cancel(+x: F32) -> String:
  cancel.go(x, F32.mul(x, x))

def halfway(+x: F32, +y: F32, +z: F32) -> String:
  bits(F32.fma(y, z, x)) ++ " " ++ bits(F32.add(F32.mul(y, z), x))

def signs(+n: F32) -> String:
  bits(F32.fma(n, 1.0, n)) ++ " " ++ bits(F32.fma(n, 1.0, 0.0))

law main.out:
  String

def main.out():
  a = cancel(1.00000012)                          # 1 + 2^-23
  b = halfway(1.00000012, 5.96046519e-8, 0.99999988)
  c = signs(F32.neg(0.0))
  d = F32.show(F32.fma(F32.div(1.0, 0.0), 0.0, 1.0))
  e = F32.show(F32.fma(2.0, 3.0, 0.5))
  a ++ " " ++ b ++ " " ++ c ++ " " ++ d ++ " " ++ e

law main:
  IO(Unit)

def main():
  IO.print(main.out())

#|679477248 0 1065353217 1065353218 2147483648 0 nan 6.5
