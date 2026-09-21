import Base
import ../../bend2/math.bend as M

law main:
  IO(Unit)

def main():
  +nz = M.from_bits(2147483648)
  a = U32.show(F32.bits(M.lgamma(1.0)))
  b = U32.show(F32.bits(M.lgamma(2.0)))
  c = U32.show(F32.bits(M.pow(1.0, M.INFINITY())))
  d = U32.show(F32.bits(M.pow(1.0, M.NAN())))
  e = U32.show(F32.bits(M.pow(F32.neg(1.0), M.INFINITY())))
  f = U32.show(F32.bits(M.fma(0.0, F32.neg(1.0), nz)))
  g = U32.show(F32.bits(M.fma(nz, F32.neg(1.0), nz)))
  h = U32.show(F32.bits(M.pown(2647993.0, M.S32.neg(6))))
  i = U32.show(F32.bits(M.exp2m1(nz)))
  j = U32.show(F32.bits(M.exp10m1(nz)))
  k = U32.show(F32.bits(M.asinpi(nz)))
  l = U32.show(F32.bits(M.rsqrt(nz)))
  m = U32.show(F32.bits(M.powr(3.0, 2.0)))
  n = Bool.show(M.isnan(M.powr(0.0, 0.0)))
  o = U32.show(F32.bits(M.tanpi(F32.neg(1.0))))
  p = U32.show(F32.bits(M.tanpi(1.0)))
  IO.print(a ++ " " ++ b ++ " " ++ c ++ " " ++ d ++ " " ++ e ++ " "
    ++ f ++ " " ++ g ++ " " ++ h ++ " " ++ i ++ " " ++ j ++ " " ++ k
    ++ " " ++ l ++ " " ++ m ++ " " ++ n ++ " " ++ o ++ " " ++ p)
#|0 0 1065353216 1065353216 1065353216 2147483648 0 2069991 2147483648 2147483648 2147483648 4286578688 1090519040 True 0 2147483648
