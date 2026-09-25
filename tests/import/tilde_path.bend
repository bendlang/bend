# a ~ key is the checker's own (a template's opaque k~x, an instance
# k~n): law.k~B.bend was the namespace law.k~B, and its x the key of
# law.k's opaque ~B.x, which a later def x then filled with a Type
# (#994); the import line refuses the path before the file is opened
import Base
import ./law.k~B.bend as E

def main() -> U32:
  0

#|Error:
#|- expected : an import path of plain names (letters, digits, _ and -; the hub's files import the hub's)
#|- observed : './law.k~B.bend'
#|Location:
#|5 | import Base
#|6>| import ./law.k~B.bend as E
#|  |        ^
#|7 |
#|exit 1
