# audit: a datatype header carries its kind: `type K is Kind(g):` (or
# `type K<..> is Kind(g):`) is the only form, so a bare `type K:` fails
# at the missing 'is'.
# ported from bend3: the law flipped with the grade kernel (a datatype
# declares its kind), bend error page
type Kk:
  Zz{}

law main:
  Unit

def main(): Unit{}

#|Error:
#|- expected : 'is'
#|- observed : ':'
#|Location:
#|5 | # declares its kind), bend error page
#|6>| type Kk:
#|  |        ^
#|7 |   Zz{}
#|exit 1
