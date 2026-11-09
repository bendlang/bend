# an index at or past 2^31 wraps like any other: a get, a set and a swap
# at 2^32 - 1, 2^31 + 6 and 2^32 - 4 on four cells reach cells 3, 2 and
# 0, on every lane
import Base

law mk:
  Array<U32>

def mk():
  Array.set(U32, Array.set(U32, Array.set(U32,
    Array.set(U32, [0 : U32*4n], 0, 10), 1, 11), 2, 12), 3, 13)

law snd:
  for r: Array<U32> & U32
  U32

def snd(r):
  (a, v) = r
  v

law swapped:
  for r: Array<U32> & U32
  U32

def swapped(r):
  (a, old) = r
  U32.add(U32.mul(old, 100), snd(Array.get(U32, a, 0)))

law main.out:
  U32

def main.out():
  +top = snd(Array.get(U32, mk(), 4294967295))
  +set = snd(Array.get(U32, Array.set(U32, mk(), 2147483654, 99), 2))
  +swp = swapped(Array.swap(U32, mk(), 4294967292, 7))
  U32.add(U32.mul(U32.add(U32.mul(top, 100), set), 10000), swp)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|13991007
