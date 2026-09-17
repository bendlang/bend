# constructor names are global and unique across the whole book: a
# later datatype cannot redeclare K at another arity.
# ported from bend3: bend3's source-prefix book resolved the first K;
# bend pins the refusal at the second declaration
type Un6 is Data:
  Uu6{}

type A6 is Data:
  K6{a: Un6}

type B6 is Data:
  K6{a: Un6, b: Un6}

law main:
  Un6

def main(): Uu6{}

#|Error:
#|- expected : a fresh constructor name (duplicate declaration: K6)
#|- observed : '{'
#|Location:
#|11 | type B6 is Data:
#|12>|   K6{a: Un6, b: Un6}
#|13 |
#|exit 1
