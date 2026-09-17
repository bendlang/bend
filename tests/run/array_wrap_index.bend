# an index past the end wraps, and every lane agrees: both runtimes
# mask i to the low class bits, and the spec walk masks once at its
# entry, where the size is already in hand. The refl proofs pin the
# checker to the number the program prints, so a proof about an
# out-of-range read cannot state what the runtimes refuse to compute
import Base

law mk:
  Array<U32>

def mk():
  Array.set(U32, Array.set(U32, Array.set(U32,
    Array.set(U32, [0 : U32*4n], 0, 10), 1, 11), 2, 12), 3, 13)

law rd:
  for r: Array<U32> & U32
  U32

def rd(r):
  (a2, v) = r
  v

law at:
  for i: U32
  U32

def at(i):
  rd(Array.get(U32, mk(), i))

law spec.five:
  {at(5) == 11 : U32}

def spec.five():
  {==}

law spec.six:
  {at(6) == 12 : U32}

def spec.six():
  {==}

law spec.nine:
  {at(9) == 11 : U32}

def spec.nine():
  {==}

law main.out:
  U32

def main.out():
  U32.add(U32.mul(U32.add(U32.mul(at(5), 100), at(6)), 100), at(9))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|111211
