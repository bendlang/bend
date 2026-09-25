# a name that two files of an imported folder both declare is refused
# where it is used: the alias cannot pick one
import Base
import ./folder-clash as C

def main() -> Nat:
  C.two()

#|Error:
#|- expected : an unambiguous name (C.two is declared by more than one file of the folder C)
#|- observed : '('
#|Location:
#|6 | def main() -> Nat:
#|7>|   C.two()
#|8 |
#|exit 1
