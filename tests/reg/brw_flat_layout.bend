# borrow witness: a flattened layout. Rec is one constructor with a word
# and a box, so a Rec parameter is two words; only the box word is rooted.
# F holds r, so Rec.len~0 is borrowed and its match reads the words in
# place: no term_keep, cnt through term_peek.
import Base

type Xs is Data:
  X0{}
  X1{v: U32, rest: Xs}

def Xs.build(n: Nat, +acc: U32) -> Xs:
  match n:
    case 0n:
      X0{}
    case 1n+p:
      X1{acc, Xs.build(p, (acc + 1 : U32))}

def Xs.sum(xs: Xs, acc: U32) -> U32:
  match xs:
    case X0{}:
      acc
    case X1{v, rest}:
      Xs.sum(rest, (acc + v : U32))

def Xs.cnt(xs: Xs, acc: U32) -> U32:
  match xs:
    case X0{}:
      acc
    case X1{v, rest}:
      Xs.cnt(rest, (acc + 1 : U32))

type Rec is Data:
  Rec{n: U32, xs: Xs}

def Rec.len(r: Rec) -> U32:
  match r:
    case Rec{n, xs}:
      (n + Xs.cnt(xs, 0) : U32)

def F(+r: Rec) -> U32:
  (Rec.len(r) + Rec.len(r) : U32)

def main() -> IO(Unit):
  IO.print(U32.show(F(Rec{5, Xs.build(3n, 1)})))

#|16
