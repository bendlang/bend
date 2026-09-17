# a caller's local inside a ~ argument (x here, g's parameter) makes the
# argument open: the call stays a plain call of the template's name, and
# the checker refuses that name at the call (pass x at run time instead)
import Base

def app(~f: Nat -> Nat, x: Nat) -> Nat:
  f(x)

def g(x: Nat) -> Nat:
  app(~(y => Nat.add(y, x)), 1n)

def main() -> Nat:
  g(3n)

#|Error:
#|- expected : a defined name
#|- observed : app
#|Context:
#|- x : Nat
#|Location: g
#| 9 | def g(x: Nat) -> Nat:
#|10>|   app(~(y => Nat.add(y, x)), 1n)
#|11 |
#|exit 1
