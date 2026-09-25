# a let-bound lambda applied twice: term_higher's beta step reads a bare
# lambda head, never under a binding (a let's name is a cell that
# term_strip would open), so each k0(..) is a use of k0, and the second
# is refused
import Base

type Pr12<Elem: Type> is Type:
  P12{x: Elem, y: Elem}

law main:
  Pr12<U32>

def main():
  k0 = {(x => x) : U32 -> U32}
  P12{k0(1), k0(2)}

#|Error:
#|- expected : k0
#|- observed : k0 (consumed more than once)
#|Location: main
#|13 | def main():
#|14>|   k0 = {(x => x) : U32 -> U32}
#|   |   ^^
#|15 |   P12{k0(1), k0(2)}
#|exit 1
