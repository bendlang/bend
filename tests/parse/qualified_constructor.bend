# bend3 ratified namespaced constructors (Nat.S{..} legal everywhere);
# bend inverts the law by design -- ctor names are bare and globally
# unique, and the qualified spelling asks for the declared ones
import Base

law main:
  Nat

def main():
  Nat.Succ{Zero{}}

#|Error:
#|- expected : a declared constructor (Nat declares Zero, Succ)
#|- observed : Nat.Succ{0n}
#|Location: main
#| 9 | def main():
#|10>|   Nat.Succ{Zero{}}
#|   |   ^^^^^^^^^^^^^^^^
#|11 |
#|exit 1
