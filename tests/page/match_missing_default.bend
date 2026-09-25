# an empty match on U32 is not total. bend3's hint asked for the number
# match's default case; bend's U32 is a plain wrapper datatype, so the
# same \{} asks for its one constructor instead
import Base

law main:
  @n:U32 -> U32

def main():
  \{}

#|Error:
#|- expected : cases for U32
#|- observed : \{}
#|Location: main
#| 9 | def main():
#|10>|   \{}
#|   |   ^^^
#|11 |
#|exit 1
