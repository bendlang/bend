# ~ in a non-leading position of a def is refused where it is written:
# only leading binders take ~ (a template's ~ parameters lead)
import Base

def keep(x: Nat, ~k: Nat) -> Nat:
  x

def main() -> IO(Unit):
  IO.print(Nat.show(keep(3n, 5n)))

#|Error:
#|- expected : a plain binder (only leading binders take ~)
#|- observed : '~'
#|Location:
#|4 |
#|5>| def keep(x: Nat, ~k: Nat) -> Nat:
#|  |                  ^
#|6 |   x
#|exit 1
