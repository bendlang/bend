# a float literal is one exact binary32 word, so a spelling and the
# arithmetic that rebuilds it meet: 1.5 * 2.0 is 3, and the readback
# rides F32.to_u32
import Base

law main.out:
  U32

def main.out():
  a = F32.to_u32((1.5 * 2.0 : F32))             # 3
  b = F32.to_u32((0.25 + 2.75 : F32))           # 3
  c = F32.to_u32((10.0 / 4.0 : F32))            # 2 (2.5 truncates)
  (a + 10 * b + 100 * c : U32)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|233
