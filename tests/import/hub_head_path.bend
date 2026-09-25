# a 0x.. head names a hub package, and only the hub's own files carry
# it: ../0x<hash>/f.bend from a local directory took the package's
# namespace and could rewrite what it means (#1005); the import line
# refuses the path before the file is opened
import Base
import ../0x0123456789abcdef0123456789abcdef/f.bend as F

def main() -> U32:
  0

#|Error:
#|- expected : an import path of plain names (letters, digits, _ and -; the hub's files import the hub's)
#|- observed : '../0x0123456789abcdef0123456789abcdef/f.bend'
#|Location:
#|5 | import Base
#|6>| import ../0x0123456789abcdef0123456789abcdef/f.bend as F
#|  |        ^
#|7 |
#|exit 1
