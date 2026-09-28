import Base
def main() -> IO(Unit):
  do IO<Unit>:
    x : U32 = 4
    IO.print(U32.show(x))
