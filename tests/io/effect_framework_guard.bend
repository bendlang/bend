# A successful C probe does not parse the Objective-C body.
import Base

def Framework.guard() -> IO(U32):
  import "./effect_framework_guard.c"
  import "./effect_framework_guard.js"

def main() -> IO(Unit):
  do IO<Unit>:
    n : U32 <- Framework.guard()
    IO.print(U32.show(n))

#|5
