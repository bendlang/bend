# the same without the inner annotation: the enclosing ": U32" names the
# operator inside the ~ argument too, since the instance is picked once
# the parens close
import Base

def T(~f: U32 -> U32, x: U32) -> U32:
  f(x)

def main() -> IO(Unit):
  IO.print(U32.show((T(~(x => x + 1), 41) : U32)))

#|42
