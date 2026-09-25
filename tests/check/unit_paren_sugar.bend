# bend3's () sugar for the Unit constructor, value and pattern; bend
# has no unit literal -- the pattern spelling dies at parse
import Base

law tick:
  for u: Unit
  U32

def tick(u):
  match u:
    case ():
      7

law main:
  U32

def main():
  0

#|Error:
#|- expected : a term
#|- observed : ')'
#|Location:
#|10 |   match u:
#|11>|     case ():
#|   |           ^
#|12 |       7
#|exit 1
