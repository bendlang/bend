# audit witness (gptpro round 3, A2): a dependent parameter that is a String
# at held sites and an Array at one dying site. The array eliminator is an
# owned position, so audit_read~1 owns its value and the array is freed
# once: ledger 0 (main's compiler freed it twice, -1).
import Base

def audit_shape(tag: Bool) -> Type:
  match tag:
    case False{}:
      String
    case True{}:
      Array<U32>

def audit_read(tag: Bool, value: audit_shape(tag)) -> U32:
  match tag:
    case False{}:
      match value:
        case SNil{}:
          0
        case SCon{h, t}:
          0
    case True{}:
      match value:
        case ALeaf{v}:
          v
        case ANode{l, r}:
          0

def main() -> IO(Unit):
  +s = {"s" : String}
  a = {ALeaf{7} : Array<U32>}
  x = audit_read(False{}, s)
  y = audit_read(False{}, s)
  z = audit_read(True{}, a)
  IO.print(U32.show((x + y + z : U32)))

#|7
