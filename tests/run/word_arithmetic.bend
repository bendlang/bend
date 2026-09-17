# U32 arithmetic wraps at 2^32: add/sub/mul edge table, one law per bit
# (b2's product exceeds 2^53: plain JS float math would diverge from C,
# so interp/compiled agreement IS the pin)
# ported from bend3: infix ops become U32.add/sub/mul/is_eq, bits via bu
import Base

law bu:
  for b: Bool
  U32

def bu(b):
  match b:
    case False{}:
      0
    case True{}:
      1

law main.out:
  U32

def main.out():
  b0 = bu(U32.is_eq(U32.add(4294967295, 2), 1))
  b1 = bu(U32.is_eq(U32.sub(0, 1), 4294967295))
  b2 = bu(U32.is_eq(U32.mul(123456789, 987654321), 4227814277))
  b3 = bu(U32.is_eq(U32.add(2147483648, 2147483648), 0))
  b4 = bu(U32.is_eq(U32.mul(4294967295, 4294967295), 1))
  b5 = bu(U32.is_eq(U32.mul(65536, 65536), 0))
  U32.add(U32.add(U32.add(U32.add(U32.add(b0, U32.mul(b1, 2)), U32.mul(b2, 4)), U32.mul(b3, 8)), U32.mul(b4, 16)), U32.mul(b5, 32))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|63
