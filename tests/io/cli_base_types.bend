import Base

def Cli.base_types() -> IO(U32):
  import "./cli_base_types.js"

def main() -> IO(Unit):
  do IO<Unit>:
    n : U32 <- Cli.base_types()
    IO.print(U32.show(n))

#|0
