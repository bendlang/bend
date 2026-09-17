# over-application: the page states the head's actual type
import Base
law id:
  U32 -> U32

def id(): x => x
law main:
  U32

def main(): id(1, 2)

#|Error:
#|- expected : a function type
#|- observed : U32
#|Location: main
#| 9 | 
#|10>| def main(): id(1, 2)
#|11 |
#|exit 1
