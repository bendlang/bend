# U32.mac64 returns zero outside the four words of its 128-bit result.
# In particular, the C backend must not return word 3 for every k >= 3.
import Base

def word(+k: U32) -> U32:
  U32.mac64(k, 0, 4294967295, 0, 4294967295, 0, 0, 0, 0)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(word(3)))
    IO.print(U32.show(word(4)))
    IO.print(U32.show(word(5)))
    IO.print(U32.show(word(4294967295)))
    IO.print(U32.show(word!(4)))

#|4294967294
#|0
#|0
#|0
#|0
