# a bang over a record holding a closure: the lambda is minted on the
# host and applied on the device, so the closure walk of the bang's
# parameter type (a field of function type) puts it on the device
import Base

type FBox is Type:
  MkF{f: U32 -> U32}

law unbox:
  for b: FBox
  for x: U32
  U32

def unbox(b, x):
  match b:
    case MkF{f}:
      f(x)

law main.out:
  Nat

def main.out():
  U32.to_nat(unbox!(MkF{y => U32.mul(y, 5)}, 4))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|20n
