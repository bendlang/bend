# two arrays SWAPPED through a self tail call, no read in the swapping
# arm: after an odd number of swaps the reads must see each array's own
# storage (bend3 pinned its header-companion clobber; the swap is the
# dialect-neutral part)
# ported from bend3: 1-slot [:U32] literals become ALeaf, the counter a Nat
import Base

law go.fin:
  for acc : U32
  for ra  : Array<U32> & U32
  for rb  : Array<U32> & U32
  U32

def go.fin(acc, ra, rb):
  (a2, x) = ra
  (b2, y) = rb
  U32.add(acc, U32.add(U32.mul(x, 10), y))

law go:
  for +n  : Nat
  for a   : Array<U32>
  for b   : Array<U32>
  for acc : U32
  U32

def go(n, a, b, acc):
  match n:
    case 0n:
      go.fin(acc, Array.get(U32, a, 0), Array.get(U32, b, 0))
    case 1n+p:
      +p2 = {p : Nat}
      go(p2, b, a, U32.add(acc, U32.add(1, U32.from_nat(p2))))

law main.out:
  U32

def main.out():
  go(3n, ALeaf{111}, ALeaf{222}, 0)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|2337
