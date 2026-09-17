# audit witness (gptpro round 2, A6/B3): a rooted packet whose dependent
# payload is an Array, matched by the array eliminator. The eliminator is
# an owned position (val_own on the scrutinee), so audit_inspect~1 owns
# its packet and the array is freed once: ledger 0 (both compilers freed
# it twice, -1).
import Base

type AuditChain is Data:
  AuditNil{}
  AuditCon{h: U32, t: AuditChain}

def audit_grade(b: Bool) -> Quant:
  match b:
    case False{}:
      &2
    case True{}:
      &1

def AuditPayload(b: Bool) -> Kind(audit_grade(b)):
  match b:
    case False{}:
      AuditChain
    case True{}:
      Array<U32>

type AuditPacket<b: Bool> is Kind(audit_grade(b)):
  AuditPacketValue{payload: AuditPayload(b)}

def audit_length(xs: AuditChain) -> U32:
  match xs:
    case AuditNil{}:
      0
    case AuditCon{h, t}:
      (1 + audit_length(t) : U32)

def audit_inspect(b: Bool, p: AuditPacket<b>) -> U32:
  match b:
    case False{}:
      match p:
        case AuditPacketValue{payload}:
          audit_length(payload)
    case True{}:
      match p:
        case AuditPacketValue{payload}:
          match payload:
            case ALeaf{value}:
              value
            case _:
              0

def audit_hold_false(+p: AuditPacket<False{}>) -> U32:
  a = audit_inspect(False{}, p)
  b = audit_inspect(False{}, p)
  (a + b : U32)

def audit_once_true(p: AuditPacket<True{}>) -> U32:
  a = audit_inspect(True{}, p)
  (a + 1 : U32)

def main() -> IO(Unit):
  a = audit_hold_false(
    AuditPacketValue{AuditCon{1, AuditCon{2, AuditNil{}}}})
  b = audit_once_true(AuditPacketValue{ALeaf{7}})
  IO.print(U32.show((a + b : U32)))

#|12
