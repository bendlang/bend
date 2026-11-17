# Overflow classification must use the exact squares of the input values.
import Base

def check(+x: F32, +y: F32, +want: U32) -> Bool:
  Bool.and(U32.is_eq(F32.bits(F32.hypot(x, y)), want),
    Bool.and(U32.is_eq(F32.bits(F32.hypot(y, x)), want),
      Bool.and(U32.is_eq(F32.bits(F32.hypot(F32.neg(x), y)), want),
        U32.is_eq(F32.bits(F32.hypot(x, F32.neg(y))), want))))

def nan(+x: F32) -> Bool:
  F32.is_ne(x, x)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(Bool.show(check(2.22e38, 2.578916e38, 2139095039)))
    IO.print(Bool.show(check(3.4028235e38, 1.0e35, 2139095040)))
    # One input step below, exactly at, and one step above the midpoint.
    IO.print(Bool.show(check(3.174205215935328e38, 1.2262256040296352e38,
      2139095039)))
    IO.print(Bool.show(check(3.174205215935328e38, 1.2262257054416832e38,
      2139095040)))
    IO.print(Bool.show(check(3.174205215935328e38, 1.2262258068537312e38,
      2139095040)))
    # A large exponent gap and zero must still give a finite result.
    IO.print(Bool.show(check(3.4028235e38, 4.153837486827862e34, 2139095039)))
    IO.print(Bool.show(check(3.4028235e38, 0.0, 2139095039)))
    IO.print(Bool.show(check(3.4028235e38, 3.4028235e38, 2139095040)))
    IO.print(Bool.show(check(F32.div(1.0, 0.0), 3.4028235e38, 2139095040)))
    IO.print(Bool.show(nan(F32.hypot(F32.div(0.0, 0.0), 3.4028235e38))))
    IO.print(Bool.show(nan(F32.hypot(3.4028235e38, F32.div(0.0, 0.0)))))

#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
#|True
