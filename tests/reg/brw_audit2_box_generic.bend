# audit witness (gptpro round 2, A4): a two-word record boxed for a generic
# parameter under a later use. The rebuilt argument is a temporary, so
# audit_ignore~2 owns and frees the box: ledger 0 (main leaked it).
import Base

type AuditNumbers is Data:
  AuditNums{a: U32, b: U32}

def audit_ignore(-A: Type, n: Nat, x: A) -> U32:
  match n:
    case 0n:
      0
    case 1n+p:
      (1 + audit_ignore(A, p, x) : U32)

def audit_sum(p: AuditNumbers) -> U32:
  match p:
    case AuditNums{a, b}:
      (a + b : U32)

def audit_test(+p: AuditNumbers) -> U32:
  a = audit_ignore(AuditNumbers, 0n, p)
  b = audit_sum(p)
  (a + b : U32)

def main() -> IO(Unit):
  n = audit_test(AuditNums{3, 4})
  IO.print(U32.show(n))

#|7
