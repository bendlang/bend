# regression witness: leaves built by hand and noded up, then dropped
# or matched back down, in a loop -- blk_node allocates the merged
# class and frees both halves to theirs; it once merged two adjacent
# slots into a view of the class above, so a slot changed class on
# every turn and the chains drifted. The answers pin the arithmetic.
import Base

law rd:
  for a: Array<U32>
  U32

def rd(a):
  match a:
    case ALeaf{x}:
      x
    case ANode{xs, ys}:
      U32.add(rd(xs), rd(ys))

law build:
  for +d: Nat
  for +i: U32
  Array<U32>

def build(d, i):
  match d:
    case 0n:
      ALeaf{i}
    case 1n+p:
      ANode{build(p, i), build(p, U32.add(i, 1))}

law builds:
  for +d: Nat
  Array<String>

def builds(d):
  match d:
    case 0n:
      ALeaf{"x"}
    case 1n+p:
      ANode{builds(p), builds(p)}

law size.go:
  for -T: Type
  for an: Array<T> & U32
  U32

def size.go(T, an):
  (b, n) = an
  n

law words:
  for +n: Nat
  for +acc: U32
  U32

def words(n, acc):
  match n:
    case 0n:
      acc
    case 1n+p:
      words(p, U32.add(acc, size.go(U32, Array.size(U32, build(5n, 1)))))

law boxes:
  for +n: Nat
  for +acc: U32
  U32

def boxes(n, acc):
  match n:
    case 0n:
      acc
    case 1n+p:
      boxes(p, U32.add(acc, size.go(String, Array.size(String, builds(4n)))))

law main:
  IO(Unit)

def main():
  do IO<Unit>:
    Unit <- IO.print(U32.show(words(200n, 0)))
    Unit <- IO.print(U32.show(boxes(50n, 0)))
    IO.print(U32.show(rd(build(5n, 1))))

#|6400
#|800
#|112
