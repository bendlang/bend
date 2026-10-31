# a compile-time argument naming a def declared later: the argument
# checks dead, but the instance calls the def live, and a def below is
# refused by the ordering rule (#1782)
import Base

def app(~f: Nat -> Nat, x: Nat) -> Nat:
  f(x)

def main() -> Nat:
  app(~later, 3n)

def later(n: Nat) -> Nat:
  Nat.mul(n, 10n)

#|SOME PROOFS FAIL
#|Error:
#|- expected : a def written above app~0 (move later above its first caller)
#|- observed : later
#|Context:
#|- x : Nat
#|Location: app~0
#| 9 | def main() -> Nat:
#|10>|   app(~later, 3n)
#|   |        ^^^^^
#|11 |
#|exit 1
