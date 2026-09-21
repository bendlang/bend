import Base
import ../../bend2/math.bend as M

law main.frexp_max:
  String

def main.frexp_pair(p: F32 & M.S32) -> String:
  (m, e) = p
  U32.show(F32.bits(m)) ++ ":" ++ M.S32.show(e)

def main.frexp_max():
  main.frexp_pair(M.frexp(M.from_bits(2139095039)))

law main.modf_inf:
  String

def main.modf_pair(p: F32 & F32) -> String:
  (f, i) = p
  U32.show(F32.bits(f)) ++ ":" ++ Bool.show(M.isinf(i))

def main.modf_inf():
  main.modf_pair(M.modf(M.INFINITY()))

law main.remquo_neg:
  String

def main.remquo_pair(p: F32 & M.S32) -> String:
  (r, q) = p
  U32.show(F32.bits(r)) ++ ":" ++ M.S32.show(q)

def main.remquo_neg():
  main.remquo_pair(M.remquo(F32.neg(23.5), 8.0))

law main:
  IO(Unit)

def main():
  min_norm = M.from_bits(8388608)
  +max_fin = M.from_bits(2139095039)
  +nz = M.from_bits(2147483648)
  a = F32.show(M.scalbn(min_norm, M.S32.pos(128)))
  b = F32.show(M.scalbn(max_fin, M.S32.neg(150)))
  c = main.frexp_max()
  d = F32.show(M.logb(max_fin))
  e = M.S32.show(M.ilogb(max_fin))
  f = main.modf_inf()
  g = F32.show(M.remainder(2.0, M.INFINITY()))
  h = U32.show(F32.bits(M.tgamma(0.0)))
  i = U32.show(F32.bits(M.tgamma(nz)))
  j = Bool.show(M.isnan(M.tgamma(F32.neg(M.INFINITY()))))
  k = Bool.show(F32.is_gt(M.erfc(5.0), 0.0))
  l = Bool.show(F32.is_ne(M.asinh(0.00000001), 0.0))
  m = U32.show(F32.bits(M.sinpi(1.0)))
  n = U32.show(F32.bits(M.sinpi(16777216.0)))
  o = U32.show(F32.bits(M.pown(F32.neg(1.0), M.S32.pos(16777217))))
  p = Bool.show(M.signbit(M.roundeven(F32.neg(0.5))))
  q = U32.show(F32.bits(M.fma(M.from_bits(1687846912),
    M.from_bits(2398336256), M.from_bits(2574717546))))
  r = main.remquo_neg()
  s = U32.show(F32.bits(M.rootn(nz, M.S32.pos(3))))
  t = U32.show(F32.bits(M.rootn(nz, M.S32.neg(3))))
  u = U32.show(F32.bits(M.round(8388609.0)))
  v = U32.show(F32.bits(M.round(F32.neg(8388609.0))))
  w = U32.show(F32.bits(M.tanpi(1.0)))
  x = U32.show(F32.bits(M.tanpi(F32.neg(1.0))))
  y = U32.show(F32.bits(M.tanpi(1.5)))
  z = U32.show(F32.bits(M.tanpi(F32.neg(1.5))))
  aa = Bool.show(M.isnan(M.powr(0.0, nz)))
  ab = Bool.show(M.isnan(M.powr(0.0, M.INFINITY())))
  ac = Bool.show(M.isnan(M.powr(M.INFINITY(), 1.0)))
  ad = U32.show(F32.bits(M.powr(F32.neg(2.0), nz)))
  ae = U32.show(F32.bits(M.powr(3.0, nz)))
  af = U32.show(F32.bits(M.rootn(nz, M.S32.pos(2))))
  ag = U32.show(F32.bits(M.rootn(nz, M.S32.neg(2))))
  IO.print(a ++ " " ++ b ++ " " ++ c ++ " " ++ d ++ " " ++ e ++ " "
    ++ f ++ " " ++ g ++ " " ++ h ++ " " ++ i ++ " " ++ j ++ " " ++ k
    ++ " " ++ l ++ " " ++ m ++ " " ++ n ++ " " ++ o ++ " " ++ p ++ " " ++ q
    ++ " " ++ r ++ " " ++ s ++ " " ++ t ++ " " ++ u ++ " " ++ v ++ " " ++ w
    ++ " " ++ x ++ " " ++ y ++ " " ++ z ++ " " ++ aa ++ " " ++ ab ++ " " ++ ac
    ++ " " ++ ad ++ " " ++ ae ++ " " ++ af ++ " " ++ ag)
#|4 2.3841856e-7 1065353215:128 127 127 0:True 2 2139095040 4286578688 True True True 0 0 3212836864 True 3021149373 1056964608:-3 2147483648 4286578688 1258291201 3405774849 2147483648 0 4286578688 2139095040 True True True 2139095040 0 0 2139095040
