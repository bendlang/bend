# borrow witness: fields of a shared node read by a borrowed reader. Dup
# keeps xs (Xs is hot: rfc_seal in the C), Read holds a and reads it twice
# through cnt~0, borrowed: term_peek through the count cell, no fade, and
# the count is back to 1 when b moves into sum.
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

type Two is Data:
  Two{a: Xs, b: Xs}

def Dup(+xs: Xs) -> Two:
  Two{xs, xs}

def Read(+t: Two) -> U32:
  Two{a, b} = t
  (Xs.cnt(a, 0) + Xs.sum(b, 0) + Xs.cnt(a, 0) : U32)

def main() -> IO(Unit):
  IO.print(U32.show(Read(Dup(Xs.build(10n, 1)))))

#|75
