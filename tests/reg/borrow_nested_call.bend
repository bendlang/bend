# regression witness: reads nested in one expression, f(g(+x), h(x)),
# infer the same borrows as the let form: a call's later siblings count
# as later uses, so the first reader borrows and the last one (the last
# use) is reached by the owner's drop after the call. Both forms print
# the same and neither shares the list.
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
  (Xs.len(xs) + Xs.sum(xs, 0) + Xs.eat(xs) : U32)

def Fb(+xs: Xs) -> U32:
  a = Xs.len(xs)
  b = Xs.sum(xs, 0)
  (a + b + Xs.eat(xs) : U32)

def main() -> IO(Unit):
  IO.print(U32.show((F(Xs.build(10n, 1)) + Fb(Xs.build(10n, 1)) : U32)))

#|144
