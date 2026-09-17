# regression witness: a + let on a list, several lending reads, then a
# consuming read. A let-bound local had no slot, so its first reader was
# made an owner and the rest of the reads shared it (a term_keep each).
# Now a local is a slot like a parameter: the reads borrow, the last use
# owns.
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

def F(n: Nat) -> U32:
  +xs = Xs.build(n, 1)
  a = Xs.len(xs)
  b = Xs.sum(xs, 0)
  (a + b + Xs.eat(xs) : U32)

def main() -> IO(Unit):
  IO.print(U32.show(F(10n)))

#|72
