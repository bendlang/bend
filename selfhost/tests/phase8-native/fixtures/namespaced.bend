import Base
import ./tags.bend as M

type Other is Data:
  Pick{}

def answer() -> U32:
  7

def main() -> IO(Unit):
  do IO<Unit>:
    a : M.Token <- M.get(0)
    Unit <- IO.print(M.show(a))
    b : M.Token <- M.get(1)
    Unit <- IO.print(M.show(b))
    IO.print(U32.show(M.answer()))

#|upper
#|lower
#|42
