# io (io_fifo_eof): a computation parked on a FIFO wakes when its writer
# closes it, and reads the end: after data, with none, and at an fd past
# FD_SETSIZE. macOS's poll never reports a FIFO's close; its select does
# (#928), and select's sets must then reach any fd poll reached.
import Base

law fifo.drain:
  U32 -> U32 -> IO(U32)

def fifo.drain(len, hi):
  import "./fifo_eof.c"
  import "./fifo_eof.js"

def main() -> IO(Unit):
  do IO<Unit>:
    a : U32 <- fifo.drain(5, 0)
    u : Unit <- IO.print(U32.show(a))
    b : U32 <- fifo.drain(0, 0)
    v : Unit <- IO.print(U32.show(b))
    c : U32 <- fifo.drain(5, 1500)
    IO.print(U32.show(c))

#|5
#|0
#|5
