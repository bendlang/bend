# continuations whose code is alike but for the names of their locals are
# one segment, so a return through them has one target. size's A and B arms
# are alike: their first continuations fuse only once their second ones
# have (a fixpoint); C's adds another constant and D's another operator, so
# those stay apart. hop's two arms differ before the call and agree after
# it (the queens shape). pair's arms fork: their continuations lead to
# different joins and stay apart. every result depends on which arm ran,
# so a wrong fusion prints another number
import Base

type Tree is Data:
  Leaf{v: U32}
  A{l: Tree, r: Tree}
  B{l: Tree, r: Tree}
  C{l: Tree, r: Tree}
  D{l: Tree, r: Tree}

def size(t: Tree) -> U32:
  match t:
    case Leaf{v}:
      v
    case A{l, r}:
      U32.add(1, U32.add(size(l), size(r)))
    case B{l, r}:
      U32.add(1, U32.add(size(l), size(r)))
    case C{l, r}:
      U32.add(2, U32.add(size(l), size(r)))
    case D{l, r}:
      U32.add(1, U32.mul(size(l), size(r)))

def pick(o: Nat, a: Tree, b: Tree) -> Tree:
  match o:
    case 0n:
      A{a, b}
    case 1n:
      B{a, b}
    case 2n:
      C{a, b}
    case 3n+p:
      D{a, b}

def grow(+d: Nat, +h: U32) -> Tree:
  match d:
    case 0n:
      Leaf{U32.and(h, 7)}
    case 1n+p:
      a = grow(p, U32.add(U32.mul(h, 1664525), 1013904223))
      b = grow(p, U32.xor(h, U32.shrn(h, 3n)))
      pick(U32.to_nat(U32.mod(U32.shrn(h, 5n), 4)), a, b)

def hop(n: Nat, b: Bool, +k: U32) -> U32:
  match n b:
    case 0n b0:
      k
    case 1n+p True{}:
      U32.add(k, hop(p, False{}, U32.add(k, 1)))
    case 1n+p False{}:
      U32.add(k, hop(p, True{}, U32.mul(k, 3)))

def pair(+n: Nat, b: Bool, +k: U32) -> U32:
  match n b:
    case 0n b0:
      k
    case 1n+p True{}:
      x y = pair(p, False{}, U32.add(k, 1)) pair(p, False{}, U32.mul(k, 3))
      U32.add(k, U32.xor(x, y))
    case 1n+p False{}:
      x y = pair(p, True{}, U32.mul(k, 5)) pair(p, False{}, U32.mul(k, 3))
      U32.add(k, U32.xor(x, y))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(size(grow(12n, 42))))
    Unit <- IO.print(U32.show(size(grow(7n, 7))))
    Unit <- IO.print(U32.show(hop(40n, True{}, 1)))
    Unit <- IO.print(U32.show(hop(41n, False{}, 2)))
    Unit <- IO.print(U32.show(pair(14n, True{}, 1)))
    IO.print(U32.show(pair(13n, False{}, 3)))

#|2836771762
#|26922
#|254052777
#|762158416
#|113776708
#|176168727
