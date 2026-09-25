# bend3's Parser repetition combinators (many/sep_by) are absent from
# bend's base: the head call is an undefined name
import Base

law main:
  U32

def main():
  Parser.many(U32, Parser.digit())

#|Error:
#|- expected : a defined name
#|- observed : Parser.many
#|Location: main
#| 8 | def main():
#| 9>|   Parser.many(U32, Parser.digit())
#|   |   ^^^^^^^^^^^
#|10 |
#|exit 1
