# a let's type B(a) is a type because box's signature is: box's T : Data
# fits Box's -T : Type, so x : Box<Nat> needs no second look at Nat
import Base

type Box<-T: Type> is Data:
  B{}

def box(T: Data) -> Box<T>:
  B{}

def main() -> Nat:
  x = box(Nat);
  0n

#|0n
