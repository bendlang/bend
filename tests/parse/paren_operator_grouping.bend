# parentheses regroup operator chains against their native
# associativity and precedence -- ported from bend3
import Base

law main.out:
  U32

def main.out():
  a = (10 - (2 - 1) : U32)        # 9 (native left-assoc reads 10-2-1 = 7)
  b = ((2 + 3) * 4 : U32)         # 20 (native * over +)
  c = (6 .&. (3 .|. 4) : U32)     # 6 (native .&. over .|.)
  (a + b * 10 + c * 1000 : U32)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|6209
