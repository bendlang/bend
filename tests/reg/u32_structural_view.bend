# regression witness (90c7d14, respelled at 8d15057's request): the
# machine word has no structural view -- a direct U32 constructor match
# in USER code opens the Word(32n) field, which the C emission holds as
# an immediate, so tocl refuses loud. The witness no longer rides
# U32.copy: that spelling becomes an emission intrinsic, and this pin
# must survive it. The evaluator and the JS backend answer 14.
import Base

law main.out:
  U32

law view:
  for u: U32
  U32

def view(u):
  match u:
    case U32{w}:
      U32{w}

def main.out():
  view(U32.add(7, 7))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|14
