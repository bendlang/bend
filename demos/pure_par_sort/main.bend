# Parallel bitonic sort of a tree of 2^16 numbers: sort sorts the halves in
# opposite directions and flow merges them, leaf by leaf, with mix. Every
# fork is a parallel let; sort! runs on the GPU or every core. Prints sorted.
#   bend demos/pure_par_sort/main.bend -o sort && ./sort
import Base

# a number at depth 0, a pair of trees below
def Tree(d: Nat) -> Data:
  match d:
    case 0n:
      Nat
    case 1n+p:
      Sigma<&2, &2, Tree(p), _ => Tree(p)>

# the numbers 0 .. 2^d - 1, descending
def gen(d: Nat, +i: Nat) -> Tree(d):
  match d:
    case 0n:
      i
    case 1n++p:
      a b = gen(p, 1n+Nat.double(i)) gen(p, Nat.double(i))
      (a, b)

def pick(-A: Data, c: Bool, x: A, y: A) -> A:
  match c:
    case True{}:
      x
    case False{}:
      y

# the lesser (s = True) or greater leaves, leaf by leaf
def mix(d: Nat, +s: Bool, +x: Tree(d), +y: Tree(d)) -> Tree(d):
  match d:
    case 0n:
      pick(Nat, Bool.xor(s, Nat.is_lt(y, x)), x, y)
    case 1n++p:
      (xl, xr) = x
      (yl, yr) = y
      a b = mix(p, s, xl, yl) mix(p, s, xr, yr)
      (a, b)

# the bitonic merge
def flow(d: Nat, +s: Bool, t: Tree(d)) -> Tree(d):
  match d:
    case 0n:
      t
    case 1n++p:
      (+x, +y) = t
      a b = flow(p, s, mix(p, s, x, y)) flow(p, s, mix(p, Bool.not(s), x, y))
      (a, b)

def sort(d: Nat, s: Bool, t: Tree(d)) -> Tree(d):
  match d:
    case 0n:
      t
    case 1n++p:
      (x, y) = t
      a b = sort(p, True{}, x) sort(p, False{}, y)
      flow(1n+p, s, (a, b))

# are the leaves the numbers from i * 2^d, in order?
def ascending(d: Nat, +i: Nat, t: Tree(d)) -> Bool:
  match d:
    case 0n:
      Cmp.is_eq(Nat.cmp(t, i))
    case 1n++p:
      (x, y) = t
      Bool.and(ascending(p, Nat.double(i), x), ascending(p, 1n+Nat.double(i), y))

# spec for LAWS.bend only
def sum(d: Nat, t: Tree(d)) -> Nat:
  match d:
    case 0n:
      t
    case 1n++p:
      (x, y) = t
      Nat.add(sum(p, x), sum(p, y))

def main() -> IO(Unit):
  IO.print(pick(String, ascending(16n, 0n, sort!(16n, True{}, gen(16n, 0n))), "sorted", "unsorted"))
