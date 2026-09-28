import Base

type Tree is Data:
  Tip{}
  Node{p: U32, lo: Tree, hi: Tree}

def find(t: Tree, b: Bool) -> U32:
  match t b:
    case Node{p, Node{+q, a, c}, hi} False{}:
      find(Node{q, a, c}, True{})
    case Node{p, lo, Node{+q, a, c}} True{}:
      find(Node{q, a, c}, False{})
    case _ _:
      0

def main() -> U32:
  find(Node{1, Node{2, Tip{}, Tip{}}, Node{3, Tip{}, Tip{}}}, True{})
