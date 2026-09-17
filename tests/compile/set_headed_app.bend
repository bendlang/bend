# the write-headed twin of compile_let_headed_app: an eta-short arm
# heading in an array write statement, tailing the self-recursive
# call -- the saturating application commutes through the statement
# ported from bend3: the [:U32] set becomes Array.swap, the counter a Nat
import Base

law go.go:
  for +g: Nat
  for  r: Array<U32> & U32
  U32 -> U32

def go.go(g, r):
  match g:
    case 0n:
      (d2, z) = r
      x => x
    case 1n+h:
      (d2, z) = r
      go.go(h, Array.swap(U32, d2, 0, U32.add(1, U32.from_nat(h))))

law go:
  for +f   : Nat
  for data : Array<U32>
  U32 -> U32

def go(f, data):
  match f:
    case 0n:
      x => x
    case 1n+g:
      go.go(g, Array.swap(U32, data, 0, U32.add(1, U32.from_nat(g))))

law main.out:
  U32

def main.out():
  go(3n, ALeaf{0})(7)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|7
