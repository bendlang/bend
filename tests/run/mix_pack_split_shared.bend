# Two drafts meet: an arm split by a node's first field (a colour) reads
# that field through the reference, and the node's U32 and tag fields share
# a word (5 fields in 3 words, so the colour is not the first word's low
# bits). Every tree is shared, so the type is counted and each node is
# taken through ctr_take. The colour tested by a split, a lookahead that
# re-forms a child, a selector-first insert, a recolour of every node.
import Base

type Color is Data:
  Red{}
  Black{}
  Blue{}

type Tree is Data:
  Leaf{}
  Node{color: Color, l: Tree, key: U32, val: Bool, r: Tree}

def col(c: Color) -> U32:
  match c:
    case Red{}:
      1
    case Black{}:
      2
    case Blue{}:
      3

def bit(b: Bool) -> U32:
  match b:
    case True{}:
      5
    case False{}:
      11

def dig(t: Tree, acc: U32) -> U32:
  match t:
    case Leaf{}:
      U32.add(U32.mul(acc, 31), 7)
    case Node{c, l, k, v, r}:
      dig(r, U32.add(U32.mul(dig(l, U32.add(U32.mul(acc, 31), col(c))), 131),
        U32.add(k, bit(v))))

def pick.go(m: U32) -> Color:
  match m:
    case 0:
      Red{}
    case 1:
      Black{}
    case _:
      Blue{}

def pick(i: U32) -> Color:
  pick.go(U32.mod(i, 3))

def gen(+d: Nat, +i: U32) -> Tree:
  match d:
    case 0n:
      Leaf{}
    case 1n+e:
      Node{pick(i), gen(e, U32.mul(i, 2)), U32.mul(i, 2654435761),
        U32.is_eq(U32.and(i, 1), 0), gen(e, U32.add(U32.mul(i, 2), 1))}

def recolor(t: Tree) -> Tree:
  match t:
    case Node{Red{}, l, k, v, r}:
      Node{Red{}, l, k, v, r}
    case Node{Black{}, l, k, v, r}:
      Node{Red{}, l, k, v, r}
    case t0:
      t0

def recolor_all(t: Tree) -> Tree:
  match t:
    case Leaf{}:
      Leaf{}
    case Node{c, l, k, v, r}:
      recolor(Node{c, recolor_all(l), k, v, recolor_all(r)})

def is_red(t: Tree) -> Tree & Bool:
  match t:
    case Node{Red{}, l, k, v, r}:
      (Node{Red{}, l, k, v, r}, True{})
    case t0:
      (t0, False{})

def red_dig(p: Tree & Bool) -> U32:
  match p:
    case (t, True{}):
      U32.add(dig(t, 3), 1)
    case (t, False{}):
      dig(t, 3)

# a lookahead on the left child's colour that re-forms it
def lean(t: Tree) -> Tree:
  match t:
    case Node{c, Node{Red{}, a, ka, va, b}, k, v, r}:
      Node{Blue{}, Node{Black{}, a, ka, va, b}, k, v, r}
    case t0:
      t0

def lean_all(t: Tree) -> Tree:
  match t:
    case Leaf{}:
      Leaf{}
    case Node{c, l, k, v, r}:
      lean(Node{c, lean_all(l), k, v, lean_all(r)})

def ins(t: Tree, o: Cmp, +k: U32) -> Tree:
  match t o:
    case Node{c, Node{c2, a, +ky, vy, b}, kx, vx, r} LT{}:
      Node{c, ins(Node{c2, a, ky, vy, b}, U32.cmp(k, ky), k), kx, vx, r}
    case Node{c, l, kx, vx, Node{c2, a, +ky, vy, b}} GT{}:
      Node{c, l, kx, vx, ins(Node{c2, a, ky, vy, b}, U32.cmp(k, ky), k)}
    case Node{c, l, kx, vx, r} EQ{}:
      Node{Blue{}, l, kx, vx, r}
    case Node{c, Leaf{}, kx, vx, r} LT{}:
      Node{c, Node{Red{}, Leaf{}, k, True{}, Leaf{}}, kx, vx, r}
    case Node{c, l, kx, vx, Leaf{}} GT{}:
      Node{c, l, kx, vx, Node{Black{}, Leaf{}, k, False{}, Leaf{}}}
    case Leaf{} o:
      Node{Red{}, Leaf{}, k, True{}, Leaf{}}

def insert(t: Tree, +k: U32) -> Tree:
  match t:
    case Leaf{}:
      Node{Red{}, Leaf{}, k, True{}, Leaf{}}
    case Node{c, l, +kx, vx, r}:
      ins(Node{c, l, kx, vx, r}, U32.cmp(k, kx), k)

def inserts(+n: Nat, t: Tree, +s: U32) -> Tree:
  match n:
    case 0n:
      t
    case 1n+m:
      inserts(m, insert(t, s), U32.add(U32.mul(s, 1103515245), 12345))

# every def on a tree another holder reads afterwards: the old tree must be
# unchanged
def run(+d: Nat, +i: U32) -> U32:
  +t = gen(d, i)
  a = dig(recolor_all(t), 1)
  b = red_dig(is_red(t))
  c = dig(lean_all(t), 2)
  e = dig(inserts(200n, t, U32.add(i, 7)), 3)
  f = dig(inserts(100n, lean_all(recolor_all(t)), i), 4)
  g = red_dig(is_red(recolor(t)))
  z = dig(t, 5)
  U32.add(z, U32.add(a, U32.add(b, U32.add(c, U32.add(e, U32.add(f, g))))))

def loop(+n: Nat, acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+p:
      +i = U32.from_nat(n)
      loop(p, U32.add(U32.mul(acc, 3), run(3n, i)))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(run(8n, 1)))
    Unit <- IO.print(U32.show(run(1n, 2)))
    Unit <- IO.print(U32.show(run(0n, 3)))
    IO.print(U32.show(loop(60n, 0)))

#|1677514471
#|4009945915
#|210755301
#|206912812
