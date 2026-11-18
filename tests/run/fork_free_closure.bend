# A fork-free segment takes its sequential path on the host whatever seq
# says. The one way such a segment runs with seq clear is a closure: Clo~apply
# may fork here (par's closure does), so a forking def under threads jumps to
# it directly, and it enters a fork-free closure body (deep's) with seq clear.
# That body then keeps its frames on the stack above the task's own frame:
# non-tail calls, a deep recursion, frames live across allocations and frees,
# a closure called from a closure. Counts come from the argument list, so no
# call is unrolled. Every line is the same at any thread count.
import Base

def len(xs: List<String>, acc: Nat) -> Nat:
  match xs:
    case Nil{}:
      acc
    case Con{h, t}:
      len(t, 1n+acc)

# non-tail recursion, fork-free
def deep(+n: Nat, +acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+p:
      U32.xor(deep(p, U32.add(U32.mul(acc, 1664525), 1013904223)), 1)

# a frame live across calls that allocate and free: builds a list, sums it
def build(+n: Nat, +x: U32) -> List<U32>:
  match n:
    case 0n:
      []
    case 1n+p:
      Con{x, build(p, U32.add(U32.mul(x, 3), 1))}

def total(xs: List<U32>) -> U32:
  match xs:
    case Nil{}:
      0
    case Con{h, t}:
      U32.add(h, total(t))

# forks
def par(+d: Nat, +i: U32) -> U32:
  match d:
    case 0n:
      U32.add(U32.mul(i, 1664525), 1013904223)
    case 1n+e:
      x y = par(e, U32.mul(i, 3)) par(e, U32.add(i, 7))
      U32.add(x, y)

# fork-free closure bodies: two non-tail calls, then a tail position op
def mk_deep(+n: Nat, +k: U32) -> U32 -> U32:
  +x => U32.add(deep(n, U32.xor(x, k)), total(build(n, x)))

# a fork-free closure that calls another closure it captured
def mk_wrap(f: U32 -> U32, +k: U32) -> U32 -> U32:
  x => U32.add(f(U32.add(x, k)), k)

# a forking closure body: makes Clo~apply a segment that may fork
def mk_par(+d: Nat, +k: U32) -> U32 -> U32:
  x => U32.add(par(d, x), k)

def pick.go(+m: Nat, +n: Nat, +d: Nat, +k: U32) -> U32 -> U32:
  match m:
    case 0n:
      mk_deep(n, k)
    case 1n+p:
      match p:
        case 0n:
          mk_par(d, k)
        case 1n+q:
          mk_wrap(mk_deep(n, k), 5)

def pick(+m: U32, +n: Nat, +d: Nat, +k: U32) -> U32 -> U32:
  pick.go(U32.to_nat(m), n, d, k)

# a forking def: each leaf calls a closure in non-tail position, then in tail
def tree(+d: Nat, +n: Nat, +i: U32) -> U32:
  match d:
    case 0n:
      f = pick(U32.mod(i, 3), n, 3n, i)
      g = pick(U32.mod(U32.add(i, 1), 3), n, 3n, i)
      +a = f(i)
      g(U32.add(a, 1))
    case 1n+e:
      x y = tree(e, n, U32.mul(i, 2)) tree(e, n, U32.add(U32.mul(i, 2), 1))
      U32.xor(x, y)

# a closure applied by a fork-free def, under a fork
def app(f: U32 -> U32, x: U32) -> U32:
  U32.add(f(x), 1)

def tree2(+d: Nat, +n: Nat, +i: U32) -> U32:
  match d:
    case 0n:
      app(pick(U32.mod(i, 3), n, 2n, i), i)
    case 1n+e:
      x y = tree2(e, n, U32.mul(i, 2)) tree2(e, n, U32.add(U32.mul(i, 2), 1))
      U32.add(x, y)

def go(+z: Nat) -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(tree(Nat.add(z, 6n), Nat.add(z, 40n), 1)))
    Unit <- IO.print(U32.show(tree2(Nat.add(z, 6n), Nat.add(z, 60n), 1)))
    Unit <- IO.print(U32.show(tree(Nat.add(z, 2n), Nat.add(z, 2000n), 1)))
    IO.print(U32.show((mk_wrap(mk_deep(Nat.add(z, 2000n), 3), 9))(7)))

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    go(len(args, 0n))

#|3053092064
#|372183353
#|16909332
#|456036040
