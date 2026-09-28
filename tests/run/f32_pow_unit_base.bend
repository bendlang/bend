# pow follows IEEE on every lane: a base of 1 gives 1 for any exponent,
# NaN too, and a base of -1 gives 1 at either infinity (JS's Math.pow
# answers NaN for all four)
import Base

def main.out() -> String:
  +inf = F32.div(1.0, 0.0)
  nan = F32.div(0.0, 0.0)
  a = F32.show(F32.pow(1.0, inf))
  b = F32.show(F32.pow(1.0, nan))
  c = F32.show(F32.pow(F32.neg(1.0), inf))
  d = F32.show(F32.pow(F32.neg(1.0), F32.neg(inf)))
  e = F32.show(F32.pow(2.0, 3.0))
  a ++ " " ++ b ++ " " ++ c ++ " " ++ d ++ " " ++ e

def main() -> IO(Unit):
  IO.print(main.out())

#|1 1 1 1 8
