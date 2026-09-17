# audit witness (gptpro round 2, A3): a borrowed generic field unboxed into
# a flat sum. val_arms roots a destination every arm fills from one root,
# so the chain stays the shelf's: ledger 0 (main double-freed it, -4).
import Base

type AuditChain is Data:
  AuditNil{}
  AuditCon{h: U32, t: AuditChain}

type AuditPick is Data:
  AuditNone{}
  AuditSome{value: AuditChain}

type AuditShelf<-A: Data> is Data:
  AuditShelfNil{}
  AuditShelfCon{head: A, tail: AuditShelf<A>}

def audit_length(xs: AuditChain) -> U32:
  match xs:
    case AuditNil{}:
      0
    case AuditCon{h, t}:
      (1 + audit_length(t) : U32)

def audit_pick(p: AuditPick) -> U32:
  match p:
    case AuditNone{}:
      0
    case AuditSome{value}:
      audit_length(value)

def audit_first(xs: AuditShelf<AuditPick>) -> U32:
  match xs:
    case AuditShelfNil{}:
      0
    case AuditShelfCon{head, tail}:
      audit_pick(head)

def audit_twice(+xs: AuditShelf<AuditPick>) -> U32:
  a = audit_first(xs)
  b = audit_first(xs)
  (a + b : U32)

def main() -> IO(Unit):
  n = audit_twice(
    AuditShelfCon{
      AuditSome{AuditCon{7, AuditCon{9, AuditNil{}}}},
      AuditShelfNil{}
    })
  IO.print(U32.show(n))

#|4
