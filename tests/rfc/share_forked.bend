# two forked walks consume ONE shared tree across threads: the fork
# siblings each take a counted handle, their matches unshare layer by
# layer, and the last consumer frees. Values exact under 8 threads.
# ported from bend3: the & fork sugar spells the parallel let,
# +Tree the + binder over the Data Tree; no interp lane (the
# structural Word evaluator overflows its host stack on the 1024-leaf
# double walk)
import Base

type Tree is Data:
  Lf{v: U32}
  Nd{a: Tree, b: Tree}

law gen:
  for +d: Nat
  for +i: U32
  Tree

def gen(d, i):
  match d:
    case 0n:
      Lf{i}
    case 1n+e:
      l r = gen(e, U32.mul(i, 2)) gen(e, U32.add(U32.mul(i, 2), 1))
      Nd{l, r}

law sum:
  for t: Tree
  U32

def sum(t):
  match t:
    case Lf{v}:
      v
    case Nd{a, b}:
      x y = sum(a) sum(b)
      U32.add(x, y)

law two:
  for +t: Tree
  U32

def two(t):
  a b = sum(t) sum(t)
  U32.add(a, b)

law main.out:
  Nat

def main.out():
  U32.to_nat(two(gen(10n, 1)))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|3144704n
