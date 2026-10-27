# a do-block bind written without its type reads x as the type of m's
# result; the error says so in a note, after "a defined name" for x (#1787)
import Base

def main() -> IO(Unit):
  do IO<Unit>:
    x <- IO.pure(U32, 1)
    IO.print(U32.show(x))

#|SOME PROOFS FAIL
#|Error:
#|- expected : a defined name
#|- observed : x
#|Location: main
#|6 |   do IO<Unit>:
#|7>|     x <- IO.pure(U32, 1)
#|  |     ^
#|8 |     IO.print(U32.show(x))
#|Note: in a do-block, x <- m runs m at type x; to bind its result, write x : A <- m.
#|exit 1
