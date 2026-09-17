# audit 010: duplicate top-level declarations are rejected.
# ported from bend3
type Uu is Data:
  Un{}

law main:
  Uu

def main(): Un{}
law main:
  Uu

def main(): Un{}

#|Error:
#|- expected : a fresh name (duplicate declaration: main)
#|- observed : ':'
#|Location:
#| 9 | def main(): Un{}
#|10>| law main:
#|11 |   Uu
#|exit 1
