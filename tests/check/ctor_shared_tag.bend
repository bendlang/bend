# bend3 scoped ctor tags per datatype and resolved by expected type;
# bend's tags are global and unique by design -- the shared K dies at
# its second declaration
import Base

type A5 is Data:
  K5{}

type B5 is Data:
  K5{a: A5}

law main:
  U32

def main():
  0

#|Error:
#|- expected : a fresh constructor name (duplicate declaration: K5)
#|- observed : '{'
#|Location:
#| 9 | type B5 is Data:
#|10>|   K5{a: A5}
#|11 |
#|exit 1
