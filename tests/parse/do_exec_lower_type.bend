# a type with a lowercase name, declared after its use, is a type: `foo <- m`
# is the exec form, and the lost-type note only ever joins an error (#1787)
import Base

def main() -> IO(Unit):
  do IO<Unit>:
    foo <- IO.pure(foo, Mkfoo{})
    IO.print("ok")

type foo is Type:
  Mkfoo{}

#|ok
