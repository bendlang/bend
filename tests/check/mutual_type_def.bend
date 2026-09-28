# a type-level def and the datatypes it returns name each other, the def
# written first: its body is live code, and the datatypes below it are
# declared up front
import Base

def Vec(n: Nat) -> Data:
  match n:
    case 0n:
      Vec.Nil
    case 1n+p:
      Vec.Con<p>

type Vec.Nil is Data:
  VNil{}

type Vec.Con<-p: Nat> is Data:
  VCon{head: U32, tail: Vec(p)}

def Vec.sum(n: Nat, v: Vec(n)) -> U32:
  match n:
    case 0n:
      0
    case 1n+p:
      match v:
        case VCon{h, t}:
          (h + Vec.sum(p, t) : U32)

def main() -> U32:
  Vec.sum(3n, VCon{1, VCon{2, VCon{3, VNil{}}}})

#|6
