# closure stress: capturing continuation chains (CPS) under a parallel
# fork tree; closures dispatch native mixers and recursive defs alike
# through the dynamic apply
# ported from bend3: shifts spell U32.shrn, shares become +binders,
# counters walk Nats, forks are parallel lets
import Base

type Bx is Data:
  MkBx{v: U32}

law mix:
  for +a: U32
  U32

def mix(a):
  +b = {U32.mul(U32.xor(a, U32.shrn(a, 16n)), 2246822519) : U32}
  +c = {U32.mul(U32.xor(b, U32.shrn(b, 13n)), 3266489917) : U32}
  U32.xor(c, U32.shrn(c, 16n))

law open2:
  for b: Bx
  U32

def open2(b):
  match b:
    case MkBx{v}:
      v

law boxer:
  (U32 -> Bx) -> U32 -> U32

def boxer():
  f => x => open2(f(x))

law cps:
  for +n: Nat
  for  k: U32 -> U32
  U32

def cps(n, k):
  match n:
    case 0n:
      k(1)
    case 1n+p:
      cps(p, r => k(mix(U32.add(r, U32.add(1, U32.from_nat(p))))))

law leaf:
  for +i: U32
  U32

def leaf(i):
  U32.add(cps(U32.to_nat(U32.mod(i, 13)), x => U32.add(x, i)), boxer(x => MkBx{U32.add(x, 7)}, i))

law tree:
  for +d: Nat
  for +i: U32
  U32

def tree(d, i):
  match d:
    case 0n:
      leaf(i)
    case 1n+p:
      l r = tree(p, U32.mul(i, 2)) tree(p, U32.add(U32.mul(i, 2), 1))
      U32.add(l, r)

law main.out:
  U32

def main.out():
  tree(2n, 0)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|2298769217
