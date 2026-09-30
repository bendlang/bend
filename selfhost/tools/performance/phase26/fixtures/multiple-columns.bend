# Row priority, literal prefixes and catch-all binding across two U32 columns.
import Base

def bench(n: U32, seed: U32) -> U32:
  match n seed:
    case 0 0: 127
    case 0 rest: U32.add(rest, 131)
    case 2147483648 4294967295: 137
    case 4294967295 rest: U32.xor(rest, 139)
    case rest 0: U32.add(rest, 149)
    case left right: U32.add(U32.mul(left, 3), right)
