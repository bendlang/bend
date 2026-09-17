# the a2 shape: a caller's local x inside a ~ argument while a def x
# exists; the argument is open, so the call stays a plain call of the
# template's name and the checker refuses it: no global capture
import Base

def x() -> Nat:
  100n

def app(~f: Nat -> Nat, y: Nat) -> Nat:
  f(y)

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
#|12 | def g(x: Nat) -> Nat:
#|13>|   app(~(y => Nat.add(y, x)), 1n)
#|14 |
#|exit 1
