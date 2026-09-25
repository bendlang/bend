# bend3's buffer literal rejected duplicate keys; bend has no buffer
# literal -- [..] is the list literal, where a key's ':' has no
# reading and the spelling dies at parse
import Base

law main:
  List<&2, U32>

def main():
  [0:1,0:2,_:0;2]

#|Error:
#|- expected : '^'
#|- observed : ','
#|Location:
#| 9 | def main():
#|10>|   [0:1,0:2,_:0;2]
#|   |       ^
#|11 |
#|exit 1
