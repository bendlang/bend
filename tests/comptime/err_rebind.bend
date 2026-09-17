# a binder form on a ~ name inside the template (the let f = ..) is refused:
# the name stands for its argument (inc, a def name read as a Ref), and a
# Ref is no pattern; before, the let bound inc and f stayed the argument
import Base

def inc(n: Nat) -> Nat:
  1n+n

def app(~f: Nat -> Nat, x: Nat) -> Nat -> Nat:
  f = Nat.add(x)
  f

def main() -> Nat:
  app(~inc, 10n)(1n)

#|Error:
#|- expected : a pattern (a binder or a constructor)
#|- observed : inc
#|Location:
#| 9 | def app(~f: Nat -> Nat, x: Nat) -> Nat -> Nat:
#|10>|   f = Nat.add(x)
#|11 |   f
#|exit 1
