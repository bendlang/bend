# bend3 scoped ctor tags per datatype (two types sharing K at
# different arities); bend ctor names are global and unique by
# design, so the shared tag is refused at its second declaration
import Base

type A7 is Data:
  K7{a: U32}
  E7{}

type B7b is Data:
  K7{a: U32, b: U32}

law main:
  U32

def main():
  0

#|Error:
#|- expected : a fresh constructor name (duplicate declaration: K7)
#|- observed : '{'
#|Location:
#|10 | type B7b is Data:
#|11>|   K7{a: U32, b: U32}
#|12 |
#|exit 1
