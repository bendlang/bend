# regression witness: a borrowed list read by two forked tasks, then
# dropped after the join through a parameter the callee never uses. The
# dead parameter's argument was sunk where the fork captured it, BEFORE
# the tasks ran, so the readers walked freed cells (the tasks' own
# allocations reused them: 3802047092, or a fault). Now the join holds
# the list alive across the fork and drops it after both tasks.
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

def Xs.dbl(xs: Xs) -> Xs:
  match xs:
    case X0{}:
      X0{}
    case X1{v, rest}:
      X1{(v * 2 : U32), Xs.dbl(rest)}

def Xs.done(a: U32, b: U32, xs: Xs) -> U32:
  (a + b : U32)

def Xs.twice(+xs: Xs) -> U32:
  a b = Xs.sum(Xs.dbl(xs), 0) Xs.sum(Xs.dbl(xs), 0)
  Xs.done(a, b, xs)

def main() -> IO(Unit):
  IO.print(U32.show(Xs.twice(Xs.build(2000n, 1))))

#|8004000
