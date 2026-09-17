# the cons tail must be a list of the head's type: <> is Con, and the
# checker holds its telescope (bend3 pinned the same wall on its sugar)
import Base

law main:
  List<&2, U32>

def main():
  1 <> 2

#|Error:
#|- expected : List<&2, U32>
#|- observed : U32
#|Location: main
#| 8 | def main():
#| 9>|   1 <> 2
#|10 |
#|exit 1
