# A valid host Char crosses first. A two-code-point answer cannot become
# a Char merely because the backend represents both Char and String as strings.
import Base

def star() -> IO(Char):
  import "./char_host_width.js"

def wide(c: Char) -> IO(Char):
  import "./char_host_width.js"

def main() -> IO(Unit):
  do IO<Unit>:
    +a : Char <- star()
    u : Unit <- IO.print(Char.show(a))
    b : Char <- wide(a)
    IO.print(Char.show(b))

#|g
#|bend: expected one Unicode scalar Char
#|exit 1
