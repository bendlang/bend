# a[i] <- v followed by a statement at its column is the let a = a[i] <- v
# (the guide's example); after a ";" too; last, it is the written array
import Base

def last(a: Array<U32>) -> Array<U32>:
  a[0] <- 7

def main() -> Array<U32> & U32:
  a = [0 : U32*8n]
  a[5] <- 42
  a[1] <- 1; b = a
  c = last(b)
  c[5]

#|([7, 1, 0, 0, 0, 42, 0, 0], 42)
