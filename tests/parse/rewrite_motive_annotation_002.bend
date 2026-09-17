# bend3 refused the '_' motive at the Type carrier; bend binds it, so
# symmetry at ANY carrier -- Type itself included -- and the transport
# cast both CHECK: the inverted law at Type:Type
import Base

law symT:
  for -t: Type
  for -x: t
  for -y: t
  for  e: {x == y : t}
  {y == x : t}

def symT(t, x, y, e):
  %e : {_ == x : t}
  {==}

law cast:
  for -A: Type
  for -B: Type
  for  e: {A == B : Type}
  for  x: A
  B

def cast(A, B, e, x):
  %e : _
  x

law main.out:
  U32

def main.out():
  0

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|0
