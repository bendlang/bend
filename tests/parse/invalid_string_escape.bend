# error census: an unknown escape in a string literal is a located
# Syntax page.
# ported from bend3: String comes from Base (no backquote char-codes)
import Base

law x:
  String

def x(): "a\qb"

law main:
  U32

def main(): 0

#|Error:
#|- expected : an escape (\n \t \r \0 \\ \' \" \u{1F600})
#|- observed : 'b'
#|Location:
#| 8 | 
#| 9>| def x(): "a\qb"
#|10 |
#|exit 1
