# regression witness: an owned parameter (its caller passes a computed
# argument) read by a cut reader (Xs.len, a non-tail recursion) and a
# fused reader (Xs.sum, a loop), then consumed. Both readers borrow: the
# emitted C matches through term_peek, and no term_keep or rfc_seal
# appears; the owner drops the list after its last read.
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

def Xs.len(xs: Xs) -> U32:
  match xs:
    case X0{}:
      0
    case X1{v, rest}:
      (Xs.len(rest) + 1 : U32)

def Xs.sum(xs: Xs, +acc: U32) -> U32:
  match xs:
    case X0{}:
      acc
    case X1{v, rest}:
      Xs.sum(rest, (acc + v : U32))

def Xs.eat(xs: Xs) -> U32:
  match xs:
    case X0{}:
      7
    case X1{v, rest}:
      Xs.eat(rest)

def F(+xs: Xs) -> U32:
  a = Xs.len(xs)
  b = Xs.sum(xs, 0)
  c = Xs.eat(xs)
  (a + b + c : U32)

def main() -> IO(Unit):
  IO.print(U32.show(F(Xs.build(10n, 1))))

#|72
