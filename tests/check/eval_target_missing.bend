# a reference to a name the file does not define is refused with the
# missing name.
# ported from bend3: bend has no --eval target, so the missing name
# sits in main's body
import Base

law alpha:
  U32

def alpha():
  1

law main:
  U32

def main(): gamma

#|Error:
#|- expected : a defined name
#|- observed : gamma
#|Location: main
#|15 | 
#|16>| def main(): gamma
#|   |             ^^^^^
#|17 |
#|exit 1
