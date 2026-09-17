# a binary search tree: insert then in-order fold -- ctor churn plus
# ordered traversal, a different data-shape from lists and arrays
# ported from bend3: the x < v dispatch rides a fueled zipper (descend
# collecting frames, insert at the leaf, rebuild) -- a computed-match
# branch cannot hold the recursion any more; compared words +U32
# binders
import Base

type BST is Data:
  BLeaf{}
  BNode{l: BST, v: U32, r: BST}

type BFrame is Data:
  BF{v: U32, other: BST, left: Bool}

law bst.pick:
  for l    : BST
  for v    : U32
  for r    : BST
  for path : List<&2, BFrame>
  for z    : Bool
  BST & List<&2, BFrame>

def bst.pick(l, v, r, path, z):
  match z:
    case True{}:
      (l, BF{v, r, True{}} <> path)
    case False{}:
      (r, BF{v, l, False{}} <> path)

law bst.step:
  for +x : U32
  for st : BST & List<&2, BFrame>
  BST & List<&2, BFrame>

def bst.step(x, st):
  match st:
    case (BLeaf{}, path):
      (BLeaf{}, path)
    case (BNode{l, v0, r}, path):
      +v = {v0 : U32}
      bst.pick(l, v, r, path, U32.is_lt(x, v))

law bst.down:
  for fuel : Nat
  for +x   : U32
  for st   : BST & List<&2, BFrame>
  BST & List<&2, BFrame>

def bst.down(fuel, x, st):
  match fuel:
    case 0n:
      st
    case 1n+f:
      bst.down(f, x, bst.step(x, st))

law bst.up:
  for path : List<&2, BFrame>
  for acc  : BST
  BST

def bst.up(path, acc):
  match path:
    case Nil{}:
      acc
    case BF{v, other, True{}} <> rest:
      bst.up(rest, BNode{acc, v, other})
    case BF{v, other, False{}} <> rest:
      bst.up(rest, BNode{other, v, acc})

law insert.fin:
  for +x : U32
  for st : BST & List<&2, BFrame>
  BST

def insert.fin(x, st):
  match st:
    case (BLeaf{}, path):
      bst.up(path, BNode{BLeaf{}, x, BLeaf{}})
    case (BNode{l, v, r}, path):
      bst.up(path, BNode{l, v, r})

law insert:
  for +x: U32
  for  t: BST
  BST

def insert(x, t):
  insert.fin(x, bst.down(8n, x, (t, Nil{})))

law inorder:
  for t   : BST
  for acc : U32
  U32

def inorder(t, acc):
  match t:
    case BLeaf{}:
      acc
    case BNode{l, v, r}:
      inorder(r, U32.add(U32.mul(inorder(l, acc), 10), v))

law main.out:
  U32

def main.out():
  t0 = {BLeaf{} : BST}
  t1 = insert(5, t0)
  t2 = insert(2, t1)
  t3 = insert(8, t2)
  t4 = insert(1, t3)
  t5 = insert(9, t4)
  inorder(t5, 0)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|12589
