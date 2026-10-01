import Base

# Two finite decisions use different final input positions. Their default
# remainder is demanded twice, so replacing it with the unadjusted Nat fails.
def select(n: Nat) -> U32:
  match n:
    case 0n: 11
    case 1n: 13
    case 2n++k: U32.add(U32.from_nat(k), U32.from_nat(k))

def select.second(prefix: U32, n: Nat) -> U32:
  match n:
    case 0n: U32.add(prefix, 17)
    case 1n: U32.add(prefix, 19)
    case 2n: U32.add(prefix, 23)
    case 3n++k: U32.add(prefix, U32.add(U32.from_nat(k), U32.from_nat(k)))

def accumulate(depth: Nat, +sum: U32) -> U32:
  match depth:
    case 0n: sum
    case 1n++k:
      +first = select(k)
      +second = select.second(sum, k)
      accumulate(k, U32.add(first, second))

def bench(size: U32, seed: U32) -> U32:
  accumulate(U32.to_nat(size), seed)

def main() -> U32:
  bench(32, 17)
