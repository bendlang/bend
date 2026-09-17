# run-length encoding: list -> (count, value) pairs -> expanded back;
# the round trip is the pin
# ported from bend3: bend-base's List helpers are inlined over bend's
# List (Nil/Con); strict -- the run and expand helpers folded into
# their callers' case trees, the shared code list a + binder over a
# List<&2, ..> of reusable pairs
import Base

law P2:
  Data

def P2(): Sigma<&2, &2, U32, _ => U32>

law bu:
  for b: Bool
  U32

def bu(b):
  match b:
    case False{}:
      0
    case True{}:
      1

law lconcat:
  for xs: List<&2, U32>
  for ys: List<&2, U32>
  List<&2, U32>

def lconcat(xs, ys):
  match xs:
    case Nil{}:
      ys
    case h <> t:
      h <> lconcat(t, ys)

law lrepeat:
  for  n: Nat
  for +v: U32
  List<&2, U32>

def lrepeat(n, v):
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      v <> lrepeat(p, v)

law lrevp.go:
  for xs  : List<&2, P2()>
  for acc : List<&2, P2()>
  List<&2, P2()>

def lrevp.go(xs, acc):
  match xs:
    case Nil{}:
      acc
    case h <> t:
      lrevp.go(t, h <> acc)

law lrevp:
  for xs: List<&2, P2()>
  List<&2, P2()>

def lrevp(xs):
  lrevp.go(xs, Nil{})

law llenp:
  for xs: List<&2, P2()>
  U32

def llenp(xs):
  match xs:
    case Nil{}:
      0
    case h <> t:
      U32.add(1, llenp(t))

law rle.step:
  for +cur : U32
  for +h   : U32
  for n    : U32
  for acc  : List<&2, P2()>
  for e    : Bool
  U32 & U32 & List<&2, P2()>

def rle.step(cur, h, n, acc, e):
  match e:
    case False{}:
      (h, 1, (n, cur) <> acc)
    case True{}:
      (cur, U32.add(n, 1), acc)

law rle:
  for xs: List<&2, U32>
  for st: U32 & U32 & List<&2, P2()>
  List<&2, P2()>

def rle(xs, st):
  match xs:
    case Nil{}:
      (cur, n, acc) = st
      lrevp((n, cur) <> acc)
    case h0 <> t:
      (cur0, n, acc) = st
      +h = {h0 : U32}
      +cur = {cur0 : U32}
      rle(t, rle.step(cur, h, n, acc, U32.is_eq(h, cur)))

law expand:
  for ps: List<&2, P2()>
  List<&2, U32>

def expand(ps):
  match ps:
    case Nil{}:
      Nil{}
    case (n, v) <> t:
      lconcat(lrepeat(U32.to_nat(n), v), expand(t))

law digest.go:
  for xs  : List<&2, U32>
  for acc : U32
  U32

def digest.go(xs, acc):
  match xs:
    case Nil{}:
      acc
    case h <> t:
      digest.go(t, U32.add(U32.mul(acc, 10), h))

law digest:
  for xs: List<&2, U32>
  U32

def digest(xs):
  digest.go(xs, 0)

law go:
  for xs: List<&2, U32>
  U32

def go(xs):
  match xs:
    case h <> t:
      +code = {rle(t, (h, 1, Nil{})) : List<&2, P2()>}
      U32.add(U32.mul(bu(U32.is_eq(llenp(code), 3)), 10), bu(U32.is_eq(digest(expand(code)), 777299)))
    case Nil{}:
      0

law main.out:
  U32

def main.out():
  go([7, 7, 7, 2, 9, 9])

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|11
