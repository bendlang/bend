# audit: the bitwise operators are spelled dotted, .&. .|. .^. --
# ported from bend3 unchanged but for the Base import
import Base

law main.out:
  U32

def main.out():
  a = (5 .&. 3 : U32)   # 1
  b = (5 .|. 3 : U32)   # 7
  c = (5 .^. 3 : U32)   # 6
  (a + 10 * b + 100 * c : U32)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|671
