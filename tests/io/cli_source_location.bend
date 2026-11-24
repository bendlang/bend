# A CLI error names the file, line and column of the source text, also in a
# def with a ~ parameter.
import Base

def Cli.source_location() -> IO(U32):
  import "./cli_source_location.js"

def main() -> IO(Unit):
  do IO<Unit>:
    result : U32 <- Cli.source_location()
    IO.print(U32.show(result))

#|0
