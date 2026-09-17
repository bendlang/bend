# the + binder on a lambda (+x => body) and on a do bind and a do let
import Base

def sq(f: U32 -> U32, x: U32) -> U32:
  f(x)

def main() -> IO(Unit):
  do IO<Unit>:
    +n : U32 <- IO.pure(U32, 7)
    +k : U32 = 3
    IO.print(U32.show((n * n + k * k : U32)))
    IO.print(U32.show(sq(+x => (x * x : U32), n)))

#|58
#|49
