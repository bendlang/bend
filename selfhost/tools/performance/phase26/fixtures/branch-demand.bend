# The unselected default diverges. Only the two literal arms are acquired.
import Base

@unsafe
def forever(n: U32) -> U32:
  forever(n)

@unsafe
def bench(n: U32, seed: U32) -> U32:
  match n:
    case 0: U32.add(seed, 151)
    case 4294967295: U32.add(seed, 157)
    case _: forever(seed)
