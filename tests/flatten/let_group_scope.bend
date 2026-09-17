# bend3's -o grouping lane re-minted let keys and this fuzz shape
# caught a scope leak; bend has no grouping lane, and the shape's
# arithmetic core computes: a spaced % is U32.mod
import Base

law pa3:
  for a: U32
  for b: U32
  for c: U32
  U32

def pa3(a, b, c):
  (a + b - c - 65536 % 2147483648 : U32)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(pa3(4, 7, 1)))

#|4294901770
