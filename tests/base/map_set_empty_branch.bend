import Base

def value(r: Map<&2, U32> & U32) -> U32:
  (m, v) = r
  v

def show(+m: Map<&2, U32>) -> IO(Unit):
  a = value(Map.get(U32, 0, m, "a"))
  b = value(Map.get(U32, 0, m, "b"))
  c = value(Map.get(U32, 0, m, "c"))
  IO.print(U32.show(a) ++ "/" ++ U32.show(b) ++ "/" ++ U32.show(c))

def main() -> IO(Unit):
  m : Map<&2, U32> = MNode{32n, MTip{}, MLeaf{"a", 7}}
  +inserted = Map.set(&2, U32, m, "b", 11)
  do IO<Unit>:
    Unit <- show(inserted)
    show(Map.set(&2, U32, inserted, "c", 13))

#|7/11/0
#|7/11/13
