import Base

type Tree is Data:
  Tip{}
  Node{p: U32, lo: Tree, hi: Tree}

def find(t: Tree, b: Bool) -> U32:
  match t b:
    case Node{p, lo, hi} False{}:
      find(Node{p, lo, hi}, True{})
    case _ _:
      0

def main() -> U32:
  0
