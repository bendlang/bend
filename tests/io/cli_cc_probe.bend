import Base

def Cli.cc_probe() -> IO(U32):
  import "./cli_cc_probe.js"

def main() -> IO(Unit):
  do IO<Unit>:
    n : U32 <- Cli.cc_probe()
    IO.print(U32.show(n))

#|0
