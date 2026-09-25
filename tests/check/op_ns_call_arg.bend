# a ( .. : T) does not reach an operator inside a call's argument: the +
# here is Nat's, so the annotation names nothing and is refused with the
# repair, instead of quietly naming the + through the call
import Base

def id_u(x: U32) -> U32: x

def main() -> U32:
  (id_u(2 + 3) : U32)

#|Error:
#|- message  : a type for this operator (write (a + b : Nat))
#|Location:
#| 8 | def main() -> U32:
#| 9>|   (id_u(2 + 3) : U32)
#|   |           ^
#|10 | 
#|Note: we broke this after launch, sorry. Until 2.0.16 a bare operator meant Nat.
#|That was a bug: operators demand annotation. Wrap the expression and it'll work again.
#|exit 1
