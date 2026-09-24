# a name is words joined by dots: no empty segment and none led by a
# digit, so a key has one spelling
import Base

def Vec.2d() -> U32:
  0

def main() -> U32:
  Vec.2d()

#|Error:
#|- expected : a name (words joined by dots, got 'Vec.2d')
#|- observed : '('
#|Location:
#|4 |
#|5>| def Vec.2d() -> U32:
#|6 |   0
#|exit 1
