# audit witness (gptpro round 3, A1): a twin read as a and consumed as b
# through audit_hold, whose result owns b. The owned pop precedes the read,
# so main keeps x and audit_head reads a live tree. Main's compiler moved
# the twin and printed 51413378 for 42.
import Base

type AuditTree is Data:
  AuditEnd{}
  AuditNode{n: U32, tail: AuditTree}

type AuditHolder is Type:
  AuditHold{tree: AuditTree}

def audit_hold(t: AuditTree) -> AuditHolder:
  AuditHold{t}

def audit_drop(p: AuditHolder) -> U32:
  match p:
    case AuditHold{t}:
      0

def audit_head(t: AuditTree) -> U32:
  match t:
    case AuditEnd{}:
      0
    case AuditNode{n, tail}:
      n

def audit_twin(a: AuditTree, b: AuditTree) -> U32:
  k = audit_drop(audit_hold(b))
  (k + audit_head(a) : U32)

def main() -> IO(Unit):
  +x = {AuditNode{42, AuditEnd{}} : AuditTree}
  n = audit_twin(x, x)
  IO.print(U32.show(n))

#|42
