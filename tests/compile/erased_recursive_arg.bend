# erased arg on a recursive def
# ported from bend3: the counter walks a Nat
import Base

type BoxR<-T: Type> is Type:
  MkBoxR{v: T}

law rep:
  for -T: Type
  for  n: Nat
  for  b: BoxR<T>
  BoxR<T>

def rep(T, n, b):
  match n:
    case 0n:
      b
    case 1n+p:
      rep(T, p, b)

law get:
  for -T: Type
  for  b: BoxR<T>
  T

def get(T, b):
  match b:
    case MkBoxR{v}:
      v

law main.out:
  U32

def main.out():
  get(U32, rep(U32, 5n, MkBoxR{9}))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|9
