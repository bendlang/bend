# regression witness (#1953): a fork's join opens on the fork path's holds,
# but the serial path sinks a held value after the spin that reads it last.
# The join then had fewer parameters than the fork filled, a task landed on
# its continuation and the frontier drained at 2+ threads. Here the value is
# borrowed by a sibling task, read by spins in one or both arguments, in a
# two- and a three-way let and in two forks in a row.
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

def Xs.rev(xs: Xs, acc: Xs) -> Xs:
  match xs:
    case X0{}:
      acc
    case X1{v, rest}:
      Xs.rev(rest, X1{v, acc})

def one(+xs: Xs) -> U32:
  a b = Xs.len(xs) Xs.sum(Xs.rev(xs, X0{}), 0)
  (a + b : U32)

def three(+xs: Xs) -> U32:
  a b c = Xs.len(xs) Xs.sum(xs, 0) Xs.len(Xs.rev(xs, X0{}))
  (a + b + c : U32)

def both(+xs: Xs) -> U32:
  a b = Xs.len(Xs.rev(xs, X0{})) Xs.len(Xs.rev(xs, X0{}))
  (a + b : U32)

def twice(+xs: Xs) -> U32:
  a b = Xs.len(xs) Xs.len(Xs.rev(xs, X0{}))
  c d = Xs.len(xs) Xs.sum(Xs.rev(xs, X0{}), a)
  (b + c + d : U32)

def main() -> IO(Unit):
  IO.print(U32.show(one(Xs.build(2000n, 1))) ++ " " ++ U32.show(three(Xs.build(2000n, 1))) ++ " " ++ U32.show(both(Xs.build(2000n, 1))) ++ " " ++ U32.show(twice(Xs.build(2000n, 1))))

#|2003000 2005000 4000 2007000
