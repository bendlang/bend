# bend3's unclosed backquote char-code scanned to end of input (the
# fixture lived in a second file); bend has no backquote word at all,
# so the tick dies in place and needs no fixture
import Base

law main:
  U32

def main():
  `a

#|Error:
#|- expected : a term
#|- observed : '`'
#|Location:
#| 9 | def main():
#|10>|   `a
#|11 |
#|exit 1
