# more arms that re-form their node: a parameter only read, two scrutinees, pairs and options in fields,
# a flag first, three colours with one named, a record of words in a list, a long list
import Base

type Tree is Data:
  Leaf{}
  Node{l: Tree, key: U32, r: Tree}

type Hue is Data:
  Red{}
  Green{}
  Blue{}

type Opt is Data:
  No{}
  Yes{t: Tree}

type Wrap is Data:
  WEnd{}
  Wrap{h: Hue, t: Tree, n: U32, q: Opt, next: Wrap}

type Flag is Data:
  FEnd{}
  Flag{on: Bool, t: Tree, next: Flag}

type V3 is Data:
  V3{x: U32, y: U32, z: U32}

def gen(+d: Nat, +i: U32) -> Tree:
  match d:
    case 0n:
      Leaf{}
    case 1n+e:
      Node{gen(e, U32.mul(i, 2)), i, gen(e, U32.add(U32.mul(i, 2), 1))}

def count(t: Tree, +acc: U32) -> U32:
  match t:
    case Leaf{}:
      U32.add(U32.mul(acc, 31), 7)
    case Node{l, k, r}:
      count(r, U32.add(U32.mul(count(l, acc), 131), k))

# reads its parameter and lends the node it re-forms
def reads(t: Tree) -> U32:
  match t:
    case Leaf{}:
      0
    case Node{l, +k, r}:
      U32.add(k, count(Node{l, k, r}, 1))

# two trees: each re-formed, swapped or dropped by the other's shape
def pair(a: Tree, b: Tree) -> Tree & Tree:
  match a b:
    case Node{l, k, r} Node{m, j, s}:
      (Node{m, j, s}, Node{l, k, r})
    case Node{l, k, r} Leaf{}:
      (Node{l, k, r}, Leaf{})
    case Leaf{} t:
      (t, Leaf{})

def pair_dig(p: Tree & Tree) -> U32:
  (a, b) = p
  U32.add(count(a, 3), count(b, 5))

def hue(h: Hue) -> U32:
  match h:
    case Red{}:
      1
    case Green{}:
      2
    case Blue{}:
      3

def opt(q: Opt) -> U32:
  match q:
    case No{}:
      9
    case Yes{t}:
      count(t, 4)

def wrap_dig(w: Wrap, +acc: U32) -> U32:
  match w:
    case WEnd{}:
      acc
    case Wrap{h, t, n, q, nx}:
      wrap_dig(nx, U32.add(U32.mul(acc, 7), U32.add(hue(h), U32.add(count(t, n), opt(q)))))

# one colour named: red is recoloured, the others come back whole
def cool(w: Wrap) -> Wrap:
  match w:
    case Wrap{Red{}, t, n, q, nx}:
      Wrap{Blue{}, t, n, q, cool(nx)}
    case Wrap{h, t, n, q, nx}:
      Wrap{h, t, n, q, nx}
    case WEnd{}:
      WEnd{}

def wraps.hue(m: U32) -> Hue:
  match m:
    case 0:
      Red{}
    case 1:
      Green{}
    case _:
      Blue{}

def wraps.opt(m: U32, t: Tree) -> Opt:
  match m:
    case 0:
      No{}
    case _:
      Yes{t}

def wraps(+n: Nat, +t: Tree, acc: Wrap) -> Wrap:
  match n:
    case 0n:
      acc
    case 1n+p:
      +m = U32.from_nat(n)
      wraps(p, t, Wrap{wraps.hue(U32.mod(m, 3)), t, m, wraps.opt(U32.mod(m, 2), t), acc})

def b2u(b: Bool) -> U32:
  match b:
    case True{}:
      1
    case False{}:
      0

def flag_dig(f: Flag, +acc: U32) -> U32:
  match f:
    case FEnd{}:
      acc
    case Flag{on, t, nx}:
      flag_dig(nx, U32.add(U32.mul(acc, 5), U32.add(b2u(on), count(t, 2))))

# a flag first: set flags come back whole, clear ones are set
def set(f: Flag) -> Flag:
  match f:
    case Flag{True{}, t, nx}:
      Flag{True{}, t, nx}
    case Flag{False{}, t, nx}:
      Flag{True{}, t, set(nx)}
    case FEnd{}:
      FEnd{}

def flags(+n: Nat, +t: Tree, acc: Flag) -> Flag:
  match n:
    case 0n:
      acc
    case 1n+p:
      flags(p, t, Flag{U32.is_eq(U32.mod(U32.from_nat(n), 3), 0), t, acc})

# records of words in a list, each re-formed
def vs(+n: Nat, acc: List<&2, V3>) -> List<&2, V3>:
  match n:
    case 0n:
      acc
    case 1n+p:
      +m = U32.from_nat(n)
      vs(p, V3{m, U32.mul(m, 2), U32.mul(m, 3)} <> acc)

def vmap(xs: List<&2, V3>) -> List<&2, V3>:
  match xs:
    case Nil{}:
      []
    case V3{x, y, z} <> r:
      V3{x, y, z} <> vmap(r)

def vsum(xs: List<&2, V3>, +acc: U32) -> U32:
  match xs:
    case Nil{}:
      acc
    case V3{x, y, z} <> r:
      vsum(r, U32.add(U32.mul(acc, 3), U32.add(x, U32.add(y, z))))

# a long list handed back node by node
def back.go(xs: List<&2, U32>, n: U32) -> List<&2, U32> & U32:
  (xs, U32.inc(n))

def back(xs: List<&2, U32>, +n: U32) -> List<&2, U32> & U32:
  match xs:
    case Nil{}:
      ([], n)
    case x <> r:
      back.go(x <> r, n)

def last(xs: List<&2, U32>, +acc: U32) -> U32:
  match xs:
    case Nil{}:
      acc
    case x <> r:
      last(r, U32.add(acc, x))

def upto(+n: Nat, acc: List<&2, U32>) -> List<&2, U32>:
  match n:
    case 0n:
      acc
    case 1n+p:
      upto(p, U32.from_nat(n) <> acc)

def back_dig(p: List<&2, U32> & U32) -> U32:
  (xs, n) = p
  last(xs, n)

def all(+d: Nat, +i: U32) -> U32:
  +t = gen(d, i)
  a = reads(t)
  b = reads(gen(d, U32.inc(i)))
  c = pair_dig(pair(t, t))
  e = pair_dig(pair(gen(d, 3), Leaf{}))
  f = pair_dig(pair(Leaf{}, t))
  +w = wraps(7n, t, WEnd{})
  g = wrap_dig(cool(w), 1)
  h = wrap_dig(cool(wraps(5n, gen(2n, i), WEnd{})), 2)
  +fl = flags(7n, t, FEnd{})
  j = flag_dig(set(fl), 1)
  k = flag_dig(set(flags(5n, gen(2n, i), FEnd{})), 2)
  +v = vs(9n, [])
  l = vsum(vmap(v), 1)
  m = vsum(vmap(vs(4n, [])), 2)
  z = U32.add(count(t, 0), U32.add(wrap_dig(w, 0), U32.add(flag_dig(fl, 0), vsum(v, 0))))
  U32.add(a, U32.add(b, U32.add(c, U32.add(e, U32.add(f, U32.add(g, U32.add(h, U32.add(j, U32.add(k, U32.add(l, U32.add(m, z)))))))))))

def loop(+n: Nat, acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+p:
      x y = all(3n, U32.from_nat(n)) loop(p, acc)
      U32.add(x, y)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(all(5n, 1)))
    Unit <- IO.print(U32.show(all(0n, 2)))
    Unit <- IO.print(U32.show(loop(150n, 0)))
    IO.print(U32.show(back_dig(back(upto(200000n, []), 5))))

#|3464386124
#|1497412360
#|3727837213
#|2820230822
