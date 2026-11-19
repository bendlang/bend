# the reproducer of the use-after-free in #2207: an erased field first, a lookahead insert
import Base

type E is Data:
  EL{}
  EN{-n: Nat, l: E, b: Bool, k: U32, r: E}

def edig(t: E, acc: U32) -> U32:
  match t:
    case EL{}:
      U32.add(U32.mul(acc, 29), 5)
    case EN{n, l, b, k, r}:
      edig(r, U32.add(U32.mul(edig(l, U32.add(U32.mul(acc, 29), Bool.to_u32(b))), 137), k))

def eins(t: E, o: Cmp, +k: U32) -> E:
  match t o:
    case EL{} _:
      EN{0n, EL{}, True{}, k, EL{}}
    case EN{n, EN{m, a, b2, +ky, c}, b, kx, r} LT{}:
      EN{n, eins(EN{m, a, b2, ky, c}, U32.cmp(k, ky), k), b, kx, r}
    case EN{n, EL{}, b, kx, r} LT{}:
      EN{n, EN{0n, EL{}, False{}, k, EL{}}, b, kx, r}
    case EN{n, l, b, kx, EN{m, a, b2, +ky, c}} GT{}:
      EN{n, l, b, kx, eins(EN{m, a, b2, ky, c}, U32.cmp(k, ky), k)}
    case EN{n, l, b, kx, EL{}} GT{}:
      EN{n, l, b, kx, EN{0n, EL{}, True{}, k, EL{}}}
    case EN{n, l, b, kx, r} EQ{}:
      EN{n, l, Bool.not(b), kx, r}

def ebuild(+n: Nat, t: E) -> E:
  match n:
    case 0n:
      t
    case 1n+m:
      +x = U32.mod(U32.mul(U32.from_nat(n), 2654435761), 1000)
      ebuild(m, eins(t, U32.cmp(x, 500), x))

def main() -> U32:
  edig(ebuild(5n, EL{}), 2)

#|467313141
