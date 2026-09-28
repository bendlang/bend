import Base
import ./tags.bend as A
import ./tags.bend as B

def main() -> IO(Unit):
  do IO<Unit>:
    a : A.Token <- A.get(0)
    Unit <- IO.print(A.show(a))
    b : B.Token <- B.get(1)
    IO.print(B.show(b))
