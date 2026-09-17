# error census: an arm tag NO datatype declares, matched over U32 --
# the page asks for a constructor of the scrutinee's type
import Base
law main:
  U32 -> U32

def main(): \{Qux: 3}

#|Error:
#|- expected : a constructor of U32 (missing, or already matched)
#|- observed : \{Qux: 3}
#|Location: main
#|6 |
#|7>| def main(): \{Qux: 3}
#|8 |
#|exit 1
