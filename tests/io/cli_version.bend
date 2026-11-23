import Base

def Cli.version() -> IO(U32):
  import "./cli_version.js"

def main() -> IO(Unit):
  do IO<Unit>:
    n : U32 <- Cli.version()
    IO.print(U32.show(n))

#|0
