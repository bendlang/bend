# over-use at runtime: a Tree consumed by two different walks, a WORD
# used three times, and a bare Data binder used twice -- identical
# results on every lane
# ported from bend3: bend3's checker-planted deep copies become explicit
# + binders over the Data-kinded Tree (bend core has no implicit
# duplication);
# the bend3 `--eval --stats` block is bend3-only and is dropped
import Base

type Tree is Data:
  TL{v: U32}
  TN{a: Tree, b: Tree}

law tsum:
  for t: Tree
  U32

def tsum(t):
  match t:
    case TL{v}:
      v
    case TN{a, b}:
      U32.add(tsum(a), tsum(b))

law depth.go:
  for +d: U32
  for +e: U32
  U32

law depth.pick:
  for +d: U32
  for +e: U32
  for  z: Bool
  U32

def depth.pick(d, e, z):
  match z:
    case True{}:
      U32.add(d, 1)
    case False{}:
      U32.add(e, 1)

def depth.go(d, e):
  depth.pick(d, e, U32.is_gt(d, e))

law depth:
  for t: Tree
  U32

def depth(t):
  match t:
    case TL{v}:
      0
    case TN{a, b}:
      depth.go(depth(a), depth(b))

law both:
  for +t: Tree
  U32

def both(t):
  U32.add(U32.mul(tsum(t), 10), depth(t))

law wshare:
  for  x: U32
  for +s: U32
  U32

def wshare(x, s):
  U32.add(U32.add(U32.add(x, s), s), s)

law main.out:
  U32

def main.out():
  t = {TN{TN{TL{1}, TL{2}}, TN{TL{3}, TN{TL{4}, TL{5}}}} : Tree}
  a = both(t)
  +u = {TN{TL{6}, TL{7}} : Tree}
  b = U32.add(tsum(u), tsum(u))
  U32.add(U32.add(U32.mul(a, 100), b), wshare(1, 2))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|15333
