# on the device: a shared tree re-formed, a path of it rebuilt, and lent to a flat def, by jobs run with `!`
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
    case Node{c, l, k, r}:
      dig(r, U32.add(U32.mul(dig(l, U32.add(U32.mul(acc, 31), col(c))), 131), k))

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
      Node{pick(U32.mod(i, 2)), gen(e, U32.mul(i, 2)), i, gen(e, U32.add(U32.mul(i, 2), 1))}

def is_red(t: Tree) -> Tree & Bool:
  match t:
    case Node{Red{}, l, k, r}:
      (Node{Red{}, l, k, r}, True{})
    case t0:
      (t0, False{})

def red_dig(p: Tree & Bool) -> U32:
  match p:
    case (t, True{}):
      U32.add(dig(t, 3), 1)
    case (t, False{}):
      dig(t, 3)

def same(t: Tree) -> Tree:
  match t:
    case Leaf{}:
      Leaf{}
    case Node{c, l, k, r}:
      Node{c, l, k, r}

# the left spine rebuilt: red nodes rekeyed, black ones re-formed around a new child
def spine(t: Tree, +d: U32) -> Tree:
  match t:
    case Leaf{}:
      Leaf{}
    case Node{Red{}, l, k, r}:
      Node{Red{}, spine(l, U32.inc(d)), U32.add(k, d), r}
    case Node{Black{}, l, k, r}:
      Node{Black{}, spine(l, U32.inc(d)), k, r}

def sum(xs: List<&2, Tree>, +acc: U32) -> U32:
  match xs:
    case Nil{}:
      acc
    case t <> r:
      sum(r, dig(t, acc))

def push(z: Bool, t: Tree, acc: List<&2, Tree>) -> List<&2, Tree>:
  match z:
    case True{}:
      t <> acc
    case False{}:
      acc

def job(+d: Nat, +i: U32) -> U32:
  +t = gen(d, i)
  a = dig(same(t), 0)
  b = red_dig(is_red(t))
  c = dig(spine(t, 1), 0)
  e = sum(push(True{}, t, push(False{}, t, push(True{}, t, []))), 0)
  f = red_dig(is_red(gen(d, U32.inc(i))))
  U32.add(a, U32.add(b, U32.add(c, U32.add(e, U32.add(f, dig(t, 0))))))

def fan(+n: Nat, +d: Nat) -> U32:
  match n:
    case 0n:
      0
    case 1n+p:
      x y = job!(d, U32.from_nat(n)) fan(p, d)
      U32.add(x, y)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(job(5n, 1)))
    Unit <- IO.print(U32.show(job!(5n, 1)))
    IO.print(U32.show(fan(64n, 6n)))

#|1542909318
#|1542909318
#|52465632
