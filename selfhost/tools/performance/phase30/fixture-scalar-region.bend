import Base
# A different, forward-declared scalar closure. Boolean matching precedes live
# branch-specific lambda binders; private-call let results must retain types.
def countdown(n: Nat, +x: U32, +flag: Bool) -> U32:
  match n:
    case 0n:
      U32.add(x, boolword(flag))
    case 1n+p:
      +y = choose(flag, x, U32.xor(x, 2654435761))
      +z = advance(y)
      countdown(p, z, U32.is_lt(y, z))

def choose(flag: Bool, +a: U32, +b: U32) -> U32:
  match flag:
    case True{}:
      U32.add(a, U32.shrn(b, 3n))
    case False{}:
      U32.xor(b, U32.shln(a, 5n))

def advance(+x: U32) -> U32:
  +y = U32.add(x, 1013904223)
  U32.mul(y, 1664525)

def boolword(flag: Bool) -> U32:
  match flag:
    case True{}:
      7
    case False{}:
      19

def bench(n: U32, seed: U32) -> U32:
  countdown(U32.to_nat(n), seed, U32.is_zero(U32.and(seed, 1)))

# Scalar result alone is not purity: the call graph below is cyclic and must
# remain ordinary code under the first acyclic helper rule.
def recursive(n: Nat, x: U32) -> U32:
  match n:
    case 0n:
      x
    case 1n+p:
      recursive(p, U32.inc(x))

def fallback(n: Nat, x: U32) -> U32:
  match n:
    case 0n:
      x
    case 1n+p:
      fallback(p, recursive(2n, x))
