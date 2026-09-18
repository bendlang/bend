# conversions: F32 widening to F64 is exact (0.1f32 reveals its true value),
# F64 to U32 truncates in range and saturates to 0 outside it, from_nat is
# exact, and the bits of small magnitudes (0 and the smallest subnormal)
# ride Nat -- large-magnitude bit patterns exceed the Nat immediate by design
import Base

law main:
  IO(Unit)

def main():
  do IO<Unit>:
    IO.print(F64.show(F32.to_f64(0.1)))
    IO.print(F64.show(F64.from_nat(7n)))
    IO.print(U32.show(F64.to_u32(3.9d)))
    IO.print(U32.show(F64.to_u32(0.99d)))
    IO.print(U32.show(F64.to_u32(F64.neg(1.0d))))
    IO.print(Nat.show(F64.bits(0.0d)))
    IO.print(Nat.show(F64.bits(5.0e-324d)))

#|0.10000000149011612
#|7
#|3
#|0
#|0
#|0
#|1
