# borrow witness: a tail-recursive reader with a fresh accumulator, lent.
# Two holds xs across both sums, so sum~0 is borrowed: its spin reads each
# node through term_peek, jumps with WL_AGAIN, frees nothing, and Two has
# no term_keep.
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

def Two(+xs: Xs) -> U32:
  (Xs.sum(xs, 0) + Xs.sum(xs, 1) : U32)

def main() -> IO(Unit):
  IO.print(U32.show(Two(Xs.build(10n, 1))))

#|111
