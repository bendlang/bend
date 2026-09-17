# a template is declared above its first use: before it, its name is no
# template head, so its ~ heads no term
import Base

def main() -> Nat:
  app(~Nat.add(1n), 3n)

def app(~f: Nat -> Nat, x: Nat) -> Nat:
  f(x)

#|Error:
#|- expected : a term
#|- observed : '~'
#|Location:
#|5 | def main() -> Nat:
#|6>|   app(~Nat.add(1n), 3n)
#|7 |
#|exit 1
