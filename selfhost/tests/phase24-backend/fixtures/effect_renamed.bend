import Base

type T is Data:
  Tick{}

def Tock() -> IO(U32):
  import "./effect_renamed.js"
  import "./effect_renamed.c"

def main() -> IO(Unit):
  do IO<Unit>:
    n : U32 <- Tock()
    IO.print(U32.show(n))

#|7
