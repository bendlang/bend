# an untyped do-block let after another statement is refused at its `=`,
# not on the statement before it, where the leftover `= v` used to
# surface as "a pattern (a binder or a constructor)" (#1868)
import Base

def pure_of() -> Nat:
  5n

def f() -> IO(Unit):
  do IO<Unit>:
    IO.print("a")
    x = pure_of()
    IO.print("ok")
    return Unit{}

def main() -> IO(Unit):
  f()
#|SOME PROOFS FAIL
#|Error:
#|- expected : a do-block let with its type (write "x : T = ...")
#|- observed : '='
#|Location:
#|11 |     IO.print("a")
#|12>|     x = pure_of()
#|   |       ^
#|13 |     IO.print("ok")
#|exit 1
