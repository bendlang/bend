# a constructor past WIDE (247) words is one node, walked as an array, and
# its value travels boxed: R2 is 512 words of R1 (64 each, flat), R3
# exactly 256; a def whose parameters span past WIDE words takes its wide
# ones boxed, so its segment fits FID_ARITY_T (u8): sum4 takes 4 x 64
# words and forks, so it is a segment, not a flat C helper (#944)
import Base

type R0 is Data:
  R0{a: U32, b: U32, c: U32, d: U32, e: U32, f: U32, g: U32, h: U32}

type R1 is Data:
  R1{a: R0, b: R0, c: R0, d: R0, e: R0, f: R0, g: R0, h: R0}

type R2 is Data:
  R2{a: R1, b: R1, c: R1, d: R1, e: R1, f: R1, g: R1, h: R1}

type R3 is Data:
  R3{a: R1, b: R1, c: R1, d: R1}

def r0(+x: U32) -> R0:
  R0{x, x, x, x, x, x, x, x}

def r1(+x: U32) -> R1:
  R1{r0(x), r0(x), r0(x), r0(x), r0(x), r0(x), r0(x), r0(x)}

def r2(+x: U32) -> R2:
  R2{r1(x), r1(x), r1(x), r1(x), r1(x), r1(x), r1(x), r1(x)}

def r3(+x: U32) -> R3:
  R3{r1(x), r1(x), r1(x), r1(x)}

def first0(x: R0) -> U32:
  match x:
    case R0{a, b, c, d, e, f, g, h}:
      a

def first1(x: R1) -> U32:
  match x:
    case R1{a, b, c, d, e, f, g, h}:
      first0(a)

def first2(x: R2) -> U32:
  match x:
    case R2{a, b, c, d, e, f, g, h}:
      first1(h)

def first3(x: R3) -> U32:
  match x:
    case R3{a, b, c, d}:
      first1(d)

def sum4(a: R1, b: R1, c: R1, d: R1) -> U32:
  x y = first1(a) first1(b)
  z w = first1(c) first1(d)
  U32.add(U32.add(x, y), U32.add(z, w))

def main() -> U32:
  a = sum4(r1(1), r1(2), r1(3), r1(4))
  b = sum4(r1(5), r1(6), r1(7), r1(8))
  U32.add(U32.add(first2(r2(7)), first3(r3(70))), U32.add(a, b))

#|113
