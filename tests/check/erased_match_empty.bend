# audit: empty elimination cannot inspect an erased argument.
# ported from bend3
type Empty9 is Data:

type Unit9 is Data:
  Uu9{}

law bad:
  @-e:Empty9 -> Empty9

def bad(): \{}

law main:
  Unit9

def main(): Uu9{}

#|Error:
#|- message  : a live scrutinee (a - scrutinee matches only in a dead region)
#|Location: bad
#|10 | 
#|11>| def bad(): \{}
#|   |            ^^^
#|12 |
#|exit 1
