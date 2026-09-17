# array statements: read `(m, x) = a[i]` and write `m = a[i] <- v`;
# the read's pair lands in a worker def's parameter (a computed
# destructure is banned), the array rides back beside the element
# ported from bend3: no array literal exists (Array.new), word literals
# become params
import Base

law main.rd2:
  for x: U32
  for r: Array<U32> & U32
  U32

def main.rd2(x, r):
  (m4, z) = r
  (x + z : U32)

law main:
  for j: U32
  for k: U32
  for w: U32
  for r: Array<U32> & U32
  U32

def main(j, k, w, r):
  (m2, x) = r
  main.rd2(x, (m2[j] <- w)[k])

#|j => k => w => \{Tuple: (m2 => x => main.rd2(x, Array.get.at(U32, k, Array.size(U32, Array.set.fin(U32, Array.swap.at(U32, j, w, Array.size(U32, m2)))))))}
