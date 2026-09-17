# a monadic loop through continuation lambdas: a bind whose
# continuation ends in the self-recursive call, threading context
# through the closure -- and the descent judgment sees the self-call
# through the bind's lambda (the recursion
# descends, and the shared fd is a + binder: U32 is Data).
# ported from bend3: IO becomes base Result, the counter becomes Nat
# fuel; the bend3 arm's inner match and let cannot ride a do block
# (match heads a def body; DoLet never parses -- io_do_let_lines pins
# that), so the continuation folds the let into the tail call
import Base

law nod:
  for fd : U32
  for x  : U32
  Result<&2, &2, U32, U32>

def nod(fd, x):
  Done{U32.add(fd, x)}

law rec:
  for +fd : U32
  for n   : Nat
  for len : U32
  Result<&2, &2, U32, U32>

def rec(fd, n, len):
  match n:
    case 0n:
      Done{len}
    case 1n+m:
      do Result<&2, &2, U32, U32>:
        a : U32 <- nod(fd, 1)
        rec(fd, m, U32.add(len, a))

law unwrap:
  for r: Result<&2, &2, U32, U32>
  U32

def unwrap(r):
  match r:
    case Done{v}:
      v
    case Fail{x}:
      x

law main.out:
  Nat

def main.out():
  U32.to_nat(unwrap(rec(7, 3n, 0)))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|24n
