# Native dependencies follow active directives, including comments and macros:
# Objective-C frameworks on macOS, and X11/ALSA libraries on Linux.
import Base

law answer:
  IO(U32)

def answer():
  import "./effect_framework.c"
  import "./effect_framework.js"

def main() -> IO(Unit):
  do IO<Unit>:
    n : U32 <- answer()
    IO.print(U32.show(n))

#|5
