# Grow the pool, run 512 narrow forks, then expand the frontier again.
# The same folds must survive joins and worker reuse at every thread count.
import Base

def leaf(n: Nat, +x: U32) -> U32:
  match n:
    case 0n:
      x
    case 1n+p:
      leaf(p, U32.add(x, 1))

def tree(+d: Nat, +i: U32) -> U32:
  match d:
    case 0n:
      leaf(32n, i)
    case 1n+p:
      a b = tree(p, U32.mul(i, 2)) tree(p, U32.add(U32.mul(i, 2), 1))
      U32.add(a, b)

def narrow(n: Nat, +x: U32) -> U32:
  match n:
    case 0n:
      x
    case 1n+p:
      a b = leaf(32n, x) leaf(32n, U32.add(x, 1))
      narrow(p, U32.add(a, b))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(tree(10n, 0)))
    IO.print(U32.show(narrow(512n, 0)))
    IO.print(U32.show(tree(10n, 1)))

#|556544
#|4294967231
#|1605120
