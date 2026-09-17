# io (io_marshal_type_null): a live type value crosses the effect
# seam as null -- every type expression compiles to null, so the
# effect sees exactly what the compiled body sees (7 twice, never
# 13), and a null answer at Type rides a later crossing out as null
# again (7, the round trip). The interpreter runs the compiled JS
# itself, so both lanes print 21 byte-identically: the old
# interp-refuses-what-compiled-runs divergence class cannot exist
# with one value model.
import Base

law gauge:
  for T: Type
  IO(U32)

def gauge(T):
  import "./marshal_type_null.js"

law pick:
  IO(Type)

def pick():
  import "./marshal_type_null.js"

law main:
  IO(U32)

def main():
  do IO<U32>:
    n  : U32 <- gauge(Nat)
    m  : U32 <- gauge(List<&2, U32>)
    T2 : Type <- pick()
    p  : U32 <- gauge(T2)
    u  : Unit <- IO.print(U32.show(U32.add(U32.add(n, m), p)))
    return 0

#|21
