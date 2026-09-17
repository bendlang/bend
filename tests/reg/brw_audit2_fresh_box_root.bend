# audit witness (gptpro round 2, B2): a specialized sum converted for a
# generic parameter: its chain word is rooted, its item is boxed on the way.
# val_arms roots destinations one by one, so the fresh box is owned and
# audit_skip~2 owns it: ledger 0 (both compilers leaked the box).
import Base

type AuditChain is Data:
  AuditNil{}
  AuditCon{h: U32, t: AuditChain}

type AuditNumbers is Data:
  AuditNums{a: U32, b: U32}

type AuditSum<-A: Data> is Data:
  AuditSumNone{}
  AuditSumSome{chain: AuditChain, item: A}

def audit_skip(-A: Data, n: Nat, s: AuditSum<A>) -> U32:
  match n:
    case 0n:
      0
    case 1n+p:
      (1 + audit_skip(A, p, s) : U32)

def audit_adapt(xs: AuditChain) -> U32:
  s = {AuditSumSome{xs, AuditNums{3, 4}} : AuditSum<AuditNumbers>}
  a = audit_skip(AuditNumbers, 0n, s)
  (a + 1 : U32)

def audit_length(xs: AuditChain) -> U32:
  match xs:
    case AuditNil{}:
      0
    case AuditCon{h, t}:
      (1 + audit_length(t) : U32)

def audit_hold(+xs: AuditChain) -> U32:
  a = audit_adapt(xs)
  b = audit_length(xs)
  (a + b : U32)

def main() -> IO(Unit):
  n = audit_hold(AuditCon{1, AuditCon{2, AuditNil{}}})
  IO.print(U32.show(n))

#|3
