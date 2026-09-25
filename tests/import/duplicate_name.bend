# bend3 refused duplicate def names across its one global namespace;
# bend imports are namespaced per file and the wall moved: the
# collision fires against the imported book itself -- redeclaring a
# base def dies as an ordinary duplicate
import Base

law Nat.add:
  for a: Nat
  for b: Nat
  Nat

def Nat.add(a, b):
  a

law main:
  U32

def main():
  0

#|Error:
#|- expected : a fresh name (duplicate declaration: Nat.add)
#|- observed : 'Nat.add'
#|Location:
#|6 | 
#|7>| law Nat.add:
#|  |     ^^^^^^^
#|8 |   for a: Nat
#|exit 1
