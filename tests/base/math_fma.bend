import Base
import ../../bend2/math.bend as M

law main:
  IO(Unit)

def main():
  a = M.from_bits(2176035992)
  b = M.from_bits(1882851208)
  c = M.from_bits(698933837)
  IO.print(U32.show(F32.bits(M.fma(a, b, c))))

#|2994901125
