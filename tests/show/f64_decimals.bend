# F64.show: the shortest decimal that reads back, with the JS thresholds
# (fixed below 1e21, exponent form at or past it); add(0.1, 0.2) at full
# binary64 length, and 1e16 swallowing the +1
import Base

law main:
  IO(Unit)

def main():
  do IO<Unit>:
    IO.print(F64.show(F64.add(0.1d, 0.2d)))
    IO.print(F64.show(F64.div(1.0d, 3.0d)))
    IO.print(F64.show(F64.sqrt(2.0d)))
    IO.print(F64.show(F64.pi()))
    IO.print(F64.show(1.0e16d))
    IO.print(F64.show(F64.add(1.0e16d, 1.0d)))

#|0.30000000000000004
#|0.3333333333333333
#|1.4142135623730951
#|3.141592653589793
#|10000000000000000
#|10000000000000000
