import Base

def FatalCleanup.test() -> IO(U32):
  import "./fatal_cleanup.c"
  import "./fatal_cleanup.js"

def main() -> IO(Unit):
  do IO<Unit>:
    result : U32 <- FatalCleanup.test()
    IO.print(U32.show(result))

#|0
