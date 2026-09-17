# audit witness (gptpro round 2, A1): a twin read then consumed. The read
# counts once every argument is laid out, so audit_twins keeps xs and the
# owned side frees a copy while the reader reads the original.
import Base

type AuditChain is Data:
  AuditNil{}
  AuditCon{h: U32, t: AuditChain}

def audit_owner(xs: AuditChain) -> AuditChain:
  xs

def audit_destroy_len(xs: AuditChain) -> U32:
  match xs:
    case AuditNil{}:
      0
    case AuditCon{h, t}:
      (1 + audit_destroy_len(t) : U32)

def audit_destroy(xs: AuditChain) -> U32:
  ys = audit_owner(xs)
  audit_destroy_len(ys)

def audit_read_len(xs: AuditChain, acc: U32) -> U32:
  match xs:
    case AuditNil{}:
      acc
    case AuditCon{h, t}:
      audit_read_len(t, (acc + 1 : U32))

def audit_pair(left: AuditChain, right: AuditChain) -> U32:
  a = audit_destroy(right)
  b = audit_read_len(left, 0)
  (a + b : U32)

def audit_twins(+xs: AuditChain) -> U32:
  n = audit_pair(xs, xs)
  (n + 0 : U32)

def main() -> IO(Unit):
  n = audit_twins(AuditCon{7, AuditCon{9, AuditNil{}}})
  IO.print(U32.show(n))

#|4
