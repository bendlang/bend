# an array flowing through a dynamically-applied closure must compile on
# every backend (bend3 pinned its prep unk-shape guard; the behavior is
# the dialect-neutral part)
# ported from bend3: [:U32] literals become Base Array trees (Array.new),
# @-swaps become Array.swap/Array.get
import Base

law app:
  for f: Array<U32> -> Array<U32>
  for a: Array<U32>
  Array<U32>

def app(f, a):
  f(a)

law poke.put:
  for r: Array<U32> & U32
  Array<U32>

def poke.put(r):
  (a2, old) = r
  a2

law poke:
  for a: Array<U32>
  Array<U32>

def poke(a):
  poke.put(Array.swap(U32, a, 0, 9))

law main.pick:
  for r: Array<U32> & U32
  U32

def main.pick(r):
  (h3, x) = r
  x

law main.out:
  U32

def main.out():
  main.pick(Array.get(U32, app(poke, [1 : U32*1n]), 0))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|9
