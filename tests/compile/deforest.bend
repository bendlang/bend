# A consumer called on what a producer builds runs as one fused def, so
# the intermediate nodes are never built: a chain of transforms, a tree
# built in parallel, a producer bound by a lone let, an extra consumer
# argument, a shape-changing filter, a consumer that drops a field, and a
# value with a second use, which stays built.
import Base

type Tree is Data:
  Tip{v: U32}
  Fork{l: Tree, r: Tree}

type Chain is Data:
  End{}
  Link{v: U32, rest: Chain}

def grow(+d: Nat, +s: U32) -> Tree:
  match d:
    case 0n:
      Tip{(s * 1664525 : U32)}
    case 1n+p:
      a b = grow(p, (s + 1 : U32)) grow(p, (s + 7 : U32))
      Fork{a, b}

def bump(t: Tree, +k: U32) -> Tree:
  match t:
    case Tip{v}:
      Tip{U32.xor(v, k)}
    case Fork{l, r}:
      a b = bump(l, k) bump(r, k)
      Fork{a, b}

def sum(t: Tree) -> U32:
  match t:
    case Tip{v}:
      v
    case Fork{l, r}:
      a b = sum(l) sum(r)
      (U32.mul(a, 3) + b : U32)

def left(t: Tree) -> U32:
  match t:
    case Tip{v}:
      v
    case Fork{l, r}:
      left(l)

def count(n: Nat, +s: U32) -> Chain:
  match n:
    case 0n:
      End{}
    case 1n+p:
      Link{(s * 31 : U32), count(p, (s + 1 : U32))}

def keep(b: Bool, +v: U32, rest: Chain) -> Chain:
  match b:
    case False{}:
      rest
    case True{}:
      Link{v, rest}

def odds(c: Chain) -> Chain:
  match c:
    case End{}:
      End{}
    case Link{+v, rest}:
      keep(U32.is_eq(U32.and(v, 1), 1), v, odds(rest))

def digest(c: Chain, +salt: U32) -> U32:
  match c:
    case End{}:
      salt
    case Link{v, rest}:
      U32.xor(v, U32.mul(33, digest(rest, salt)))

def main() -> U32:
  a = sum(bump(bump(grow(6n, 5), 17), 3))
  t = grow(5n, 9)
  b = sum(t)
  c = left(bump(grow(7n, 2), 9))
  d = digest(odds(count(50n, 4)), 13)
  +u = grow(4n, 1)
  e = U32.xor(sum(u), sum(bump(u, 5)))
  U32.xor(U32.xor(a, b), U32.xor(c, U32.xor(d, e)))

#|230445706
