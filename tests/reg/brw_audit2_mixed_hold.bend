# audit witness (gptpro round 2, A2/B1): a flat aggregate with a rooted
# word and an owned fresh cell, lent twice and dead after. A binding is the
# caller's to let go only when every box word is rooted, so it stays bound
# and the continuation sinks its owned cell: ledger 0 (both compilers once
# leaked it).
import Base

type AuditChain is Data:
  AuditNil{}
  AuditCon{h: U32, t: AuditChain}

type AuditMixed is Data:
  AuditMixedValue{left: AuditChain, right: AuditChain}

def audit_reader(n: Nat, a: AuditMixed, b: AuditMixed) -> U32:
  match n:
    case 0n:
      0
    case 1n+p:
      (1 + audit_reader(p, a, b) : U32)

def audit_mixed(xs: AuditChain) -> U32:
  +m = {AuditMixedValue{xs, AuditCon{7, AuditNil{}}} : AuditMixed}
  n = audit_reader(0n, m, m)
  (n + 1 : U32)

def audit_length(xs: AuditChain) -> U32:
  match xs:
    case AuditNil{}:
      0
    case AuditCon{h, t}:
      (1 + audit_length(t) : U32)

def audit_hold(+xs: AuditChain) -> U32:
  a = audit_mixed(xs)
  b = audit_length(xs)
  (a + b : U32)

def main() -> IO(Unit):
  n = audit_hold(AuditCon{1, AuditCon{2, AuditNil{}}})
  IO.print(U32.show(n))

#|3
