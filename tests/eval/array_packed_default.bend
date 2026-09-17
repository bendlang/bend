# no array literal and no defaults: [..] builds a List, and a List is
# not an Array -- the checker refuses the shape bend3's packed slab
# literal filled with materialized defaults
import Base

law main:
  Array<U32>

def main():
  [1, 2]

#|Error:
#|- expected : Array<U32>
#|- observed : List
#|Location: main
#| 9 | def main():
#|10>|   [1, 2]
#|11 |
#|exit 1
