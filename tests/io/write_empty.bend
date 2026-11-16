# io (io_write_empty): empty writes add no chunks to stdout's queue, which
# counts bytes, so they never reach its 64 KiB flush and would pile up.
# Stdout.hold queues stdout even on a TTY; after "before" and two empty
# writes, the queue holds the one chunk. JS only: the C lane has no queue.
import Base

def Stdout.hold() -> IO(Unit):
  import "./write_empty.js"

def Stdout.held() -> IO(U32):
  import "./write_empty.js"

def main() -> IO(Unit):
  do IO<Unit>:
    Stdout.hold()
    IO.write("before")
    IO.write("")
    IO.write("")
    n : U32 <- Stdout.held()
    IO.print("after")
    IO.print(U32.show(n))

#|beforeafter
#|1
