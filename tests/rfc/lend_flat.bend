# a flat def lent a box its caller still uses: kept in one arm, dropped, matched, handed on or returned in others
import Base

type Tree is Data:
  Leaf{}
  Node{l: Tree, key: U32, r: Tree}

def dig(t: Tree, +acc: U32) -> U32:
  match t:
    case Leaf{}:
      U32.add(U32.mul(acc, 31), 7)
    case Node{l, k, r}:
      dig(r, U32.add(U32.mul(dig(l, acc), 131), k))

def gen(+d: Nat, +i: U32) -> Tree:
  match d:
    case 0n:
      Leaf{}
    case 1n+e:
      Node{gen(e, U32.mul(i, 2)), i, gen(e, U32.add(U32.mul(i, 2), 1))}

def lit() -> Tree:
  Node{Node{Leaf{}, 1, Leaf{}}, 2, Node{Leaf{}, 3, Leaf{}}}

def sum(xs: List<&2, Tree>, +acc: U32) -> U32:
  match xs:
    case Nil{}:
      acc
    case t <> r:
      sum(r, dig(t, acc))

# keeps t in one arm, drops it in the other
def push(z: Bool, t: Tree, acc: List<&2, Tree>) -> List<&2, Tree>:
  match z:
    case True{}:
      t <> acc
    case False{}:
      acc

def five.two(+t: Tree, acc: List<&2, Tree>) -> List<&2, Tree>:
  t <> t <> acc

def five.open(t: Tree, acc: List<&2, Tree>) -> List<&2, Tree>:
  match t:
    case Leaf{}:
      Leaf{} <> acc
    case Node{l, k, r}:
      r <> Node{Leaf{}, k, Leaf{}} <> acc

# five ways: keep twice, take apart, hand on, return, drop
def five(m: U32, t: Tree, acc: List<&2, Tree>) -> List<&2, Tree>:
  match m:
    case 0:
      five.two(t, acc)
    case 1:
      five.open(t, acc)
    case 2:
      push(True{}, t, acc)
    case 3:
      t <> acc
    case _:
      acc

# the same def called by a caller that keeps its tree and by one that gives it away
def both(+m: U32, +t: Tree, acc: List<&2, Tree>) -> List<&2, Tree>:
  five(U32.mod(U32.add(m, 2), 5), t, five(m, t, acc))

# the same tree twice in one call: lent and given
def twin(a: Tree, b: Tree, z: Bool) -> U32:
  match z:
    case True{}:
      dig(a, 1)
    case False{}:
      dig(b, 2)

def twins(+t: Tree, z: Bool) -> U32:
  twin(t, t, z)

def twins3(+t: Tree, +z: Bool) -> U32:
  U32.add(twin(t, t, z), dig(t, 3))

def run(+n: Nat, +t: Tree, acc: List<&2, Tree>) -> List<&2, Tree>:
  match n:
    case 0n:
      acc
    case 1n+p:
      +m = U32.from_nat(n)
      run(p, t, both(U32.mod(m, 5), t, push(U32.is_eq(U32.mod(m, 3), 0), t, acc)))

# a fresh tree per step, never shared before it is lent
def fresh(+n: Nat, acc: List<&2, Tree>) -> List<&2, Tree>:
  match n:
    case 0n:
      acc
    case 1n+p:
      +m = U32.from_nat(n)
      +t = gen(3n, m)
      fresh(p, push(U32.is_eq(U32.mod(m, 2), 0), t, five(U32.mod(m, 5), t, acc)))

def par(+n: Nat, +t: Tree) -> U32:
  match n:
    case 0n:
      dig(t, 0)
    case 1n+p:
      a b = sum(run(7n, t, []), U32.from_nat(n)) par(p, t)
      U32.add(a, U32.add(b, twins3(t, U32.is_eq(U32.mod(U32.from_nat(n), 2), 0))))

# a closure made by the lent def captures the tree
type Fn is Type:
  Fn{f: U32 -> U32, tag: U32}

def top(t: Tree) -> U32:
  match t:
    case Leaf{}:
      7
    case Node{l, k, r}:
      k

def later(z: Bool, t: Tree) -> Fn:
  match z:
    case True{}:
      Fn{x => U32.add(x, top(t)), 1}
    case False{}:
      Fn{x => x, 2}

def call(g: Fn, x: U32) -> U32:
  match g:
    case Fn{f, n}:
      U32.add(n, f(x))

def clo(+n: Nat, +t: Tree, acc: U32) -> U32:
  match n:
    case 0n:
      U32.add(acc, dig(t, 9))
    case 1n+p:
      clo(p, t, U32.add(acc, call(later(U32.is_eq(U32.mod(U32.from_nat(n), 2), 0), t), 1)))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(sum(run(40n, gen(4n, 1), []), 0)))
    Unit <- IO.print(U32.show(sum(run(11n, lit(), []), 0)))
    Unit <- IO.print(U32.show(sum(fresh(300n, []), 0)))
    Unit <- IO.print(U32.show(U32.add(twins(gen(3n, 1), True{}), twins(gen(3n, 2), False{}))))
    Unit <- IO.print(U32.show(U32.add(twins3(gen(3n, 1), True{}), twins3(lit(), False{}))))
    Unit <- IO.print(U32.show(par(200n, gen(6n, 1))))
    IO.print(U32.show(clo(50n, gen(4n, 1), 0)))

#|2799445384
#|3296398237
#|2178155738
#|4130772560
#|653109127
#|3949310216
#|2252982881
