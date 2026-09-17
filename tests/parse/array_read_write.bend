# array read/write syntax over base Array ops: a[i] is Array.get(U32, a, i)
# (leftovers-first, the array rides back beside the element) and
# a[i] <- v is Array.set(U32, a, i, v). bend3's bare-statement error census
# has no counterpart wall: both forms are plain terms here
import Base

law main.out:
  U32

law main.rd2:
  for x: U32
  for r: Array<U32> & U32
  U32

def main.rd2(x, r):
  (a3, y) = r
  (x * 10 + y : U32)

law main.rd1:
  for r: Array<U32> & U32
  U32

def main.rd1(r):
  (a2, x) = r
  main.rd2(x, a2[0])

def main.out():
  main.rd1(([7 : U32*4n][1] <- 9)[1])

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|97
