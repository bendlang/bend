# a datatype or field named __proto__, constructor or toString: the
# compiler's name-keyed tables (WORDS, the printer's kinds) have no
# prototype to inherit from (#948)
import Base

type __proto__ is Data:
  P{}

type constructor is Data:
  C{__proto__: U32, toString: U32}

type toString is Data:
  T{x: constructor, y: __proto__}

def main() -> toString:
  T{C{1, 2}, P{}}

#|T{C{1, 2}, P{}}
