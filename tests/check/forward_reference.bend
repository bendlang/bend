# term-level forward references FAIL: a def below is a bodiless claim
# to live code, as an unfilled law, so book order rules.
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
#|- expected : a filled definition (an unfilled law is a dead claim: live code cannot use it)
#|- observed : later
#|Location: main
#| 9 | 
#|10>| def main(): later
#|   |             ^^^^^
#|11 |
#|exit 1
