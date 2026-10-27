# an exec statement whose type is a lowercase type variable is still the
# exec form: the lost-type note only ever joins an error (#1787)
import Base

def f(-a: Type, x: a) -> IO(Unit):
  do IO<Unit>:
    a <- IO.pure(a, x)
    IO.print("ok")

def main() -> IO(Unit):
  f(U32, 1)

#|ok
