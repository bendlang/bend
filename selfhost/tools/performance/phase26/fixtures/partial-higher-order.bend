# A numeric matcher returned through partial applications and higher-order calls.
import Base

def select(n: U32, +offset: U32, value: U32) -> U32:
  match n:
    case 0: U32.add(offset, value)
    case 3000000000: U32.xor(offset, value)
    case 4294967295: U32.sub(offset, value)
    case _: U32.add(U32.mul(offset, 3), value)

def invoke(f: U32 -> U32, value: U32) -> U32:
  f(value)

def bench(n: U32, +seed: U32) -> U32:
  f = select(n)
  g = f(seed)
  invoke(g, U32.add(seed, 17))
