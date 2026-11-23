# The signs are visible in F32.bits even though both zeros compare equal.
import Base

def show(+a: F32, +b: F32) -> IO(Unit):
  do IO<Unit>:
    u : Unit <- IO.print(U32.show(F32.bits(F32.min(a, b))))
    v : Unit <- IO.print(U32.show(F32.bits(F32.min(b, a))))
    w : Unit <- IO.print(U32.show(F32.bits(F32.max(a, b))))
    IO.print(U32.show(F32.bits(F32.max(b, a))))

def zeros(+scale: F32) -> IO(Unit):
  show(F32.mul(F32.neg(0.0), scale), F32.mul(0.0, scale))

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    zeros(F32.from_nat(Nat.add(1n, List.length(&1, String, args))))

#|2147483648
#|2147483648
#|0
#|0
