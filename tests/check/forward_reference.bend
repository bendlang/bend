# term-level forward references FAIL as undefined: resolution follows
# book order.
# ported from bend3: bend3 ratified forward refs (C27); bend pins the
# refusal (the descent wall needs order)
import Base

law main:
  U32

def main(): later

law later:
  U32

def later(): 0

#|Error:
#|- expected : a defined name
#|- observed : later
#|Location: main
#| 9 | 
#|10>| def main(): later
#|11 |
#|exit 1
