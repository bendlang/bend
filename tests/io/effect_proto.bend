# The foreign table keeps __proto__ as an own effect entry.
import Base

def __proto__() -> IO(U32):
  import "./effect_proto.js"

def main() -> IO(Unit):
  do IO<Unit>:
    x : U32 <- __proto__()
    IO.print(U32.show(x))

#|77
