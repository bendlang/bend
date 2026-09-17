# contiguous halves: an ANode match yields the LOW flat half and the
# HIGH flat half of the parent block in place, an in-place write to a
# half stays visible through a rebuilt ANode, and the rebuilt parent's
# flat indices read [lo.. , hi..] on every backend
import Base

law fill8:
  for a: Array<U32>
  Array<U32>

def fill8(a):
  (((((((a[0] <- 1)[1] <- 2)[2] <- 3)[3] <- 4)[4] <- 5)[5] <- 6)[6] <- 7)[7] <- 8

law jn.b:
  for acc : U32
  for r   : Array<U32> & U32
  U32

def jn.b(acc, r):
  (a2, v) = r
  U32.add(U32.mul(acc, 10), v)

law jn.a:
  for acc : U32
  for r   : Array<U32> & U32
  U32

def jn.a(acc, r):
  (a, v) = r
  jn.b(U32.add(U32.mul(acc, 10), v), a[5])

law jn:
  for acc : U32
  for a   : Array<U32>
  U32

def jn(acc, a):
  jn.a(acc, a[1])

law go.d:
  for v1 : U32
  for v4 : U32
  for v5 : U32
  for xs : Array<U32>
  for r  : Array<U32> & U32
  U32

def go.d(v1, v4, v5, xs, r):
  (ys, v8) = r
  acc = U32.add(U32.mul(U32.add(U32.mul(U32.add(U32.mul(v1, 10), v4), 10), v5), 10), v8)
  jn(acc, ANode{xs[1] <- 9, ys})

law go.c:
  for v1 : U32
  for v4 : U32
  for xs : Array<U32>
  for r  : Array<U32> & U32
  U32

def go.c(v1, v4, xs, r):
  (ys, v5) = r
  go.d(v1, v4, v5, xs, ys[3])

law go.b:
  for v1 : U32
  for ys : Array<U32>
  for r  : Array<U32> & U32
  U32

def go.b(v1, ys, r):
  (xs, v4) = r
  go.c(v1, v4, xs, ys[0])

law go.a:
  for ys : Array<U32>
  for r  : Array<U32> & U32
  U32

def go.a(ys, r):
  (xs, v1) = r
  go.b(v1, ys, xs[3])

law halves:
  for a: Array<U32>
  U32

def halves(a):
  match a:
    case ALeaf{x}:
      x
    case ANode{xs, ys}:
      go.a(ys, xs[0])

law main.out:
  U32

def main.out():
  halves(fill8([0 : U32*8n]))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|145896
