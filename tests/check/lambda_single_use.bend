# a let-applied lambda that reduces to a lambda cannot be used twice:
# k binds Lone, and no live binding contracts (the redex head rides a
# let binding: a bare beta-redex is its body, stepped by term_higher).
# ported from bend3: the annotation wears the brace Ann form
import Base

type Pr12<Elem: Type> is Type:
  P12{x: Elem, y: Elem}

law main:
  Pr12<(U32 -> U32)>

def main():
  k0 = {(d => x => x) : Unit -> U32 -> U32}
  k = k0(Unit{})
  P12{k, k}

#|Error:
#|- expected : k
#|- observed : k (consumed more than once)
#|Context:
#|- k0 : @_:Unit -> @_:U32 -> U32
#|Location: main
#|14 |   k0 = {(d => x => x) : Unit -> U32 -> U32}
#|15>|   k = k0(Unit{})
#|   |   ^
#|16 |   P12{k, k}
#|exit 1
