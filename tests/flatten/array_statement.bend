# array statements: read `(m, x) = a[i]` and write `m = a[i] <- v`;
# the read's pair lands in a worker def's parameter (a computed
# destructure is banned), the array rides back beside the element
# ported from bend3: no array literal exists (Array.new), word literals
# become params
import Base

law main:
  for i: U32
  for j: U32
  for k: U32
  for v: U32
  for w: U32
  U32

law main.rd2:
  for x: U32
  for r: Array<U32> & U32
  U32

def main.rd2(x, r):
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
  main.rd2(x, (m2[j] <- w)[k])

def main(i, j, k, v, w):
  main.rd1(j, k, w, [v : U32*4n][i])

#|i => j => k => v => w => main.rd1(j, k, w, Array.get.if(U32, [v, v], [v, v], 2, U32.and(i, 3), Cmp.is_lt(U32.cmp(U32.and(i, 3), 2))))
