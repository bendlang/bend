import Base

def Cli.output_operand() -> IO(U32):
  import "./cli_output_operand.js"

def main() -> IO(Unit):
  do IO<Unit>:
    n : U32 <- Cli.output_operand()
    IO.print(U32.show(n))

#|0
