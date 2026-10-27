# a do-block let takes its type (`x : T = v`, the grammar's DoLet); an
# untyped `x = v`, or a destructure like `(a, b) = v`, is refused at its
# `=`, not on the statement before it, where the leftover `= v` used to
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
#|12 |     IO.print("a")
#|13>|     x = pure_of()
#|   |       ^
#|14 |     IO.print("ok")
#|exit 1
