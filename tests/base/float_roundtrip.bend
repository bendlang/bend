# a float chain (: F32) round-trips through arithmetic:
# literals build exact halves, and - and / undo + and * -- read
# back through F32.to_u32, which run_float_text does through F32.show
import Base

law main.out:
  U32

def main.out():
  x = (6.25 - 2.25 : F32)                        # 4.0
  y = (3.5 * 2.0 / 0.5 : F32)                  # 14.0 (left assoc)
  (F32.to_u32(x) + F32.to_u32(y) * 10 : U32)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|144
