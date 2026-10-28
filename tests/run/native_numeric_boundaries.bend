# Native bit widths agree with Base at zero and bit-width boundaries.
import Base

# Naive references: a bit per step
def slow.pc(+k: Nat, +n: U32) -> Nat:
  match k:
    case 0n:
      0n
    case 1n+p:
      Nat.add(U32.to_nat(U32.and(n, 1)), slow.pc(p, U32.shr(n)))

def slow.tz(+k: Nat, +n: U32, +m: U32) -> Nat:
  match k:
    case 0n:
      0n
    case 1n+p:
      +z = U32.to_nat(Bool.to_u32(U32.is_zero(U32.and(n, m))))
      Nat.add(z, slow.tz(p, n, U32.inc(U32.shl(m))))

def fast(+x: U32) -> Nat:
  Nat.add(U32.popcount(x), U32.ctz(x))

def slow(+x: U32) -> Nat:
  Nat.add(slow.pc(32n, x), slow.tz(32n, x, 1))

# A ! call, so the device lanes build popcount too
def bits(~f: @+x:U32 -> Nat, +d: Nat, +i: U32) -> Nat:
  match d:
    case 0n:
      f((i * 2654435761 : U32))
    case 1n+p:
      a b = bits(~f, p, (i * 2 : U32)) bits(~f, p, (i * 2 + 1 : U32))
      Nat.add(a, b)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(Nat.show(U32.log2(0)))
    IO.print(Nat.show(U32.log2(1)))
    IO.print(Nat.show(U32.log2(2)))
    IO.print(Nat.show(U32.log2(3)))
    IO.print(Nat.show(U32.log2(4)))
    IO.print(Nat.show(U32.log2(2147483647)))
    IO.print(Nat.show(U32.log2(2147483648)))
    IO.print(Nat.show(U32.log2(4294967295)))
    IO.print(Nat.show(U32.popcount(0)))
    IO.print(Nat.show(U32.popcount(1)))
    IO.print(Nat.show(U32.popcount(61680)))
    IO.print(Nat.show(U32.popcount(2147483648)))
    IO.print(Nat.show(U32.popcount(4294967295)))
    IO.print(Nat.show(U32.ctz(0)))
    IO.print(Nat.show(U32.ctz(1)))
    IO.print(Nat.show(U32.ctz(12)))
    IO.print(Nat.show(U32.ctz(2147483648)))
    IO.print(Nat.show(U32.ctz(4294967295)))
    IO.print(Nat.show(bits!(~fast, 6n, 0)))
    IO.print(Nat.show(bits(~slow, 6n, 0)))
    IO.print(Nat.show(Map.msb.u(0n, 4294967295)))
    IO.print(Nat.show(Map.msb.u(1n, 0)))
    IO.print(Nat.show(Map.msb.u(1n, 4294967295)))
    IO.print(Nat.show(Map.msb.u(31n, 4294967295)))
    IO.print(Nat.show(Map.msb.u(32n, 4294967295)))
    IO.print(Nat.show(Map.msb.u(99n, 4294967295)))
    IO.print(Nat.show(Map.msb.u(32n, 1)))
    IO.print(Nat.show(Map.msb.u(99n, 2147483648)))

#|0
#|0
#|1
#|1
#|2
#|30
#|31
#|31
#|0
#|1
#|8
#|1
#|32
#|32
#|0
#|2
#|31
#|0
#|1115
#|1115
#|0
#|0
#|1
#|31
#|32
#|32
#|1
#|32
