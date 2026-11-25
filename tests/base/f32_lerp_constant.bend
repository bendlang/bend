import Base

def lerp_nan(+x: F32) -> Bool:
  F32.is_ne(x, x)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(F32.bits(F32.lerp(1.401298464324817e-45, 1.401298464324817e-45, 0.5))))
    IO.print(U32.show(F32.bits(F32.lerp(F32.neg(1.401298464324817e-45), F32.neg(1.401298464324817e-45), 0.5))))
    IO.print(U32.show(F32.bits(F32.lerp(2.25, 2.25, 1.0e20))))
    IO.print(U32.show(F32.bits(F32.lerp(3.4028234663852886e38, 3.4028234663852886e38, 0.3))))
    IO.print(U32.show(F32.bits(F32.lerp(F32.neg(0.0), F32.neg(0.0), 0.5))))
    IO.print(U32.show(F32.bits(F32.lerp(F32.neg(0.0), 0.0, 0.5))))
    IO.print(Bool.show(lerp_nan(F32.lerp(2.25, 2.25, F32.div(1.0, 0.0)))))
    IO.print(Bool.show(lerp_nan(F32.lerp(2.25, 2.25, F32.div(0.0, 0.0)))))
    IO.print(Bool.show(F32.is_eq(F32.lerp(F32.div(1.0, 0.0), F32.div(1.0, 0.0), 0.5), F32.div(1.0, 0.0))))
    IO.print(Bool.show(lerp_nan(F32.lerp(F32.div(1.0, 0.0), F32.div(1.0, 0.0), 2.0))))
    IO.print(Bool.show(F32.is_le(F32.lerp(1.0000001192092896, 1.000000238418579, 0.25), F32.lerp(1.0000001192092896, 1.000000238418579, 0.28125))))
    stamp : Nat <- IO.now()
    IO.print(U32.show(F32.bits(F32.lerp(1.401298464324817e-45, 1.401298464324817e-45, F32.from_nat(stamp)))))

#|1
#|2147483649
#|1074790400
#|2139095039
#|2147483648
#|0
#|True
#|True
#|True
#|True
#|True
#|1
