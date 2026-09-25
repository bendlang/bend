# ^ is no operator (bitwise xor is dotted, .^.): after a full term the
# parser closes the def and a bare caret is refused at the top level
import Base

law main:
  U32

def main():
  1 ^ 2

#|Error:
#|- expected : 'def', 'type' or 'law'
#|- observed : '^'
#|Location:
#| 8 | def main():
#| 9>|   1 ^ 2
#|   |     ^
#|10 |
#|exit 1
