# sealing witness: Array.clone on a cold element type. blk_copy installs a
# count cell on each element through blk_keep, so the element type must be
# hot before an owning reader takes a node: emit_intr heats it for clone as
# for new and get (clone has a C form, so the heat sits above arr_call).
# Before, audit_head read the count cell as an AuditNode and the run hung.
import Base

type AuditTree is Data:
  AuditEnd{}
  AuditNode{n: U32, tail: AuditTree}

def audit_head(t: AuditTree) -> U32:
  match t:
    case AuditEnd{}:
      0
    case AuditNode{n, tail}:
      n

def audit_leaf(a: Array<AuditTree>) -> U32:
  match a:
    case ALeaf{t}:
      audit_head(t)
    case ANode{l, r}:
      0

def audit_both(p: Array<AuditTree> & Array<AuditTree>) -> U32:
  match p:
    case Tuple{a, b}:
      x = audit_leaf(a)
      y = audit_leaf(b)
      (x + y : U32)

def main() -> IO(Unit):
  a = {ALeaf{AuditNode{7, AuditEnd{}}} : Array<AuditTree>}
  n = audit_both(Array.clone(AuditTree, a))
  IO.print(U32.show(n))

#|14
