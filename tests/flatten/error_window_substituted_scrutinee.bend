# a var column substitutes its binder by the scrutinee's own variable
# (body_sub), and the substitute carried the scrutinee's span: an error
# at the later match on y pointed at where a was bound (the def line),
# not at the match that is out of order. the use keeps its own span
import Base

def f(a: Nat, b: Nat) -> Nat:
  match a, b:
    case y, 0n:
      y
    case y, 1n+q:
      match y:
        case 0n:
          q
        case 1n+p:
          p

def main() -> Nat:
  f(3n, 2n)

#|Error:
#|- message  : a match on a parameter or field (this name is a def or a consumed binder: give the value its own def)
#|Location:
#|11 |     case y, 1n+q:
#|12>|       match y:
#|   |             ^
#|13 |         case 0n:
#|exit 1
