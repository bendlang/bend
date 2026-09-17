# a compile-time argument naming a def declared later: the name is a
# free Var at the call, a Ref at the raise, and the instance validates
# before that def, so it is undefined there, as for any forward call;
# the ~ name is answered as a Ref carrying the use's span, so the window
# is f(x) inside app
import Base

def app(~f: Nat -> Nat, x: Nat) -> Nat:
  f(x)

def main() -> Nat:
  app(~later, 3n)

def later(n: Nat) -> Nat:
  Nat.mul(n, 10n)

#|Error:
#|- expected : a defined name
#|- observed : later
#|Context:
#|- f : @_:Nat -> Nat
#|- x : Nat
#|Location: app~0
#| 8 | def app(~f: Nat -> Nat, x: Nat) -> Nat:
#| 9>|   f(x)
#|10 |
#|exit 1
