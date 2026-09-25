# a constructor unknown to the goal datatype: the error lists the
# datatype's constructors instead of a bare type mismatch
type MB is Data:
  T{}
  F{}
law main:
  MB

def main(): Tru{}

#|Error:
#|- expected : a declared constructor (MB declares T, F)
#|- observed : Tru{}
#|Location: main
#| 8 | 
#| 9>| def main(): Tru{}
#|   |             ^^^^^
#|10 |
#|exit 1
