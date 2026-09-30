# Native U32 literals: dense gaps, sparse keys and unsigned full-width keys.
import Base

def dense(n: U32) -> U32:
  match n:
    case 0: 11
    case 1: 13
    case 2: 17
    case 4: 19
    case 7: 23
    case 15: 29
    case _: 31

def sparse(n: U32) -> U32:
  match n:
    case 4294967295: 37
    case 0: 41
    case 3000000000: 43
    case 2147483648: 47
    case 65536: 53
    case 2147483647: 59
    case _: 61

def bench(+n: U32, seed: U32) -> U32:
  U32.add(U32.add(U32.mul(dense(n), 67), sparse(n)), seed)
