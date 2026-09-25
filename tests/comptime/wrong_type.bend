# a wrong-typed argument: a ~ argument checks at the call against the
# template's generic domain, so the checker fails in main, where Bool.not
# meets Nat -> Nat
import Base

def app(~f: Nat -> Nat, x: Nat) -> Nat:
  f(x)

def main() -> Nat:
  app(~Bool.not, 3n)

#|Error:
#|- expected : @_:Nat -> Nat
#|- observed : @b:Bool -> Bool
#|Location: main
#| 9 | def main() -> Nat:
#|10>|   app(~Bool.not, 3n)
#|   |        ^^^^^^^^
#|11 |
#|exit 1
