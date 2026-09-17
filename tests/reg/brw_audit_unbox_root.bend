# audit witness (gptpro A.3/B.2): a borrowed sum unboxed. The head of the
# rooted list is a box; matching it converts BOX to the two-arm layout
# through val_arms, whose outputs take the source's root, so the unused
# payload is let go, not sunk: ledger 0 (both compilers double-freed it).
import Base

type PayloadChain is Data:
  PayloadEnd{}
  PayloadCell{head: U32, tail: PayloadChain}

type AuditPayload is Data:
  WithoutPayload{}
  WithPayload{value: PayloadChain}

def payload_make(v: U32) -> +List<AuditPayload>:
  [WithPayload{PayloadCell{v, PayloadEnd{}}}]

def payload_probe(xs: +List<AuditPayload>) -> U32:
  match xs:
    case Nil{}:
      0
    case WithoutPayload{} <> tail:
      0
    case WithPayload{value} <> tail:
      1

def main() -> IO(Unit):
  +xs = payload_make(U32.add(40, 2))
  a = payload_probe(xs)
  b = payload_probe(xs)
  IO.print(U32.show(U32.add(a, b)))

#|2
