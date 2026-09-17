# borrow witness: a spin (a flat def called as a C function) fed a lent
# argument. Xs.sum and Xs.cnt are flat; F holds xs across both calls, so
# each spin reads it through term_peek and F has no term_keep.
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

def F(+xs: Xs) -> U32:
  a = Xs.sum(xs, 0)
  b = Xs.cnt(xs, 0)
  (a + b : U32)

def main() -> IO(Unit):
  IO.print(U32.show(F(Xs.build(10n, 1))))

#|65
