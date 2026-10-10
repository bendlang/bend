# io (io_terminal): IO.is_terminal and IO.terminal_width (#1464). The
# test's stdout is a pipe: no terminal, so 0 wide. Pty.open opens a
# pseudo-terminal 77 columns wide and answers the fd of its terminal
# side: a terminal, 77 wide.
import Base

def Pty.open(cols: U32) -> IO(U32):
  import "./terminal.c"
  import "./terminal.js"

def main() -> IO(Unit):
  do IO<Unit>:
    a : Bool <- IO.is_terminal(1)
    b : U32 <- IO.terminal_width(1)
    +t : U32 <- Pty.open(77)
    c : Bool <- IO.is_terminal(t)
    d : U32 <- IO.terminal_width(t)
    IO.print(Bool.show(a) ++ " " ++ U32.show(b) ++ " " ++ Bool.show(c) ++ " " ++ U32.show(d))

#|False 0 True 77
