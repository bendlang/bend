# borrow witness: a consuming native fed a held value. IO.print is a
# foreign request, an owned position: Twice~0 is owned and the first print
# keeps s (one term_keep in the C, String hot).
import Base

def Twice(+s: String) -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(s)
    IO.print(s)

def main() -> IO(Unit):
  Twice("hi")

#|hi
#|hi
