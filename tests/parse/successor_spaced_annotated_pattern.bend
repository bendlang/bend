# the annotation the operator's error asks for doesn't make a pattern either,
# so the error names the glued spelling here too (#1510)
import Base

def pred(n: Nat) -> Nat:
  match n:
    case 0n: 0n
    case (1n + p : Nat): p

#|SOME PROOFS FAIL
#|Error:
#|- message  : a pattern (a successor takes no spaces: 1n+p)
#|Location:
#|7 |     case 0n: 0n
#|8>|     case (1n + p : Nat): p
#|  |           ^^^^^^^
#|9 | 
#|exit 1
