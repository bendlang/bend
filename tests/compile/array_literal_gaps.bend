# u32 array: gaps + default, set (swap), get, fold
# ported from bend3: the ![..] literal becomes [7 : U32*8n] plus
# swaps; the fold counter walks a +Nat with its U32 index rebuilt
# from the twice-read predecessor a +let licenses (Nat is Data), strict
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

law suma.go:
  for k   : Nat
  for acc : U32
  for r   : Array<U32> & U32
  U32

def suma.go(k, acc, r):
  match k:
    case 0n:
      (a2, x) = r
      U32.add(acc, x)
    case 1n+p:
      match p:
        case 0n:
          (a2, x) = r
          suma.go(0n, U32.add(U32.mul(acc, 31), x), Array.get(U32, a2, 0))
        case 1n+q:
          (a2, x) = r
          +q2 = {q : Nat}
          suma.go(1n+q2, U32.add(U32.mul(acc, 31), x),
            Array.get(U32, a2, U32.add(U32.from_nat(q2), 1)))

law suma:
  for k   : Nat
  for a   : Array<U32>
  for acc : U32
  U32

def suma(k, a, acc):
  match k:
    case 0n:
      suma.go(0n, acc, Array.get(U32, a, 0))
    case 1n+p:
      +p2 = {p : Nat}
      suma.go(1n+p2, acc, Array.get(U32, a, U32.add(U32.from_nat(p2), 1)))

law main.fin:
  for old : U32
  for r   : Array<U32> & U32
  U32

def main.fin(old, r):
  (b3, x) = r
  suma(5n, b3, U32.add(old, x))

law main.go:
  for r: Array<U32> & U32
  U32

def main.go(r):
  (b2, old) = r
  main.fin(old, Array.get(U32, b2, 1))

law main.out:
  U32

def main.out():
  main.go(Array.swap(U32, wr(wr(wr([7 : U32*8n], 0, 11), 2, 22), 5, 33), 1, 99))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|3065382255
