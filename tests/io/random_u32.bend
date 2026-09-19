# io (io_random_u32): two draws from the host's entropy source differ.
import Base

law main:
  IO(Unit)

def main():
  do IO<Unit>:
    a : U32 <- IO.try(U32, IO.random_u32())
    b : U32 <- IO.try(U32, IO.random_u32())
    IO.print(Bool.show(U32.is_ne(a, b)))

#|True
