# f32: u32_to_f32/f32_to_u32 round-trip through float arithmetic,
# with 7.5 spelled as F32.div(15, 2); no interpreter lane (Base's F32
# axioms are stuck there)
import Base

law fl:
  for n: U32
  for d: U32
  F32

def fl(n, d):
  F32.div(U32.to_f32(n), U32.to_f32(d))

law main.out:
  U32

def main.out():
  F32.to_u32(F32.mul(U32.to_f32(6), fl(15, 2)))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|45
