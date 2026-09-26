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
