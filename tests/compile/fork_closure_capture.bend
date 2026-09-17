# closures crossing a parallel fork + capture of matched fields
# ported from bend3: counters walk Nats, forks are parallel lets
import Base

type Bx is Data:
  MkBx{v: U32}

law step:
  for +n: Nat
  for  k: U32 -> U32
  U32

def step(n, k):
  match n:
    case 0n:
      k(1)
    case 1n+p:
      step(p, r => k(U32.add(r, U32.add(1, U32.from_nat(p)))))

law par2:
  for +n: Nat
  U32

def par2(n):
  match n:
    case 0n:
      1
    case 1n+p:
      a b = par2(p) step(1n+p, x => x)
      U32.add(a, U32.mul(31, b))

law grab:
  for b: Bx
  U32 -> U32

def grab(b):
  match b:
    case MkBx{v}:
      x => U32.add(x, v)

law main.out:
  U32

def main.out():
  f = grab(MkBx{100})
  U32.add(par2(6n), f(par2(5n)))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|3264
