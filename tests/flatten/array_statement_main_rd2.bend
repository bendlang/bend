# array statements: read `(m, x) = a[i]` and write `m = a[i] <- v`;
# the read's pair lands in a worker def's parameter (a computed
# destructure is banned), the array rides back beside the element
# ported from bend3: no array literal exists (Array.new), word literals
# become params
import Base

law main:
  for x: U32
  for r: Array<U32> & U32
  U32

def main(x, r):
  (m4, z) = r
  (x + z : U32)

law main.rd1:
  for j: U32
  for k: U32
  for w: U32
  for r: Array<U32> & U32
  U32

def main.rd1(j, k, w, r):
  (m2, x) = r
  main(x, (m2[j] <- w)[k])

#|x => \{Tuple: (m4 => z => U32.add(x, z))}
