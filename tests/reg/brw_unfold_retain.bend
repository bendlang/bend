# borrow witness: a retain revealed only by unfolding. Sel(True{}, xs)
# unfolds into F as X1{0, xs}: the stored rooted word owns F~0, so F keeps
# xs once (the one term_keep). Two(True{}, xs) unfolds into G as two reads
# of xs, and their counts move with the unfolding: G keeps nothing.
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

def Sel(b: Bool, x: Xs) -> Xs:
  match b:
    case True{}:
      X1{0, x}
    case False{}:
      x

def F(+xs: Xs) -> U32:
  ys = Sel(True{}, xs)
  (Xs.cnt(xs, 0) + Xs.cnt(ys, 0) : U32)

def Two(b: Bool, +x: Xs) -> U32:
  match b:
    case True{}:
      (Xs.cnt(x, 0) + Xs.sum(x, 0) : U32)
    case False{}:
      0

def G(+xs: Xs) -> U32:
  a = Two(True{}, xs)
  (a + Xs.cnt(xs, 0) : U32)

def main() -> IO(Unit):
  IO.print(U32.show((F(Xs.build(3n, 1)) + G(Xs.build(4n, 1)) : U32)))

#|25
