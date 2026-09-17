# the same macro under a bare domain: the duplicated x is consumed
# twice, and the usage rule rejects it inside the instance app~0, at
# the binder's span (a use points at its binder)
import Base

def app(~f: Nat -> Nat, x: Nat) -> Nat:
  f(x)

def main() -> Nat:
  app(~(y => Nat.add(y, y)), 3n)

#|Error:
#|- expected : x
#|- observed : x (consumed more than once)
#|Context:
#|- f : @_:Nat -> Nat
#|Location: app~0
#|5 | 
#|6>| def app(~f: Nat -> Nat, x: Nat) -> Nat:
#|7 |   f(x)
#|exit 1
