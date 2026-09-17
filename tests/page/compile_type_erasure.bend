# error census: a Type VALUE consumed at a runtime position survives
# the checker (types are inert) and dies at compile erasure; the
# interpreter shows the value (as its Word chain). the def recurses so
# the inliner cannot erase the call before emission sees it
import Base
law id0:
  for A: Type
  for n: Nat
  U32

def id0(A, n):
  match n:
    case 0n:
      0
    case 1n+p:
      id0(A, p)

law main.out:
  U32

def main.out(): id0(U32, 3n)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|0
