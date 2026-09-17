# a constructor declared twice within one datatype is a parse error
# (constructor names are global and unique).
# ported from bend3
type Aa is Data:
  Kk{}
  Kk{a: Aa}

law main:
  Aa

def main(): Kk{}

#|Error:
#|- expected : a fresh constructor name (duplicate declaration: Kk)
#|- observed : '{'
#|Location:
#|5 |   Kk{}
#|6>|   Kk{a: Aa}
#|7 |
#|exit 1
