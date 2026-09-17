# the != form is core grammar, gated on nothing -- with Base in scope
# it checks at any type (bend3 gated the sugar on `import Empty`)
import Base

law cneq:
  Type

def cneq():
  {'a' != 'b' : Char}

law main:
  Nat

def main():
  9n

#|9n
