# a def named like a Base def is a duplicate of it, in the root namespace
# and in a module alike: a module's Nat.add once stood apart from Base's,
# and the module's Nat.add meant Base's above it and its own below
import Base

def Nat.add(a: Nat, b: Nat) -> Bool:
  True{}

#|Error:
#|- expected : a fresh name (duplicate declaration: Nat.add)
#|- observed : 'Nat.add'
#|Location:
#|5 | 
#|6>| def Nat.add(a: Nat, b: Nat) -> Bool:
#|  |     ^^^^^^^
#|7 |   True{}
#|exit 1
