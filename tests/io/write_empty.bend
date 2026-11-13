# Empty writes must not add buffers while stdout waits for a flush.
import Base

def empty_chunks() -> IO(U32):
  import "./write_empty.js"

def main() -> IO(Unit):
  do IO<Unit>:
    IO.write("before")
    IO.write("")
    IO.write("")
    n : U32 <- empty_chunks()
    IO.print("after")
    IO.print(U32.show(n))

#|beforeafter
#|0
