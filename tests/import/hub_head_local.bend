# a path spelled ./ is local, however it goes on: ./0x<hash>/f.bend once
# went to the hub store (a cached package in place of the local file, or
# a fetch), where a local 0x.. head is refused as ../0x.. is
import Base
import ./0x0123456789abcdef0123456789abcdef/f.bend as F

def main() -> U32:
  0

#|Error:
#|- expected : an import path of plain names (letters, digits, _ and -; the hub's files import the hub's)
#|- observed : './0x0123456789abcdef0123456789abcdef/f.bend'
#|Location:
#|4 | import Base
#|5>| import ./0x0123456789abcdef0123456789abcdef/f.bend as F
#|  |        ^
#|6 |
#|exit 1
