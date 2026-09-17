# a wrong-typed argument: the instance validates before its caller, so
# the checker fails inside app~0, where Bool.not meets x : Nat
import Base

def app(~f: Nat -> Nat, x: Nat) -> Nat:
  f(x)

def main() -> Nat:
  app(~Bool.not, 3n)

#|Error:
#|- expected : Bool
#|- observed : Nat
#|Context:
#|- f : @_:Nat -> Nat
#|- x : Nat
#|Location: app~0
#|5 | def app(~f: Nat -> Nat, x: Nat) -> Nat:
#|6>|   f(x)
#|7 | 
#|exit 1
