# a + on a name in term position is a parser marker for a reusable
# binder, not a term: inside a ~ argument it is refused as it is
# everywhere, not as an open argument (the lambda's y is closed)
import Base

def app(~f: Nat -> Nat, x: Nat) -> Nat:
  f(x)

def g(x: Nat) -> Nat:
  app(~(y => +y), x)

def main() -> Nat:
  g(1n)

#|Error:
#|- expected : a bound variable
#|- observed : y^-1
#|Context:
#|- y : Nat
#|Location: g
#| 9 | def g(x: Nat) -> Nat:
#|10>|   app(~(y => +y), x)
#|   |              ^^
#|11 |
#|exit 1
