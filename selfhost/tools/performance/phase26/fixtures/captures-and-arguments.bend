# Remaining arguments cross the literal matcher; nested matches retain captures.
import Base

def choose(n: U32, +a: U32, b: U32) -> U32:
  match n:
    case 0: U32.add(a, b)
    case 2147483648:
      match a:
        case 0: U32.add(b, 5)
        case 4294967295: U32.add(b, 7)
        case _: U32.add(U32.mul(a, 3), b)
    case 4294967295: U32.sub(a, b)
    case _: U32.add(U32.mul(a, 11), b)

def bench(n: U32, +seed: U32) -> U32:
  choose(n, seed, U32.xor(seed, 12345))
