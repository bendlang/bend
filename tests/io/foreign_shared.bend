# io (io_foreign_shared): a foreign def's C lays a value of the program's
# own type, and the program then SHARES it: `both` puts the tree into two
# nodes and sums both trees. Sharing heats Tree, so the program's own Node
# seals its fields; the twin's io_node must seal the same way, and it
# cannot know: whether a type is hot is a fact of the whole program. So
# io_node and io_box seal by the constructor's own hot bit in CID_T,
# the fact the emitter wrote for its own constructors, and a twin passes
# no flag (a twin that laid the tree unsealed fail-stopped here).
import Base

type Tree is Data:
  Empty{}
  Leaf{v: U32}
  Node{l: Tree, r: Tree}

law shared.make:
  U32 -> IO(Tree)

def shared.make(depth):
  import "./foreign_shared.c"
  import "./foreign_shared.js"

def tree.sum(t: Tree) -> U32:
  match t:
    case Leaf{v}:
      v
    case Node{l, r}:
      (tree.sum(l) + tree.sum(r) : U32)
    case other:
      0

def wrap(+t: Tree) -> Tree:
  Node{t, Node{t, Empty{}}}

def both(+t: Tree) -> U32:
  w = wrap(t)
  (tree.sum(w) + tree.sum(t) : U32)

def main() -> IO(Unit):
  do IO<Unit>:
    t : Tree <- shared.make(4)
    IO.print(U32.show(both(t)))

#|216
