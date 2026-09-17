# the same without the inner annotation: the enclosing ": U32" does not
# reach into the ~ argument (its operator is already Nat's), and the
# instance says so
import Base

def T(~f: U32 -> U32, x: U32) -> U32:
  f(x)

def main() -> IO(Unit):
  IO.print(U32.show((T(~(x => x + 1), 41) : U32)))

#|Error:
#|- expected : Nat
#|- observed : U32
#|Context:
#|- f : @_:U32 -> U32
#|- x : U32
#|Location: T~0
#|6 | def T(~f: U32 -> U32, x: U32) -> U32:
#|7>|   f(x)
#|8 | 
#|exit 1
