# regression witness: the fields of an owned boxed match (a box with two
# constructors, so it is a heap node, not a flat record) lent to readers
# while the box is alive, then consumed. A field of an owned box had no
# slot, so every reader it reached became an owner and the box shared
# (term_keep). Now the fields borrow and the readers keep term_peek.
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

type Bx is Data:
  B0{}
  B2{+xs: Xs, +ys: Xs, n: U32}

def Xs.eat(xs: Xs) -> U32:
  match xs:
    case X0{}:
      7
    case X1{v, rest}:
      Xs.eat(rest)

def G(b: Bx) -> U32:
  match b:
    case B0{}:
      0
    case B2{xs, ys, n}:
      a = Xs.len(xs)
      c = Xs.sum(ys, n)
      (a + c + Xs.eat(xs) + Xs.eat(ys) : U32)

def main() -> IO(Unit):
  IO.print(U32.show(G(B2{Xs.build(10n, 1), Xs.build(5n, 3), 2})))

#|51
