import Base

type T is Data:
  Left.Tick{}

def Right.Tick() -> IO(U32):
  import "./effect_qualified_apart.js"
  import "./effect_qualified_apart.c"

def main() -> IO(Unit):
  do IO<Unit>:
    n : U32 <- Right.Tick()
    IO.print(U32.show(n))

#|7
