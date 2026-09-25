# bend3's Parser lexer kit (char/digit/or/read) is absent from bend's
# base: the head call is an undefined name
import Base

law main:
  U32

def main():
  Parser.read(U32, Parser.digit(), "7")

#|Error:
#|- expected : a defined name
#|- observed : Parser.read
#|Location: main
#| 8 | def main():
#| 9>|   Parser.read(U32, Parser.digit(), "7")
#|   |   ^^^^^^^^^^^
#|10 |
#|exit 1
