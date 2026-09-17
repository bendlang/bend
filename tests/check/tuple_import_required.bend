# tuple literals are UNGATED sugar over the Tuple constructor: with no
# declaration in scope, (1, 2) fails as an unknown constructor, never
# as a parse error.
# ported from bend3: bend3 gated the literal on `import Pair`; bend's
# sugar always parses and resolves against the book
law main:
  Type

def main():
  x = (1, 2)
  Type

#|Error:
#|- expected : a declared constructor
#|- observed : (1, 2)
#|Location: main
#| 9 | def main():
#|10>|   x = (1, 2)
#|11 |   Type
#|exit 1
