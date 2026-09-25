# AUDIT 17: ctx_dead must ignore ERASED binders - an erased region can
# be inhabited by dead code, so `-v: Void` in scope proves nothing about
# a LIVE branch; the inner match omits B1 and must be refused (the same
# shape with a live Void binder is check-efq's legitimate dead region)
type Void is Data:

type Bit is Data:
  B0{}
  B1{}

type Box is Data:
  Pack{-v: Void, b: Bit}

law bad:
  for x: Box
  Bit

def bad(x):
  match x:
    case Pack{v, b}:
      match b:
        case B0{}: B0{}

#|Error:
#|- expected : cases for B1
#|- observed : \{}
#|Context:
#|- v : Void
#|Location: bad
#|20 |     case Pack{v, b}:
#|21>|       match b:
#|   |       ^^^^^^^^
#|22 |         case B0{}: B0{}
#|exit 1
