# borrow witness: arrays are owned positions. An Array parameter is never
# borrowed (Arr.first~0), and an array field of a rooted node handed to
# Array.get owns the root (Box.peek~0): no term_peek in the C, no term_keep.
import Base

type Box is Type:
  Box{arr: Array<U32>, n: U32}

def Box.fin(n: U32, r: Array<U32> & U32) -> U32:
  (arr, v) = r
  (n + v : U32)

def Box.peek(b: Box) -> U32:
  match b:
    case Box{arr, n}:
      Box.fin(n, Array.get(U32, arr, 1))

def Arr.first(arr: Array<U32>) -> U32:
  Box.fin(0, Array.get(U32, arr, 0))

def main() -> IO(Unit):
  IO.print(U32.show((Box.peek(Box{[7 : U32*4n], 3}) + Arr.first([5 : U32*2n]) : U32)))

#|15
