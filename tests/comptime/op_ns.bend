# an operator inside a ~ argument is named at the argument's end (Nat's
# unless annotated inside), so the instance and the caller's copy agree:
# annotate inside the argument for another type
import Base

def T(~f: U32 -> U32, x: U32) -> U32:
  f(x)

def main() -> IO(Unit):
  IO.print(U32.show((T(~(x => (x + 1 : U32)), 41) : U32)))

#|42
