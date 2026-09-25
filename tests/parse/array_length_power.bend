# bend3's slab-array literal with a length tail is gone: [..] is the
# list literal and ; ends no element -- refused by the grammar
import Base

law main:
  U32

def main():
  m = [7; 16]
  0

#|Error:
#|- expected : a term
#|- observed : ';'
#|Location:
#| 8 | def main():
#| 9>|   m = [7; 16]
#|   |         ^
#|10 |   0
#|exit 1
