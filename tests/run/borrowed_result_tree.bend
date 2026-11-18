# an accessor that answers a part of its argument: a lookup in a shared tree
import Base

type Chain is Data:
  CNil{}
  CCons{k: U32, t: Chain}

type Tree is Data:
  Leaf{c: Chain}
  Node{l: Tree, r: Tree}

def sum(c: Chain, acc: U32) -> U32:
  match c:
    case CNil{}:
      acc
    case CCons{h, t}:
      sum(t, (acc + h : U32))

def bit(i: U32) -> Bool:
  U32.is_eq((i .&. 1 : U32), 1)

# the chain at leaf i: a part of t
def pick(t: Tree, b: Bool, +i: U32) -> Chain:
  match t b:
    case Leaf{c} b:
      c
    case Node{l, r} False{}:
      pick(l, bit((i >> 1n : U32)), (i >> 1n : U32))
    case Node{l, r} True{}:
      pick(r, bit((i >> 1n : U32)), (i >> 1n : U32))

def chain(n: Nat, +x: U32, acc: Chain) -> Chain:
  match n:
    case 0n:
      acc
    case 1n+p:
      chain(p, (x * 7 + 3 : U32), CCons{(x .&. 255 : U32), acc})

def build(+d: Nat, +x: U32) -> Tree:
  match d:
    case 0n:
      Leaf{chain(4n, x, CNil{})}
    case 1n+p:
      Node{build(p, (x * 2 + 1 : U32)), build(p, (x * 2 + 2 : U32))}

def look(n: Nat, +t: Tree, +j: U32, acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+p:
      +k = (j * 2654435761 >> 7n : U32)
      look(p, t, (j + 1 : U32), (acc * 31 + sum(pick(t, bit(k), k), 0) : U32))

def size() -> Nat:
  U32.to_nat(2000)

# the tree is held across two passes
def run(+t: Tree) -> U32:
  (look(size(), t, 0, 0) + look(size(), t, 7, 0) : U32)

def main() -> IO(Unit):
  IO.print(U32.show(run(build(10n, 1))))

#|4135878592
