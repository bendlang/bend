# A constant array passed to an atomic op, whose C names its argument three
# times, is held in a local, so the op writes the array it returns, not a
# copy that is dropped.
import Base

def pick(p: Array<U32> & U32) -> U32:
  (a, x) = p
  x

def cell(r: Array<U32> & U32, +i: U32) -> U32:
  (a, o) = r
  pick(Array.get(U32, a, i))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(cell(Array.atomic.add(ALeaf{5}, 0, 3), 0)))
    IO.print(U32.show(cell(Array.atomic.cas(ANode{ALeaf{5}, ALeaf{6}}, 1,
      6, 9), 1)))

#|8
#|9
