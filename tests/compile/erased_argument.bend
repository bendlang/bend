# erased argument (-T): polymorphic first-order def
# ported from bend3 (Data -> Type)
import Base

type BoxA<-T: Type> is Type:
  MkBoxA{v: T}

law get:
  for -T: Type
  for  b: BoxA<T>
  T

def get(T, b):
  match b:
    case MkBoxA{v}:
      v

law main.out:
  U32

def main.out():
  get(U32, MkBoxA{7})

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|7
