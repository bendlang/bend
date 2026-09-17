# a comparison answers Bool, not a word: the result feeds no
# arithmetic without an explicit if (bend3's checker bridged them)
import Base

law main:
  U32

def main():
  ((1 < 2) + 5 : U32)

#|Error:
#|- expected : U32
#|- observed : Bool
#|Location: main
#| 8 | def main():
#| 9>|   ((1 < 2) + 5 : U32)
#|10 |
#|exit 1
