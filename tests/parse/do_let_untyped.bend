# a do-block let written without its type is refused at its `=`, with
# the typed form (#1787)
import Base

def main() -> IO(Unit):
  do IO<Unit>:
    x = 1
    IO.print(U32.show(x))

#|SOME PROOFS FAIL
#|Error:
#|- expected : a do-block let with its type (write "x : T = ...")
#|- observed : '='
#|Location:
#|6 |   do IO<Unit>:
#|7>|     x = 1
#|  |       ^
#|8 |     IO.print(U32.show(x))
#|exit 1
