# special values: overflow and division reach inf, 0/0 is nan, negation
# makes -0; the smallest subnormal prints as 5e-324; 1e-7 takes the
# scientific form, 1e21 sits exactly on the cutover (also scientific)
import Base

law main:
  IO(Unit)

def main():
  do IO<Unit>:
    IO.print(F64.show(F64.mul(1.0e308d, 10.0d)))
    IO.print(F64.show(F64.div(1.0d, 0.0d)))
    IO.print(F64.show(F64.div(0.0d, 0.0d)))
    IO.print(F64.show(F64.neg(0.0d)))
    IO.print(F64.show(5.0e-324d))
    IO.print(F64.show(1.0e-7d))
    IO.print(F64.show(1.0e21d))

#|inf
#|inf
#|nan
#|-0
#|5e-324
#|1e-7
#|1e+21
