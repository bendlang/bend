# Only the left module's effect is reachable; sharing its source with an
# unused right module must not invent a namespace conflict.
import Base
import ./tags_left.bend as A
import ./tags_right.bend as B

def main() -> IO(Unit):
  do IO<Unit>:
    a : A.Token <- A.get(0)
    Unit <- IO.print(A.show(a))
    IO.print(U32.show(A.answer()))

#|upper
#|42
