# borrow witness: reader chains. (a) HoldA holds xs, so ChainA~0 and LenA~0
# are borrowed (a lend passed on along the chain); (b) every site of ChainB
# dies (a temporary), so ChainB~0 and LenB~0 are owned and the callers
# move; (c) KeepC stores its parameter, so KeepC~0 and ChainC~0 are owned
# and HoldC keeps xs once (the one term_keep in the C).
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

def LenA(xs: Xs) -> U32:
  Xs.cnt(xs, 0)

def ChainA(xs: Xs) -> U32:
  LenA(xs)

def HoldA(+xs: Xs) -> U32:
  (ChainA(xs) + ChainA(xs) : U32)

def LenB(xs: Xs) -> U32:
  Xs.cnt(xs, 0)

def ChainB(xs: Xs) -> U32:
  LenB(xs)

def DieB(n: Nat) -> U32:
  r = ChainB(Xs.build(n, 1))
  (r + 1 : U32)

def KeepC(xs: Xs) -> Xs:
  X1{0, xs}

def ChainC(xs: Xs) -> Xs:
  KeepC(xs)

def HoldC(+xs: Xs) -> U32:
  ys = ChainC(xs)
  (Xs.cnt(xs, 0) + Xs.cnt(ys, 0) : U32)

def main() -> IO(Unit):
  IO.print(U32.show((HoldA(Xs.build(10n, 1)) + DieB(5n) + HoldC(Xs.build(3n, 1)) : U32)))

#|33
