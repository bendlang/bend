# Two marked calls exchange heap-allocated trees with an unmarked consumer.
# IO separates the calls. CPU-only execution checks the same results.
import Base

type Tree is Data:
  Leaf{value: U32}
  Node{left: Tree, right: Tree}

def build(+depth: Nat, +seed: U32) -> Tree:
  match depth:
    case 0n:
      Leaf{seed}
    case 1n+d:
      left right = build(d, seed) build(d, U32.add(seed, 1))
      Node{left, right}

def shift(tree: Tree, +amount: U32) -> Tree:
  match tree:
    case Leaf{value}:
      Leaf{U32.add(value, amount)}
    case Node{left, right}:
      l r = shift(left, amount) shift(right, amount)
      Node{l, r}

def sum(tree: Tree) -> U32:
  match tree:
    case Leaf{value}:
      value
    case Node{left, right}:
      l r = sum(left) sum(right)
      U32.add(l, r)

def main() -> IO(Unit):
  do IO<Unit>:
    first: Tree = build!(5n, 1)
    Unit <- IO.print(U32.show(sum(first)))
    second: Tree = shift!(build(5n, 10), 7)
    IO.print(U32.show(sum(second)))

#|112
#|624
