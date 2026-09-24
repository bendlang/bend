# a key is a namespace, a dot and a name, so a namespace has no dot of
# its own: LAWS.Nat.bend was the namespace LAWS.Nat, its def add the key
# LAWS.Nat.add, and LAWS.bend's Nat.add resolved to it (#1002); the
# import line refuses the path before the file is opened
import Base
import ./LAWS.Nat.bend as H

def main() -> U32:
  0

#|Error:
#|- expected : an import path of plain names (letters, digits, _ and -; the hub's files import the hub's)
#|- observed : './LAWS.Nat.bend'
#|Location:
#|5 | import Base
#|6>| import ./LAWS.Nat.bend as H
#|7 |
#|exit 1
