# rebuilding a matched scrutinee keeps its binder span, so returning it
# at the wrong result type points at the parameter that supplied it
type One is Data:
  One.new{}
def bad(x: One) -> Type:
  match x:
    case One.new{}:
      x

#|Error:
#|- expected : Type
#|- observed : One
#|Location: bad
#|7 |     case One.new{}:
#|8>|       x
#|  |       ^
#|9 | 
#|exit 1
