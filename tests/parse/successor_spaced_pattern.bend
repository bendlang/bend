# a successor pattern is glued, `1n+p`; spaced, `1n + p` is the operator,
# so the error names the glued spelling, not an annotation (#1510)
import Base

def pred(n: Nat) -> Nat:
  match n:
    case 0n: 0n
    case 1n + p: p

#|SOME PROOFS FAIL
#|Error:
#|- message  : a pattern (a successor takes no spaces: 1n+p)
#|Location:
#|7 |     case 0n: 0n
#|8>|     case 1n + p: p
#|  |          ^^^^^^
#|9 | 
#|exit 1
