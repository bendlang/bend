# FLAGSHIP: certified insertion sort, strict. The comparator returns an
# evidence SUM (LEOr), so the proof matches the same ordering fact the
# program branched on; SortedB carries the lower bound as an
# accumulator, making the insert lemma's IH fit exactly. Proved:
# sortedness + length preservation.
# ported from bend3: bend3's elaborator specialized a computed-match
# goal in place and its dec/insert pair was mutual; bend
# passes the recursive result INTO dec, so the pair untangles, and each
# proof replays insert's dispatch through a framed match whose motive
# keeps dec folded over the cell -- the arms then specialize and the IH
# sits in the OG arm, a direct structural self-call. The double spends
# ride + binders over Nat and List<&2, Nat>, both Data
import Base

law LL.length:
  for -A : Data
  for xs : List<&2, A>
  Nat

def LL.length(A, xs):
  match xs:
    case Nil{}:
      0n
    case h <> t:
      1n+LL.length(A, t)

law LE:
  for a: Nat
  for b: Nat
  Data

def LE(a, b):
  match a:
    case 0n:
      Unit
    case 1n+a1:
      match b:
        case 0n:
          Empty
        case 1n+b1:
          LE(a1, b1)

type LEOr<-x: Nat, -h: Nat> is Data:
  OL{e: LE(x, h)}
  OG{e: LE(h, x)}

law le_case:
  for x: Nat
  for h: Nat
  LEOr<x, h>

law le_case.fin:
  for -a: Nat
  for -b: Nat
  for  w: LEOr<a, b>
  LEOr<1n+a, 1n+b>

def le_case.fin(a, b, w):
  match w:
    case OL{e}:
      OL{e}
    case OG{e}:
      OG{e}

def le_case(x, h):
  match x, h:
    case 0n, 0n:
      OL{Unit{}}
    case 0n, 1n+b:
      OL{Unit{}}
    case 1n+a, 0n:
      OG{Unit{}}
    case 1n+a, 1n+b:
      le_case.fin(a, b, le_case(a, b))

law dec:
  for x: Nat
  for h: Nat
  for t: List<&2, Nat>
  for r: List<&2, Nat>
  for c: LEOr<x, h>
  List<&2, Nat>

def dec(x, h, t, r, c):
  match c:
    case OL{e}:
      x <> h <> t
    case OG{e}:
      h <> r

law insert:
  for +x  : Nat
  for +xs : List<&2, Nat>
  List<&2, Nat>

def insert(x, xs):
  match xs:
    case Nil{}:
      [x]
    case h <> t:
      dec(x, h, t, insert(x, t), le_case(x, h))

law isort:
  for xs: List<&2, Nat>
  List<&2, Nat>

def isort(xs):
  match xs:
    case Nil{}:
      Nil{}
    case h <> t:
      insert(h, isort(t))

law SortedB:
  for xs: List<&2, Nat>
  for lo: Nat
  Type

def SortedB(xs, lo):
  match xs:
    case Nil{}:
      Unit
    case h <> t:
      (LE(lo, h) & SortedB(t, h))

law sorted_ins.fin:
  for -lo : Nat
  for -x  : Nat
  for -h  : Nat
  for -t  : List<&2, Nat>
  for sx  : SortedB(h <> t, lo)
  for lx  : LE(lo, x)
  for rec : (SortedB(t, h) -> LE(h, x) -> SortedB(insert(x, t), h))
  for c   : LEOr<x, h>
  SortedB(dec(x, h, t, insert(x, t), c), lo)

def sorted_ins.fin(lo, x, h, t, sx, lx, rec, c):
  (lh, st) = sx
  match c:
    case OL{e}:
      (lx, e, st)
    case OG{e}:
      (lh, rec(st, e))

law sorted_ins:
  for xs  : List<&2, Nat>
  for -lo : Nat
  for +x  : Nat
  SortedB(xs, lo) -> LE(lo, x) -> SortedB(insert(x, xs), lo)

def sorted_ins(xs, lo, x):
  match xs:
    case Nil{}:
      sx => lx => (lx, Unit{})
    case h <> t:
      sx => lx => sorted_ins.fin(lo, x, h, t, sx, lx,
        sorted_ins(t, h, x), le_case(x, h))

law sorted_isort:
  for +xs: List<&2, Nat>
  SortedB(isort(xs), 0n)

def sorted_isort(xs):
  match xs:
    case Nil{}:
      Unit{}
    case h <> t:
      sorted_ins(isort(t), 0n, h)(sorted_isort(t), Unit{})

law len_ins:
  for +x : Nat
  for xs : List<&2, Nat>
  {1n+LL.length(Nat, xs) == LL.length(Nat, insert(x, xs)) : Nat}

law len_ins.fin:
  for -x  : Nat
  for -h  : Nat
  for -t  : List<&2, Nat>
  for rec : {1n+LL.length(Nat, t) == LL.length(Nat, insert(x, t)) : Nat}
  for c   : LEOr<x, h>
  {1n+LL.length(Nat, h <> t) == LL.length(Nat, dec(x, h, t, insert(x, t), c)) : Nat}

def len_ins.fin(x, h, t, rec, c):
  match c:
    case OL{e}:
      {==}
    case OG{e}:
      %rec : {2n+LL.length(Nat, t) == 1n+_ : Nat}
      {==}

def len_ins(x, xs):
  match xs:
    case Nil{}:
      {==}
    case h <> t:
      len_ins.fin(x, h, t, len_ins(x, t), le_case(x, h))

law len_isort:
  for +xs: List<&2, Nat>
  {LL.length(Nat, isort(xs)) == LL.length(Nat, xs) : Nat}

def len_isort(xs):
  match xs:
    case Nil{}:
      {==}
    case h <> t:
      %len_ins(h, isort(t)) : {_ == 1n+LL.length(Nat, t) : Nat}
      %len_isort(t) : {1n+LL.length(Nat, isort(t)) == 1n+_ : Nat}
      {==}

law s:
  List<&2, Nat>

def s(): isort([2n, 0n, 1n])

law main:
  List<&2, Nat>

def main(): s()

#|[0n, 1n, 2n]
