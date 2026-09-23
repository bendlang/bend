# two datatypes name each other with no forward law: every datatype is
# declared up front, as a declaration runs nothing; only live defs keep
# to the order
import Base

type Tree is Data:
  Node{val: U32, kids: Forest}

type Forest is Data:
  FNil{}
  FCon{head: Tree, tail: Forest}

def Forest.sum(f: Forest) -> U32:
  match f:
    case FNil{}:
      0
    case FCon{t, fs}:
      match t:
        case Node{v, ks}:
          (v + Forest.sum(fs) : U32)

def main() -> U32:
  Forest.sum(FCon{Node{1, FNil{}}, FCon{Node{2, FCon{Node{5, FNil{}}, FNil{}}}, FNil{}}})

#|3
