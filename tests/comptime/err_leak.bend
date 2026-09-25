# a caller's local inside a ~ argument (x here, g's parameter) makes the
# argument open: a ~ argument checks in the empty context, where x is
# unbound, and the checker refuses it there (pass x at run time instead)
import Base

def app(~f: Nat -> Nat, x: Nat) -> Nat:
  f(x)

def g(x: Nat) -> Nat:
  app(~(y => Nat.add(y, x)), 1n)

def main() -> Nat:
  g(3n)

#|Error:
#|- expected : a template applied to closed ~ arguments (x is a variable here, not comptime: pass it at run time)
#|- observed : app
#|Context:
#|- x : Nat
#|Location: g
#| 9 | def g(x: Nat) -> Nat:
#|10>|   app(~(y => Nat.add(y, x)), 1n)
#|   |   ^^^
#|11 |
#|exit 1
