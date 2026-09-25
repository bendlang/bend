# the dotted-both-sides .+. is no operator (a float chain is spelled
# by its ": F32" suffix): it dies at its leading dot, which no infix
# owns
import Base

law main:
  F32

def main():
  1.0 .+. 2.0

#|Error:
#|- expected : 'def', 'type' or 'law'
#|- observed : '.'
#|Location:
#| 9 | def main():
#|10>|   1.0 .+. 2.0
#|   |       ^
#|11 |
#|exit 1
