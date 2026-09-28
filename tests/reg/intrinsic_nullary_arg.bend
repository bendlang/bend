# regression witness (#1093): U32.is_eq on a nullary def's call is
# emitted with no asked type; its result took the BOX layout, so Bool.or
# read the raw word as a boxed Bool and C printed True where JS said False
import Base

def K() -> U32: 1

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(Bool.show(U32.is_eq(0, K()) || False{}))
    IO.print(Bool.show(False{} || U32.is_eq(0, K())))
    IO.print(Bool.show(U32.is_eq(1, K()) || False{}))
    IO.print(Bool.show(Bool.xor(U32.is_eq(0, K()), True{})))
    IO.print(Bool.show(Bool.xor(True{}, U32.is_eq(1, K()))))

#|False
#|False
#|True
#|True
#|False
