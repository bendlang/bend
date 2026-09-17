# audit witness (gptpro round 2, A5): a call folded away drops the last use
# of xs before a tail jump; the count move sinks xs at zero: ledger 0 (main
# leaked two nodes).
import Base

type AuditChain is Data:
  AuditNil{}
  AuditCon{h: U32, t: AuditChain}

def audit_choose(flag: Bool, xs: AuditChain) -> U32:
  match flag:
    case False{}:
      0
    case True{}:
      1

def audit_jump(n: Nat, x: U32) -> U32:
  match n:
    case 0n:
      x
    case 1n+p:
      (0 + audit_jump(p, x) : U32)

def audit_last(flag: Bool, +xs: AuditChain) -> U32:
  a = audit_choose(flag, xs)
  audit_jump(1n, (a + audit_choose(True{}, xs) : U32))

def main() -> IO(Unit):
  n = audit_last(True{}, AuditCon{1, AuditCon{2, AuditNil{}}})
  IO.print(U32.show(n))

#|2
