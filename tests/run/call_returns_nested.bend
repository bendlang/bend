# A call into a tree recursion also runs the callee's returning arms that sit
# under a second or a third test, with the lines between the tests when they
# only name words. Such defs here, each called in non-tail position: two
# trees matched together, arms that free and arms that reuse the node they
# own (zip); three tests deep (tri); a Bool, then two Nats (ways); a shared
# pair of trees read by two walks (both); a word test under a tag test
# (cut); the same def called by an owner and by a reader (keep, use); forks
# (pzip, fanz) and a ! call (bang); a comb deep on one side (comb). The rest must
# stay as they were: a nested arm that drops a subtree (lose) and one behind
# lines that take a node apart (shell, which also runs on a tree that a
# reader and a picker share, all). Counts come from the argument list, so no
# call is unrolled. Every line is the same at any thread count.
import Base

type Tree is Data:
  Leaf{a: U32}
  Node{l: Tree, r: Tree}

type Trit is Data:
  Nix{}
  Uno{}
  Many{l: Trit, r: Trit}

type Rose is Data:
  Tip{a: U32}
  Fork{l: Rose, r: Rose}
  Wrap{h: Rose, w: U32}

def len(xs: List<String>, acc: Nat) -> Nat:
  match xs:
    case Nil{}:
      acc
    case Con{h, t}:
      len(t, 1n+acc)

def grow(+d: Nat, +i: U32) -> Tree:
  match d:
    case 0n:
      Leaf{i}
    case 1n+p:
      Node{grow(p, U32.add(U32.mul(i, 3), 1)),
        grow(p, U32.add(U32.mul(i, 5), 2))}

# a tree with a leaf on one side at every level, the side by turns
def lopw(+d: Nat, +i: U32, +o: U32) -> Tree:
  match d:
    case 0n:
      Leaf{i}
    case 1n+p:
      match o:
        case 0:
          Node{lopw(p, U32.add(U32.mul(i, 3), 1), U32.and(i, 2)),
            Leaf{U32.xor(i, 77)}}
        case _:
          Node{Leaf{U32.add(i, 5)},
            lopw(p, U32.add(U32.mul(i, 5), 2), U32.and(i, 4))}

def lop(+d: Nat, +i: U32) -> Tree:
  lopw(d, i, U32.and(i, 1))

def tritw(+d: Nat, +i: U32, +o: U32) -> Trit:
  match d:
    case 0n:
      match o:
        case 0:
          Nix{}
        case _:
          Uno{}
    case 1n+p:
      match o:
        case 0:
          Nix{}
        case 1:
          Uno{}
        case _:
          Many{tritw(p, U32.add(U32.mul(i, 3), 1), U32.mod(U32.add(i, 3), 7)),
            tritw(p, U32.add(U32.mul(i, 7), 2), U32.mod(U32.mul(i, 3), 5))}

def trit(+d: Nat, +i: U32) -> Trit:
  tritw(d, i, 2)

def sum(t: Tree) -> U32:
  match t:
    case Leaf{a}:
      a
    case Node{l, r}:
      U32.add(sum(l), U32.mul(sum(r), 3))

def tsum(t: Trit) -> U32:
  match t:
    case Nix{}:
      1
    case Uno{}:
      2
    case Many{l, r}:
      U32.add(tsum(l), U32.mul(tsum(r), 5))

# owns both trees: leaf with leaf frees two nodes and builds one, leaf with
# node keeps the node, node with leaf keeps the leaf
def zip(x: Tree, y: Tree) -> Tree:
  match x:
    case Leaf{a}:
      match y:
        case Leaf{b}:
          Leaf{U32.add(a, b)}
        case Node{l, r}:
          Node{Leaf{a}, Node{l, r}}
    case Node{l, r}:
      match y:
        case Leaf{b}:
          Node{Node{l, r}, Leaf{U32.xor(b, 9)}}
        case Node{m, s}:
          Node{zip(l, m), zip(r, s)}

# the returning arms sit under two and three tests
def tri(x: Trit, y: Trit, +k: U32, +o: U32) -> U32:
  match x:
    case Nix{}:
      match y:
        case Nix{}:
          k
        case Uno{}:
          U32.add(k, 1)
        case Many{l, r}:
          U32.add(tsum(l), tsum(r))
    case Uno{}:
      match y:
        case Nix{}:
          U32.mul(k, 3)
        case Uno{}:
          match o:
            case 0:
              7
            case _:
              U32.xor(k, 11)
        case Many{l, r}:
          U32.xor(tsum(l), tsum(r))
    case Many{a, b}:
      match y:
        case Nix{}:
          U32.add(tsum(a), U32.mul(tsum(b), 2))
        case Uno{}:
          U32.sub(tsum(a), tsum(b))
        case Many{l, r}:
          U32.add(tri(a, l, U32.add(k, 1), U32.and(k, 1)),
            U32.mul(tri(b, r, U32.mul(k, 3), U32.and(k, 2)), 7))

def coin(+k: Nat) -> Nat:
  match k:
    case 0n:
      7n
    case 1n:
      1n
    case 2n:
      2n
    case 1n+p:
      5n

# a Bool, then two Nats
@unsafe
def ways(neg: Bool, +amount: Nat, +kinds: Nat) -> U32:
  match neg:
    case True{}:
      0
    case False{}:
      match amount:
        case 0n:
          1
        case 1n+ap:
          match kinds:
            case 0n:
              0
            case 1n+kp:
              U32.add(ways(Nat.is_lt(amount, coin(kinds)),
                Nat.sub(amount, coin(kinds)), kinds),
                ways(False{}, amount, kp))

# reads two shared trees: the lines between its tests load fields
def both(+x: Tree, +y: Tree, +k: U32) -> U32:
  match x:
    case Leaf{a}:
      match y:
        case Leaf{b}:
          U32.add(U32.mul(a, k), b)
        case Node{l, r}:
          U32.xor(a, k)
    case Node{l, r}:
      match y:
        case Leaf{b}:
          U32.add(b, k)
        case Node{m, s}:
          U32.add(both(l, m, k), U32.xor(both(r, s, U32.add(k, 1)), k))

# a word test under a tag test
def cut(+t: Tree, +lim: U32) -> U32:
  match t:
    case Leaf{a}:
      match lim:
        case 0:
          a
        case 1:
          U32.mul(a, 3)
        case _:
          U32.add(a, lim)
    case Node{l, r}:
      match lim:
        case 0:
          5
        case _:
          U32.add(cut(l, U32.sub(lim, 1)), U32.mul(cut(r, U32.and(lim, 3)), 3))

# zip called by a def that still reads what it passed (through copies)
def keep(+x: Tree, +y: Tree) -> U32:
  U32.add(sum(zip(x, y)), U32.mul(both(x, y, 3), 5))

# and by one that hands both over
def use(x: Tree, y: Tree) -> U32:
  sum(zip(x, y))

def pzip(x: Tree, y: Tree) -> U32:
  match x:
    case Leaf{a}:
      match y:
        case Leaf{b}:
          U32.add(a, b)
        case Node{l, r}:
          U32.xor(a, 3)
    case Node{l, r}:
      match y:
        case Leaf{b}:
          U32.add(b, 1)
        case Node{m, s}:
          p q = pzip(l, m) pzip(r, s)
          U32.add(p, U32.mul(q, 3))

def btri(+n: Nat, +i: U32) -> U32:
  tri(trit(n, i), trit(n, U32.add(i, 1)), i, 1)

def bang(+d: Nat, +n: Nat, +i: U32) -> U32:
  match d:
    case 0n:
      btri!(n, i)
    case 1n+e:
      x y = bang(e, n, U32.mul(i, 2)) bang(e, n, U32.add(U32.mul(i, 2), 1))
      U32.xor(x, y)

# a forking def whose single call ends at once while seq is clear
def fanz(+d: Nat, +m: Nat, +i: U32) -> U32:
  match d:
    case 0n:
      +v = pzip(grow(m, i), grow(m, U32.add(i, 1)))
      U32.xor(v, i)
    case 1n+e:
      x y = fanz(e, m, U32.mul(i, 2)) fanz(e, m, U32.add(U32.mul(i, 2), 1))
      U32.add(x, y)

# a comb: the left side is as deep as the count, every right side a leaf
def comb(+n: Nat, +i: U32) -> Tree:
  match n:
    case 0n:
      Leaf{i}
    case 1n+p:
      Node{comb(p, U32.add(i, 1)), Leaf{U32.mul(i, 3)}}

# the nested returning arm drops a subtree: it stays in the callee
def lose(x: Tree, y: Tree) -> U32:
  match x:
    case Leaf{a}:
      match y:
        case Leaf{b}:
          U32.add(a, b)
        case Node{l, r}:
          a
    case Node{l, r}:
      match y:
        case Leaf{b}:
          b
        case Node{m, s}:
          U32.add(lose(l, m), U32.mul(lose(r, s), 3))

def rose(+d: Nat, +i: U32, +o: U32) -> Rose:
  match d:
    case 0n:
      match o:
        case 0:
          Wrap{Tip{i}, U32.xor(i, 5)}
        case _:
          Tip{i}
    case 1n+p:
      match o:
        case 0:
          Wrap{rose(p, U32.add(i, 1), U32.mod(i, 3)), U32.mul(i, 7)}
        case 1:
          Wrap{Tip{U32.add(i, 9)}, i}
        case _:
          Fork{rose(p, U32.add(U32.mul(i, 3), 1), U32.mod(U32.add(i, 1), 4)),
            rose(p, U32.add(U32.mul(i, 5), 2), U32.mod(U32.add(i, 2), 4))}

# owns the tree: the nested returning arm frees two nodes, after the outer
# node's fields were taken
def shell(t: Rose, +k: U32) -> U32:
  match t:
    case Tip{a}:
      U32.add(a, k)
    case Fork{l, r}:
      U32.add(shell(l, k), U32.mul(shell(r, U32.add(k, 1)), 3))
    case Wrap{h, w}:
      match h:
        case Tip{a}:
          U32.add(a, w)
        case Fork{l, r}:
          U32.add(shell(Fork{l, r}, w), k)
        case Wrap{g, v}:
          U32.xor(shell(g, v), w)

# reads a shared tree; a nested arm answers with a word of an inner node
def look(+t: Rose, +k: U32) -> U32:
  match t:
    case Tip{a}:
      U32.mul(a, k)
    case Fork{l, r}:
      U32.add(look(l, k), U32.xor(look(r, U32.add(k, 1)), 3))
    case Wrap{h, w}:
      match h:
        case Tip{a}:
          U32.add(a, U32.mul(w, k))
        case Fork{l, r}:
          U32.add(look(l, w), look(r, k))
        case Wrap{g, v}:
          U32.xor(look(g, v), w)

# answers a part of its shared argument
def pick(+t: Rose, +k: U32) -> Rose:
  match t:
    case Tip{a}:
      Tip{U32.add(a, k)}
    case Fork{l, r}:
      match k:
        case 0:
          l
        case 1:
          r
        case _:
          Fork{pick(l, U32.sub(k, 2)), pick(r, U32.sub(k, 1))}
    case Wrap{h, w}:
      match h:
        case Tip{a}:
          h
        case Fork{l, r}:
          Wrap{pick(l, w), k}
        case Wrap{g, v}:
          g

def size(t: Rose) -> U32:
  match t:
    case Tip{a}:
      U32.add(a, 1)
    case Fork{l, r}:
      U32.add(size(l), U32.mul(size(r), 3))
    case Wrap{h, w}:
      U32.xor(size(h), w)

# the same shared tree goes to an owner, a reader and a picker
def all(+t: Rose, +k: U32) -> U32:
  U32.add(U32.add(shell(t, k), U32.mul(look(t, k), 3)), U32.mul(size(pick(t, k)), 5))

def go(+z: Nat) -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(sum(zip(grow(Nat.add(z, 9n), 1),
      lop(Nat.add(z, 9n), 2)))))
    Unit <- IO.print(U32.show(sum(zip(lop(Nat.add(z, 12n), 3),
      grow(Nat.add(z, 7n), 4)))))
    Unit <- IO.print(U32.show(tri(trit(Nat.add(z, 9n), 1),
      trit(Nat.add(z, 9n), 2), 3, 0)))
    Unit <- IO.print(U32.show(ways(False{}, Nat.add(z, 40n), 3n)))
    Unit <- IO.print(U32.show(both(grow(Nat.add(z, 9n), 5),
      lop(Nat.add(z, 9n), 6), 7)))
    Unit <- IO.print(U32.show(cut(grow(Nat.add(z, 9n), 8), 37)))
    Unit <- IO.print(U32.show(keep(lop(Nat.add(z, 8n), 9),
      grow(Nat.add(z, 6n), 10))))
    Unit <- IO.print(U32.show(use(grow(Nat.add(z, 8n), 11),
      lop(Nat.add(z, 10n), 12))))
    Unit <- IO.print(U32.show(pzip(grow(Nat.add(z, 9n), 13),
      lop(Nat.add(z, 9n), 14))))
    Unit <- IO.print(U32.show(bang(Nat.add(z, 3n), Nat.add(z, 6n), 1)))
    Unit <- IO.print(U32.show(fanz(Nat.add(z, 10n), z, 1)))
    Unit <- IO.print(U32.show(sum(zip(comb(Nat.add(z, 3000n), 1),
      comb(Nat.add(z, 2000n), 2)))))
    Unit <- IO.print(U32.show(lose(grow(Nat.add(z, 9n), 15),
      lop(Nat.add(z, 9n), 16))))
    Unit <- IO.print(U32.show(shell(rose(Nat.add(z, 12n), 1, 2), 3)))
    Unit <- IO.print(U32.show(size(pick(rose(Nat.add(z, 12n), 3, 2), 9))))
    Unit <- IO.print(U32.show(all(rose(Nat.add(z, 11n), 4, 3), 5)))
    IO.print(U32.show(all(rose(Nat.add(z, 10n), 5, 0), 0)))

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    go(len(args, 0n))

#|4235522136
#|2808761368
#|8679383
#|101
#|13409013
#|3637833369
#|3699070313
#|520188103
#|34615618
#|20938235
#|226524160
#|58594559
#|7928126
#|19766
#|102
#|226743
#|87970542
