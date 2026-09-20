# A relative ordinary call does not annotate operators in its arguments.
import Base
import ../import/op_parent_lib.bend as M

def main() -> U32:
  (M.id_u(2 + 3) : U32)

#|Error:
#|- message  : a type for this operator (write (a + b : Nat))
#|Location:
#|5 | def main() -> U32:
#|6>|   (M.id_u(2 + 3) : U32)
#|7 | 
#|Note: we broke this after launch, sorry. Until 2.0.16 a bare operator meant Nat.
#|That was a bug: operators demand annotation. Wrap the expression and it'll work again.
#|exit 1
