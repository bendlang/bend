# peek arms under forks: one shared tree read, re-formed, rebuilt and dropped by parallel tasks
import Base

type Color is Data:
  Red{}
  Black{}

type Tree is Data:
  Leaf{}
  Node{color: Color, l: Tree, key: U32, r: Tree}

def col(c: Color) -> U32:
  match c:
    case Red{}:
      1
    case Black{}:
      2

def dig(t: Tree, +acc: U32) -> U32:
  match t:
    case Leaf{}:
      U32.add(U32.mul(acc, 31), 7)
    case Node{c, l, +k, r}:
      x y = dig(l, U32.add(U32.mul(acc, 31), col(c))) dig(r, U32.add(acc, k))
      U32.add(U32.mul(x, 131), U32.add(y, k))

def pick(m: U32) -> Color:
  match m:
    case 0:
      Red{}
    case _:
      Black{}

def gen(+d: Nat, +i: U32) -> Tree:
  match d:
    case 0n:
      Leaf{}
    case 1n+e:
      l r = gen(e, U32.mul(i, 2)) gen(e, U32.add(U32.mul(i, 2), 1))
      Node{pick(U32.mod(i, 2)), l, i, r}

def is_red(t: Tree) -> Tree & Bool:
  match t:
    case Node{Red{}, l, k, r}:
      (Node{Red{}, l, k, r}, True{})
    case t0:
      (t0, False{})

# walks down re-forming every node (peek), flipping red nodes' keys (take): a path copy of a shared tree
@unsafe def walk(t: Tree, +d: U32) -> Tree:
  match t:
    case Leaf{}:
      Leaf{}
    case Node{Red{}, l, k, r}:
      a b = walk(l, U32.inc(d)) walk(r, U32.inc(d))
      Node{Red{}, a, U32.add(k, d), b}
    case Node{Black{}, l, k, r}:
      walk.black(is_red(l), k, r, d)

@unsafe def walk.black(lz: Tree & Bool, k: U32, r: Tree, +d: U32) -> Tree:
  match lz:
    case (l, True{}):
      Node{Black{}, walk(l, U32.inc(d)), k, r}
    case (l, False{}):
      Node{Black{}, l, k, walk(r, U32.inc(d))}

def same(t: Tree) -> Tree:
  match t:
    case Leaf{}:
      Leaf{}
    case Node{c, l, k, r}:
      Node{c, l, k, r}

def waste(t: Tree, x: U32) -> U32:
  x

# four tasks over one tree: two read it, one rebuilds a path of it, one re-forms and drops it
def four(+t: Tree) -> U32:
  a b = dig(t, 0) dig(walk(t, 1), 0)
  c e = dig(same(t), 5) waste(same(t), 9)
  U32.add(U32.add(a, b), U32.add(c, e))

def many(+n: Nat, +t: Tree) -> U32:
  match n:
    case 0n:
      dig(t, 1)
    case 1n+p:
      x y = four(t) many(p, t)
      U32.add(x, y)

def fresh(+n: Nat, +d: Nat) -> U32:
  match n:
    case 0n:
      0
    case 1n+p:
      x y = many(3n, gen(d, U32.from_nat(n))) fresh(p, d)
      U32.add(x, y)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(many(40n, gen(9n, 1))))
    IO.print(U32.show(fresh(60n, 7n)))

#|1684414670
#|1871268912
