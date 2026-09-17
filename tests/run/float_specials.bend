# F32 specials: nan compares false, inf arithmetic, -0.0 == 0.0 (IEEE),
# f32_to_u32 sends nan/negative/overflow to 0
# ported from bend3: nan/inf are rebuilt as 0/0 and 1/0; -F32.inf is
# 0-inf; 1e30 becomes a huge finite product (the law is inf > finite);
# the nan laws need the F32.is_eq/is_ne/is_ge/is_gt axioms
import Base

law bu:
  for b: Bool
  U32

def bu(b):
  match b:
    case False{}:
      0
    case True{}:
      1

law fl:
  for n: U32
  for d: U32
  F32

def fl(n, d):
  F32.div(U32.to_f32(n), U32.to_f32(d))

law main.out:
  U32

def main.out():
  +z = {fl(0, 1) : F32}
  +one = {fl(1, 1) : F32}
  +nan = {F32.div(z, z) : F32}
  +inf = {F32.div(one, z) : F32}
  b0 = bu(U32.is_eq(bu(F32.is_eq(nan, nan)), 0))
  b1 = bu(U32.is_eq(bu(F32.is_ne(nan, nan)), 1))
  b2 = bu(U32.is_eq(bu(F32.is_lt(nan, one)), 0))
  b3 = bu(U32.is_eq(bu(F32.is_ge(nan, one)), 0))
  b4 = bu(F32.is_eq(F32.div(one, z), inf))
  b5 = bu(F32.is_eq(F32.div(F32.sub(z, one), z), F32.sub(z, inf)))
  b6 = bu(U32.is_eq(F32.to_u32(F32.sub(inf, inf)), 0))
  b7 = bu(F32.is_eq(F32.mul(z, F32.sub(z, one)), z))
  b8 = bu(U32.is_eq(bu(F32.is_gt(inf, F32.mul(U32.to_f32(4294967295), U32.to_f32(4294967295)))), 1))
  b9 = bu(U32.is_eq(F32.to_u32(F32.sub(z, fl(5, 2))), 0))
  b10 = bu(U32.is_eq(F32.to_u32(F32.mul(U32.to_f32(2500000000), fl(2, 1))), 0))
  b11 = bu(U32.is_eq(F32.to_u32(nan), 0))
  U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(U32.add(b0, b1), b2), b3), b4), b5), b6), b7), b8), b9), b10), b11)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|12
