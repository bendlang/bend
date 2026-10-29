# The event loop must create its wake pipe before making its read end
# nonblocking. A blocking read end can hang the loop after a wake.
import Base

def Wake.check() -> IO(Unit):
  import "./wake_pipe.c"

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- Wake.check()
    IO.print("wake pipe is nonblocking")

#|wake pipe is nonblocking
