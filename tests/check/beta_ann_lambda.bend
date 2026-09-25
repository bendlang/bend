# an annotated lambda applied is not a redex: the annotation is a claim,
# so the call checks the lambda at it and the argument against its
# domain. once the checker's beta steps read the lambda under the
# annotation and dropped it, so a U32 passed where the user wrote Nat
import Base

def main() -> U32:
  {(x => x) : Nat -> Nat}(1)

#|Error:
#|- expected : Nat
#|- observed : U32
#|Location: main
#|7 | def main() -> U32:
#|8>|   {(x => x) : Nat -> Nat}(1)
#|  |                           ^
#|9 |
#|exit 1
