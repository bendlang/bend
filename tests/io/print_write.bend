# io (io_print_write): print (newline) and write (raw) sequence in
# order through the event loop, and U32.show feeds a computed string
# to an effect.
import Base

law main:
  IO(U32)

def main():
  do IO<U32>:
    a : Unit <- IO.print("hello")
    b : Unit <- IO.write("num=")
    c : Unit <- IO.print(U32.show((40 + 2 : U32)))
    return 0

#|hello
#|num=42
