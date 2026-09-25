# a + on a name that is no datatype marks a binder: in a term position
# it binds nothing, and the checker refuses the unbound variable
import Base

def main() -> U32:
  x = U32.add(1, 1)
  U32.add(+x, 1)

#|Error:
#|- expected : a bound variable
#|- observed : x^-1
#|Context:
#|- x : U32
#|Location: main
#|6 |   x = U32.add(1, 1)
#|7>|   U32.add(+x, 1)
#|  |           ^^
#|8 | 
#|exit 1
