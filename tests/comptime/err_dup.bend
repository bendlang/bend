# a template takes its name like a def: a second declaration is refused
import Base

def app(~f: Nat -> Nat, x: Nat) -> Nat:
  f(x)

def app(~f: Nat -> Nat, x: Nat) -> Nat:
  f(x)

#|Error:
#|- expected : a fresh name (duplicate declaration: app)
#|- observed : 'app'
#|Location:
#|6 | 
#|7>| def app(~f: Nat -> Nat, x: Nat) -> Nat:
#|  |     ^^^
#|8 |   f(x)
#|exit 1
