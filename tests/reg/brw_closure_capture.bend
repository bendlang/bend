# borrow witness: a closure capturing a held list (Cap) and a partial
# application of a reader (Part, an eta closure). A capture is an owned
# position, so Cap~0 and Part~0 are owned and each keeps xs once for the
# read after: two term_keep in the C, none in the readers.
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

def Apply(f: U32 -> U32, x: U32) -> U32:
  f(x)

def Cap(+xs: Xs) -> U32:
  a = Apply(k => (k + Xs.cnt(xs, 0) : U32), 1)
  (a + Xs.cnt(xs, 0) : U32)

def Part(+xs: Xs) -> U32:
  a = Apply(Xs.sum(xs), 5)
  (a + Xs.cnt(xs, 0) : U32)

def main() -> IO(Unit):
  IO.print(U32.show((Cap(Xs.build(10n, 1)) + Part(Xs.build(4n, 1)) : U32)))

#|40
