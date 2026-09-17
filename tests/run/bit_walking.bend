# bit-walking loops: popcount and bit-reversal via shift/mask recursion
# ported from bend3: level counters become Nat, hex masks decimals,
# the walked word a +U32 binder
import Base

law bu:
  for b: Bool
  U32

def bu(b):
  match b:
    case False{}:
      0
    case True{}:
      1

law pop:
  for i   : Nat
  for +n  : U32
  for acc : U32
  U32

def pop(i, n, acc):
  match i:
    case 0n:
      acc
    case 1n+p:
      pop(p, U32.shr(n), U32.add(acc, U32.and(n, 1)))

law brev:
  for i    : Nat
  for +n   : U32
  for +acc : U32
  U32

def brev(i, n, acc):
  match i:
    case 0n:
      acc
    case 1n+p:
      brev(p, U32.shr(n), U32.or(U32.shln(acc, 1n), U32.and(n, 1)))

law main.out:
  U32

def main.out():
  b0 = bu(U32.is_eq(pop(16n, 48879, 0), 13))
  b1 = bu(U32.is_eq(pop(16n, 0, 0), 0))
  b2 = bu(U32.is_eq(pop(16n, 65535, 0), 16))
  b3 = bu(U32.is_eq(brev(8n, 0, 0), 0))
  b4 = bu(U32.is_eq(brev(8n, 13, 0), 176))
  U32.add(U32.add(U32.add(U32.add(b0, b1), b2), b3), b4)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|5
