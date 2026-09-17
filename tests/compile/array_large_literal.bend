# a large array: 1024 slots default-filled, three slots written, strided
# reads at 0, 100, .., 1000
# ported from bend3: the ![..] literal with a default becomes
# [3 : U32*1024n] plus swaps; the read counter walks a +Nat whose
# twice-read predecessor a +let licenses (Nat is Data), strict
import Base

law wr.put:
  for r: Array<U32> & U32
  Array<U32>

def wr.put(r):
  (m2, old) = r
  m2

law wr:
  for m: Array<U32>
  for i: U32
  for v: U32
  Array<U32>

def wr(m, i, v):
  wr.put(Array.swap(U32, m, i, v))

law rd.go:
  for k   : Nat
  for acc : U32
  for r   : Array<U32> & U32
  U32

def rd.go(k, acc, r):
  match k:
    case 0n:
      (a2, x) = r
      U32.add(acc, x)
    case 1n+p:
      match p:
        case 0n:
          (a2, x) = r
          rd.go(0n, U32.add(acc, x), Array.get(U32, a2, 0))
        case 1n+q:
          (a2, x) = r
          +q2 = {q : Nat}
          rd.go(1n+q2, U32.add(acc, x),
            Array.get(U32, a2, U32.mul(U32.add(U32.from_nat(q2), 1), 100)))

law rd:
  for k   : Nat
  for a   : Array<U32>
  for acc : U32
  U32

def rd(k, a, acc):
  match k:
    case 0n:
      rd.go(0n, acc, Array.get(U32, a, 0))
    case 1n+p:
      +p2 = {p : Nat}
      rd.go(1n+p2, acc,
        Array.get(U32, a, U32.mul(U32.add(U32.from_nat(p2), 1), 100)))

law main.out:
  U32

def main.out():
  rd(10n, wr(wr(wr([3 : U32*1024n], 0, 7), 500, 20), 1000, 9), 0)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|60
