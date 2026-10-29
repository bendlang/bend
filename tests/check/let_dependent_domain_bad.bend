# the signature is where a let's type B(a) is checked to be a type: box's
# T : Type does not fit Box's -T : Data, so box is refused, not the let
import Base

type Box<-T: Data> is Data:
  B{}

def box(T: Type) -> Box<T>:
  B{}

def main() -> Nat:
  x = box(Nat);
  0n

#|SOME PROOFS FAIL
#|Error:
#|- expected : Data
#|- observed : Type
#|Context:
#|- T : Type
#|Location: box
#|7 |
#|8>| def box(T: Type) -> Box<T>:
#|  |                         ^
#|9 |   B{}
#|exit 1
