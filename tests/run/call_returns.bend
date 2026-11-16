# A call whose callee would return at once from an arm that neither calls
# nor jumps runs that arm at the call and jumps to its own continuation,
# when the callee calls itself twice on one path. Such defs here, each
# called in non-tail position: an arm that frees the node it owns (sum), one
# that allocates (grow), a record result (span), a Nat match two levels deep
# (fib), a returning arm written after the calling one (last), a shared tree
# read by two walks (twice), a forking def (par) and forks over fork-free
# ones (fan). The rest keep their calls: an arm that drops another owned
# parameter (shed), and those that call themselves once on a path, a
# recursion down a list (take), two defs that call each other (ping, pong),
# a deep recursion (deep). Counts come from the argument list, so no call is
# unrolled. Every line is the same at any thread count.
import Base

type Tree is Data:
  Leaf{a: U32, b: U32}
  Node{l: Tree, r: Tree}

type Span is Data:
  Span{lo: U32, hi: U32, n: U32}

def len(xs: List<String>, acc: Nat) -> Nat:
  match xs:
    case Nil{}:
      acc
    case Con{h, t}:
      len(t, 1n+acc)

def grow(+d: Nat, +i: U32) -> Tree:
  match d:
    case 0n:
      Leaf{i, U32.xor(i, 2654435761)}
    case 1n+p:
      Node{grow(p, U32.add(U32.mul(i, 3), 1)),
        grow(p, U32.add(U32.mul(i, 5), 2))}

# owns the tree: the returning arm frees a node
def sum(t: Tree) -> U32:
  match t:
    case Leaf{a, b}:
      U32.add(a, b)
    case Node{l, r}:
      U32.add(sum(l), U32.mul(sum(r), 3))

# the returning arm is written last
def last(t: Tree) -> U32:
  match t:
    case Node{l, r}:
      U32.xor(last(l), U32.add(last(r), 1))
    case Leaf{a, b}:
      U32.sub(a, b)

def join(x: Span, y: Span) -> Span:
  match x y:
    case Span{a, b, n} Span{c, d, m}:
      Span{U32.add(a, c), U32.xor(b, d), U32.add(n, m)}

# a three-word result
def span(t: Tree) -> Span:
  match t:
    case Leaf{a, b}:
      Span{a, b, 1}
    case Node{l, r}:
      join(span(l), span(r))

def fill(+n: Nat, +x: U32) -> List<U32>:
  match n:
    case 0n:
      []
    case 1n+p:
      Con{x, fill(p, U32.add(U32.mul(x, 7), 3))}

# the returning arm drops the tree it was handed
def take(xs: List<U32>, t: Tree) -> U32:
  match xs:
    case Nil{}:
      9
    case Con{h, tl}:
      U32.add(h, U32.mul(take(tl, t), 3))

# the returning arm drops the list it was handed: it stays in the callee
def shed(t: Tree, xs: List<U32>) -> U32:
  match t:
    case Leaf{a, b}:
      U32.add(a, b)
    case Node{l, r}:
      U32.add(shed(l, fill(2n, 1)), U32.mul(shed(r, xs), 3))

def fib(+n: Nat) -> U32:
  match n:
    case 0n:
      0
    case 1n+p:
      match p:
        case 0n:
          1
        case 1n+pp:
          U32.add(fib(p), fib(pp))

law ping:
  for +n: Nat
  for +x: U32
  U32

law pong:
  for +n: Nat
  for +x: U32
  U32

@unsafe
def ping(n, x):
  match n:
    case 0n:
      x
    case 1n+p:
      U32.add(pong(p, U32.mul(x, 3)), 1)

@unsafe
def pong(n, x):
  match n:
    case 0n:
      U32.xor(x, 5)
    case 1n+p:
      U32.xor(ping(p, U32.add(x, 7)), 2)

def deep(+n: Nat, +acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+p:
      U32.xor(deep(p, U32.add(U32.mul(acc, 1664525), 1013904223)), 1)

# reads a shared tree: nothing is freed
def peek(+t: Tree, +k: U32) -> U32:
  match t:
    case Leaf{a, b}:
      U32.add(U32.mul(a, k), b)
    case Node{l, r}:
      U32.add(peek(l, k), U32.xor(peek(r, k), k))

def twice(+t: Tree) -> U32:
  U32.add(peek(t, 3), U32.mul(peek(t, 5), 7))

# forks; its 0n arm returns at once
def par(+d: Nat, +i: U32) -> U32:
  match d:
    case 0n:
      U32.add(U32.mul(i, 1664525), 1013904223)
    case 1n+e:
      x y = par(e, U32.mul(i, 3)) par(e, U32.add(i, 7))
      U32.add(x, y)

# a forking def: fork-free callees in a fork, then a forking one in a let
def fan(+d: Nat, +n: Nat, +i: U32) -> U32:
  match d:
    case 0n:
      x y = sum(grow(n, i)) last(grow(n, U32.add(i, 1)))
      +z = par(n, U32.xor(x, y))
      U32.add(z, deep(n, i))
    case 1n+e:
      x y = fan(e, n, U32.mul(i, 2)) fan(e, n, U32.add(U32.mul(i, 2), 1))
      U32.xor(x, y)

def show(s: Span) -> U32:
  match s:
    case Span{a, b, n}:
      U32.add(U32.add(a, b), n)

def go(+z: Nat) -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(sum(grow(Nat.add(z, 8n), 1))))
    Unit <- IO.print(U32.show(last(grow(Nat.add(z, 8n), 2))))
    Unit <- IO.print(U32.show(show(span(grow(Nat.add(z, 8n), 3)))))
    Unit <- IO.print(U32.show(take(fill(Nat.add(z, 500n), 1),
      grow(Nat.add(z, 4n), 4))))
    Unit <- IO.print(U32.show(shed(grow(Nat.add(z, 8n), 6),
      fill(Nat.add(z, 4n), 2))))
    Unit <- IO.print(U32.show(fib(Nat.add(z, 16n))))
    Unit <- IO.print(U32.show(ping(Nat.add(z, 1001n), 1)))
    Unit <- IO.print(U32.show(deep(Nat.add(z, 2000n), 1)))
    Unit <- IO.print(U32.show(twice(grow(Nat.add(z, 8n), 5))))
    Unit <- IO.print(U32.show(par(Nat.add(z, 8n), 1)))
    IO.print(U32.show(fan(Nat.add(z, 4n), Nat.add(z, 4n), 1)))

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    go(len(args, 0n))

#|3504967168
#|64941695
#|475404224
#|3807483578
#|1553809920
#|1597
#|1912416853
#|1995520893
#|625758758
#|1493590784
#|2698961760
