# matching b closes the binder a before it, as a lambda, while c stays pending.
# A later match on a stays an error when its one pattern is a variable, as it
# is for a constructor
import Base

def f(a: Nat, b: Nat, c: Nat) -> Nat:
  match b:
    case 0n:
      match a:
        case y:
          y
    case 1n+q:
      q

def main() -> Nat:
  f(3n, 2n, 1n)

#|SOME PROOFS FAIL
#|Error:
#|- message  : 'a' can't be matched in this position (it is matched after a local statement or after a match on a later binder, it was already matched, or it is a def)
#|Location:
#| 8 |     case 0n:
#| 9>|       match a:
#|   |             ^
#|10 |         case y:
#|exit 1
