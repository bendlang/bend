# io (io_foreign_arrow_arity): a foreign def takes its arity from its
# own parameter list, exactly like a local one. An assert spelled with
# arrows carries no forall clause, so the import branch of the fill
# left def.n at 0 while twice(x) declared one parameter, and comp.ts,
# which slices the type's domains by def.n, emitted a request with no
# argument in it: the companion then read a field nobody wrote.
import Base

law twice:
  U32 -> IO(U32)

def twice(x):
  import "./foreign_arrow_arity.c"
  import "./foreign_arrow_arity.js"

law main:
  IO(U32)

def main():
  do IO<U32>:
    x : U32 <- twice(21)
    u : Unit <- IO.print(U32.show(x))
    return 0

#|42
