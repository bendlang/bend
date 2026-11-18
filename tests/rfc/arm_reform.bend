# peek arms: an arm that re-forms its node; unique, shared, static, swapped, partial
import Base

type Color is Data:
  Red{}
  Black{}
  Blue{}

type Tree is Data:
  Leaf{}
  Node{color: Color, l: Tree, key: U32, r: Tree}

def col(c: Color) -> U32:
  match c:
    case Red{}:
      1
    case Black{}:
      2
    case Blue{}:
      3

def dig(t: Tree, acc: U32) -> U32:
  match t:
    case Leaf{}:
      U32.add(U32.mul(acc, 31), 7)
    case Node{c, l, k, r}:
      dig(r, U32.add(U32.mul(dig(l, U32.add(U32.mul(acc, 31), col(c))), 131), k))

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
      Node{pick(i), gen(e, U32.mul(i, 2)), i, gen(e, U32.add(U32.mul(i, 2), 1))}

def same(t: Tree) -> Tree:
  match t:
    case Leaf{}:
      Leaf{}
    case Node{c, l, k, r}:
      Node{c, l, k, r}

def swap(t: Tree) -> Tree:
  match t:
    case Leaf{}:
      Leaf{}
    case Node{c, l, k, r}:
      Node{c, r, k, l}

def rekey(t: Tree, k2: U32) -> Tree:
  match t:
    case Leaf{}:
      Leaf{}
    case Node{c, l, k, r}:
      Node{c, l, k2, r}

def recolor(t: Tree) -> Tree:
  match t:
    case Node{Red{}, l, k, r}:
      Node{Red{}, l, k, r}
    case Node{Black{}, l, k, r}:
      Node{Red{}, l, k, r}
    case t0:
      t0

def is_red(t: Tree) -> Tree & Bool:
  match t:
    case Node{Red{}, l, k, r}:
      (Node{Red{}, l, k, r}, True{})
    case t0:
      (t0, False{})

def peekkey(t: Tree) -> Tree & U32:
  match t:
    case Leaf{}:
      (Leaf{}, 0)
    case Node{c, l, +k, r}:
      (Node{c, l, k, r}, k)

def twice(t: Tree) -> Tree & Tree:
  match t:
    case Leaf{}:
      (Leaf{}, Leaf{})
    case Node{+c, +l, +k, +r}:
      (Node{c, l, k, r}, Node{c, l, k, r})

def half(t: Tree) -> Tree & U32:
  match t:
    case Leaf{}:
      (Leaf{}, 0)
    case Node{c, +l, k, r}:
      (Node{c, l, k, r}, dig(l, 0))

def look(t: Tree) -> Tree:
  match t:
    case Node{c, Node{c2, a, +k2, b}, k, r}:
      Node{c, Node{c2, a, k2, b}, U32.add(k, k2), r}
    case t0:
      t0

def rot(t: Tree) -> Tree:
  match t:
    case Node{c, Node{Red{}, a, k2, b}, k, r}:
      Node{Red{}, a, k2, Node{c, b, k, r}}
    case t0:
      t0

def dropper(t: Tree) -> U32:
  match t:
    case Leaf{}:
      5
    case Node{Red{}, l, k, r}:
      k
    case Node{c, l, k, r}:
      dig(Node{c, l, k, r}, 9)

def fst_dig(p: Tree & U32) -> U32:
  match p:
    case (t, k):
      U32.add(dig(t, 3), k)

def red_dig(p: Tree & Bool) -> U32:
  match p:
    case (t, True{}):
      U32.add(dig(t, 3), 1)
    case (t, False{}):
      dig(t, 3)

def two_dig(p: Tree & Tree) -> U32:
  match p:
    case (a, b):
      U32.add(dig(a, 1), dig(b, 2))

# every def on a unique tree
def uniq(+d: Nat, +i: U32) -> U32:
  a = dig(same(gen(d, i)), 0)
  b = dig(swap(gen(d, i)), 0)
  c = dig(rekey(gen(d, i), 77), 0)
  e = dig(recolor(gen(d, i)), 0)
  f = red_dig(is_red(gen(d, i)))
  g = fst_dig(peekkey(gen(d, i)))
  h = two_dig(twice(gen(d, i)))
  j = fst_dig(half(gen(d, i)))
  k = dig(look(gen(d, i)), 0)
  l = dig(rot(gen(d, i)), 0)
  m = dropper(gen(d, i))
  U32.add(a, U32.add(b, U32.add(c, U32.add(e, U32.add(f, U32.add(g, U32.add(h, U32.add(j, U32.add(k, U32.add(l, m))))))))))

# every def on a tree another holder reads afterwards: the old tree must be unchanged
def shar(+d: Nat, +i: U32) -> U32:
  +t = gen(d, i)
  a = dig(same(t), 0)
  b = dig(swap(t), 0)
  c = dig(rekey(t, 77), 0)
  e = dig(recolor(t), 0)
  f = red_dig(is_red(t))
  g = fst_dig(peekkey(t))
  h = two_dig(twice(t))
  j = fst_dig(half(t))
  k = dig(look(t), 0)
  l = dig(rot(t), 0)
  m = dropper(t)
  z = dig(t, 0)
  U32.add(z, U32.add(a, U32.add(b, U32.add(c, U32.add(e, U32.add(f, U32.add(g, U32.add(h, U32.add(j, U32.add(k, U32.add(l, m)))))))))))

def lit() -> Tree:
  Node{Black{}, Node{Red{}, Leaf{}, 1, Leaf{}}, 2, Node{Blue{}, Leaf{}, 3, Leaf{}}}

def stat() -> U32:
  a = dig(same(lit()), 0)
  b = dig(swap(lit()), 0)
  e = dig(recolor(lit()), 0)
  f = red_dig(is_red(lit()))
  h = two_dig(twice(lit()))
  k = dig(look(lit()), 0)
  l = dig(rot(lit()), 0)
  m = dropper(lit())
  U32.add(a, U32.add(b, U32.add(e, U32.add(f, U32.add(h, U32.add(k, U32.add(l, m)))))))

def loop(+n: Nat, acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+p:
      +i = U32.from_nat(n)
      loop(p, U32.add(acc, U32.add(uniq(4n, i), shar(4n, i))))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(uniq(6n, 1)))
    Unit <- IO.print(U32.show(shar(6n, 1)))
    Unit <- IO.print(U32.show(uniq(1n, 3)))
    Unit <- IO.print(U32.show(shar(1n, 4)))
    Unit <- IO.print(U32.show(stat()))
    IO.print(U32.show(loop(300n, 0)))

#|4032790191
#|337179209
#|48532358
#|85475844
#|3083974719
#|2235464258
