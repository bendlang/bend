# #2135 x #2207 x #2211 x #2218: trees held in an Array's slots (read
# borrowed, or taken and written back), walked by a selector-first lookup
# and insert, split by colour, lent to a flat def, with a node whose U32,
# Bool and colour share a word.
import Base

type Color is Data:
  Red{}
  Black{}

type Tree is Data:
  Leaf{}
  Node{color: Color, l: Tree, key: U32, val: Bool, r: Tree}

def bit(b: Bool) -> U32:
  match b:
    case True{}:
      3
    case False{}:
      5

def col(c: Color) -> U32:
  match c:
    case Red{}:
      1
    case Black{}:
      2

def dig(t: Tree, acc: U32) -> U32:
  match t:
    case Leaf{}:
      U32.add(U32.mul(acc, 31), 7)
    case Node{c, l, k, v, r}:
      dig(r, U32.add(U32.mul(dig(l, U32.add(U32.mul(acc, 31), col(c))), 131),
        U32.add(k, bit(v))))

# read-only: the node is never taken
def has(t: Tree, o: Cmp, +k: U32) -> Bool:
  match t o:
    case Node{c, Node{c2, a, +ky, vy, b}, kx, vx, r} LT{}:
      has(Node{c2, a, ky, vy, b}, U32.cmp(k, ky), k)
    case Node{c, l, kx, vx, Node{c2, a, +ky, vy, b}} GT{}:
      has(Node{c2, a, ky, vy, b}, U32.cmp(k, ky), k)
    case Node{c, l, kx, vx, r} EQ{}:
      vx
    case t0 o:
      False{}

def has_at(t: Tree, +k: U32) -> Bool:
  match t:
    case Leaf{}:
      False{}
    case Node{c, l, +kx, vx, r}:
      has(Node{c, l, kx, vx, r}, U32.cmp(k, kx), k)

def ins(t: Tree, o: Cmp, +k: U32) -> Tree:
  match t o:
    case Node{c, Node{c2, a, +ky, vy, b}, kx, vx, r} LT{}:
      Node{c, ins(Node{c2, a, ky, vy, b}, U32.cmp(k, ky), k), kx, vx, r}
    case Node{c, l, kx, vx, Node{c2, a, +ky, vy, b}} GT{}:
      Node{c, l, kx, vx, ins(Node{c2, a, ky, vy, b}, U32.cmp(k, ky), k)}
    case Node{c, l, kx, vx, r} EQ{}:
      Node{Black{}, l, kx, Bool.not(vx), r}
    case Node{c, Leaf{}, kx, vx, r} LT{}:
      Node{c, Node{Red{}, Leaf{}, k, True{}, Leaf{}}, kx, vx, r}
    case Node{c, l, kx, vx, Leaf{}} GT{}:
      Node{c, l, kx, vx, Node{Red{}, Leaf{}, k, False{}, Leaf{}}}
    case Leaf{} o:
      Node{Black{}, Leaf{}, k, True{}, Leaf{}}

def insert(t: Tree, +k: U32) -> Tree:
  match t:
    case Leaf{}:
      Node{Black{}, Leaf{}, k, True{}, Leaf{}}
    case Node{c, l, +kx, vx, r}:
      ins(Node{c, l, kx, vx, r}, U32.cmp(k, kx), k)

def is_red(t: Tree) -> Tree & Bool:
  match t:
    case Node{Red{}, l, k, v, r}:
      (Node{Red{}, l, k, v, r}, True{})
    case t0:
      (t0, False{})

# a flat def lent a tree its caller uses again
def push(ok: Bool, t: Tree, ts: List<Tree>) -> List<Tree>:
  match ok:
    case True{}:
      t <> ts
    case False{}:
      ts

@unsafe
def keep(+n: Nat, a: Array<Tree>, +k: U32, ts: List<Tree>) -> List<Tree>:
  match n:
    case 0n:
      ts
    case 1n+p:
      keep.go(p, k, ts, Array.get(Tree, a, U32.and(k, 7)))

@unsafe
def keep.go(+p: Nat, +k: U32, ts: List<Tree>, r: Array<Tree> & Tree) -> List<Tree>:
  (a2, +t) = r
  keep(p, a2, U32.add(U32.mul(k, 5), 1), push(has_at(t, k), t, ts))

def put(+i: U32, +k: U32, r: Array<Tree> & Tree) -> Array<Tree>:
  (a, t) = r
  Array.set(Tree, a, i, insert(t, k))

def fill(n: Nat, +j: U32, a: Array<Tree>) -> Array<Tree>:
  match n:
    case 0n:
      a
    case 1n+p:
      +i = U32.and(j, 7)
      fill(p, U32.add(j, 1), put(i, U32.mod(U32.mul(j, 2654435761), 997),
        Array.get(Tree, a, i)))

@unsafe
def hits(n: Nat, a: Array<Tree>, +k: U32, acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+p:
      hits.go(p, k, acc, Array.get(Tree, a, U32.and(k, 7)))

@unsafe
def hits.go(+p: Nat, +k: U32, acc: U32, r: Array<Tree> & Tree) -> U32:
  (a2, t) = r
  hits.red(p, a2, k, acc, is_red(t))

@unsafe
def hits.red(+p: Nat, a2: Array<Tree>, +k: U32, acc: U32, q: Tree & Bool) -> U32:
  (t2, red) = q
  hits(p, a2, U32.add(U32.mul(k, 69069), 1), U32.add(U32.mul(acc, 3),
    U32.add(bit(has_at(t2, U32.mod(k, 997))), bit(red))))

@unsafe
def digs(n: Nat, +i: U32, a: Array<Tree>, acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+p:
      digs.go(p, i, acc, Array.get(Tree, a, i))

@unsafe
def digs.go(+p: Nat, +i: U32, acc: U32, r: Array<Tree> & Tree) -> U32:
  (a2, t) = r
  digs(p, U32.add(i, 1), a2, dig(t, acc))

def sums(ts: List<Tree>, acc: U32) -> U32:
  match ts:
    case Nil{}:
      acc
    case Con{t, rest}:
      sums(rest, dig(t, acc))

def mk(+j: U32) -> Array<Tree>:
  fill(3000n, j, Array.new(Tree, 8n, Leaf{}))

def run(+j: U32) -> U32 & U32 & U32 & U32:
  (digs(8n, 0, mk(j), 1), hits(2000n, mk(j), 12345, 0),
    sums(keep(200n, mk(j), 7, []), 3), digs(8n, 0, mk(U32.add(j, 1)), 2))

def show(r: U32 & U32 & U32 & U32) -> IO(Unit):
  (w, x, y, z) = r
  do IO<Unit>:
    Unit <- IO.print(U32.show(w))
    Unit <- IO.print(U32.show(x))
    Unit <- IO.print(U32.show(y))
    IO.print(U32.show(z))

def main() -> IO(Unit):
  show(run(1))

#|4049191879
#|2192366376
#|1841493366
#|3079406933
