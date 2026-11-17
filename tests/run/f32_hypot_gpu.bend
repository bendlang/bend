# Parallel vector lengths must stay finite and nonzero at extreme scales.
import Base

def lengths(+n: Nat, +s: F32) -> U32:
  match n:
    case 0n:
      +x = F32.hypot(F32.mul(3.0, s), F32.mul(4.0, s))
      Bool.to_u32(Bool.and(F32.is_gt(x, 0.0), F32.is_lt(x, F32.div(1.0, 0.0))))
    case 1n+p:
      a b = lengths(p, s) lengths(p, F32.neg(s))
      U32.add(a, b)

def boundary(n: Nat, +x: F32, +y: F32, +want: U32) -> U32:
  match n:
    case 0n:
      Bool.to_u32(U32.is_eq(F32.bits(F32.hypot(x, y)), want))
    case 1n+p:
      +d = p
      a b = boundary(d, x, y, want) boundary(d, y, F32.neg(x), want)
      U32.add(a, b)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(lengths!(4n, 1.0e30)))
    IO.print(U32.show(lengths!(4n, 1.0e-30)))
    IO.print(U32.show(boundary!(2n, 2.22e38, 2.578916e38, 2139095039)))
    IO.print(U32.show(boundary!(2n, 3.4028235e38, 1.0e35, 2139095040)))
    IO.print(U32.show(boundary!(2n, 3.174205215935328e38,
      1.2262257054416832e38, 2139095040)))

#|16
#|16
#|4
#|4
#|4
