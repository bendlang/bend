# a match binder that hides a parameter of the same name: the context marks
# the hidden one, so the two rate rows tell which is which (#1998)
import Base

type Box is Data:
  Box{rate: Nat}

def f(+rate: U32, b: Box) -> U32:
  match b:
    case Box{rate}:
      rate

#|SOME PROOFS FAIL
#|Error:
#|- expected : U32
#|- observed : Nat
#|Context:
#|- rate : U32 (shadowed)
#|- rate : Nat
#|Location: f
#|10 |     case Box{rate}:
#|11>|       rate
#|   |       ^^^^
#|12 | 
#|exit 1
