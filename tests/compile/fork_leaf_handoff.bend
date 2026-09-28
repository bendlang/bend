import Base

type Tree is Data:
  Leaf{v: U32}
  Node{l: Tree, r: Tree}

def make(+n: Nat, +seed: U32) -> Tree:
  match n:
    case 0n:
      Leaf{seed}
    case 1n+p:
      Node{make(p, U32.mul(seed, 2)), make(p, U32.add(U32.mul(seed, 2), 1))}

def total(t: Tree) -> U32:
  match t:
    case Leaf{v}:
      v
    case Node{l, r}:
      U32.add(total(l), total(r))

def split(+k: Nat, +n: Nat, +seed: U32) -> Tree:
  match k:
    case 0n:
      make(n, seed)
    case 1n+p:
      l r = split(p, n, U32.mul(seed, 2)) split(p, n, U32.add(U32.mul(seed, 2), 1))
      Node{l, r}

def pair(+t: Tree) -> U32 & U32:
  (total(t), total(t))

def finish(p: U32 & U32, q: U32 & U32, seed: U32) -> U32:
  (a, b) = p
  (c, d) = q
  U32.add(seed, U32.add(U32.add(a, b), U32.add(c, d)))

def pipeline(+seed: U32) -> U32:
  before = total(make(3n, seed))
  +tree = split(3n, 5n, before)
  p q = pair(tree) pair(tree)
  finish(p, q, seed)

def clo(f: U32 -> U32, +x: U32) -> U32:
  f(x)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(pipeline(1)))
    IO.print(U32.show(pipeline!(1)))
    IO.print(U32.show(pipeline(1)))
    IO.print(U32.show(clo!(x => pipeline(x), 1)))
    IO.print(U32.show(clo!(x => total(make(3n, x)), 1)))

#|24247809
#|24247809
#|24247809
#|24247809
#|92
