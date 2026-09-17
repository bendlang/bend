# the device compiles what a bang reaches, and every closure of the
# program when a bang's parameter type may hold one: a list of partial
# applications built on the host is applied on the device, and the
# value is the plain call's on every lane
import Base

law add:
  for a: U32
  for b: U32
  U32

def add(a, b):
  (a + b : U32)

law mul:
  for a: U32
  for b: U32
  U32

def mul(a, b):
  (a * b : U32)

law run_all:
  for fs: List<&1, U32 -> U32>
  for x: U32
  U32

def run_all(fs, x):
  match fs:
    case Nil{}:
      x
    case f <> r:
      run_all(r, f(x))

law main.out:
  Nat

def main.out():
  U32.to_nat(run_all!([add(2), mul(3)], 5))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|21n
