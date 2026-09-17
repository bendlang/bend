# audit witness (gptpro A.4/B.3): a packed Var boxed for a generic parameter.
# The conversion allocates, so the argument is a temporary, not a read:
# audit_ignore~1 owns it and sinks it: ledger 0 (both compilers leaked the
# two boxes).
import Base

type AuditDuo is Data:
  AuditDuoValue{left: U32, right: U32}

def audit_ignore(-A: Type, x: A) -> U32:
  0

def main() -> IO(Unit):
  +p = {AuditDuoValue{10, 20} : AuditDuo}
  a = audit_ignore(AuditDuo, p)
  b = audit_ignore(AuditDuo, p)
  IO.print(U32.show(U32.add(a, b)))

#|0
