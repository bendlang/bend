import Base

def a.b() -> U32: 1
def a_b() -> U32: 2
def inspect() -> IO(U32):
  import "./foreign_fid.js"
  import "./foreign_fid.c"
def main() -> IO(Unit):
  do IO<Unit>:
    n : U32 <- inspect()
    IO.print(U32.show(n))

#|1
