# ~ after a runtime argument: a template head reads its ~ arguments at
# the leading positions only, so a later ~ heads no term
import Base

def app(~f: Nat -> Nat, x: Nat, y: Nat) -> Nat:
  f(Nat.add(x, y))

def main() -> Nat:
  app(~Nat.add(1n), 3n, ~4n)

#|Error:
#|- expected : a term
#|- observed : '~'
#|Location:
#| 8 | def main() -> Nat:
#| 9>|   app(~Nat.add(1n), 3n, ~4n)
#|10 |
#|exit 1
