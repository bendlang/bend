# A large free must be available to another lane without growing the heap.
import Base

def Heap.check() -> IO(Unit):
  import "./heap_large_reuse.c"
  import "./heap_large_reuse.js"

def increment(x: U32) -> U32:
  U32.add(x, 1)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(increment!(41)))
    Heap.check()
    IO.print("allocator checks pass")

#|42
#|allocator checks pass
