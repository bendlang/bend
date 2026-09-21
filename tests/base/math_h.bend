# math.h-style library smoke test: constants, rounding, bit stepping,
# transcendental helpers, gamma and classification all cross a module import.
import Base
import ../../bend2/math.bend as M

law main.out:
  String

def main.out():
  a = F32.show(M.M_PI())
  b = F32.show(M.M_SQRT2())
  c = F32.show(M.round(F32.neg(1.5)))
  d = U32.show(F32.bits(M.nextafter(1.0, 2.0)))
  e = F32.show(M.tgamma(5.0))
  f = F32.show(M.erf(1.0))
  g = Bool.show(M.isfinite(M.INFINITY()))
  h = Bool.show(M.isnan(M.NAN()))
  a ++ " " ++ b ++ " " ++ c ++ " " ++ d ++ " " ++ e ++ " " ++ f
    ++ " " ++ g ++ " " ++ h

law main:
  IO(Unit)

def main():
  IO.print(main.out())

#|3.1415927 1.4142135 -2 1065353217 24 0.8427008 False True
