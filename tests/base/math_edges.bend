import Base
import ../../bend2/math.bend as M

law main.out:
  String

def main.frexp_show(p: F32 & M.S32) -> String:
  (m, n) = p
  F32.show(m) ++ ":" ++ M.S32.show(n)

def main.out():
  +nz = M.from_bits(2147483648)
  a = U32.show(F32.bits(M.nextafter(1.0, 0.0)))
  b = U32.show(F32.bits(M.nextafter(F32.neg(1.0), 0.0)))
  c = U32.show(F32.bits(M.nextafter(0.0, F32.neg(1.0))))
  d = Bool.show(M.signbit(M.fmin(0.0, nz)))
  e = Bool.show(M.signbit(M.fmax(nz, 0.0)))
  f = F32.show(M.roundeven(2.5))
  g = F32.show(M.roundeven(3.5))
  h = F32.show(M.roundeven(F32.neg(2.5)))
  i = main.frexp_show(M.frexp(12.0))
  j = Bool.show(M.signbit(M.remainder(F32.neg(4.0), 2.0)))
  k = M.S32.show(M.ilogb(8.0))
  a ++ " " ++ b ++ " " ++ c ++ " " ++ d ++ " " ++ e ++ " " ++ f
    ++ " " ++ g ++ " " ++ h ++ " " ++ i ++ " " ++ j ++ " " ++ k

law main:
  IO(Unit)

def main():
  IO.print(main.out())

#|1065353215 3212836863 2147483649 True False 2 4 -2 0.75:4 True 3
