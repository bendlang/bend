# a float chain (: F32) keeps the ladder: * / bind over + - exactly
# as on U32
import Base

law main.out:
  U32

def main.out():
  a = F32.to_u32((1.5 + 0.25 * 2.0 : F32))     # 2 (* first)
  b = F32.to_u32((6.0 - 4.0 / 2.0 : F32))      # 4 (/ first)
  (a * 10 + b : U32)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|24
