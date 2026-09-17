# a missing ~ at a template head instantiates with fewer arguments: the
# unfilled ~f binds as an erased runtime parameter, and the instance's
# live use of it is the checker's to refuse
import Base

def app(~f: Nat -> Nat, x: Nat) -> Nat:
  f(x)

def main() -> Nat:
  app(Nat.add(1n), 3n)

#|Error:
#|- expected : -f
#|- observed : f
#|Location: app~0
#|5 | 
#|6>| def app(~f: Nat -> Nat, x: Nat) -> Nat:
#|7 |   f(x)
#|exit 1
