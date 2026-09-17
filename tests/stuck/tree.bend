# a user datatype: size(Node{Node{Leaf{}, Leaf{}}, t}) computes the
# closed subtree to 1n, so add(1n, size(t)) unfolds through its
# first argument and the goal is 2n+size(t).
import Base

type Tree is Data:
  Leaf{}
  Node{l: Tree, r: Tree}

law add:
  for a: Nat
  for b: Nat
  Nat

def add(a, b):
  match a:
    case 0n:
      b
    case 1n+p:
      1n+add(p, b)

law size:
  for t: Tree
  Nat

def size(t):
  match t:
    case Leaf{}:
      0n
    case Node{l, r}:
      1n+add(size(l), size(r))

law main:
  @t:Tree -> Nat

def main():
  t => size(Node{Node{Leaf{}, Leaf{}}, t})

#|t => 2n+size(t)
