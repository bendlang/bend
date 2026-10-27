# a do-block let written without its type: the pattern error gets a note
# that a let names its type (#1787)
import Base

def main() -> IO(Unit):
  do IO<Unit>:
    x = 1
    IO.print(U32.show(x))

#|SOME PROOFS FAIL
#|Error:
#|- expected : a pattern (a binder or a constructor)
#|- observed : {x : IO(Unit)}
#|Location:
#|6 |   do IO<Unit>:
#|7>|     x = 1
#|  |     ^
#|8 |     IO.print(U32.show(x))
#|Note: in a do-block, a let names its type: x : A = v.
#|exit 1
