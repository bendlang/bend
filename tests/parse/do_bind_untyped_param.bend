# the same bind on a name that exists: "expected Type, observed U32" gets
# the note that x <- m runs m at type x (#1787)
import Base

def f(n: U32) -> IO(Unit):
  do IO<Unit>:
    n <- IO.pure(U32, 1)
    IO.print(U32.show(n))

def main() -> IO(Unit):
  f(2)

#|SOME PROOFS FAIL
#|Error:
#|- expected : Type
#|- observed : U32
#|Context:
#|- n : U32
#|Location: f
#|6 |   do IO<Unit>:
#|7>|     n <- IO.pure(U32, 1)
#|  |     ^
#|8 |     IO.print(U32.show(n))
#|Note: in a do-block, n <- m runs m at type n; to bind its result, write n : A <- m.
#|exit 1
