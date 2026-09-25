# a do header's padded leading quantities carry the header's span: a bind
# or pure that refuses one points at the header, not at no line at all
import Base

type M<a, -A: Kind(a)> is Kind(a):
  W{v: A}

def M.pure(-A: Type, x: A) -> M<&1, A>:
  W{x}

def M.bind(-A: Type, -B: Type, m: M<&1, A>, f: A -> M<&1, B>) -> M<&1, B>:
  match m:
    case W{x}:
      f(x)

def r() -> M<&1, U32>:
  do M<U32>:
    x : U32 <- W{1}
    return (x + 1 : U32)

def main() -> U32:
  0

#|Error:
#|- expected : Type
#|- observed : Quant
#|Location: r
#|16 | def r() -> M<&1, U32>:
#|17>|   do M<U32>:
#|   |   ^^^^^^^^^
#|18 |     x : U32 <- W{1}
#|exit 1
