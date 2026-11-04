# A translator stack error names its definition and preserves the output file.
import Base

def Verdict.translation_error() -> IO(U32):
  import "./verdict_translation_error.js"

def main() -> IO(Unit):
  do IO<Unit>:
    result : U32 <- Verdict.translation_error()
    IO.print(U32.show(result))

#|0
