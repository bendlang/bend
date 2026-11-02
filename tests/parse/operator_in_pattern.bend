# an operator is no pattern, so the error doesn't ask for its annotation or
# offer a successor: the literal isn't on the left (#1510)
import Base

def pred(n: Nat) -> Nat:
  match n:
    case 0n: 0n
    case p + 1n: p

#|SOME PROOFS FAIL
#|Error:
#|- message  : a pattern (a binder or a constructor)
#|Location:
#|7 |     case 0n: 0n
#|8>|     case p + 1n: p
#|  |          ^^^^^^
#|9 | 
#|exit 1
