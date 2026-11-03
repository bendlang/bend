# Comments, strings and skipped includes do not select native dependencies.
import Base

def Native.ignored() -> IO(U32):
  import "./native_build_ignored.js"

def main() -> IO(Unit):
  do IO<Unit>:
    n : U32 <- Native.ignored()
    IO.print(U32.show(n))

#|0
