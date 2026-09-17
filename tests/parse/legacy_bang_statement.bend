# audit: the legacy `! x = v;` statement spelling is gone from the
# grammar: '!' is a plain parse error at a term position.
# ported from bend3: bend has no ![..] buffer form either, so the page
# is the bare term refusal
import Base

law main:
  U32

def main(): ! x = 1; x

#|Error:
#|- expected : a term
#|- observed : '!'
#|Location:
#| 9 | 
#|10>| def main(): ! x = 1; x
#|11 |
#|exit 1
