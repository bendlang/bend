# a term in a do block followed by ";" or by a line at the block's
# column (its first statement's) is a step, Unit <- term; the last
# term is the value
import Base

def twice(+s: String) -> IO(Unit):
  do IO<Unit>:
    IO.print(s)
    IO.print(s)

def main() -> IO(Unit):
  do IO<Unit>:
    twice("a"); IO.print("b")
    n : U32 <- do IO<U32>:
      IO.print("c")
      return 2
    do IO<Unit>:
      IO.print(U32.show(n))
    IO.print("d")

#|a
#|a
#|b
#|c
#|2
#|d
