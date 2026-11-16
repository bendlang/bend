# A def that adds two or more calls to itself in its tail keeps every call
# but the last, which becomes the loop: each call takes the sum so far as
# the first parameter of d~acc and answers it grown, so the sum crosses the
# calls that stay without a frame of its own (C lane). The spellings: the
# calls bound by lets and added in either order, calls inside nested adds
# and under successors, an operand that consumes a list beside them, three
# calls, U32.add past 2^32, erased parameters, a tree lent to two folds
# and then given to a third, a sum that lands on 2^48-1, the def under a
# fork with another def beside the sum, a tree twenty thousand nodes deep
# on either side, and an Array of closures called at its leaves. A bound
# call used twice keeps the def a recursion. Every count comes from the
# command line's length (1 in the harness), which no compiler sees.
import Base

type Tree is Data:
  Leaf{v: Nat}
  Node{l: Tree, x: List<&2, Nat>, r: Tree}

def build(+d: Nat, +k: Nat) -> Tree:
  match d:
    case 0n:
      Leaf{k}
    case 1n+p:
      Node{build(p, Nat.mul(k, 2n)), List.range(Nat.mod(k, 5n)), build(p, Nat.add(Nat.mul(k, 2n), 1n))}

def total(xs: List<&2, Nat>) -> Nat:
  match xs:
    case Nil{}:
      0n
    case Con{h, t}:
      Nat.add(h, total(t))

def fold(t: Tree) -> Nat:
  match t:
    case Leaf{v}:
      v
    case Node{l, x, r}:
      Nat.add(total(x), Nat.add(fold(l), fold(r)))

def flip(t: Tree) -> Nat:
  match t:
    case Leaf{v}:
      v
    case Node{l, x, r}:
      Nat.add(flip(r), 1n+Nat.add(List.length(&2, Nat, x), flip(l)))

def uses(+t: Tree) -> Nat:
  Nat.add(fold(t), Nat.add(flip(t), fold(t)))

def fib(+n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      match p:
        case 0n:
          1n
        case 1n+pp:
          a = fib(p)
          b = fib(pp)
          Nat.add(a, b)

def bif(+n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      match p:
        case 0n:
          1n
        case 1n+pp:
          a = bif(p)
          b = bif(pp)
          Nat.add(b, a)

def ufib(+n: Nat) -> U32:
  match n:
    case 0n:
      4000000000
    case 1n+p:
      match p:
        case 0n:
          300000001
        case 1n+pp:
          U32.add(ufib(pp), U32.add(ufib(p), 7))

def third(+n: Nat) -> Nat:
  match n:
    case 0n:
      1n
    case 1n+p:
      match p:
        case 0n:
          2n
        case 1n+pp:
          +a = third(p)
          b = third(pp)
          Nat.add(a, Nat.add(b, a))

def three(+n: Nat) -> Nat:
  match n:
    case 0n:
      1n
    case 1n+p:
      Nat.add(three(p), Nat.add(three(p), three(p)))

type Rose<-A: Data> is Data:
  Tip{}
  Bin{l: Rose<A>, v: A, r: Rose<A>}

def size(-A: Data, t: Rose<A>) -> Nat:
  match t:
    case Tip{}:
      0n
    case Bin{l, v, r}:
      1n+Nat.add(size(A, l), size(A, r))

def grow(+d: Nat) -> Rose<U32>:
  match d:
    case 0n:
      Tip{}
    case 1n+p:
      Bin{grow(p), 7, grow(p)}

def spine(+n: Nat, acc: Tree, right: Bool) -> Tree:
  match n:
    case 0n:
      acc
    case 1n+p:
      match right:
        case True{}:
          spine(p, Node{Leaf{n}, Nil{}, acc}, True{})
        case False{}:
          spine(p, Node{acc, Nil{}, Leaf{n}}, False{})

def t15(+d: Nat, +v: Nat) -> Nat:
  match d:
    case 0n:
      v
    case 1n+p:
      Nat.add(v, Nat.add(t15(p, v), t15(p, v)))

def big() -> Nat:
  Nat.add(Nat.mul(16777215n, 16777216n), 16777215n)

def psum(+d: Nat) -> Nat:
  match d:
    case 0n:
      1n
    case 1n+p:
      a b = psum(p) psum(p)
      Nat.add(a, b)

def beside(+n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      a b = psum(Nat.mod(n, 4n)) fib(Nat.mod(n, 9n))
      Nat.add(a, Nat.add(b, beside(p)))

def forked(+d: Nat, +n: Nat) -> Nat:
  match d:
    case 0n:
      fib(n)
    case 1n+p:
      a b = forked(p, n) fold(build(Nat.add(d, 3n), d))
      Nat.add(a, b)

def cell(n: U32) -> Array<(U32 -> U32)>:
  ALeaf{x => (x + n : U32)}

def calls(a: Array<(U32 -> U32)>) -> U32:
  match a:
    case ALeaf{f}:
      f(1)
    case ANode{xs, ys}:
      U32.add(calls(xs), calls(ys))

def show(+one: Nat) -> String:
  String.join([
    Nat.show(fold(build(Nat.mul(10n, one), 1n))),
    Nat.show(flip(build(Nat.mul(10n, one), 1n))),
    Nat.show(uses(build(Nat.mul(8n, one), 3n))),
    Nat.show(fib(Nat.mul(24n, one))),
    Nat.show(bif(Nat.mul(24n, one))),
    U32.show(ufib(Nat.mul(24n, one))),
    Nat.show(third(Nat.mul(20n, one))),
    Nat.show(three(Nat.mul(10n, one))),
    Nat.show(size(U32, grow(Nat.mul(12n, one)))),
    Nat.show(fold(spine(Nat.mul(20000n, one), Leaf{0n}, True{}))),
    Nat.show(fold(spine(Nat.mul(20000n, one), Leaf{0n}, False{}))),
    Nat.show(flip(spine(Nat.mul(20000n, one), Leaf{0n}, True{}))),
    Nat.show(t15(Nat.mul(3n, one), Nat.div(big(), 15n))),
    Nat.show(beside(Nat.mul(200n, one))),
    Nat.show(forked(Nat.mul(5n, one), Nat.mul(18n, one))),
    U32.show(calls(ANode{cell(41), cell(U32.from_nat(Nat.mul(6n, one)))}))], "\n")

def main() -> IO(Unit):
  do IO<Unit>:
    xs : List<String> <- IO.args()
    IO.print(show(List.length(&1, String, xs)))

#|1574396
#|1575421
#|689529
#|46368
#|46368
#|2914304144
#|38613965
#|59049
#|4095
#|200010000
#|200010000
#|200030000
#|281474976710655
#|1940
#|454767
#|49
