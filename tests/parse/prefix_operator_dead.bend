# no prefix operators: a leading - in term position heads an erased
# let and demands a binder name, not a number (bend3's prefix ops are
# equally dead, by a different wall)
import Base

law main:
  U32

def main():
  -5

#|Error:
#|- expected : a name
#|- observed : '5'
#|Location:
#| 9 | def main():
#|10>|   -5
#|   |    ^
#|11 |
#|exit 1
