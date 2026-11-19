# peek arms on lists, pairs, a borrowed parameter, two scrutinees and a type shared only in a dead branch
import Base

type Box is Data:
  Bx{tag: U32, xs: List<&2, U32>, n: U32}

def sum(xs: List<&2, U32>, acc: U32) -> U32:
  match xs:
    case Nil{}:
      acc
    case x <> r:
      sum(r, U32.add(U32.mul(acc, 3), x))

def upto(+n: Nat) -> List<&2, U32>:
  match n:
    case 0n:
      []
    case 1n+p:
      U32.from_nat(n) <> upto(p)

# a list re-formed node by node
def copy(xs: List<&2, U32>) -> List<&2, U32>:
  match xs:
    case Nil{}:
      []
    case x <> r:
      x <> copy(r)

# the head re-formed, the head read
def head2(xs: List<&2, U32>) -> List<&2, U32> & U32:
  match xs:
    case Nil{}:
      ([], 0)
    case +x <> r:
      (x <> r, x)

def sort2.go(z: Bool, x: U32, y: U32, r: List<&2, U32>) -> List<&2, U32>:
  match z:
    case True{}:
      y <> x <> r
    case False{}:
      x <> y <> r

# two deep: the first re-formed around a re-formed second, or swapped
def sort2(xs: List<&2, U32>) -> List<&2, U32>:
  match xs:
    case +x <> +y <> r:
      sort2.go(U32.is_lt(y, x), x, y, r)
    case l:
      l

# a record: re-formed, or its list replaced, by a second scrutinee
def step(b: Box, z: Bool) -> Box:
  match b z:
    case Bx{t, xs, n} True{}:
      Bx{t, xs, n}
    case Bx{t, xs, n} False{}:
      Bx{t, copy(xs), U32.inc(n)}

def box_dig(b: Box) -> U32:
  match b:
    case Bx{t, xs, n}:
      U32.add(sum(xs, t), n)

# re-formed in one arm, dropped in the other
def keep_or(b: Box, z: Bool) -> U32:
  match b z:
    case Bx{t, xs, n} True{}:
      box_dig(Bx{t, xs, n})
    case Bx{t, xs, n} False{}:
      n

# lends its parameter: the node it re-forms is the parameter
def lend(b: Box) -> U32:
  match b:
    case Bx{t, xs, n}:
      U32.add(box_dig(Bx{t, xs, n}), 1)

# shared only where never run
def dead(z: Bool, +b: Box) -> U32:
  match z:
    case True{}:
      U32.add(box_dig(b), box_dig(b))
    case False{}:
      box_dig(step(b, True{}))

def pair_same(p: List<&2, U32> & U32) -> List<&2, U32> & U32:
  match p:
    case (xs, n):
      (xs, n)

def pair_dig(p: List<&2, U32> & U32) -> U32:
  match p:
    case (xs, n):
      sum(xs, n)

def all(+k: Nat) -> U32:
  +xs = upto(k)
  a = sum(copy(xs), 0)
  b = pair_dig(head2(xs))
  c = sum(sort2(xs), 1)
  e = sum(sort2(copy(xs)), 2)
  +bx : Box = Bx{7, xs, 1}
  f = box_dig(step(bx, True{}))
  g = box_dig(step(bx, False{}))
  h = box_dig(step(Bx{8, upto(k), 2}, True{}))
  i = keep_or(bx, True{})
  j = keep_or(bx, False{})
  l = keep_or(Bx{9, upto(k), 3}, False{})
  m = lend(bx)
  n = lend(Bx{9, copy(xs), 3})
  o = dead(False{}, Bx{4, upto(k), 5})
  p = pair_dig(pair_same(pair_same((xs, 4))))
  z = sum(xs, 0)
  U32.add(a, U32.add(b, U32.add(c, U32.add(e, U32.add(f, U32.add(g, U32.add(h, U32.add(i, U32.add(j, U32.add(l, U32.add(m, U32.add(n, U32.add(o, U32.add(p, z))))))))))))))

def loop(+n: Nat, acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+p:
      loop(p, U32.add(acc, all(n)))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(all(0n)))
    Unit <- IO.print(U32.show(all(1n)))
    Unit <- IO.print(U32.show(all(2n)))
    Unit <- IO.print(U32.show(all(50n)))
    IO.print(U32.show(loop(200n, 0)))

#|77
#|205
#|630
#|3907028014
#|2810275032
