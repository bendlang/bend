# u32_table (#867): a U32 match of dense literal arms is the same
# embedded-data idiom as a Nat one (a nibble popcount), and must
# compile to one CONSTV table with a clamped TAB_AT lookup whose last
# entry is the default, not a 32-deep bit tree. walk() reads the table
# with a dynamic index past the last arm, so 16..199 must take the
# default 100, not row 15.
import Base

law pop:
  for n: U32
  U32

def pop(n):
  match n:
    case 0: 0
    case 1: 1
    case 2: 1
    case 3: 2
    case 4: 1
    case 5: 2
    case 6: 2
    case 7: 3
    case 8: 1
    case 9: 2
    case 10: 2
    case 11: 3
    case 12: 2
    case 13: 3
    case 14: 3
    case 15: 4
    case _: 100

law walk:
  for +n: Nat
  U32

def walk(n):
  match n:
    case 0n:
      0
    case 1n+p:
      U32.add(pop(U32.from_nat(p)), walk(p))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(walk(200n)))

#|18432

# Phase25 appended dynamic API. The pinned fixture above is unchanged.
@unsafe
def bench(+size: U32,+seed: U32) -> U32:
  U32.add(walk(U32.to_nat(size)),pop(seed))
