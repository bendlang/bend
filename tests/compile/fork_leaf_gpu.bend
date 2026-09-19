import Base
import ./fork_leaf_handoff.bend as Leaf

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(Leaf.pipeline(1)))
    IO.print(U32.show(Leaf.pipeline!(1)))
    IO.print(U32.show(Leaf.pipeline(1)))

#|24247809
#|24247809
#|24247809
