# Exercise runtime operands: F32 ties preserve the selected zero's sign,
# NaN follows is_lt rather than Math.min/max, and U32 compares unsigned.
import Base

def floats(+a: F32, +b: F32) -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(F32.bits(F32.min(a, b))))
    IO.print(U32.show(F32.bits(F32.max(a, b))))

def is_nan(+x: F32) -> Bool:
  F32.is_ne(x, x)

def nan_pair(+a: F32, +b: F32) -> IO(Unit):
  do IO<Unit>:
    IO.print(Bool.show(is_nan(F32.min(a, b))))
    IO.print(Bool.show(is_nan(F32.max(a, b))))
    IO.print(Bool.show(F32.is_eq(F32.min(a, b), 1.0)))
    IO.print(Bool.show(F32.is_eq(F32.max(a, b), 1.0)))

def unsigned(+a: U32, +b: U32) -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(U32.min(a, b)))
    IO.print(U32.show(U32.max(a, b)))

def bools(+a: Bool, +b: Bool) -> IO(Unit):
  do IO<Unit>:
    IO.print(Bool.show(Bool.and(a, b)))
    IO.print(Bool.show(Bool.not(a)))
    IO.print(Bool.show(Bool.pick(Bool, a, b, Bool.not(b))))
    IO.print(Bool.pick(String, a, "yes", "no"))
    IO.print(Nat.show(Bool.pick(Nat, a, Nat.mul(1048576n, 1048576n), 7n)))

def suite(+z: Nat) -> IO(Unit):
  do IO<Unit>:
    floats(F32.from_nat(z), F32.neg(F32.from_nat(z)))
    floats(F32.neg(F32.from_nat(z)), F32.from_nat(z))
    floats(F32.from_nat(z), F32.from_nat(z))
    floats(F32.neg(F32.from_nat(z)), F32.neg(F32.from_nat(z)))
    nan_pair(F32.div(F32.from_nat(z), F32.from_nat(z)), 1.0)
    nan_pair(1.0, F32.div(F32.from_nat(z), F32.from_nat(z)))
    nan_pair(F32.div(F32.from_nat(z), F32.from_nat(z)),
      F32.div(F32.from_nat(z), F32.from_nat(z)))
    unsigned(U32.from_nat(z), 4294967295)
    unsigned(4294967295, U32.from_nat(z))
    unsigned(U32.add(2147483648, U32.from_nat(z)), 2147483647)
    unsigned(2147483647, U32.add(2147483648, U32.from_nat(z)))
    unsigned(U32.add(4294967295, U32.from_nat(z)), 4294967295)
    bools(Nat.is_eq(z, 0n), Nat.is_eq(z, 0n))
    bools(Nat.is_eq(z, 0n), Nat.is_eq(z, 1n))
    bools(Nat.is_eq(z, 1n), Nat.is_eq(z, 0n))
    bools(Nat.is_eq(z, 1n), Nat.is_eq(z, 1n))

def main() -> IO(Unit):
  do IO<Unit>:
    t : Nat <- IO.now()
    suite(Nat.mod(t, 1n))

#|2147483648
#|0
#|0
#|2147483648
#|0
#|0
#|2147483648
#|2147483648
#|False
#|True
#|True
#|False
#|True
#|False
#|False
#|True
#|True
#|True
#|False
#|False
#|0
#|4294967295
#|0
#|4294967295
#|2147483647
#|2147483648
#|2147483647
#|2147483648
#|4294967295
#|4294967295
#|True
#|False
#|True
#|yes
#|1099511627776
#|False
#|False
#|False
#|yes
#|1099511627776
#|False
#|True
#|False
#|no
#|7
#|False
#|True
#|True
#|no
#|7
