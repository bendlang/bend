# each segment of an import path is a name, and a name starts with a letter
# or _, so ./2d/x.bend is refused on its spelling, before the file is opened
# (#1961: the message once listed digits and not where they may go)
import Base
import ./2d/x.bend as X

def main() -> U32:
  0

#|SOME PROOFS FAIL
#|Error:
#|- expected : an import path of plain names (each starts with a letter or _, then letters, digits, _ and -)
#|- observed : './2d/x.bend'
#|Location:
#|4 | import Base
#|5>| import ./2d/x.bend as X
#|  |        ^
#|6 |
#|exit 1
