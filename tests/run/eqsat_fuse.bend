# eqsat: a consumer over a producer's result is one recursion (check over
# make: 2^d nodes become d steps, the two equal calls computed once); first
# reads only the left spine of what make builds; size over grow consumes a
# tree grown from an accumulator; and depth's answer on a tree past the
# Nat limit stops the program on every lane, fused or not.
import Base

type Tree is Data:
  Leaf{}
  Node{l: Tree, r: Tree}

def make(+d: Nat) -> Tree:
  match d:
    case 0n:
      Node{Leaf{}, Leaf{}}
    case 1n+p:
      Node{make(p), make(p)}

def check(t: Tree) -> Nat:
  match t:
    case Leaf{}:
      0n
    case Node{l, r}:
      Nat.add(1n, Nat.add(check(l), check(r)))

def first(t: Tree) -> Nat:
  match t:
    case Leaf{}:
      7n
    case Node{l, r}:
      Nat.add(first(l), 1n)

def grow(+n: Nat, t: Tree) -> Tree:
  match n:
    case 0n:
      t
    case 1n+p:
      grow(p, Node{Leaf{}, t})

def size(t: Tree) -> Nat:
  match t:
    case Leaf{}:
      1n
    case Node{l, r}:
      Nat.add(size(l), size(r))

def heavy(t: Tree) -> Nat:
  match t:
    case Leaf{}:
      Nat.mul(4294967295n, 65537n)
    case Node{l, r}:
      Nat.add(heavy(l), heavy(r))

def go(+i: Nat, acc: Nat) -> Nat:
  match i:
    case 0n:
      acc
    case 1n+p:
      go(p, Nat.add(acc, check(make(10n))))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(Nat.show(go(50n, 0n)))
    IO.print(Nat.show(first(make(12n))))
    IO.print(Nat.show(size(grow(1000n, Leaf{}))))
    IO.print(Nat.show(check(make(0n))))
    IO.print(Nat.show(heavy(make(2n))))

#|102350
#|20
#|1001
#|1
#|bend: a Nat past the largest immediate 2^48-1
