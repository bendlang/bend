# `1n +p` reads as two patterns, so the count error names the glued spelling
# (#1510)
import Base

def pred(n: Nat) -> Nat:
  match n:
    case 0n: 0n
    case 1n +p: p

#|SOME PROOFS FAIL
#|Error:
#|- expected : 1 patterns (one per scrutinee; a successor takes no spaces: 1n+p)
#|- observed : '1n +p'
#|Location:
#|7 |     case 0n: 0n
#|8>|     case 1n +p: p
#|  |          ^^^^^
#|9 | 
#|exit 1
