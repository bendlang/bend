# regression witness: the same reader twice on one value, and the same
# reader on a throwaway value elsewhere. The first read is used later, so
# it asks the reader to lend and the request wins: both reads borrow, and
# each site that passes a dying list has its continuation sink it after
# the call. The C lane must print the interpreter's sum, not a freed
# cell's. In the C, WL_CASE(FID_F) has no term_keep.
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
  a = Xs.eat(xs)
  b = Xs.eat(xs)
  (a + b : U32)

def main() -> IO(Unit):
  IO.print(U32.show((F(Xs.build(10n, 1)) + Xs.eat(Xs.build(3n, 1)) : U32)))

#|21
