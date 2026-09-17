# the displaced element: Array.swap moves the old value out beside the
# written array -- bend's affine respell of bend3's Set-moves-old law
# (the a[i] <- v sugar rides Array.set and drops the old element; swap
# is the keeping form). the moved-out word shares via +
import Base

law main.b:
  for old0 : U32
  for r    : Array<U32> & U32
  U32

def main.b(old0, r):
  (b1, x) = r
  +old = {old0 : U32};
  (old + old + x : U32)

law main.a:
  for r: Array<U32> & U32
  U32

def main.a(r):
  (b, old0) = r
  main.b(old0, b[0])

law main.out:
  U32

def main.out():
  main.a(Array.swap(U32, [5 : U32*2n], 0, 1))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|11
