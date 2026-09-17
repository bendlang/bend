# string literals are core grammar, ungated: ".." builds SCon/SNil
# with Base's String in scope (bend3 gated the sugar on `import
# String`)
import Base

law main.out:
  String

def main.out():
  "hi" ++ "!"

law main:
  IO(Unit)

def main():
  IO.print(main.out())

#|hi!
