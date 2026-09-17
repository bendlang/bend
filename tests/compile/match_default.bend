# Witness for emit_match's default arm.
#
# rank matches one constructor of three and catches the rest with a
# default, so emit_match reaches end !== null: the partial ladder, the
# `} else {` that runs the default, and fin over the default's own use
# counts. Every match in bench/ is total with an Efq tail, so none of
# that path is otherwise exercised.
#
# Expect 0n: Blue takes the default arm.

import Base

type Colour is Data:
  Red{}
  Green{}
  Blue{}

law rank:
  for c: Colour
  Nat

def rank(c):
  match c:
    case Red{}:
      1n
    case _:
      0n

law main.out:
  Nat

def main.out():
  rank(Blue{})

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|0n
