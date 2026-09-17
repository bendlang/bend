# theorems: mirror-involution on a binary tree -- one arm consumes TWO
# induction hypotheses, each rewriting one constructor field.
# ported from bend3: each IH rewrite carries an explicit motive marking
# its own field
import Base

type Tree is Data:
  Leaf{v: U32}
  Node{l: Tree, r: Tree}

law mirror:
  for t: Tree
  Tree

def mirror(t):
  match t:
    case Leaf{v}:
      Leaf{v}
    case Node{l, r}:
      Node{mirror(r), mirror(l)}

law mm:
  for t: Tree
  {mirror(mirror(t)) == t : Tree}

def mm(t):
  match t:
    case Leaf{v}:
      {==}
    case Node{l, r}:
      %mm(l) : {Node{mirror(mirror(l)), mirror(mirror(r))} == Node{_, r} : Tree}
      %mm(r) : {Node{mirror(mirror(l)), mirror(mirror(r))} == Node{mirror(mirror(l)), _} : Tree}
      {==}

law main:
  {mirror(mirror(Node{Leaf{1}, Leaf{2}})) == Node{Leaf{1}, Leaf{2}} : Tree}

def main(): mm(Node{Leaf{1}, Leaf{2}})

#|{==}
