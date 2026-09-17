# regression witness: an array built and matched down to its leaves,
# or split once and dropped, in a loop -- every half is its own slot in
# its own class, freed to that class, so a loop of these reuses its
# slots; the views that once served the halves left the whole array's
# slot behind on every turn. The answer pins the arithmetic; the
# plateau is a leak probe's business.
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

law rl:
  for a: Array<String>
  U32

def rl(a):
  match a:
    case ALeaf{x}:
      1
    case ANode{xs, ys}:
      U32.add(rl(ys), rl(xs))

law half:
  for a: Array<U32>
  U32

def half(a):
  match a:
    case ALeaf{x}:
      x
    case ANode{xs, ys}:
      1

law words:
  for +n: Nat
  for +acc: U32
  U32

def words(n, acc):
  match n:
    case 0n:
      acc
    case 1n+p:
      words(p, U32.add(acc, rd([1 : U32*64n])))

law boxes:
  for +n: Nat
  for +acc: U32
  U32

def boxes(n, acc):
  match n:
    case 0n:
      acc
    case 1n+p:
      boxes(p, U32.add(acc, rl(["a" : String*8n])))

law halves:
  for +n: Nat
  for +acc: U32
  U32

def halves(n, acc):
  match n:
    case 0n:
      acc
    case 1n+p:
      halves(p, U32.add(acc, half([1 : U32*64n])))

law main:
  IO(Unit)

def main():
  do IO<Unit>:
    Unit <- IO.print(U32.show(words(300n, 0)))
    Unit <- IO.print(U32.show(boxes(100n, 0)))
    IO.print(U32.show(halves(100n, 0)))

#|19200
#|800
#|100
