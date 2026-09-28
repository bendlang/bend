import Base
law get:
  IO(U32)
def get():
  import "./unknown.c"
def main() -> IO(Unit):
  do IO<Unit>:
    n : U32 <- get()
    IO.print(U32.show(n))
