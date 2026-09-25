# `()` is not a term: bend has no empty-tuple sugar, so the closing
# paren fails at the term position.
# ported from bend3: bend3 desugared () to U{}; bend pins the refusal
import Base

law main:
  U32

def main(): ()

#|Error:
#|- expected : a term
#|- observed : ')'
#|Location:
#| 8 | 
#| 9>| def main(): ()
#|   |              ^
#|10 |
#|exit 1
