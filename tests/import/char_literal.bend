# char literals are core grammar, ungated: 'a' is Chr{97} with Base's
# Char in scope (bend3 gated the quote sugar on `import Char`)
import Base

law code:
  for c: Char
  U32

def code(c):
  match c:
    case Chr{u}:
      u

law main.out:
  U32

def main.out():
  code('a')

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|97
