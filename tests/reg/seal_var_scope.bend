# sealing witness: a constructor's own erased binder. AuditHide binds -A
# itself; facts_hot once matched that A by index and name against the
# def's telescope and marked poly on audit_twice's unrelated -A, heating
# Bool while AuditNode stayed cold and its count cell was read as a node.
# Under a constructor's own binder a type variable is unknown (hot *).
import Base

type AuditTree is Data:
  AuditEnd{}
  AuditNode{n: U32, tail: AuditTree}

type AuditHidden is Data:
  AuditHide{-A: Data, value: A, eq: {A == AuditTree : Type}}

def audit_head(t: AuditTree) -> U32:
  match t:
    case AuditEnd{}:
      0
    case AuditNode{n, tail}:
      n

def audit_unhide(x: AuditHidden) -> AuditTree:
  match x:
    case AuditHide{A, value, eq}:
      %eq : _
      value

def audit_read_hidden(x: AuditHidden) -> U32:
  audit_head(audit_unhide(x))

def audit_twice(-A: Data, +x: AuditHidden) -> U32:
  a = audit_read_hidden(x)
  b = audit_read_hidden(x)
  (a + b : U32)

def main() -> IO(Unit):
  n = audit_twice(
    Bool,
    AuditHide{AuditTree, AuditNode{7, AuditEnd{}}, {==}}
  )
  IO.print(U32.show(n))

#|14
