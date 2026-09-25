# a ~ argument past the template's ~ parameters heads no term: the call
# writes at most one ~ per ~ parameter
import Base

def app(~f: Nat -> Nat, x: Nat) -> Nat:
  f(x)

def main() -> Nat:
  app(~Nat.add(1n), ~3n)

#|Error:
#|- expected : a term (app takes 1 ~)
#|- observed : '~'
#|Location:
#| 8 | def main() -> Nat:
#| 9>|   app(~Nat.add(1n), ~3n)
#|   |                     ^
#|10 |
#|exit 1
